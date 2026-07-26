; Genesis Geb Browser Start Stub
; Defines _start entry point that jumps to main
; Also provides a simple bump allocator (malloc/free) for
; compiler-generated struct allocations

bits 64

; Mark stack as non-executable
section .note.GNU-stack noalloc noexec nowrite progbits

section .data

; Heap pointer (simple bump allocator)
align 8
heap_ptr: dq 0x5800000      ; Start of browser heap

; Heap limits
HEAP_BASE equ 0x5800000
HEAP_END  equ 0x5F00000     ; 7MB heap (stack region starts here)

section .text
global _start
extern main

_start:
    ; Use private stack region (0x5F00000 - 0x6000000)
    mov rsp, 0x5FFFFF0
    ; main expects no arguments in Genesis
    call main
    ; If main returns, just loop forever
.halt:
    jmp .halt

; malloc(size) -> ptr
; Input: rdi = size in bytes
; Output: rax = pointer to allocated memory, or 0 if out of memory
global malloc
malloc:
    push rbx

    ; Load current heap pointer
    mov rax, [rel heap_ptr]

    ; Align to 8 bytes: (ptr + 7) & ~7
    add rax, 7
    and rax, ~7

    ; Calculate new pointer
    mov rbx, rax
    add rbx, rdi            ; new_ptr = aligned + size

    ; Check bounds
    cmp rbx, HEAP_END
    ja .out_of_memory

    ; Store new heap pointer
    mov [rel heap_ptr], rbx

    ; Return aligned pointer
    pop rbx
    ret

.out_of_memory:
    xor eax, eax            ; Return NULL
    pop rbx
    ret

; free(ptr)
; Input: rdi = pointer to free
; No-op for bump allocator
global free
free:
    ret
