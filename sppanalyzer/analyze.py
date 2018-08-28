import os
from flask import Flask, flash, request, redirect, url_for, Blueprint, render_template, jsonify
from werkzeug.utils import secure_filename

app = Flask(__name__)

bp = Blueprint('analyze', __name__, url_prefix='/analyze')

@bp.route('/loglist', methods=['GET'])
def get_loglist():
    # get already analyzed/unpacked list of logs return as JSON
    return None

@bp.route('/joblist', methods=['GET', 'POST'])
def get_joblist():
    # GET requires param of existing log unpack directory
    # function determines if analyze datafile needs to be generated
    # if so: runs script to generate .csv datafile
    # returns JSON of log list
    # optional parameter of date range
    return None

@bp.route('/jobdetails', methods=['GET'])
def get_job_details():
    # Requires param of existing log unpack directory and job session ID
    # function determines if analyze datafile needs to be generated
    # if so: runs script with proper args to generate
    # returns JSON of job details, errors, etc.
    return None

