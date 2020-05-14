; # Configuration program (Panel: Serial)
; ###########################################################################
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
