/* SPDX-License-Identifier: BSD-3-Clause */
/*
 * Copyright (c) 2023, Unikraft GmbH and the Unikraft Authors.
 */

#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <uk/alloc.h>
#include <uk/netdev.h>
#include <uk/config.h>
#include <uk/alloc.h>

#define LISTEN_PORT 8080
static const char reply[] = "HTTP/1.1 200 OK\r\n" \
			    "Content-Type: text/html\r\n" \
			    "Content-Length: 21\r\n" \
			    "Connection: close\r\n" \
			    "\r\n" \
			    "Hello from Unikraft!\n";

#define BUFLEN 2048
static char recvbuf[BUFLEN];

int main(int argc __attribute__((unused)),
	 char *argv[] __attribute__((unused)))
{
	struct uk_netdev *dev = uk_netdev_get(0);
	printf("Address of _tx_queue %p in main!\n", dev->_tx_queue[0]);

	struct uk_netdev_info dev_info;

	uk_netdev_info_get(dev, &dev_info);

	struct uk_netbuf *pkt = NULL;

	struct uk_alloc *a = uk_alloc_get_default();

	while (1) {
		int status = uk_netdev_rx_one(dev, 0, &pkt);
		if (uk_netdev_status_successful(status)) {
				printf("Received packet with length: %d\n", pkt->len);
				struct uk_netbuf *nb = uk_netbuf_alloc_buf(a,
								2048,
								dev_info.ioalign,
								dev_info.nb_encap_tx,
								0, NULL);
				if (!nb) {
					printf("Could not allocate!\n");
				} else {
					printf("Allocate!\n");
				}
				nb->len = pkt->len;
				memcpy(nb->data, pkt->data, pkt->len);
				// uk_netdev_tx_one(dev, 0, nb);
				printf("Sent packet!\n");
				// uk_netbuf_free(pkt);
		}
	}
}

// 	int rc = 0;
// 	int srv, client;
// 	ssize_t n;
// 	struct sockaddr_in srv_addr;

// 	srv = socket(AF_INET, SOCK_STREAM, 0);
// 	if (srv < 0) {
// 		fprintf(stderr, "Failed to create socket: %d\n", errno);
// 		goto out;
// 	}

// 	srv_addr.sin_family = AF_INET;
// 	srv_addr.sin_addr.s_addr = INADDR_ANY;
// 	srv_addr.sin_port = htons(LISTEN_PORT);

// 	rc = bind(srv, (struct sockaddr *) &srv_addr, sizeof(srv_addr));
// 	if (rc < 0) {
// 		fprintf(stderr, "Failed to bind socket: %d\n", errno);
// 		goto out;
// 	}

// 	/* Accept one simultaneous connection */
// 	rc = listen(srv, 1);
// 	if (rc < 0) {
// 		fprintf(stderr, "Failed to listen on socket: %d\n", errno);
// 		goto out;
// 	}

// 	printf("Listening on port %d...\n", LISTEN_PORT);
// 	while (1) {
// 		client = accept(srv, NULL, 0);
// 		if (client < 0) {
// 			fprintf(stderr,
// 				"Failed to accept incoming connection: %d\n",
// 				errno);
// 			goto out;
// 		}

// 		/* Receive some bytes (ignore errors) */
// 		read(client, recvbuf, BUFLEN);

// 		/* Send reply */
// 		n = write(client, reply, sizeof(reply) - 1);
// 		if (n < 0)
// 			fprintf(stderr, "Failed to send a reply\n");
// 		else
// 			printf("Sent a reply\n");

// 		/* Close connection */
// 		close(client);
// 	}

// out:
// 	return rc;
// }