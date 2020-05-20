; # Configuration program (Panel: Memory)
; ###########################################################################

; # Defines
; ##################################################
setup_cmd_window_memory_item_wait_states:	equ		0x00
setup_cmd_window_memory_item_max:		equ		0x00

str_memtype_rom:				db		" ROM",0
str_memtype_ram:				db		" RAM",0
str_memtype_cram:				db		"CARD",0

str_memory_card:				db		"Memory Card:",0
str_mc:						db		"MC ",0
str_gt_200ns:					db		">=200ns",0

; # Variables
; ##################################################


; # setup_cmd_window_memory_draw
; #################################
setup_cmd_window_memory_draw:
	call	setup_cmd_set_attributes_inverted
	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x0811						; Initial position (17,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, 0x0000
	call	print_hex16
	ld	de, 0x081b						; Initial position (27,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, 0x4000
	call	print_hex16
	ld	de, 0x0825						; Initial position (37,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, 0x8000
	call	print_hex16
	ld	de, 0x082f						; Initial position (47,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, 0xc000
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
	ld	de, 0x3010						; Initial position (16,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_mc
	call	print_str_simple
	ld	hl, str_battery
	call	print_str_simple
	ld	de, 0x282a						; Initial position (44,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_mc
	call	print_str_simple
	ld	hl, str_gt_200ns
	call	print_str_simple
	ld	hl, str_checkbox
	call	print_str_simple

	ret

; # setup_cmd_window_memory_update
; #################################
setup_cmd_window_memory_update:
	call	setup_cmd_set_attributes_inverted

setup_cmd_window_memory_update_page_src:
	ld	de, 0x1812						; Initial position (18,24)
	ld	l, 0
	ld	c, nc100_io_membank_A
setup_cmd_window_memory_update_page_src_loop:
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
setup_cmd_window_memory_update_page_src_str_loop:
	jr	z, setup_cmd_window_memory_update_page_src_print
	add	hl, de							; Next string pointer
	dec	a
	jr	setup_cmd_window_memory_update_page_src_str_loop
setup_cmd_window_memory_update_page_src_print:
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
	jr	nz, setup_cmd_window_memory_update_page_src_loop

setup_cmd_window_memory_update_memcard:
	call	nc100_memory_memcard_present
	jr	nc, setup_cmd_window_memory_update_memcard_missing
	ld	de, 0x281c						; Initial position (28,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_present
	call	print_str_simple
	ld	de, 0x301c						; Initial position (28,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_okay
	call	nc100_power_check_battery_memcard			; Check memory card battery status
	jr	c, setup_cmd_window_memory_update_memcard_battery_print
	ld	hl, str_failed
setup_cmd_window_memory_update_memcard_battery_print:
	call	print_str_simple
	jr	setup_cmd_window_memory_update_wait_states
setup_cmd_window_memory_update_memcard_missing:
	ld	de, 0x301c						; Initial position (28,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_missing
	call	print_str_simple
	ld	de, 0x301c						; Initial position (28,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_na
	call	print_str_simple

setup_cmd_window_memory_update_wait_states:
	ld	de, 0x2836						; Initial position (54,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_memory_item_wait_states
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (nc100_config_misc)					; Get wait states config
	bit	nc100_config_misc_memcard_wstates, a
	ld	a, ' '
	jr	z, setup_cmd_window_memory_update_wait_states_print
	ld	a, 'X'
setup_cmd_window_memory_update_wait_states_print:
	call	monlib_console_out

setup_cmd_window_memory_update_finish:
	ret

; # setup_cmd_window_memory_edit
; #################################
setup_cmd_window_memory_edit:
	call	setup_cmd_window_memory_update				; Update pane

setup_cmd_window_memory_edit_check_key:
	call	nc100_keyboard_char_in					; Check for key press
	jr	nc, setup_cmd_window_memory_edit			; Just loop if no key
setup_cmd_window_memory_edit_check_key_up:
	cp	character_code_up					; Check if up
	jr	nz, setup_cmd_window_memory_edit_check_key_down
	ld	a, (var_setup_selected_item)				; Get selected index
	and	a							; Check if zero
	jr	z, setup_cmd_window_memory_edit				; If already zero, just loop
	dec	a							; Index--
	ld	(var_setup_selected_item), a				; Save selected index
	jr	setup_cmd_window_memory_edit				; Loop
setup_cmd_window_memory_edit_check_key_down:
	cp	character_code_down					; Check if down
	jr	nz, setup_cmd_window_memory_edit_check_key_left
	ld	a, (var_setup_selected_item)				; Get selected index
	cp	setup_cmd_window_memory_item_max
	jr	z, setup_cmd_window_memory_edit				; If on last screen, just loop
	inc	a							; Index++
	ld	(var_setup_selected_item), a				; Save selected index
	jr	setup_cmd_window_memory_edit				; Loop
setup_cmd_window_memory_edit_check_key_left:
	cp	character_code_left					; Check if left
	jr	nz, setup_cmd_window_memory_edit_check_key_space
	ld	a, (var_setup_selected_item)				; Get selected index
	ld	hl, setup_cmd_window_memory_edit			; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_window_memory_item_wait_states
	jp	z, nc100_config_misc_memcard_wstates_toggle
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_memory_edit_check_key_space:
	cp	' '							; Check if space
	jr	nz, setup_cmd_window_memory_edit_check_key_right
	jr	setup_cmd_window_memory_edit_check_key_right_do
setup_cmd_window_memory_edit_check_key_right:
	cp	character_code_right					; Check if right
	jr	nz, setup_cmd_window_memory_edit_check_key_exit
setup_cmd_window_memory_edit_check_key_right_do:
	ld	a, (var_setup_selected_item)				; Get selected index
	ld	hl, setup_cmd_window_memory_edit			; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_window_memory_item_wait_states
	jp	z, nc100_config_misc_memcard_wstates_toggle
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_memory_edit_check_key_exit:
	cp	character_code_escape
	jp	nz, setup_cmd_window_memory_edit

	ld	a, 0xff
	ld	(var_setup_selected_item), a				; Reset selected item
	ret

