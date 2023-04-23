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
        <script src="https://kit.fontawesome.com/55eb9c16a8.js"></script>
        <script type="text/javascript">
          <![CDATA[
            document.addEventListener(
              "DOMContentLoaded",
              function () {
                function calculateSize(size) {
                  var sufixes = ["B", "KB", "MB", "GB", "TB"];
                  var output = size;
                  var q = 0;

                  while (size / 1024 > 1) {
                    size = size / 1024;
                    q++;
                  }

                  return Math.round(size * 100) / 100 + " " + sufixes[q];
                }

                if (window.location.pathname == "/") {
                  document.querySelector(".directory.go-up").style.display = "none";
                }

                var path = window.location.pathname.split("/");
                var nav = document.querySelector("nav#breadcrumbs ul");
                var pathSoFar = "/";

                for (var i = 1; i < path.length - 1; i++) {
                  pathSoFar += decodeURI(path[i]) + "/";
                  nav.innerHTML += '<li><a href="' + encodeURI(pathSoFar) + '">' + decodeURI(path[i]) + "</a></li>";
                }

                var mtimes = document.querySelectorAll("table#contents td.mtime a");

                for (var i = 0; i < mtimes.length; i++) {
                  var mtime = mtimes[i].textContent;
                  if (mtime) {
                    var d = new Date(mtime);
                    mtimes[i].textContent = d.toLocaleString();
                  }
                }

                var sizes = document.querySelectorAll("table#contents td.size a");

                for (var i = 0; i < sizes.length; i++) {
                  var size = sizes[i].textContent;
                  if (size) {
                    sizes[i].textContent = calculateSize(parseInt(size));
                  }
                }
              },
              false
            );
          ]]>
        </script>

        <style type="text/css">
          <![CDATA[
            * {
              box-sizing: border-box;
            }
            html {
              margin: 0px;
              padding: 0px;
              height: 100%;
              width: 100%;
            }
            body {
              background-color: #303030;
              font-family: Verdana, Geneva, sans-serif;
              font-size: 14px;
              padding: 20px;
              margin: 0px;
              height: 100%;
              width: 100%;
            }

            table#contents td a {
              text-decoration: none;
              display: block;
              padding: 10px 30px 10px 30px;
              pointer: default;
            }
            table#contents {
              width: 50%;
              margin-left: auto;
              margin-right: auto;
              border-collapse: collapse;
              border-width: 0px;
            }
            table#contents td {
              padding: 0px;
              word-wrap: none;
              white-space: nowrap;
            }
            table#contents td.icon,
            table td.size,
            table td.mtime {
              width: 1px;
              white-space: nowrap;
            }
            table#contents td.icon a {
              padding-left: 0px;
              padding-right: 5px;
            }
            table#contents td.name a {
              padding-left: 5px;
            }
            table#contents td.size a {
              color: #9e9e9e;
            }
            table#contents td.mtime a {
              padding-right: 0px;
              color: #9e9e9e;
            }
            table#contents tr * {
              color: #efefef;
            }
            table#contents tr:hover * {
              color: #c1c1c1 !important;
            }
            table#contents tr.directory td.icon i {
              color: #fbdd7c !important;
            }
            table#contents tr.directory.go-up td.icon i {
              color: #bf8ef3 !important;
            }
            table#contents tr.separator td {
              padding: 10px 30px 10px 30px;
            }
            table#contents tr.separator td hr {
              display: none;
            }

            nav#breadcrumbs {
              margin-bottom: 50px;
              display: flex;
              justify-content: center;
              align-items: center;
            }
            nav#breadcrumbs ul {
              list-style: none;
              display: inline-block;
              margin: 0px;
              padding: 0px;
            }
            nav#breadcrumbs ul .icon {
              font-size: 14px;
            }
            nav#breadcrumbs ul li {
              float: left;
            }
            nav#breadcrumbs ul li a {
              color: #fff;
              display: block;
              background: #515151;
              text-decoration: none;
              position: relative;
              height: 40px;
              line-height: 40px;
              padding: 0 10px 0 5px;
              text-align: center;
              margin-right: 23px;
            }
            nav#breadcrumbs ul li:nth-child(even) a {
              background-color: #525252;
            }
            nav#breadcrumbs ul li:nth-child(even) a:before {
              border-color: #525252;
              border-left-color: transparent;
            }
            nav#breadcrumbs ul li:nth-child(even) a:after {
              border-left-color: #525252;
            }
            nav#breadcrumbs ul li:first-child a {
              padding-left: 15px;
              -moz-border-radius: 4px 0 0 4px;
              -webkit-border-radius: 4px;
              border-radius: 4px 0 0 4px;
            }
            nav#breadcrumbs ul li:first-child a:before {
              border: none;
            }
            nav#breadcrumbs ul li:last-child a {
              padding-right: 15px;
              -moz-border-radius: 0 4px 4px 0;
              -webkit-border-radius: 0;
              border-radius: 0 4px 4px 0;
            }
            nav#breadcrumbs ul li:last-child a:after {
              border: none;
            }
            nav#breadcrumbs ul li a:before,
            nav#breadcrumbs ul li a:after {
              content: "";
              position: absolute;
              top: 0;
              border: 0 solid #515151;
              border-width: 20px 10px;
              width: 0;
              height: 0;
            }
            nav#breadcrumbs ul li a:before {
              left: -20px;
              border-left-color: transparent;
            }
            nav#breadcrumbs ul li a:after {
              left: 100%;
              border-color: transparent;
              border-left-color: #515151;
            }
            nav#breadcrumbs ul li a:hover {
              background-color: #6320aa;
            }
            nav#breadcrumbs ul li a:hover:before {
              border-color: #6320aa;
              border-left-color: transparent;
            }
            nav#breadcrumbs ul li a:hover:after {
              border-left-color: #6320aa;
            }
            nav#breadcrumbs ul li a:active {
              background-color: #330860;
            }
            nav#breadcrumbs ul li a:active:before {
              border-color: #330860;
              border-left-color: transparent;
            }
            nav#breadcrumbs ul li a:active:after {
              border-left-color: #330860;
            }

            div#droparea {
              height: 100%;
              width: 100%;
              border: 5px solid transparent;
              padding: 10px;
            }

            .zip {
              color: #fff;
              background: #515151;
              text-decoration: none;
              height: 40px;
              line-height: 40px;
              padding: 0 15px 0 15px;
              text-align: center;
              -moz-border-radius: 4px;
              -webkit-border-radius: 4px;
              border-radius: 4px;
            }
            .zip:hover {
              background-color: #6320aa;
            }
          ]]>
        </style>
      </head>
      <body>
        <div id="droparea">
          <nav id="breadcrumbs">
            <ul>
              <li>
                <a href="/"><i class="fa fa-home"></i></a>
              </li>
            </ul>
            <a href="?zip=1" data-action="delete" class="fa fa-download zip"></a>
          </nav>
          <table id="contents">
            <tbody>
              <tr class="directory go-up">
                <td class="icon">
                  <a href="../"><i class="fa fa-arrow-up"></i></a>
                </td>
                <td class="name"><a href="../">..</a></td>
                <td class="size"><a href="../"></a></td>
                <td class="mtime"><a href="../"></a></td>
              </tr>

              <xsl:if test="count(directory) != 0">
                <tr class="separator directories">
                  <td colspan="4"><hr /></td>
                </tr>
              </xsl:if>

              <xsl:for-each select="directory">
                <tr class="directory">
                  <td class="icon">
                    <a href="{.}/"><i class="fa fa-folder"></i></a>
                  </td>
                  <td class="name">
                    <a href="{.}/"><xsl:value-of select="." /></a>
                  </td>
                  <td class="size"><a href="{.}/"></a></td>
                  <td class="mtime">
                    <a href="{.}/"><xsl:value-of select="./@mtime" /></a>
                  </td>
                </tr>
              </xsl:for-each>

              <xsl:if test="count(file) != 0">
                <tr class="separator files">
                  <td colspan="4"><hr /></td>
                </tr>
              </xsl:if>

              <xsl:for-each select="file">
                <tr class="file">
                  <td class="icon">
                    <a href="{.}"><i class="fa fa-file"></i></a>
                  </td>
                  <td class="name">
                    <a href="{.}"><xsl:value-of select="." /></a>
                  </td>
                  <td class="size">
                    <a href="{.}"><xsl:value-of select="./@size" /></a>
                  </td>
                  <td class="mtime">
                    <a href="{.}"><xsl:value-of select="./@mtime" /></a>
                  </td>
                </tr>
              </xsl:for-each>
            </tbody>
          </table>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
