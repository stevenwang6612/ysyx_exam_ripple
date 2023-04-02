include $(AM_HOME)/scripts/isa/riscv64.mk

AM_SRCS := riscv/npc/start.S \
           riscv/npc/trm.c \
           riscv/npc/ioe.c \
           riscv/npc/timer.c \
           riscv/npc/gpu.c \
           riscv/npc/input.c \
           riscv/npc/cte.c \
           riscv/npc/trap.S \
           riscv/npc/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/scripts/linker.ld --defsym=_pmem_start=0x80000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start
CFLAGS += -DMAINARGS=\"$(mainargs)\"
.PHONY: $(AM_HOME)/am/src/riscv/npc/trm.c

DIFF_SPIKE_SO = $(NEMU_HOME)/tools/spike-diff/build/riscv64-spike-so
DIFF_NEMU_SO = $(NEMU_HOME)/riscv64-nemu-interpreter-so
LOGFLAGS = -l $(shell dirname $(IMAGE).elf)/npc-log.txt
WAVFLAGS = -w$(shell dirname $(IMAGE).elf)/wave.vcd
DIFFFLAGS = -d $(DIFF_NEMU_SO)

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt -M no-aliases
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

sdb: image
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) run ARGS="$(DIFFFLAGS) -i $(IMAGE).bin"

run: image
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) run ARGS="$(DIFFFLAGS) -b -i $(IMAGE).bin"

wave: image
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) run ARGS="$(WAVFLAGS) $(LOGFLAGS) -b -i $(IMAGE).bin"

run_fast: image
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) run ARGS="-b -i $(IMAGE).bin"

gdb: image
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) gdb ARGS="$(LOGFLAGS) -i $(IMAGE).bin"
