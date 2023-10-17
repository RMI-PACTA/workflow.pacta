# using rocker r-vers as a base with R 4.3.1
# https://hub.docker.com/r/rocker/r-ver
# https://rocker-project.org/images/versioned/r-ver.html
#
# sets CRAN repo to use Posit Package Manager to freeze R package versions to
# those available on 2023-09-29
# https://packagemanager.posit.co/client/#/repos/2/overview
# https://packagemanager.posit.co/cran/__linux__/jammy/2023-09-29

# set proper base image
ARG PLATFORM="linux/amd64"
ARG R_VERS="4.3.1"
FROM --platform=$PLATFORM rocker/r-ver:$R_VERS

# set Docker image labels
LABEL org.opencontainers.image.source=https://github.com/RMI-PACTA/workflow.pacta
LABEL org.opencontainers.image.description="Docker image to run PACTA"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title=""
LABEL org.opencontainers.image.revision=""
LABEL org.opencontainers.image.version=""
LABEL org.opencontainers.image.vendor=""
LABEL org.opencontainers.image.base.name=""
LABEL org.opencontainers.image.ref.name=""
LABEL org.opencontainers.image.authors=""

# set apt-get to noninteractive mode
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NOWARNINGS="yes"

# install system dependencies
ARG SYS_DEPS="\
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    openssh-client \
    wget \
    "
RUN apt-get update \
    && apt-get install -y --no-install-recommends $SYS_DEPS \
    && chmod -R a+rwX /root \
    && rm -rf /var/lib/apt/lists/*

# set frozen CRAN repo
ARG CRAN_REPO="https://packagemanager.posit.co/cran/__linux__/jammy/2023-09-29"
RUN echo "options(repos = c(CRAN = '$CRAN_REPO'))" >> "${R_HOME}/etc/Rprofile.site"

# install packages for dependency resolution and installation
RUN Rscript -e "install.packages('pak')"
RUN Rscript -e "pak::pkg_install('renv')"

# copy in everything from this repo
COPY . /

# PACTA R package tags
ARG allocate_tag="/tree/main"
ARG audit_tag="/tree/main"
ARG import_tag="/tree/main"
ARG utils_tag="/tree/main"

ARG allocate_url="https://github.com/rmi-pacta/pacta.portfolio.allocate"
ARG audit_url="https://github.com/rmi-pacta/pacta.portfolio.audit"
ARG import_url="https://github.com/rmi-pacta/pacta.portfolio.import"
ARG utils_url="https://github.com/rmi-pacta/pacta.portfolio.utils"

# install R package dependencies
RUN Rscript -e "\
  gh_pkgs <- \
    c( \
      paste0('$allocate_url', '$allocate_tag'), \
      paste0('$audit_url', '$audit_tag'), \
      paste0('$import_url', '$import_tag'), \
      paste0('$utils_url', '$utils_tag') \
    ); \
  workflow_pkgs <- renv::dependencies('DESCRIPTION')[['Package']]; \
  workflow_pkgs <- grep('^pacta[.]', workflow_pkgs, value = TRUE, invert = TRUE); \
  pak::pak(c(gh_pkgs, workflow_pkgs)); \
  "

# set default run behavior
ENTRYPOINT ["/run-pacta.sh"]
CMD ["input_dir/default_config.json"]
