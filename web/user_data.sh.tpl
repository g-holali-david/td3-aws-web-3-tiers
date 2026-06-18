#!/bin/bash
set -e
dnf install -y python3 python3-pip
pip3 install flask gunicorn requests

mkdir -p /opt/web
cat > /opt/web/web.py <<'PYEOF'
${web_code}
PYEOF

cat > /etc/systemd/system/web.service <<'UNIT'
[Unit]
Description=Tier Web (Flask formulaire)
After=network.target

[Service]
Environment=INTERNAL_ALB_DNS=${internal_alb_dns}
WorkingDirectory=/opt/web
ExecStart=/usr/local/bin/gunicorn --workers 2 --bind 0.0.0.0:80 web:app
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now web
