FROM docker.io/rocker/r-ver:4.3.1 AS base

# set Docker image labels
LABEL org.opencontainers.image.source=https://github.com/RMI-PACTA/workflow.pacta
LABEL org.opencontainers.image.description="Docker image to run PACTA analysis"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="workflow.pacta"
LABEL org.opencontainers.image.vendor="RMI"
LABEL org.opencontainers.image.base.name="docker.io/rocker/r-ver:4.3.1"
LABEL org.opencontainers.image.authors="Alex Axthelm, CJ Yetman, Jackson Hoffart"

# set apt-get to noninteractive mode

# install system dependencies
RUN apt-get update \
    && DEBIAN_FRONTEND="noninteractive" \
    apt-get install -y --no-install-recommends \
      git=1:2.34.* \
      libcurl4-openssl-dev=7.81.* \
      libgit2-dev=1.1.* \
      libicu-dev=70.* \
      libssl-dev=3.0.* \
      openssh-client=1:8.* \
      wget=1.21.* \
    && chmod -R a+rwX /root \
    && rm -rf /var/lib/apt/lists/*

# set frozen CRAN repo and RProfile.site
# This block makes use of the builtin ARG $TARGETPLATFORM (See:
# https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/
# ) to pick the correct CRAN-like repo, which will let us target binaries fo
# supported platforms
ARG TARGETPLATFORM
RUN PACKAGE_PIN_DATE="2023-10-30" && \
  echo "TARGETPLATFORM: $TARGETPLATFORM" && \
  if [ "$TARGETPLATFORM" = "linux/amd64" ] && grep -q -e "Jammy Jellyfish" "/etc/os-release" ; then \
    CRAN_LIKE_URL="https://packagemanager.posit.co/cran/__linux__/jammy/$PACKAGE_PIN_DATE"; \
  else \
    CRAN_LIKE_URL="https://packagemanager.posit.co/cran/$PACKAGE_PIN_DATE"; \
  fi && \
  echo "CRAN_LIKE_URL: $CRAN_LIKE_URL" && \
  printf "options(\n \
    repos = c(CRAN = '%s'),\n \
    pak.no_extra_messages = TRUE,\n \
    pkg.sysreqs = FALSE,\n \
    pkg.sysreqs_db_update = FALSE,\n \
    pkg.sysreqs_update = FALSE\n \
  )\n" \
  "$CRAN_LIKE_URL" \
  > "${R_HOME}/etc/Rprofile.site"

# copy in DESCRIPTION from this repo
COPY DESCRIPTION /workflow.pacta/DESCRIPTION

# install pak, find dependencises from DESCRIPTION, and install them.
RUN Rscript -e "\
    install.packages('pak'); \
    deps <- pak::local_deps(root = '/workflow.pacta'); \
    pkg_deps <- deps[!deps[['direct']], 'ref']; \
    print(pkg_deps); \
    pak::pak(pkg_deps); \
    "

FROM base AS install-pacta

COPY . /workflow.pacta/

RUN Rscript -e "pak::local_install(root = '/workflow.pacta')"

# set default run behavior
ENTRYPOINT ["Rscript", "--vanilla", "/workflow.pacta/inst/extdata/scripts/run_pacta.R"]
CMD ["/workflow.pacta/input_dir/default_config.json"]

# Create and use non-root user
RUN useradd -m -s /bin/bash workflow-pacta
USER workflow-pacta
WORKDIR /home/workflow-pacta

