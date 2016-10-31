FROM haproxy:alpine

MAINTAINER laurent.bernaille@gmail.com

ARG ctmpl_version=0.16.0
RUN apk add --no-cache curl && \
        curl -sSL https://releases.hashicorp.com/consul-template/${ctmpl_version}/consul-template_${ctmpl_version}_linux_amd64.zip -o /tmp/consultemplate.zip && \
        unzip /tmp/consultemplate.zip -d /usr/local/bin && \
        rm /tmp/consultemplate.zip && \
        apk del curl

ADD haproxy.ctmpl /etc/haproxy/haproxy.ctmpl
ADD haproxy.cfg /etc/haproxy/haproxy.cfg
ADD nobackend.http /etc/haproxy/nobackend.http

ENTRYPOINT []
CMD [ "/usr/local/bin/consul-template", "-consul=consul:8500", "-template=/etc/haproxy/haproxy.ctmpl:/etc/haproxy/haproxy.cfg", "-exec=haproxy -p /run/haproxy.pid -f /etc/haproxy/haproxy.cfg" ] 
