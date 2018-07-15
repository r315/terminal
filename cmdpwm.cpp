#include "cmdpwm.h"


void CmdPwm::start(void){
        vcom->printf("1kHz square wave on P2.0 (TXD1) using pwm\n");
        PWM_Init(1000);
	    PWM_Enable(1);
	    PWM_Set(1, 50);
}

char CmdPwm::execute(void *ptr){
    char *p1, *p2;
    start();
    return CMD_OK;
}