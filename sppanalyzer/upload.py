import os
import zipfile
import gzip
from flask import Flask, flash, request, redirect, url_for, Blueprint, render_template
from werkzeug.utils import secure_filename

UPLOAD_FOLDER = '/sppanalyzer/upload'
ALLOWED_EXTENSIONS = set(['zip'])

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

bp = Blueprint('upload', __name__, url_prefix='/')

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@bp.route('/upload', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        if 'file' not in request.files:
            return 'No file selected'
        file = request.files['file']
        if file.filename == '':
            return 'No file selected'
        if file and not allowed_file(file.filename):
            return 'Extension not allowed'
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            fullfilepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            if not os.path.exists(fullfilepath):
                os.makedirs(fullfilepath)
            file.save(os.path.join(fullfilepath, filename))
            unpack_log_file(fullfilepath, filename)
            return 'Complete'
    return render_template('upload.html')

def unpack_log_file(fullfilepath, filename):
    zip = zipfile.ZipFile(os.path.join(fullfilepath, filename), 'r')
    zip.extractall(fullfilepath)
    zip.close()
    os.remove(os.path.join(fullfilepath, filename))
    for root, directories, filenames in os.walk(fullfilepath):
        for filename in filenames:
            if filename.endswith(".gz"):
                infile = gzip.GzipFile(os.path.join(root,filename), 'rb')
                content = infile.read()
                infile.close()
                newfilename = filename.replace('.gz', '')
                outfile = open(os.path.join(root,newfilename), 'wb')
                outfile.write(content)
                outfile.close()
                os.remove(os.path.join(root,filename))

