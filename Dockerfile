# Použití oficiálního Python obrazu
FROM python:3.10-slim

# Nastavení pracovního adresáře
WORKDIR /app

# Kopírování requirements a instalace závislostí
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Kopírování aplikace
COPY . .

# Exponování portu
EXPOSE 5001

# Spuštění aplikace
CMD ["python", "app.py"]
