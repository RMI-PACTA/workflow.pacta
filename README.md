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
data_folder=~/github/rmi-pacta/pacta-data
portfolio_name="1234"
user_folder=~/github/rmi-pacta/workflow.pacta/working_dir

docker run -ti --rm --network none \
  --pull=always \
  --mount type=bind,source=${user_folder},target=/workflow.pacta/working_dir \
  --mount type=bind,readonly,source=${data_folder},target=/pacta-data \
  $image_name \
  /bound/bin/run-r-scripts-results-only "$portfolio_name"
```
