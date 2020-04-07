FROM debian:stable-slim AS final

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN set -x && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        ca-certificates \
        cmake \
        collectd \
        cron \
        curl \
        debhelper \
        dh-systemd \
        dpkg-dev \
        g++ \
        gcc \
        git \
        gnupg \
        libc-dev \
        libedit-dev \
        libfl-dev \
        libprotobuf-c-dev \
        librrd-dev \
        libtecla-dev \
        libtecla1 \
        libusb-1.0-0 \
        libusb-1.0-0-dev \
        libxml2 \
        libxml2-dev \
        lighttpd \
        make \
        pkg-config \
        protobuf-c-compiler \
        rrdtool \
        && \ 
    echo "========== Building RTL-SDR ==========" && \
    git clone git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    cd /src/rtl-sdr && \
    export BRANCH_RTLSDR=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "tags/${BRANCH_RTLSDR}" && \
    echo "rtl-sdr ${BRANCH_RTLSDR}" >> /VERSIONS && \
    mkdir -p /src/rtl-sdr/build && \
    cd /src/rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    make -Wstringop-truncation && \
    make -Wstringop-truncation install && \
    cp -v /src/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/ && \
    ldconfig && \
    echo "========== Building bladeRF ==========" && \
    git clone --recursive https://github.com/Nuand/bladeRF.git /src/bladeRF && \
    cd /src/bladeRF && \
    export BRANCH_BLADERF=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_BLADERF}" && \
    echo "bladeRF ${BRANCH_BLADERF}" >> /VERSIONS && \
    mkdir /src/bladeRF/host/build && \
    cd /src/bladeRF/host/build && \
    cmake -DTREAT_WARNINGS_AS_ERRORS=OFF ../ && \
    make && \
    make install && \
    ldconfig && \
    echo "========== Building libiio ==========" && \
    git clone https://github.com/analogdevicesinc/libiio.git /src/libiio && \
    cd /src/libiio && \
    export BRANCH_LIBIIO=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_LIBIIO}" && \
    echo "libiio ${BRANCH_LIBIIO}" >> /VERSIONS && \
    cmake PREFIX=/usr/local ./ && \
    make && \
    make install && \
    ldconfig && \
    echo "========== Building libad9361-iio ==========" && \
    git clone https://github.com/analogdevicesinc/libad9361-iio.git /src/libad9361-iio && \
    cd /src/libad9361-iio && \
    export BRANCH_LIBAD9361IIO=$(git tag --sort="-creatordate" | head -1) && \
    git checkout "${BRANCH_LIBAD9361IIO}" && \
    echo "libad9361-iio ${BRANCH_LIBAD9361IIO}" >> /VERSIONS && \
    cmake ./ && \
    make && \
    make install && \
    ldconfig && \
    echo "========== Building readsb ==========" && \
    git clone https://github.com/Mictronics/readsb-protobuf.git /src/readsb && \
    cd /src/readsb && \
    #export BRANCH_READSB=$(git tag --sort="-creatordate" | head -1) && \
    BRANCH_READSB=dev && \
    git checkout "${BRANCH_READSB}" && \
    dpkg-buildpackage -b --build-profiles=rtlsdr,bladerf,plutosdr && \
    cd /src && \
    dpkg --install readsb_*.deb && \
    echo "readsb $(readsb --version | cut -d " " -f 2)" >> /VERSIONS && \
    ln -s /etc/lighttpd/conf-available/01-setenv.conf /etc/lighttpd/conf-enabled/01-setenv.conf && \
    echo "========== Deploying s6-overlay ==========" && \
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    echo "========== Clean-up ==========" && \
    apt-get remove -y \
        bison \
        build-essential \
        cmake \
        curl \
        debhelper \
        dh-systemd \
        dpkg-dev \
        g++ \
        gcc \
        git \
        gnupg \
        libc-dev \
        libedit-dev \
        libfl-dev \
        libprotobuf-c-dev \
        libtecla-dev \
        libusb-1.0-0-dev \
        libxml2-dev \
        make \
        pkg-config \
        protobuf-c-compiler \
        && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \
    rm -rfv /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/* && \
    cat /VERSIONS

# Copy config files
COPY etc/ /etc/

# Expose ports
EXPOSE 30104/tcp 80/tcp 30001/tcp 30002/tcp 30003/tcp 30004/tcp 30005/tcp

# Configure volumes
VOLUME [ "/var/lib/collectd", "/run/readsb" ]

# Set s6 init as entrypoint
ENTRYPOINT [ "/init" ]
