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
	"path/filepath"
	"strings"
)

var CLI struct {
	Symlinks bool   `help:"Follow symlinks."`
	Hidden   bool   `help:"Serve files and directories that start with dot."`
	Level    uint16 `help:"ZIP compression level (0/store - 9/highest)." default:"0"`
	Prefix   string `help:"URL prefix when calling this server." default:"/" type:"path"`
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

	if strings.TrimSpace(CLI.Prefix) == "" {
		log.Fatal().Msg("prefix cannot be empty")
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

	log.Info().Str("state", "started http server").Send()
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

// Handles a directory ZIP download from the frontend.
// The archive can be created with no compression (Store) to avoid any performance impact.
func handleZip(c echo.Context) error {
	zipFullPath := resolvePath(c.Request().URL.Path)
	zipName := filepath.Base(zipFullPath)
	if _, err := osStat(zipFullPath); os.IsNotExist(err) {
		return c.String(404, "error")
	} else if err != nil {
		return err
	}
	c.Response().Header().Set("Content-Disposition", "attachment; filename=\""+zipName+".zip\"")
	zipWriter := zip.NewWriter(c.Response().Writer)
	defer zipWriter.Close()
	if err := osWalk(zipFullPath, func(path string, f fs.FileInfo, err error) error {
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
		header, err := zip.FileInfoHeader(f)
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(filepath.Join(zipFullPath, ".."), path)
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
		if f.IsDir() {
			// no data needs to be written to directory
			return nil
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

// Resolves file paths relative to the CLI.Root path, stripping away the CLI.Prefix path.
// Prevents any directory traversal attacks.
func resolvePath(unsafePath string) string {
	unsafePath, err := filepath.Rel(CLI.Prefix, filepath.Clean("//"+unsafePath))
	if err != nil {
		log.Fatal().Str("path", unsafePath).Err(err).Msg("failed to resolve path")
	}
	newPath := filepath.Join(CLI.Root, filepath.Clean("//"+unsafePath))
	return newPath
}
