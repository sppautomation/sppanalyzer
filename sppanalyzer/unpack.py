import os
import zipfile
import gzip
from flask import Flask, flash, request, redirect, url_for, Blueprint, render_template, jsonify
from werkzeug.utils import secure_filename

app = Flask(__name__)

bp = Blueprint('unpack', __name__, url_prefix='/')

@bp.route('/unpack', methods=['POST'])
def unpack_log_file():
    try:
        fullfilepath = request.args.get('fullfilepath')
        filename = request.args.get('filename')
        logkey = request.args.get('logkey')
        #unzip main file to directory with same name
        zip = zipfile.ZipFile(os.path.join(fullfilepath, filename), 'r')
        zip.extractall(fullfilepath)
        zip.close()
        #remove unneeded zip file
        os.remove(os.path.join(fullfilepath, filename))
        #loop through unpacked logs and unzip all gzips
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
                if filename.endswith(".zip"):
                    zip = zipfile.ZipFile(os.path.join(root,filename), 'r')
                    newfolder = filename.replace('.zip', '')
                    zip.extractall(os.path.join(root,newfolder))
                    zip.close()
                    os.remove(os.path.join(root,filename))
        return jsonify({"status":"unpacked","path":fullfilepath,"logkey":logkey})
    except:
        return jsonify({"status":"error unpacking","logkey":logkey})
