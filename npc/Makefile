TOPNAME = top
INC_PATH += $(NPC_HOME)/csrc/include

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
WAIVER = $(OBJ_DIR)/waiver.vlt
BIN = $(BUILD_DIR)/$(TOPNAME)
WAVE = $(BUILD_DIR)/wave.vcd
LOG_FILE = $(NPC_HOME)/build/log.txt
DIFF_SPIKE_SO = -d $(NEMU_HOME)/tools/spike-diff/build/riscv64-spike-so
DIFF_NEMU_SO = -d $(NEMU_HOME)/build/riscv64-nemu-interpreter-so

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc --trace \
				-O3 --x-assign fast --x-initial fast --noassert \
        -Wall -Wno-UNUSED 
VERILATOR_CFLAGS +=  --waiver-output $(WAIVER)

ARGS = -l $(LOG_FILE) 

# project source
VSRCS = $(shell find ~/common/rtl -name "*.v")
VSRCS += $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cpp")

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
LDFLAGS += -lSDL2 -lSDL2_image -lreadline -pie -ldl

#llvm
CFLAGS += -I/usr/lib/llvm-11/include -std=c++14 -fno-exceptions -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -fPIE
LDFLAGS += $(shell llvm-config --libs)

$(shell mkdir -p $(BUILD_DIR))

$(BIN): $(VSRCS) $(CSRCS) 
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

default: $(BIN)

run: $(BIN)
	$(call git_commit, "compile RTL") # DO NOT REMOVE THIS LINE!!!
	$(BIN) $(ARGS)

$(WAVE): $(BIN)
	@./build/$(TOPNAME) -w

wave: $(WAVE)
	@vcd2wlf.exe $^ wave.wlf
	modelsim.exe wave.wlf &

gtkwave: $(WAVE)
	gtkwave $^

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(BIN) $(ARGS) -b
	@make wave

count:
	@find ./vsrc -name "*.v" | xargs cat | wc -l | xargs echo -n "verilog:" && echo " lines"
	@find ./csrc -name "*.cpp" -o -name "*.cc" -o -name "*.c" -o -name "*.h"| xargs cat | wc -l | xargs echo -n "c & cpp:" && echo " lines"

clean:
	rm -rf $(BUILD_DIR)

.PHONY: clean run sim

include ../Makefile
