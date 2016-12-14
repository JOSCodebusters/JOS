#include <kern/e1000.h>


// LAB 6: Your driver code here
volatile uint32_t *e1000_pci_addr;

struct tx_desc tx_desc_array[TX_DESC_SIZE];		// TX_DESC_SIZE = 64
struct tx_pkt tx_pkt_buf[TX_DESC_SIZE];

int e1000_pci_attach(struct pci_func *pcif){
	int i;
	
	pci_func_enable(pcif);		// Attach the device and enable it
	
	e1000_pci_addr = mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);		// create a virtual memory mapping for the E1000's BAR 0
	
	cprintf("E1000_PCI_ADDRESS = %x\n", e1000_pci_addr[E1000_STATUS]);
	
	memset(tx_desc_array, 0, sizeof(struct tx_desc) * TX_DESC_SIZE);
	
	/* Transmit initialization */

	e1000_pci_addr[E1000_TDBAL] = PADDR(tx_desc_array);
	e1000_pci_addr[E1000_TDBAH] = 0x00;		// because physical address is 32-bit
	
	e1000_pci_addr[E1000_TDLEN] = sizeof(struct tx_desc) * TX_DESC_SIZE;
	
	e1000_pci_addr[E1000_TDH] = 0x00;		// initially at 0
	e1000_pci_addr[E1000_TDT] = 0x00;		// initially at 0
	
	e1000_pci_addr[E1000_TCTL] = E1000_TCTL_EN;		// bit 1
	e1000_pci_addr[E1000_TCTL] |= E1000_TCTL_PSP;	// bit 3
	
	e1000_pci_addr[E1000_TCTL] &= ~E1000_TCTL_CT;	// bits 11:4 - Clear the bits and then set to 10h
	e1000_pci_addr[E1000_TCTL] |= (0x10) << 4;
	
	e1000_pci_addr[E1000_TCTL] &= ~E1000_TCTL_COLD;	// bits 21:12 - Clear the bits and then set to 40h for full duplex
	e1000_pci_addr[E1000_TCTL] |= (0x40) << 12;
	
	e1000_pci_addr[E1000_TIPG] = 0x0;
	e1000_pci_addr[E1000_TIPG] |= 0xA;			// IPGT = 10 (802.3 standard)
	e1000_pci_addr[E1000_TIPG] |= (0x4) << 10;	// IPGR1 = 2/3 of IPGR2
	e1000_pci_addr[E1000_TIPG] |= (0x6) << 20;	// IPGR2 = 6 (802.3 standard)
	
	/* in order to relate the descriptors with packets */
	for(i = 0; i < TX_DESC_SIZE; i++){
		tx_desc_array[i].addr = PADDR(tx_pkt_buf[i].buf);
		tx_desc_array[i].status |= E1000_TXD_STAT_DD;
	}

	return 0;
}

/* Transmit function */
/* Return 0 on SUCCESS and -1 otherwise */
int e1000_pci_tx(char *data, size_t len){
	
	if(len > MAX_PKT_SIZE)
		return -1;

	uint32_t tail = e1000_pci_addr[E1000_TDT];
	
	if(tx_desc_array[tail].status & E1000_TXD_STAT_DD){
		memmove(tx_pkt_buf[tail].buf, data, len);
		tx_desc_array[tail].length = len;
		tx_desc_array[tail].status = ~E1000_TXD_STAT_DD;	// clear the status flag
		
		tx_desc_array[tail].cmd |= E1000_TXD_CMD_RS | E1000_TXD_CMD_EOP;
		
		e1000_pci_addr[E1000_TDT] = (tail+1) % TX_DESC_SIZE;
		
		return 0;
	}
	
	else
		return -1;
}










