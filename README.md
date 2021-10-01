# easyDNS-dynamic

## Description

Lightweight Docker client to update Dynamic DNS records on easyDNS

## Table of Contents

* [Description](#description)
* [Usage](#usage)
* [Packaging and Releasing](#packaging-and-releasing)

## Usage

Provide a list of credentials and domains as part of the `command` for running
the docker container.

By default, this runs as a service that will poll the status every 10 minutes.

The [docker-compose.yaml](docker-compose.yaml) contains an example line showing
the format for each argument:

    <username>:<token>[:<domain> ...]

If running locally using `docker-compose`, you may execute:

    make exec

or, if you want to force the image to rebuild before execution:

    make dist exec

Additionally, the polling interval can be configured by adding an `interval`
variable to the environment, in seconds.

## Packaging and Releasing

The docker image can be built by executing:

    make dist

Releasing the image to DockerHub can be done by executing:

    make release
