#!/bin/bash

# Kubernetes deployment script pro Flask Formular aplikaci
# ==========================================================

set -e

echo "🚀 Kubernetes Deployment Script"
echo "================================"
echo ""

# Barvy pro výstup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funkce pro výpis
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Kontrola kubectl
if ! command -v kubectl &> /dev/null; then
    error "kubectl není nainstalován!"
    exit 1
fi

info "kubectl nalezen: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# Dotaz na konfiguraci
echo ""
echo "📝 Konfigurace nasazení"
echo "----------------------"
read -p "Název namespace [formular]: " NAMESPACE
NAMESPACE=${NAMESPACE:-formular}

read -p "Máte již existující MariaDB? (y/n) [n]: " HAS_DB
HAS_DB=${HAS_DB:-n}

if [[ $HAS_DB == "y" || $HAS_DB == "Y" ]]; then
    read -p "Název DB service (např. test): " DB_SERVICE
    read -p "Namespace databáze [default]: " DB_NAMESPACE
    DB_NAMESPACE=${DB_NAMESPACE:-default}
    read -p "DB uživatel [root]: " DB_USER
    DB_USER=${DB_USER:-root}
    read -sp "DB heslo: " DB_PASSWORD
    echo ""
    read -p "Název databáze [formular_db]: " DB_NAME
    DB_NAME=${DB_NAME:-formular_db}
    
    DB_HOST="${DB_SERVICE}.${DB_NAMESPACE}.svc.cluster.local"
    DATABASE_URL="mysql+pymysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:3306/${DB_NAME}"
fi

read -p "Docker image [formular-web:latest]: " DOCKER_IMAGE
DOCKER_IMAGE=${DOCKER_IMAGE:-formular-web:latest}

read -p "Použít lokální image? (y/n) [y]: " USE_LOCAL
USE_LOCAL=${USE_LOCAL:-y}

# Vytvoření namespace
info "Vytváření namespace: $NAMESPACE"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF

# Vytvoření ConfigMap
info "Vytváření ConfigMap"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: formular-config
  namespace: $NAMESPACE
data:
  FLASK_ENV: "production"
EOF

# Vytvoření Secret
if [[ $HAS_DB == "y" || $HAS_DB == "Y" ]]; then
    info "Vytváření Secret s připojením k DB: $DB_HOST"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: formular-secrets
  namespace: $NAMESPACE
type: Opaque
stringData:
  DATABASE_URL: "$DATABASE_URL"
EOF
else
    warn "Budete nasazovat vlastní MariaDB"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: formular-secrets
  namespace: $NAMESPACE
type: Opaque
stringData:
  DATABASE_URL: "mysql+pymysql://root:password@mariadb-service:3306/formular_db"
EOF
    
    # Nasazení MariaDB
    info "Nasazování MariaDB..."
    kubectl apply -f k8s/mariadb.yaml
    
    info "Čekám na MariaDB..."
    kubectl wait --for=condition=ready pod -l app=mariadb -n $NAMESPACE --timeout=300s || warn "Timeout - zkontrolujte manuálně"
fi

# Vytvoření Deployment
info "Vytváření Deployment"
IMAGE_PULL_POLICY="IfNotPresent"
if [[ $USE_LOCAL == "y" || $USE_LOCAL == "Y" ]]; then
    IMAGE_PULL_POLICY="Never"
fi

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: formular-app
  namespace: $NAMESPACE
  labels:
    app: formular
spec:
  replicas: 2
  selector:
    matchLabels:
      app: formular
  template:
    metadata:
      labels:
        app: formular
    spec:
      containers:
      - name: flask-app
        image: $DOCKER_IMAGE
        imagePullPolicy: $IMAGE_PULL_POLICY
        ports:
        - containerPort: 5001
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: formular-secrets
              key: DATABASE_URL
        - name: FLASK_ENV
          valueFrom:
            configMapKeyRef:
              name: formular-config
              key: FLASK_ENV
        livenessProbe:
          httpGet:
            path: /health
            port: 5001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 5001
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
EOF

# Vytvoření Service
info "Vytváření Service"
kubectl apply -f k8s/service.yaml

# Čekání na ready
info "Čekám na pody..."
kubectl wait --for=condition=ready pod -l app=formular -n $NAMESPACE --timeout=120s || warn "Timeout - zkontrolujte logy"

# Výpis stavu
echo ""
info "Nasazení dokončeno! 🎉"
echo ""
echo "📊 Stav nasazení:"
kubectl get all -n $NAMESPACE

echo ""
echo "🌐 Přístup k aplikaci:"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "   NodePort: http://$NODE_IP:30001"
echo ""
echo "🔍 Užitečné příkazy:"
echo "   Logy:       kubectl logs -f -n $NAMESPACE -l app=formular"
echo "   Pody:       kubectl get pods -n $NAMESPACE"
echo "   Port-fwd:   kubectl port-forward -n $NAMESPACE service/formular-service 8080:80"
echo "   Restart:    kubectl rollout restart deployment/formular-app -n $NAMESPACE"
echo "   Delete:     kubectl delete namespace $NAMESPACE"
echo ""
