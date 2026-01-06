FROM spark:3.5.0-scala2.12-java17-python3-ubuntu

USER root
WORKDIR /opt/spark/work-dir

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt && rm -f /tmp/requirements.txt

COPY app/ /app
RUN chown -R spark:spark /app

USER spark
