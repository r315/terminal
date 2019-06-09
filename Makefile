#########################################################
# 
#########################################################
GCC_EXEC_PREFIX = arm-none-eabi
GCC = $(GCC_EXEC_PREFIX)-gcc
GPP = $(GCC_EXEC_PREFIX)-g++
AS = $(GCC_EXEC_PREFIX)-as
LD = $(GCC_EXEC_PREFIX)-ld
SIZE = $(GCC_EXEC_PREFIX)-size
OBJCOPY = $(GCC_EXEC_PREFIX)-objcopy
OBJDUMP = $(GCC_EXEC_PREFIX)-objdump
DBG = $(GCC_EXEC_PREFIX)-insight
REMOVE = rm -fR
CHECKSUM =$(BSPPATH)/tools/checksum
#########################################################
# project files
#########################################################
TARGET = LPCbus
PRJPATH =src usbdrv stk500
INCSPATH =inc usbdrv
CSRCS =usbserial.c usbhw_lpc.c usbcontrol.c usbstdreq.c vcom.c \
ili9328.c lcd.c display.c blueboard.c clock_lpc17xx.c timer.c pwm.c i2c.c \
spi_lpc17xx.c dac_lpc17xx.c dma_lpc17xx.c uart_lpc17xx.c \
fifo.c strfunc.c button.c stk500.c \
mmc.c pff.c \

CPPSRCS = \
LPCbus.cpp \
console.cpp \
cmdspi.cpp \
stk500_service.cpp \
cmdavr.cpp \
cmdsbus.cpp \
cmdlsd.cpp \
#cmdmem.cpp \
#cmdpwm.cpp \
#cmdgpio.cpp \
#cmdi2c.cpp \
#cmdawg.cpp \

#command.cpp \

#########################################################
#Startup files and libraries
#########################################################
BSPPATH   = $(LIBEMB_PATH)/bsp

INCSPATH +=inc $(LIBEMB_PATH)/include $(BSPPATH)/CMSISv2p00_LPC17xx/inc $(LIBEMB_PATH)/pff
LIBSPATH +=
OBJPATH =build

GCSYMBOLS =-D__NEWLIB__
GCFLAGS =-mcpu=cortex-m3 -mthumb -Wall -O0 -g #-fno-exceptions -fno-unwind-tables -ffunction-sections
GPPFLAGS=-mcpu=cortex-m3 -mthumb -Wall -O0 -g -fno-exceptions -fno-unwind-tables -fno-rtti #-ffunction-sections 
LDFLAGS =-mcpu=cortex-m3 -mthumb -nostdlib -lgcc #-Wl,--gc-sections -nostartfiles #-lstdc++ 

CSRCS   +=startup_lpc1768.c #syscalls.c
LDSCRIPT =$(BSPPATH)/lpc17xx/lpc1768.ld
##########################################################
OBJECTS = \
$(addprefix $(OBJPATH)/,$(CPPSRCS:.cpp=.obj)) \
$(addprefix $(OBJPATH)/,$(CSRCS:.c=.o)) \
$(addprefix $(OBJPATH)/,$(ASRCS:.S=.o)) \

VPATH = \
$(PRJPATH) \
$(BSPPATH)/lpc17xx/ \
$(LIBEMB_PATH)/drv/tft \
$(LIBEMB_PATH)/drv/spi \
$(LIBEMB_PATH)/drv/timer \
$(LIBEMB_PATH)/drv/pwm \
$(LIBEMB_PATH)/drv/i2c \
$(LIBEMB_PATH)/drv/dac \
$(LIBEMB_PATH)/drv/dma \
$(LIBEMB_PATH)/drv/clock \
$(LIBEMB_PATH)/drv/uart \
$(LIBEMB_PATH)/drv/mmc \
$(LIBEMB_PATH)/display \
$(LIBEMB_PATH)/button \
$(LIBEMB_PATH)/console \
$(LIBEMB_PATH)/misc \
$(LIBEMB_PATH)/pff \

ifeq ($(LIBEMB_PATH), )
erro:
	@echo "Please export LIBEMB_PATH"
endif

all: $(TARGET).elf stats


$(TARGET).elf:  $(OBJECTS)
	@echo "---- Linking ---->" $@
	$(GCC) -T$(LDSCRIPT) $(addprefix -L, $(LIBSPATH)) $(OBJECTS) $(LDFLAGS) -o $(TARGET).elf

$(TARGET).hex: $(TARGET).elf
	@$(OBJCOPY) -O ihex -j .startup -j .text $(TARGET).elf $(TARGET).hex

bin: $(TARGET).bin

$(TARGET).bin: $(TARGET).elf
#@$(OBJCOPY) -O binary  $(TARGET).elf $@
	$(OBJCOPY) -O binary -j .startup -j .text $(TARGET).elf $@
	hd -n 128 $@
	$(CHECKSUM) $@

stats: $(TARGET).elf
	@echo "---- Sections Summary ---"
	@$(SIZE) -A -x $<

aslist: $(TARGET).elf
	@$(OBJDUMP) -D $(TARGET).elf > $(TARGET).lst

clean:
#$(REMOVE) $(OBJPATH)/*.obj $(OBJPATH)/*.o *.hex *.elf *.bin	
	$(REMOVE) $(OBJPATH)  

rebuild: clean all

inline_asm:
	$(GCC) -Og -g -mcpu=cortex-m3 -mthumb -Wall -c inline_asm.c -o inline_asm.o
	$(GCC) -Tinline_asm.ld inline_asm.o -nostdlib -nostartfiles -o inline_asm.elf

$(TARGET).jlink:
	@echo "Creating Jlink configuration file"
	@echo "erase\nloadbin $(TARGET).bin , 0x0000000\nr\nq" > $(TARGET).jlink
	
#flash-jlink: $(TARGET).jlink #tdso.bin #$(TARGET).bin
#	$(JLINK) -device $(DEVICE) -if SWD -speed auto -CommanderScript $(TARGET).jlink

$(TARGET).cfg:
	@echo "Creating opencod configuration file"
	echo "interface jlink\ntransport select swd\nsource [find target/lpc17xx.cfg]\nadapter_khz 4000" > $(TARGET).cfg

flash-openocd: $(TARGET).bin $(TARGET).cfg
	openocd -f $(TARGET).cfg -c "program $(TARGET).bin 0x00000000 verify reset exit"

minicom:
	minicom -b 115200 -D /dev/ttyACM0

#make command CMDNAME=<name>
TEMPLATEIN =cmdTemplate.in
L1 =en
SHELL := /bin/bash
command:	
	@cat  $(TEMPLATEIN) > inc/cmd$(CMDNAME).h
	@sed -i -- "s/%NAME%/$(CMDNAME)/g" inc/cmd$(CMDNAME).h
	@sed -i -- "s/%CLASSNAME%/$(shell L1=$(CMDNAME); echo $${L1^})/g" inc/cmd$(CMDNAME).h
	
$(OBJPATH):
	mkdir $@
	
########################################################
$(OBJPATH)/%.o : %.c | $(OBJPATH)
	@echo "---- Compile" $< "---->" $@
	@$(GCC) $(GCFLAGS) $(addprefix -I, $(INCSPATH)) $(GCSYMBOLS) -c $< -o $@

$(OBJPATH)/%.obj : %.cpp | $(OBJPATH)
	@echo "---- Compile" $< "---->" $@
	@$(GPP) $(GPPFLAGS) $(addprefix -I, $(INCSPATH)) $(GCSYMBOLS) -c $< -o $@
	
$(OBJPATH)/%.o : %.S | $(OBJPATH)
	@echo "---- Assemble" $< "---->" $@
	@$(AS) $(ASFLAGS) $< -o $@

