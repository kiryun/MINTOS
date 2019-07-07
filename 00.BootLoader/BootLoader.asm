[ORG 0x00]   ; Code start address : 0x00
[BITS 16]    ; 16-bit environment

SECTION.text  ; text section(Segment)

jmp 0x07C0:START    ; copy 0x0C70 to cs, and goto START

START:
    mov ax, 0x07C0 ; convert start address to 0x0C70
    mov ds, ax   ; set ds register
    mov ax, 0xB800 ; base video address
    mov es, ax   ; set es register(videos address)

.SCREENCLEARLOOP:
    mov byte [ es: si ], 0     ; delete character at si index
    mov byte [ es: si + 1], 0x0A  ; copy 0x)A(black / gree)
    add si, 2            ; go to next location
    cmp si, 80 * 25 *2       ; compare si and screen size
    jl .SCREENCLEARLOOP       ; end loop if si == screen size

    mov si, 0            ; initialize si register
    mov di, 0            ; initialize di register

.MESSAGELOOP:
    mov cl, byte [ si + MESSAGE1 ] ; copy charactor which is on the address MESSAGE1's addr + SI register's value
    cmp cl, 0            ; compare the charactor and 0
    je .MESSAGEEND         ; if value is 0 -> string index is out of bound -> finish the routine

    mov byte [ es : di], cl     ; if value is not 0 -> print the charactor on 0xB800 + di
    add si, 1            ; go to next index
    add di, 2            ; go to next video address

    jmp .MESSAGELOOP        ; loop code

.MESSAGEEND:
    jmp $              ; infinite loop

MESSAGE1:    db 'OS Boot Loader Start!!', 0 ; define the string tha I want to print

times 510 - ($ - $$)  db   0x00  ; $ : current line's address
                    ; $$ : current section's base address
                    ; $ - $$ : offset!
                    ; 510 - ($ - $$) : offset to addr 510
                    ; db - 0x00 : declare 1byte and init to 0x00
                    ; time : loop
                    ; fill 0x00 from current address to 510

db 0x55 ; declare 1byte and init to 0x55
db 0xAA ; declare 1byte and init to 0xAA
    ; Address 511 : 0x55
    ; 512 : 0xAA -> declare that this sector is boot sector
