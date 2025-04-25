

helm uninstall earthquake-monitor


kubectl get pods
kubectl get pods -w




kubectl rollout restart deployment kafka
kubectl rollout restart deployment web
kubectl rollout restart deployment producer
kubectl rollout restart deployment consumer



docker build -t earthquake-producer:latest ./producer
kubectl rollout restart deployment producer

kubectl get svc web

docker build -t earthquake-web:latest ./web


### Need this to access Site
kubectl port-forward svc/web 8080:80
kubectl port-forward deploy/earthquake-app 8080:80

# Then go to: http://localhost:8080


kubectl exec -it deploy/web -- ls -l /usr/share/nginx/html/data.json
kubectl exec -it deploy/web -- cat /usr/share/nginx/html/data.json


kubectl exec -it deploy/earthquake-app -c web -- ls -l /usr/share/nginx/html/data.json
kubectl exec -it deploy/earthquake-app -c web -- cat /usr/share/nginx/html/data.json







kubectl delete deployment web
kubectl delete pod consumer-7b8f6d9b76-4lzxx


helm upgrade --install earthquake-monitor ./charts/earthquake-monitor




docker build -t earthquake-consumer:latest ./consumer
charts/earthquake-monitor/templates/web-deployment.yaml

helm upgrade earthquake-monitor ./charts/earthquake-monitor





docker run -d -p 5000:5000 --name registry registry:2
docker ps
docker tag earthquake-producer:latest localhost:5000/earthquake-producer:latest


docker build -t localhost:5000/earthquake-consumer:latest ./consumer
docker push localhost:5000/earthquake-consumer:latest

# Reset
kubectl delete all --all -n default
kubectl delete pvc --all -n default
kubectl delete configmap --all -n default
kubectl delete secret --all -n default


kubectl apply -f charts/earthquake-monitor/templates/
kubectl get pods
kubectl port-forward svc/earthquake-app 8080:80
kubectl port-forward svc/web 8080:80


helm upgrade --install earthquake-monitor ./charts/earthquake-monitor
helm upgrade earthquake-monitor ./charts/earthquake-monitor

#Render Only
helm template earthquake-monitor ./charts/earthquake-monitor





kubectl exec producer-dddd9bb8b-ntp5j -- cat /data/data.json
kubectl exec consumer-6f4844b58f-5tckl -- cat /data/data.json

kubectl exec web-6b86f844c7-drz7x -- ls -l /data/data.json
kubectl exec web-6b86f844c7-drz7x -- cat /data/data.json

# Add the Bitnami Helm Repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 📁 Create a postgres-values.yaml File

auth:
  username: earthquake
  password: quakepass
  database: quakesdb

primary:
  persistence:
    enabled: true
    size: 1Gi

# 🚀 Install PostgreSQL in Your Cluster
helm install earthquake-postgres bitnami/postgresql -f postgres-values.yaml


# 🔌 Connect Your Apps (Consumer, Web)







kubectl get secret earthquake-postgres-postgresql -o yaml
MiWx9oYY8U
PS C:\earthquake-monitor> kubectl exec -it earthquake-postgres-postgresql-0 -- psql -U postgres
Password for user postgres: 
psql (17.4)
Type "help" for help.

postgres=# CREATE TABLE quakes (
postgres(#     id SERIAL PRIMARY KEY,
postgres(#     timestamp TIMESTAMPTZ,
postgres(#     location TEXT,
postgres(#     magnitude REAL
postgres(# );
CREATE TABLE
postgres=# \q
could not save history to file "//.psql_history": Read-only file system
PS C:\earthquake-monitor> 





# Secrets in Windows
$secret = kubectl get secret earthquake-postgres-postgresql -o jsonpath="{.data.postgres-password}"
[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($secret))

kubectl exec -it consumer-66b764655d-zbcfh -- printenv | Select-String "DB_PASSWORD"



http://localhost:8080/

