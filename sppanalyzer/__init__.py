import os

from flask import Flask


def create_app(test_config=None):
    # create and configure the app
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_mapping(
        SECRET_KEY='dev'
    )
    app.config.from_pyfile('config.py')

    if test_config is None:
        # load the instance config, if it exists, when not testing
        app.config.from_pyfile('config.py', silent=True)
    else:
        # load the test config if passed in
        app.config.from_mapping(test_config)

    # ensure the instance folder exists
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    # a simple page
    @app.route('/test')
    def hello():
        return app.config['UPLOAD_FOLDER']

    from . import upload
    app.register_blueprint(upload.bp)

    from . import unpack
    app.register_blueprint(unpack.bp)

    from . import analyze
    app.register_blueprint(analyze.bp)

    return app
