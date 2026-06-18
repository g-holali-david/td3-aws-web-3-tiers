#!/bin/bash
set -e
dnf install -y python3 python3-pip
pip3 install flask gunicorn psycopg2-binary

mkdir -p /opt/app
cat > /opt/app/app.py <<'PYEOF'
${app_code}
PYEOF

cat > /etc/systemd/system/app.service <<'UNIT'
[Unit]
Description=Tier App (Flask API)
After=network.target

[Service]
Environment=DB_HOST=${db_host}
Environment=DB_NAME=${db_name}
Environment=DB_USER=${db_user}
Environment=DB_PASSWORD=${db_password}
WorkingDirectory=/opt/app
ExecStart=/usr/local/bin/gunicorn --workers 2 --bind 0.0.0.0:80 app:app
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now app
