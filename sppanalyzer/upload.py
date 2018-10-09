import os
import random
import string
from flask import Flask, flash, request, redirect, url_for, Blueprint, render_template, jsonify, Response
from flask import current_app as app
from werkzeug.utils import secure_filename

ALLOWED_EXTENSIONS = set(['zip'])

bp = Blueprint('upload', __name__, url_prefix='/')


def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@bp.route('/upload', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        if 'file' not in request.files:
            return Response('{"message":"No file selected"}', status=400, mimetype='application/json')
        if not free_space_available():
            return Response('{"message":"Not enough free space available."}', status=400, mimetype='application/json')
        file = request.files['file']
        if file.filename == '':
            return Response('{"message":"No file selected"}', status=400, mimetype='application/json')
        if file and not allowed_file(file.filename):
            return Response('{"message":"Extension not allowed"}', status=400, mimetype='application/json')
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            logkey = ''.join(random.choice(string.ascii_letters + string.digits) for x in range(10))
            fullfilepath = os.path.join(app.config['UPLOAD_FOLDER'], logkey)
            if not os.path.exists(fullfilepath):
                os.makedirs(fullfilepath)
            file.save(os.path.join(fullfilepath, filename))
            return jsonify({"message":"COMPLETE","fullfilepath":fullfilepath,"filename":filename,"logkey":logkey})
    #for GET return page template
    return render_template('upload.html')

def free_space_available():
    fs = os.statvfs(app.config['UPLOAD_FOLDER'])
    freespace = fs.f_frsize * fs.f_bfree / 1024 / 1024
    if freespace > int(app.config['SPACE_THRESHOLD']):
        return True
    else:
        return False
