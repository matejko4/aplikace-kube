# 📦 Kompletní průvodce nasazením

## ✅ Co máte k dispozici

### Soubory projektu:
```
formular/
├── app.py                      # Flask aplikace
├── requirements.txt            # Python závislosti
├── Dockerfile                  # Docker image
├── docker-compose.yml          # Docker Compose
├── templates/                  # HTML šablony
├── static/                     # CSS styly
├── k8s/                        # Kubernetes manifesty
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── mariadb.yaml
│   └── README.md
├── k8s-deploy.sh              # Automatický deploy skript
├── README.md                   # Hlavní dokumentace
├── KUBERNETES-QUICKSTART.md    # Rychlý start pro K8s
└── PUBLIKACE.md               # Návod na GitHub publikaci
```

## 🎯 3 způsoby nasazení

### 1️⃣ Docker Compose (lokální vývoj)

**Nejjednodušší způsob pro testování:**

```bash
# Spuštění
docker compose up --build

# Aplikace běží na: http://localhost:5001

# Zastavení
docker compose down
```

📖 **Dokumentace:** `README.md` sekce "Rychlé spuštění"

---

### 2️⃣ Kubernetes s existující databází

**Pro produkční nasazení s vaší MariaDB:**

#### Krok 1: Zjistěte údaje o databázi
```bash
kubectl get svc -A | grep maria
# Najděte: název service, namespace
```

#### Krok 2: Vytvořte secret
```bash
kubectl create namespace formular

kubectl create secret generic formular-secrets \
  --from-literal=DATABASE_URL='mysql+pymysql://USER:PASSWORD@DB_SERVICE.NAMESPACE.svc.cluster.local:3306/formular_db' \
  -n formular
```

**Příklad pro service "test" v namespace "default":**
```bash
kubectl create secret generic formular-secrets \
  --from-literal=DATABASE_URL='mysql+pymysql://root:heslo123@test.default.svc.cluster.local:3306/formular_db' \
  -n formular
```

#### Krok 3: Vytvořte databázi (pokud neexistuje)
```bash
kubectl exec -it <VASE_DB_POD> -- mysql -uroot -p

# V MySQL:
CREATE DATABASE IF NOT EXISTS formular_db;
EXIT;
```

#### Krok 4: Build a load image
```bash
# Build
docker build -t formular-app:latest .

# Pro Minikube:
minikube image load formular-app:latest

# Pro Kind:
kind load docker-image formular-app:latest

# Pro standardní K8s - push do registry:
docker tag formular-app:latest ghcr.io/VASE_JMENO/formular:latest
docker push ghcr.io/VASE_JMENO/formular:latest
```

#### Krok 5: Upravte deployment
Změňte v `k8s/deployment.yaml`:
```yaml
image: formular-app:latest  # váš image
imagePullPolicy: Never      # pro lokální image
```

#### Krok 6: Deploy
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
# secret už máte
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

#### Krok 7: Přístup
```bash
# NodePort (výchozí)
kubectl get nodes -o wide
# Aplikace: http://NODE_IP:30001

# Port-forward (alternativa)
kubectl port-forward -n formular service/formular-service 8080:80
# Aplikace: http://localhost:8080
```

📖 **Dokumentace:** `KUBERNETES-QUICKSTART.md`

---

### 3️⃣ GitHub + Automatická publikace

**Pro sdílení a automatický CI/CD:**

#### Krok 1: Vytvoření GitHub repozitáře
```bash
# Inicializace
git init
git add .
git commit -m "Initial commit"

# Připojení k GitHubu (vytvořte repo na GitHub.com)
git remote add origin https://github.com/VASE_JMENO/formular.git
git branch -M main
git push -u origin main
```

#### Krok 2: GitHub Actions automaticky:
- Builduje Docker image při každém push
- Publikuje do GitHub Container Registry (ghcr.io)
- Najdete v záložce "Packages" na vašem profilu

#### Krok 3: Použití publikovaného image
```bash
docker pull ghcr.io/VASE_JMENO/formular:main

# V Kubernetes deployment:
image: ghcr.io/VASE_JMENO/formular:main
```

📖 **Dokumentace:** `PUBLIKACE.md`

---

## 🔍 Kterou metodu zvolit?

| Metoda | Kdy použít | Složitost |
|--------|-----------|-----------|
| Docker Compose | Lokální vývoj, testování | ⭐ Snadné |
| Kubernetes | Produkce, škálovatelnost | ⭐⭐⭐ Pokročilé |
| GitHub Actions | Sdílení, automatizace | ⭐⭐ Střední |

## 🆘 Potřebujete pomoc?

### Pro Docker Compose:
```bash
# Logy
docker compose logs -f

# Restart
docker compose restart

# Úplné vyčištění
docker compose down -v
```

### Pro Kubernetes:
```bash
# Logy
kubectl logs -f -n formular -l app=formular

# Stav podů
kubectl get pods -n formular

# Detail problému
kubectl describe pod -n formular <POD_NAME>

# Restart
kubectl rollout restart deployment/formular-app -n formular

# Smazání všeho
kubectl delete namespace formular
```

### Pro GitHub:
```bash
# Kontrola workflow
# Jděte na GitHub.com → váš repo → Actions

# Nový push
git add .
git commit -m "Update"
git push
```

## 📚 Kompletní dokumentace

- **README.md** - Obecný přehled, Docker Compose, manuální instalace
- **KUBERNETES-QUICKSTART.md** - Rychlý start pro Kubernetes
- **k8s/README.md** - Detailní K8s dokumentace, troubleshooting
- **PUBLIKACE.md** - GitHub a Docker Hub publikace
- **Tento soubor** - Přehled všech možností

## 🎓 Tipy pro začátečníky

### Začněte s Docker Compose
1. `docker compose up`
2. Otevřete http://localhost:5001
3. Vyzkoušejte formulář

### Pokud máte Kubernetes:
1. Použijte `KUBERNETES-QUICKSTART.md`
2. Postupujte krok za krokem
3. Používejte `kubectl logs` pro debugging

### Pro sdílení projektu:
1. Push na GitHub
2. GitHub Actions se spustí automaticky
3. Image bude v GitHub Packages

## ⚡ Rychlé příkazy

```bash
# Docker Compose - start
docker compose up -d

# Kubernetes - úplné nasazení
./k8s-deploy.sh

# GitHub - push
git add . && git commit -m "Update" && git push

# Logy - Docker
docker compose logs -f flask

# Logy - Kubernetes
kubectl logs -f -n formular -l app=formular

# Test aplikace
curl http://localhost:5001/health
```

## 🎉 Enjoy!

Máte kompletní Flask aplikaci s:
- ✅ MariaDB databází
- ✅ Docker podporou
- ✅ Kubernetes manifesty
- ✅ GitHub Actions CI/CD
- ✅ Responzivním designem
- ✅ Kompletní dokumentací

**Vyberte si metodu nasazení a začněte! 🚀**
