; # Configuration program (Main)
; ###########################################################################
;  Must start here
setup_cmd:
	ld	a, 0x80							; Initialise state variables
	ld	(var_setup_selected_config), a
	ld	a, 0xff
	ld	(var_setup_selected_item), a
	ld	(var_setup_selected_editor), a

	call	nc100_console_set_local
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
	cp	setup_cmd_config_datetime
	jp	z, setup_cmd_window_datetime_draw
	cp	setup_cmd_config_general
	jp	z, setup_cmd_window_general_draw
	cp	setup_cmd_config_serial
	jp	z, setup_cmd_window_serial_draw
	cp	setup_cmd_config_memory
	jp	z, setup_cmd_window_memory_draw
	cp	setup_cmd_config_status
	jp	z, setup_cmd_window_status_draw
	pop	af							; Should never reach here
									; So pop to re-align stack
setup_cmd_loop_update:
	ld	a, (var_setup_selected_config)				; Get index
	ld	hl, setup_cmd_loop_check_key				; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_config_datetime
	jp	z, setup_cmd_window_datetime_update
	cp	setup_cmd_config_general
	jp	z, setup_cmd_window_general_update
	cp	setup_cmd_config_serial
	jp	z, setup_cmd_window_serial_update
	cp	setup_cmd_config_memory
	jp	z, setup_cmd_window_memory_update
	cp	setup_cmd_config_status
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
	cp	setup_cmd_config_max					; Check if last screen
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
	cp	setup_cmd_config_datetime
	jp	z, setup_cmd_window_datetime_edit
	cp	setup_cmd_config_general
	jp	z, setup_cmd_window_general_edit
	cp	setup_cmd_config_serial
	jp	z, setup_cmd_window_serial_edit
	cp	setup_cmd_config_memory
	jp	z, setup_cmd_window_memory_edit
	cp	setup_cmd_config_status
	jp	z, setup_cmd_window_status_edit
	pop	af							; Should never reach here
									; So pop to re-align stack
setup_cmd_loop_check_key_exit:
	cp	character_code_escape
	jp	nz, setup_cmd_loop

	call	nc100_config_save_apply					; Save configuration, and apply
	call	nc100_lcd_clear_screen

	ret

; # Basic functions
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
	cp	setup_cmd_config_datetime
	call	z, setup_cmd_set_attributes_normal
	call	nz, setup_cmd_set_attributes_inverted
	ld	de, 0x0802
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,8)
	ld	hl, str_setup_datetime
	call	print_str_simple

setup_cmd_selector_print_general:
	ld	a, (var_setup_selected_config)
	and	0x7f
	cp	setup_cmd_config_general
	call	z, setup_cmd_set_attributes_normal
	call	nz, setup_cmd_set_attributes_inverted
	ld	de, 0x1002
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,16)
	ld	hl, str_setup_general
	call	print_str_simple

setup_cmd_selector_print_serial:
	ld	a, (var_setup_selected_config)
	and	0x7f
	cp	setup_cmd_config_serial
	call	z, setup_cmd_set_attributes_normal
	call	nz, setup_cmd_set_attributes_inverted
	ld	de, 0x1802
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,24)
	ld	hl, str_setup_serial
	call	print_str_simple

setup_cmd_selector_print_memory:
	ld	a, (var_setup_selected_config)
	and	0x7f
	cp	setup_cmd_config_memory
	call	z, setup_cmd_set_attributes_normal
	call	nz, setup_cmd_set_attributes_inverted
	ld	de, 0x2002
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,32)
	ld	hl, str_setup_memory
	call	print_str_simple

setup_cmd_selector_print_status:
	ld	a, (var_setup_selected_config)
	and	0x7f
	cp	setup_cmd_config_status
	call	z, setup_cmd_set_attributes_normal
	call	nz, setup_cmd_set_attributes_inverted
	ld	de, 0x2802
	ld	l, 0x00
	call	nc100_lcd_set_cursor_by_grid				; Set cursor (2,40)
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

; # Includes
; ##################################################
include	"nc100/setup_panel_datetime.asm"
include	"nc100/setup_panel_general.asm"
include	"nc100/setup_panel_serial.asm"
include	"nc100/setup_panel_memory.asm"
include	"nc100/setup_panel_status.asm"

; # Variables
; ##################################################
var_setup_selected_config:			db		0x80			; msb set to force redraw
var_setup_selected_item:			db		0xff
var_setup_selected_editor:			db		0xff
var_setup_selected_editor_index:		db		0x00

; # Defines
; ##################################################
setup_cmd_config_datetime:			equ		0x00
setup_cmd_config_general:			equ		0x01
setup_cmd_config_serial:			equ		0x02
setup_cmd_config_memory:			equ		0x03
setup_cmd_config_status:			equ		0x04
setup_cmd_config_max:				equ		0x04			; Number of different screens

str_setup_border_top:				db		0x01,0xc9,0x0c,0xcd,0x01,0xcb,0x2d,0xcd,0x01,0xbb,0x00
str_setup_border_middle:			db		0x01,0xba,0x0c,0x20,0x01,0xba,0x2d,0x20,0x01,0xba,0x00
str_setup_border_bottom:			db		0x01,0xc8,0x0c,0xcd,0x01,0xca,0x2d,0xcd,0x01,0xbc,0x00

str_setup_status_mem_top:			db		0x01,0xda,0x09,0xc4,0x01,0xc2,0x09,0xc4,0x01,0xc2,0x09,0xc4,0x01,0xc2,0x09,0xc4,0x01,0xbf,0x00
str_setup_status_mem_middle:			db		0x01,0xb3,0x09,0x20,0x01,0xb3,0x09,0x20,0x01,0xb3,0x09,0x20,0x01,0xb3,0x09,0x20,0x01,0xb3,0x00
str_setup_status_mem_bottom:			db		0x01,0xc0,0x09,0xc4,0x01,0xc1,0x09,0xc4,0x01,0xc1,0x09,0xc4,0x01,0xc1,0x09,0xc4,0x01,0xd9,0x00

str_setup_datetime:				db		"Date/Time",0
str_setup_general:				db		" General ",0
str_setup_serial:				db		"  Serial ",0
str_setup_memory:				db		"  Memory ",0
str_setup_status:				db		"  Status ",0

; General
str_battery:					db		"Battery:",0
str_current:					db		"Current",0
str_alarm:					db		"Alarm",0
str_enabled:					db		"Enabled",0
str_checkbox:					db		" [ ]",0
str_present:					db		"Present",0
str_missing:					db		"Missing",0
str_okay:					db		"Okay",0
str_poor:					db		"Poor",0
str_failed:					db		"Failed",0
str_na:						db		"N/A",0
