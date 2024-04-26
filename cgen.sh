#!/bin/sh

cc $(pkg-config --cflags libuv) sizes.c -o sizes $(pkg-config --libs libuv)

./sizes > sizes.f90
rm sizes
