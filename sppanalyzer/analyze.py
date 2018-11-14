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
    logfullpath = get_log_fullpath(logdir) + "/virgo/all_logs.log"
    p = Parser()
    return jsonify(p.get_joboverview_data(logfullpath))


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


class Parser:

    def __init__(self):
        self.catalog_matcher = re.compile("catalog")
        self.on_demand_restore_matcher = re.compile("onDemandRestore")
        self.maintenance_matcher = re.compile("Maintenance")
        self.vmware_matcher = re.compile("vmware_")
        self.hyper_v_matcher = re.compile("hyperv_")
        self.sql_matcher = re.compile("sql_")
        self.db2_matcher = re.compile("db2_")
        self.oracle_matcher = re.compile("oracle_")

    @staticmethod
    def get_timestamp_from_id(job_id):
        return job_id[:-3]

    def job_classifier(self, job_name):
        job_type, sla_name = None, None
        if self.catalog_matcher.search(job_name):
            job_type = "SPP"
            sla_name = "Catalog"
        elif self.on_demand_restore_matcher.search(job_name):
            job_type = "SPP"
            sla_name = "On-Demand Restore"
        elif self.maintenance_matcher.search(job_name):
            job_type = "SPP"
            sla_name = "Maintenance"
        elif self.vmware_matcher.search(job_name):
            job_type = "VMware"
            sla_name = "_".join(job_name.split("_")[1:])
        elif self.hyper_v_matcher.search(job_name):
            job_type = "Hyper-V"
            sla_name = "_".join(job_name.split("_")[1:])
        elif self.oracle_matcher.search(job_name):
            job_type = "Oracle"
            sla_name = "_".join(job_name.split("_")[1:])
        elif self.sql_matcher.search(job_name):
            job_type = "SQL"
            sla_name = "_".join(job_name.split("_")[1:])
        elif self.db2_matcher.search(job_name):
            job_type = "DB2"
            sla_name = "_".join(job_name.split("_")[1:])
        else:
            job_type = "SPP"
            sla_name = job_name
        return sla_name, job_type

    def get_joboverview_data(self, log_path):
        job_pattern = re.compile("[0-9]{13} ===== Starting job for policy .*\. id")
        vm_job_pattern = re.compile("[0-9]{13} vmWrapper .* type vm")
        job_app_pattern = re.compile("[0-9]{13} Options for database .*")
        completion_pattern = re.compile("[0-9]{13} .* completed.*with status .*")
        completion_type_matcher = re.compile("(COMPLETED|PARTIAL|FAILED|RESOURCE ACTIVE)")
        job_id_pattern = re.compile("[0-9]{13}")
        universal_dict = {}
        for line in open(log_path, "r"):
            line = re.sub("\s+", " ", line)
            res = job_pattern.search(line)
            if (res):
                job_id = res.group(0)[0:13]
                job_name = " ".join(res.group(0).split(" ")[6:-9])
                universal_dict[job_id] = {}
                universal_dict[job_id]["JobID"] = job_id
                universal_dict[job_id]["StartDateTime"] = self.get_timestamp_from_id(job_id)
                universal_dict[job_id]["SLA"], universal_dict[job_id]["JobType"] = self.job_classifier(job_name)
                universal_dict[job_id]["Targets"] = ""
                continue
            vm = vm_job_pattern.search(line)
            if vm:
                key = vm.group(0).split(' ')[0]
                val = vm.group(0).split(' ')[2]
                if universal_dict.get(key) is None:
                    universal_dict[key] = {}
                    universal_dict[key]["JobId"] = key
                universal_dict[key]["Targets"] = universal_dict[key]["Targets"] + f":{val}" if universal_dict[key][
                    "Targets"] else f"{val}"
                continue
            job_apps = job_app_pattern.search(line)
            if job_apps:
                key = job_apps.group(0).split(' ')[0]
                val = job_apps.group(0).split(' ')[4][0:-3]
                if universal_dict.get(key) is None:
                    universal_dict[key] = {}
                    universal_dict[key]["JobId"] = key
                universal_dict[key]["Targets"] = universal_dict[key]["Targets"] + f":{val}" if universal_dict[key][
                    "Targets"] else f"{val}"
                continue
            completion = completion_pattern.search(line)
            if completion:
                completion_type = completion_type_matcher.search(line)
                key = job_id_pattern.search(line).group(0)
                if universal_dict.get(key) is None:
                    universal_dict[key] = {}
                    universal_dict[key]["JobId"] = key
                if completion_type:
                    universal_dict[key]["Result"] = completion_type.group(0)
                else:
                    universal_dict[key]["Result"] = "UNKNOWN"

        ret = [universal_dict[i] for i in universal_dict]
        return ret
