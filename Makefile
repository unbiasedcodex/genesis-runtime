# Genesis Runtime Makefile
# Phase 1: Init System

# Tools
GLC = cargo run --manifest-path ../genesis-lang/Cargo.toml --bin glc --release --
LD = ld
OBJCOPY = objcopy

# Flags
GLCFLAGS = --freestanding --emit-obj
LDFLAGS = -T linker.ld -m elf_x86_64 --nostdlib

# Output
BUILD_DIR = build

# Services
SERVICES = init

# Default target
all: $(SERVICES)

# Init system
init: $(BUILD_DIR)/init.elf

$(BUILD_DIR)/init.elf: $(BUILD_DIR)/init.o linker.ld
	$(LD) $(LDFLAGS) -o $@ $(BUILD_DIR)/init.o

$(BUILD_DIR)/init.o: src/init/main.gl src/init/runtime.gl | $(BUILD_DIR)
	$(GLC) build src/init/main.gl $(GLCFLAGS) -o $@

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Clean
clean:
	rm -rf $(BUILD_DIR)

# Install to kernel ISO
install: all
	@if [ -z "$(DESTDIR)" ]; then echo "Usage: make install DESTDIR=/path/to/iso"; exit 1; fi
	mkdir -p $(DESTDIR)/boot
	cp $(BUILD_DIR)/init.elf $(DESTDIR)/boot/

# Tests
test: $(BUILD_DIR)/test_init.elf
	@echo "Tests built: $(BUILD_DIR)/test_init.elf"
	@echo "Run with QEMU to execute tests"

$(BUILD_DIR)/test_init.elf: $(BUILD_DIR)/test_init.o linker.ld
	$(LD) $(LDFLAGS) -o $@ $(BUILD_DIR)/test_init.o

$(BUILD_DIR)/test_init.o: tests/test_init.gl tests/runtime.gl | $(BUILD_DIR)
	$(GLC) build tests/test_init.gl $(GLCFLAGS) -o $@

# Check tools
check:
	@$(GLC) --version > /dev/null || (echo "Error: glc not found" && exit 1)
	@echo "Tools OK"

.PHONY: all clean install test check $(SERVICES)
