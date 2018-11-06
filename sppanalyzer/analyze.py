import os
import csv
import re
import json
import subprocess
from flask import Flask, flash, request, redirect, url_for, Blueprint, render_template, jsonify
from flask import current_app as app
from werkzeug.utils import secure_filename
import parser

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
    p = parser.get(logfullpath + "/virgo/all_logs.log")
    return jsonify(p.get_joboverview_data())
    #check if exists first
    # if not os.path.isfile(os.path.join(logdir, 'virgoLogIndex.csv')):
    #     subprocess.check_call([os.getcwd() + "/sppanalyzer/scripts/virgoCsv.sh",
    #                            logfullpath + "/virgo/all_logs.log"],
    #                            cwd=logdir)
    # csvfile = logdir + '/virgoLogIndex.csv'
    # return csv_to_json(csvfile)


def get_jobdetails_data(logdir, jobsession):
    logfullpath = get_log_fullpath(logdir)
    currwd = os.getcwd()
    os.chdir(os.getcwd() + "/sppanalyzer/scripts/")
    out, err = subprocess.Popen([os.getcwd() + "/virgoLogExtractor.sh",
                                logfullpath + "/virgo/all_logs.log", jobsession],
                                stdout=subprocess.PIPE).communicate()
    loglines = out.decode('utf-8').splitlines()
    for i, line in enumerate(loglines, 0):
        while not loglines[i].startswith("["):
            loglines[i-1] = loglines[i-1] + "\n" + loglines[i]
            del loglines[i]
    for i, line in enumerate(loglines, 0):
        logobj = {}
        logelements = re.split("\s+",line,5)
        logobj['date'] = logelements[0]
        logobj['loglevel'] = logelements[1]
        logobj['thread'] = logelements[2]
        logobj['class'] = logelements[3]
        logobj['sessionid'] = logelements[4]
        logobj['message'] = logelements[5]
        loglines[i] = logobj
    os.chdir(currwd)
    return jsonify(loglines)

def csv_to_json(csvfile):
    with open(csvfile) as f:
        dictcsv = [{k: str(v) for k, v in row.items()}
                   for row in csv.DictReader(f, skipinitialspace=True)]
    return jsonify(dictcsv)
