from flask import Flask, render_template, url_for, request, redirect
from datetime import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///test.db'


@app.route('/')
def index():
    return render_template('index.html', page='Home')


@app.route('/setup')
def setup():
    return "ToDo"


@app.route('/doc')
def view_doc():
    return "ToDo"


if __name__ == "__main__":
    app.run(debug=True)
