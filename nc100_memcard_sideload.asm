; # NC100 Program Card
; ###########################################################################
;  Using this feature allows code to be executed from a memory card.
;  Pressing Function-X will map the first 16K page of the card at C000-FFFF.
;  For this to work:
;	- Must have  "NC100PRG" at 0xc200
;	- 0xc210-0xc212 contains a long jump to 0xc220
; 	- Program name at 0xc13, max 12 characters, zero terminated.
;  If that is set, execution starts at 0xc210

include	"nc100/nc100_io.def"

;seek	0x0200								; Actual place in image where code is placed
;org	0xc200								; This is where we're pretending to be
;	db	"NC100PRG"
;seek	0x0210
org	0xc210
	jp	nc100_program_card_start
	db	"z80Mon SLoad",0
;seek	0x0220
org	0xc220
nc100_program_card_start:
	di								; Disable interrupts (or things will go very wrong!)

	; Set system RAM Bank 0 at address 00k
        ld      a, nc100_membank_RAM|nc100_membank_0k
        out     (nc100_io_membank_A), a                                 ; Select system RAM for lowest page

	; Copy CRAM to RAM
	ld	bc, monitor_image					; Source: Page 0 (CRAM)
	ld	de, 0x0000						; Destination: Page 0 (RAM)
	ld	hl, 0x3500						; Num. bytes: 16k-0x0500 (For this)
memory_copy:
	ld	a, (bc)							; Get byte to copy
	ld	(de), a							; Save byte
	inc	bc							; Increment pointers
	inc	de
	dec	hl							; Decrement byte count
	ld	a, l
	or	h							; See if we've reached zero
	jr	nz, memory_copy						; If there are remaining bytes to copy

	rst 	0							; Cold reset for monitor

monitor_image:
	incbin	"z80mon.hex"
