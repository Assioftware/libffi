#!/bin/bash

set -x

if [ -z ${QEMU_CPU+x} ]; then
    export SET_QEMU_CPU=
else
    export SET_QEMU_CPU="-e QEMU_CPU=${QEMU_CPU}"
fi

# Default to podman where available, docker otherwise.
# Override by setting the DOCKER environment variable.
if test -z "$DOCKER"; then
  which podman > /dev/null 2>&1
  if [ $? != 0 ]; then
    export DOCKER=docker
  else
    export DOCKER=podman
  fi
fi

function build_cfarm()
{
    curl -u ${CFARM_AUTH} https://cfarm-test-libffi-libffi.apps.home.labdroid.net/test?host=${HOST}\&commit=${TRAVIS_COMMIT} | tee build.log
    echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo $(tail build.log | grep '^==LOGFILE==')
    echo $(tail build.log | grep '^==LOGFILE==' | cut -b13-)
    echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    curl -u ${CFARM_AUTH} "$(tail build.log | grep '^==LOGFILE==' | cut -b13-)" > libffi.log

    ./rlgl l https://rl.gl
    ID=$(./rlgl start)
    ./rlgl e --id=$ID --policy=https://github.com/libffi/rlgl-policy.git libffi.log
    exit $?
}

function build_linux()
{
    ./autogen.sh
    ./configure ${HOST+--host=$HOST} ${CONFIGURE_OPTIONS}
    make
    make dist
    make check RUNTESTFLAGS="-a $RUNTESTFLAGS"

    ./rlgl l https://rl.gl
    ID=$(./rlgl start)
    ./rlgl e --id=$ID --policy=https://github.com/libffi/rlgl-policy.git */testsuite/libffi.log
    exit $?
}

function build_foreign_linux()
{
    ${DOCKER} run --rm -t -i -v `pwd`:/opt ${SET_QEMU_CPU} -e LIBFFI_TEST_OPTIMIZATION="${LIBFFI_TEST_OPTIMIZATION}" $2 bash -c /opt/.travis/build-in-container.sh

    ./rlgl l https://rl.gl
    ID=$(./rlgl start)
    ./rlgl e --id=$ID --policy=https://github.com/libffi/rlgl-policy.git */testsuite/libffi.log
    exit $?
}

function build_cross_linux()
{
    ${DOCKER} run --rm -t -i -v `pwd`:/opt ${SET_QEMU_CPU} -e HOST="${HOST}" -e CC="${HOST}-gcc-8 ${GCC_OPTIONS}" -e CXX="${HOST}-g++-8 ${GCC_OPTIONS}" -e LIBFFI_TEST_OPTIMIZATION="${LIBFFI_TEST_OPTIMIZATION}" moxielogic/cross-ci-build-container:latest bash -c /opt/.travis/build-in-container.sh

    ./rlgl l https://rl.gl
    ID=$(./rlgl start)
    ./rlgl e --id=$ID --policy=https://github.com/libffi/rlgl-policy.git */testsuite/libffi.log
    exit $?
}

function build_cross()
{
    ${DOCKER} run --rm -t -i -v `pwd`:/opt -e HOST="${HOST}" -e CC="${HOST}-gcc ${GCC_OPTIONS}" -e CXX="${HOST}-g++ ${GCC_OPTIONS}" -e LIBFFI_TEST_OPTIMIZATION="${LIBFFI_TEST_OPTIMIZATION}" docker.io/moxielogic/libffi-ci-${HOST} bash -c /opt/.travis/build-cross-in-container.sh

    ./rlgl l https://rl.gl
    ID=$(./rlgl start)
    ./rlgl e --id=$ID --policy=https://github.com/libffi/rlgl-policy.git */testsuite/libffi.log
    exit $?
}

function build_ios()
{
    which python
# export PYTHON_BIN=/usr/local/bin/python
    ./generate-darwin-source-and-headers.py --only-ios
    xcodebuild -showsdks
    xcodebuild -project libffi.xcodeproj -target "libffi-iOS" -configuration Release -sdk iphoneos11.4
    exit $?
}

function build_macosx()
{
    which python
# export PYTHON_BIN=/usr/local/bin/python
    ./generate-darwin-source-and-headers.py --only-osx
    xcodebuild -showsdks
    xcodebuild -project libffi.xcodeproj -target "libffi-Mac" -configuration Release -sdk macosx10.13
    exit $?
}

case "$HOST" in
    arm-apple-darwin*)
	./autogen.sh
	build_ios
	;;
    x86_64-apple-darwin*)
	./autogen.sh
	build_macosx
	;;
    arm32v7-linux-gnu)
	./autogen.sh
        build_foreign_linux arm moxielogic/arm32v7-ci-build-container:latest 
	;;
    aarch64-linux-gnu| powerpc64le-unknown-linux-gnu | mips64el-linux-gnu | sparc64-linux-gnu)
        build_cfarm
	;;
    bfin-elf )
	./autogen.sh
	GCC_OPTIONS=-msim build_cross
	;;
    m32r-elf )
	./autogen.sh
	build_cross
	;;
    m68k-linux-gnu )
	./autogen.sh
	GCC_OPTIONS=-mcpu=547x build_cross_linux
	;;
    alpha-linux-gnu | sh4-linux-gnu | s390x-linux-gnu )
	./autogen.sh
	build_cross_linux
	;;
    *)
	./autogen.sh
	build_linux
	;;
esac
