cd web
docker build -t localhost:5000/earthquake-web:latest .
docker push localhost:5000/earthquake-web:latest

cd ..
helm upgrade --install earthquake-monitor ./charts/earthquake-monitor
