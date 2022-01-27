; Today, we continue Day 7's code and enable text printing. 
;
; Since we need more space for font data, 6 sectors of disk space is not enough. 
; In the startup program, we load 20 sectors instead of 6 sectors.
;
; Text printing in GUI is equivalent to drawing the font on the screen. We load the binary representation of 
; 8x16 pixel size fonts for ASCII code in "font8x16.hpp".
;
; Give credits to 
; http://3zanders.co.uk/2017/10/18/writing-a-bootloader3/   for the framework
; https://wiki.osdev.org/GDT_Tutorial 	for the explanation of GDT
; Comments mainly added by Yu Wang
; -------------------------------------------------------------------

section .boot 	; Marking this to be .boot section. Will be checked by linker script
bits 16
global boot
;org 0x7c00 ; this is realized in the "linker.ld" with code ". = 0x7c00;"

; some constants will be loaded in struct BOOTINFO in C code.
CYLS	EQU		0x0ff0			; BOOTINFO address
LEDS	EQU		0x0ff1			; 
VMODE	EQU		0x0ff2			; color info
SCRNX	EQU		0x0ff4			; screen x 
SCRNY	EQU		0x0ff6			; screen y
VRAM	EQU		0x0ff8			; vram initial address

boot:
	; enable A20 bit (I think both methods work)
	; mov ax, 0x2401
	; int 0x15
	in al, 0x92		; read port 0x92 to AL
	or al, 0x02		; set bit 1 to 1
	out 0x92, al	; set port 0x92, which is to enable A20

	; set vga to be graphic mode 
	; enter mode $(AL). details in https://cs.lmu.edu/~ray/notes/pcvideomodes/
	mov ax, 0x0013	; 320x200x8bit G
	int 0x10
	; store these parameters into memory 
	mov BYTE [VMODE],8	; 
	mov	WORD [SCRNX],320
	mov	WORD [SCRNY],200
	mov	DWORD [VRAM],0x000a0000


	; get keyboard LED
	mov	AH,0x02
	int	0x16 			; keyboard BIOS
	mov	[LEDS],AL		; store keyboard LED info to memroy

	mov [disk], dl  ; store disk id to [disk] from DL. When bootup, BIOS sets disk id to DL implicitly. 

	mov ah, 0x2     ; AH=0x02: read sectors. More can be found https://en.wikipedia.org/wiki/INT_13H
	mov al, 20      ; Since we need more disk for bootsector, data, C++, we need more space. Here we load 20 sectors
	mov ch, 0       ; cylinder idx
	mov dh, 0       ; head idx
	mov cl, 2       ; sector idx
	mov dl, [disk]  ; disk idx
	mov bx, copy_target ;target code pointer
	int 0x13        		; Call BIOS interrupt to operate disk 
	
	cli 					; Clear interrupt flag; Interruptions in Protected mode hasn't fully setup so far
	lgdt [gdt_pointer] 		; Load Global/Interrupt Descriptor Table defined below to GDBR(Register) 
	mov eax, cr0 			; CR0 has various control flags that modify the basic operation of the processor
	or eax,0x1 				; EAX |= 0x01 set the protected mode bit on special CPU reg cr0
	mov cr0, eax			;
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	jmp CODE_SEG:boot2

gdt_start:
gdt_null: ; the GDT starts with a null 8-byte
	dq 0x0000000000000000	; 8 bytes zeros

; GDT for code segment. base = 0x00000000, length = 0xfffff
gdt_code:					; a 8-byte data describing code seg
	dw 0xFFFF 				; segment length, bits 0-15
	dw 0x0000				; segment base, bits 0-15
	db 0x00  				; segment base, bits 16-23
	
	; flags (8 bits): 
	; P(1bit) 		1
	; DPL(2bits) 	 00
	; 1(1bit)		   1
	; TYPE(4bits)			
	; 					1			1: code segment 			0: data segment
	;					 0			1: consistant code, 		0: inconsistant code
	; 					  1 		1: readable & executable 	0: unreadable & executable
	; 					   0		1: Has been accessed 		0: hasn't been accessed (should be)
	db 10011010b

	; flags (4 bits) + segment length (4bits)
	; G(1bit) 		1				granularity: 1: 4KB. 0: 1Byte. The whole memory is length * granularity
	; D(1bit)		 1 				1: 32bit addr + 32/16bit operant
	; L(1bit) 		  0				reserved for 64 bit processor. Set to 0
	; AVL=0(1bit) 	   0 			used by operating system rather than processor 
	; Segment length 	1111		segment length cont. 16-19 bit
	db 11001111b 			

	db 0x00 				; segment base, bits 24-31

; GDT for data segment. base and length identical to code segment
gdt_data:
	dw 0xFFFF 				; segment length, bits 0-15
	dw 0x0000				; segment base, bits 0-15
	db 0x00  				; segment base, bits 16-23

	; flags (8 bits): 
	; P(1bit) 		1
	; DPL(2bits) 	 00
	; 1(1bit)		   1
	; TYPE(4bits)			
	; 					0			1: code segment 					0: data segment
	;					 0			1: extend above(Limit to 0xFFFF) 	0: extend below(0 to Limit) usually a stack
	; 					  1 		1: writable 						0: unwritable
	; 					   0		1: Has been accessed 				0: hasn't been accessed (should be)
	db 10010010b 
	
	; flags (4 bits) + segment length (4bits)
	; G(1bit) 		1				granularity: 1: 4KB. 0: 1Byte. The whole memory is length * granularity
	; B(1bit)		 1 				1: use ESP (max 0xFFFF_FFFF)	0: use SP (max 0xFFFF)
	; L(1bit) 		  0				reserved for 64 bit processor. Set to 0
	; AVL=0(1bit) 	   0 			used by operating system rather than processor 
	; Segment length 	1111		segment length cont. 16-19 bit
	db 11001111b
	db 0x00
gdt_end:

; GDT descripto
gdt_pointer:
	dw gdt_end - gdt_start-1 ; some instructions say there must be a "-1" here, but the original code doesn't
	dd gdt_start

disk:
	db 0x0

; define some constants for later use
CODE_SEG equ gdt_code - gdt_start 	
DATA_SEG equ gdt_data - gdt_start

times 510 - ($-$$) db 0
dw 0xaa55

; Compare to previous two days code, the following code are in the second 512-byte sector.
copy_target:
bits 32

hello: db "Hello more than 512 bytes world!!", 0

; The following are the assembly code to print
boot2:
	mov esi,hello
	mov ebx,0xb8000
.loop:
	lodsb
	or al,al
	jz cppcode
	or eax,0x0F00
	mov word [ebx], ax
	add ebx,2
	jmp .loop

; The following is to call C++
section .text
cppcode:
	mov esp, kernel_stack_top
	extern main
	call main			; the actual name in c++ obj file. "main" is a special function name

global fin
fin:
	cli
	hlt


	
	

section .bss 	; Mark the following to be .bss section. Will be checked by linker script
align 4 		; aligns the current location to a specified boundary by padding 0.
kernel_stack_bottom: equ $
	resb 64 * 1024 ; reserve 64 KB for kernel stack from current place (marked by $)
kernel_stack_top: