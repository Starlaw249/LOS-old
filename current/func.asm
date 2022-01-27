BITS 32

GLOBAL	io_hlt, io_cli, io_sti, io_stihlt
GLOBAL	io_in8,  io_in16,  io_in32
GLOBAL	io_out8, io_out16, io_out32
GLOBAL	io_load_eflags, io_store_eflags
GLOBAL  write_mem8

section .text

io_hlt:	; void io_hlt(void);
    HLT
    RET

io_cli:	; void io_cli(void);
    CLI
    RET

io_sti:	; void io_sti(void);
    STI
    RET

io_stihlt:	; void io_stihlt(void);
    STI
    HLT
    RET

io_in8:	; int io_in8(int port);
    MOV		EDX,[ESP+4]		; port
    MOV		EAX,0
    IN		AL,DX
    RET

io_in16:	; int io_in16(int port);
    MOV		EDX,[ESP+4]		; port
    MOV		EAX,0
    IN		AX,DX
    RET

io_in32:	; int io_in32(int port);
    MOV		EDX,[ESP+4]		; port
    IN		EAX,DX
    RET

io_out8:	; void io_out8(int port, int data);
    MOV		EDX,[ESP+4]		; port
    MOV		AL,[ESP+8]		; data
    OUT		DX,AL
    RET

io_out16:	; void io_out16(int port, int data);
    MOV		EDX,[ESP+4]		; port
    MOV		EAX,[ESP+8]		; data
    OUT		DX,AX
    RET

io_out32:	; void io_out32(int port, int data);
    MOV		EDX,[ESP+4]		; port
    MOV		EAX,[ESP+8]		; data
    OUT		DX,EAX
    RET

io_load_eflags:	; int io_load_eflags(void);
    PUSHFD		; PUSH EFLAGS  "MOV EAX EFLAGS" is not allowed 
    POP		EAX
    RET

io_store_eflags:	; void io_store_eflags(int eflags);
    MOV		EAX,[ESP+4]
    PUSH	EAX
    POPFD		; POP EFLAGS 
    RET

write_mem8:             ; void write_mem8(int addr, int data)
    MOV ECX, [ESP + 4]  ; [ESP+4] stores the first parameter "addr"
    MOV AL, [ESP + 8]   ; [ESP+8] stores the second parameter "data"
    MOV [ECX], AL       ; move data to memory address ECX
    RET



msg:
	db "C++ calls assembly function success!!", 0

global assemblyprint 			; declare a function name called "hlt"
assemblyprint:
	mov esi,msg
	mov ebx,0xb8000
	add ebx, 80*2*2		; 80 chars is one line, one char is 2 bytes. spare two lines
.loop2:
	lodsb
	or al,al
	jz fin2
	or eax,0x0F00
	mov word [ebx], ax
	add ebx,2
	jmp .loop2

global fin2
fin2:
	cli
	hlt