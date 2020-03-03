export CXXFLAGS="$CXXFLAGS -fPIC"
export CFLAGS="$CFLAGS -fPIC"
./dockcross-linux-armv7a cmake -Bbuild -HEggDriver
./dockcross-linux-armv7a cmake --build build