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
nc100_config3:				db	0x0
nc100_config4:				db	0x0
nc100_config5:				db	0x0
nc100_config6:				db	0x0
nc100_config7:				db	0x0
nc100_config8:				db	0x0
nc100_config9:				db	0x0
nc100_config10:				db	0x0
nc100_config11:				db	0x0
nc100_config_chksum:			db	0x0

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
	ld	a, 0x80							; Initialise state variables
	ld	(var_setup_selected_config), a
	ld	a, 0xff
	ld	(var_setup_selected_item), a
	ld	(var_setup_selected_editor), a

	call	nc100_lcd_clear_screen
	call	setup_cmd_set_attributes_inverted
	call	setup_cmd_border_print					; Print border

setup_cmd_loop:
	call	setup_cmd_selector_print

setup_cmd_loop_draw:
	ld	a, (var_setup_selected_config)				; Get index
	bit	7, a							; Check if need to redraw
	jr	z, setup_cmd_loop_update
	and	0x7f
	ld	(var_setup_selected_config), a				; Save filtered index
	ld	hl, setup_cmd_loop_update				; Push return address
	push	hl							; For the following jumps
	cp	0
	jp	z, setup_cmd_window_datetime_draw
	cp	1
	jp	z, setup_cmd_window_console_draw
	cp	2
	jp	z, setup_cmd_window_serial_draw
	cp	3
	jp	z, setup_cmd_window_status_draw
	pop	af							; Should never reach here
									; So pop to re-align stack
setup_cmd_loop_update:
	ld	a, (var_setup_selected_config)				; Get index
	ld	hl, setup_cmd_loop_check_key				; Push return address
	push	hl							; For the following jumps
	cp	0
	jp	z, setup_cmd_window_datetime_update
	cp	1
	jp	z, setup_cmd_window_console_update
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
	ld	a, (var_setup_selected_config)				; Get selected index
	and	a							; Check if zero
	jr	z, setup_cmd_loop					; If already zero, just loop
	dec	a							; Index--
	set	7, a							; Set msb (used to force a redraw)
	ld	(var_setup_selected_config), a				; Save selected index
	jr	setup_cmd_loop						; Loop
setup_cmd_loop_check_key_down:
	cp	character_code_down					; Check if down
	jr	nz, setup_cmd_loop_check_key_enter
	ld	a, (var_setup_selected_config)				; Get selected index
	cp	setup_cmd_screens_max-1					; Check if last screen
	jr	z, setup_cmd_loop					; If on last screen, just loop
	inc	a							; Index++
	set	7, a							; Set msb (used to force a redraw)
	ld	(var_setup_selected_config), a				; Save selected index
	jr	setup_cmd_loop						; Loop
setup_cmd_loop_check_key_enter:
	cp	character_code_carriage_return				; Check if enter
	jr	nz, setup_cmd_loop_check_key_exit
	xor	a
	ld	(var_setup_selected_item), a				; Reset selected item
	ld	a, (var_setup_selected_config)				; Get index
	ld	hl, setup_cmd_loop_check_key_exit			; Push return address
	push	hl							; For the following jumps
	cp	0
	jp	z, setup_cmd_window_datetime_edit
	cp	1
	jp	z, setup_cmd_window_console_edit
	cp	2
	jp	z, setup_cmd_window_serial_edit
	cp	3
	jp	z, setup_cmd_window_status_edit
	pop	af							; Should never reach here
									; So pop to re-align stack
setup_cmd_loop_check_key_exit:
	cp	character_code_escape
	jp	nz, setup_cmd_loop

	call	print_newline

	ret

; # Date/Time window
; ##################################################
setup_cmd_window_datetime_item_time:		equ		0x00
setup_cmd_window_datetime_item_date:		equ		0x01
setup_cmd_window_datetime_item_format:		equ		0x02
setup_cmd_window_datetime_item_alarm_time:	equ		0x03
setup_cmd_window_datetime_item_alarm_enabled:	equ		0x04

; # setup_cmd_window_datetime_draw
; #################################
setup_cmd_window_datetime_draw:
	call	setup_cmd_set_attributes_inverted
	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x080f						; Initial position (15,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_current
	call	print_str_simple
	ld	de, 0x1014						; Initial position (20,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_time
	call	print_str_simple
	ld	de, 0x1028						; Initial position (40,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_clk_format
	call	print_str_simple
	ld	de, 0x1814						; Initial position (20,24)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_date
	call	print_str_simple
	ld	de, 0x200f						; Initial position (15,32)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_alarm
	call	print_str_simple
	ld	de, 0x2814						; Initial position (20,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_time
	call	print_str_simple
	ld	de, 0x2828						; Initial position (40,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_enabled
	call	print_str_simple
	ld	hl, str_checkbox
	call	print_str_simple

	ret

; # setup_cmd_window_datetime_update
; #################################
setup_cmd_window_datetime_update:
	call	setup_cmd_set_attributes_inverted

	call	nc100_rtc_datetime_get					; Get Date/Time
	ld	(var_setup_time_second), bc				; Save to memory
	ld	(var_setup_time_hour), de
	ld	(var_setup_date_month), hl

setup_cmd_window_datetime_update_time:
	ld	de, 0x101a						; Initial position (26,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
setup_cmd_window_datetime_update_time_edit:
	ld	a, (var_setup_selected_editor)				; Is this being editted?
	cp	setup_cmd_window_datetime_item_time
	jr	nz, setup_cmd_window_datetime_update_time_actual
	call	setup_cmd_window_datetime_editor_draw
	jr	setup_cmd_window_datetime_update_date
setup_cmd_window_datetime_update_time_actual:
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_datetime_item_time
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (var_setup_time_hour)
	call	print_hex8
	ld	a, ':'
	call	monlib_console_out
	ld	a, (var_setup_time_minute)
	call	print_hex8
	ld	a, ':'
	call	monlib_console_out
	ld	a, (var_setup_time_second)
	call	print_hex8

setup_cmd_window_datetime_update_date:
	ld	de, 0x181a						; Initial position (26,24)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
setup_cmd_window_datetime_update_date_edit:
	ld	a, (var_setup_selected_editor)				; Is this being editted?
	cp	setup_cmd_window_datetime_item_date
	jr	nz, setup_cmd_window_datetime_update_date_actual
	call	setup_cmd_window_datetime_editor_draw
	jr	setup_cmd_window_datetime_update_format
setup_cmd_window_datetime_update_date_actual:
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_datetime_item_date
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (var_setup_date_day)
	call	print_hex8
	ld	a, '/'
	call	monlib_console_out
	ld	a, (var_setup_date_month)
	call	print_hex8
	ld	a, '/'
	call	monlib_console_out
	ld	a, (var_setup_date_year)
	call	print_hex8

setup_cmd_window_datetime_update_format:
	ld	de, 0x1030						; Initial position (48,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_datetime_item_format
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	call	nc100_rtc_datetime_format_check
	ld	hl, str_format_12
	jr	nc, setup_cmd_window_datetime_update_format_print
	ld	hl, str_format_24
setup_cmd_window_datetime_update_format_print:
	call	print_str_simple

	call	nc100_rtc_alarm_get					; Get alarm time
	ld	(var_setup_alarm_minute), de

setup_cmd_window_datetime_update_alarm_time:
	ld	de, 0x281a						; Initial position (26,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
setup_cmd_window_datetime_update_alarm_time_edit:
	ld	a, (var_setup_selected_editor)				; Is this being editted?
	cp	setup_cmd_window_datetime_item_alarm_time
	jr	nz, setup_cmd_window_datetime_update_alarm_time_actual
	call	setup_cmd_window_datetime_editor_draw
	jr	setup_cmd_window_datetime_update_alarm_enabled
setup_cmd_window_datetime_update_alarm_time_actual:
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_datetime_item_alarm_time
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (var_setup_alarm_hour)
	call	print_hex8
	ld	a, ':'
	call	monlib_console_out
	ld	a, (var_setup_alarm_minute)
	call	print_hex8
	ld	a, ':'
	call	monlib_console_out
	ld	a, 0x00							; Draw fake seconds for the datetime editor
	call	print_hex8

setup_cmd_window_datetime_update_alarm_enabled:
	ld	de, 0x2831						; Initial position (49,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_datetime_item_alarm_enabled
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	call	nc100_rtc_alarm_check					; Check whether alarm is enabled
	ld	a, ' '
	jr	nc, setup_cmd_window_datetime_update_alarm_enabled_print
	ld	a, 'X'
setup_cmd_window_datetime_update_alarm_enabled_print:
	call	monlib_console_out

	ret

; # setup_cmd_window_datetime_edit
; #################################
setup_cmd_window_datetime_edit:
	call	setup_cmd_window_datetime_update			; Update pane

setup_cmd_window_datetime_edit_check_key:
	call	nc100_keyboard_char_in					; Check for key press
	jr	nc, setup_cmd_window_datetime_edit			; Just loop if no key
setup_cmd_window_datetime_edit_check_key_up:
	cp	character_code_up					; Check if up
	jr	nz, setup_cmd_window_datetime_edit_check_key_down
	ld	a, (var_setup_selected_item)				; Get selected index
	and	a							; Check if zero
	jr	z, setup_cmd_window_datetime_edit			; If already zero, just loop
	dec	a							; Index--
	ld	(var_setup_selected_item), a				; Save selected index
	jr	setup_cmd_window_datetime_edit				; Loop
setup_cmd_window_datetime_edit_check_key_down:
	cp	character_code_down					; Check if down
	jr	nz, setup_cmd_window_datetime_edit_check_key_left
	ld	a, (var_setup_selected_item)				; Get selected index
	cp	4
	jr	z, setup_cmd_window_datetime_edit			; If on last screen, just loop
	inc	a							; Index++
	ld	(var_setup_selected_item), a				; Save selected index
	jr	setup_cmd_window_datetime_edit				; Loop
setup_cmd_window_datetime_edit_check_key_left:
	cp	character_code_left					; Check if left
	jr	nz, setup_cmd_window_datetime_edit_check_key_space
	ld	a, (var_setup_selected_item)				; Get selected index
	ld	hl, setup_cmd_window_datetime_edit			; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_window_datetime_item_format
	jp	z, nc100_rtc_datetime_format_toggle
	cp	setup_cmd_window_datetime_item_alarm_enabled
	jp	z, nc100_rtc_alarm_toggle
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_datetime_edit_check_key_space:
	cp	' '							; Check if space
	jr	nz, setup_cmd_window_datetime_edit_check_key_right
	jr	setup_cmd_window_datetime_edit_check_key_right_do
setup_cmd_window_datetime_edit_check_key_right:
	cp	character_code_right					; Check if right
	jr	nz, setup_cmd_window_datetime_edit_check_key_enter
setup_cmd_window_datetime_edit_check_key_right_do:
	ld	a, (var_setup_selected_item)				; Get selected index
	ld	hl, setup_cmd_window_datetime_edit			; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_window_datetime_item_format
	jp	z, nc100_rtc_datetime_format_toggle
	cp	setup_cmd_window_datetime_item_alarm_enabled
	jp	z, nc100_rtc_alarm_toggle
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_datetime_edit_check_key_enter:
	cp	character_code_carriage_return				; Check if enter
	jr	nz, setup_cmd_window_datetime_edit_check_key_exit
	ld	a, (var_setup_selected_item)				; Get selected index
	ld	hl, setup_cmd_window_datetime_edit			; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_window_datetime_item_time
	jp	z, setup_cmd_window_datetime_editor_time
	cp	setup_cmd_window_datetime_item_date
	jp	z, setup_cmd_window_datetime_editor_date
	cp	setup_cmd_window_datetime_item_alarm_time
	jp	z, setup_cmd_window_datetime_editor_alarm_time
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_datetime_edit_check_key_exit:
	cp	character_code_escape
	jp	nz, setup_cmd_window_datetime_edit

	ld	a, 0xff
	ld	(var_setup_selected_item), a				; Reset selected item
	ret

; # setup_cmd_window_datetime_editor_draw
; #################################
;  Draws the editor contents with highlighting
setup_cmd_window_datetime_editor_draw:
	ld	a, (var_setup_selected_editor_index)
	cp	0
	call	z,setup_cmd_set_attributes_inverted
	call	nz,setup_cmd_set_attributes_normal
	ld	a, (var_setup_editor_temp1)
	ld	b, a
	and	0xf0
	srl	a
	srl	a
	srl	a
	srl	a
	call	print_hex_digit
	ld	a, (var_setup_selected_editor_index)
	cp	1
	call	z,setup_cmd_set_attributes_inverted
	call	nz,setup_cmd_set_attributes_normal
	ld	a, b
	and	0x0f
	call	print_hex_digit

	call	nc100_lcd_position_increment_8x8

	ld	a, (var_setup_selected_editor_index)
	cp	2
	call	z,setup_cmd_set_attributes_inverted
	call	nz,setup_cmd_set_attributes_normal
	ld	a, (var_setup_editor_temp2)
	ld	b, a
	and	0xf0
	srl	a
	srl	a
	srl	a
	srl	a
	call	print_hex_digit
	ld	a, (var_setup_selected_editor_index)
	cp	3
	call	z,setup_cmd_set_attributes_inverted
	call	nz,setup_cmd_set_attributes_normal
	ld	a, b
	and	0x0f
	call	print_hex_digit

	call	nc100_lcd_position_increment_8x8

	ld	a, (var_setup_selected_editor_index)
	cp	4
	call	z,setup_cmd_set_attributes_inverted
	call	nz,setup_cmd_set_attributes_normal
	ld	a, (var_setup_editor_temp3)
	ld	b, a
	and	0xf0
	srl	a
	srl	a
	srl	a
	srl	a
	call	print_hex_digit
	ld	a, (var_setup_selected_editor_index)
	cp	5
	call	z,setup_cmd_set_attributes_inverted
	call	nz,setup_cmd_set_attributes_normal
	ld	a, b
	and	0x0f
	call	print_hex_digit
	ret

; # setup_cmd_window_datetime_editor
; #################################
;  Editor for date/time fields
;	IY:	Pointer to table of routines to handle each digit position
;	Out:	Carry flag set if return pressed
;		Carry flag cleared if escaped pressed
setup_cmd_window_datetime_editor:
	call	setup_cmd_window_datetime_update			; Update pane

setup_cmd_window_datetime_editor_check_key:
	call	nc100_keyboard_char_in					; Check for key press
	jr	nc, setup_cmd_window_datetime_editor			; Just loop if no key

setup_cmd_window_datetime_editor_check_digit:
	cp	'0'							; Check if '0' or above
	jr	c, setup_cmd_window_datetime_editor_check_key_backspace
	cp	':'							; Check if greater than '9'
	jr	nc, setup_cmd_window_datetime_editor_check_key_backspace
	sub	'0'
	ld	b, a							; Save digit value
	ld	hl, setup_cmd_window_datetime_editor
	push	hl							; Push return address on stack
	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	cp	0							; Check if this digit
	jr	nz, $+9							; If not skip
	ld	l, (iy+0)						; Jump address: LSB
	ld	h, (iy+1)						; Jump address: MSB
	jp	(hl)							; Jump to digit routine
	cp	1							; Check if this digit
	jr	nz, $+9							; If not skip
	ld	l, (iy+2)						; Jump address: LSB
	ld	h, (iy+3)						; Jump address: MSB
	jp	(hl)							; Jump to digit routine
	cp	2							; Check if this digit
	jr	nz, $+9							; If not skip
	ld	l, (iy+4)						; Jump address: LSB
	ld	h, (iy+5)						; Jump address: MSB
	jp	(hl)							; Jump to digit routine
	cp	3							; Check if this digit
	jr	nz, $+9							; If not skip
	ld	l, (iy+6)						; Jump address: LSB
	ld	h, (iy+7)						; Jump address: MSB
	jp	(hl)							; Jump to digit routine
	cp	4							; Check if this digit
	jr	nz, $+9							; If not skip
	ld	l, (iy+8)						; Jump address: LSB
	ld	h, (iy+9)						; Jump address: MSB
	jp	(hl)							; Jump to digit routine
	cp	5							; Check if this digit
	jr	nz, $+9							; If not skip
	ld	l, (iy+10)						; Jump address: LSB
	ld	h, (iy+11)						; Jump address: MSB
	jp	(hl)							; Jump to digit routine
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_datetime_editor_check_key_backspace:
	cp	character_code_backspace				; Check if backspace
	jr	nz, setup_cmd_window_datetime_editor_check_key_left
	jr	setup_cmd_window_datetime_editor_check_key_left_do
setup_cmd_window_datetime_editor_check_key_left:
	cp	character_code_left					; Check if left
	jr	nz, setup_cmd_window_datetime_editor_check_key_right
setup_cmd_window_datetime_editor_check_key_left_do:
	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	cp	0
	jr	z, setup_cmd_window_datetime_editor			; Loop if maxed
	dec	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	jr	setup_cmd_window_datetime_editor
setup_cmd_window_datetime_editor_check_key_right:
	cp	character_code_right					; Check if right
	jr	nz, setup_cmd_window_datetime_editor_check_key_enter
	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	cp	5
	jr	z, setup_cmd_window_datetime_editor			; Loop if maxed
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	jp	setup_cmd_window_datetime_editor
setup_cmd_window_datetime_editor_check_key_enter:
	cp	character_code_carriage_return				; Check if enter
	jr	nz, setup_cmd_window_datetime_editor_check_key_exit
	ld	a, 0xff
	ld	(var_setup_selected_editor), a				; Reset selected item
	scf								; Set Carry flag
	ret
setup_cmd_window_datetime_editor_check_key_exit:
	cp	character_code_escape					; Check if escape
	jp	nz, setup_cmd_window_datetime_editor
	ld	a, 0xff
	ld	(var_setup_selected_editor), a				; Reset selected item
	scf								; Clear Carry flag
	ccf
	ret

; #################################
; # Time editor
; #################################
setup_cmd_window_datetime_editor_time_table:
	dw	setup_cmd_window_datetime_editor_time_digit1
	dw	setup_cmd_window_datetime_editor_time_digit2
	dw	setup_cmd_window_datetime_editor_time_digit3
	dw	setup_cmd_window_datetime_editor_time_digit4
	dw	setup_cmd_window_datetime_editor_time_digit5
	dw	setup_cmd_window_datetime_editor_time_digit6
setup_cmd_window_datetime_editor_time_digit1:
	ld	a, b							; Get digit value
	cp	3							; Check if value greater than 2
	ret	nc							; Just return if it is
	sla	a							; Shift to upper nibble
	sla	a
	sla	a
	sla	a
	ld	b, a							; Save value

	ld	a, (var_setup_editor_temp1)				; Get number to update
	and	0x0f							; Strip first digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp1), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_time_digit2:
	ld	a, (var_setup_editor_temp1)				; Check first digit
	srl	a							; Upper nibble to lower
	srl	a
	srl	a
	srl	a
	cp	2							; Check if first digit is 2
	jr	nz, setup_cmd_window_datetime_editor_time_digit2_update
	ld	a, b
	cp	4							; Check if value greater than 3
	ret	nc							; Just return if it is
setup_cmd_window_datetime_editor_time_digit2_update:
	ld	a, (var_setup_editor_temp1)				; Get number to update
	and	0xf0							; Strip second digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp1), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_time_digit3:
	ld	a, b							; Get digit value
	cp	6							; Check if value greater than 5
	ret	nc							; Just return if it is
	sla	a							; Shift to upper nibble
	sla	a
	sla	a
	sla	a
	ld	b, a							; Save value

	ld	a, (var_setup_editor_temp2)				; Get number to update
	and	0x0f							; Strip first digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp2), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_time_digit4:
	ld	a, (var_setup_editor_temp2)				; Get number to update
	and	0xf0							; Strip second digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp2), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_time_digit5:
	ld	a, b							; Get digit value
	cp	6							; Check if value greater than 5
	ret	nc							; Just return if it is
	sla	a							; Shift to upper nibble
	sla	a
	sla	a
	sla	a
	ld	b, a							; Save value

	ld	a, (var_setup_editor_temp3)				; Get number to update
	and	0x0f							; Strip first digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp3), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_time_digit6:
	ld	a, (var_setup_editor_temp3)				; Get number to update
	and	0xf0							; Strip second digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp3), a				; Save digit
	ret

; #################################
; # Date editor
; #################################
setup_cmd_window_datetime_editor_date_table:
	dw	setup_cmd_window_datetime_editor_date_digit1
	dw	setup_cmd_window_datetime_editor_date_digit2
	dw	setup_cmd_window_datetime_editor_date_digit3
	dw	setup_cmd_window_datetime_editor_date_digit4
	dw	setup_cmd_window_datetime_editor_date_digit5
	dw	setup_cmd_window_datetime_editor_date_digit6
setup_cmd_window_datetime_editor_date_digit1:
	ld	a, b							; Get digit value
	cp	4							; Check if value greater than 3
	ret	nc							; Just return if it is
	sla	a							; Shift to upper nibble
	sla	a
	sla	a
	sla	a
	ld	b, a							; Save value

	ld	a, (var_setup_editor_temp1)				; Get number to update
	and	0x0f							; Strip first digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp1), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_date_digit2:
	ld	a, (var_setup_editor_temp1)				; Check first digit
	srl	a							; Upper nibble to lower
	srl	a
	srl	a
	srl	a
	cp	3							; Check if first digit is 3
	jr	nz, setup_cmd_window_datetime_editor_date_digit2_update
	ld	a, b
	cp	2							; Check if value greater than 1
	ret	nc							; Just return if it is
setup_cmd_window_datetime_editor_date_digit2_update:
	ld	a, (var_setup_editor_temp1)				; Get number to update
	and	0xf0							; Strip second digit
	or	b							; Combine with new digit
	ret	z							; If the combined value is zero, return
	ld	(var_setup_editor_temp1), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_date_digit3:
	ld	a, b							; Get digit value
	cp	2							; Check if value greater than 1
	ret	nc							; Just return if it is
	sla	a							; Shift to upper nibble
	sla	a
	sla	a
	sla	a
	ld	b, a							; Save value

	ld	a, (var_setup_editor_temp2)				; Get number to update
	and	0x0f							; Strip first digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp2), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_date_digit4:
	ld	a, (var_setup_editor_temp2)				; Check first digit
	srl	a							; Upper nibble to lower
	srl	a
	srl	a
	srl	a
	cp	1							; Check if first digit is 1
	jr	nz, setup_cmd_window_datetime_editor_date_digit4_update
	ld	a, b
	cp	3							; Check if value greater than 2
	ret	nc							; Just return if it is
setup_cmd_window_datetime_editor_date_digit4_update:
	ld	a, (var_setup_editor_temp2)				; Get number to update
	and	0xf0							; Strip second digit
	or	b							; Combine with new digit
	ret	z							; If the combined value is zero, return
	ld	(var_setup_editor_temp2), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_date_digit5:
	ld	a, b							; Get digit value
	sla	a							; Shift to upper nibble
	sla	a
	sla	a
	sla	a
	ld	b, a							; Save value

	ld	a, (var_setup_editor_temp3)				; Get number to update
	and	0x0f							; Strip first digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp3), a				; Save digit

	ld	a, (var_setup_selected_editor_index)			; Get current editor index
	inc	a
	ld	(var_setup_selected_editor_index), a			; Save current editor index
	ret
setup_cmd_window_datetime_editor_date_digit6:
	ld	a, (var_setup_editor_temp3)				; Get number to update
	and	0xf0							; Strip second digit
	or	b							; Combine with new digit
	ld	(var_setup_editor_temp3), a				; Save digit
	ret

; # setup_cmd_window_datetime_editor_time
; #################################
setup_cmd_window_datetime_editor_time:
	ld	a, setup_cmd_window_datetime_item_time
	ld	(var_setup_selected_editor), a				; Set selected editor
	xor	a
	ld	(var_setup_selected_editor_index), a			; Reset editor index

	ld	a, (var_setup_time_hour)				; Copy value to edit
	ld	(var_setup_editor_temp1), a
	ld	a, (var_setup_time_minute)
	ld	(var_setup_editor_temp2), a
	ld	a, (var_setup_time_second)
	ld	(var_setup_editor_temp3), a

	ld	iy, setup_cmd_window_datetime_editor_time_table
	call	setup_cmd_window_datetime_editor
	ret	nc							; Just exit if escape pressed

	ld	a,(var_setup_editor_temp1)				; Copy editor value back
	ld	(var_setup_time_hour), a
	ld	a, (var_setup_editor_temp2)
	ld	(var_setup_time_minute), a
	ld	a, (var_setup_editor_temp3)
	ld	(var_setup_time_second), a

	ld	bc, (var_setup_time_second)				; Load registers
	ld	de, (var_setup_time_hour)
	ld	hl, (var_setup_date_month)
	call	nc100_rtc_datetime_set					; Set Date/Time

	ret

; # setup_cmd_window_datetime_editor_date
; #################################
setup_cmd_window_datetime_editor_date:
	ld	a, setup_cmd_window_datetime_item_date
	ld	(var_setup_selected_editor), a				; Set selected editor
	xor	a
	ld	(var_setup_selected_editor_index), a			; Reset editor index

	ld	a, (var_setup_date_day)					; Copy value to edit
	ld	(var_setup_editor_temp1), a
	ld	a, (var_setup_date_month)
	ld	(var_setup_editor_temp2), a
	ld	a, (var_setup_date_year)
	ld	(var_setup_editor_temp3), a

	ld	iy, setup_cmd_window_datetime_editor_date_table
	call	setup_cmd_window_datetime_editor
	ret	nc							; Just exit if escape pressed

	ld	a,(var_setup_editor_temp1)				; Copy editor value back
	ld	(var_setup_date_day), a
	ld	a, (var_setup_editor_temp2)
	ld	(var_setup_date_month), a
	ld	a, (var_setup_editor_temp3)
	ld	(var_setup_date_year), a

	call	math_bcd_2_hex						; Convert from BCD
setup_cmd_window_datetime_editor_date_leap_loop:
	cp	0x04
	jr	c, setup_cmd_window_datetime_editor_date_leap_set
	sub	0x04
	jr	setup_cmd_window_datetime_editor_date_leap_loop
setup_cmd_window_datetime_editor_date_leap_set:
	ld	c, a							; Set the leap year digits
	call	nc100_rtc_leap_year_set

	ld	bc, (var_setup_time_second)				; Load registers
	ld	de, (var_setup_time_hour)
	ld	hl, (var_setup_date_month)
	call	nc100_rtc_datetime_set					; Set Date/Time

	ret

; # setup_cmd_window_datetime_editor_alarm_time
; #################################
setup_cmd_window_datetime_editor_alarm_time:
	ld	a, setup_cmd_window_datetime_item_alarm_time
	ld	(var_setup_selected_editor), a				; Set selected editor
	xor	a
	ld	(var_setup_selected_editor_index), a			; Reset editor index

	ld	a, (var_setup_alarm_hour)				; Copy value to edit
	ld	(var_setup_editor_temp1), a
	ld	a, (var_setup_alarm_minute)
	ld	(var_setup_editor_temp2), a
	xor	a							; No seconds on the alarm
	ld	(var_setup_editor_temp3), a

	ld	iy, setup_cmd_window_datetime_editor_time_table
	call	setup_cmd_window_datetime_editor
	ret	nc							; Just exit if escape pressed

	ld	a, (var_setup_editor_temp1)				; Copy editor value back
	ld	(var_setup_alarm_hour), a
	ld	a, (var_setup_editor_temp2)
	ld	(var_setup_alarm_minute), a

	ld	de, (var_setup_alarm_minute)
	call	nc100_rtc_alarm_set					; Set alarm time

	ret

; # Console window
; ##################################################
; # setup_cmd_window_console_draw
; #################################
setup_cmd_window_console_draw:
	call	setup_cmd_set_attributes_inverted
	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x080e						; Initial position (14,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid

	ld	hl, str_setup_console
	call	print_str_simple

	ret

; # setup_cmd_window_console_update
; #################################
setup_cmd_window_console_update:
	ret

; # setup_cmd_window_console_edit
; #################################
setup_cmd_window_console_edit:
	ret

; # Serial window
; ##################################################
setup_cmd_window_serial_item_baud:		equ		0x00
setup_cmd_window_serial_item_char_len:		equ		0x01
setup_cmd_window_serial_item_parity:		equ		0x02
setup_cmd_window_serial_item_stopbits:		equ		0x03
setup_cmd_window_serial_item_always:		equ		0x04

; # setup_cmd_window_serial_draw
; #################################
setup_cmd_window_serial_draw:
	call	setup_cmd_set_attributes_inverted
	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x1029						; Initial position (41,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_enabled
	call	print_str_simple
	ld	hl, str_checkbox
	call	print_str_simple
	ld	de, 0x1015						; Initial position (21,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_baud
	call	print_str_simple
	ld	de, 0x1813						; Initial position (19,24)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_length
	call	print_str_simple
	ld	de, 0x2013						; Initial position (19,32)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_parity
	call	print_str_simple
	ld	de, 0x2810						; Initial position (16,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_stopbit
	call	print_str_simple
	ret

; # setup_cmd_window_serial_update
; #################################
setup_cmd_window_serial_update:
	call	setup_cmd_set_attributes_inverted

setup_cmd_window_serial_update_baud:
	ld	de, 0x101b						; Initial position (27,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_serial_item_baud
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (nc100_config_uart_baud)				; Get baud
	and	0x0f							; Filter bits
	inc	a							; Convert index to count
	ld	b, a
	ld	hl, str_baud_150-0x06					; String table base
	ld	de, 0x0006
setup_cmd_window_serial_update_baud_offset_loop:			; Calculate offset
	add	hl, de
	djnz	setup_cmd_window_serial_update_baud_offset_loop
	call	print_str_simple

setup_cmd_window_serial_update_char_len:
	ld	de, 0x181b						; Initial position (27,24)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_serial_item_char_len
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (nc100_config_uart_mode)				; Get current UART mode
	and	0x0c							; Filter bits
	rrc	a							; Rotate to zero
	rrc	a
	add	a, '5'							; Create character
	call	monlib_console_out

setup_cmd_window_serial_update_parity:
	ld	de, 0x201b						; Initial position (27,32)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_serial_item_parity
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (nc100_config_uart_mode)				; Get current UART mode
	and	0x30							; Filter bits
	cp	uPD71051_reg_mode_parity_none
	ld	hl, str_none
	jr	z, setup_cmd_window_serial_update_parity_print
	cp	uPD71051_reg_mode_parity_odd
	ld	hl, str_odd
	jr	z, setup_cmd_window_serial_update_parity_print
	cp	uPD71051_reg_mode_parity_even
	ld	hl, str_even
	jr	z, setup_cmd_window_serial_update_parity_print
	ld	hl, str_unknown
setup_cmd_window_serial_update_parity_print:
	call	print_str_simple

setup_cmd_window_serial_update_stopbit:
	ld	de, 0x281b						; Initial position (27,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_serial_item_stopbits
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (nc100_config_uart_mode)				; Get current UART mode
	and	0xc0							; Filter bits
	cp	uPD71051_reg_mode_stopbit_1
	ld	hl, str_sb_1
	jr	z, setup_cmd_window_serial_update_stopbit_print
	cp	uPD71051_reg_mode_stopbit_15
	ld	hl, str_sb_15
	jr	z, setup_cmd_window_serial_update_stopbit_print
	cp	uPD71051_reg_mode_stopbit_2
	ld	hl, str_sb_2
	jr	z, setup_cmd_window_serial_update_stopbit_print
	ld	hl, str_unknown
setup_cmd_window_serial_update_stopbit_print:
	call	print_str_simple

setup_cmd_window_serial_update_enabled:
	ld	de, 0x1032						; Initial position (50,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_serial_item_always
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (nc100_config_uart_baud)				; Get enabled status
	bit	nc100_config_uart_baud_always, a
	ld	a, ' '
	jr	z, setup_cmd_window_serial_update_enabled_print
	ld	a, 'X'
setup_cmd_window_serial_update_enabled_print:
	call	monlib_console_out

setup_cmd_window_serial_update_finish:
	ret

; # setup_cmd_window_serial_edit
; #################################
setup_cmd_window_serial_edit:
	call	setup_cmd_window_serial_update				; Update pane

setup_cmd_window_serial_edit_check_key:
	call	nc100_keyboard_char_in					; Check for key press
	jr	nc, setup_cmd_window_serial_edit			; Just loop if no key
setup_cmd_window_serial_edit_check_key_up:
	cp	character_code_up					; Check if up
	jr	nz, setup_cmd_window_serial_edit_check_key_down
	ld	a, (var_setup_selected_item)				; Get selected index
	and	a							; Check if zero
	jr	z, setup_cmd_window_serial_edit				; If already zero, just loop
	dec	a							; Index--
	ld	(var_setup_selected_item), a				; Save selected index
	jr	setup_cmd_window_serial_edit				; Loop
setup_cmd_window_serial_edit_check_key_down:
	cp	character_code_down					; Check if down
	jr	nz, setup_cmd_window_serial_edit_check_key_left
	ld	a, (var_setup_selected_item)				; Get selected index
	cp	4
	jr	z, setup_cmd_window_serial_edit				; If on last screen, just loop
	inc	a							; Index++
	ld	(var_setup_selected_item), a				; Save selected index
	jr	setup_cmd_window_serial_edit				; Loop
setup_cmd_window_serial_edit_check_key_left:
	cp	character_code_left					; Check if left
	jr	nz, setup_cmd_window_serial_edit_check_key_space
	ld	a, (var_setup_selected_item)				; Get selected index
	ld	hl, setup_cmd_window_serial_edit			; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_window_serial_item_baud
	jp	z, nc100_serial_baud_dec
	cp	setup_cmd_window_serial_item_char_len
	jp	z, nc100_serial_character_length_dec
	cp	setup_cmd_window_serial_item_parity
	jp	z, nc100_serial_parity_dec
	cp	setup_cmd_window_serial_item_stopbits
	jp	z, nc100_serial_stopbits_dec
	cp	setup_cmd_window_serial_item_always
	jp	z, nc100_serial_always_toggle
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_serial_edit_check_key_space:
	cp	' '							; Check if space
	jr	nz, setup_cmd_window_serial_edit_check_key_right
	jr	setup_cmd_window_serial_edit_check_key_right_do
setup_cmd_window_serial_edit_check_key_right:
	cp	character_code_right					; Check if right
	jr	nz, setup_cmd_window_serial_edit_check_key_exit
setup_cmd_window_serial_edit_check_key_right_do:
	ld	a, (var_setup_selected_item)				; Get selected index
	ld	hl, setup_cmd_window_serial_edit			; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_window_serial_item_baud
	jp	z, nc100_serial_baud_inc
	cp	setup_cmd_window_serial_item_char_len
	jp	z, nc100_serial_character_length_inc
	cp	setup_cmd_window_serial_item_parity
	jp	z, nc100_serial_parity_inc
	cp	setup_cmd_window_serial_item_stopbits
	jp	z, nc100_serial_stopbits_inc
	cp	setup_cmd_window_serial_item_always
	jp	z, nc100_serial_always_toggle
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_serial_edit_check_key_exit:
	cp	character_code_escape
	jp	nz, setup_cmd_window_serial_edit

	ld	a, 0xff
	ld	(var_setup_selected_item), a				; Reset selected item
	ret

; # Status window
; ##################################################
; # setup_cmd_window_status_draw
; #################################
setup_cmd_window_status_draw:
	call	setup_cmd_set_attributes_inverted
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

; # setup_cmd_window_status_update
; #################################
setup_cmd_window_status_update:
	call	setup_cmd_set_attributes_inverted

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
	jr	z, setup_cmd_window_status_update_page_src_print
	add	hl, de							; Next string pointer
	dec	a
	jr	setup_cmd_window_status_update_page_src_str_loop
setup_cmd_window_status_update_page_src_print:
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
	jr	c, setup_cmd_window_status_update_memcard_battery_print
	ld	hl, str_failed
setup_cmd_window_status_update_memcard_battery_print:
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
	jr	c, setup_cmd_window_status_update_power_in_print
	ld	hl, str_poor
	call	nc100_power_check_in_gt_3v
	jr	c, setup_cmd_window_status_update_power_in_print
	ld	hl, str_failed
setup_cmd_window_status_update_power_in_print:
	call	print_str_simple
setup_cmd_window_status_update_power_backup:
	ld	de, 0x302f						; Initial position (47,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_okay
	call	nc100_power_check_battery_backup
	jr	c, setup_cmd_window_status_update_power_backup_print
	ld	hl, str_failed
setup_cmd_window_status_update_power_backup_print:
	call	print_str_simple
	ret

; # setup_cmd_window_status_edit
; #################################
setup_cmd_window_status_edit:
	ret

; ##################################################

; # setup_cmd_window_clear
; #################################
;  Clears the window (right hand pane)
setup_cmd_window_clear:
	ld	de, 0x080e						; Initial position (14,8)
	ld	l, 0
	call	setup_cmd_set_attributes_inverted
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

; # setup_cmd_selector_print
; #################################
;  Print the window selector
setup_cmd_selector_print:
setup_cmd_selector_print_datetime:
	ld	a, (var_setup_selected_config)
	and	0x7f
	cp	0
	call	z, setup_cmd_set_attributes_normal
	call	nz, setup_cmd_set_attributes_inverted
	ld	de, 0x0802
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,8)
	ld	hl, str_setup_datetime
	call	print_str_simple

setup_cmd_selector_print_console:
	ld	a, (var_setup_selected_config)
	and	0x7f
	cp	1
	call	z, setup_cmd_set_attributes_normal
	call	nz, setup_cmd_set_attributes_inverted
	ld	de, 0x1002
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,16)
	ld	hl, str_setup_console
	call	print_str_simple

setup_cmd_selector_print_serial:
	ld	a, (var_setup_selected_config)
	and	0x7f
	cp	2
	call	z, setup_cmd_set_attributes_normal
	call	nz, setup_cmd_set_attributes_inverted
	ld	de, 0x1802
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,24)
	ld	hl, str_setup_serial
	call	print_str_simple

setup_cmd_selector_print_status:
	ld	a, (var_setup_selected_config)
	and	0x7f
	cp	3
	call	z, setup_cmd_set_attributes_normal
	call	nz, setup_cmd_set_attributes_inverted
	ld	de, 0x2002
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,32)
	ld	hl, str_setup_status
	call	print_str_simple

	ret

; # setup_cmd_border_print
; #################################
;  Prints the border for the setup interface
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

; # setup_cmd_set_attributes_normal
; #################################
setup_cmd_set_attributes_normal:
	xor	a
	call	nc100_lcd_set_attributes				; No scroll
	ret

; # setup_cmd_set_attributes_inverted
; #################################
setup_cmd_set_attributes_inverted:
	ld	a, nc100_draw_attrib_invert_mask
	call	nc100_lcd_set_attributes				; No scroll, inverted
	ret


; # Variables
; #################################
setup_cmd_screens_max:			equ		0x04			; Number of different screens
var_setup_selected_config:		db		0x80			; msb set to force redraw
var_setup_selected_item:		db		0xff
var_setup_selected_editor:		db		0xff
var_setup_selected_editor_index:	db		0x00

var_setup_time_second:			db		0x00
var_setup_time_minute:			db		0x00
var_setup_time_hour:			db		0x00
var_setup_date_day:			db		0x00
var_setup_date_month:			db		0x00
var_setup_date_year:			db		0x00
var_setup_alarm_minute:			db		0x00
var_setup_alarm_hour:			db		0x00

var_setup_editor_temp1:			db		0x00
var_setup_editor_temp2:			db		0x00
var_setup_editor_temp3:			db		0x00

; # Strings
; #################################
str_setup_border_top:			db		0x01,0xc9,0x0c,0xcd,0x01,0xcb,0x2d,0xcd,0x01,0xbb,0x00
str_setup_border_middle:		db		0x01,0xba,0x0c,0x20,0x01,0xba,0x2d,0x20,0x01,0xba,0x00
str_setup_border_bottom:		db		0x01,0xc8,0x0c,0xcd,0x01,0xca,0x2d,0xcd,0x01,0xbc,0x00

str_setup_status_mem_top:		db		0x01,0xda,0x09,0xc4,0x01,0xc2,0x09,0xc4,0x01,0xc2,0x09,0xc4,0x01,0xc2,0x09,0xc4,0x01,0xbf,0x00
str_setup_status_mem_middle:		db		0x01,0xb3,0x09,0x20,0x01,0xb3,0x09,0x20,0x01,0xb3,0x09,0x20,0x01,0xb3,0x09,0x20,0x01,0xb3,0x00
str_setup_status_mem_bottom:		db		0x01,0xc0,0x09,0xc4,0x01,0xc1,0x09,0xc4,0x01,0xc1,0x09,0xc4,0x01,0xc1,0x09,0xc4,0x01,0xd9,0x00

str_setup_datetime:			db		"Date/Time",0
str_setup_console:			db		" Console ",0
str_setup_serial:			db		"  Serial ",0
str_setup_status:			db		"  Status ",0

str_current:				db		"Current",0
str_time:				db		"Time:   :  ",0
str_date:				db		"Date:   /  /  ",0
str_clk_format:				db		"Format:    hour",0
str_format_12:				db		"12",0
str_format_24:				db		"24",0
str_alarm:				db		"Alarm",0

str_enabled:				db		"Enabled",0
str_checkbox:				db		" [ ]",0

str_baud:				db		"Baud:",0
; Baud string packed to the same length
str_baud_150:				db		"150  ",0
str_baud_300:				db		"300  ",0
str_baud_600:				db		"600  ",0
str_baud_1200:				db		"1200 ",0
str_baud_2400:				db		"2400 ",0
str_baud_4800:				db		"4800 ",0
str_baud_9600:				db		"9600 ",0
str_baud_19200:				db		"19200",0
str_baud_38400:				db		"38400",0

str_length:				db		"Length:",0
str_parity:				db		"Parity:",0
str_stopbit:				db		"Stop Bits:",0

str_none:				db		"None",0
str_odd:				db		"Odd ",0
str_even:				db		"Even",0
str_unknown:				db		"Unknown",0

str_sb_1:				db		"1  ",0
str_sb_15:				db		"1.5",0
str_sb_2:				db		"2  ",0

str_memtype_rom:			db		" ROM",0
str_memtype_ram:			db		" RAM",0
str_memtype_cram:			db		"CRAM",0

str_memory_card:			db		"Memory Card:",0
str_backup:				db		"Backup:",0
str_battery:				db		"Battery:",0
str_power_in:				db		"Power In: ",0
str_present:				db		"Present",0
str_missing:				db		"Missing",0
str_okay:				db		"Okay",0
str_poor:				db		"Poor",0
str_failed:				db		"Failed",0
str_na:					db		"N/A",0
