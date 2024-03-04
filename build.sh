nasm -fmacho64 ez_strlen.asm -o ez_strlen.o
ld -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/ -platform_version macos 12.0.0 12.0 -lSystem ez_strlen.o -o ez_strlen

