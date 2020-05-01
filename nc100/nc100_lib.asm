include	"nc100/nc100_io.def"

; # Defines
; ###########################################################################
nc100_lib_base:				equ	mem_base+0x1000		; nc100_lib offset
nc100_cmd_base:				equ	nc100_lib_base+0x1000	; nc100_lib commands offset

; # Library variable storage
; ###########################################################################
orgmem	mon_base-0x20
nc100_raster_start_addr:		dw	0x0000			; Address of LCD raster memory
; Possibly move these into the raster memory
; Last 4 bytes of each line are not used
nc100_raster_cursor_addr:		dw	0x0000			; Cursor position in raster memory
; These are words to allow loading directly into double registers
nc100_lcd_pos_xy:			dw	0x0000			; LCD x/y cursor position (X: 0-59/Y: 0-63)
nc100_lcd_pixel_offset:			db	0x00			; LCD pixel position in data byte
nc100_lcd_draw_attributes:		db	0x00			; Cursor draw attributes
									; 0 - 0 = Normal, 1 = Invert
									; 1 - 0 = Copy over, 1 = Merge
									; 7 - 0 = LF resets to (0,0), 1 = Scrolls screen

nc100_keyboard_raw_keycode_prev:	db	0x00			; Previous raw keycode returned from interrupt handler
nc100_keyboard_raw_keycode:		db	0x00			; Raw keycode returned from interrupt handler (Possibly amalgam of characters)
nc100_keyboard_raw_control_prev:	db	0x00			; Previous raw control keys from interrupt handler
nc100_keyboard_raw_control:		db	0x00			; Raw control keys from interrupt handler
nc100_keyboard_controller_state:	db	0x00			; Persistent information (capslock, etc)
nc100_keyboard_raw_character_count:	db	0x00			; Number of character (not control!) keys depressed

orgmem	nc100_lib_base
; # Font data
; ###########################################################################
nc100_font_6x8:
	include	'fonts/font_6x8.asm'
nc100_font_8x8:
	include	'fonts/font_8x8.asm'

; # Table data
; ###########################################################################
; x64 multiplication table
include	"math/multiplication_64.def"

; # Hardware routines
; ###########################################################################
; Basic LCD routines
include	"nc100/lcd_basic.asm"

; Provides LCD 6x8 font
;include	"nc100/lcd_font_6x8.asm"

; Provides LCD 8x8 font
include "nc100/lcd_font_8x8.asm"

; Keyboard routines
include	"nc100/keyboard.asm"

; Interrupt routines
include	"nc100/interrupts.asm"

; # Console routines
; ###########################################################################
; # nc100_console_linefeed
; #################################
nc100_console_linefeed:
	jp	nc100_lcd_print_lf_8x8

; # nc100_console_carriage_return
; #################################
nc100_console_carriage_return:
	jp	nc100_lcd_print_cr_8x8

; # nc100_console_char_out
; #################################
;  Copy character to selected output device
;	In:	A = ASCII character
nc100_console_char_out:
	exx								; Swap out registers
	ld	de, (nc100_lcd_pos_xy)					; Load cursor X/Y position
nc100_console_char_out_check_lf:
	cp	character_code_linefeed					; Check for LF (line feed)
	jr	nz, nc100_console_char_out_check_cr
	call	nc100_console_linefeed
	jr	nc100_console_char_out_exit
nc100_console_char_out_check_cr:
	cp	character_code_carriage_return				; Check for CR (carriage return)
	jr	nz, nc100_console_char_out_print_glyph
	call	nc100_console_carriage_return
	jr	nc100_console_char_out_exit
nc100_console_char_out_print_glyph:
	call	nc100_lcd_print_glyph_8x8
nc100_console_char_out_exit:
	exx								; Swap back registers
	ret

; # nc100_console_char_in
; #################################
;  Returns a character from the keyboard if one is depressed
;	Out:    A = ASCII character code
;	Carry flag set if character valid
nc100_console_char_in:
	exx
nc100_console_char_in_loop:
	call	nc100_keyboard_char_in
	jr	nc, nc100_console_char_in_loop
	exx
	ret

; # Interrupt handlers
; ###########################################################################

; # interrupt_handler
; #################################
;  Maskable interrupt handler
interrupt_handler:
	di								; Disable interrupts
	push	af							; Save registers
	push	bc
	push	de
	push	hl
	push	ix
	push	iy

	ld	a, nc100_irq_key_scan					; Is this a keyboard interrupt
	call	interrupt_source_check
	call	z, interrupt_handler_keyboard

	pop	iy							; Restore registers
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
	ei								; Enable interrupts
	reti

; # nm_interrupt_handler
; #################################
;  Non-maskable interrupt handler
nm_interrupt_handler:
	retn

; # Commands
; ###########################################################################

; ###########################################################################
; #                                                                         #
; #                              System init                                #
; #                                                                         #
; ###########################################################################

orgmem	nc100_cmd_base
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	249,',',0,0						; id (249=init)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"System init",0

orgmem	nc100_cmd_base+0x40						; executable code begins here
system_init:
	; Reset interrupts
	xor	a							; Clear A
	out	(nc100_io_irq_mask), a					; Clear interrupt mask
	out	(nc100_io_irq_status), a				; Clear interrupt status flags

	; Configure RAM/ROM
	ld	a, nc100_membank_RAM|nc100_membank_48k
	out	(nc100_io_membank_D), a					; Select RAM for next page
	ld	a, nc100_membank_RAM|nc100_membank_32k
	out	(nc100_io_membank_C), a					; Select RAM for next page

	; We've got RAM now so set stack pointer (Yay!)
	; Set below screen RAM
	ld	sp, 0xf000						; So first object wil be pushed to 0xEFFF

	; Copy ROM to RAM
	ld	a, nc100_membank_RAM|nc100_membank_16k
	out	(nc100_io_membank_B), a					; Select RAM for next page
	ld	bc, 0x0000						; Source: Page 0 (ROM)
	ld	de, 0x4000						; Destination: Page 1 (RAM)
	ld	hl, 0x4000						; Num. bytes: 16k
	call	memory_copy

	; RAM pages 0 & 1 are swapped.
	; That way we can swap them back when something else is loaded
	ld	a, nc100_membank_RAM|nc100_membank_0k
	out	(nc100_io_membank_B), a					; Select RAM for next page
	ld	a, nc100_membank_RAM|nc100_membank_16k
	out	(nc100_io_membank_A), a					; Select RAM for lowest page

	; Setup screen
	ld	hl, 0xf000						; Set screen at RAM top, above stack
	call	nc100_lcd_set_raster_addr

	xor	a							; Clear attributes
	set	0, a							; Set inverted attributes
	;set	1, a							; Overwrite
	set	7, a							; Scroll screen
	call	nc100_lcd_set_attributes
	call	nc100_lcd_clear_screen					; Clear screen memory

	; Replace dummy console routines
	ld	bc, nc100_console_char_out
	ld	(monlib_console_out+1), bc
	ld	bc, nc100_console_char_in
	ld	(monlib_console_in+1), bc

	; Add interrupt handlers
	ld	a, 0xc3							; JP instruction
	ld	bc, interrupt_handler
	ld	(z80_interrupt_handler), a				; Write JP instruction
	ld	(z80_interrupt_handler+1), bc				; Write address of interrupt handler
	ld	bc, nm_interrupt_handler
	ld	(z80_nm_interrupt_handler), a				; Write JP instruction
	ld	(z80_nm_interrupt_handler+1), bc			; Write address of non-maskable interrupt handler

	ld	a, nc100_irq_key_scan					; Enable keyboard interrupts
	call	interrupt_set_mask_enabled
	ei								; Enable interrupts

	; Configure z80Mon variables
	ld	bc, 0x4000
	ld	(z80mon_current_addr), bc				; Set monitor's current address: 0x4000

	rst	8							; Continue boot


; ###########################################################################
; #                                                                         #
; #                            Startup Command                              #
; #                                                                         #
; ###########################################################################

orgmem	nc100_cmd_base+0x0100
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	253,',',0,0						; id (249=init)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"Startup Command",0

orgmem	nc100_cmd_base+0x0140						; executable code begins here
startup_cmd:
	rst	16							; Continue boot

; ###########################################################################
; #                                                                         #
; #                             System Config                               #
; #                                                                         #
; ###########################################################################

orgmem  nc100_cmd_base+0x0500
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	254,'!',0,0						; id (254=cmd)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"System config",0

orgmem  nc100_cmd_base+0x0540
setup_cmd:
