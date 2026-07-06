#!/bin/sh
sed "s|SEU_WEBHOOK_AQUI|${SLACK_WEBHOOK_URL}|g" /etc/alertmanager/alertmanager.tpl > /etc/alertmanager/alertmanager.yml
exec /bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --web.listen-address=:9093
