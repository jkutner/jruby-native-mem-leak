# JRuby native memory debugging example

This example can be used to reproduce JRuby native memory usage in a container.

## Overview

The `run.sh` script can be executed to start the server and seige it will thousands of requests. The server will run in the background, and the
`parse.rb` script will run in the foreground to parse `smaps` into various categories. It only works with Linux (provided by the Docker runtime).

## Usage

```
$ docker-compose run shell
...
root@c099c061635a:~/user# sh run.sh
```

Then watch the memory analysis roll in.