cls

cd C:\earthquake-monitor

Write-Host "Rebuilding and pushing Docker images..."

# producer
docker build -t localhost:5000/earthquake-producer:latest ./producer
docker push localhost:5000/earthquake-producer:latest

# consumer
docker build -t localhost:5000/earthquake-consumer:latest ./consumer
docker push localhost:5000/earthquake-consumer:latest

# web
docker build -t localhost:5000/earthquake-web:latest ./web
docker push localhost:5000/earthquake-web:latest

# alert-dispatcher-svc
docker build -t localhost:5000/alert-dispatcher-svc:latest ./alert-dispatcher-svc
docker push localhost:5000/alert-dispatcher-svc:latest

# quake-detector-svc
docker build -t localhost:5000/quake-detector-svc:latest ./quake-detector-svc
docker push localhost:5000/quake-detector-svc:latest

Write-Host "Upgrading Helm release..."
helm upgrade --install earthquake-monitor ./charts/earthquake-monitor

Write-Host "Deleting old pods..."
kubectl delete pod -l app=producer
kubectl delete pod -l app=consumer
kubectl delete pod -l app=quake-detector-svc
kubectl delete pod -l app=alert-dispatcher-svc
kubectl delete pod -l app=web

Write-Host "Listing pods..."
kubectl get pods

Write-Host "Setting up port-forward to web service..."
kubectl port-forward svc/web 8080:80
