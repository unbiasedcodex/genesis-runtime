/* Genesis Shell Server Linker Script */
/* Base address: 0xB00000 (PID 4) */
OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)

SECTIONS {
    . = 0xB00000;

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
        /* Reserve space for shell variables */
        . = . + 0x2000;  /* 8KB for shell data */
        __bss_end = .;
    }

    /DISCARD/ : {
        *(.comment)
        *(.note*)
        *(.eh_frame*)
    }
}
