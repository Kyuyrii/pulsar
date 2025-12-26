# Building Pulsar

How to build a project from the source code is the first step for any new contributor.

This document explains what the build dependencies are, what they are needed for, and how to build all of Pulsar.

The example commands are for building in Ubuntu Linux, and the exact commands and package names may vary on different platforms.


Fork Pulsar at https://github.com/pulsar-edit/pulsar

Clone your own fork, including submodules:

    git clone --recurse-submodules https://github.com/<username>/pulsar

Enter the git repository directory, and configure so that running `git pull` in general or in the `master` branch automatically fetches the latest upstream `master` branch contents, while running `git push` in the `master` branch will push those upstream commits to your own fork, ensuring the fork is current.

    cd pulsar
    git remote add upstream --track master https://github.com/pulsar-edit/pulsar.git
    git remote set-url --push upstream git@github.com:ottok/pulsar.git

Next start a container of Ubuntu 24.04, which ships with Node 18, which satisfies Pulsar's requirement of minimum NodeJS version 16 mentioned in docs or 14 mentioned in package.json.


    podman run --interactive --rm --privileged --network host --tty --shm-size=1G -e DISPLAY=$DISPLAY --volume=$PWD:/tmp/pulsar --workdir=/tmp/pulsar ubuntu:noble bash

Inside the fresh container install everything needed (402 MB in total):

    packages=(
      # Pulsar project main build tool. Installing it automatically pulls in 191
      # MB of dependencies, including NodeJS.
      yarnpkg

      # 'yarn install' needs git to resolve multiple dependencies defined as git
      # urls with git commit ids
      git

      # 'yarn build' needs 'node-gyp' build native binaries in NodeJS modules
      # @pulsar-edit/fuzzy-native and @pulsar-edit/keyboard-layout
      node-gyp

      # @pulsar-edit/fuzzy-native native binary build dependencies (yes, it runs
      # both Python and make)
      python3-setuptools
      make
      g++

      # @pulsar-edit/keyboard-layout native binary build dependencies
      pkg-config
      libwayland-dev
      libxkbcommon-x11-dev
      libxkbfile-dev
    )
    apt-get update
    apt-get install --yes --quiet --no-install-recommends "${packages[@]}"

  build-essential
  git
  libc6-dev
  libffi-dev
  libgdbm-dev
  libncursesw5-dev
  libsecret-1-dev
  libxkbcommon-dev
  libxkbcommon-x11-dev
  libxkbcommon0 xkb-data
  make
  npm
  pkg-config
  python3-setuptools
  rpm

In Debian/Ubuntu, 'yarn' name is taken, so manually install a symlink to make 'yarn' refer to it

    ln -s /usr/bin/yarnpkg /usr/bin/yarn

Install all additional required NodeJS modules (~1000 MB)

    yarn install

Run 'electron-rebuild' as defined in package.json to build Pulsar

    yarn build

Even with all dependencies downloaded in `yarn install`, a network connection is still needed during `yarn build` as the package @pulsar-edit/fuzzy-native downloads the external dependency [https://www.electronjs.org/headers/v30.0.9/node-v30.0.9-headers.tar.gz] during the build.

Build the Pulsar package manager with custom Yarn command (package.json: `cd ppm && yarn install`)

    yarn build:apm

In addition to standard NodeJS modules the above step also downloads the bundled [https://nodejs.org/download/release/v20.11.1/node-v20.11.1-headers.tar.gz] in addition to the ones defined explicitly in `ppm/package.json`.

Finally build the Debian packages using the custom Yarn command (package.json: `'script/electron-builder.js`) to run a `electron-builder` wrapper that launches it with Pulsar specific customizations, passing argument 'deb' to only build Debian packages.

    yarn dist deb

The above step too needs an online system in order to download [https://github.com/electron/electron/releases/download/v30.0.9/electron-v30.0.9-linux-x64.zip] (despite Electron already being built at `node_modules/electron/dist/electron`) and [https://github.com/electron-userland/electron-builder-binaries/releases/download/appimage-12.0.1/appimage-12.0.1.7z] despite the deb build not actually using it.

Also [https://github.com/electron-userland/electron-builder-binaries/releases/download/fpm-1.9.3-2.3.1-linux-x86_64/fpm-1.9.3-2.3.1-linux-x86_64.7z] is downloaded.


---------------
apt install -y build-essential rpm fakeroot
gem install --no-document fpm -v 1.9.3   # the exact version it tries to download

export USE_SYSTEM_FPM=true
export DEBUG=electron-builder
# Only command that actually only builds .deb?
yarn electron-builder --linux=deb --publish=never


DEBUG=electron-builder yarn dist deb 2>&1 | tee yarn-dist-deb.log
DEBUG=electron-builder yarn dist --linux deb 2>&1 | tee yarn-dist-linux-deb.log
DEBUG=electron-builder yarn dist --linux=deb --publish=never 2>&1 | tee yarn-dist-linux-deb.publish-never.log

# objdump -p  /tmp/pulsar/node_modules/electron/dist/electron | grep NEEDED
  NEEDED               libffmpeg.so
  NEEDED               libdl.so.2
  NEEDED               libpthread.so.0
  NEEDED               libgobject-2.0.so.0
  NEEDED               libglib-2.0.so.0
  NEEDED               libgio-2.0.so.0
  NEEDED               libnss3.so
  NEEDED               libnssutil3.so
  NEEDED               libsmime3.so
  NEEDED               libnspr4.so
  NEEDED               libdbus-1.so.3
  NEEDED               libatk-1.0.so.0
  NEEDED               libatk-bridge-2.0.so.0
  NEEDED               libcups.so.2
  NEEDED               libdrm.so.2
  NEEDED               libgtk-3.so.0
  NEEDED               libpango-1.0.so.0
  NEEDED               libcairo.so.2
  NEEDED               libX11.so.6
  NEEDED               libXcomposite.so.1
  NEEDED               libXdamage.so.1
  NEEDED               libXext.so.6
  NEEDED               libXfixes.so.3
  NEEDED               libXrandr.so.2
  NEEDED               libgbm.so.1
  NEEDED               libexpat.so.1
  NEEDED               libxcb.so.1
  NEEDED               libxkbcommon.so.0
  NEEDED               libasound.so.2
  NEEDED               libatspi.so.0
  NEEDED               libm.so.6
  NEEDED               libgcc_s.so.1
  NEEDED               libc.so.6
  NEEDED               ld-linux-x86-64.so.2

  ld-linux-x86-64.so.2           → (provided by glibc/core system)
  libX11.so.6                    → libx11-6
  libXcomposite.so.1             → libxcomposite1
  libXdamage.so.1                → libxdamage1
  libXext.so.6                   → libxext6
  libXfixes.so.3                 → libxfixes3
  libXrandr.so.2                 → libxrandr2
  libasound.so.2                 → libasound2t64
  libatk-1.0.so.0                → libatk1.0-0t64
  libatk-bridge-2.0.so.0         → libatk-bridge2.0-0t64
  libatspi.so.0                  → libatspi2.0-0t64
  libc.so.6                      → (provided by glibc/core system)
  libcairo.so.2                  → libcairo2
  libcups.so.2                   → libcups2t64
  libdbus-1.so.3                 → dbus-tests
  libdl.so.2                     → (provided by glibc/core system)
  libdrm.so.2                    → libdrm2
  libexpat.so.1                  → libexpat1
  libffmpeg.so                   → qmmp
  libgbm.so.1                    → libgbm1
  libgcc_s.so.1                  → (provided by glibc/core system)
  libgio-2.0.so.0                → libglib2.0-0t64
  libglib-2.0.so.0               → libglib2.0-0t64
  libgobject-2.0.so.0            → libglib2.0-0t64
  libgtk-3.so.0                  → libgtk-3-0t64
  libm.so.6                      → (provided by glibc/core system)
  libnspr4.so                    → libnspr4
  libnss3.so                     → libnss3
  libnssutil3.so                 → libnss3
  libpango-1.0.so.0              → libpango-1.0-0
  libpthread.so.0                → (provided by glibc/core system)
  libsmime3.so                   → libnss3
  libxcb.so.1                    → libxcb1
  libxkbcommon.so.0              → libxkbcommon0

apt --yes --quiet --no-install-recommends install libdrm2 libatk1.0-0t64 libxrandr2 libexpat1 libxcomposite1 qmmp libnss3 libxdamage1 libgbm1 libcairo2 libglib2.0-0t64 libatk-bridge2.0-0t64 libpango-1.0-0 libcups2t64 libxext6 libxcb1 libxkbcommon0 libnspr4 libxfixes3 libasound2t64 libatspi2.0-0t64 dbus-tests libx11-6 libgtk-3-0t64

# yarn start
yarn run v1.22.19
$ electron --no-sandbox --enable-logging . -f
[36921:1226/061419.796782:ERROR:bus.cc(407)] Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
Starting crash reporter; crash reports will be saved to /root/.pulsar/crashdumps
Authorization required, but no authorization protocol specified

[36921:1226/061420.020759:ERROR:ozone_platform_x11.cc(244)] Missing X server or $DISPLAY
[36921:1226/061420.020776:ERROR:env.cc(258)] The platform failed to initialize.  Exiting.
/tmp/pulsar/node_modules/electron/dist/electron exited with signal SIGSEGV
error Command failed with exit code 1.
info Visit https://yarnpkg.com/en/docs/cli/run for documentation about this command.



------------
Host:
echo $XDG_SESSION_TYPE
sudo apt install xwayland
xhost

# the only thing needed:
xhost +local:

------------
Container:

apt-get install --yes --quiet ./dist/pulsar_1.130.1-dev_amd64.deb
Need to get 3809 kB/177 MB of archives.
After this operation, 895 MB of additional disk space will be used.

apt-get install --yes --quiet libasound2t64

Dbus not needed, but these are the commands to install it inside the container:
apt-get install --yes --quiet dbus-x11
dbus-launch
