package main

import (
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestResolvePath(t *testing.T) {
	// Test cases covering various path traversal attack vectors
	tests := []struct {
		name           string
		rootPath       string
		prefixPath     string
		unsafePath     string
		expectError    bool
		errorMsg       string
		expectedResult string
	}{
		// Basic valid cases
		{
			name:           "Valid simple path",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/index.html",
			expectError:    false,
			expectedResult: "/var/www/index.html",
		},
		{
			name:           "Valid nested path",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/dir/file.txt",
			expectError:    false,
			expectedResult: "/var/www/dir/file.txt",
		},
		{
			name:           "Valid path with prefix",
			rootPath:       "/var/www",
			prefixPath:     "/api/",
			unsafePath:     "/api/data/file.json",
			expectError:    false,
			expectedResult: "/var/www/data/file.json",
		},
		{
			name:           "Root path request",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/",
			expectError:    false,
			expectedResult: "/var/www",
		},

		// Prefix mismatch attacks
		{
			name:        "Prefix mismatch - wrong prefix",
			rootPath:    "/var/www",
			prefixPath:  "/api/",
			unsafePath:  "/wrong/path",
			expectError: true,
			errorMsg:    ErrPrefix.Error(),
		},
		{
			name:        "Prefix mismatch - partial prefix",
			rootPath:    "/var/www",
			prefixPath:  "/api/",
			unsafePath:  "/ap/file.txt",
			expectError: true,
			errorMsg:    ErrPrefix.Error(),
		},
		{
			name:        "Prefix mismatch - empty path",
			rootPath:    "/var/www",
			prefixPath:  "/api/",
			unsafePath:  "",
			expectError: true,
			errorMsg:    ErrPrefix.Error(),
		},

		// Classic directory traversal attacks
		{
			name:        "Classic dot-dot traversal",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/../../../etc/passwd",
			expectError: true,
		},
		{
			name:        "Multiple dot-dot traversal",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/../../../../../../../../etc/passwd",
			expectError: true,
		},
		{
			name:        "Dot-dot in middle of path",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/dir/../../../etc/passwd",
			expectError: true,
		},
		{
			name:        "Mixed valid and traversal",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/valid/dir/../../../../../../etc/passwd",
			expectError: true,
		},

		// URL encoding attacks
		{
			name:           "URL encoded dot-dot (%2e%2e)",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/%2e%2e/%2e%2e/etc/passwd",
			expectError:    false,
			expectedResult: "/var/www/%2e%2e/%2e%2e/etc/passwd",
		},
		{
			name:           "URL encoded slash (%2f)",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/..%2f..%2fetc%2fpasswd",
			expectError:    false,
			expectedResult: "/var/www/..%2f..%2fetc%2fpasswd",
		},
		{
			name:           "Double URL encoding (%252e%252e)",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/%252e%252e/%252e%252e/etc/passwd",
			expectError:    false,
			expectedResult: "/var/www/%252e%252e/%252e%252e/etc/passwd",
		},
		{
			name:           "Mixed encoding",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/%2e%2e/..%2fetc/passwd",
			expectError:    false,
			expectedResult: "/var/www/%2e%2e/..%2fetc/passwd",
		},

		// Unicode and alternative encoding attacks
		{
			name:        "Unicode dot (U+002E)",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/\u002e\u002e/\u002e\u002e/etc/passwd",
			expectError: true,
		},
		{
			name:           "Overlong UTF-8 encoding",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/%c0%ae%c0%ae/%c0%ae%c0%ae/etc/passwd",
			expectError:    false,
			expectedResult: "/var/www/%c0%ae%c0%ae/%c0%ae%c0%ae/etc/passwd",
		},

		// Null byte injection attacks
		{
			name:        "Null byte injection",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/valid\x00/../../../etc/passwd",
			expectError: true,
		},
		{
			name:        "URL encoded null byte",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/valid%00/../../../etc/passwd",
			expectError: true,
		},

		// Backslash attacks (Windows-style)
		{
			name:           "Backslash traversal",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/..\\..\\..\\etc\\passwd",
			expectError:    false,
			expectedResult: "/var/www/..\\..\\..\\etc\\passwd",
		},
		{
			name:        "Mixed slash types",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/../..\\../etc/passwd",
			expectError: true,
		},

		// Absolute path attacks
		{
			name:        "Absolute path attack",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "//etc/passwd",
			expectError: true,
		},
		{
			name:        "UNC path attack",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "//server/share/file",
			expectError: true,
		},

		// Edge cases with dots
		{
			name:        "Single dot",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/./file.txt",
			expectError: true,
		},
		{
			name:        "Multiple single dots",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/./././file.txt",
			expectError: true,
		},
		{
			name:        "Dot-dot at end",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/dir/..",
			expectError: true,
		},

		// Long path attacks
		{
			name:        "Very long traversal path",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/" + strings.Repeat("../", 100) + "etc/passwd",
			expectError: true,
		},

		// Case sensitivity attacks
		{
			name:        "Mixed case traversal",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "/../.././../ETC/PASSWD",
			expectError: true,
		},

		// Space and special character attacks
		{
			name:           "Spaces in traversal",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/ .. / .. /etc/passwd",
			expectError:    false,
			expectedResult: "/var/www/ .. / .. /etc/passwd",
		},
		{
			name:           "Tab characters",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/\t..\t/\t..\t/etc/passwd",
			expectError:    false,
			expectedResult: "/var/www/\t..\t/\t..\t/etc/passwd",
		},

		// Prefix bypass attempts
		{
			name:        "Prefix bypass with traversal",
			rootPath:    "/var/www",
			prefixPath:  "/api/",
			unsafePath:  "/api/../../../etc/passwd",
			expectError: true,
		},
		{
			name:           "Prefix bypass with encoding",
			rootPath:       "/var/www",
			prefixPath:     "/api/",
			unsafePath:     "/api/%2e%2e/%2e%2e/etc/passwd",
			expectError:    false,
			expectedResult: "/var/www/%2e%2e/%2e%2e/etc/passwd",
		},

		// Complex nested attacks
		{
			name:        "Nested directory with traversal",
			rootPath:    "/var/www",
			prefixPath:  "/app/static/",
			unsafePath:  "/app/static/css/../../../../../../etc/passwd",
			expectError: true,
		},

		// Windows-specific attacks (should still be blocked on Unix)
		{
			name:           "Windows drive letter",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/C:/Windows/System32/config/sam",
			expectedResult: "/var/www/C:/Windows/System32/config/sam",
		},
		{
			name:           "Windows UNC path",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/\\\\server\\share\\file",
			expectedResult: "/var/www/\\\\server\\share\\file",
		},

		// Alternative representations
		{
			name:           "Hex encoded dots",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/\\x2e\\x2e/\\x2e\\x2e/etc/passwd",
			expectError:    false,
			expectedResult: "/var/www/\\x2e\\x2e/\\x2e\\x2e/etc/passwd",
		},

		// Combination attacks
		{
			name:           "Multiple encoding types",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/%2e%2e\\../%2e%2e/etc/passwd",
			expectError:    false,
			expectedResult: "/var/www/%2e%2e\\../%2e%2e/etc/passwd",
		},

		// Edge cases with empty components
		{
			name:        "Double slashes",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "//dir//file.txt",
			expectError: true,
		},
		{
			name:        "Triple slashes",
			rootPath:    "/var/www",
			prefixPath:  "/",
			unsafePath:  "///dir///file.txt",
			expectError: true,
		},

		// Symlink-related edge cases (path construction)
		{
			name:           "Path with symlink-like name",
			rootPath:       "/var/www",
			prefixPath:     "/",
			unsafePath:     "/symlink/file.txt",
			expectError:    false,
			expectedResult: "/var/www/symlink/file.txt",
		},

		// Edge cases
		{
			name:           "Empty root path",
			rootPath:       "",
			prefixPath:     "/",
			unsafePath:     "/file.txt",
			expectedResult: "file.txt",
		},
		{
			name:           "Root path with trailing slash",
			rootPath:       "/var/www/",
			prefixPath:     "/",
			unsafePath:     "/file.txt",
			expectedResult: "/var/www/file.txt",
		},
		{
			name:           "Complex prefix",
			rootPath:       "/var/www",
			prefixPath:     "/api/v1/files/",
			unsafePath:     "/api/v1/files/document.pdf",
			expectedResult: "/var/www/document.pdf",
		},
		{
			name:        "Prefix without trailing slash",
			rootPath:    "/var/www",
			prefixPath:  "/api",
			unsafePath:  "/api/file.txt",
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := resolvePath(tt.rootPath, tt.prefixPath, tt.unsafePath)

			if tt.expectError {
				if err == nil {
					t.Errorf("Expected error but got none. Result: %s", result)
					return
				}
				if tt.errorMsg != "" && !strings.Contains(err.Error(), tt.errorMsg) {
					t.Errorf("Expected error message to contain '%s', got: %s", tt.errorMsg, err.Error())
				}
				// For traversal attacks, ensure the result doesn't escape the root
				if result != "" && !strings.HasPrefix(result, tt.rootPath) {
					t.Errorf("Path traversal detected! Result '%s' escapes root '%s'", result, tt.rootPath)
				}
			} else {
				if err != nil {
					t.Errorf("Unexpected error: %v", err)
					return
				}
				// Normalize paths for comparison (handle OS differences)
				expectedNorm := filepath.Clean(tt.expectedResult)
				resultNorm := filepath.Clean(result)
				if expectedNorm != resultNorm {
					t.Errorf("Expected result '%s', got '%s'", expectedNorm, resultNorm)
				}
				// Ensure result is within root path
				if !strings.HasPrefix(result, tt.rootPath) {
					t.Errorf("Result '%s' is not within root path '%s'", result, tt.rootPath)
				}
			}
		})
	}
}

// Test that demonstrates the function's behavior with OS-specific paths
func TestResolvePathOSSpecific(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Run("Windows paths", func(t *testing.T) {
			// Test Windows-specific path handling
			result, err := resolvePath("C:\\www", "/", "/file.txt")
			if err != nil {
				t.Errorf("Unexpected error on Windows: %v", err)
			}
			if !strings.Contains(result, "C:") {
				t.Errorf("Expected Windows path format, got: %s", result)
			}
		})
	} else {
		t.Run("Unix paths", func(t *testing.T) {
			// Test Unix-specific path handling
			result, err := resolvePath("/var/www", "/", "/file.txt")
			if err != nil {
				t.Errorf("Unexpected error on Unix: %v", err)
			}
			if !strings.HasPrefix(result, "/var/www") {
				t.Errorf("Expected Unix path format, got: %s", result)
			}
		})
	}
}

// Fuzz test to catch edge cases
func FuzzResolvePath(f *testing.F) {
	// Seed with some known inputs
	f.Add("/var/www", "/", "/index.html")
	f.Add("/var/www", "/api/", "/api/data.json")
	f.Add("/var/www", "/", "/../../../etc/passwd")
	f.Add("/var/www", "/", "/%2e%2e/%2e%2e/etc/passwd")

	f.Fuzz(func(t *testing.T, rootPath, prefixPath, unsafePath string) {
		result, err := resolvePath(rootPath, prefixPath, unsafePath)

		// If no error occurred, ensure the result doesn't escape the root
		if err == nil && rootPath != "" {
			// Clean the root path for comparison
			cleanRoot := filepath.Clean(rootPath)
			cleanResult := filepath.Clean(result)

			// Check if result is within root (allowing for relative roots)
			if filepath.IsAbs(cleanRoot) && filepath.IsAbs(cleanResult) {
				if !strings.HasPrefix(cleanResult, cleanRoot) {
					t.Errorf("Path traversal detected! Result '%s' escapes root '%s'", cleanResult, cleanRoot)
				}
			}
		}
	})
}
