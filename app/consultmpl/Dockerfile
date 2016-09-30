FROM docker:1.11

MAINTAINER laurent.bernaille@gmail.com

ARG ctmpl_version=0.16.0
RUN curl -sSL https://releases.hashicorp.com/consul-template/${ctmpl_version}/consul-template_${ctmpl_version}_linux_amd64.zip -o /tmp/consultemplate.zip && \
        unzip /tmp/consultemplate.zip -d /usr/local/bin && \
        rm /tmp/consultemplate.zip

RUN mkdir /haproxy
ADD haproxy.cfg /haproxy/haproxy.cfg
ADD haproxy.ctmpl /haproxy/haproxy.ctmpl
ADD nobackend.http /haproxy/nobackend.http

VOLUME /haproxy

CMD [ "/usr/local/bin/consul-template", "--help"] 
