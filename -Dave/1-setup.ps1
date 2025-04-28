$root = "earthquake-monitor"
$folders = @(
    "$root/charts/earthquake-monitor/templates",
    "$root/producer",
    "$root/consumer",
    "$root/web",
    "$root/nginx"
)

# Create folders
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

# Chart.yaml
@"
apiVersion: v2
name: earthquake-monitor
version: 0.1.0
description: A simple local demo with Kafka, NGINX, and K8s
"@ | Set-Content "$root/charts/earthquake-monitor/Chart.yaml"

# values.yaml
@"
kafkaImage: bitnami/kafka:latest
producerImage: earthquake-producer:latest
consumerImage: earthquake-consumer:latest
webImage: earthquake-web:latest
"@ | Set-Content "$root/charts/earthquake-monitor/values.yaml"

# kafka.yaml
@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
        - name: kafka
          image: {{ .Values.kafkaImage }}
          ports:
            - containerPort: 9092
---
apiVersion: v1
kind: Service
metadata:
  name: kafka
spec:
  selector:
    app: kafka
  ports:
    - port: 9092
      targetPort: 9092
"@ | Set-Content "$root/charts/earthquake-monitor/templates/kafka.yaml"

# producer-deployment.yaml
@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: producer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: producer
  template:
    metadata:
      labels:
        app: producer
    spec:
      containers:
        - name: producer
          image: {{ .Values.producerImage }}
"@ | Set-Content "$root/charts/earthquake-monitor/templates/producer-deployment.yaml"

# consumer-deployment.yaml
@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consumer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: consumer
  template:
    metadata:
      labels:
        app: consumer
    spec:
      volumes:
        - name: data-volume
          emptyDir: { }
      containers:
        - name: consumer
          image: {{ .Values.consumerImage }}
          volumeMounts:
            - name: data-volume
              mountPath: /data
"@ | Set-Content "$root/charts/earthquake-monitor/templates/consumer-deployment.yaml"

# web-deployment.yaml
@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      volumes:
        - name: data-volume
          emptyDir: { }
        - name: nginx-config
          configMap:
            name: nginx-config
      containers:
        - name: web
          image: {{ .Values.webImage }}
          volumeMounts:
            - name: data-volume
              mountPath: /usr/share/nginx/html/data.json
              subPath: data.json
            - name: nginx-config
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
---
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
"@ | Set-Content "$root/charts/earthquake-monitor/templates/web-deployment.yaml"

# nginx-configmap.yaml
@"
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  labels:
    app: web
  namespace: default
  annotations:
    managed-by: Helm
binaryData: {}
data:
  nginx.conf: |
    events {}
    http {
      server {
        listen 80;
        root /usr/share/nginx/html;
        location / {
          index index.html;
        }
        location /data.json {
          alias /usr/share/nginx/html/data.json;
          add_header Content-Type application/json;
        }
      }
    }
"@ | Set-Content "$root/charts/earthquake-monitor/templates/nginx-configmap.yaml"

# Producer app.py
@"
import json, time, requests
from kafka import KafkaProducer

producer = KafkaProducer(bootstrap_servers='kafka:9092', value_serializer=lambda v: json.dumps(v).encode('utf-8'))

while True:
    res = requests.get('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson')
    data = res.json()['features']
    for quake in data:
        producer.send('earthquakes', quake)
    print(\"Published latest earthquakes.\")
    time.sleep(60)
"@ | Set-Content "$root/producer/app.py"

# Consumer app.py
@"
import json
from kafka import KafkaConsumer

consumer = KafkaConsumer('earthquakes', bootstrap_servers='kafka:9092', value_deserializer=lambda m: json.loads(m.decode('utf-8')))
earthquakes = []

for msg in consumer:
    earthquakes.append(msg.value)
    with open('/data/data.json', 'w') as f:
        json.dump(earthquakes[-10:], f, indent=2)
"@ | Set-Content "$root/consumer/app.py"

# Web index.html
@"
<!DOCTYPE html>
<html>
<head>
  <title>Earthquake Monitor</title>
</head>
<body>
  <h1>Recent Earthquakes</h1>
  <ul id=\"quakes\"></ul>
  <script>
    fetch(\"/data.json\").then(res => res.json()).then(data => {
      const list = document.getElementById(\"quakes\");
      data.forEach(q => {
        const li = document.createElement(\"li\");
        li.textContent = `${q.properties.place} - M${q.properties.mag}`;
        list.appendChild(li);
      });
    });
  </script>
</body>
</html>
"@ | Set-Content "$root/web/index.html"

# Dockerfiles
# Producer Dockerfile
@"
FROM python:3.11-slim
RUN pip install kafka-python requests
COPY app.py /app.py
CMD ["python", "/app.py"]
"@ | Set-Content "$root/producer/Dockerfile"

# Consumer Dockerfile
@"
FROM python:3.11-slim
RUN pip install kafka-python
COPY app.py /app.py
CMD ["python", "/app.py"]
"@ | Set-Content "$root/consumer/Dockerfile"

# Web Dockerfile
@"
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
RUN mkdir /usr/share/nginx/html/data && touch /usr/share/nginx/html/data/data.json
"@ | Set-Content "$root/web/Dockerfile"


# README.md
@"
# Earthquake Monitor

A local demo app that fetches real-time USGS earthquake data and displays it via Kafka + K8s + Helm + NGINX.

## Features
- Python producer for USGS data
- Kafka event stream
- Consumer writes to local JSON
- NGINX serves it with a simple HTML dashboard
- Fully local with Docker Desktop + Helm
"@ | Set-Content "$root/README.md"

Write-Host "✅ Project structure created under '$root'"
