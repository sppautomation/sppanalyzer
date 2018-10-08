import os
import time
from flask import Blueprint, current_app as app
from flask import

bp = Blueprint('delete', __name__, url_prefix='/delete')

@bp.route("", methods=["OPTIONS", "POST", "GET"])  #Doesn't matter which we end up implementing
def delete_old_logs():
    now = time.time()
    for name in os.listdir(app.config["UPLOAD_FOLDER"]):
        dir = os.path.join(app.config["UPLOAD_FOLDER"], name)
        if os.path.isdir(dir):
            if os.stat(dir).st_mtime < now - (app.config["FILE_EXPIRATION_TIME"] * 86400):
                os.rmdir(dir)