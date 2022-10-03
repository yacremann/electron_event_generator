/* ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include <stdlib.h>

#define BUF_LEN 256

#define LED_REG   *((volatile uint32_t*)(0x44a00000))

void read_line(int max, char* result){
	int counter;
	counter = 0;
	char c;
	while (((c = inbyte()) != '\n') && (counter < max)){
		result[counter] = c;
		counter ++;
	}
	result[counter] = 0;
}




void parse_cmd(char* str){
	char* cmdChr = strtok(str, " ");
	if (cmdChr == NULL){
		return;
	}
	char* addrStr = strtok(NULL, " ");
	if (addrStr == NULL){
		print("E\n");
		return;
	}
	uint32_t addr = strtoul(addrStr, NULL, 0);
	// check if address is one of the defined ones on the bus or after then the bus adress space to prevent locked system:
	if ((addr >= 0x44a00000) && (addr <= 0x44a0ffff)){

		// if write operation:
		if (cmdChr[0] == 'w' ){

			char* valueStr = strtok(NULL, " ");
			if (valueStr == NULL){
				print("E\n");
				return;
			}
			uint32_t value = strtoul(valueStr, NULL, 0);
			// here set the value of the register:
			(* (volatile uint32_t *) addr) = value;
			print("OK\n");
		}

		// if read operation:
		if (cmdChr[0] == 'r' ){

			// here read the value of the register:
			uint32_t value = (* (volatile uint32_t *) addr);
			char buffer[BUF_LEN];
			itoa(value,buffer,16);
			print("0x");
			print(buffer);
			print("\n");
		}
	}
	else{
		print("invalid address\n");
	}
	free(str);
}



int main()
{
    init_platform();

    print("\n\n HALLO \n");
    char str[BUF_LEN];
    while(1){
    	read_line(BUF_LEN, str);
    	parse_cmd(str);
    }

    cleanup_platform();
    return 0;
}
