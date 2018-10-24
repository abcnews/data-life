# Server setup

The first step is upload the files to the docker host. Skip this step if you're using `docker-machine` or working with a locally installed docker host.

```bash
rsync -rvP ../server root@$VPN_IP:~/
```

There are a few environment variables that need to be set. See `.envrc-template` for details.

## Running the docker containers

There are two docker containers. The first is an extended version of `mitmproxy/mitmproxy:4.0.4` which is built from the `Dockerfile` in `server`. The second is a VPN image which is necessary for reliably intercepting iOS traffic when switching between networks (wi-fi ↔ mobile).

The server used for intercepting iOS traffic should live on a publicly accessible server so it can be reached from the mobile data connection.

SSH into the docker host and change into the server directory.

```bash
ssh root@$VPN_IP
cd server
```

Run the VPN and mitmproxy containers using `docker-compose`

```bash
source .envrc
docker-compose build
docker-compose up -d
```

To run just the proxy (i.e. if you're running on a local docker host to intercept local traffic) you can just run:

```
docker-compose up -d mitmproxy
```

The proxy and VPN containers are setup so that the proxy will only accept connections from the local network. This avoids the proxy attracting junk traffic from proxy sniffers. It also avoids a number of complications involved in requiring auth for the proxy. For a transparent proxy config option see below.

To get iOS connecting to the VPN and sending traffic through the proxy, you'll need to airdrop a `.mobileconfig` file that has all the VPN and proxy settings. It's not possible to setup these details manually in the iOS settings app and also ensure that the VPN automatically re-connects when the connection is dropped.

### iOS profile

The `.mobileconfig` profile specifications are templated to avoid putting secrets into this repo. Run the following commands from bash to template them from environment vars.

```bash
perl -pe 's;(\\*)(\$([a-zA-Z_][a-zA-Z_0-9]*)|\$\{([a-zA-Z_][a-zA-Z_0-9]*)\})?;substr($1,0,int(length($1)/2)).($2&&length($1)%2?$2:$ENV{$3||$4});eg' vpn-proxied.tmpl.mobileconfig > vpn-proxied.mobileconfig
```

## Transparent proxy setup

This has been left here for posterity because it took me forever to figure out.

One method for setup is to transparently proxy the traffic exiting the VPN. This works well, but the one major drawback is that we lose the host domain name from the request and can only capture the IP address.

If deploying the `docker-compose.yaml` with `mitmproxy` run in transparent mode, these settings will be required. You'll need to modify the `command` call in the compose file and switch to using the host network.

The docker containers must use host networking to avoid having to set `iptables` rules in each container. With host networking specified, all we need to do is make sure all port 80 and 443 tcp traffic is redirected to port 8080, pushing it into the proxy container which is running in transparent mode.

```bash
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8080
ip6tables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
ip6tables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8080
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

These `iptables` settings can be undone with by passing `-D` instead of `-A`:

```bash
iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8080
ip6tables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
ip6tables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8080
iptables -D INPUT -p tcp --dport 8080 -j ACCEPT
ip6tables -D INPUT -p tcp --dport 8080 -j ACCEPT
```

## Credits

Aside from [mitmproxy](https://mitmproxy.org) itself I also used a [script from Ed Medvedev](https://github.com/mitmproxy/mitmproxy/pull/2861) to dump all the recorded data to disk.
