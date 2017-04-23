# Docker Image for Running CI Tests Flycheck
#
# VERSION               0.0.1
###
# TODO: packages not available through package manager in debian: processing & scalastyle
### Code:

FROM library/debian:unstable

LABEL version="0.1" \
      org.flycheck.ci.docker.version="0.1" \
      org.flycheck.ci.docker.changelog="./Dockerfile.changelog"

# Version variables used later in this script -- this are subject to change as time goes on/other versions are required
ENV GOSU_VERSION=1.10
ENV PROCESSING_VERSION=3.3
ENV PHP_VERSION=7.0
ENV JDK_VERSION=8
ENV EMACS_VERSION=25
ENV PLATFORM_ARCH=amd64

ENV USER=flycheck-tester USER_ID=1000
ENV HOST_GROUP="${USER}" HOST_GID=1000
ENV HOME="/home/${USER}"
ENV APP_DIR=/flycheck
ENV R_LIBS_USER=~/R
ENV GOPATH="${HOME}/go"

RUN groupadd --gid "${HOST_GID}" "${HOST_GROUP}"
RUN useradd --create-home --shell /bin/bash --uid "${USER_ID}" -g "${HOST_GROUP}" "${USER}" && \
    mkdir -m 775 -p "${APP_DIR}" && \
    chown -R "${USER}:${USER}" "${APP_DIR}"

# Don't install suggested or recommended packages, prevents image bloat 
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/01norecommend
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/01norecommend

COPY docker/sources.list /etc/apt/sources.list

RUN apt-get update && apt-get install -y wget nodejs npm "openjdk-${JDK_VERSION}-jdk" gnat asciidoc asciidoctor clang cppcheck \
				      	 coffeescript ldc erlang gfortran golang groovy ghc hlint haskell-stack perl libhtml-tidy-perl \
				    	 cpanminus "php${PHP_VERSION}-cgi" protobuf-compiler puppet flake8 pylint racket python-docutils \
				    	 python-sphinx r-base r-base-dev jruby rustc scala chicken-bin shellcheck devscripts xmlstarlet \
				    	 cfengine3 coq lua-check phpmd php-pear golint libperl-critic-perl php-codesniffer ruby-dev \
					 "emacs${EMACS_VERSION}-nox" emacs-goodies-el "emacs${EMACS_VERSION}-common-non-dfsg" "emacs${EMACS_VERSION}-common" git-core curl \
					 rubocop puppet-lint ruby-sass ruby-slim foodcritic ruby-haml ssh

RUN wget "http://download.processing.org/processing-${PROCESSING_VERSION}-linux64.tgz" -qO /opt/processing.tgz

WORKDIR /opt/
RUN tar xaf ./processing.tgz && mv "processing-${PROCESSING_VERSION}" processing

RUN chown -R "${USER}:${USER}" /opt

RUN mkdir -p /usr/local/bin && \
    wget -qO /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${PLATFORM_ARCH}" && \
    chmod +x /usr/local/bin/gosu

RUN update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10

COPY docker/php-conf.d/pear.ini "/etc/php/${PHP_VERSION}/mods-available/pear.ini"
RUN ln -s "/etc/php/${PHP_VERSION}/mods-available/pear.ini" "/etc/php/${PHP_VERSION}/cli/conf.d/98-pear.ini"

WORKDIR "${APP_DIR}"
VOLUME "${APP_DIR}"

# Needs to be done before lowering privileges to ${USER} otherwise gem doesn't install due to permission issues
RUN gem install --no-document mdl ruby-lint scss_lint scss_lint_reporter_checkstyle sqlint

COPY docker/profile "${HOME}/.bash_profile"
RUN chown "${USER}:${USER}" "${HOME}/.bash_profile"

COPY docker/npmrc "${HOME}/.npmrc"
COPY docker/package.json "${HOME}/package.json"

WORKDIR ${HOME}
RUN npm install -g .

RUN git clone https://github.com/cask/cask.git cask && cd cask && ./bin/cask upgrade-cask

# User controlled commands following
USER "${USER}"

COPY docker/install-packages.R "${HOME}/install-packages.R"
RUN R CMD BATCH "${HOME}/install-packages.R"

RUN mkdir "${HOME}/go"
RUN go get -u github.com/kisielk/errcheck github.com/mdempsky/unconvert

RUN stack setup

ENTRYPOINT ["/bin/bash"]


