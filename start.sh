#!/bin/bash

cd /opt/app

/usr/sbin/nginx &

export WITH_CDC=true

/opt/app/minio.sh 

echo Enable Metrics export...
curl --request POST \
  --url https://cockroachlabs.cloud/api/v1/clusters/$cluster_id/metricexport/prometheus \
  --header "Authorization: Bearer $secret_key"

sleep 20
echo Waiting a bit...
curl --request GET \
  --url https://cockroachlabs.cloud/api/v1/clusters/$cluster_id/metricexport/prometheus \
  --header "Authorization: Bearer $secret_key"


envsubst < /opt/app/prometheus.template >/opt/app/prometheus.conf

/opt/app/prometheus-2.49.1.linux-amd64/prometheus --web.listen-address="0.0.0.0:9090" --config.file=/opt/app/prometheus.conf >$LOGFOLDER/../prometheus.log 2>&1  &

/usr/bin/loki -config.file=/opt/app/loki-local-config.yaml >$LOGFOLDER/../loki.log 2>&1  &

envsubst < /opt/app/datasources.yaml >/usr/share/grafana/conf/provisioning/datasources/datasources.yaml
cp /opt/app/dashboards.yaml /usr/share/grafana/conf/provisioning/dashboards/

cd /usr/share/grafana;
./bin/grafana server >$LOGFOLDER/../grafana.log 2>&1 &
cd /opt/app

mkdir -p /var/lib/grafana/dashboards

export __rate_interval='$__rate_interval'
envsubst < /opt/app/dashboard.json >/var/lib/grafana/dashboards/dashboard.json
envsubst < /opt/app/dashboard2.json >/var/lib/grafana/dashboards/dashboard2.json

#CREATE CHANGEFEED INTO  "s3://cockroachdb?AWS_ACCESS_KEY_ID=cockroachdb&AWS_SECRET_ACCESS_KEY=cockroachdb&AWS_ENDPOINT=http://127.0.0.1:9000" WITH updated, split_column_families AS SELECT * FROM Heartrates;
#CREATE CHANGEFEED FOR TABLE heartrates INTO 's3://cockroachdb?AWS_ACCESS_KEY_ID=cockroachdb&AWS_SECRET_ACCESS_KEY=cockroachdb&AWS_ENDPOINT=http://127.0.0.1:9000&AWS_REGION=eu-west-1' with updated, split_column_families, resolved='10s';

tail -f /dev/null