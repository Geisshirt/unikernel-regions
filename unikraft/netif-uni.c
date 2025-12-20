#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <uk/alloc.h>
#include <uk/netdev.h>
#include <uk/config.h>
#include <uk/alloc.h>
#include "String.h"
#include "List.h"
#include "Math.h"

#define MTU 1518

struct uk_netdev_info dev_info;

struct uk_netdev *dev = NULL;

struct uk_alloc *a = NULL;

void setup() {
    printf("setup!\n");
    dev = uk_netdev_get(0);

    a = uk_alloc_get_default();

    uk_netdev_mtu_set(dev, MTU);

    uint16_t d = uk_netdev_mtu_get(dev);

    printf("\nMTU: %u\n", d);

	uk_netdev_info_get(dev, &dev_info);    
}

String REG_POLY_FUN_HDR(toMLString, Region rAddr, const char *cStr, int len) {  
    String res;
    char *p;
    res = REG_POLY_CALL(allocStringC, rAddr, len);
    for (p = res->data; len > 0;) {
        *p++ = *cStr++;
        len--;
    }
    *p = '\0';
    return res;
}


String Receive(__attribute__ ((unused)) int addr, Region str_r, __attribute__ ((unused)) Context ctx) {
    dev = uk_netdev_get(0);

    uint16_t d = uk_netdev_mtu_get(dev);

    printf("\nMTU: %u\n", d);
    
    if (dev == NULL) {
        setup();
    }

    ssize_t bytesRead = 0;
    char buf[MTU]; // MTU + 18 (the 18 bytes are header and frame check sequence)

    struct uk_netbuf *pkt = NULL;

    while (1) {
		int status = uk_netdev_rx_one(dev, 0, &pkt);
		if (uk_netdev_status_successful(status)) {
            memcpy(buf, pkt->data, pkt->len);
            bytesRead = pkt->len;

            uk_netbuf_free(pkt);
            break;
		}
	}

    printf("Received %d bytesss\n", bytesRead);

    // Null-terminate the buffer
    buf[bytesRead] = '\0';
    return toMLString(str_r, buf, bytesRead); 
}

// Optimize here
void Send(uintptr_t byte_list) {
    char toWrite_buf[MTU] = {0};

    uintptr_t ys;
    int i = 0;
    for (ys = byte_list; isCONS(ys) && i <= MTU; ys=tl(ys)) {
        toWrite_buf[i++] = convertIntToC(hd(ys));
    }

    struct uk_netbuf *nb = uk_netbuf_alloc_buf(a,
								2048,
								dev_info.ioalign,
								dev_info.nb_encap_tx,
								0, NULL);

    nb->len = i;
    memcpy(nb->data, toWrite_buf, i);
    
    int ret;

    printf("SEND ONE PACKET!\n");

    do {
		ret = uk_netdev_tx_one(dev, 0, nb);
	} while (uk_netdev_status_notready(ret));

    printf("ret: %d\n", ret);

    if (unlikely(ret < 0)) {
		printf("Failed to send");
		uk_netbuf_free_single(nb);
	}
}