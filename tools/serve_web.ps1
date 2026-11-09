param([string]$Root, [int]$Port = 8060)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()
$types = @{
  ".html" = "text/html"; ".js" = "application/javascript"; ".wasm" = "application/wasm"; ".pck" = "application/octet-stream";
  ".png" = "image/png"; ".svg" = "image/svg+xml"; ".json" = "application/json"; ".css" = "text/css"; ".ico" = "image/x-icon"
}
while ($listener.IsListening) {
  $context = $listener.GetContext()
  $request = $context.Request
  $response = $context.Response
  try {
    $path = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath.TrimStart("/"))
    if ($path -eq "") { $path = "index.html" }
    $file = Join-Path $Root $path
    $response.Headers.Add("Cross-Origin-Opener-Policy", "same-origin")
    $response.Headers.Add("Cross-Origin-Embedder-Policy", "require-corp")
    $response.Headers.Add("Cache-Control", "no-store")
    if (Test-Path $file -PathType Leaf) {
      $extension = [System.IO.Path]::GetExtension($file).ToLower()
      $response.ContentType = if ($types.ContainsKey($extension)) { $types[$extension] } else { "application/octet-stream" }
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $response.ContentLength64 = $bytes.Length
      $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $response.StatusCode = 404
    }
  } catch {
    $response.StatusCode = 500
  } finally {
    $response.OutputStream.Close()
  }
}
