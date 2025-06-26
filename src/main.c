/*
 * Copyright (c) 2016 Intel Corporation
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <stdio.h>
#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/drivers/i2c.h>
#include <zephyr/sys/printk.h>
#include <logging/log_rpc.h>
#include <dk_buttons_and_leds.h>
#include "ble/ble.h"
#include <stdint.h>



#define STEMMAADDRESS 0x36
#define BASEREGISTER 0x0F
#define FUNCTIONREGISTER 0x10


uint16_t capacitance; 

/* The devicetree node identifier for the "led0" alias. */
#define LED0_NODE DT_ALIAS(led0)
#define I2C_NODE DT_NODELABEL(i2c1)
/*
 * A build error on this line means your board is unsupported.
 * See the sample documentation for information on how to fix this.
 */
//static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(LED0_NODE, gpios);
static const struct device *i2c_dev = DEVICE_DT_GET(I2C_NODE); 



void scan_i2c_bus(const struct device *dev)
{
    printk("Starting I2C scan...\n");
    for (uint8_t addr = 0x03; addr <= 0x77; addr++) {
        if (i2c_write(dev, NULL, 0, addr) == 0) {
            printk("Device found at 0x%02X\n", addr);
        }       
    }
    printk("I2C scan done\n");
}

int main(void)
{



	
	int ret; 
	
	ble_init(); 
	


	scan_i2c_bus(i2c_dev);

	if(!device_is_ready(i2c_dev)){
		printk("i2c_dev not ready\n"); 
	
	}

	while(1) {
	uint8_t config[2] = {BASEREGISTER,FUNCTIONREGISTER};
	ret = i2c_write(i2c_dev, config, 2, 0x36);

	printk("%d\n", ret); // ret reads 0 if successful 
	
	if(ret != 0){
	printk("Failed to write to I2C device\n");
	}
	
	k_msleep(3);

    // Read 2 bytes of data from the sensor
    uint8_t data[2];
    ret = i2c_read(i2c_dev, data, 2, STEMMAADDRESS);
    if (ret != 0) {
        printk("Read failed: %d\n", ret);
    
		capacitance = 0; 
    }


	if(ret == 0) {
			uint16_t capacitance_value = (data[0] << 8) | data[1];
    printk("Seesaw value: %u\n", capacitance_value);

	capacitance = capacitance_value; 
	}

		ble_notify_capacitance();

		 k_sleep(K_MSEC(1000));

	}
	return 0;
}
