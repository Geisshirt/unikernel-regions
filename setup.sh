#!/bin/sh

test -d repos/unikraft || git clone https://github.com/unikraft/unikraft repos/unikraft
test -d repos/libs/lwip || git clone https://github.com/unikraft/lib-lwip repos/libs/lwip
test -d repos/openlib || git clone https://github.com/JuliaMath/openlibm repos/openlib

cat libm-replace/Make_src.files > repos/openlib/src/Make.files
cat libm-replace/Make_i387.files > repos/openlib/i387/Make.files
cat libm-replace/Make_ld80.files > repos/openlib/ld80/Make.files
cat libm-replace/Make_ld128.files > repos/openlib/ld128/Make.files
cat libm-replace/Make.inc > repos/openlib/Make.inc

(cd repos/openlib; make install-static; cp libopenlibm.a ../../unikraft)
(cd repos/openlib; make install-static; cp libopenlibm.a ../../c-http)





