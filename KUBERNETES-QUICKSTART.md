# 🚀 RYCHLÝ START - Kubernetes Nasazení

## Pro existující MariaDB databázi (váš případ)

### 1. Upravte secret s připojením k vaší DB

Zjistěte název vašeho DB service:
```bash
kubectl get svc -A | grep maria
```

Předpokládejme, že service je `test` v namespace `default`.

Vytvořte secret:
```bash
kubectl create namespace formular

kubectl create secret generic formular-secrets \
  --from-literal=DATABASE_URL='mysql+pymysql://root:VASE_HESLO@test.default.svc.cluster.local:3306/formular_db' \
  -n formular
```

**DŮLEŽITÉ:** Změňte `VASE_HESLO` na skutečné heslo k vaší databázi!

### 2. Vytvořte databázi (pokud neexistuje)

Připojte se k vaší MariaDB:
```bash
kubectl exec -it <POD_NAME_VASI_DB> -- mysql -uroot -p
```

Vytvořte databázi:
```sql
CREATE DATABASE IF NOT EXISTS formular_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SHOW DATABASES;
EXIT;
```

### 3. Buildněte a načtěte Docker image do Kubernetes

```bash
# Build image
docker build -t formular-app:latest .

# Pro Minikube
minikube image load formular-app:latest

# Pro Kind
kind load docker-image formular-app:latest

# Pro standardní K8s (push do registry)
docker tag formular-app:latest ghcr.io/VASE_JMENO/formular:latest
docker push ghcr.io/VASE_JMENO/formular:latest
```

### 4. Upravte deployment

Upravte `k8s/deployment.yaml` - změňte image:
```bash
sed -i 's|ghcr.io/VASE_JMENO/formular:latest|formular-app:latest|' k8s/deployment.yaml
sed -i 's|image: formular-web:latest|image: formular-app:latest|' k8s/deployment.yaml
```

Nebo ručně v souboru změňte:
```yaml
image: formular-app:latest
imagePullPolicy: Never  # pro lokální image
```

### 5. Nasaďte aplikaci

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
# Secret už máte vytvořený v kroku 1
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 6. Zkontrolujte nasazení

```bash
# Sledujte pody
kubectl get pods -n formular -w

# Logy
kubectl logs -f -n formular -l app=formular

# Detail podu
kubectl describe pod -n formular <POD_NAME>
```

### 7. Přístup k aplikaci

```bash
# Zjistěte node IP
kubectl get nodes -o wide

# Aplikace běží na: http://NODE_IP:30001
```

Nebo port-forward:
```bash
kubectl port-forward -n formular service/formular-service 8080:80
# Otevřete: http://localhost:8080
```

## 🔧 Troubleshooting

### CrashLoopBackOff?

```bash
# Zkontrolujte logy
kubectl logs -n formular <POD_NAME>

# Zkontrolujte předchozí crash
kubectl logs -n formular <POD_NAME> --previous

# Zkontrolujte eventi
kubectl get events -n formular --sort-by='.lastTimestamp'
```

### Nelze se připojit k databázi?

```bash
# Test DNS
kubectl exec -it -n formular <POD_NAME> -- nslookup test.default.svc.cluster.local

# Test připojení
kubectl exec -it -n formular <POD_NAME> -- nc -zv test.default.svc.cluster.local 3306

# Exec do podu
kubectl exec -it -n formular <POD_NAME> -- sh
```

### Vytvoření tabulek v databázi

```bash
kubectl exec -it -n formular deployment/formular-app -- python << EOF
from app import app, db
with app.app_context():
    db.create_all()
    print("✅ Tabulky vytvořeny!")
EOF
```

## 📋 Kompletní příklad pro "test" databázi

```bash
# 1. Namespace
kubectl create namespace formular

# 2. Secret (ZMĚŇTE HESLO!)
kubectl create secret generic formular-secrets \
  --from-literal=DATABASE_URL='mysql+pymysql://root:password@test.default.svc.cluster.local:3306/formular_db' \
  -n formular

# 3. Build image
docker build -t formular-app:latest .

# 4. Load do clusteru (Minikube)
minikube image load formular-app:latest

# 5. ConfigMap
kubectl apply -f k8s/configmap.yaml

# 6. Deployment
kubectl apply -f k8s/deployment.yaml

# 7. Service  
kubectl apply -f k8s/service.yaml

# 8. Check
kubectl get all -n formular
kubectl logs -f -n formular -l app=formular
```

Hotovo! 🎉
