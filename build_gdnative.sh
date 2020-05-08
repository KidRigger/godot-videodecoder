#! /bin/bash

# usage: ADDON_BIN_DIR=$PWD/godot/addons/bin ./contrib/godot-videodecoder/build_gdnative.sh
# (from within your project where this is a submodule installed at ./contrib/godot-videodecoder/build_gdnative.sh/)

# TODO: Set up a docker container to compile everything:
# http://docs.godotengine.org/en/3.2/development/compiling/compiling_for_x11.html
# http://docs.godotengine.org/en/3.2/development/compiling/compiling_for_windows.html#cross-compiling-for-windows-from-other-operating-systems
# http://docs.godotengine.org/en/3.2/development/compiling/compiling_for_osx.html#cross-compiling-for-macos-from-linux

# NOTE: use XCode 7 for darwin15 support: https://developer.apple.com/download/more/?name=Xcode%207.3.1

# cp contrib/MacOSX10.*.sdk.tar.gz ~/src/osxcross/tarballs
# cd ~/src/osxcross; ./build.sh && ./build_gcc.sh
# https://docs.godotengine.org/en/3.2/tutorials/plugins/gdnative/gdnative-c-example.html

# to build just the plugin, run $0 --no-libs

TARGET_DIR=$PWD/thirdparty
PLUGIN_BIN_DIR=$PWD/bin

ADDON_BIN_DIR=${ADDON_BIN_DIR:-$PWD/godot/addons/bin}

# TODO: make this more portable?
OSXCROSS_BIN_DIR=$HOME/src/osxcross/target/bin

dist="$(lsb_release -is)"
JOBS="$(echo "$(cat /proc/cpuinfo  | grep processor |wc -l) - 1" |  bc -l)"
if [[ "$dist" == "Ubuntu" ]]; then
    echo "you may need to run contrib/ffmpeg-static/install-deps-ubuntu.sh"
fi

on_error() {
    caller
    echo $@
    exit $1
}

trap 'on_error' ERR
if [[ "$1" != "--no-libs" ]]; then
    if [ ! -z "$ADDON_BIN_DIR" ] && [ ! -z "$PLUGIN_BIN_DIR" ]; then
        rm -rf $ADDON_BIN_DIR/* $PLUGIN_BIN_DIR
    fi
    pushd contrib/ffmpeg-static
        set -x
        ./build.sh -B -T "$TARGET_DIR/x11" -j $JOBS
        ./build.sh -B -p windows -T "$TARGET_DIR/win64" -j $JOBS
        ./build.sh -B -p darwin -T "$TARGET_DIR/osx" -j $JOBS
        set +x
    popd
fi
pushd contrib/godot-videodecoder
    set -x
    scons platform=x11 prefix="$ADDON_BIN_DIR"
    scons platform=windows prefix="$ADDON_BIN_DIR"
    # NOTE: -j doesn't work with this platform
    scons platform=osx toolchainbin=$OSXCROSS_BIN_DIR prefix="$ADDON_BIN_DIR"
    set +x
popd
