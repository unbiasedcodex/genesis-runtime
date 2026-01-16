# Genesis Runtime Makefile
# Phase 1: Init System + VFS Server

# Tools
GLC = cargo run --manifest-path ../genesis-lang/Cargo.toml --bin glc --release --
LD = ld
OBJCOPY = objcopy

# Flags
GLCFLAGS = --freestanding --emit-obj

# Output
BUILD_DIR = build

# Services
SERVICES = init vfs

# Default target
all: $(SERVICES)

# Init system (loads at 0x800000)
init: $(BUILD_DIR)/init.elf

$(BUILD_DIR)/init.elf: $(BUILD_DIR)/init.o $(BUILD_DIR)/start.o src/init/userspace.ld
	$(LD) -T src/init/userspace.ld -m elf_x86_64 --nostdlib -o $@ $(BUILD_DIR)/start.o $(BUILD_DIR)/init.o

$(BUILD_DIR)/init.o: src/init/main.gl src/init/runtime.gl | $(BUILD_DIR)
	$(GLC) build src/init/main.gl $(GLCFLAGS) -o $@

$(BUILD_DIR)/start.o: src/init/start.asm | $(BUILD_DIR)
	nasm -f elf64 -o $@ $<

# VFS Server (loads at 0x900000)
vfs: $(BUILD_DIR)/vfs.elf

$(BUILD_DIR)/vfs.elf: $(BUILD_DIR)/vfs.o src/fs/linker.ld
	$(LD) -T src/fs/linker.ld -m elf_x86_64 --nostdlib -o $@ $(BUILD_DIR)/vfs.o

$(BUILD_DIR)/vfs.o: src/fs/main.gl src/fs/runtime.gl | $(BUILD_DIR)
	$(GLC) build src/fs/main.gl $(GLCFLAGS) -o $@

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
	cp $(BUILD_DIR)/vfs.elf $(DESTDIR)/boot/

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
