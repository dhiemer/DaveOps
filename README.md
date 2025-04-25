# Earthquake Monitor

A local demo app that fetches real-time USGS earthquake data and displays it via Kafka + K8s + Helm + NGINX.

## Features
- Python producer for USGS data
- Kafka event stream
- Consumer writes to local JSON
- NGINX serves it with a simple HTML dashboard
- Fully local with Docker Desktop + Helm
