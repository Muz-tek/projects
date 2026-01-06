$Image = "pyspark-demo:latest"

# host app folder -> /app in container
$AppDir = Resolve-Path (Join-Path $PSScriptRoot "..\app")

Write-Host "Running local dev job using image: $Image"
Write-Host "Mounting $($AppDir.Path) -> /app"

# Use the venv python if present, otherwise fall back to python3
$Py = (docker run --rm --entrypoint sh $Image -lc "if [ -x /opt/venv/bin/python ]; then echo /opt/venv/bin/python; else command -v python3; fi" 2>$null).Trim()

if (-not $Py) {
  Write-Host "Could not find /opt/venv/bin/python or python3 inside the image."
  exit 1
}

docker run --rm -it `
  --entrypoint $Py `
  -v "$($AppDir.Path):/app" `
  -w /app `
  $Image /app/job.py
