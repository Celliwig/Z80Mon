; # Configuration program (Panel: General)
; ###########################################################################
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
