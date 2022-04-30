TOPNAME = top
INC_PATH += $(NPC_HOME)/csrc/include

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
WAIVER = $(OBJ_DIR)/waiver.vlt
BIN = $(BUILD_DIR)/$(TOPNAME)
WAVE = $(BUILD_DIR)/wave.vcd

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc --trace \
				-O3 --x-assign fast --x-initial fast --noassert \
        -Wall -Wno-UNUSED 
VERILATOR_CFLAGS +=  --waiver-output $(WAIVER)

ARGS =

# project source
VSRCS = $(shell find ~/common/rtl -name "*.v")
VSRCS += $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
LDFLAGS += -lSDL2 -lSDL2_image -lreadline

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
	./build/$(TOPNAME) $(ARGS)

$(WAVE): $(BIN)
	@./build/$(TOPNAME) -w

$(BUILD_DIR)/wave.wlf: $(WAVE)
	@vcd2wlf.exe $^ $@

wave: $(BUILD_DIR)/wave.wlf
	modelsim.exe wave.wlf &

gtkwave: $(WAVE)
	gtkwave $^

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@make wave

count:
	@find ./vsrc -name "*.v" | xargs cat | wc -l | xargs echo -n "verilog:" && echo " lines"
	@find ./csrc -name "*.cpp" -o -name "*.cc" -o -name "*.c" -o -name "*.h"| xargs cat | wc -l | xargs echo -n "c & cpp:" && echo " lines"

clean:
	rm -rf $(BUILD_DIR)

.PHONY: clean run sim

include ../Makefile
