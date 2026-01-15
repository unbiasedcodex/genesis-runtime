/* Genesis VFS Server Linker Script */
/* VFS Server loads at 0x900000 (after Init at 0x800000) */

OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
ENTRY(main)

SECTIONS
{
    . = 0x900000;

    .text : ALIGN(0x1000)
    {
        *(.text)
        *(.text.*)
    }

    .rodata : ALIGN(0x1000)
    {
        *(.rodata)
        *(.rodata.*)
    }

    .data : ALIGN(0x1000)
    {
        *(.data)
        *(.data.*)
    }

    .bss : ALIGN(0x1000)
    {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    }

    /DISCARD/ :
    {
        *(.comment)
        *(.note.*)
        *(.eh_frame)
        *(.eh_frame_hdr)
    }
}
