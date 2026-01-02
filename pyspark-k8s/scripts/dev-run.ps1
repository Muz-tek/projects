param(
  [string]$Image = "pyspark-demo:latest"
)

$appPath = (Resolve-Path ".\app").Path

Write-Host "Running local dev job using image: $Image"
Write-Host "Mounting $appPath -> /app"

docker run --rm -it `
  -v "${appPath}:/app" `
  $Image `
  python /app/job.py


# powershell -ExecutionPolicy Bypass -File scripts\dev-run.ps1