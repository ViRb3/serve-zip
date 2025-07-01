<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:D="DAV:" exclude-result-prefixes="D">
  <xsl:output method="html" encoding="UTF-8" />

  <xsl:template match="D:multistatus">
    <xsl:text disable-output-escaping="yes">&lt;?xml version="1.0" encoding="utf-8" ?&gt;</xsl:text>
    <D:multistatus xmlns:D="DAV:">
      <xsl:copy-of select="*"/>
    </D:multistatus>
  </xsl:template>
  
  <xsl:template match="/list">
    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>

    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
        <meta charset="UTF-8" />
        <title>Directory Index</title>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" />
        
        <style type="text/css">
          <![CDATA[
            :root {
              --bg-primary: #ffffff;
              --bg-secondary: #f8f9fa;
              --bg-hover: #e9ecef;
              --text-primary: #212529;
              --text-secondary: #6c757d;
              --text-muted: #adb5bd;
              --border-color: #dee2e6;
              --accent-color: #0d6efd;
              --accent-hover: #0b5ed7;
              --shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
              --shadow-hover: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
            }

            [data-theme="dark"] {
              --bg-primary: #1a1a1a;
              --bg-secondary: #2d2d2d;
              --bg-hover: #404040;
              --text-primary: #ffffff;
              --text-secondary: #b3b3b3;
              --text-muted: #808080;
              --border-color: #404040;
              --accent-color: #4dabf7;
              --accent-hover: #339af0;
              --shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.3);
              --shadow-hover: 0 0.5rem 1rem rgba(0, 0, 0, 0.4);
            }

            * {
              box-sizing: border-box;
              margin: 0;
              padding: 0;
            }

            html {
              font-size: 16px;
              line-height: 1.5;
            }

            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
              background-color: var(--bg-primary);
              color: var(--text-primary);
              transition: background-color 0.3s ease, color 0.3s ease;
              min-height: 100vh;
            }

            .container {
              max-width: 1200px;
              margin: 0 auto;
              padding: 1rem;
            }

            /* Header */
            .header {
              display: flex;
              justify-content: space-between;
              align-items: center;
              margin-bottom: 2rem;
              padding: 1rem 0;
              border-bottom: 1px solid var(--border-color);
              flex-wrap: wrap;
              gap: 1rem;
            }

            .breadcrumbs {
              display: flex;
              align-items: center;
              flex-wrap: wrap;
              gap: 0.5rem;
              flex: 1;
              min-width: 0;
            }

            .breadcrumb-item {
              display: flex;
              align-items: center;
              gap: 0.5rem;
            }

            .breadcrumb-item a {
              color: var(--accent-color);
              text-decoration: none;
              padding: 0.25rem 0.5rem;
              border-radius: 0.25rem;
              transition: all 0.2s ease;
              word-break: break-all;
            }

            .breadcrumb-item a:hover {
              background-color: var(--bg-hover);
              color: var(--accent-hover);
            }

            .breadcrumb-separator {
              color: var(--text-muted);
              font-size: 0.875rem;
            }

            .header-actions {
              display: flex;
              align-items: center;
              gap: 0.75rem;
              flex-shrink: 0;
            }

            .search-container {
              position: relative;
              display: flex;
              align-items: center;
            }

            .search-input {
              background: var(--bg-secondary);
              border: 1px solid var(--border-color);
              color: var(--text-primary);
              padding: 0.5rem 2.5rem 0.5rem 0.75rem;
              border-radius: 0.375rem;
              font-size: 1rem;
              width: 200px;
              transition: all 0.2s ease;
            }

            .search-input:focus {
              outline: 2px solid var(--accent-color);
              outline-offset: 2px;
              border-color: var(--accent-color);
              box-shadow: var(--shadow);
            }

            .search-input::placeholder {
              color: var(--text-muted);
            }

            .search-icon {
              position: absolute;
              right: 0.75rem;
              color: var(--text-muted);
              pointer-events: none;
            }

            .search-clear {
              position: absolute;
              right: 0.75rem;
              color: var(--text-muted);
              cursor: pointer;
              padding: 0.25rem;
              border-radius: 0.25rem;
              transition: all 0.2s ease;
              display: none;
            }

            .search-clear:hover {
              color: var(--text-primary);
              background-color: var(--bg-hover);
            }

            .search-clear.visible {
              display: block;
            }

            .search-icon.hidden {
              display: none;
            }

            .theme-toggle {
              background: var(--bg-secondary);
              border: 1px solid var(--border-color);
              color: var(--text-primary);
              padding: 0.5rem;
              border-radius: 0.375rem;
              cursor: pointer;
              transition: all 0.2s ease;
              display: flex;
              align-items: center;
              justify-content: center;
              width: 2.5rem;
              height: 2.5rem;
              position: relative;
            }

            .theme-toggle:hover {
              background-color: var(--bg-hover);
              box-shadow: var(--shadow);
            }

            .theme-toggle::after {
              content: attr(data-theme-label);
              position: absolute;
              bottom: -1.5rem;
              left: 50%;
              transform: translateX(-50%);
              font-size: 0.625rem;
              color: var(--text-muted);
              white-space: nowrap;
              opacity: 0;
              transition: opacity 0.2s ease;
            }

            .theme-toggle:hover::after {
              opacity: 1;
            }

            .download-zip {
              background: var(--accent-color);
              color: white;
              text-decoration: none;
              padding: 0.5rem;
              border-radius: 0.375rem;
              transition: all 0.2s ease;
              display: flex;
              align-items: center;
              justify-content: center;
              font-weight: 500;
              white-space: nowrap;
              width: 2.5rem;
              height: 2.5rem;
            }

            .download-zip:hover {
              background: var(--accent-hover);
              box-shadow: var(--shadow-hover);
              transform: translateY(-1px);
            }

            /* File list */
            .file-list {
              background: var(--bg-secondary);
              border-radius: 0.5rem;
              overflow: hidden;
              box-shadow: var(--shadow);
            }

            .file-item {
              display: flex;
              align-items: center;
              padding: 0.75rem 1rem;
              border-bottom: 1px solid var(--border-color);
              transition: all 0.2s ease;
              text-decoration: none;
              color: inherit;
              min-height: 3rem;
            }

            .file-item:last-child {
              border-bottom: none;
            }

            .file-item:hover {
              background-color: var(--bg-hover);
              transform: translateX(2px);
            }

            .file-item:active {
              transform: translateX(1px);
            }

            .file-item.hidden {
              display: none;
            }

            .no-results {
              text-align: center;
              padding: 2rem;
              color: var(--text-muted);
              font-style: italic;
              display: none;
            }

            .no-results.visible {
              display: block;
            }

            .file-icon {
              flex-shrink: 0;
              width: 1.5rem;
              height: 1.5rem;
              display: flex;
              align-items: center;
              justify-content: center;
              margin-right: 0.75rem;
              font-size: 1rem;
            }

            .file-icon.directory {
              color: #fbbf24;
            }

            .file-icon.go-up {
              color: #8b5cf6;
            }

            .file-icon.file {
              color: var(--text-secondary);
            }

            .file-info {
              flex: 1;
              min-width: 0;
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 1rem;
            }

            .file-name {
              flex: 1;
              min-width: 0;
              font-weight: 500;
              word-wrap: break-word;
              overflow-wrap: break-word;
              hyphens: auto;
            }

            .file-meta {
              display: flex;
              align-items: center;
              gap: 1rem;
              flex-shrink: 0;
              color: var(--text-secondary);
              font-size: 0.875rem;
            }

            .file-size {
              text-align: right;
            }

            .file-date {
              min-width: 6rem;
              text-align: right;
            }

            /* Responsive design */
            @media (max-width: 768px) {
              .container {
                padding: 0.5rem;
              }

              .header {
                flex-direction: row;
                flex-wrap: wrap;
                align-items: center;
                gap: 0.75rem;
              }

              .breadcrumbs {
                flex: 1;
                min-width: 0;
                justify-content: flex-start;
              }

              .header-actions {
                flex-shrink: 0;
                gap: 0.75rem;
              }

              .file-meta {
                justify-content: space-between;
                font-size: 0.8125rem;
              }

              .file-size {
                text-align: right;
              }

              .file-date {
                min-width: 5rem;
                text-align: right;
              }
            }

            @media (max-width: 640px) {
              .header {
                gap: 0.5rem;
              }

              .search-input {
                width: 160px;
              }
            }

            @media (max-width: 480px) {
              .header {
                justify-content: space-between;
                gap: 0.5rem;
              }

              .breadcrumbs {
                flex: 1;
                min-width: 0;
              }

              .header-actions {
                gap: 0.5rem;
              }

              .search-input {
                width: 120px;
              }

              .file-meta {
                flex-direction: column;
                align-items: stretch;
                gap: 0.25rem;
              }
            }

            /* Dark mode auto-detection */
            @media (prefers-color-scheme: dark) {
              :root:not([data-theme="light"]) {
                --bg-primary: #1a1a1a;
                --bg-secondary: #2d2d2d;
                --bg-hover: #404040;
                --text-primary: #ffffff;
                --text-secondary: #b3b3b3;
                --text-muted: #808080;
                --border-color: #404040;
                --accent-color: #4dabf7;
                --accent-hover: #339af0;
                --shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.3);
                --shadow-hover: 0 0.5rem 1rem rgba(0, 0, 0, 0.4);
              }
            }

            /* Loading animation */
            .loading {
              opacity: 0.7;
              pointer-events: none;
            }

            /* Focus styles for accessibility */
            .theme-toggle:focus,
            .download-zip:focus,
            .file-item:focus,
            .breadcrumb-item a:focus {
              outline: 2px solid var(--accent-color);
              outline-offset: 2px;
            }
          ]]>
        </style>

        <script type="text/javascript">
          <![CDATA[
            // Apply theme immediately to prevent flash
            (function() {
              const savedTheme = localStorage.getItem('theme') || 'auto';
              const html = document.documentElement;
              
              if (savedTheme === 'auto') {
                html.removeAttribute('data-theme');
              } else {
                html.setAttribute('data-theme', savedTheme);
              }
            })();

            document.addEventListener('DOMContentLoaded', function() {
              // Update page title with current path
              const currentPath = window.location.pathname;
              const decodedPath = decodeURIComponent(currentPath);
              document.title = 'Index of ' + (decodedPath === '/' ? '/' : decodedPath);

              // Theme management
              const themeToggle = document.getElementById('theme-toggle');
              const html = document.documentElement;
              
              // Theme states: auto, light, dark
              const themeStates = ['auto', 'light', 'dark'];
              
              // Get saved theme preference
              const savedTheme = localStorage.getItem('theme') || 'auto';
              let currentThemeIndex = themeStates.indexOf(savedTheme);
              if (currentThemeIndex === -1) currentThemeIndex = 0; // fallback to auto
              
              // Apply initial theme
              applyTheme(themeStates[currentThemeIndex]);
              
              // Theme toggle handler - cycles through auto -> light -> dark -> auto
              themeToggle.addEventListener('click', function() {
                currentThemeIndex = (currentThemeIndex + 1) % themeStates.length;
                const newTheme = themeStates[currentThemeIndex];
                applyTheme(newTheme);
                
                if (newTheme === 'auto') {
                  localStorage.removeItem('theme');
                } else {
                  localStorage.setItem('theme', newTheme);
                }
              });
              
              function applyTheme(themeMode) {
                if (themeMode === 'auto') {
                  // Remove data-theme attribute to use CSS media query
                  html.removeAttribute('data-theme');
                  updateThemeIcon('auto');
                } else {
                  html.setAttribute('data-theme', themeMode);
                  updateThemeIcon(themeMode);
                }
              }
              
              function updateThemeIcon(themeMode) {
                const icon = themeToggle.querySelector('i');
                let iconClass, label;
                
                switch(themeMode) {
                  case 'auto':
                    iconClass = 'fas fa-circle-half-stroke';
                    label = 'Auto';
                    break;
                  case 'light':
                    iconClass = 'fas fa-sun';
                    label = 'Light';
                    break;
                  case 'dark':
                    iconClass = 'fas fa-moon';
                    label = 'Dark';
                    break;
                }
                
                icon.className = iconClass;
                themeToggle.setAttribute('data-theme-label', label);
                themeToggle.setAttribute('title', `Theme: ${label} (click to cycle)`);
              }
              
              // Listen for system theme changes when in auto mode
              window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
                // Only react to system changes if we're in auto mode
                if (!localStorage.getItem('theme')) {
                  // Theme will automatically update via CSS media query
                  // No need to manually set anything
                }
              });

              // File processing
              function calculateSize(size) {
                const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
                let output = size;
                let q = 0;

                while (size / 1024 > 1) {
                  size = size / 1024;
                  q++;
                }

                return Math.round(size * 100) / 100 + ' ' + suffixes[q];
              }

              // Hide go-up link if at root
              if (window.location.pathname === '/') {
                const goUpElement = document.querySelector('.file-item.go-up');
                if (goUpElement) {
                  goUpElement.style.display = 'none';
                }
              }

              // Build breadcrumbs
              const path = window.location.pathname.split('/');
              const breadcrumbsContainer = document.querySelector('.breadcrumbs');
              let pathSoFar = '/';

              for (let i = 1; i < path.length - 1; i++) {
                if (path[i]) {
                  pathSoFar += decodeURI(path[i]) + '/';
                  
                  const separator = document.createElement('span');
                  separator.className = 'breadcrumb-separator';
                  separator.innerHTML = '<i class="fas fa-chevron-right"></i>';
                  breadcrumbsContainer.appendChild(separator);
                  
                  const breadcrumbItem = document.createElement('div');
                  breadcrumbItem.className = 'breadcrumb-item';
                  breadcrumbItem.innerHTML = '<a href="' + encodeURI(pathSoFar) + '">' + decodeURI(path[i]) + '</a>';
                  breadcrumbsContainer.appendChild(breadcrumbItem);
                }
              }

              // Process file dates
              const dateElements = document.querySelectorAll('.file-date');
              dateElements.forEach(function(element) {
                const mtime = element.textContent.trim();
                if (mtime) {
                  const date = new Date(mtime);
                  if (!isNaN(date.getTime())) {
                    element.textContent = date.toLocaleDateString();
                  }
                }
              });

              // Process file sizes
              const sizeElements = document.querySelectorAll('.file-size');
              sizeElements.forEach(function(element) {
                const size = element.textContent.trim();
                if (size && !isNaN(parseInt(size))) {
                  element.textContent = calculateSize(parseInt(size));
                }
              });

              // Fix URL encoding for links
              const outLinks = document.querySelectorAll('.out-link');
              outLinks.forEach(function(link) {
                link.href = encodeURI(decodeURI(link.href));
              });

              // Search functionality
              const searchInput = document.getElementById('search-input');
              const searchIcon = document.querySelector('.search-icon');
              const searchClear = document.querySelector('.search-clear');
              const fileItems = document.querySelectorAll('.file-item:not(.go-up)');
              const noResults = document.querySelector('.no-results');

              function performSearch() {
                const searchTerm = searchInput.value.toLowerCase().trim();
                let visibleCount = 0;

                // Show/hide clear button and search icon
                if (searchTerm) {
                  searchClear.classList.add('visible');
                  searchIcon.classList.add('hidden');
                } else {
                  searchClear.classList.remove('visible');
                  searchIcon.classList.remove('hidden');
                }

                // Filter file items
                fileItems.forEach(function(item) {
                  const fileName = item.querySelector('.file-name').textContent.toLowerCase();
                  const matches = fileName.includes(searchTerm);
                  
                  if (matches || !searchTerm) {
                    item.classList.remove('hidden');
                    visibleCount++;
                  } else {
                    item.classList.add('hidden');
                  }
                });

                // Show/hide no results message
                if (searchTerm && visibleCount === 0) {
                  noResults.classList.add('visible');
                } else {
                  noResults.classList.remove('visible');
                }
              }

              // Search input event listeners
              searchInput.addEventListener('input', performSearch);
              searchInput.addEventListener('keyup', performSearch);

              // Clear search functionality
              searchClear.addEventListener('click', function() {
                searchInput.value = '';
                searchInput.focus();
                performSearch();
              });

              // Clear search on Escape key
              searchInput.addEventListener('keydown', function(e) {
                if (e.key === 'Escape') {
                  searchInput.value = '';
                  performSearch();
                  searchInput.blur();
                }
              });
            });
          ]]>
        </script>
      </head>
      
      <body>
        <div class="container">
          <header class="header">
            <nav class="breadcrumbs">
              <div class="breadcrumb-item">
                <a href="/"><i class="fas fa-home"></i></a>
              </div>
            </nav>
            
            <div class="header-actions">
              <div class="search-container">
                <input 
                  type="text" 
                  id="search-input" 
                  class="search-input" 
                  placeholder="Search..."
                  autocomplete="off"
                  spellcheck="false"
                />
                <i class="fas fa-search search-icon"></i>
                <i class="fas fa-times search-clear" title="Clear search"></i>
              </div>
              <button id="theme-toggle" class="theme-toggle" title="Theme: Auto (click to cycle)" data-theme-label="Auto">
                <i class="fas fa-circle-half-stroke"></i>
              </button>
              <a href="?zip=1" class="download-zip" title="Download as ZIP">
                <i class="fas fa-download"></i>
              </a>
            </div>
          </header>

          <div class="file-list">
            <div class="no-results">
              <i class="fas fa-search" style="font-size: 2rem; margin-bottom: 0.5rem; opacity: 0.5;"></i>
              <div>No files match your search</div>
            </div>
            
            <a href="../" class="file-item go-up">
              <div class="file-icon go-up">
                <i class="fas fa-arrow-up"></i>
              </div>
              <div class="file-info">
                <div class="file-name">..</div>
                <div class="file-meta">
                  <span class="file-size"></span>
                  <span class="file-date"></span>
                </div>
              </div>
            </a>

            <xsl:for-each select="directory">
              <a href="{.}/" class="file-item out-link">
                <div class="file-icon directory">
                  <i class="fas fa-folder"></i>
                </div>
                <div class="file-info">
                  <div class="file-name"><xsl:value-of select="." /></div>
                  <div class="file-meta">
                    <span class="file-size">—</span>
                    <span class="file-date"><xsl:value-of select="./@mtime" /></span>
                  </div>
                </div>
              </a>
            </xsl:for-each>

            <xsl:for-each select="file">
              <a href="{.}" class="file-item out-link">
                <div class="file-icon file">
                  <i class="fas fa-file"></i>
                </div>
                <div class="file-info">
                  <div class="file-name"><xsl:value-of select="." /></div>
                  <div class="file-meta">
                    <span class="file-size"><xsl:value-of select="./@size" /></span>
                    <span class="file-date"><xsl:value-of select="./@mtime" /></span>
                  </div>
                </div>
              </a>
            </xsl:for-each>
          </div>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
