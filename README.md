# docker-ruby

Unofficial ruby client for [docker](https://github.com/dotcloud/docker) (work in progress)

## FAQ

### Q: Is this the default ruby client for Docker?

Possibly not; the docker team is considering writing a official client based on the [upcoming HTTP API](https://github.com/dotcloud/docker/issues/21). 

### Q: Why does it exist then?

Because as of now, docker-ruby is the only way to talk to docker without having to shell-out to the command-line client (which doesn't always work).
