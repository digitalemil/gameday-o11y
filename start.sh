#!/bin/bash

cd /opt/app

/usr/sbin/nginx &

export WITH_CDC=true

/opt/app/minio.sh 

echo Enable Metrics export...
curl --request POST \
  --url https://cockroachlabs.cloud/api/v1/clusters/$cluster_id/metricexport/prometheus \
  --header "Authorization: Bearer $secret_key"


envsubst < /opt/app/prometheus.template >/opt/app/prometheus.conf
envsubst < /opt/app/alertmanager.template >/opt/app/prometheus-2.54.1.linux-amd64/alert_manager/alertmanager-0.27.0.linux-amd64/alertmanager.yml 
envsubst < /opt/app/promtail.template >/opt/app/promtail.config 

/opt/app/prometheus-2.54.1.linux-amd64/alert_manager/alertmanager-0.27.0.linux-amd64/alertmanager --config.file=/opt/app/prometheus-2.54.1.linux-amd64/alert_manager/alertmanager-0.27.0.linux-amd64/alertmanager.yml >$LOGFOLDER/alertmanager.log 2>&1  &

/opt/app/prometheus-2.54.1.linux-amd64/prometheus --web.enable-lifecycle --web.listen-address="0.0.0.0:9090" --config.file=/opt/app/prometheus.conf >$LOGFOLDER/prometheus.log 2>&1  &

/usr/bin/loki -config.file=/opt/app/loki-local-config.yaml >$LOGFOLDER/loki.log 2>&1  &

/usr/bin/promtail -config.file /opt/app/promtail.config >$LOGFOLDER/promtail.log 2>&1  &

envsubst < /opt/app/datasources.yaml >/usr/share/grafana/conf/provisioning/datasources/datasources.yaml
cp /opt/app/dashboards.yaml /usr/share/grafana/conf/provisioning/dashboards/

cd /usr/share/grafana;
./bin/grafana server >$LOGFOLDER/grafana.log 2>&1 &
cd /opt/app

mkdir -p /var/lib/grafana/dashboards
cp /opt/app/dashboards/*.json /var/lib/grafana/dashboards/

#CREATE CHANGEFEED INTO  "s3://cockroachdb?AWS_ACCESS_KEY_ID=cockroachdb&AWS_SECRET_ACCESS_KEY=cockroachdb&AWS_ENDPOINT=http://127.0.0.1:9000" WITH updated, split_column_families AS SELECT * FROM Heartrates;
#CREATE CHANGEFEED FOR TABLE heartrates INTO 's3://cockroachdb?AWS_ACCESS_KEY_ID=cockroachdb&AWS_SECRET_ACCESS_KEY=cockroachdb&AWS_ENDPOINT=http://127.0.0.1:9000&AWS_REGION=eu-west-1' with updated, split_column_families, resolved='10s';

sleep 20
echo Waiting a bit...
curl --request GET \
  --url https://cockroachlabs.cloud/api/v1/clusters/$cluster_id/metricexport/prometheus \
  --header "Authorization: Bearer $secret_key"

tail -f /dev/null