#!/bin/sh
git submodule update --init --recursive

cat libm-replace/Make_src.files > external/openlib/src/Make.files
cat libm-replace/Make_i387.files > external/openlib/i387/Make.files
cat libm-replace/Make_ld80.files > external/openlib/ld80/Make.files
cat libm-replace/Make_ld128.files > external/openlib/ld128/Make.files
cat libm-replace/Make.inc > external/openlib/Make.inc

(cd external/openlib; make install-static; cp libopenlibm.a ../../unikraft)
