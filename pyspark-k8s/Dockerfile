FROM eclipse-temurin:17-jre

ENV VENV=/opt/venv
ENV PATH="$VENV/bin:$PATH"
ENV PYSPARK_PYTHON="$VENV/bin/python"

RUN apt-get update && \
    apt-get install -y python3 python3-venv python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Create venv and install Python deps into it
RUN python3 -m venv $VENV && \
    $VENV/bin/pip install --upgrade pip && \
    $VENV/bin/pip install pyspark==3.5.0 "numpy<2" "pandas>=2.1.0"

WORKDIR /app
COPY app/job.py /app/job.py
