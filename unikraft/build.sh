./setup.sh
make distclean
wget -O /tmp/defconfig https://raw.githubusercontent.com/unikraft/catalog-core/refs/heads/scripts/c-http/scripts/defconfig/qemu.x86_64
UK_DEFCONFIG=/tmp/defconfig make defconfig
make -j $(nproc)
sudo ip link set dev virbr0 down
sudo ip link del dev virbr0
sudo ip link add dev virbr0 type bridge
sudo ip address add 172.44.0.1/24 dev virbr0
sudo ip link set dev virbr0 up