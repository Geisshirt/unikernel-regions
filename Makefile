MLKIT_SOURCE_RUNTIME=~/mlkit/src/Runtime 

MINIOS_PATH=

SL=$(shell pwd)/UnixRuntimeMini

ifndef t 
t=unix
endif

.PHONY: clean echo facfib

FLAGS=

ifeq ($(t), xen)
SL=$(shell pwd)/XenRuntimeMini
FLAGS=-objs -no_delete_target_files
endif

ifeq ($(t), uk)
SL=$(shell pwd)/unikraft/UnikraftRuntimeMini
FLAGS=-objs -no_delete_target_files
endif

APP_OBJS=

setup:
	sudo modprobe tun
	sudo tunctl -u $$USER -t tap0
	sudo ifconfig tap0 10.0.0.1 up
	(cd UnixRuntimeMini; make)

tests/%test: FORCE
	(cd tests; SML_LIB=$(SL) mlkit $(FLAGS) -no_gc -o $*test.exe $*test/$*test.mlb)
	./tests/$*test.exe

FORCE: ;

tests: unix tests/*test 

%.exe: $(t)
	:
# 	ifeq($(t), uk)
# 		SML_LIB=$(shell pwd)/UnixRuntimeMini mlkit $(FLAGS) -no_gc -o $*.exe -libdirs "." -libs "m,c,dl,netiflib" $(shell pwd)/$*/main.mlb
# 	else
# 		SML_LIB=$(SL) mlkit $(FLAGS) -no_gc -o $*.exe -libdirs "." -libs "m,c,dl,netiflib" $(shell pwd)/$*/main.mlb
# 	endif

%Prof: FORCE
	SML_LIB=~/mlkit/src/Runtime mlkit -no_gc -prof -Pcee -o $*Prof.exe $*Prof/main.mlb > out.txt

.PRECIOUS: %.exe
%-app: $(t) %.exe 
	:
ifeq ($(t), xen)
	- rm -r app.a
	- rm -r build
	mkdir build
	ar -x --output build XenRuntimeMini/libm.a
	ar -x --output build XenRuntimeMini/lib/runtimeSystem.a
	cp libnetiflib.a build/libnetiflib.o
	cp $(shell cat $*.exe | cut -d " " -f2-) build
	ar -rc app.a build/*.o
	rm -r build
	(cd $(MINIOS_PATH); make)
endif
ifeq ($(t), uk)
	- rm -rf unikraft/build 
	SML_LIB=$(SL) mlkit $(FLAGS) -no_gc -o $*.exe -libdirs "." -libs "m,c,dl" $(shell pwd)/$*/main.mlb
	mkdir unikraft/build && cp $(shell cat $*.exe | cut -d " " -f2-) unikraft/build
	(cd unikraft; ar -x --output build libopenlibm.a; bash build.sh)
endif

configure:
	sed -i 's|$$(LD) -r $$(LDFLAGS) $$(HEAD_OBJ) $$(OBJS) $$(LDARCHLIB) -o $$@|$$(LD) -r $$(LDFLAGS) $$(HEAD_OBJ) $$(OBJS) $$(LDARCHLIB) $(shell pwd)/app.a -o $$@|g' $(MINIOS_PATH)/Makefile

uk:
	:

unix:
	(cd UnixRuntimeMini; make)
	gcc -I $(SL)/src/RuntimeMini -o libnetiflib.a -c Libs/netiflib/netif-tuntap.c

xen:
	(cd XenRuntimeMini; make)
	gcc -fno-builtin -Wall -Wredundant-decls -Wno-format -Wno-redundant-decls -Wformat -fno-stack-protector -fgnu89-inline -Wstrict-prototypes -Wnested-externs -Wpointer-arith -Winline -g -D__INSIDE_MINIOS__ -m64 -mno-red-zone -fno-reorder-blocks -fno-asynchronous-unwind-tables -DCONFIG_START_NETWORK -DCONFIG_SPARSE_BSS -DCONFIG_BLKFRONT -DCONFIG_NETFRONT -DCONFIG_FBFRONT -DCONFIG_KBDFRONT -DCONFIG_CONSFRONT -DCONFIG_XENBUS -DCONFIG_PARAVIRT -DCONFIG_LIBXS -D__XEN_INTERFACE_VERSION__=0x00030205 -isystem XenRuntimeMini/src/RuntimeMini -isystem XenRuntimeMini/include -isystem XenRuntimeMini/include/x86 -isystem XenRuntimeMini/include/x86/x86_64 -o libnetiflib.a -c Libs/netiflib/netif-miniOS.c

run-uk:
	qemu-system-x86_64 -nographic -m 16 -cpu max -kernel unikraft/workdir/build/unikraft_qemu-x86_64

clean:
	-(cd UnixRuntimeMini; make clean)
	-rm run
	-rm *.a 
	-rm -rf Libs/*lib/MLB MLB
	-rm -rf facfib/MLB
	-rm -rf echo/MLB
	-rm -rf monteCarlo/MLB
	-rm -rf sort/MLB
	-rm -r *.exe
	-rm -r tests/*.exe
