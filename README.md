# tis24dev/loxone-config-docker

Docker container for [Loxone Config](https://www.loxone.com/dede/produkte/loxone-config/)

Originally based on [lian/docker-loxone-config](https://github.com/lian/docker-loxone-config), updated for **Loxone Config 17+**, which is 64-bit only: the image now runs Debian 13 (amd64) with a 64-bit Wine prefix instead of Alpine/i386 with 32-bit Wine.

The windows GUI of the Loxone Config application is run through [Wine](https://en.wikipedia.org/wiki/Wine_(software)) and accessed on a modern web browser (no installation or configuration needed on client side) or via any VNC client.

---

This container is based on the absolutely fantastic [jlesage/baseimage-gui](https://hub.docker.com/r/jlesage/baseimage-gui). All the hard work to make GUI applications possible inside your browser via docker has been done by them, and I shamelessly copied the README.md from [mikenye/docker-picard](https://github.com/mikenye/docker-picard). For advanced usage or modification I suggest you check out their [README](https://github.com/jlesage/docker-baseimage-gui).

---

## Usage

Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs.  Note that only mandatory network
ports are part of the example.

```yaml
services:
  loxone-config:
    image: "ghcr.io/tis24dev/loxone-config-docker:main"
    container_name: loxone-config
    ports:
      - "127.0.0.1:5800:5800"
    environment:
      - VNC_PASSWORD=${VNC_PASSWORD:?Set VNC_PASSWORD, e.g. in a .env file}
      - USER_ID=1000
      - GROUP_ID=1000
      - DISPLAY_WIDTH=1920
      - DISPLAY_HEIGHT=1080
      - XLANG=de
    volumes:
      - "./config:/config:rw"
      - "./config/Loxone:/config/wine/drive_c/users/app/Documents/Loxone:rw"
```

**NOTE**: On first launch the container looks up the latest Loxone Config release in Loxone's update feed (`https://update.loxone.com/updatecheck.xml`), downloads it (about 670 MB), checks its crc32 and installs it unattended into `/config/wine`. Further launches skip this step. To start clean again, delete `/config/wine`. If the download does not work, put `LoxoneConfigSetup.exe` into `./config/` yourself and restart.

**NOTE**: The GUI is bound to `127.0.0.1` and needs `VNC_PASSWORD`. Only the first 8 characters of the password are used (VNC protocol limit). To reach it from other devices on your network, change the port to `5800:5800` and consider `SECURE_CONNECTION=1`.

### Updating Loxone Config

The image does not contain Loxone Config, so a new image does not update it. To install the latest release, stop the container, delete `./config/wine` and `./config/LoxoneConfigSetup.exe`, and start it again. Your projects in `./config/Loxone` are kept.

### Upgrading from the old 32-bit image

A `./config/wine` folder created by the old image (Loxone Config 16 and older) is a 32-bit Wine prefix and cannot run Loxone Config 17+. The container detects it and shows a message. Delete `./config/wine` and `./config/LoxoneConfigSetup.exe` and start again; `./config/Loxone` is kept.

Launch the Loxone Config docker container with the following commands:

```shell
# create empty config directory
mkdir -p config

# set the VNC password (max 8 characters are used)
echo 'VNC_PASSWORD=changeme' > .env

# ensure USER_ID and GROUP_ID from docker-compose.yml are correct
id

# start loxone config container
docker compose up
```

Browse to `http://127.0.0.1:5800` to access the Loxone Config GUI.

### Data Paths

The following table describes data paths used by the container.  Your host folder `./config` is mounted into the container to `/config`

| Container path  | Description |
|-----------------|-------------|
|`/config`| This is where the application stores its configuration, log and any files needing persistency. |
|`/config/Loxone`| This is where Loxone Config stores its configuration and project files. |
|`/config/wine`| This is where Wine stores its Loxone Config Windows installation. (can be removed for a fresh install) |

### Environment Variables

To customize some properties of the container, the following environment
variables can be changed inside `docker-compose.yml`file. Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`USER_ID`| ID of the user the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GROUP_ID`| ID of the group the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`TZ`| [TimeZone] of the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`KEEP_APP_RUNNING`| When set to `1`, the application will be automatically restarted if it crashes or if user quits it. | `0` |
|`DISPLAY_WIDTH`| Width (in pixels) of the application's window. | `1280` |
|`DISPLAY_HEIGHT`| Height (in pixels) of the application's window. | `768` |
|`SECURE_CONNECTION`| When set to `1`, an encrypted connection is used to access the application's GUI (either via web browser or VNC client).  See the [Security](#security) section for more details. | `0` |
|`VNC_PASSWORD`| Password needed to connect to the application's GUI.  See the [VNC Password](#vnc-password) section for more details. | (unset) |
|`XLANG`| Keyboard map to be used by XVNC/Loxone Config. Use this to set specific keyboard maps via setxkbmap. See the [keyboard maps](#keyboard-maps) section for more details. | `de` |

### Ports

Here is the list of ports used by the container.  They can be mapped to the host
via the `ports` inside `docker-compose.yml`. Each mapping is defined in the
following format: `<HOST_PORT>:<CONTAINER_PORT>`.  The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port | Mapping to host | Description |
|------|-----------------|-------------|
| 5800 | Mandatory | Port used to access the application's GUI via the web interface. |
| 5900 | Optional | Port used to access the application's GUI via the VNC protocol.  Optional if no VNC client is used. |

**NOTE**: The example binds to localhost only (`127.0.0.1:5800:5800`), so other devices in your network cannot reach Loxone Config. Use `5800:5800` only together with a `VNC_PASSWORD`.

### Keyboard maps

Keyboard maps are set via setxkbmap. See the [setxkbmap configuration options](https://gist.github.com/jatcwang/ae3b7019f219b8cdc6798329108c9aee) section "layout" for more details.

Common keyboard maps are:

| map | Language | Default |
|-----|----------| ------- |
| us | English (US) | - |
| en | English | - |
| at | German (Austria) | - |
| ch | German (Switzerland) | - |
| de | German | yes |
| fr | French | - |

## User/Group IDs

When using data volumes, permissions issues can occur between the
host and the container.  For example, the user within the container may not
exists on the host.  This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`USER_ID` and `GROUP_ID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

```shell
id <username>
```

Which gives an output like this one:

```text
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.

## Accessing the GUI

Assuming that container's ports are mapped to the same host's ports, the
graphical interface of the application can be accessed via:

* A web browser:

```text
http://<HOST IP ADDR>:5800
```

* Any VNC client:

```text
<HOST IP ADDR>:5900
```

## Security

By default, access to the application's GUI is done over an unencrypted
connection (HTTP or VNC).

Secure connection can be enabled via the `SECURE_CONNECTION` environment
variable.  See the [Environment Variables](#environment-variables) section for
more details on how to set an environment variable.

When enabled, application's GUI is performed over an HTTPs connection when
accessed with a browser.  All HTTP accesses are automatically redirected to
HTTPs.

When using a VNC client, the VNC connection is performed over SSL.  Note that
few VNC clients support this method.  [SSVNC] is one of them.

[SSVNC]: http://www.karlrunge.com/x11vnc/ssvnc.html

### Certificates

Here are the certificate files needed by the container.  By default, when they
are missing, self-signed certificates are generated and used.  All files have
PEM encoded, x509 certificates.

| Container Path                  | Purpose                    | Content |
|---------------------------------|----------------------------|---------|
|`/config/certs/vnc-server.pem`   |VNC connection encryption.  |VNC server's private key and certificate, bundled with any root and intermediate certificates.|
|`/config/certs/web-privkey.pem`  |HTTPs connection encryption.|Web server's private key.|
|`/config/certs/web-fullchain.pem`|HTTPs connection encryption.|Web server's certificate, bundled with any root and intermediate certificates.|

**NOTE**: To prevent any certificate validity warnings/errors from the browser
or VNC client, make sure to supply your own valid certificates.

**NOTE**: Certificate files are monitored and relevant daemons are automatically
restarted when changes are detected.

### VNC Password

To restrict access to your application, a password can be specified.  This can
be done via two methods:

* By using the `VNC_PASSWORD` environment variable.
* By creating a `.vncpass_clear` file at the root of the `/config` volume.
  This file should contains the password in clear-text.  During the container
  startup, content of the file is obfuscated and moved to `.vncpass`.

The level of security provided by the VNC password depends on two things:

* The type of communication channel (encrypted/unencrypted).
* How secure access to the host is.

When using a VNC password, it is highly desirable to enable the secure
connection to prevent sending the password in clear over an unencrypted channel.

**ATTENTION**: Password is limited to 8 characters.  This limitation comes from
the Remote Framebuffer Protocol [RFC](https://tools.ietf.org/html/rfc6143) (see
section [7.2.2](https://tools.ietf.org/html/rfc6143#section-7.2.2)).  Any
characters beyhond the limit are ignored.

## Shell Access

To get shell access to a the running container, execute the following command:

```shell
docker exec -it loxone-config bash
```

## Getting Help

Having troubles with the container or have questions?  Please [create a new issue](https://github.com/tis24dev/loxone-config-docker/issues).

## Thanks

* [t_heinrich](https://www.loxforum.com/member/1843-t_heinrich) for bug reports
* [timboettiger](https://github.com/timboettiger) for [keyboard maps](#keyboard-maps)
* [lian](https://github.com/lian) for the original image
* [rubenvanwanzeele](https://github.com/rubenvanwanzeele), [PaulSchwanitz](https://github.com/PaulSchwanitz) and [JonasReuter](https://github.com/JonasReuter) for the 64-bit Wine work for Loxone Config 17 this fork is based on
