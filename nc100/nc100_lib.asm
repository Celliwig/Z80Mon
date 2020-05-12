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
nc100_config1:
					db	0x0
nc100_config2:
					db	0x0
nc100_config3:
					db	0x0
nc100_config4:
					db	0x0
nc100_config5:
					db	0x0
nc100_config6:
					db	0x0
nc100_config7:
					db	0x0
nc100_config8:
					db	0x0
nc100_config9:
					db	0x0
nc100_config10:
					db	0x0
nc100_config11:
					db	0x0
nc100_config_chksum:
					db	0x0

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

; Power routines
include	"nc100/power.asm"

; Keyboard routines
include	"nc100/keyboard.asm"

; Serial routines
include	"nc100/serial_io.asm"

; RTC routines
include "nc100/rtc.asm"

; Interrupt routines
include	"nc100/interrupts.asm"

; # Console routines
; ###########################################################################
; # nc100_console_print_glyph
; #################################
nc100_console_print_glyph:
	jp	nc100_lcd_print_glyph_8x8

; # nc100_console_linefeed
; #################################
nc100_console_linefeed:
	jp	nc100_lcd_print_lf_8x8

; # nc100_console_carriage_return
; #################################
nc100_console_carriage_return:
	jp	nc100_lcd_print_cr_8x8

; # nc100_console_delete
; #################################
nc100_console_delete:
; # nc100_console_backspace
; #################################
nc100_console_backspace:
	jp	nc100_lcd_backspace_8x8

; # nc100_console_char_out
; #################################
;  Copy character to selected output device
;	In:	A = ASCII character
nc100_console_char_out:
	exx								; Swap out registers
	ld	de, (nc100_lcd_pos_xy)					; Load cursor X/Y position
	ld	hl, (nc100_raster_cursor_addr)				; Load cursor address
nc100_console_char_out_check_bs:
	cp	character_code_backspace				; Check for BS (backspace)
	jr	nz, nc100_console_char_out_check_del
	call	nc100_console_backspace
	jr	nc100_console_char_out_exit
nc100_console_char_out_check_del:
	cp	character_code_delete					; Check for Delete
	jr	nz, nc100_console_char_out_check_lf
	call	nc100_console_delete
	jr	nc100_console_char_out_exit
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
	call	nc100_console_print_glyph
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
;  Power switch handler
nm_interrupt_handler:

; Is this sideloaded, so need to switch back to original ROM
if NC100_PROGRAMCARD_SIDELOAD == 0
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

	; Setup screen
	ld	hl, 0xf000						; Set screen at RAM top, above stack
	call	nc100_lcd_set_raster_addr

	xor	a							; Clear attributes
	;set	nc100_draw_attrib_invert_bit, a				; Set inverted attributes
	;set	nc100_draw_attrib_merge_bit, a				; Overwrite
	set	nc100_draw_attrib_scroll_bit, a				; Scroll screen
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

	call	nc100_serial_init					; Init UART (turn off)
	call	nc100_rtc_init						; Init RTC

	; Configure z80Mon variables
	ld	bc, 0x4000
	ld	(z80mon_default_addr), bc				; Set monitor's current address: 0x4000

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
;	ld	b, nc100_serial_baud_2400
;	ld	c, uPD71051_reg_mode_bclk_x16 | uPD71051_reg_mode_chrlen_8 | uPD71051_reg_mode_parity_none | uPD71051_reg_mode_stopbit_1
;	call	nc100_serial_config
;
;	; Replace dummy console routines
;	ld	bc, nc100_serial_char_out_poll
;	ld	(monlib_console_out+1), bc
;	ld	bc, nc100_serial_char_in_poll
;	ld	(monlib_console_in+1), bc

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
	call	nc100_lcd_clear_screen
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
	call	setup_cmd_border_print					; Print border

setup_cmd_loop:
	call	setup_cmd_selector_print

setup_cmd_loop_draw:
	ld	a, (var_setup_selected)					; Get index
	bit	7, a							; Check if need to redraw
	jr	z, setup_cmd_loop_update
	and	0x7f
	ld	(var_setup_selected), a					; Save filtered index
	ld	hl, setup_cmd_loop_update				; Push return address
	push	hl							; For the following jumps
	cp	0
	jr	z, setup_cmd_window_datetime_draw
	cp	1
	jr	z, setup_cmd_window_console_draw
	cp	2
	jp	z, setup_cmd_window_serial_draw
	cp	3
	jp	z, setup_cmd_window_status_draw
	pop	af							; Should never reach here
									; So pop to re-align stack
setup_cmd_loop_update:
	ld	a, (var_setup_selected)					; Get index
	ld	hl, setup_cmd_loop_check_key				; Push return address
	push	hl							; For the following jumps
	cp	0
	jr	z, setup_cmd_window_datetime_update
	cp	1
	jr	z, setup_cmd_window_console_update
	cp	2
	jp	z, setup_cmd_window_serial_update
	cp	3
	jp	z, setup_cmd_window_status_update
	pop	af							; Should never reach here
									; So pop to re-align stack
setup_cmd_loop_check_key:
	call	nc100_keyboard_char_in					; Check for key press
	jr	nc, setup_cmd_loop					; Just loop if no key
setup_cmd_loop_check_key_up:
	cp	character_code_up					; Check if up
	jr	nz, setup_cmd_loop_check_key_down
	ld	a, (var_setup_selected)					; Get selected index
	and	a							; Check if zero
	jr	z, setup_cmd_loop					; If already zero, just loop
	dec	a							; Index--
	set	7, a							; Set msb (used to force a redraw)
	ld	(var_setup_selected), a					; Save selected index
	jr	setup_cmd_loop						; Loop
setup_cmd_loop_check_key_down:
	cp	character_code_down					; Check if down
	jr	nz, setup_cmd_loop_check_key_exit
	ld	a, (var_setup_selected)					; Get selected index
	cp	setup_cmd_screens_max-1					; Check if last screen
	jr	z, setup_cmd_loop					; If on last screen, just loop
	inc	a							; Index++
	set	7, a							; Set msb (used to force a redraw)
	ld	(var_setup_selected), a					; Save selected index
	jr	setup_cmd_loop						; Loop
setup_cmd_loop_check_key_exit:
	cp	character_code_escape
	jr	nz, setup_cmd_loop

	call	print_newline

	ret

; # Date/Time window
; #################################
setup_cmd_window_datetime_draw:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted

	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x080e						; Initial position (14,8)
	ld	l, 0
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
	call	nc100_lcd_set_cursor_by_grid

	ld	hl, str_setup_datetime
	call	print_str_simple

	ret

setup_cmd_window_datetime_update:
	ret

; # Console window
; #################################
setup_cmd_window_console_draw:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted

	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x080e						; Initial position (14,8)
	ld	l, 0
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
	call	nc100_lcd_set_cursor_by_grid

	ld	hl, str_setup_console
	call	print_str_simple

	ret

setup_cmd_window_console_update:
	ret

; # Serial window
; #################################
setup_cmd_window_serial_draw:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted

	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x080e						; Initial position (14,8)
	ld	l, 0
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
	call	nc100_lcd_set_cursor_by_grid

	ld	hl, str_setup_serial
	call	print_str_simple

	ret

setup_cmd_window_serial_update:
	ret

; # Status window
; #################################
setup_cmd_window_status_draw:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted

	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x0811						; Initial position (17,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	bc, 0x0000
	call	print_hex16
	ld	de, 0x081b						; Initial position (27,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	bc, 0x4000
	call	print_hex16
	ld	de, 0x0825						; Initial position (37,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	bc, 0x8000
	call	print_hex16
	ld	de, 0x082f						; Initial position (47,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	bc, 0xc000
	call	print_hex16
	ld	de, 0x1010						; Initial position (16,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_setup_status_mem_top
	call	print_str_repeat
	ld	de, 0x1810						; Initial position (16,24)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_setup_status_mem_middle
	call	print_str_repeat
	ld	de, 0x2010						; Initial position (16,32)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_setup_status_mem_bottom
	call	print_str_repeat
	ld	de, 0x280f						; Initial position (15,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_memory_card
	call	print_str_simple
	ld	de, 0x3013						; Initial position (19,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_battery
	call	print_str_simple
	ld	de, 0x2826						; Initial position (38,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_power_in
	call	print_str_simple
	ld	de, 0x3028						; Initial position (40,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_backup
	call	print_str_simple
	ret

setup_cmd_window_status_update:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted

setup_cmd_window_status_update_page_src:
	ld	de, 0x1812						; Initial position (18,24)
	ld	l, 0
	ld	c, nc100_io_membank_A
setup_cmd_window_status_update_page_src_loop:
	push	bc							; Save C
	call	nc100_lcd_set_cursor_by_grid
	pop	bc							; Restore C
	call	nc100_memory_page_get
	ld	a, b							; Get page source bits
	rlc	a
	rlc	a
	and	0x03
	ld	hl, str_memtype_rom
	ld	de, 0x05
	cp	0
setup_cmd_window_status_update_page_src_str_loop:
	jr	z, setup_cmd_window_status_update_page_src_write
	add	hl, de							; Next string pointer
	dec	a
	jr	setup_cmd_window_status_update_page_src_str_loop
setup_cmd_window_status_update_page_src_write:
	call	print_str
	ld	a, ':'
	call	monlib_console_out
	ld	a, b
	and	0x3f
	call	print_hex8
	ld	de, (nc100_lcd_pos_xy)					; Get current position
	ld	a, 0x03							; Value to add to X
	add	e
	ld	e, a							; Set new position
	ld	l, 0
	inc	c
	ld	a, c
	cp	nc100_io_membank_D+1
	jr	nz, setup_cmd_window_status_update_page_src_loop

setup_cmd_window_status_update_memcard:
	call	nc100_memory_memcard_present
	jr	nc, setup_cmd_window_status_update_memcard_missing
	ld	de, 0x281b						; Initial position (27,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_present
	call	print_str_simple
	ld	de, 0x301b						; Initial position (27,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_okay
	call	nc100_power_check_battery_memcard			; Check memory card battery status
	jr	c, setup_cmd_window_status_update_memcard_battery_write
	ld	hl, str_failed
setup_cmd_window_status_update_memcard_battery_write:
	call	print_str_simple
	jr	setup_cmd_window_status_update_power
setup_cmd_window_status_update_memcard_missing:
	ld	de, 0x281b						; Initial position (27,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_missing
	call	print_str_simple
	ld	de, 0x301b						; Initial position (27,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_na
	call	print_str_simple

setup_cmd_window_status_update_power:
setup_cmd_window_status_update_power_in:
	ld	de, 0x282f						; Initial position (47,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_okay
	call	nc100_power_check_in_gt_4v
	jr	c, setup_cmd_window_status_update_power_in_write
	ld	hl, str_poor
	call	nc100_power_check_in_gt_3v
	jr	c, setup_cmd_window_status_update_power_in_write
	ld	hl, str_failed
setup_cmd_window_status_update_power_in_write:
	call	print_str_simple
setup_cmd_window_status_update_power_backup:
	ld	de, 0x302f						; Initial position (47,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_okay
	call	nc100_power_check_battery_backup
	jr	c, setup_cmd_window_status_update_power_backup_write
	ld	hl, str_failed
setup_cmd_window_status_update_power_backup_write:
	call	print_str_simple
	ret

; # Clear window
; #################################
setup_cmd_window_clear:
	ld	de, 0x080e						; Initial position (14,8)
	ld	l, 0
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
setup_cmd_window_clear_set_row:
	call	nc100_lcd_set_cursor_by_grid
	ld	b, 0x2d							; Number of characters to clear
setup_cmd_window_clear_write_char:
	ld	a, ' '
	call	monlib_console_out
	djnz	setup_cmd_window_clear_write_char
	ld	a, d
	add	0x08
	ld	d, a							; Next row
	cp	0x38							; Check if on last row
	jr	nz, setup_cmd_window_clear_set_row
	ret

; # Print the window selector
; #################################
setup_cmd_selector_print:
setup_cmd_selector_print_datetime:
	ld	a, (var_setup_selected)
	and	0x7f
	cp	0
	jr	z, setup_cmd_selector_print_datetime_selected
setup_cmd_selector_print_datetime_unselected:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
	jr	setup_cmd_selector_print_datetime_draw
setup_cmd_selector_print_datetime_selected:
	xor	a
	call	nc100_lcd_set_attributes				; No scroll
setup_cmd_selector_print_datetime_draw:
	ld	de, 0x0802
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,8)
	ld	hl, str_setup_datetime
	call	print_str_simple
setup_cmd_selector_print_console:
	ld	a, (var_setup_selected)
	and	0x7f
	cp	1
	jr	z, setup_cmd_selector_print_console_selected
setup_cmd_selector_print_console_unselected:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
	jr	setup_cmd_selector_print_console_draw
setup_cmd_selector_print_console_selected:
	xor	a
	call	nc100_lcd_set_attributes				; No scroll
setup_cmd_selector_print_console_draw:
	ld	de, 0x1002
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,16)
	ld	hl, str_setup_console
	call	print_str_simple
setup_cmd_selector_print_serial:
	ld	a, (var_setup_selected)
	and	0x7f
	cp	2
	jr	z, setup_cmd_selector_print_serial_selected
setup_cmd_selector_print_serial_unselected:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
	jr	setup_cmd_selector_print_serial_draw
setup_cmd_selector_print_serial_selected:
	xor	a
	call	nc100_lcd_set_attributes				; No scroll
setup_cmd_selector_print_serial_draw:
	ld	de, 0x1802
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,24)
	ld	hl, str_setup_serial
	call	print_str_simple
setup_cmd_selector_print_status:
	ld	a, (var_setup_selected)
	and	0x7f
	cp	3
	jr	z, setup_cmd_selector_print_status_selected
setup_cmd_selector_print_status_unselected:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
	jr	setup_cmd_selector_print_status_draw
setup_cmd_selector_print_status_selected:
	xor	a
	call	nc100_lcd_set_attributes				; No scroll
setup_cmd_selector_print_status_draw:
	ld	de, 0x2002
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,32)
	ld	hl, str_setup_status
	call	print_str_simple
	ret

; # Prints the border for the setup interface
; #################################
setup_cmd_border_print:
	ld	de, 0x0000
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Reset cursor (0,0)
	ld	hl, str_setup_border_top
	call	print_str_repeat					; Print top
	ld	d, 0x6
setup_cmd_border_print_loop:
	ld	hl, str_setup_border_middle
	call	print_str_repeat					; Print middle
	dec	d
	jr	nz, setup_cmd_border_print_loop
	ld	hl, str_setup_border_bottom
	call	print_str_repeat					; Print bottom
	ret

; # Variables
; #################################
setup_cmd_screens_max:		equ		0x04			; Number of different screens
var_setup_selected:		db		0x80

; # Strings
; #################################
str_setup_border_top:		db		0x01,0xc9,0x0c,0xcd,0x01,0xcb,0x2d,0xcd,0x01,0xbb,0x00
str_setup_border_middle:	db		0x01,0xba,0x0c,0x20,0x01,0xba,0x2d,0x20,0x01,0xba,0x00
str_setup_border_bottom:	db		0x01,0xc8,0x0c,0xcd,0x01,0xca,0x2d,0xcd,0x01,0xbc,0x00

str_setup_status_mem_top:	db		0x01,0xda,0x09,0xc4,0x01,0xc2,0x09,0xc4,0x01,0xc2,0x09,0xc4,0x01,0xc2,0x09,0xc4,0x01,0xbf,0x00
str_setup_status_mem_middle:	db		0x01,0xb3,0x09,0x20,0x01,0xb3,0x09,0x20,0x01,0xb3,0x09,0x20,0x01,0xb3,0x09,0x20,0x01,0xb3,0x00
str_setup_status_mem_bottom:	db		0x01,0xc0,0x09,0xc4,0x01,0xc1,0x09,0xc4,0x01,0xc1,0x09,0xc4,0x01,0xc1,0x09,0xc4,0x01,0xd9,0x00

str_setup_datetime:		db		"Date/Time",0
str_setup_console:		db		" Console ",0
str_setup_serial:		db		"  Serial ",0
str_setup_status:		db		"  Status ",0

str_memtype_rom:		db		" ROM",0
str_memtype_ram:		db		" RAM",0
str_memtype_cram:		db		"CRAM",0

str_memory_card:		db		"Memory Card:",0
str_backup:			db		"Backup:",0
str_battery:			db		"Battery:",0
str_power_in:			db		"Power In: ",0
str_present:			db		"Present",0
str_missing:			db		"Missing",0
str_okay:			db		"Okay",0
str_poor:			db		"Poor",0
str_failed:			db		"Failed",0
str_na:				db		"N/A",0
