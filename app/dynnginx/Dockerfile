FROM nginx:alpine

MAINTAINER laurent.bernaille@gmail.com

ARG ctmpl_version=0.16.0
RUN apk add --no-cache curl && \
        curl -sSL https://releases.hashicorp.com/consul-template/${ctmpl_version}/consul-template_${ctmpl_version}_linux_amd64.zip -o /tmp/consultemplate.zip && \
        unzip /tmp/consultemplate.zip -d /usr/local/bin && \
        rm /tmp/consultemplate.zip && \
        apk del curl

ADD nginx.ctmpl /etc/nginx/nginx.ctmpl
ADD nginx.conf /etc/nginx/nginx.conf
ADD nobackend.html /usr/share/nginx/html/index.html

ENTRYPOINT []
CMD [ "/usr/local/bin/consul-template", "-consul=consul:8500", "-template=/etc/nginx/nginx.ctmpl:/etc/nginx/nginx.conf", "-exec=nginx -g daemon off;", "-exec-reload-signal=SIGHUP" ] 
