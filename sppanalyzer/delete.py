import os
import time
import shutil
from flask import Blueprint, current_app as app, jsonify

bp = Blueprint('delete', __name__, url_prefix='/delete')

@bp.route("", methods=["OPTIONS", "POST", "GET"])  #Doesn't matter which we end up implementing
def delete_old_logs():
    now = time.time()
    try:
        for name in os.listdir(app.config["UPLOAD_FOLDER"]):
            log_dir = os.path.join(app.config["UPLOAD_FOLDER"], name)
            if os.path.isdir(log_dir):
                if os.stat(log_dir).st_mtime < now - (app.config["FILE_EXPIRATION_TIME"] * 86400):
                    shutil.rmtree(log_dir, ignore_errors=True)
        return jsonify({"message": "Deleted files", "status": 200})
    except Exception:
        return jsonify({"message": "Failed to delete files", "status": 500})