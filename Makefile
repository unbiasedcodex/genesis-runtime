# Genesis Runtime Makefile
# Builds all userspace services: init, vfs, console, shell

# Tools
GLC = cargo run --manifest-path ../genesis-lang/Cargo.toml --bin glc --release --
LD = ld
OBJCOPY = objcopy
NASM = nasm

# Flags
GLCFLAGS = --freestanding --emit-obj
NASMFLAGS = -f elf64

# Output
BUILD_DIR = build

# Services
SERVICES = init vfs console shell

# Default target
all: $(SERVICES)

# Init system (loads at 0x800000, PID 1)
init: $(BUILD_DIR)/init.elf

$(BUILD_DIR)/init.elf: $(BUILD_DIR)/init.o $(BUILD_DIR)/init_start.o src/init/userspace.ld
	$(LD) -T src/init/userspace.ld -m elf_x86_64 --nostdlib -o $@ $(BUILD_DIR)/init_start.o $(BUILD_DIR)/init.o

$(BUILD_DIR)/init.o: src/init/main.gl src/init/runtime.gl | $(BUILD_DIR)
	$(GLC) build src/init/main.gl $(GLCFLAGS) -o $@

$(BUILD_DIR)/init_start.o: src/init/start.asm | $(BUILD_DIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# VFS Server (loads at 0x900000, PID 2)
vfs: $(BUILD_DIR)/vfs.elf

$(BUILD_DIR)/vfs.elf: $(BUILD_DIR)/vfs.o $(BUILD_DIR)/vfs_start.o src/fs/userspace.ld
	$(LD) -T src/fs/userspace.ld -m elf_x86_64 --nostdlib -o $@ $(BUILD_DIR)/vfs_start.o $(BUILD_DIR)/vfs.o

$(BUILD_DIR)/vfs.o: src/fs/main.gl src/fs/runtime.gl | $(BUILD_DIR)
	$(GLC) build src/fs/main.gl $(GLCFLAGS) -o $@

$(BUILD_DIR)/vfs_start.o: src/fs/start.asm | $(BUILD_DIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Console Server (loads at 0xA00000, PID 3)
console: $(BUILD_DIR)/console.elf

$(BUILD_DIR)/console.elf: $(BUILD_DIR)/console.o $(BUILD_DIR)/console_start.o src/console/userspace.ld
	$(LD) -T src/console/userspace.ld -m elf_x86_64 --nostdlib -o $@ $(BUILD_DIR)/console_start.o $(BUILD_DIR)/console.o

$(BUILD_DIR)/console.o: src/console/main.gl src/console/runtime.gl | $(BUILD_DIR)
	$(GLC) build src/console/main.gl $(GLCFLAGS) -o $@

$(BUILD_DIR)/console_start.o: src/console/start.asm | $(BUILD_DIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Shell (loads at 0xB00000, PID 4)
shell: $(BUILD_DIR)/shell.elf

$(BUILD_DIR)/shell.elf: $(BUILD_DIR)/shell.o $(BUILD_DIR)/shell_start.o src/shell/userspace.ld
	$(LD) -T src/shell/userspace.ld -m elf_x86_64 --nostdlib -o $@ $(BUILD_DIR)/shell_start.o $(BUILD_DIR)/shell.o

$(BUILD_DIR)/shell.o: src/shell/main.gl src/shell/commands.gl src/shell/runtime.gl | $(BUILD_DIR)
	$(GLC) build src/shell/main.gl $(GLCFLAGS) -o $@

$(BUILD_DIR)/shell_start.o: src/shell/start.asm | $(BUILD_DIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Clean
clean:
	rm -rf $(BUILD_DIR)

# Install to kernel ISO
install: all
	cp $(BUILD_DIR)/init.elf ../genesis-kernel/iso/boot/
	cp $(BUILD_DIR)/vfs.elf ../genesis-kernel/iso/boot/
	cp $(BUILD_DIR)/console.elf ../genesis-kernel/iso/boot/
	cp $(BUILD_DIR)/shell.elf ../genesis-kernel/iso/boot/

# Check tools
check:
	@$(GLC) --version > /dev/null || (echo "Error: glc not found" && exit 1)
	@echo "Tools OK"

.PHONY: all clean install check $(SERVICES)
