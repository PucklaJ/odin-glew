set windows-shell := ["C:\\Windows\\System32\\cmd.exe", "/k"]

BUILD_DIR := justfile_directory() / 'build'
EXAMPLE_BIN := BUILD_DIR / 'game_of_life' + if os_family() == 'windows' {'.exe'} else {''}
EXAMPLE_LINK_FLAGS := if os() == 'windows' {
    'opengl32.lib'
} else if os() == 'linux' {
    '-lEGL -lGL'
} else if os() == 'macos' {
    '-framework OpenGL'
} else {
    '-L/usr/local/lib -lGL'
}
EXAMPLE_GLEW_STATIC := if os_family() == 'windows' {
    'true'
} else if os() == 'macos' {
    'true'
} else {
    'false'
}

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
    SYSTEM=linux-egl make -C shared/glew -j {{ num_cpus() }} glew.lib

[windows]
build:
    msbuild /p:PlatformToolset=v143 /p:Platform=x64 /p:Configuration=Release shared\glew\build\vc15\glew.sln

[linux]
install: build
    @mkdir -p {{ BUILD_DIR }}
    SYSTEM=linux-egl GLEW_DEST={{ BUILD_DIR }} make -C shared/glew install
    @rm -rf lib/linux
    @mkdir -p lib/linux
    ln -s {{ BUILD_DIR / 'lib64' / 'libGLEW.a' }}  lib/linux/libGLEW.a
    ln -s {{ BUILD_DIR / 'lib64' / 'libGLEW.so' }} lib/linux/libGLEW.so

[windows]
install:

runic:
    just -f shared/runic/justfile

from: runic install
    @mkdir -p {{ BUILD_DIR / 'runestones' }}
    shared/runic/build/runic --os linux   --arch x86_64 from.json > {{ BUILD_DIR / 'runestones' / 'glew.linux.x86_64' }}
    shared/runic/build/runic --os linux   --arch arm64  from.json > {{ BUILD_DIR / 'runestones' / 'glew.linux.arm64' }}
    shared/runic/build/runic --os windows --arch x86_64 from.json > {{ BUILD_DIR / 'runestones' / 'glew.windows.x86_64' }}

to: from
    shared/runic/build/runic to.json

example:
    odin build example -out:{{ EXAMPLE_BIN }} -debug -thread-count:{{ num_cpus() }} '-extra-linker-flags:{{ EXAMPLE_LINK_FLAGS }}' -define:GLEW_STATIC={{ EXAMPLE_GLEW_STATIC }}

[unix]
clean:
    rm -rf {{ BUILD_DIR }}
    make -C shared/glew clean
    make -C shared/glew/auto clean
