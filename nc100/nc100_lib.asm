include	"nc100/nc100_lib.def"

; # Library variable storage
; ###########################################################################
; Interrupt space 0x0018-0x0037 free (32 bytes)
orgmem  mem_base+0x18

; # LCD variables
; #################################
nc100_raster_start_addr:		dw	0x0000			; Address of LCD raster memory
nc100_raster_cursor_addr:		dw	0x0000			; Cursor position in raster memory
nc100_lcd_pos_xy:			dw	0x0000			; LCD x/y cursor position (X: 0-59/Y: 0-63)
nc100_lcd_pixel_offset:			db	0x00			; LCD pixel position in data byte
nc100_lcd_draw_attributes:		db	0x00			; Cursor draw attributes
									; 0 - 0 = Normal, 1 = Invert
									; 1 - 0 = Copy over, 1 = Merge
									; 7 - 0 = LF resets to (0,0), 1 = Scrolls screen

; # Keyboard variables
; #################################
nc100_keyboard_raw_keycode:		db	0x00			; Raw keycode returned from interrupt handler (Possibly amalgam of characters)
nc100_keyboard_raw_keycode_prev:	db	0x00			; Previous raw keycode returned from interrupt handler
nc100_keyboard_raw_control:		db	0x00			; Raw control keys from interrupt handler
nc100_keyboard_raw_control_prev:	db	0x00			; Previous raw control keys from interrupt handler
nc100_keyboard_controller_state:	db	0x00			; Persistent information (capslock, etc)
nc100_keyboard_raw_character_count:	db	0x00			; Number of character (not control!) keys depressed

;  Memory locations 0x0040-0x004f not used by CP/M, allocated to CBIOS
orgmem	mem_base+0x40
; # Config variables
; #################################
nc100_config:
nc100_config_uart_mode:			db	0x0			; Holds the UART mode byte
nc100_config_uart_baud:			db	0x0			; Holds UART baud [3-0], current state [6], permanently enable [7]
nc100_config_misc:			db	0x0			; Stores various parameters
nc100_config_draw_attributes:		db	0x0			; Copy of draw attributes
nc100_config5:				db	0x0
nc100_config6:				db	0x0
nc100_config7:				db	0x0
nc100_config8:				db	0x0
nc100_config9:				db	0x0
nc100_config10:				db	0x0
nc100_config11:				db	0x0
nc100_config_chksum:			db	0x0
; # I/O register mirrors
; #################################
;  Some I/O ports are write only so mirror
;  writes to these locations
nc100_io_mirror_misc_config_A:		db	0xff			; Initialises as all 1s

orgmem	nc100_lib_base
; # Font data
; ###########################################################################
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

; Provides LCD 8x8 font
include "nc100/lcd_font_8x8.asm"

; Memory routines
include	"nc100/memory.asm"

; Special I/O routines
include	"nc100/io_special.asm"

; Power routines
include	"nc100/power.asm"

; Keyboard routines
include	"nc100/keyboard.asm"

; Serial routines
include	"nc100/serial_io.asm"
include	"nc100/serial_config.asm"

; RTC routines
include "nc100/rtc.asm"

; Config routines
include	"nc100/config.asm"

; Interrupt routines
include	"nc100/interrupts.asm"

; ###########################################################################
; # nc100_get_version
; #################################
;  Returns the version number of the nc100_libs
;	Out:	D = Major version number
;		E = Minor version number
nc100_get_version:
        ld      d, nc100_lib_version_major
        ld      e, nc100_lib_version_minor
        ret

; # Console routines
; ###########################################################################

; # nc100_console_set_local
; #################################
;  Use LCD/keyboard as the console I/O
nc100_console_set_local:
	; Replace dummy console routines
	ld	de, nc100_console_local_char_out
	ld	(monlib_console_out+1), de
	ld	de, nc100_console_local_char_in
	ld	(monlib_console_in+1), de
	call	nc100_serial_reset
	and	0x00							; Ensure Zero flag set (for config routine)
	ret

; # nc100_console_set_serial
; #################################
;  Set the serial port as the console I/O
nc100_console_set_serial:
	; Replace dummy console routines
	ld	de, nc100_serial_polling_char_out
	ld	(monlib_console_out+1), de
	ld	de, nc100_serial_polling_char_in
	ld	(monlib_console_in+1), de
	call	nc100_serial_config
	call	nc100_lcd_clear_screen
	or	0xff							; Ensure Zero flag unset (for config routine)
	ret

; # nc100_console_local_char_out
; #################################
;  Copy character to selected output device
;	In:	A = ASCII character
nc100_console_local_char_out:
	exx								; Swap out registers
	push	ix
	push	iy
	ld	de, (nc100_lcd_pos_xy)					; Load cursor X/Y position
	ld	hl, (nc100_raster_cursor_addr)				; Load cursor address
nc100_console_local_char_out_check_bs:
	cp	character_code_backspace				; Check for BS (backspace)
	jr	nz, nc100_console_local_char_out_check_del
	call	nc100_lcd_backspace_8x8
	jr	nc100_console_local_char_out_exit
nc100_console_local_char_out_check_del:
	cp	character_code_delete					; Check for Delete
	jr	nz, nc100_console_local_char_out_check_lf
	call	nc100_lcd_backspace_8x8
	jr	nc100_console_local_char_out_exit
nc100_console_local_char_out_check_lf:
	cp	character_code_linefeed					; Check for LF (line feed)
	jr	nz, nc100_console_local_char_out_check_cr
	call	nc100_lcd_print_lf_8x8
	jr	nc100_console_local_char_out_exit
nc100_console_local_char_out_check_cr:
	cp	character_code_carriage_return				; Check for CR (carriage return)
	jr	nz, nc100_console_local_char_out_print_glyph
	call	nc100_lcd_print_cr_8x8
	jr	nc100_console_local_char_out_exit
nc100_console_local_char_out_print_glyph:
	call	nc100_lcd_print_glyph_8x8
nc100_console_local_char_out_exit:
	pop	iy
	pop	ix
	exx								; Swap back registers
	ret

; # nc100_console_local_char_in
; #################################
;  Returns a character from the keyboard if one is depressed
;	Out:    A = ASCII character code
;	Carry flag set if character valid
nc100_console_local_char_in:
	exx
nc100_console_local_char_in_loop:
	call	nc100_keyboard_char_in
	jr	nc, nc100_console_local_char_in_loop
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
;  Power switch handler
nm_interrupt_handler:

; Is this sideloaded, so need to switch back to original ROM
if NC100_PROGRAMCARD_SIDELOAD == 0
	jp	nc100_power_off						; Turn off system
	halt								; Shouldn't get here
else
	; Switch bank 0 RAM into the last page
	ld	a, nc100_membank_RAM|nc100_membank_0k
	out	(nc100_io_membank_D), a

	; Continue execution from high address
	ld	hl, nm_interrupt_handler_pc_sl_cont			; Get jump address
	ld	bc, 0xc000						; Start of the last page
	add	hl, bc
	jp	(hl)							; Jump to next instruction in high address

nm_interrupt_handler_pc_sl_cont:
	; Switch ROM back in
	ld	a, nc100_membank_ROM|nc100_membank_32k
	out	(nc100_io_membank_C), a					; Select RAM for next page
	ld	a, nc100_membank_ROM|nc100_membank_16k
	out	(nc100_io_membank_B), a					; Select RAM for next page
	ld	a, nc100_membank_ROM|nc100_membank_0k
	out	(nc100_io_membank_A), a					; Select RAM for lowest page

	rst 0								; Restart ROM
endif

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
	; Configure RAM/ROM
	ld	a, nc100_membank_RAM|nc100_membank_48k
	out	(nc100_io_membank_D), a					; Select RAM for next page
	ld	a, nc100_membank_RAM|nc100_membank_32k
	out	(nc100_io_membank_C), a					; Select RAM for next page

	; We've got RAM now so set stack pointer (Yay!)
	; Set below screen RAM
	ld	sp, 0xf000						; So first object wil be pushed to 0xEFFF

; If booting from ROM, need to copy the code into RAM.
; Otherwise being sideloaded, so just configure memory as all RAM (already copied).
if NC100_PROGRAMCARD_SIDELOAD == 0
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
else
	ld	a, nc100_membank_RAM|nc100_membank_16k
	out	(nc100_io_membank_B), a					; Select RAM for next page
	ld	a, nc100_membank_RAM|nc100_membank_0k
	out	(nc100_io_membank_A), a					; Select RAM for lowest page
endif

	call	nc100_serial_init					; Init UART (turn off)
	call	nc100_rtc_init						; Init RTC

	; Reset interrupts
	xor	a							; Clear A
	out	(nc100_io_irq_mask), a					; Clear interrupt mask
	out	(nc100_io_irq_status), a				; Clear interrupt status flags

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

	; Setup screen
	ld	hl, 0xf000						; Set screen at RAM top, above stack
	call	nc100_lcd_set_raster_addr
	xor	a							; Clear attributes
	call	nc100_lcd_set_attributes
	call	nc100_lcd_clear_screen					; Clear screen memory

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
	halt								; Wait for keyboard interrupt
									; So that any key currently depressed can be read

startup_cmd_config:
	; Check for device config reset
	call	nc100_keyboard_char_in					; Get key (if there is one)
	cp	character_code_delete					; Check if delete
	jr	nz, startup_cmd_config_load
startup_cmd_config_load_defaults:
	call	nc100_config_load_defaults				; Restore and apply default system config
	jr	startup_cmd_continue
startup_cmd_config_load:
	call	nc100_config_restore					; Restore and apply system config

startup_cmd_continue:
	; Configure z80Mon variables
	ld	bc, 0x4000
	ld	(z80mon_default_addr), bc				; Set monitor's current address: 0x4000

	rst	16							; Continue boot

; ###########################################################################
; #                                                                         #
; #                             System Config                               #
; #                                                                         #
; ###########################################################################

orgmem  nc100_cmd_base+0x0200
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	254,'!',0,0						; id (254=cmd)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"System config",0

orgmem  nc100_cmd_base+0x0240
include	"nc100/setup.asm"
