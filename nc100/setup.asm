; # Configuration program (Main)
; ###########################################################################
;  Must start here
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

; # Includes
; ##################################################
include	"nc100/setup_panel_datetime.asm"
include	"nc100/setup_panel_general.asm"
include	"nc100/setup_panel_serial.asm"
include	"nc100/setup_panel_status.asm"

; # Variables
; ##################################################
