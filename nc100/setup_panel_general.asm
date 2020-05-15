; # Configuration program (Panel: General)
; ###########################################################################

; # Defines
; ##################################################
setup_cmd_window_general_item_console:		equ		0x00
setup_cmd_window_general_item_lcd_invert:	equ		0x01
setup_cmd_window_general_item_max:		equ		0x01

str_console:					db		"Console:",0
str_local:					db		"Local ",0
str_serial:					db		"Serial",0
str_lcd_invert:					db		"LCD Invert",0

; # Variables
; ##################################################

; # setup_cmd_window_general_draw
; #################################
setup_cmd_window_general_draw:
	call	setup_cmd_set_attributes_inverted
	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x100f						; Initial position (18,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_console
	call	print_str_simple
	ld	de, 0x200f						; Initial position (15,32)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_lcd_invert
	call	print_str_simple
	ld	hl, str_checkbox
	call	print_str_simple
	ret

; # setup_cmd_window_general_update
; #################################
setup_cmd_window_general_update:
	call	setup_cmd_set_attributes_inverted

setup_cmd_window_general_update_console:
	ld	de, 0x1018						; Initial position (24,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_general_item_console
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (nc100_config_misc)					; Get console selection
	bit	nc100_config_misc_console, a
	ld	hl, str_local
	jr	z, setup_cmd_window_general_update_console_print
	ld	hl, str_serial
setup_cmd_window_general_update_console_print:
	call	print_str_simple

setup_cmd_window_general_update_lcd_invert:
	ld	de, 0x201b						; Initial position (27,32)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	a, (var_setup_selected_item)				; Is this the selected item
	cp	setup_cmd_window_general_item_lcd_invert
	call	z,setup_cmd_set_attributes_normal			; Set attributes appropriately
	call	nz,setup_cmd_set_attributes_inverted
	ld	a, (nc100_config_draw_attributes)			; Get LCD inverted state
	bit	nc100_draw_attrib_invert_bit, a
	ld	a, ' '
	jr	z, setup_cmd_window_general_update_lcd_invert_print
	ld	a, 'X'
setup_cmd_window_general_update_lcd_invert_print:
	call	monlib_console_out

	ret

; # setup_cmd_window_general_edit
; #################################
setup_cmd_window_general_edit:
	call	setup_cmd_window_general_update				; Update pane

setup_cmd_window_general_edit_check_key:
	call	nc100_keyboard_char_in					; Check for key press
	jr	nc, setup_cmd_window_general_edit			; Just loop if no key
setup_cmd_window_general_edit_check_key_up:
	cp	character_code_up					; Check if up
	jr	nz, setup_cmd_window_general_edit_check_key_down
	ld	a, (var_setup_selected_item)				; Get selected index
	and	a							; Check if zero
	jr	z, setup_cmd_window_general_edit			; If already zero, just loop
	dec	a							; Index--
	ld	(var_setup_selected_item), a				; Save selected index
	jr	setup_cmd_window_general_edit				; Loop
setup_cmd_window_general_edit_check_key_down:
	cp	character_code_down					; Check if down
	jr	nz, setup_cmd_window_general_edit_check_key_left
	ld	a, (var_setup_selected_item)				; Get selected index
	cp	setup_cmd_window_general_item_max
	jr	z, setup_cmd_window_general_edit			; If on last screen, just loop
	inc	a							; Index++
	ld	(var_setup_selected_item), a				; Save selected index
	jr	setup_cmd_window_general_edit				; Loop
setup_cmd_window_general_edit_check_key_left:
	cp	character_code_left					; Check if left
	jr	nz, setup_cmd_window_general_edit_check_key_space
	ld	a, (var_setup_selected_item)				; Get selected index
	ld	hl, setup_cmd_window_general_edit			; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_window_general_item_console
	jp	z, nc100_config_misc_console_toggle
	cp	setup_cmd_window_general_item_lcd_invert
	jp	z, nc100_config_draw_attrib_invert_toggle
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_general_edit_check_key_space:
	cp	' '							; Check if space
	jr	nz, setup_cmd_window_general_edit_check_key_right
	jr	setup_cmd_window_general_edit_check_key_right_do
setup_cmd_window_general_edit_check_key_right:
	cp	character_code_right					; Check if right
	jr	nz, setup_cmd_window_general_edit_check_key_exit
setup_cmd_window_general_edit_check_key_right_do:
	ld	a, (var_setup_selected_item)				; Get selected index
	ld	hl, setup_cmd_window_general_edit			; Push return address
	push	hl							; For the following jumps
	cp	setup_cmd_window_general_item_console
	jp	z, nc100_config_misc_console_toggle
	cp	setup_cmd_window_general_item_lcd_invert
	jp	z, nc100_config_draw_attrib_invert_toggle
	ret								; Should never reach here
									; So pop to re-align stack
setup_cmd_window_general_edit_check_key_exit:
	cp	character_code_escape
	jp	nz, setup_cmd_window_general_edit

	ld	a, 0xff
	ld	(var_setup_selected_item), a				; Reset selected item
	ret
