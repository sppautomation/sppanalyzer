import os
import csv
import json
import subprocess
from flask import Flask, flash, request, redirect, url_for, Blueprint, render_template, jsonify
from flask import current_app as app
from werkzeug.utils import secure_filename

bp = Blueprint('analyze', __name__, url_prefix='/analyze')

@bp.route('/joblist', methods=['GET'])
def render_joblist_page():
    # GET requires param of log key for persistence
    logkey = request.args.get('logkey')
    keys = os.listdir(app.config['UPLOAD_FOLDER'])
    if logkey in keys:
        return render_template('joblist.html', logkey=logkey)
    else:
        return jsonify({'status':'error','message':'Log key not found'})

@bp.route('/joboverview', methods=['GET'])
def get_joboverview():
    logkey = request.args.get('logkey')
    logdir = app.config['UPLOAD_FOLDER'] + "/" + logkey
    jsondata = get_joboverview_data(logdir)
    return jsondata

@bp.route('/jobdetails', methods=['GET'])
def get_job_details():
    logkey = request.args.get('logkey')
    jobsession = request.args.get('jobsession')
    logdir = app.config['UPLOAD_FOLDER'] + "/" + logkey
    # Requires param of log key and job session ID
    # function determines if analyze datafile needs to be generated
    # if so: runs script with proper args to generate
    # returns JSON of job details, errors, etc.
    return None

def get_log_fullpath(logdir):
    # Need to find better way here or ensure only one directory exists in logdir
    for name in os.listdir(logdir):
        if os.path.isdir(os.path.join(logdir,name)):
            return os.path.join(logdir,name)

def get_joboverview_data(logdir):
    logfullpath = get_log_fullpath(logdir)
    #check if exists first
    subprocess.check_call([os.getcwd() + "/sppanalyzer/scripts/virgoCsv.sh",
                           logfullpath + "/virgo/log.log"],
                           cwd=logdir)
    csvfile = logdir + '/virgoLogIndex.csv'
    return csv_to_json(csvfile)

def get_jobdetails_data(logdir):
    return None

def csv_to_json(csvfile):
    with open(csvfile) as f:
        dictcsv = [{k: str(v) for k, v in row.items()}
                   for row in csv.DictReader(f, skipinitialspace=True)]
    return jsonify(dictcsv)
