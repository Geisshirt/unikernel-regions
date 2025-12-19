# MLKIT_SOURCE_RUNTIME=~/mlkit/src/Runtime
# MINIOS_PATH=

SL=$(shell pwd)/UnixRuntimeMini
UNI=$(shell pwd)/unikraft

ifndef t
t=unix
endif

.PHONY: clean echo facfib

FLAGS=--reml --maximum_inline_size 1000 --maximum_specialise_size 1000

SERVICE += Network App

ifeq ($(t), uk)
FLAGS+=-objs -no_delete_target_files
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
	(cd tests; SML_LIB=$(SL) PROF="" mlkit $(FLAGS) -no_gc -o $*test.exe $*test/$*test.mlb)
	./tests/$*test.exe

FORCE: ;

tests: unix tests/*test
# SML_LIB=~/mlkit/src/Runtime mlkit $(FLAGS) -no_gc -prof -o $SML_LIB=$(SL) mlkit $(FLAGS) -no_gc -o $*.exe -libdirs "." -libs "m,c,dl,netiflib" $(shell pwd)/examples/$*/main.mlb
# %.exe: $(t)
# 	gcc -I $(SL)/src/RuntimeMini -o libnetiflib.a -c src/netiflib/netif-tuntap.c
# 	SML_LIB=$(SL) mlkit $(FLAGS) -no_gc -o $*.exe -libdirs "." -libs "m,c,dl,netiflib" $(shell pwd)/examples/$*/main.mlb

%.exe: $(t)
ifeq ($(t), uk)
	SML_LIB=$(SL) PROF="" mlkit $(FLAGS) -no_gc -o $*.exe -libdirs "." -libs "m,c,dl" $(shell pwd)/examples/$*/main.mlb
else
	gcc -I $(SL)/src/RuntimeMini -o libnetiflib.a -c src/netiflib/netif-tuntap.c
	PROF="" mlkit $(FLAGS) -no_gc -o $*.exe -libdirs "." -libs "m,c,dl,netiflib" $(shell pwd)/examples/$*/main.mlb
endif

%-prof-gen: $(t)
	gcc -I $(SL)/src/RuntimeMini -o libnetiflib.a -c src/netiflib/netif-tuntap.c
	PROF="Gen" mlkit $(FLAGS) -no_gc -o $*.exe -libdirs "." -libs "m,c,dl,netiflib" $(shell pwd)/examples/$*/main.mlb

%-prof-run: $(t)
	PROF="Run" mlkit $(FLAGS) -no_gc -prof -Pcee -Ptypes --print_rho_types -o $*.exe $(shell pwd)/examples/$*/main.mlb > prof_out

prof-pdf:
	rp2ps -region -name 'Service: $(SERVICE)' -sampleMax 100000 -sortBySize
	ps2pdf region.ps region.pdf

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
	-rm -rf MLB
	-find src examples tests -type d -name "MLB" -exec rm -rf {} +  # remove all MLB/ directories.
	-rm -rf unikraft/build/*.o
	-rm -rf unikraft/wordir/build/*.o
	-rm -r *.exe
	-rm -r tests/*.exe
	-rm *.ps
	-rm *.out
	-rm run

realclean: clean
	-(cd UnixRuntimeMini; make clean)
