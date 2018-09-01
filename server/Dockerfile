FROM mitmproxy/mitmproxy:4.0.4

COPY --chown=mitmproxy .mitmproxy/* /home/mitmproxy/.mitmproxy/

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt && rm /tmp/requirements.txt

RUN mkdir /proxydata && chown mitmproxy:mitmproxy /proxydata
