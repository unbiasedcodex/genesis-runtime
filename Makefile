# Genesis Runtime Makefile
# Phase 1: Init System

# Tools
GLC = glc
LD = ld
NASM = nasm

# Flags
GLCFLAGS = --freestanding --emit-obj
NASMFLAGS = -f elf64
LDFLAGS = -m elf_x86_64 --nostdlib

# Output
BUILD_DIR = build

# Services
SERVICES = init

# Default target
all: $(SERVICES)

# Init system
init: $(BUILD_DIR)/init.elf

$(BUILD_DIR)/init.elf: src/init/main.gl | $(BUILD_DIR)
	$(GLC) build $< $(GLCFLAGS) -o $(BUILD_DIR)/init.o
	$(LD) $(LDFLAGS) -o $@ $(BUILD_DIR)/init.o

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Clean
clean:
	rm -rf $(BUILD_DIR)

# Install to kernel ISO
install: all
	@if [ -z "$(DESTDIR)" ]; then echo "Usage: make install DESTDIR=/path/to/iso"; exit 1; fi
	mkdir -p $(DESTDIR)/boot/runtime
	cp $(BUILD_DIR)/*.elf $(DESTDIR)/boot/runtime/

# Run tests
test:
	@echo "Tests not yet implemented"

# Check tools
check:
	@which $(GLC) > /dev/null || (echo "Error: glc not found" && exit 1)
	@echo "Tools OK"

.PHONY: all clean install test check $(SERVICES)
