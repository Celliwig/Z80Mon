; ###########################################################################
; #                                                                         #
; #                             Keyboard Test                               #
; #                                                                         #
; ###########################################################################

orgmem  extras_cmd_base+0x0000
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	254,'1',0,0						; id (254=cmd)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"Keyboard Test",0

orgmem  extras_cmd_base+0x0040
keyboard_test:
	call	nc100_lcd_clear_screen					; Clear screen

keyboard_test_loop:
	ld	de, 0x0							; Reset cursor position
	ld	l, 0x0
	call	nc100_lcd_set_cursor_by_grid

	ld	hl, str_keybd_keycode
	call	print_str
	ld	a, (nc100_keyboard_raw_keycode)
	call	print_hex8
	call	print_spacex2
	ld	a, (nc100_keyboard_raw_keycode_prev)
	call	print_hex8
	call	print_newline

	ld	hl, str_keybd_raw
	call	print_str
	ld	a, (nc100_keyboard_raw_control)
	call	print_hex8
	call	print_spacex2
	ld	a, (nc100_keyboard_raw_control_prev)
	call	print_hex8
	call	print_newline

	ld	hl, str_keybd_state
	call	print_str
	ld	a, (nc100_keyboard_controller_state)
	call	print_hex8
	call	print_newline

	ld	hl, str_keybd_count
	call	print_str
	ld	a, (nc100_keyboard_raw_character_count)
	call	print_hex8
	call	print_newline

	ld	a, (nc100_keyboard_raw_control)
	and	nc100_key_stop | nc100_key_control | nc100_key_shift
	cp	nc100_key_stop | nc100_key_control | nc100_key_shift
	jr	nz, keyboard_test_loop

	ret

str_keybd_keycode:	db	"Keycode: ",0
str_keybd_raw:		db	"Raw:     ",0
str_keybd_state:	db	"State:   ",0
str_keybd_count:	db	"Count:   ",0
