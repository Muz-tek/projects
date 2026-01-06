from pyspark.sql import SparkSession


print("=== JOB START ===", flush=True)

spark = (
    SparkSession.builder
    .appName("pyspark-k8s-demo")
    .getOrCreate()
)

data = [
    ("Alice", 34),
    ("Bob", 45),
    ("Charlie", 29)
]

df = spark.createDataFrame(data, ["name", "age"])

df.filter(df.age >= 30).show()

spark.stop()

print("=== JOB END ===", flush=True)
