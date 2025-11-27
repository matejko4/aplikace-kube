# Flask aplikace s MariaDB

Webová aplikace vytvořená pomocí Flask frameworku s MariaDB databází, containerizovaná pomocí Docker.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)

## Funkce

- 📝 Kontaktní formulář s polem pro jméno, email a zprávu
- 💾 Ukládání dat do MariaDB databáze
- 📊 Zobrazení všech odeslaných dat s časovým razítkem
- 🎨 Responzivní design s moderním vzhledem
- 🐳 Docker & Docker Compose pro snadné nasazení

## Požadavky

- Docker
- Docker Compose

## Rychlé spuštění

### Pomocí Docker Compose (doporučeno)

1. Naklonujte repozitář:
```bash
git clone https://github.com/VASE_JMENO/formular.git
cd formular
```

2. Spusťte aplikaci:
```bash
docker compose up --build
```

3. Otevřete prohlížeč a jděte na: **http://localhost:5001**

4. Pro zastavení použijte `Ctrl+C` nebo:
```bash
docker compose down
```

### Použití publikovaného Docker image

```bash
# Stáhněte image z GitHub Container Registry
docker pull ghcr.io/VASE_JMENO/formular:latest

# Nebo použijte docker-compose.yml s publikovaným image
```

## Publikace na GitHub

### 1. Vytvoření GitHub repozitáře

```bash
# Inicializujte git repozitář
git init
git add .
git commit -m "Initial commit: Flask app with MariaDB"

# Připojte se k GitHub repozitáři (vytvořte si nový repozitář na GitHubu)
git remote add origin https://github.com/VASE_JMENO/formular.git
git branch -M main
git push -u origin main
```

### 2. Automatická publikace Docker image

Repozitář obsahuje GitHub Actions workflow (`.github/workflows/docker-publish.yml`), který automaticky:
- Builduje Docker image při každém push na main/master
- Publikuje image do GitHub Container Registry (ghcr.io)
- Vytváří tagy podle verzí

Po pushnutí na GitHub:
1. Image bude automaticky publikován na `ghcr.io/VASE_JMENO/formular`
2. Najdete ho v sekci "Packages" vašeho GitHub profilu
3. Můžete ho stáhnout pomocí: `docker pull ghcr.io/VASE_JMENO/formular:latest`

### 3. Nastavení viditelnosti package

Po prvním buildu:
1. Jděte do svého GitHub profilu → Packages
2. Klikněte na package "formular"
3. Package settings → Change visibility → Public (pokud chcete veřejný přístup)

## Manuální publikace na Docker Hub

```bash
# Přihlaste se do Docker Hub
docker login

# Build image
docker build -t vase_jmeno/formular:latest .

# Push do Docker Hub
docker push vase_jmeno/formular:latest
```

## Konfigurace

### Environment proměnné

V `docker-compose.yml` můžete upravit:

```yaml
environment:
  DATABASE_URL: mysql+pymysql://root:password@db:3306/formular_db
  FLASK_ENV: development
  MYSQL_ROOT_PASSWORD: password
  MYSQL_DATABASE: formular_db
  MYSQL_USER: formular_user
  MYSQL_PASSWORD: formular_pass
```

### Porty

- **Flask aplikace**: 5001
- **MariaDB**: 3306

## Struktura projektu

```
.
├── app.py                   # Hlavní Flask aplikace
├── templates/               # HTML šablony
│   ├── index.html          # Formulář
│   ├── success.html        # Potvrzení
│   └── data.html           # Zobrazení dat
├── static/
│   └── style.css           # CSS styly
├── Dockerfile              # Docker image definice
├── docker-compose.yml      # Docker Compose konfigurace
├── requirements.txt        # Python závislosti
├── .github/
│   └── workflows/
│       └── docker-publish.yml  # GitHub Actions CI/CD
└── README.md
```

## Databáze

- **Engine**: MariaDB 11.2
- **Databáze**: formular_db
- **Tabulka**: form_submissions
- **Sloupce**: 
  - `id` (Primary Key)
  - `name` (VARCHAR)
  - `email` (VARCHAR)
  - `message` (TEXT)
  - `created_at` (DATETIME)

## Endpoints

- `GET /` - Hlavní stránka s formulářem
- `POST /submit` - Odeslání formuláře
- `GET /success` - Potvrzení o úspěšném odeslání
- `GET /data` - Zobrazení všech odeslaných dat
- `GET /health` - Health check endpoint

## Development

Pro vývoj bez Dockeru:

```bash
# Vytvořte virtuální prostředí
python -m venv venv
source venv/bin/activate  # Linux/Mac
# nebo
venv\Scripts\activate  # Windows

# Nainstalujte závislosti
pip install -r requirements.txt

# Spusťte MariaDB (nebo upravte DATABASE_URL v app.py)

# Spusťte aplikaci
python app.py
```

## Čištění

```bash
# Zastavení a odstranění kontejnerů
docker compose down

# Odstranění s volumes (smaže databázová data)
docker compose down -v

# Odstranění images
docker rmi formular-web mariadb:11.2
```

## Licence

MIT

## Autor

Váš jméno

## Technologie

- **Backend**: Flask 3.0.0
- **ORM**: Flask-SQLAlchemy
- **Database**: MariaDB 11.2
- **Database Driver**: PyMySQL
- **Container**: Docker & Docker Compose
- **CI/CD**: GitHub Actions
