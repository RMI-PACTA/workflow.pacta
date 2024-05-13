#! /bin/bash

# Set permissions so that new files can be deleted/overwritten outside docker
umask 000

Rscript --vanilla -e 'workflow.pacta::run_pacta()' "${1}"
