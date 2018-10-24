# Getting data from the VMs

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
rsync -rvP root@$VPN_IP:~/backup ./
```

This has (sort of) been wrapped up into a script at `scripts/download.sh` which will probably just run if you have the right environment variables set.

The `pre-process.sh` probably won't run, but it has some scripts which are handy for pre-processing the data before it gets imported into R/SQLite for further analysis.
