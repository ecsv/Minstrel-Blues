LUAC ?= luac
SRC_DIR	= .
BIN_DIR	?= bin
ROOT ?= /
INSTALL_BIN_DIR	?= $(ROOT)/usr/bin
INSTALL_LUA_LIB_DIR	?= $(ROOT)/usr/lib/lua/5.1

CPUSAGE_SINGLE = cpusage_single
FETCH_FILE = fetch_file
TRACE_WIFI = traceWifi
RUN_CONTROL = runControl
RUN_LOGGER = runLogger
RUN_NODE = runNode
KILL_REMOTE = kill_remote
ANALYSE_SNR = analyseSNR

all: $(FETCH_FILE) $(TRACE_WIFI) $(RUN_CONTROL) $(RUN_LOGGER) $(RUN_NODE) $(KILL_REMOTE) $(ANALYSE_SNR)

$(FETCH_FILE): $(BIN_DIR)/$(FETCH_FILE).lua
	$(LUAC) -o $(BIN_DIR)/$(FETCH_FILE) "$<"
	chmod 755 $(BIN_DIR)/$(FETCH_FILE)

$(TRACE_WIFI): $(BIN_DIR)/$(TRACE_WIFI).lua
	$(LUAC) -o $(BIN_DIR)/$(TRACE_WIFI) "$<"
	chmod 755 $(BIN_DIR)/$(TRACE_WIFI)

$(RUN_CONTROL): $(BIN_DIR)/$(RUN_CONTROL).lua
	$(LUAC) -o $(BIN_DIR)/$(RUN_CONTROL) "$<"
	chmod 755 $(BIN_DIR)/$(RUN_CONTROL)

$(RUN_LOGGER): $(BIN_DIR)/$(RUN_LOGGER).lua
	$(LUAC) -o $(BIN_DIR)/$(RUN_LOGGER) "$<"
	chmod 755 $(BIN_DIR)/$(RUN_LOGGER)

$(RUN_NODE): $(BIN_DIR)/$(RUN_NODE).lua
	$(LUAC) -o $(BIN_DIR)/$(RUN_NODE) "$<"
	chmod 755 $(BIN_DIR)/$(RUN_NODE)

$(KILL_REMOTE): $(BIN_DIR)/$(KILL_REMOTE).lua
	$(LUAC) -o $(BIN_DIR)/$(KILL_REMOTE) "$<"
	chmod 755 $(BIN_DIR)/$(KILL_REMOTE)

$(ANALYSE_SNR): $(BIN_DIR)/$(ANALYSE_SNR).lua
	$(LUAC) -o $(BIN_DIR)/$(ANALYSE_SNR) "$<"
	chmod 755 $(BIN_DIR)/$(ANALYSE_SNR)

.PHONY: all

clean:
	rm -f $(BIN_DIR)/$(FETCH_FILE)
	rm -f $(BIN_DIR)/$(TRACE_WIFI)
	rm -f $(BIN_DIR)/$(RUN_CONTROL)
	rm -f $(BIN_DIR)/$(RUN_LOGGER)
	rm -f $(BIN_DIR)/$(RUN_NODE)
	rm -f $(BIN_DIR)/$(KILL_REMOTE)
	rm -f $(BIN_DIR)/$(ANALYSE_SNR)

install:
	mkdir -p $(INSTALL_BIN_DIR)
	cp $(BIN_DIR)/$(CPUSAGE_SINGLE) $(INSTALL_BIN_DIR)/$(CPUSAGE_SINGLE)
	chmod 755 $(INSTALL_BIN_DIR)/$(CPUSAGE_SINGLE)
	cp $(BIN_DIR)/$(FETCH_FILE) $(INSTALL_BIN_DIR)/$(FETCH_FILE)
	chmod 755 $(INSTALL_BIN_DIR)/$(FETCH_FILE)
	cp $(BIN_DIR)/$(TRACE_WIFI) $(INSTALL_BIN_DIR)/$(TRACE_WIFI)
	chmod 755 $(INSTALL_BIN_DIR)/$(TRACE_WIFI)
	cp $(BIN_DIR)/$(RUN_CONTROL) $(INSTALL_BIN_DIR)/$(RUN_CONTROL)
	chmod 755 $(INSTALL_BIN_DIR)/$(RUN_CONTROL)
	cp $(BIN_DIR)/$(RUN_NODE) $(INSTALL_BIN_DIR)/$(RUN_NODE)
	chmod 755 $(INSTALL_BIN_DIR)/$(RUN_NODE)
	cp $(BIN_DIR)/$(RUN_LOGGER) $(INSTALL_BIN_DIR)/$(RUN_LOGGER)
	chmod 755 $(INSTALL_BIN_DIR)/$(RUN_LOGGER)
	cp $(BIN_DIR)/$(KILL_REMOTE) $(INSTALL_BIN_DIR)/$(KILL_REMOTE)
	chmod 755 $(INSTALL_BIN_DIR)/$(KILL_REMOTE)
	cp $(BIN_DIR)/$(ANALYSE_SNR) $(INSTALL_BIN_DIR)/$(ANALYSE_SNR)
	chmod 755 $(INSTALL_BIN_DIR)/$(ANALYSE_SNR)
	mkdir -p $(INSTALL_LUA_LIB_DIR)
	cp *.lua $(INSTALL_LUA_LIB_DIR)
	mkdir -p $(INSTALL_LUA_LIB_DIR)/parsers
	cp parsers/*.lua $(INSTALL_LUA_LIB_DIR)/parsers
