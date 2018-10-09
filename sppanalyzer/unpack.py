import os
import zipfile
import gzip
import re
from glob import glob
from flask import Flask, flash, request, redirect, url_for, Blueprint, render_template, jsonify
from flask import current_app as app
from werkzeug.utils import secure_filename

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
        combine_virgo_logs(fullfilepath)
        return jsonify({"status":"UNPACKED","path":fullfilepath,"logkey":logkey})
    except:
        return jsonify({"status":"ERROR","logkey":logkey})

def combine_virgo_logs(fullfilepath):
    virgopath = os.path.join(get_log_fullpath(fullfilepath), "virgo")
    output = open(os.path.join(virgopath,"all_logs.log"), "w", buffering=1024)
    logfiles = glob(os.path.join(virgopath,"log*.log"))
    logfiles.sort(key=natural_keys, reverse=True)
    for fname in logfiles:
        with open(fname) as f:
            for line in f:
                output.write(line)
        f.close()
        os.remove(fname)
    output.close()

def atoi(text):
    return int(text) if text.isdigit() else text

def natural_keys(text):
    return [ atoi(c) for c in re.split('(\d+)', text) ]

def get_log_fullpath(logdir):
    for name in os.listdir(logdir):
        if os.path.isdir(os.path.join(logdir,name)):
            return os.path.join(logdir,name)
