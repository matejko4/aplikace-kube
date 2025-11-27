# Kubernetes Deployment Guide

## 📋 Předpoklady

- Běžící Kubernetes cluster
- `kubectl` nainstalovaný a nakonfigurovaný
- Docker image buildunutý nebo přístupný v registry

## 🚀 Rychlé nasazení

### 1. Příprava

Pokud máte **vlastní existující MariaDB**, upravte:
- `k8s/secret.yaml` - nastavte správné DB credentials
- `k8s/deployment.yaml` - změňte image na váš

Pokud **NEMÁTE** databázi, použijte i `k8s/mariadb.yaml`.

### 2. Build a push Docker image

```bash
# Build image
docker build -t formular-app:latest .

# Tag pro registry (GitHub Container Registry)
docker tag formular-app:latest ghcr.io/VASE_JMENO/formular:latest

# Push do registry
docker push ghcr.io/VASE_JMENO/formular:latest
```

### 3. Nasazení do Kubernetes

```bash
# Vytvoření namespace
kubectl apply -f k8s/namespace.yaml

# ConfigMap a Secrets (UPRAVTE PŘED POUŽITÍM!)
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# Pokud NEMÁTE vlastní databázi:
kubectl apply -f k8s/mariadb.yaml

# Deployment aplikace
kubectl apply -f k8s/deployment.yaml

# Service
kubectl apply -f k8s/service.yaml
```

### 4. Kontrola nasazení

```bash
# Zkontrolujte pody
kubectl get pods -n formular

# Sledujte logy
kubectl logs -f -n formular deployment/formular-app

# Zkontrolujte služby
kubectl get svc -n formular
```

## 🔧 Připojení k existující databázi

Pokud máte existující MariaDB v Kubernetes:

### Zjistěte service name:
```bash
kubectl get svc -A | grep mariadb
```

### Upravte soubory:

**k8s/secret.yaml:**
```yaml
stringData:
  DATABASE_URL: "mysql+pymysql://USER:PASSWORD@MYSQL_SERVICE_NAME:3306/formular_db"
```

Příklad:
```yaml
stringData:
  DATABASE_URL: "mysql+pymysql://root:heslo123@test:3306/formular_db"
```

**k8s/deployment.yaml:**
Změňte image na váš:
```yaml
image: ghcr.io/matysek/formular:latest  # Váš image
```

### Přeaplikujte:
```bash
kubectl delete -f k8s/secret.yaml
kubectl apply -f k8s/secret.yaml

kubectl rollout restart deployment/formular-app -n formular
```

## 🌐 Přístup k aplikaci

### NodePort (výchozí):
```bash
# Zjistěte IP node
kubectl get nodes -o wide

# Aplikace je dostupná na: http://NODE_IP:30001
```

### Port Forward (pro testování):
```bash
kubectl port-forward -n formular service/formular-service 8080:80
# Otevřete: http://localhost:8080
```

### LoadBalancer (pokud máte):
Změňte v `k8s/service.yaml`:
```yaml
spec:
  type: LoadBalancer
```

Zjistěte external IP:
```bash
kubectl get svc -n formular formular-service
```

## 📊 Monitoring a debugging

### Zkontrolujte stav podů:
```bash
kubectl get pods -n formular -w
```

### Logy aplikace:
```bash
# Všechny pody
kubectl logs -n formular -l app=formular --tail=100 -f

# Konkrétní pod
kubectl logs -n formular POD_NAME -f
```

### Logy databáze:
```bash
kubectl logs -n formular mariadb-0 -f
```

### Exec do podu:
```bash
# Flask app
kubectl exec -it -n formular deployment/formular-app -- /bin/bash

# MariaDB
kubectl exec -it -n formular mariadb-0 -- mysql -uroot -ppassword formular_db
```

### Health check:
```bash
# Z venku
curl http://NODE_IP:30001/health

# Z clusteru
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://formular-service.formular.svc.cluster.local/health
```

## 🔄 Aktualizace aplikace

```bash
# 1. Build nový image
docker build -t ghcr.io/VASE_JMENO/formular:v1.0.1 .
docker push ghcr.io/VASE_JMENO/formular:v1.0.1

# 2. Update deployment
kubectl set image deployment/formular-app flask-app=ghcr.io/VASE_JMENO/formular:v1.0.1 -n formular

# Nebo rollout restart
kubectl rollout restart deployment/formular-app -n formular

# 3. Sledujte rollout
kubectl rollout status deployment/formular-app -n formular
```

## 🗄️ Migrace dat

Pokud potřebujete vytvořit tabulky v existující DB:

```bash
# Exec do Flask podu
kubectl exec -it -n formular deployment/formular-app -- python

# V Python shellu:
>>> from app import app, db
>>> with app.app_context():
...     db.create_all()
...     print("Tabulky vytvořeny!")
>>> exit()
```

## 🧹 Úklid

```bash
# Smazání všeho
kubectl delete namespace formular

# Nebo jednotlivě
kubectl delete -f k8s/service.yaml
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/mariadb.yaml  # POZOR: smaže i data!
kubectl delete -f k8s/secret.yaml
kubectl delete -f k8s/configmap.yaml
kubectl delete -f k8s/namespace.yaml
```

## 🔐 Produkční bezpečnost

### 1. Použijte silná hesla:
```bash
# Vygenerujte náhodné heslo
openssl rand -base64 32
```

### 2. Použijte Kubernetes secrets:
```bash
kubectl create secret generic formular-secrets \
  --from-literal=DATABASE_URL='mysql+pymysql://user:STRONG_PASSWORD@host:3306/db' \
  -n formular
```

### 3. Použijte ImagePullSecrets pro private registry:
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=GITHUB_USERNAME \
  --docker-password=GITHUB_TOKEN \
  -n formular
```

Přidejte do deployment:
```yaml
spec:
  imagePullSecrets:
  - name: ghcr-secret
```

## ❓ Řešení problémů

### Pod nejde do stavu Running:
```bash
kubectl describe pod -n formular POD_NAME
kubectl logs -n formular POD_NAME
```

### CrashLoopBackOff:
- Zkontrolujte DATABASE_URL v secrets
- Zkontrolujte, že DB service je dostupný
- Zkontrolujte logy: `kubectl logs -n formular POD_NAME --previous`

### ImagePullBackOff:
- Zkontrolujte, že image existuje
- Pro private registry přidejte imagePullSecrets
- Pro lokální image použijte `imagePullPolicy: Never`

### Nelze se připojit k DB:
```bash
# Test připojení z podu
kubectl exec -it -n formular deployment/formular-app -- sh
# V shellu:
nc -zv mariadb-service 3306
```

## 🎯 Příklad kompletního nasazení s existující DB

Předpokládejme, že máte DB service s názvem `test` v namespace `default`:

```bash
# 1. Upravte secret
cat > k8s/secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: formular-secrets
  namespace: formular
type: Opaque
stringData:
  DATABASE_URL: "mysql+pymysql://root:vase_heslo@test.default.svc.cluster.local:3306/formular_db"
EOF

# 2. Vytvořte databázi (pokud neexistuje)
kubectl exec -it test-0 -- mysql -uroot -p
# V MySQL:
# CREATE DATABASE IF NOT EXISTS formular_db;
# exit

# 3. Nasaďte aplikaci
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# 4. Zkontrolujte
kubectl get all -n formular
kubectl logs -f -n formular -l app=formular
```

Hotovo! Aplikace by měla běžet na http://NODE_IP:30001 🎉
