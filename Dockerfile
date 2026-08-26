# Builds TuxGuitar for Arch Linux (generic "linux-swt" target, native modules
# included) inside a container so the host doesn't need the JDK/Maven/native
# toolchain permanently installed.
#
# Usage:
#   DOCKER_BUILDKIT=1 docker build --output type=local,dest=./dist .
#   sudo ./install-arch.sh ./dist/tuxguitar-*-linux-swt
#
# To skip the (slow) unit tests: add --build-arg SKIP_TESTS=true

FROM archlinux:base AS builder

ARG SWT_VERSION=4.37
ARG SWT_BUILD=R-4.37-202509050730
ARG SKIP_TESTS=false

RUN pacman -Syu --noconfirm --needed \
        base-devel jdk-openjdk maven wget unzip git \
        webkit2gtk-4.1 fluidsynth jack2 alsa-lib lilv suil qt5-base \
    && pacman -Scc --noconfirm

WORKDIR /build
COPY . .

# Eclipse only ships SWT natives for gtk-linux-x86_64/aarch64, matching
# `uname -m` on the build host (same recipe as .github/workflows/ubuntu-maven.yml).
RUN set -eux; \
    ARCH="$(uname -m)"; \
    wget -O /tmp/swt.zip "https://archive.eclipse.org/eclipse/downloads/drops4/${SWT_BUILD}/swt-${SWT_VERSION}-gtk-linux-${ARCH}.zip"; \
    mkdir /tmp/swt && cd /tmp/swt && unzip /tmp/swt.zip; \
    mvn -B install:install-file \
        -Dfile=swt.jar \
        -DgroupId=org.eclipse.swt \
        -DartifactId=org.eclipse.swt.gtk.linux \
        -Dpackaging=jar \
        -Dversion="${SWT_VERSION}"; \
    rm -rf /tmp/swt /tmp/swt.zip

RUN cd desktop/build-scripts/tuxguitar-linux-swt \
    && mvn -B -e clean verify -P native-modules $( [ "$SKIP_TESTS" = "true" ] && echo -DskipTests )

FROM scratch AS export
COPY --from=builder /build/desktop/build-scripts/tuxguitar-linux-swt/target/tuxguitar-*-linux-swt /
