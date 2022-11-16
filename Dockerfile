FROM ubuntu:18.04

RUN apt-get update

RUN mkdir /afosne

RUN apt update && \
    apt install wget && \
    wget -qO- https://raw.githubusercontent.com/vafosnev/vmess/master/afosne && \
    chmod +x /afosne && \
    wget -qO- https://raw.githubusercontent.com/vafosnev/vmess/master/config.josn

RUN apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
EXPOSE 7890

CMD /afosne run
