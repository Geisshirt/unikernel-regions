MLKIT_SOURCE_RUNTIME=~/mlkit/src/Runtime

MINIOS_PATH=

SL=$(shell pwd)/UnixRuntimeMini
UNI=$(shell pwd)/unikraft

ifndef t
t=unix
endif

.PHONY: clean echo facfib

FLAGS=

ifeq ($(t), uk)
FLAGS=-objs -no_delete_target_files
endif

APP_OBJS=

setup:
ifeq ($(t), unix)
	sudo modprobe tun
	sudo tunctl -u $$USER -t tap0
	sudo ifconfig tap0 10.0.0.1 up
endif
ifeq ($(t), uk)
	bash setup.sh
endif

tests/%test: FORCE
	(cd tests; SML_LIB=$(SL) mlkit $(FLAGS) -no_gc -o $*test.exe $*test/$*test.mlb)
	./tests/$*test.exe

FORCE: ;

tests: unix tests/*test

%.exe: $(t)
	gcc -I $(SL)/src/RuntimeMini -o libnetiflib.a -c src/netiflib/netif-tuntap.c
	SML_LIB=$(SL) mlkit $(FLAGS) -no_gc -o $*.exe -libdirs "." -libs "m,c,dl,netiflib" $(shell pwd)/examples/$*/main.mlb

%Prof: FORCE
	SML_LIB=~/mlkit/src/Runtime mlkit -no_gc -prof -Pcee -o $*Prof.exe $*Prof/main.mlb > out.txt

.PRECIOUS: %.exe
%-ex-app: %.exe
	:
ifeq ($(t), uk)
	rm -rf $(UNI)/build/*.o
	cp $(shell cat $*.exe | cut -d " " -f2-) $(UNI)/build
	(cd $(UNI); ar -x --output build libopenlibm.a; bash build.sh)
endif

unix:
	(cd UnixRuntimeMini; make)

uk:
	:

run-uk:
	sudo qemu-system-x86_64 \
    -nographic \
    -m 4096 \
    -cpu max \
    -netdev bridge,id=en0,br=virbr0 \
	-device virtio-net-pci,netdev=en0,mac=7c:75:b2:39:d4:84 \
    -append "unikraft netdev.ip=172.44.0.2/24:172.44.0.1::: -- " \
    -kernel $(UNI)/workdir/build/unikraft_qemu-x86_64

clean:
	-rm *.a
	-rm -rf src/*lib/MLB MLB
	-rm -rf tests/*/MLB
	-rm -rf examples/*/MLB
	-rm -rf unikraft/build/*.o
	-rm -rf unikraft/wordir/build/*.o
	-rm -r *.exe
	-rm -r tests/*.exe

realclean: clean
	-(cd UnixRuntimeMini; make clean)