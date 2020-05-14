; # Configuration program (Panel: Date/Time)
; ###########################################################################
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
