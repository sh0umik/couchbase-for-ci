FROM ubuntu:16.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc

RUN curl -O https://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-6-amd64.deb && \
    dpkg -i ./couchbase-release-1.0-6-amd64.deb && apt-get -y update && apt-get -y install couchbase-server-community

#Add runit services
COPY sv /etc/service 

#Initialize
RUN runsvdir-start & \
    until curl http://127.0.0.1:8091; do echo "waiting for API server to come online..."; sleep 3; done && \
    mkdir -p /tmp/couchbase-data /tmp/couchbase-index && \
    /opt/couchbase/bin/couchbase-cli node-init -c localhost --node-init-data-path=/tmp/couchbase-data --node-init-index-path=/tmp/couchbase-index --user=admin --password=password && \
    /opt/couchbase/bin/couchbase-cli cluster-init -c localhost --cluster-username=admin --cluster-password=password --cluster-ramsize=384 --cluster-index-ramsize=384 --services=data,index,query && \
    /opt/couchbase/bin/couchbase-cli bucket-create -c localhost --bucket=data --bucket-type=couchbase --bucket-ramsize=100 --bucket-replica=0 --user=admin --password=password && \
    sv stop couchbase
  
