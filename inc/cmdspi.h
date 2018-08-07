#ifndef _cmdspi_h_
#define _cmdspi_h_

#define SPI_INIT (1<<0)

#define SPI_IF LPC_SSP1

typedef struct _SpiBuffer{
    uint8_t len;
    uint8_t *data;
}SpiBuffer;


#ifdef __cplusplus
extern "C" {
#endif

#include <common.h>     // all drivers headers should be placed here 
#include "command.h"

class CmdSpi : public Command{

public:
    CmdSpi (Vcom *vc) : Command("spi", vc) { }
    char execute(void *ptr);
    void help(void);
};

void spiWriteBuffer(SpiBuffer *buf);
void spiWrite(uint8_t *data, uint32_t len);

#ifdef __cplusplus
}
#endif

#endif