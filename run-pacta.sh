#! /bin/bash

# Set permissions so that new files can be deleted/overwritten outside docker
umask 000

Rscript --vanilla pacta_01.R "${1}" \
  && Rscript --vanilla pacta_02.R "${1}"
