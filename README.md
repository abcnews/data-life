# Data Life

Here I am man-in-the-middling myself and analysing the results.

## `server`

The `server` folder contains code that packages the setup into Docker images. Doing it this way is mostly for reproducibility and so I don't have to deal with python dependencies locally. Blowing it all away and starting again should be simple.

Check out `server/README.md` for more details.

## `analysis`

The `analysis` folder contains (mostly) R code for analysing the data recorded by the proxy.

To get the data out of the docker containers, see below.

### Get the data from the VM

SSH into the docker host

```bash
ssh root@$VPN_IP
```

Pull the data out of the container onto the host

```bash
docker run --rm --volumes-from mitmproxy -v $(pwd)/backup:/backup ubuntu tar czvf /backup/flows.tar.gz /proxydata
```

`rsync` it down from local machine

```bash
rsync -rvP root@165.227.51.86:~/backup ./
```

This has all been wrapped up into a script at `./scripts/download.sh`
