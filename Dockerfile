# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

# set version label
ARG BUILD_DATE
ARG VERSION
ARG ELEGOOSLICER_VERSION
LABEL build_version="Linuxserver.io fork version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="fork"

# title
ENV TITLE=ElegooSlicer \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NO_GAMEPAD=true

RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/ELEGOO-3D/ElegooSlicer/main/resources/images/ElegooSlicer.png || \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/orcaslicer-logo.png && \
  echo "**** install packages ****" && \
  add-apt-repository ppa:xtradeb/apps && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    firefox \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    libgstreamer-plugins-bad1.0-0 \
    libmspack0 \
    libwebkit2gtk-4.1-0 \
    libwx-perl \
    libfuse2 && \
  echo "**** install elegooslicer from appimage ****" && \
  if [ -z ${ELEGOOSLICER_VERSION+x} ]; then \
    ELEGOOSLICER_VERSION=$(curl -sX GET \
      "https://api.github.com/repos/ELEGOO-3D/ElegooSlicer/releases/latest" \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  RELEASE_URL=$(curl -sX GET \
    "https://api.github.com/repos/ELEGOO-3D/ElegooSlicer/releases/latest" \
    | awk '/url/{print $4;exit}' FS='[""]') && \
  DOWNLOAD_URL=$(curl -sX GET "${RELEASE_URL}" \
    | awk '/browser_download_url.*Ubuntu2404.*AppImage/{print $4;exit}' FS='[""]') && \
  cd /tmp && \
  curl -o \
    /tmp/elegoo.app -L \
    "${DOWNLOAD_URL}" && \
  chmod +x /tmp/elegoo.app && \
  ./elegoo.app --appimage-extract && \
  mv squashfs-root /opt/elegooslicer && \
  echo "**** patch PrinterManager to fix mIsInitialized bug ****" && \
  python3 -c "f=open('/opt/elegooslicer/bin/elegoo-slicer','r+b');f.seek(0x1d4b24f);assert f.read(4)==b'\x66\x0f\xef\xc9','pxor mismatch';f.seek(0x1d4b24f);f.write(b'\xc6\x47\x08\x00');f.seek(0x1d4b2cf);assert f.read(1)==b'\x8f','xmm1a mismatch';f.seek(0x1d4b2cf);f.write(b'\x87');f.seek(0x1d4b2d6);assert f.read(1)==b'\x8f','xmm1b mismatch';f.seek(0x1d4b2d6);f.write(b'\x87');f.close();print('Binary patch applied: mIsInitialized now zero-initialized in constructor')" && \
  localedef -i en_GB -f UTF-8 en_GB.UTF-8 && \
  printf "Fork version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /config/.launchpadlib \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3000 3001
VOLUME /config
