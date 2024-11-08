set windows-shell := ["powershell.exe"]

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
MAKE := if os() == 'linux' {
    'make'
} else if os() == 'macos' {
    'make'
} else {
    'gmake'
}
RUNIC := 'runic'

default: bindings

[linux]
deps-arch:
    pacman -S --needed --noconfirm base-devel libxmu libxi libglvnd
[linux]
deps-debian:
    apt install --yes --no-upgrade build-essential libxmu-dev libxi-dev libgl-dev libegl-dev python-is-python3
[macos]
deps:
    brew install python
[unix]
deps-freebsd:
    pkg install -y xorg lang/gcc git cmake gmake bash python perl5

[unix]
auto:
    {{ MAKE }} -C shared/glew/auto -j {{ num_cpus() }}

[windows]
build:
    msbuild /p:PlatformToolset=v143 /p:Platform=x64 /p:Configuration=Release shared\glew\build\vc15\glew.sln

[linux]
build: auto (make-directory BUILD_DIR)
    SYSTEM=linux-egl GLEW_DEST={{ BUILD_DIR }} {{ MAKE }} -j {{ num_cpus() }} -C shared/glew install.lib install.include
    @rm -rf lib/linux
    @mkdir -p lib/linux
    -ln -s {{ BUILD_DIR / 'lib' }} {{ BUILD_DIR / 'lib64' }}
    ln -s {{ BUILD_DIR / 'lib64' / 'libGLEW.a' }}  lib/linux/libGLEW.a
    ln -s {{ BUILD_DIR / 'lib64' / 'libGLEW.so' }} lib/linux/libGLEW.so

[macos]
build: auto (make-directory BUILD_DIR)
    DESTDIR={{ BUILD_DIR }} INCDIR=/include LIBDIR=/lib64 {{ MAKE }} -j {{ num_cpus() }} -C shared/glew install.include install.lib
    @rm -rf lib/macos
    @mkdir -p lib/macos
    ln -s {{ BUILD_DIR / 'lib64' / 'libGLEW.a' }} lib/macos/libGLEW.a
    ln -s {{ BUILD_DIR / 'lib64' / 'libGLEW.dylib' }} lib/macos/libGLEW.dylib

[windows]
install:

runic:
    just -f shared/runic/justfile

bindings:
    {{ RUNIC }}

    echo '//+build amd64, arm64' > glew.odin.tmp
    cat glew.odin >> glew.odin.tmp
    mv glew.odin.tmp glew.odin

example static=EXAMPLE_GLEW_STATIC: (make-directory BUILD_DIR)
    odin build example -out:{{ EXAMPLE_BIN }} -debug -thread-count:{{ num_cpus() }} '-extra-linker-flags:{{ EXAMPLE_LINK_FLAGS }}' -define:GLEW_STATIC={{ static }}

[unix]
clean:
    rm -rf {{ BUILD_DIR }}
    {{ MAKE }} -C shared/glew clean
    {{ MAKE }} -C shared/glew/auto clean
    rm -rf shared/glew/auto/EGL-Registry
    rm -rf shared/glew/auto/glfixes
    rm -rf shared/glew/auto/OpenGL-Registry
    rm -rf shared/glew/auto/extensions

[unix]
make-directory DIR:
    @mkdir -p "{{ DIR }}"

[windows]
make-directory DIR:
    @New-Item -Path "{{ DIR }}" -ItemType Directory -Force
