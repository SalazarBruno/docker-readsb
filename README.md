# mikenye/readsb

[Mictronics' `readsb`](https://github.com/Mictronics/readsb) Mode-S/ADSB/TIS decoder for RTLSDR, BladeRF, Modes-Beast and GNS5894 devices, running in a docker container.

Support for RTLSDR, bladeRF and plutoSDR is compiled in. Builds and runs on x86_64, arm32v7 and arm64v8 (see below).

This image will configure a software-defined radio (SDR) to receive and decode Mode-S/ADSB/TIS data from aircraft within range, for use with other services such as:

* `mikenye/adsbexchange` to feed ADSB data to [adsbexchange.com](https://adsbexchange.com)
* `mikenye/piaware` to feed ADSB data into [flightaware.com](https://flightaware.com)
* `mikenye/fr24feed` to feed ADSB data into [flightradar24.com](https://www.flightradar24.com)
* `mikenye/piaware-to-influx` to feed data into your own instance of [InfluxDB](https://docs.influxdata.com/influxdb/), for visualisation with [Grafana](https://grafana.com) and/or other tools
* Any other tools that can receive Beast, BeastReduce, Basestation or the raw data feed from `readsb` or `dump1090` and their variants

Tested and working on:

* `x86_64` (`amd64`) platform running Ubuntu 16.04.4 LTS using an RTL2832U radio (FlightAware Pro Stick Plus Blue)
* `armv7l` (`arm32v7`) platform (Odroid HC1) running Ubuntu 18.04.1 LTS using an RTL2832U radio (FlightAware Pro Stick Plus Blue)
* `aarch64` (`arm64v8`) platform (Raspberry Pi 4) running Raspbian Buster 64-bit using an RTL2832U radio (FlightAware Pro Stick Plus Blue)
* If you run on a different platform (or if you have issues) please raise an issue and let me know!
* bladeRF & plutoSDR are untested - I don't own bladeRF or plutoSDR hardware (only RTL2832U as outlined above), but support for the devices is compiled in. If you have the hardware and would be willing to test, please [open an issue on GitHub](https://github.com/mikenye/docker-readsb/issues).

## Supported tags and respective Dockerfiles

* `latest` should always contain the latest released versions of `rtl-sdr`, `bladeRF`, `libiio`, `libad9361-iio` and `readsb`. This image is built nightly from the [`master` branch](https://github.com/mikenye/docker-readsb) [`Dockerfile`](https://github.com/mikenye/docker-readsb/blob/master/Dockerfile) for all supported architectures.
* `development` ([`master` branch](https://github.com/mikenye/docker-readsb/tree/master), [`Dockerfile`](https://github.com/mikenye/docker-readsb/blob/master/Dockerfile), `amd64` architecture only, built on commit, not recommended for production)
* Specific version and architecture tags are available if required, however these are not regularly updated. It is generally recommended to run `latest`.

## Changelog

### 20200408

* Create `protobuf` tags for in-development v4.0.0.

**PLEASE NOTE: THE COMMAND LINE & ENVIRONMENT VARIABLES HAVE CHANGED IN THE V4.0.0 RELEASE OF `readsb`. YOU WILL NEED TO CHANGE YOUR COMPOSE FILE AND/OR RUNNING CONTAINER CONFIG!**

### 20200320

* Remove `/src/*` during container build, to reduce size of container
* Linting & clean-up

### 20200317

* Move to single Dockerfile for multi architecture
* Change `rtl-sdr`, `bladeRF`, `libiio`, `libad9361-iio` and `readsb` to build from latest released github tag. Versions of each component can be viewed with the command `docker run --rm -it --entrypoint cat mikenye/readsb:latest /VERSIONS`
* Include `gpg` verification of `s6-overlay`
* Increase verbosity of docker build output
* Change build process to use `docker buildx`

### 20200218

* Original image, based on [debian:stable-slim](https://hub.docker.com/_/debian).

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* ```amd64```: Linux x86-64
* ```arm32v7```, ```armv7l```: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3)
* ```arm64v8```, ```aarch64```: ARMv8 64-bit (RPi 3B+/4)

## Prerequisites

Before this container will work properly, you must blacklist the kernel modules for the RTL-SDR USB device from the host's kernel.

To do this, create a file `/etc/modprobe.d/blacklist-rtl2832.conf` containing the following:

```shell
# Blacklist RTL2832 so docker container readsb can use the device

blacklist rtl2832
blacklist dvb_usb_rtl28xxu
blacklist rtl2832_sdr
```

Once this is done, you can plug in your RTL-SDR USB device and start the container.

Failure to do this will result in the error below being spammed to the container log.

```
usb_claim_interface error -6
rtlsdr: error opening the RTLSDR device: Device or resource busy
```

If you get the error above even after blacklisting the kernel modules as outlined above, the modules may still be loaded. You can unload them by running the following commands:

```shell
sudo rmmod rtl2832_sdr
sudo rmmod dvb_usb_rtl28xxu
sudo rmmod rtl2832
```

## Quick Start with `docker run`

Firstly, plug in your USB radio.

Run the command `lsusb` and find your radio. It'll look something like this:

```
Bus 001 Device 004: ID 0bda:2832 Realtek Semiconductor Corp. RTL2832U DVB-T
```

Take note of the bus number, and device number. In the output above, its 001 and 004 respectively.

Start the docker container, passing through the USB device:

```shell
docker run \
 -d \
 --rm \
 --name readsb \
 --device /dev/bus/usb/USB_BUS_NUMBER/USB_DEVICE_NUMBER \
 -p 8080:80 \
 -p 30005:30005 \
 -e TZ=YOURTIMEZONE \
 mikenye/readsb
```

For example, based on the `lsusb` output above:

```shell
docker run \
 -d \
 --rm \
 --name readsb \
 --device /dev/bus/usb/001/004 \
 -p 8080:80 \
 -p 30005:30005 \
 -e TZ=Australia/Perth \
 mikenye/readsb
 ```

## Up-and-Running with Docker Compose

Firstly, plug in your USB radio.

Run the command `lsusb` and find your radio. It'll look something like this:

```shell
Bus 001 Device 004: ID 0bda:2832 Realtek Semiconductor Corp. RTL2832U DVB-T
```

Take note of the bus number, and device number. In the output above, its 001 and 004 respectively. This is used in the `devices:` section of the `docker-compose.xml`. Change these in your environment as required.

An example `docker-compose.xml` file is below:

```shell
version: '2.0'

networks:
  adsbnet:

volumes:
  readsb_run:
  readsb_rrd:

services:

  readsb:
    image: mikenye/readsb:latest
    tty: true
    container_name: readsb
    restart: always
    devices:
      - /dev/bus/usb/001/007:/dev/bus/usb/001/007
    ports:
      - 8080:80
      - 30005:30005
    networks:
      - adsbnet
    volumes:
      - readsb_run:/run/readsb
      - readsb_rrd:/var/lib/collectd
```

The reason for creating a specific docker network makes it easier to feed data into other containers. This will be explained further below.

The two volumes are used to provide persistant storage for `readsb`'s performance graphs.

## Testing the container

Once running, you can test the container to ensure it is correctly receiving & decoding ADSB traffic by issuing the command:

```shell
docker exec -it readsb viewadsb
```

Which should display a departure-lounge-style screen showing all the aircraft being tracked, for example:

```
 Hex    Mode  Sqwk  Flight   Alt    Spd  Hdg    Lat      Long   RSSI  Msgs  Ti -
────────────────────────────────────────────────────────────────────────────────
 7C801C S                     8450  256  296                   -28.0    14  1
 7C8148 S                     3900                             -21.5    19  0
 7C7A48 S     1331  VOZ471   28050  468  063  -31.290  117.480 -26.8    48  0
 7C7A4D S     3273  VOZ694   13100  376  077                   -29.1    14  1
 7C7A6E S     4342  YGW       1625  109  175  -32.023  115.853  -5.9    71  0
 7C7A71 S           YGZ        725   64  167  -32.102  115.852 -27.1    26  0
 7C42D1 S                    32000  347  211                   -32.0     4  1
 7C42D5 S                    33000  421  081  -30.955  118.568 -28.7    15  0
 7C42D9 S     4245  NWK1643   1675  173  282  -32.043  115.961 -13.6    60  0
 7C431A S     3617  JTE981   24000  289  012                   -26.7    41  0
 7C1B2D S     3711  VOZ9242  11900  294  209  -31.691  116.118  -9.5    65  0
 7C5343 S           QQD      20000  236  055  -30.633  116.834 -25.5    27  0
 7C6C96 S     1347  JST116   24000  397  354  -30.916  115.873 -17.5    62  0
 7C6C99 S     3253  JST975    2650  210  046  -31.868  115.993  -2.5    70  0
 76CD03 S     1522  SIA214     grnd   0                        -22.5     7  0
 7C4513 S     4220  QJE1808   3925  282  279  -31.851  115.887  -1.9    35  0
 7C4530 S     4003  NYA      21925  229  200  -30.933  116.640 -19.8    58  0
 7C7533 S     3236  XFP       4300  224  266  -32.066  116.124  -6.9    74  0
 7C4D44 S     3730  PJQ      20050  231  199  -31.352  116.466 -20.1    62  0
 7C0559 S     3000  BCB       1000                             -18.4    28  0
 7C0DAA S     1200            2500  146  002  -32.315  115.918 -26.6    48  0
 7C6DD7 S     1025  QFA793   17800  339  199  -31.385  116.306  -8.7    53  0
 8A06F0 S     4131  AWQ544    6125  280  217  -32.182  116.143 -12.6    61  0
 7CF7C4 S           PHRX1A                                     -13.7     8  1
 7CF7C5 S           PHRX1B                                     -13.3     9  1
 7C77F6 S           QFA595     grnd 112  014                   -33.2     2  2
```

Press `CTRL-C` to escape this screen.

You should also be able to point your web browser at `http://dockerhost:8080/` to view the web interface.

## Runtime Configuration

The container accepts the following environment variables:

| Environment Variable | Default Value |
|-|-|
| `RECEIVER_OPTIONS` | `--device 0 --device-type rtlsdr --gain -10 --ppm 0` |
| `DECODER_OPTIONS` | `--max-range 360` |
| `NET_OPTIONS` | `--net --net-heartbeat 60 --net-ro-size 1200 --net-ro-interval 0.1 --net-ri-port 0 --net-ro-port 30002 --net-sbs-port 30003 --net-bi-port 30004,30104 --net-bo-port 30005` |
| `OUTPUT_OPTIONS` | `--rx-location-accuracy 1` |

So, to change your rtl-sdr gain, you might do the following:

```yaml
  readsb:
    image: readsbtest:refactor
    tty: true
    container_name: readsb
    restart: always
    devices:
      - /dev/bus/usb/001/007:/dev/bus/usb/001/007
    ports:
      - 8080:80
      - 30005:30005
      networks:
      - adsbnet
    volumes:
      - readsb_run:/run/readsb
      - readsb_rrd:/var/lib/collectd
    environment:
      - TZ=Australia/Perth
      - RECEIVER_OPTIONS="--device 0 --device-type rtlsdr --gain 36.4 --ppm 0"
```

To get a list of command line arguments, you can issue the following command:

```shell
docker run --rm -it --entrypoint readsb mikenye/readsb --help
```

The defaults should work for the vast majority of ADSB set-ups.

## Volumes

The following volumes are defined by the container:

| Volume | Purpose |
|-|-|
| `/var/lib/collectd` | Contains `.rrd` files for `readsb`'s "Performance Graphs" |
| `/run/readsb` | Contains `readsb` output data and graphs generated by RRDTool |

Mapping these volumes to persistent storage is optional but recommended.

## Ports

The following default ports are used by readsb and this container:

* `80` - readsb webapp - optional but recommended so you can look at the pretty maps and watch the planes fly around.
* `30002` - readsb TCP raw output listen port - optional, recommended to leave unmapped unless explicitly needed
* `30003` - readsb TCP BaseStation output listen port - optional, recommended to leave unmapped unless explicitly needed
* `30004` - readsb TCP Beast input listen port - optional, recommended to leave unmapped unless explicitly needed
* `30005` - readsb TCP Beast output listen port - optional but recommended to allow other applications to receive the data provided by readsb
* `30104` - readsb TCP Beast input listen port - optional, recommended to leave unmapped unless explicitly needed

## Logging

All logs are to the container's log. It is recommended to enable docker log rotation to prevent container logs from filling up your hard drive. See [How-to-setup-log-rotation-post-installation](https://success.docker.com/article/how-to-setup-log-rotation-post-installation) for details on how to achieve this.
