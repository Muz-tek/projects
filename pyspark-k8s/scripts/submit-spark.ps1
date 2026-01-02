$Name = "pyspark-demo"
$Ns   = "default"
$Yaml = "k8s/spark-application.yaml"

Write-Host "Deleting SparkApplication (ignore if not found): $Name"
kubectl delete sparkapplication.sparkoperator.k8s.io $Name -n $Ns --ignore-not-found | Out-Null

Write-Host "Applying: $Yaml"
kubectl apply -f $Yaml -n $Ns

# prevents the “wait forever” behaviour when the webhook blocks creation
kubectl apply -f $Yaml -n $Ns
if ($LASTEXITCODE -ne 0) { throw "kubectl apply failed" }

Write-Host "Waiting for driver pod to appear..."
$driver = $null

# Wait up to 5 minutes
for ($i = 0; $i -lt 150; $i++) {
  # Spark Operator labels driver pods with spark-role=driver and spark-app-selector=<appName>
  $driver = kubectl get pods -n $Ns `
    -l "spark-role=driver,spark-app-selector=$Name" `
    -o jsonpath="{.items[0].metadata.name}" 2>$null

  if ($driver) { break }
  Start-Sleep -Seconds 2
}

if (-not $driver) {
  Write-Host "Driver pod not found after waiting. Showing SparkApplication details:"
  kubectl describe sparkapplication.sparkoperator.k8s.io $Name -n $Ns
  Write-Host "`nRecent events:"
  kubectl get events -n $Ns --sort-by=.lastTimestamp | Select-Object -Last 30
  exit 1
}

Write-Host "Driver pod: $driver"
Write-Host "Streaming logs..."
kubectl logs -f -n $Ns $driver
