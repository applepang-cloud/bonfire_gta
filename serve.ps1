param([int]$Port = 8859, [string]$Root = "build\web")
$ErrorActionPreference = "Stop"
$root = Join-Path $PSScriptRoot $Root
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root on http://localhost:$Port/"
$mime = @{
  ".html"="text/html"; ".css"="text/css"; ".js"="application/javascript";
  ".mjs"="application/javascript"; ".json"="application/json"; ".wasm"="application/wasm";
  ".png"="image/png"; ".ico"="image/x-icon"; ".webp"="image/webp";
  ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"; ".svg"="image/svg+xml";
  ".otf"="font/otf"; ".ttf"="font/ttf"; ".woff"="font/woff"; ".woff2"="font/woff2";
  ".bin"="application/octet-stream"; ".map"="application/json"; ".symbols"="text/plain"
}
try {
  while ($listener.IsListening) {
    try {
      $ctx = $listener.GetContext()
      $path = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
      if ($path -eq "/" -or $path -eq "") {
        # default document: index.html, else island.html (standalone 3D hub)
        if (Test-Path (Join-Path $root "index.html") -PathType Leaf) { $path = "/index.html" }
        elseif (Test-Path (Join-Path $root "island.html") -PathType Leaf) { $path = "/island.html" }
        else { $path = "/index.html" }
      }
      $file = Join-Path $root ($path.TrimStart("/"))
      if (Test-Path $file -PathType Leaf) {
        $bytes = $null
        for ($i = 0; $i -lt 5; $i++) {
          try { $bytes = [System.IO.File]::ReadAllBytes($file); break }
          catch { Start-Sleep -Milliseconds 120 }
        }
        if ($null -eq $bytes) { throw "locked: $file" }
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        $ctx.Response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
        $ctx.Response.ContentLength64 = $bytes.Length
        if ($ctx.Request.HttpMethod -ne "HEAD") {
          $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
      } else {
        $ctx.Response.StatusCode = 404
      }
      $ctx.Response.Close()
    } catch {
      try { $ctx.Response.StatusCode = 500; $ctx.Response.Close() } catch {}
    }
  }
} finally {
  $listener.Stop()
}
