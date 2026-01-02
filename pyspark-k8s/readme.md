# PySpark on Docker Desktop Kubernetes (Spark Operator)

**What this is:** A minimal, repeatable setup to run a **PySpark** job on **Docker Desktop’s Kubernetes** using the **Kubeflow Spark Operator**.  
**How it runs:** You build a local Docker image (`pyspark-demo:latest`), install the operator + CRDs, apply RBAC, then submit a `SparkApplication` that creates driver/executor pods and streams logs.

## Prereqs
**What this covers:** Tools you need installed/enabled before anything will work.

- Docker Desktop with **Kubernetes enabled**: provides the cluster you deploy into.
- `kubectl`: CLI to apply YAML and inspect pods/logs.
- `helm`: installs the Spark Operator (and its webhook) cleanly.
- PowerShell: matches the scripts/commands in this repo.

Verify:
```powershell
kubectl config current-context
helm version
kubectl get nodes
```
**Why these checks matter:**
- `current-context` should be `docker-desktop` (so you target the right cluster).
- `helm version` confirms Helm is usable in this terminal/session.
- `get nodes` confirms the cluster is up.

## Repo
**What this shows:** The key files and where they live.

```
app/job.py                     # Your PySpark script that Spark runs
k8s/spark-application.yaml      # SparkApplication resource submitted to the operator
k8s/spark-rbac.yaml             # ServiceAccount/Role/RoleBinding used by driver/executors
scripts/submit-spark.ps1        # Delete+apply SparkApplication, wait for driver, stream logs
scripts/dev-run.ps1             # Local/dev run (no Kubernetes) for fast iteration
Dockerfile                      # Builds the image containing Python + your job
requirements.txt                # Python deps used in the image
```

## 1) Build the image
**What this does:** Produces the container image Kubernetes will run for driver/executors.

From repo root:
```powershell
docker build -t pyspark-demo:latest -f Dockerfile .
docker images | findstr pyspark-demo
```
**Why it matters:** Your `SparkApplication` references `image: pyspark-demo:latest`. If the image doesn’t exist locally (or isn’t available to the cluster), pods won’t start.

## 2) Install Spark Operator (Kubeflow)
**What this does:** Installs the Spark Operator + CRDs + webhook admission controller.

```powershell
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update

helm install spark-operator spark-operator/spark-operator `
  -n spark-operator --create-namespace `
  --set "spark.jobNamespaces={default}"

kubectl get pods -n spark-operator -w
```

**Key points:**
- `spark.jobNamespaces={default}` tells the operator to watch the `default` namespace for SparkApplications.
- Wait until **controller** and **webhook** are `1/1 Running` before submitting jobs (otherwise you can hit webhook “connection refused”).

Confirm CRDs:
```powershell
kubectl api-resources | findstr /i sparkapplication
```
**Why this matters:** If CRDs aren’t present, Kubernetes can’t understand `kind: SparkApplication`.

## 3) RBAC (default namespace)
**What this does:** Creates the permissions Spark driver/executors need inside the cluster (via your `spark-sa`).

```powershell
kubectl apply -f k8s/spark-rbac.yaml
```
**Why it matters:** Without correct RBAC the SparkApplication may be created, but driver/executors can fail to create/manage resources.

## 4) Run the job (submit + stream logs)
**What this does:** Submits your job and tails the driver logs so you can see output.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/submit-spark.ps1
```

**What you should see:** SparkApplication created → driver pod appears → logs stream (your job’s `print()` output shows here).

## Re-run
**What this means:** Spark-on-K8s runs from a Kubernetes resource. “Rerun” = re-submit a SparkApplication.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/submit-spark.ps1
```

**Note:** The script re-runs by doing a delete+apply of the SparkApplication (simple and predictable).

## Local dev run (no Kubernetes)
**What this is for:** Fast iteration without waiting for Kubernetes.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/dev-run.ps1
```

**Why it helps:** Validate logic locally, then submit to Kubernetes once it works.

## Debugging (quick)
**What this section is:** Short commands to identify whether issues are in the operator layer or the job layer.

### Operator health
**Use this when:** SparkApplications aren’t creating driver pods or you get webhook/readiness errors.

```powershell
kubectl get pods -n spark-operator
kubectl logs -n spark-operator deploy/spark-operator-controller --tail=200
kubectl logs -n spark-operator deploy/spark-operator-webhook --tail=200
```

**What you’re looking for:** webhook/controller running, and logs indicating it’s watching the right namespace(s).

### SparkApplication + pods
**Use this when:** You want to see job status, find the driver pod, and read job output.

```powershell
kubectl get sparkapplications.sparkoperator.k8s.io -n default
kubectl describe sparkapplication.sparkoperator.k8s.io pyspark-demo -n default
kubectl get pods -n default -w
kubectl get pods -n default -l spark-role=driver
kubectl logs -f -n default <driver-pod-name>
```

**What you’re looking for:** a driver pod named like `pyspark-demo-...-driver`, then executor pods, then completion.

### Events
**Use this when:** Something fails “quietly”. Events usually show the reason.

```powershell
kubectl get events -n default --sort-by=.lastTimestamp | Select-Object -Last 30
kubectl get events -n spark-operator --sort-by=.lastTimestamp | Select-Object -Last 30
```

## Common fixes
**What this section is:** The most common setup issues and the fastest fix.

### Webhook “connection refused”
**Why it happens:** You submitted a SparkApplication before the operator webhook was ready.

Wait for readiness:
```powershell
kubectl get pods -n spark-operator -w
```

Then submit again:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/submit-spark.ps1
```

### “No matches for kind SparkApplication”
**Why it happens:** Wrong API group/version in YAML (or CRDs not installed).

This repo expects **Kubeflow**:
```yaml
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
```

## Cleanup
**What this does:** Removes the SparkApplication and the operator if you want a clean slate.

```powershell
kubectl delete sparkapplication.sparkoperator.k8s.io pyspark-demo -n default --ignore-not-found
helm uninstall spark-operator -n spark-operator
```
