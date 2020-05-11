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

rtc_test_key_set:
	; Check if function depressed
	; Set date/time if it is
	ld	a, (nc100_keyboard_raw_control)
	and	nc100_rawkey_function ^ 0x80
	cp	nc100_rawkey_function ^ 0x80
	jr	nz, rtc_test_key_ram

	; Set date/time
	ld	b, 0
	ld	c, 39
	ld	d, 17
	ld	e, 1
	ld	h, 2
	ld	l, 77
	call	nc100_rtc_datetime_set

rtc_test_key_ram:
	; Check if shift is depressed
	; Run RTC RAM routines
	ld	a, (nc100_keyboard_raw_control)
	and	nc100_rawkey_shift ^ 0x80
	cp	nc100_rawkey_shift ^ 0x80
	jr	nz, rtc_test_key_exit
rtc_test_key_ram_brkpt:
	ld	hl, rtc_test_ramblk1
	call	nc100_rtc_ram_check
	ld	hl, rtc_test_ramblk1
	call	nc100_rtc_ram_write
	ld	hl, rtc_test_ramblk1
	call	nc100_rtc_ram_check
	ld	hl, rtc_test_ramblk2
	call	nc100_rtc_ram_read

rtc_test_key_exit:
	; Check if escape depressed
	; Exit if it is
	ld	a, (nc100_keyboard_raw_control)
	and	nc100_rawkey_stop ^ 0x80
	cp	nc100_rawkey_stop ^ 0x80
	jp	nz, rtc_test_loop

	call	print_newline

	ret

str_rtc_timedate:	db	"Time/Date:",0
rtc_test_ramblk1:	db	"Hello World",0				; 12 bytes of storage to copy into RTC RAM
rtc_test_ramblk2:	ds	12, 0					; 12 bytes of storage to copy RTC RAM into

; ###########################################################################
; #                                                                         #
; #                                LCD Test                                 #
; #                                                                         #
; ###########################################################################

orgmem  extras_cmd_base+0x0200
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	254,'3',0,0						; id (254=cmd)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"LCD Test",0

orgmem  extras_cmd_base+0x0240
lcd_test:
	call	nc100_lcd_clear_screen					; Clear screen

	ld	b, 0xdf
	ld	a, ' '
lcd_test_print_loop:
	push	af
	call	monlib_console_out
	pop	af
	inc	a
	djnz	lcd_test_print_loop

lcd_test_key_exit:
	; Check if escape depressed
	; Exit if it is
	ld	a, (nc100_keyboard_raw_control)
	and	nc100_rawkey_stop ^ 0x80
	cp	nc100_rawkey_stop ^ 0x80
	jp	nz, lcd_test_key_exit

	call	print_newline

	ret

; ###########################################################################
; #                                                                         #
; #                            Dictionary Test                              #
; #                                                                         #
; ###########################################################################

orgmem  extras_cmd_base+0x0300
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	254,'4',0,0						; id (254=cmd)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"Dictionary Test",0

orgmem  extras_cmd_base+0x0340
dictionary_test:
	call	nc100_lcd_clear_screen					; Clear screen

	ld	hl, str_dictionary_test
	call	print_cstr

dictionary_test_key_exit:
	; Check if escape depressed
	; Exit if it is
	ld	a, (nc100_keyboard_raw_control)
	and	nc100_rawkey_stop ^ 0x80
	cp	nc100_rawkey_stop ^ 0x80
	jp	nz, dictionary_test_key_exit

	call	print_newline

	ret

str_dictionary_test:	db		235,236,237,238,239,240,241,13
			db		242,243,244,245,246,247,13
			db		248,249,250,251,252,253,254,255,14
