from flask import Flask, render_template, request, redirect, url_for
from flask_sqlalchemy import SQLAlchemy
import os
from datetime import datetime

app = Flask(__name__)

# Konfigurace databáze
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
    'DATABASE_URL',
    'mysql+pymysql://root:password@db:3306/formular_db'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Model pro ukládání dat z formuláře
class FormData(db.Model):
    __tablename__ = 'form_submissions'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), nullable=False)
    message = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<FormData {self.name}>'

# Vytvoření tabulek při startu aplikace
with app.app_context():
    db.create_all()

@app.route('/')
def index():
    """Hlavní stránka s formulářem"""
    return render_template('index.html')

@app.route('/submit', methods=['POST'])
def submit():
    """Zpracování formuláře"""
    name = request.form.get('name')
    email = request.form.get('email')
    message = request.form.get('message')
    
    # Uložení dat do databáze
    new_entry = FormData(name=name, email=email, message=message)
    db.session.add(new_entry)
    db.session.commit()
    
    return redirect(url_for('success'))

@app.route('/success')
def success():
    """Stránka s potvrzením"""
    return render_template('success.html')

@app.route('/data')
def show_data():
    """Zobrazení všech odeslaných dat"""
    data = FormData.query.order_by(FormData.created_at.desc()).all()
    return render_template('data.html', data=data)

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        # Zkontroluj připojení k databázi
        db.session.execute(db.text('SELECT 1'))
        return {'status': 'healthy', 'database': 'connected'}, 200
    except Exception as e:
        return {'status': 'unhealthy', 'error': str(e)}, 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=5001)
