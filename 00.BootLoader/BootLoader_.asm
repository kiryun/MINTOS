[ORG 0x00]	; Code start address : 0x00
[BITS 16]	; 16-bit environment

SECTION.text	; text section(Segment)

jmp 0x07C0:START	; copy 0x0C70 to cs, and goto START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	environment seting value for os
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TOTALSECTORCOUNT:	dw 1025	; os image size without bootloader
				; max 1152 sector(0x90000byte)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; code domain
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


START:
	mov ax, 0x07C0	; convert start address to 0x0C70
	mov ds, ax	; set ds register
	mov ax, 0xB800	; base video address
	mov es, ax	; set es register(videos address)

	; create stack domain 0x0000:0000 ~ 0x0000:FFFF (64kb size)
	mov ax, 0x000	; convert stack start address to segment register value
	mov ss, ax	; set ss register
	mov sp, 0xFFFE	; set sp register address (0xFFFE)
	mov bp, 0xFFFE	; set bp register address (sp)

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; clear display, set value = green
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov si, 0	; initialize si register

.SCREENCLEARLOOP:
	mov byte [ es: si ], 0		; delete character at si index
	mov byte [ es: si + 1], 0x0A	; copy 0x)A(black / gree)
	add si, 2			; go to next location
	cmp si, 80 * 25 *2		; compare si and screen size
	jl .SCREENCLEARLOOP		; end loop if si == screen size
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; print start message at top display
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push MESSAGE1		; printing message addr push in stack
	push 1			; display Y location(1) push in stack
	push 0			; display X location(0) push in stack
	call RPINTMESSAGE	; call PRINTMESSAGE function
	add sp, 6		; remove parameter
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; loading os image in disk
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; reset before read disk
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESETDISK:			; start disk reset code
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; call BIOS reset function
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; service number 0, drive number(0=Floppy)
	mov ax, 0
	mov dl, -
	int 0x13
	; error handle
	jc HANDLEDISKERROR
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; read sector in disk
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; set the addr to copy the contents of the disk to memory as 0x10000
	mov si, 0x1000	; convert copy the contents of the disk (0x10000) to segement register
	mov es, si	; set es segement register
	mov bx, 0x0000	; set bx register
			; address to copy = 0x1000:0000(0x10000)
	
	mov di, word[TOTALSECTORCOUNT]	; set di register number of address to copy sector

READDAT:
	; check all of sector read
	cmp di, 0	; compare to number of os image sector and 0
	je READEND	; if number of copy to sector == 0 then READEND(read complete)
	sub di, 0x1	; copty to sector --
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; call BIOS read function
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ah, 0x02			; BIOS service number 2(Read sector)
	mov al, 0x1			; number of sectors to read = 1
	mov ch, byte [TRACKNUMBER]	; set track number
	mov cl, byte [SECTORNUMBER]	; set sector number
	mov dh, byte [HEADNUMBER]	; set head number
	mov dl, 0x00			; set drive number(0 = Floppy)
	int 0x13			; call interrupt service
	jc HANDLEDISKERROR		; error -> HANDLEDISKERROR
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 
	
		


	mov si, 0			; initialize si register
	mov di, 0			; initialize di register

.MESSAGELOOP:
	mov cl, byte [ si + MESSAGE1 ]	; copy charactor which is on the address MESSAGE1's addr + SI register's value
	cmp cl, 0			; compare the charactor and 0
	je .MESSAGEEND			; if value is 0 -> string index is out of bound -> finish the routine

	mov byte [ es : di], cl		; if value is not 0 -> print the charactor on 0xB800 + di
	add si, 1			; go to next index
	add di, 2			; go to next video address

	jmp .MESSAGELOOP		; loop code

.MESSAGEEND:
	jmp $				; infinite loop

MESSAGE1:	db 'OS Boot Loader Start!!', 0	; define the string tha I want to print

times 510 - ($ - $$)	db	0x00	; $ : current line's address
					; $$ : current section's base address
					; $ - $$ : offset!
					; 510 - ($ - $$) : offset to addr 510
					; db - 0x00 : declare 1byte and init to 0x00
					; time : loop
					; fill 0x00 from current address to 510

db 0x55	; declare 1byte and init to 0x55
db 0xAA	; declare 1byte and init to 0xAA
	; Address 511 : 0x55
	; 512 : 0xAA -> declare that this sector is boot sector
