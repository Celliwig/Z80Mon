; # Configuration program (Panel: Status)
; ###########################################################################

; # Defines
; ##################################################

str_power_supply:				db		"Power Supply:",0
str_input:					db		"Input:",0
str_backup:					db		"Backup ",0

str_version:					db		"Version:",0
str_monitor:					db		"Monitor: ",0
str_nc100_lib:					db		"NC100 Lib: ",0

; # Variables
; ##################################################


; # setup_cmd_window_status_draw
; #################################
setup_cmd_window_status_draw:
	call	setup_cmd_set_attributes_inverted
	call	setup_cmd_window_clear					; First clear any previous screen

	ld	de, 0x080f						; Initial position (15,8)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_version
	call	print_str_simple
	ld	de, 0x1014						; Initial position (20,16)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_monitor
	call	print_str_simple
	call	get_version
	call	print_version
	ld	de, 0x1814						; Initial position (20,24)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_nc100_lib
	call	print_str_simple
	call	nc100_get_version
	call	print_version
	ld	de, 0x200f						; Initial position (15,32)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_power_supply
	call	print_str_simple
	ld	de, 0x2814						; Initial position (20,40)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_input
	call	print_str_simple
	ld	de, 0x3014						; Initial position (20,48)
	ld	l, 0
	call	nc100_lcd_set_cursor_by_grid
	ld	hl, str_backup
	call	print_str_simple
	ld	hl, str_battery
	call	print_str_simple
	ret

; # setup_cmd_window_status_update
; #################################
setup_cmd_window_status_update:
	call	setup_cmd_set_attributes_inverted

setup_cmd_window_status_update_power_in:
	ld	de, 0x281b						; Initial position (27,40)
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
	ld	de, 0x3024						; Initial position (36,48)
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
