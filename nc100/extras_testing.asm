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
; This test prints the contents of the various keyboard variables
; And also prints the keycode
keyboard_test1:
	call	nc100_lcd_clear_screen					; Clear screen
keyboard_test1_loop:
	ld	de, 0x0							; Reset cursor position
	ld	l, 0x0
	call	nc100_lcd_set_cursor_by_grid

	ld	hl, str_keybd_raw
	call	print_str
	ld	a, (nc100_keyboard_raw_keycode)
	call	print_hex8
	call	print_spacex2
	ld	a, (nc100_keyboard_raw_keycode_prev)
	call	print_hex8
	call	print_newline

	ld	hl, str_keybd_control
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

	call	print_newline
	ld	hl, str_keybd_keycode
	call	nc100_keyboard_char_in
	call	print_hex8

	call	keyboard_test_select

	jp	keyboard_test1_loop

; This test prints a keypress to the screen
keyboard_test2:
	call	nc100_lcd_clear_screen
keyboard_test2_loop:
	call	nc100_keyboard_char_in
	call	c, monlib_console_out

	call	keyboard_test_select
	jr	keyboard_test2_loop

keyboard_test_select:
	ld	a, (nc100_keyboard_raw_control)
	and	key_combo_exit
	cp	key_combo_exit
	jr	z, keyboard_test_select_exit

	ld	a, (nc100_keyboard_raw_control)
	and	key_combo_test1
	cp	key_combo_test1
	jr	z, keyboard_test_select_test1

	ld	a, (nc100_keyboard_raw_control)
	and	key_combo_test2
	cp	key_combo_test2
	jr	z, keyboard_test_select_test2

	ret
keyboard_test_select_test1:
	pop	af						; Pop return address
	jp	keyboard_test1
keyboard_test_select_test2:
	pop	af						; Pop return address
	jp	keyboard_test2
keyboard_test_select_exit:
	pop	af						; Pop first return address
	call	print_newline
	ret

str_keybd_raw:		db	"Raw:     ",0
str_keybd_control:	db	"Control: ",0
str_keybd_state:	db	"State:   ",0
str_keybd_count:	db	"Count:   ",0
str_keybd_keycode:	db	"Keycode: ",0

key_combo_exit:		equ	(nc100_rawkey_control | nc100_rawkey_stop) & 0x7f
key_combo_test1:	equ	(nc100_rawkey_control | nc100_rawkey_shift) & 0x7f
key_combo_test2:	equ	(nc100_rawkey_control | nc100_rawkey_capslock) & 0x7f

; ###########################################################################
; #                                                                         #
; #                                RTC Test                                 #
; #                                                                         #
; ###########################################################################

orgmem  extras_cmd_base+0x0100
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	254,'2',0,0						; id (254=cmd)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"RTC Test",0

orgmem  extras_cmd_base+0x0140
rtc_test:
	call	nc100_lcd_clear_screen					; Clear screen
rtc_test_loop:
	ld	de, 0x0							; Reset cursor position
	ld	l, 0x0
	call	nc100_lcd_set_cursor_by_grid

	ld	hl, str_rtc_timedate
	call	print_str
	call	print_newline
	call	print_spacex2

	call	nc100_rtc_datetime_get
	ld	a, d
	call	print_dec8u						; Print hours
	ld	a, ':'
	call	monlib_console_out
	ld	a, c
	call	print_dec8u						; Print minutes
	ld	a, ':'
	call	monlib_console_out
	ld	a, b
	call	print_dec8u						; Print seconds

	call	print_spacex2

	ld	a, e
	call	print_dec8u
	ld	a, '/'
	call	monlib_console_out
	ld	a, h
	call	print_dec8u
	ld	a, '/'
	call	monlib_console_out
	ld	a, l
	call	print_dec8u

	ld	a, (nc100_keyboard_raw_control)
	and	nc100_rawkey_stop ^ 0x80
	cp	nc100_rawkey_stop ^ 0x80
	jr	nz, rtc_test_loop

	call	print_newline

	ret

str_rtc_timedate:	db	"Time/Date:",0

