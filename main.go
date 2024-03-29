package main

import (
	"archive/zip"
	"errors"
	"fmt"
	"github.com/alecthomas/kong"
	"github.com/facebookgo/symwalk"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/ziflex/lecho/v2"
	"io"
	"io/fs"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"strings"
)

var CLI struct {
	Symlinks bool   `help:"Follow symlinks. WARNING: Allows escaping the root path!"`
	Hidden   bool   `help:"Serve files and directories that start with dot."`
	Level    uint16 `help:"ZIP compression level (0/store - 9/highest)." default:"0"`
	Prefix   string `help:"URL prefix to be removed before serving." default:"/"`
	Root     string `arg:"" help:"Path from which to serve files." type:"existingdir"`
	Host     string `help:"Host on which to listen, empty for all." default:""`
	Port     uint16 `help:"Port on which to listen." default:"8080"`
	Json     bool   `help:"Log in JSON instead of pretty printing."`
}

func main() {
	kong.Parse(&CLI,
		kong.Name("serve-zip"),
		kong.Description("Simple HTTP server that streams directories as a ZIP."),
		kong.UsageOnError(),
		kong.ConfigureHelp(kong.HelpOptions{
			Compact: true,
		}),
	)

	CLI.Prefix = path.Clean("//" + CLI.Prefix)
	if !strings.HasSuffix(CLI.Prefix, "/") {
		CLI.Prefix += "/"
	}
	if CLI.Level > 9 {
		log.Fatal().Msg("level cannot exceed 9")
	}

	var consoleWriter io.Writer
	if CLI.Json {
		consoleWriter = os.Stdout
	} else {
		consoleWriter = zerolog.ConsoleWriter{Out: os.Stdout}
	}
	log.Logger = log.Output(consoleWriter)

	e := echo.New()
	e.HideBanner = true
	logger := lecho.From(log.Logger)
	e.Logger = logger
	e.Use(lecho.Middleware(lecho.Config{Logger: logger}))

	e.GET("*", handleZip)

	log.Info().Str("state", "boot").Str("prefix", CLI.Prefix).Msg("started http server")
	if err := e.Start(fmt.Sprintf("%s:%d", CLI.Host, CLI.Port)); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal().Err(err).Send()
	}
}

func osStat(name string) (os.FileInfo, error) {
	if CLI.Symlinks {
		return os.Stat(name)
	} else {
		return os.Lstat(name)
	}
}

func osWalk(path string, walkFn filepath.WalkFunc) error {
	if CLI.Symlinks {
		return symwalk.Walk(path, walkFn)
	} else {
		return filepath.Walk(path, walkFn)
	}
}

func errNotFound(c echo.Context) error {
	return c.String(404, "file not found")
}

func errBadRequest(c echo.Context, err error) error {
	return c.String(400, err.Error())
}

var ErrPrefix = errors.New("prefix does not match")

// Handles a directory ZIP download from the frontend.
// The archive can be created with no compression (Store) to avoid any performance impact.
func handleZip(c echo.Context) error {
	requestPath := path.Clean(c.Request().URL.Path)
	// ensure no file in the path is hidden
	if !CLI.Hidden && strings.Contains(requestPath, "/.") {
		return errNotFound(c)
	}
	servePath, err := resolvePath(requestPath)
	if errors.Is(err, ErrPrefix) {
		return errBadRequest(c, err)
	} else if err != nil {
		return err
	}
	if _, err := osStat(servePath); os.IsNotExist(err) {
		return errNotFound(c)
	} else if err != nil {
		return err
	}
	var zipName string
	if requestPath == "/" {
		zipName = "Archive"
	} else {
		zipName = filepath.Base(requestPath)
	}
	c.Response().Header().Set("Content-Disposition", "attachment; filename=\""+zipName+".zip\"")
	zipWriter := zip.NewWriter(c.Response().Writer)
	defer zipWriter.Close()
	if err := osWalk(servePath, func(path string, f fs.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !CLI.Hidden && strings.HasPrefix(f.Name(), ".") {
			if f.IsDir() {
				return filepath.SkipDir
			} else {
				return nil
			}
		}
		if f.IsDir() {
			// no header for directory
			return nil
		}
		header, err := zip.FileInfoHeader(f)
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(filepath.Join(servePath, ".."), path)
		if err != nil {
			return err
		}
		// make the paths consistent between OSes
		header.Name = filepath.ToSlash(rel)
		header.Method = CLI.Level
		headerWriter, err := zipWriter.CreateHeader(header)
		if err != nil {
			return err
		}
		file, err := os.Open(path)
		if err != nil {
			return err
		}
		defer file.Close()
		if _, err := io.Copy(headerWriter, file); err != nil {
			return err
		}
		return nil
	}); err != nil {
		return err
	}
	return nil
}

// Resolves file paths relative to CLI.Root, stripping away CLI.Prefix.
// Prevents any directory traversal attacks.
func resolvePath(unsafePath string) (string, error) {
	unsafePath = filepath.Clean("//" + unsafePath)
	if !strings.HasPrefix(unsafePath, CLI.Prefix) {
		return "", ErrPrefix
	}
	unsafePath = unsafePath[len(CLI.Prefix):]
	newPath := filepath.Join(CLI.Root, filepath.Clean("//"+unsafePath))
	return newPath, nil
}
