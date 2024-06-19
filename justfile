BUILD_DIR := justfile_directory() / 'build'

default: build

deps-arch:
    pacman --needed --nonfirm base-devel libxmu libxi libglvnd
deps-debian:
    apt install --yes --no-upgrade build-essential libxmu-dev libxi-dev libgl-dev

[linux]
auto:
    make -C shared/glew/auto -j {{ num_cpus() }}

[linux]
build: auto
    make -C shared/glew -j {{ num_cpus() }} glew.lib

[linux]
install: build
    @mkdir -p {{ BUILD_DIR }}
    GLEW_DEST={{ BUILD_DIR }} make -C shared/glew install

[unix]
clean:
    rm -rf {{ BUILD_DIR }}
