set windows-shell := ["C:\\Windows\\System32\\cmd.exe", "/k"]

BUILD_DIR := justfile_directory() / 'build'

default: to

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

[windows]
build:
    msbuild /p:PlatformToolset=v143 /p:Platform=x64 /p:Configuration=Release shared\glew\build\vc15\glew.sln

[linux]
install: build
    @mkdir -p {{ BUILD_DIR }}
    GLEW_DEST={{ BUILD_DIR }} make -C shared/glew install

[windows]
install:

runic:
    just -f shared/runic/justfile

from: runic install
    @mkdir -p {{ BUILD_DIR / 'runestone' }}
    shared/runic/build/runic --os linux from.json > {{ BUILD_DIR / 'runestone' / 'glew.linux' }}

to: from
    shared/runic/build/runic to.json

[unix]
clean:
    rm -rf {{ BUILD_DIR }}
    rm -f glew.odin
