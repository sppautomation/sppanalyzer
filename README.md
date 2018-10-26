# SPP Analyzer

## Deployment

### Options
The Flask framework has many different options for deployment.
Based on current architecture a Linux platform is required in order to run the text parsing scripts.
```
http://flask.pocoo.org/docs/1.0/deploying/
```

### Example
Our internal environment is running CentOS 7 and using the uWSGI service running on port 3000 which forwards to Apache running on the default HTTP port 80.
The following guide outlines the installation of uWSGI, Apache, Python, and other dependencies on CentOS7
```
https://mitchjacksontech.github.io/How-To-Flask-Python-Centos7-Apache-uWSGI/
```

### uWSGI Example Configuration Files

````
uwsgi.py (located in root of cloned repository):

import os
from sppanalyzer import app as application

if __name__ == "__main__":
port = int(os.environ.get('PORT', 5000))
application.run(host='0.0.0.0', port=port)



app.ini (located in root of cloned repository):

[uwsgi]
module = wsgi

master = true
processes = 5

socket = 127.0.0.1:8000
chmod-socket = 660
vacuum = true

die-on-term = true

logto = /tmp/errlog



/etc/systemd/system/sppanalyzer.service
[Unit]
Description=uWSGI server for sppanalyzer
After=network.target

[Service]
User=sppanalyzer
Group=sppanalyzer
WorkingDirectory=/sppanalyzer
Environment="PATH=/sppanalyzer/.env/bin:/usr/bin:/bin"
ExecStart=/sppanalyzer/.env/bin/uwsgi --ini app.ini

[Install]
WantedBy=multi-user.target
````
