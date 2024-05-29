# `workflow.pacta`

[![Lifecycle:experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

## Description

`workflow.pacta` is an R package (and associated Docker image) that runs the PACTA audit and analysis phases (but not the report generation phase, which is covered by [`workflow.pacta.report`](https://github.com/RMI-PACTA/workflow.pacta.report)).

`workflow.pacta` can be used locally, or through the docker image.
The Docker image is [publicly available](https://github.com/RMI-PACTA/workflow.pacta/pkgs/container/workflow.pacta) via GitHub container registry.
For more information, see [Invoking the Docker image](#invoking-the-docker-image), below

## Prerequisites

In order to run `workflow.pacta`, you must have:

* PACTA-data: The outputs of [`workflow.data.preparation`](https://github.com/RMI-PACTA/workflow.data.preparation).
* One or more portfolios, formatted to be read by [`pacta.portfolio.import::read_portfolio.csv()`](https://rmi-pacta.github.io/pacta.portfolio.import/reference/read_portfolio_csv.html)

You must also prepare a JSON string specifying the portfolio parameters, which optionally may be written to a file.
See [Parameters](#parameters) below.

## Invoking the Docker image

The docker image can be run either via `docker`, or more easily `docker-compose`, as the `docker-compose.yml` file has the appropriate mounts and envvars set.

By default, `docker-compose.yml` will build the image locally (if needed).
The compose file by default looks for PACTA-data at `./pacta-data`, portfolios at `./portfolios`, and outputs result files to `./outputs`.

If you already have those directories set up, then you can invoke:

```sh
docker-compose up
```

and the process will run from there.

### Using the `ghcr.io` images

Rather than building the docker image locally (which may take several minutes), you can instead opt to use a prebuilt docker image.
To do this, either replace `build: .` in `docker-compose.yml` with `image: ghcr.io/rmi-pacta/workflow.pacta:main`, or run using `docker`, and specifying the volume mounts as needed.

GitHub Actions is configured to build images from `main` (with the `main` tag), and from pull request branches (with the `pr-##` tags).
No `latest` tag is published.

## Configuration

Application configuration is handled via environment variables.

Defaults are set in the Docker image as targets for bind volumes, but may be overridden.

The Environment Variables that control the application are:

* `PACTA_DATA_DIR`: (default `/mnt/pacta-data`) Path where PACTA-data is located.
  Can be set to an output directory from `workflow.data.preparation`.
* `OUTPUT_DIR`: (default `/mnt/output_dir`) Path where output files from the workflow will be written.
* `PORTFOLIO_DIR`: (default `/mnt/portfolios`) Path where Portfolio CSV files are stored.
* `LOG_LEVEL`: (default `INFO`) Controls verbosity of logging. Accepts standard `log4j` levels (UPPERCASE).

## Parameters

**TODO**

## Using Docker images pushed to GHCR automatically by GH Actions

``` {.bash}
tag_name=main
image_name=ghcr.io/rmi-pacta/workflow.pacta:$tag_name
data_dir=~/github/pactaverse/pacta-data
input_dir=./input_dir
output_dir=./output_dir

docker run -it --rm \
  --network none \
  --pull=always \
  --platform linux/amd64 \
  --env LOG_LEVEL=DEBUG \
  --mount type=bind,readonly,source=${data_dir},target=/pacta-data \
  --mount type=bind,source=${output_dir},target=/output_dir \
  --mount type=bind,source=${input_dir},target=/input_dir \
  $image_name

```
