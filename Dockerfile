FROM ubuntu:16.04
LABEL maintainer="nullbyte.in@gmail.com"
# modified by macfly1202 for export/import conda env

ARG proxy

ENV http_proxy $proxy
ENV https_proxy $proxy

RUN echo "check_certificate = off" >> ~/.wgetrc
RUN echo "[global] \n\
trusted-host = pypi.python.org \n \
\t               pypi.org \n \
\t              files.pythonhosted.org" >> /etc/pip.conf

# >> START Install base software
# Basic update and Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales ca-certificates &&  rm -rf /var/lib/apt/lists/*

# Locale set to something minimal like POSIX
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PATH /opt/conda/bin:$PATH

# Exit when RUN get non-zero value
RUN set -e 

RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# Get basic packages
# RUN apt-get update && apt-get install -y --no-install-recommends \
RUN apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        wget \
        git \
        python3 \
        python3-dev \
        python3-pip \
        python3-wheel \
        python3-numpy \
        python3-setuptools \
        libcurl3-dev  \
        gcc \
        sox \
        libsox-fmt-mp3 \
        htop \
        nano \
        swig \
        cmake \
        libboost-all-dev \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        pkg-config \
        libsox-dev \
        apt-utils

RUN rm -f /usr/bin/python && ln -s /usr/bin/python /usr/bin/python3

# Install pip
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN /bin/bash -c "yes w | pip3 install --upgrade pip"   

#RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
#    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
#    rm ~/miniconda.sh && \
#    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
#    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
#    echo "conda activate base" >> ~/.bashrc

# # Install openvivoToolKit
# ARG DOWNLOAD_LINK=http://registrationcenter-download.intel.com/akdlm/irc_nas/16057/l_openvino_toolkit_p_2019.3.376.tgz
ARG DOWNLOAD_LINK=http://registrationcenter-download.intel.com/akdlm/irc_nas/16345/l_openvino_toolkit_p_2020.1.023.tgz
ARG INSTALL_DIR=/opt/intel/openvino
ARG TEMP_DIR=/tmp/openvino_installer
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    cpio \
    sudo \
    lsb-release && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p $TEMP_DIR && cd $TEMP_DIR && \
    wget -c $DOWNLOAD_LINK && \
    tar xf l_openvino_toolkit*.tgz && \
    cd l_openvino_toolkit* && \
    sed -i 's/decline/accept/g' silent.cfg && \
    ./install.sh -s silent.cfg && \
    rm -rf $TEMP_DIR

RUN $INSTALL_DIR/install_dependencies/install_openvino_dependencies.sh

# build Inference Engine samples
RUN mkdir $INSTALL_DIR/deployment_tools/inference_engine/samples/build && cd $INSTALL_DIR/deployment_tools/inference_engine/samples/build && \
    /bin/bash -c "source $INSTALL_DIR/bin/setupvars.sh && cmake .. && make -j`nproc`"

# OpenCV Fix
RUN pip3 install opencv-python
RUN apt-get update && apt-get install -y --no-install-recommends \ 
    libcanberra-gtk-module \
    libcanberra-gtk3-module

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
RUN ln -s /usr/local/bin/docker-entrypoint.sh / # backwards compat

ENTRYPOINT ["docker-entrypoint.sh"]
