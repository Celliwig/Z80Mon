; # Flash tool
; ###########################################################################

; ###########################################################################
; #                                                                         #
; #                          Simple Flash Tool                              #
; #                                                                         #
; ###########################################################################

orgmem  extras_cmd_base+0x0000
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	254,')',0,0						; id (254=cmd)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"Flash Tool",0

orgmem  extras_cmd_base+0x0040
flash_tool:
	ld	c, flash_tool_ROM_bank
	call	nc100_memory_page_get
	ld	(var_ft_rom_bank_config_old), bc			; Save current memory bank config

	call	print_newline

	ld	hl, str_ft_device					; Print device ID
	call	print_str_simple
	call	flash_device_get_id
	ex	de, hl
	call	print_hex16
	call	print_newline

	ld	hl, str_ft_select_page					; Get the desired page to flash
	call	print_str_simple
	call	input_hex8
	jp	nc, flash_tool_finish					; Aborted entry
	call	print_newline

	ld	b, e							; Save selected page
	ld	a, b							; Check page selection
	and	0x3f							; Make sure it's within the desired range
	cp	b							; And make sure it's what we entered
	jr	z, flash_tool_actual_confirm				; Values are the same so continue
	ld	hl, str_ft_err_page
	jr	flash_tool_finish_result_print
flash_tool_actual_confirm:
	push	bc							; Save ROM page

	ld	hl, str_ft_confirm					; Confirm we want to flash page
	call	print_str_simple
	call	input_character_filter					; Get response
	call	char_2_upper
	ld	c, a
	call	monlib_console_out
	call	print_newline
	ld	a, c
	cp	'Y'
	jr	nz, flash_tool_finish_pop				; Check choice

	ld	hl, str_ft_erasing_page
	call	print_str_simple
	pop	bc							; Restore ROM page
	push	bc							; Save ROM page
	ld	a, b
	call	print_hex8
	call	print_colon_space
	pop	bc							; Restore ROM page
	push	bc							; Save ROM page
	call	flash_device_erase_page					; Erase page
	ld	hl, str_ft_failed
	jr	nc, flash_tool_finish_fail_print_pop			; Erase failed to finish
	ld	hl, str_okay
	call	print_str_simple
	call	print_newline

	ld	hl, str_ft_flashing_page
	call	print_str_simple
	pop	bc							; Restore ROM page
	push	bc							; Save ROM page
	ld	a, b
	call	print_hex8
	call	print_colon_space
	pop	bc							; Restore ROM page
	ld	de, 0x0000						; Copy from offset 0x0000
	ld	hl, 0x4000						; Copy 16k of data
	call	flash_tool_flash_ram_2_rom				; Copy RAM 2 ROM
	ld	hl, str_ft_failed
	jr	nc, flash_tool_finish_result_print
	ld	hl, str_okay
	call	print_str_simple
	call	print_newline
	ld	hl, str_ft_verifying
	call	print_str_simple
	ld	bc, 0x4000
	ld	de, flash_tool_RAM_bank_offset
	ld	hl, flash_tool_ROM_bank_offset
	call	memory_copy_verify
	ld	hl, str_failed
	jr	nc, flash_tool_finish_result_print
	ld	hl, str_okay
flash_tool_finish_result_print:
	call	print_str_simple
flash_tool_finish:
	ld	bc, (var_ft_rom_bank_config_old)			; Restore original memory config
	call	nc100_memory_page_set

	call	print_newline
	ret
flash_tool_finish_fail_print_pop:
	call	print_str_simple
flash_tool_finish_pop:
	pop	bc							; This has been saved earlier
	jr	flash_tool_finish

; # flash_tool_flash_ram_2_rom
; #################################
;  Copies a number of bytes from RAM to the specified ROM page
;	In:	B = ROM page to program (4-0 / A18-A14)
;		DE = Offset address to copy from (within 16k block)
;		HL = Number of bytes to copy
;	Out:	Carry flag set if operation sucessful, unset on error
flash_tool_flash_ram_2_rom:
	xor	a						; Clear A
	or	h						; Check whether byte count >0
	or	l
	jr	z, flash_tool_flash_ram_2_rom_failed		; Byte count zero, so fail
flash_tool_flash_ram_2_rom_read_loop:
	push	hl						; Store byte count
	push	bc						; Save ROM page
	ld	hl, flash_tool_RAM_bank_offset
	add	hl, de						; Add offset to RAM address
	ld	a, (hl)						; Get next byte
	call	flash_device_program_byte			; Write byte
	pop	bc						; Restore ROM page
	pop	hl						; Restore byte count
	jr	nc, flash_tool_flash_ram_2_rom_failed		; Write failed, so fail
	dec	hl						; Decrement byte count
	xor	a						; Clear a
	or	h						; Check whether num. bytes >0
	or	l
	jr	z, flash_tool_flash_page_from_ram_finish	; No more bytes to copy, finish
	inc	de						; Increment address
	ld	a, d						; Check for overrun
	cp	0x40
	jr	z, flash_tool_flash_ram_2_rom_failed		; Overrun 16k boundary
	jr	flash_tool_flash_ram_2_rom_read_loop		; Loop
flash_tool_flash_page_from_ram_finish:
	scf							; Set Carry flag
	ret
flash_tool_flash_ram_2_rom_failed:
	scf							; Clear Carry flag
	ccf
	ret

; # Basic functions
; ##################################################

; # flash_device_send_command
; #################################
;  Sends the command register select sequence
flash_device_send_command:
	ld	b, nc100_membank_ROM|nc100_membank_0k			; Select ROM page 0
	ld	c, flash_tool_ROM_bank
	call	nc100_memory_page_set
flash_device_send_command_no_setup:
	ld	hl, flash_tool_ROM_bank_offset+flash_command_reg_addr1	; Command register enable address 1
	ld	a, flash_command_reg_enable1				; Command register enable command byte 1
	ld	(hl), a

	ld	hl, flash_tool_ROM_bank_offset+flash_command_reg_addr2	; Command register enable address 2
	ld	a, flash_command_reg_enable2				; Command register command byte 2
	ld	(hl), a

	ld	hl, flash_tool_ROM_bank_offset+flash_command_reg_addr1	; Command register enable address 1

	ret

; # flash_device_reset
; #################################
;  Resets the flash device back to read operation
flash_device_reset:
	call	flash_device_send_command
	ld	a, flash_command_reset					; Reset device operation
	ld	(hl), a
	ret

; # flash_device_get_id
; #################################
;  Gets the flash chip manufacturer/device ID
;	Out:	D = Manufacturer ID
;		E = Device ID
flash_device_get_id:
	call	flash_device_send_command
	ld	a, flash_command_autoselect				; Device/ID command
	ld	(hl), a
	ld	hl, flash_tool_ROM_bank_offset
	ld	d, (hl)							; Save manufacturer id
	inc	hl
	ld	e, (hl)							; Save device id
	call	flash_device_reset					; Reset the device back to read operation
	ret

; # flash_device_erase_page
; #################################
;  Erase a page of flash memory
;	In:	B = ROM page to erase (4-0 / A18-A14)
;	Out:	Carry flag set if operation sucessful, unset on error
flash_device_erase_page:
	push	bc							; Save ROM page
	call	flash_device_send_command
	ld	a, flash_command_erase					; Setup erase
	ld	(hl), a
	call	flash_device_send_command_no_setup
	pop	bc							; Restore ROM page
	ld	a, b							; Get ROM page to write
	and	31							; Make sure it's valid
	;or	nc100_membank_ROM					; Don't actually need to do this as it's 0x0
	ld	b, a
	ld	c, flash_tool_ROM_bank
	call	nc100_memory_page_set					; Select Flash ROM page to erase
	ld	hl, flash_tool_ROM_bank_offset				; Select first sector of page
	ld	a, flash_command_erase_sector				; Select sector erase
	ld	(hl), a
flash_device_erase_page_loop:
	ld	a, (hl)							; Get status
	bit	flash_status_command_finished, a
	jr	nz, flash_device_erase_page_finish			; Check whether this sector erase has finished
	bit	flash_status_command_time_limit_exceeded, a
	jr	nz, flash_device_erase_page_error			; Check whether the sector erase has timed out
	jr	flash_device_erase_page_loop
flash_device_erase_page_finish:
	scf								; Set Carry flag
	ret
flash_device_erase_page_error:
	scf								; Clear Carry flag
	ccf
	ret

; # flash_device_program_byte
; #################################
;  Program a byte of flash memory
;	In:	A = Byte to write
;		B = ROM page to program (4-0 / A18-A14)
;		DE = Address within 16k block
;	Out:	Carry flag set if operation sucessful, unset on error
flash_device_program_byte:
	ex	af, af'							; Swap byte out
	push	bc							; Save ROM page
	call	flash_device_send_command
	ld	a, flash_command_program				; Program byte
	ld	(hl), a
	pop	bc							; Restore ROM page
	ld	a, b							; Get ROM page to write
	and	31							; Make sure it's valid
	;or	nc100_membank_ROM					; Don't actually need to do this as it's 0x0
	ld	b, a
	ld	c, flash_tool_ROM_bank
	call	nc100_memory_page_set					; Select Flash ROM page to program
	ld	hl, flash_tool_ROM_bank_offset
	add	hl, de							; Add 16k offset to base address
	ex	af, af'							; Swap byte back in
	ld	c, a							; Save a copy of the byte
	ld	(hl), a							; Write byte
flash_device_program_byte_loop:
	ld	a, (hl)							; Check the status of the byte
	ld	b, a							; Copy status
	xor	c							; Check if it matches byte that was written
	jr	z, flash_device_program_byte_finish			; It matches, so finish
	bit	flash_status_command_time_limit_exceeded, b		; Check for a timeout
	jr	nz, flash_device_program_byte_error			; Timeout, so exit as error
	jr	flash_device_program_byte_loop				; Keep checking
flash_device_program_byte_finish:
	scf								; Set Carry flag
	ret
flash_device_program_byte_error:
	scf								; Clear Carry flag
	ccf
	ret

; # Includes
; ##################################################

; # Variables
; ##################################################
var_ft_rom_bank_config_old:			dw		0x0000			; Original memory bank configuration

; # Defines
; ##################################################
; Flash command enable
flash_command_reg_addr1:			equ		0x555
flash_command_reg_addr2:			equ		0x2aa
flash_command_reg_enable1:			equ		0xaa
flash_command_reg_enable2:			equ		0x55
; Flash commands
flash_command_reset:				equ		0xf0
flash_command_autoselect:			equ		0x90
flash_command_program:				equ		0xa0
flash_command_erase:				equ		0x80
flash_command_erase_all:			equ		0x10
flash_command_erase_sector:			equ		0x30
; Flash command status bits
flash_status_command_finished:			equ		7
flash_status_command_time_limit_exceeded:	equ		5

flash_tool_ROM_bank:				equ		nc100_io_membank_C	; Memory bank to use for ROM operations
flash_tool_ROM_bank_offset:			equ		0x8000
flash_tool_RAM_bank_offset:			equ		0x4000

;str_ft_err_con:					db		"This tool can only be run using a serial connection.", 0
str_ft_err_page:				db		"Incorrect page selected.", 0
str_ft_confirm:					db		"Confirm flash write [Y/N]: ", 0
str_ft_failed:					db		"Failed",0
str_ft_device:					db		"Device: ", 0
str_ft_select_page:				db		"Select Page To Flash: ", 0
str_ft_erasing_page:				db		"Erasing Page ", 0
str_ft_flashing_page:				db		"Flashing Page ", 0
str_ft_verifying:				db		"Verifying: ",0
