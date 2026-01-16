; Genesis Init System Start Stub
; Defines _start entry point that jumps to main

section .text
global _start
extern main

_start:
    ; main expects no arguments in Genesis
    call main
    ; If main returns, just loop forever
.halt:
    jmp .halt
