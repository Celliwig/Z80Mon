; # Configuration program (Panel: Status)
; ###########################################################################
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
