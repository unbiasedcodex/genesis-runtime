/* Genesis Geb Browser Linker Script */
/* Base address: 0x5000000 (native-base process) */
OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)

SECTIONS {
    . = 0x5000000;

    .text : {
        *(.text .text.*)
    }

    .rodata : {
        *(.rodata .rodata.*)
    }

    /* Align to page boundary for separate RW segment */
    . = ALIGN(0x1000);

    .data : {
        *(.data .data.*)
    }

    .bss : {
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        /* Reserve space for browser variables */
        . = . + 0x10000;  /* 64KB for browser data */
        __bss_end = .;
    }

    /DISCARD/ : {
        *(.comment)
        *(.note*)
        *(.eh_frame*)
    }
}
