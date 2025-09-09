#!/bin/sh

test -d repos/unikraft || git clone https://github.com/unikraft/unikraft repos/unikraft
test -d repos/openlib || git clone https://github.com/JuliaMath/openlibm repos/openlib
test -d repos/libs/compiler-rt || git clone https://github.com/unikraft/lib-compiler-rt repos/libs/compiler-rt
bash unikraft/setup.sh
test -d unikraft/workdir/libs || unikraft/mkdir workdir/libs
ln -sfn ../../../repos/libs/compiler-rt unikraft/workdir/libs/compiler-rt

cat libm-replace/Make_src.files > repos/openlib/src/Make.files
cat libm-replace/Make_i387.files > repos/openlib/i387/Make.files
cat libm-replace/Make_ld80.files > repos/openlib/ld80/Make.files
cat libm-replace/Make_ld128.files > repos/openlib/ld128/Make.files
cat libm-replace/Make.inc > repos/openlib/Make.inc

(cd repos/openlib; make install-static; cp libopenlibm.a ../../unikraft)





