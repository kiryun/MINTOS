[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x1000:START	; copy 0x1000 to CS, and goto START label

SECTORCOUNT:		dw	0x0000
TOTALSECTORCOUNT:	equ	1024

START:
	; Register initialize
	mov ax, cs
	mov ds, ax
	mov ax, 0xB800

	mov es, ax

	; Code generate on each sector
	%assign	i	0
	%rep	TOTALSECTORCOUNT
		%assign i	i+1
		
		; convert sector's location to coordinates
		mov ax, 2
		mul word [ SECTORCOUNT ]
		mov si, ax
		
		; set result to video memory's offset and print 0 on 3rd line
		mov byte [ es: si + (160 * 2) ], '0' + (i % 10)
		add word [ SECTORCOUNT ], 1	
		
		; if (last sector) -> jmp $ || else go to next sector
		%if i == TOTALSECTORCOUNT
			jmp $
		%else
			jmp (0x1000 + i * 0x20): 0x0000
		%endif

		times ( 512 - ($ - $$) % 512 )	db 0x00
	%endrep
