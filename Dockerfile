# Loxone Config 17+ is 64-bit only, so this image runs Debian amd64 with
# Debian's own multilib Wine (wine64 + wine32): the installer is a 32-bit
# InnoSetup stub, the application itself is 64-bit.
FROM --platform=linux/amd64 jlesage/baseimage-gui:debian-13-v4

# /var/log is a symlink to /config/log in the base image; package postinst
# scripts (fontconfig) fail at build time unless the target exists.
RUN mkdir -p /config/log && \
    dpkg --add-architecture i386 && \
    add-pkg \
        wine wine64 wine32:i386 libwine libwine:i386 fonts-wine \
        wget ca-certificates unzip cabextract libarchive-zip-perl \
        xterm xfonts-base x11-xkb-utils xkb-data \
        xdotool wmctrl x11-utils && \
    rm -rf /config/log

COPY init-install.sh /init-install.sh
COPY startapp.sh /startapp.sh
COPY fix-window.sh /fix-window.sh
RUN chmod a+rx /startapp.sh /init-install.sh /fix-window.sh

ENV WINEARCH=win64 \
    WINEPREFIX=/config/wine \
    WINEDEBUG=-all \
    XLANG=de

RUN set-cont-env APP_NAME "Loxone Config"
