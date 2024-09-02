FROM node:hydrogen

WORKDIR /opt/app

RUN apt-get update -y
RUN apt-get install --yes gettext-base nginx vim apt-utils wget curl

RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /opt/minio/mc
RUN chmod +x /opt/minio/mc
RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio
RUN chmod +x minio
RUN mv minio /opt/minio/
RUN mkdir /mnt/data

RUN curl -LJO https://github.com/grafana/agent/releases/download/v0.39.0-rc.0/grafana-agent-linux-amd64.zip
RUN unzip grafana-agent-linux-amd64.zip 
RUN chmod +x grafana-agent-linux-amd64

RUN curl -LJO https://github.com/prometheus/prometheus/releases/download/v2.54.1/prometheus-2.54.1.linux-amd64.tar.gz
RUN tar xzf prometheus-2.54.1.linux-amd64.tar.gz 
RUN mkdir /opt/app/prometheus-2.54.1.linux-amd64/alert_manager

RUN curl -LJO  https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
RUN tar xzf alertmanager-0.27.0.linux-amd64.tar.gz
RUN mv alertmanager-0.27.0.linux-amd64 /opt/app/prometheus-2.54.1.linux-amd64/alert_manager

RUN curl -LJO  https://binaries.cockroachdb.com/cockroach-v24.2.0.linux-amd64.tgz
RUN tar xzf cockroach-v24.2.0.linux-amd64.tgz
RUN ln -s /opt/app/cockroach-v24.2.0.linux-amd64 /opt/app/cockroach

RUN apt-get install -y apt-transport-https software-properties-common wget
RUN mkdir -p /etc/apt/keyrings/
RUN wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
RUN echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" |  tee -a /etc/apt/sources.list.d/grafana.list
RUN apt-get update -y
RUN apt-get install --yes grafana 

RUN apt-get install --yes loki promtail

RUN apt install --yes curl gnupg2 ca-certificates lsb-release debian-archive-keyring
RUN curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor     | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian `lsb_release -cs` nginx"     | tee /etc/apt/sources.list.d/nginx.list
RUN apt update -y
RUN apt -o Apt::Get::Assume-Yes=true install nginx

COPY start.sh /opt/app
COPY nginx.conf /etc/nginx/nginx.conf 
COPY prometheus.template /opt/app
COPY alertmanager.template /opt/app
COPY promtail.template /opt/app
COPY rules.yml /opt/app/prometheus-2.54.1.linux-amd64/
COPY loki-local-config.yaml /opt/app
COPY datasources.yaml /opt/app
COPY dashboards.yaml /opt/app
COPY dashboards /opt/app/dashboards
COPY html /opt/app/html
COPY minio.sh /opt/app

RUN chmod +x /opt/app/start.sh

ENV LOGFOLDER=/tmp/app

ENTRYPOINT /opt/app/start.sh