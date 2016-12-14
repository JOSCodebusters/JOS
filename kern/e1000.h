#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#include <kern/pci.h>
#include <inc/string.h>
#include <kern/pmap.h>



int e1000_pci_attach(struct pci_func *pcif);
int e1000_pci_tx(char *data, size_t len);

#define E1000_STATUS     0x00008/4  /* Device Status - RO */

#define TX_DESC_SIZE	64		// size of transmit descriptor array is 64 in order to detect transmit ring overflow
#define MAX_PKT_SIZE	1518


/* Transmit control registers */
#define E1000_TCTL     	  0x00400/4  /* TX Control - RW */
#define E1000_TCTL_EN     0x00000002    /* enable tx */
#define E1000_TCTL_PSP    0x00000008    /* pad short packets */
#define E1000_TCTL_CT     0x00000ff0    /* collision threshold */
#define E1000_TCTL_COLD   0x003ff000    /* collision distance */

/* Transmit descriptor base address registers */
#define E1000_TDBAL    0x03800/4  /* TX Descriptor Base Address Low - RW */
#define E1000_TDBAH    0x03804/4  /* TX Descriptor Base Address High - RW */
#define E1000_TDLEN    0x03808/4  /* TX Descriptor Length - RW */
#define E1000_TDH      0x03810/4  /* TX Descriptor Head - RW */
#define E1000_TDT      0x03818/4  /* TX Descripotr Tail - RW */

/* Transmit IPG registers */
#define E1000_TIPG     0x00410/4  /* TX Inter-packet gap -RW */

/* Transmit Descriptor bit definitions */
#define E1000_TXD_CMD_RS     0x00000008 /* Report Status */
#define E1000_TXD_CMD_EOP    0x00000001 /* End of Packet */
#define E1000_TXD_STAT_DD    0x00000001 /* Descriptor Done */


struct tx_desc
{
	uint64_t addr;
	uint16_t length;
	uint8_t cso;
	uint8_t cmd;
	uint8_t status;
	uint8_t css;
	uint16_t special;
}__attribute__((packed));

struct tx_pkt
{
	uint8_t buf[MAX_PKT_SIZE];
}__attribute__((packed));

#endif	// JOS_KERN_E1000_H
