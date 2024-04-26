#!/bin/sh

egfortran sizes.f90 main.f90 $(pkg-config --libs libuv) -lgfortran -lm
