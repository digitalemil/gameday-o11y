#!/bin/bash

cd /opt/app

/usr/sbin/nginx &

export WITH_CDC=true

/opt/app/minio.sh 

DASHBOARD_FOLDER=localdashboards
METRICSPATH=/_status/vars
TARGET=$(cat <<-END
static_configs:
      - targets: ['127.0.0.1:8088']
END

)

DEDICATEDTARGET=$(cat <<-END
static_configs:
      - targets: ['cockroachlabs.cloud']
    scheme: 'https'
    authorization:
      credentials: '${secret_key}'
END

)

if [[ "$DEDICATED" == "true" ]]; then
  echo Enable Metrics export...
  curl --request POST \
    --url https://cockroachlabs.cloud/api/v1/clusters/$cluster_id/metricexport/prometheus \
    --header "Authorization: Bearer $secret_key"
  DASHBOARD_FOLDER=dedicateddashboards
  METRICSPATH=/api/v1/clusters/$cluster_id/metricexport/prometheus/$cluster_region/scrape
  TARGET=$DEDICATEDTARGET
fi
echo TARGET:$TARGET
export TARGET
export METRICSPATH
if [[ "$DEDICATED" != "true" ]]; then
  /opt/app/cockroach/cockroach start-single-node --insecure --http-addr :8088 >$LOGFOLDER/cockroachdb.log 2>&1  &
fi

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
cp /opt/app/$DASHBOARD_FOLDER/*.json /var/lib/grafana/dashboards/

#CREATE CHANGEFEED INTO  "s3://cockroachdb?AWS_ACCESS_KEY_ID=cockroachdb&AWS_SECRET_ACCESS_KEY=cockroachdb&AWS_ENDPOINT=http://127.0.0.1:9000" WITH updated, split_column_families AS SELECT * FROM Heartrates;
#CREATE CHANGEFEED FOR TABLE heartrates INTO 's3://cockroachdb?AWS_ACCESS_KEY_ID=cockroachdb&AWS_SECRET_ACCESS_KEY=cockroachdb&AWS_ENDPOINT=http://127.0.0.1:9000&AWS_REGION=eu-west-1' with updated, split_column_families, resolved='10s';

if [[ "$DEDICATED" == "true" ]]; then
  sleep 20
  echo Waiting a bit...
  curl --request GET \
    --url https://cockroachlabs.cloud/api/v1/clusters/$cluster_id/metricexport/prometheus \
    --header "Authorization: Bearer $secret_key"
fi

tail -f /dev/null