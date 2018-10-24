# Data Life

Here I am man-in-the-middling myself and analysing the results.

This repository contains some of the code written to record and analyse HTTP requests from my phone and laptop as part of a project for ABC News.

I wanted to find out in great detail what kinds of data my devices were sharing about me without my knowledge.

The project uses [mitmproxy](https://mitmproxy.org/) to do most of the heavy lifting.

## `server`

The `server` folder contains code that packages the setup into Docker images. Doing it this way is mostly for reproducibility and so I don't have to deal with python dependencies locally. Blowing it all away and starting again should be simple.

Check out `[server/README.md](server/README.md)` for more details.

## `analysis`

The `analysis` folder contains (mostly) R code for analysing the data recorded by the proxy.

Check out `[analysis/README.md](analysis/README.md)` for more details.

## `scripts`

The `scripts` folder is mostly a collection of bash scripts I've used to get the data out of the docker containers. They probably won't just run. They're mostly there so I don't have to remember all the individual commands I ran.

Check out `[scripts/README.md](scripts/README.md)` for more details.
