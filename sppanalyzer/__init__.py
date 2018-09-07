import os

from flask import Flask, request

app = Flask(__name__)

app.config.from_pyfile('config.py')

# ensure the instance folder exists
try:
    os.makedirs(app.instance_path)
except OSError:
    pass

# a simple page
@app.route('/test')
def hello():
    return "This is a test"

from . import upload
app.register_blueprint(upload.bp)

from . import unpack
app.register_blueprint(unpack.bp)

from . import analyze
app.register_blueprint(analyze.bp)

if __name__ == "__main__":
    app.run(host='0.0.0.0')
