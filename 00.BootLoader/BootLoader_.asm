[ORG 0x00]	; Code start address : 0x00
[BITS 16]	; 16-bit environment

SECTION.text	; text section(Segment)

jmp 0x07C0:START		; copy 0x07C0 to cs, and goto START

TOTALSECTORCOUNT:	dw	1024

START:
	mov ax, 0x07C0 	; convert start address to 0x07C0
	mov ds, ax	; set ds register
	mov ax, 0xB800	; base video address
	mov es, ax	; set es register(video address)

	;STACK Generate code (0x0000:0000~ 0x0000:FFFF, 64KB)
	mov ax, 0x0000	; 
	mov ss, ax	;
	mov sp, 0xFFFE	;
	mov bp,	0xFFFE	;

	;SI Reg(string index) initialize
	mov si, 0

.SCREENCLEARLOOP:
	mov byte [ es: si ], 0		; delete character at si index
	mov byte [ es: si + 1 ], 0x0A 	; copy 0x0A(black / green)
	add si, 2			; go to next location
	cmp si, 80 * 25 * 2		; compare si and screen size	
	jl .SCREENCLEARLOOP		; end loop if si == screen size

	push MESSAGE1			; push message's address
	push 0				; Y val
	push 0				; X val
	call PRINTMESSAGE		; call function
	add sp,	6			; cdecl convention
	
	push IMAGELOADINGMESSAGE	; push image loading message's address
	push 1				; Y val(1)
	push 0				; X val(0)
	call PRINTMESSAGE		; call function
	add sp, 6			; cdecl convention

RESETDISK:
	;BIOS Reset Function : service number 0, drive number 0 (Floppy)
	mov ax, 0
	mov dl, 0
	int 0x13
	jc HANDLEDISKERROR

	;Read Sector from disk
	mov si, 0x1000	;set si : 0x1000, bx : 0x0000 -> 0x1000:0000
	mov es, si
	mov bx, 0x0000

	mov di, word [ TOTALSECTORCOUNT ]

READDATA:
	cmp di, 0			; check remaining sectors
	je READEND			; jump if di == 0 (ZF is set)
	sub di, 0x1			; di-- (if sectors remain)
	
	; Call BIOS Read Function
	mov ah, 0x02			; Service Number : 0x02(Read Sector)
	mov al, 0x1			; Read 1 Sector 
	mov ch, byte [ TRACKNUMBER ]	; set Track Number
	mov cl, byte [ SECTORNUMBER ]	; set Sector Number
	mov dh, byte [ HEADNUMBER ]	; set Head Number
	mov dl, 0x00			; set Drive Number(Floppy)
	int 0x13			; interrupt
	jc HANDLEDISKERROR		; Error Handling (if CF == 1)

	; Calculate copy, track, head, sector address
	add si, 0x0020			; convert 512 byte to seg reg
	mov es, si			; increase address amount of 1 sector
	
	mov al, byte [ SECTORNUMBER ]	; SECTORNUMBER++
	add al, 0x01			; 
	mov byte [ SECTORNUMBER ], al	; 
	
	cmp al, 19			; if (SECTORNUMBER <= 18)
	jl READDATA			; Sign flag is opposite with Overflow Flag

	xor byte [ HEADNUMBER ], 0x01	; toggle head number
	mov byte [ SECTORNUMBER ], 0x01	; set Sector number to 0x01
	cmp byte [ HEADNUMBER ], 0x00	; cmp 0x00 & head number
	jne READDATA			; head num != 0 -> loop

	add byte [ TRACKNUMBER ], 0x01	; increase track number 1
	jmp READDATA			; loop

READEND:
	push LOADINGCOMPLETEMESSAGE	; loading complete!
	push 1				; Y location
	push 20				; X location
	call PRINTMESSAGE		
	add sp, 6			; cdecl convention
	
	; execute os image
	jmp 0x1000:0000			

HANDLEDISKERROR:
	push DISKERRORMESSAGE		
	push 1
	push 20	
	call PRINTMESSAGE		
	
	jmp $

PRINTMESSAGE:
	push bp
	mov bp, sp			; stack frame
	
	push es
	push si
	push di
	push ax
	push cx
	push dx
	
	mov ax, 0xB800			; video memory start addr
	mov es, ax			; set es 
	
	; get line addr
	mov ax, word [ bp + 6 ]		; set ax with y location
	mov si, 160			; set si with the size of the line (160b)
	mul si				; y location * line size (save on ax)
	mov di, ax			; set y address on di

	; get video memory address
	mov ax, word [ bp + 4 ]		
	mov si, 2
	mul si
	add di, ax			; y location + x location
	
	mov si, word [ bp + 8 ]		; string address (param 03)
	
.MESSAGELOOP:
	mov cl, byte [ si ]	; copy character which is on the adress MESSAGE1's addr + SI register's value
	cmp cl, 0			; compare the character and 0 
	je .MESSAGEEND			; if value is 0 -> string index is out of bound -> finish the routine

	mov byte [ es : di ], cl	; if value is not 0 -> print the character on 0xB800 + di
	add si, 1			; go to next index
	add di, 2			; go to next video address
	
	jmp .MESSAGELOOP		; loop code

.MESSAGEEND:
	pop dx
	pop cx
	pop ax
	pop di
	pop si
	pop es
	pop bp
	ret

MESSAGE1:	db 'MINT64 OS Boot Loader Start~!!', 0 ;define the string that I want to print

DISKERRORMESSAGE:	db	'DISK Error~!!', 0
IMAGELOADINGMESSAGE:	db	'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE:	db	'Complete~!!', 0

SECTORNUMBER:		db	0x02
HEADNUMBER:		db	0x00
TRACKNUMBER:		db	0x00

times 510 - ($ - $$)	db	0x00	; $ : current line's addr, $$ : current section's base address -> $ - $$ : Offset!
					; 510 - ( $ - $$ ) : offset to addr 510, db - 0x00 : declare 1byte and init to 0x00
					; time : loop -> fill 0x00 from current address to 510

db 0x55	; declare 1 byte and init to 0x55
db 0xAA	; declare 1 byte and init to 0xAA
	; Address 511 : 0x55, 512 : 0xAA -> declare that this sector is boot sector
