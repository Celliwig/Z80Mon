; # Configuration program (Main)
; ###########################################################################
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
