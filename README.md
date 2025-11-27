# Flask aplikace s MariaDB

Webová aplikace vytvořená pomocí Flask frameworku s MariaDB databází, containerizovaná pomocí Docker.

## Funkce

- 📝 Kontaktní formulář s polem pro jméno, email a zprávu
- 💾 Ukládání dat do MariaDB databáze
- 📊 Zobrazení všech odeslaných dat s časovým razítkem
- 🎨 Responzivní design s moderním vzhledem
- 🐳 Docker & Docker Compose pro snadné nasazení

## Požadavky

- Docker
- Docker Compose

## Spuštění pomocí Docker

1. Build a spuštění kontejnerů:
```bash
docker-compose up --build
```

2. Aplikace bude dostupná na: **http://localhost:5001**

3. Pro zastavení:
```bash
docker-compose down
```

4. Pro smazání dat (volumes):
```bash
docker-compose down -v
```

## Manuální instalace (bez Dockeru)

1. Vytvořte virtuální prostředí:
```bash
python -m venv venv
source venv/bin/activate
```

2. Nainstalujte závislosti:
```bash
pip install -r requirements.txt
```

3. Nastavte připojení k MariaDB (upravte v `app.py` nebo použijte env proměnnou DATABASE_URL)

4. Spusťte aplikaci:
```bash
python app.py
```

## Struktura projektu

- `app.py` - hlavní soubor aplikace s Flask routes a SQLAlchemy modely
- `templates/` - HTML šablony
- `static/` - CSS styly
- `Dockerfile` - definice Docker image pro Flask aplikaci
- `docker-compose.yml` - orchestrace Flask a MariaDB kontejnerů
- `requirements.txt` - Python závislosti

## Databáze

- **Engine**: MariaDB 11.2
- **Databáze**: formular_db
- **Tabulka**: form_submissions
- **Sloupce**: id, name, email, message, created_at

## Health Check

Aplikace obsahuje health check endpoint:
```
GET /health
```

## Technologie

- Flask 3.0.0
- Flask-SQLAlchemy
- MariaDB 11.2
- Docker & Docker Compose
- PyMySQL
