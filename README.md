# Description

The Dockerfile in this repository creates an image containing a freshly
cloned copy of workflow.pacta. It also installs the relevant PACTA R packages 
that it depends on.

# Notes

Running PACTA also requires pacta-data, which needs to be mounted into the 
container at run-time.

# Using Docker images pushed to GHCR automatically by GH Actions

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
  --mount type=bind,readonly,source=${data_dir},target=/pacta-data \
  --mount type=bind,source=${output_dir},target=/output_dir \
  --mount type=bind,source=${input_dir},target=/input_dir \
  $image_name
```
