import os
import csv
import re
import json
import subprocess
from flask import Flask, flash, request, redirect, url_for, Blueprint, render_template, jsonify
from flask import current_app as app
from werkzeug.utils import secure_filename

bp = Blueprint('analyze', __name__, url_prefix='/analyze')


@bp.route('/joblist', methods=['GET'])
def render_joblist_page():
    # GET requires param of logkey for persistence
    # requires virgolog which can be multiple params
    logkey = request.args.get('logkey')
    keys = os.listdir(app.config['UPLOAD_FOLDER'])
    if logkey in keys:
        return render_template('joblist.html', logkey=logkey)
    else:
        return jsonify({'status':'error','message':'Log key not found'})

@bp.route('/joboverview', methods=['GET'])
def get_joboverview():
    logkey = request.args.get('logkey')
    virgologs = request.args.getlist('virgolog')
    logdir = app.config['UPLOAD_FOLDER'] + "/" + logkey
    jsondata = get_joboverview_data(logdir)
    return jsondata

@bp.route('/jobdetails', methods=['GET'])
def get_job_details():
    logkey = request.args.get('logkey')
    jobsession = request.args.get('jobsession')
    logdir = app.config['UPLOAD_FOLDER'] + "/" + logkey
    jsondata = get_jobdetails_data(logdir, jobsession)
    return jsondata

@bp.route('/applianceinfo', methods=['GET'])
def get_appliance_info():
    logkey = request.args.get('logkey')
    logdir = app.config['UPLOAD_FOLDER'] + "/" + logkey
    logfullpath = get_log_fullpath(logdir)
    logbundle = logfullpath.rsplit('/',1)[1]
    logname = logbundle.rsplit('_logs_',1)[0]
    logdate = logbundle.rsplit('_logs_',2)[1].replace("_","/",2).replace("_"," ",1).replace("_",":",2).replace("_"," ")
    release = get_app_release_info(logfullpath)
    rpminfo = get_rpm_info(logfullpath)
    appinfo = {}
    appinfo['name'] = logname
    appinfo['date'] = logdate
    appinfo['release'] = release
    appinfo['rpminfo'] = rpminfo
    return jsonify(appinfo)

def get_app_release_info(logfullpath):
    release = open(os.path.join(logfullpath,'release'),'r')
    reldata = release.read()
    release.close()
    return json.loads(reldata.replace('\n',''))

def get_rpm_info(logfullpath):
    with open(os.path.join(logfullpath,'system/rpminfo.txt'),'r') as f:
        rpminfo = f.readlines()
    rpminfo = [l.strip() for l in rpminfo]
    return rpminfo

def get_log_fullpath(logdir):
    # Need to find better way here or ensure only one directory exists in logdir
    for name in os.listdir(logdir):
        if os.path.isdir(os.path.join(logdir,name)):
            return os.path.join(logdir,name)

def virgo_log_exists(virgolog, logdir):
    logfullpath = get_log_fullpath(logdir)
    virgologlist = os.listdir(logfullpath + "/virgo")
    if virgolog in virgologlist:
        return True
    else:
        return False

def get_joboverview_data(logdir):
    logfullpath = get_log_fullpath(logdir)
    #check if exists first
    if not os.path.isfile(os.path.join(logdir, 'virgoLogIndex.csv')):
        subprocess.check_call([os.getcwd() + "/sppanalyzer/scripts/virgoCsv.sh",
                               logfullpath + "/virgo/all_logs.log"],
                               cwd=logdir)
    csvfile = logdir + '/virgoLogIndex.csv'
    return csv_to_json(csvfile)

def get_jobdetails_data(logdir, jobsession):
    logfullpath = get_log_fullpath(logdir)
    loglines = []
    pattern = re.compile(".{90,110}" + jobsession) # variable number,
    # mainly to avoid matches where the jobsession is contained later in the line,
    #  even though the jobsession is not the right one. If there's a smarter way, need to change #TODO
    with open(logfullpath + "/virgo/all_logs.log", "r") as f:
        for line in f:
            job_id = pattern.search(line)
            if (job_id):
                curr_dict = {}
                l = re.sub("\s+", " ", line).split(" ")
                curr_dict['date'] = l[0]
                curr_dict['loglevel'] = l[1]
                curr_dict['thread'] = l[2]
                curr_dict['class'] = l[3]
                curr_dict['sessionid'] = l[4]
                curr_dict['message'] = " ".join(l[5:])
                loglines.append(curr_dict)
    return jsonify(loglines)

def csv_to_json(csvfile):
    with open(csvfile) as f:
        dictcsv = [{k: str(v) for k, v in row.items()}
                   for row in csv.DictReader(f, skipinitialspace=True)]
    return jsonify(dictcsv)
