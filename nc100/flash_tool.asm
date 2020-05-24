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

	call	flash_device_get_id
	ex	de, hl
	call	print_hex16

	ld	bc, (var_ft_rom_bank_config_old)			; Restore original memory config
	call	nc100_memory_page_set

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
	call	flash_device_send_command
	ld	a, flash_command_erase					; Setup erase
	ld	(hl), a
	call	flash_device_send_command_no_setup
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


;; # Copied from OysterLib
;; #######################################
;; define latch addresses
;.equ    psen_page_latch, 0x08
;.equ    rdwr_page_latch, 0x0c
;
;.equ	base_addr, 0x8000					; Base address for all ROM command operations
;
;.equ	flash_tool_addr_fudge, (paulmon2+0x8000)&0xFFFF		; Fudge to allow code to run while being developed in RAM
;								; or run from ROM (which has been copied to RAM)
;
;; # flash_tool
;; #
;; # Copies the XRAM area 0x0000 to XRAM area 0x8000, with the selected
;; # flash ROM page mapped to this area.
;; ##########################################################################
;flash_tool:
;	lcall	oysterlib_newline
;
;	jnb	use_oysterlib, flash_tool_location_check	; Check whether we are using a serial link
;	mov	dptr, #str_ft_err_con				; If not, print error
;	lcall	pstr
;	lcall	oysterlib_newline
;	ret							; and exit
;
;flash_tool_location_check:
;	mov	dptr, #*					; Check whether we are running from ROM or a RAM dev version
;	mov	a, dph
;	cjne	a, #0x80, flash_tool_location_check_cmp
;flash_tool_location_check_cmp:
;	jnc	flash_tool_actual
;	mov	dptr, #str_ft_copy_rom
;	lcall	pstr
;	lcall	oysterlib_newline
;	lcall	flash_tool_copy_rom_to_ram			; Make a working copy of the ROM in RAM
;
;	setb	p1.0						; Select RAM on PSEN in 0x8000 area
;	setb	mem_mode_psen_ram
;	clr	p1.1
;	clr	mem_mode_psen_ram_card
;
;	mov	a, #0x03					; Select page 3 on access to 0x8000 area
;	mov	mem_page_psen, a
;	mov	dph, #psen_page_latch
;	setb	p1.4						; Enable address logic
;	movx	@dptr, a
;	clr	p1.4
;	ljmp	flash_tool_actual+flash_tool_addr_fudge		; Jump to copy in RAM
;
;flash_tool_actual:
;	mov	dptr, #str_ft_device+flash_tool_addr_fudge	; Print device ID
;	lcall	flash_tool_print_str+flash_tool_addr_fudge
;	lcall	flash_get_deviceid+flash_tool_addr_fudge
;	lcall	flash_tool_print_hex+flash_tool_addr_fudge
;	mov	a, #'/'
;	lcall	oysterlib_cout+flash_tool_addr_fudge
;	mov	a, b
;	lcall	flash_tool_print_hex+flash_tool_addr_fudge
;	lcall	oysterlib_newline+flash_tool_addr_fudge
;
;	mov	dptr, #str_ft_select_page+flash_tool_addr_fudge	; Get the desired page to flash
;	lcall	flash_tool_print_str+flash_tool_addr_fudge
;	lcall	oysterlib_cin+flash_tool_addr_fudge
;	lcall	oysterlib_cout+flash_tool_addr_fudge
;	lcall	oysterlib_newline+flash_tool_addr_fudge
;	clr	c						; Clear Carry for the following subtract
;	subb	a, #0x30					; Convert from ASCII
;	mov	r1, a						; Save selected page
;	anl	a, #0x03					; Make sure it's within the desired range
;	xrl	a, r1						; And make sure it's what we entered
;	jz	flash_tool_actual_confirm
;	mov	dptr, #str_ft_err_page+flash_tool_addr_fudge
;	lcall	flash_tool_print_str+flash_tool_addr_fudge
;	lcall	oysterlib_newline+flash_tool_addr_fudge
;	ret
;
;flash_tool_actual_confirm:
;	mov	dptr, #str_ft_confirm+flash_tool_addr_fudge	; Confirm we want to flash page
;	lcall	flash_tool_print_str+flash_tool_addr_fudge
;	lcall	oysterlib_cin+flash_tool_addr_fudge
;	lcall	oysterlib_newline+flash_tool_addr_fudge
;	cjne	a, #'Y', flash_tool_finish			; Check choice
;
;	mov	dptr, #str_ft_erasing_page+flash_tool_addr_fudge
;	lcall	flash_tool_print_str+flash_tool_addr_fudge
;	mov	a, r1
;	lcall	flash_tool_print_hex+flash_tool_addr_fudge
;	mov	a, #':'
;	lcall	oysterlib_cout+flash_tool_addr_fudge
;	mov	a, #' '
;	lcall	oysterlib_cout+flash_tool_addr_fudge
;	lcall	flash_erase_page+flash_tool_addr_fudge		; Erase page
;	mov	dptr, #str_fail+flash_tool_addr_fudge
;	jc	flash_tool_actual_erase_result
;	mov	dptr, #str_okay+flash_tool_addr_fudge
;flash_tool_actual_erase_result:
;	lcall	flash_tool_print_str+flash_tool_addr_fudge
;	lcall	oysterlib_newline+flash_tool_addr_fudge
;
;	mov	dptr, #str_ft_flashing_page+flash_tool_addr_fudge
;	lcall	flash_tool_print_str+flash_tool_addr_fudge
;	mov	a, r1
;	lcall	flash_tool_print_hex+flash_tool_addr_fudge
;	mov	a, #':'
;	lcall	oysterlib_cout+flash_tool_addr_fudge
;	mov	a, #' '
;	lcall	oysterlib_cout+flash_tool_addr_fudge
;	lcall	flash_tool_flash_page_from_ram+flash_tool_addr_fudge	; Flash page
;	mov	dptr, #str_fail+flash_tool_addr_fudge
;	jc	flash_tool_actual_flash_result
;	mov	dptr, #str_okay+flash_tool_addr_fudge
;flash_tool_actual_flash_result:
;	lcall	flash_tool_print_str+flash_tool_addr_fudge
;	lcall	oysterlib_newline+flash_tool_addr_fudge
;
;	mov	a, r1						; If page 0 was written, we need to reset
;	jnz	flash_tool_finish
;	mov	dptr, #str_ft_reseting_device+flash_tool_addr_fudge
;	lcall	flash_tool_print_str+flash_tool_addr_fudge
;	lcall	oysterlib_newline+flash_tool_addr_fudge
;	ljmp	0x0000						; Perform a reset as the monitor was overwritten
;
;flash_tool_finish:
;	ret
;
;; ##############################################################################
;; # Flash tool helper functions
;; ##############################################################################
;
;; ##############################################################################
;; # ROM flash routines
;; ##############################################################################
;
;; # flash_tool_flash_page_from_ram
;; #
;; # Copies from system RAM page 0 to the specified ROM page
;; # In:
;; #   r1 - ROM page to select
;; # Out:
;; #   Carry - Set on error
;; ##########################################################################
;flash_tool_flash_page_from_ram:
;	mov	r2, #0xFF					; Address pointer LSB store
;	mov	r3, #0x7F					; Address pointer MSB store
;
;flash_tool_flash_page_from_ram_read_loop:
;	setb	p1.2						; Select RAM
;	setb	mem_mode_rdwr_ram
;	clr	p1.3
;	clr	mem_mode_rdwr_ram_card
;
;	mov	a, #0						; Select page 0
;	mov	mem_page_rdwr, a
;	mov	dph, #rdwr_page_latch
;	setb	p1.4						; Enable address logic
;	movx	@dptr, a
;	clr	p1.4
;
;	mov	dpl, r2						; Load dptr with next byte to read
;	mov	dph, r3
;	movx	a, @dptr					; Get next byte
;
;	mov	r0, a						; Set data to program
;	lcall	flash_program_byte+flash_tool_addr_fudge
;	jc	flash_tool_flash_page_from_ram_finish		; On error, exit
;
;	dec	r2
;	cjne	r2, #0xff, flash_tool_flash_page_from_ram_read_loop	; Loop on the LSB of address data
;	dec	r3
;	cjne	r3, #0xff, flash_tool_flash_page_from_ram_read_loop	; Loop on the MSB of address data
;
;	clr	c						; No errors
;flash_tool_flash_page_from_ram_finish:
;	ret
;
;; # flash_program_byte
;; #
;; # Program a byte of flash memory
;; # In:
;; #   r0 - Data to write
;; #   r1 - ROM page to select
;; #   r2 - A7-A0 of address to write data to
;; #   r3 - A14-A8 of address to write data to
;; # Out:
;; #   Carry - Set on error
;; ##########################################################################
;flash_program_byte:
;	lcall	flash_send_command+flash_tool_addr_fudge
;	mov	a, #flash_command_program			; Program byte
;	movx	@dptr, a
;
;	mov	a, r1						; Get ROM page to write
;	anl	a, #3						; Make sure it's valid
;	mov	mem_page_rdwr, a
;	mov	dph, #rdwr_page_latch
;	setb	p1.4						; Enable address logic
;	movx	@dptr, a
;	clr	p1.4
;
;	mov	dph, r3						; Get address MSB
;	orl	dph, #0x80					; Make sure we are wrting in the right place
;	mov	dpl, r2						; Get address LSB
;	mov	a, r0						; Get data
;	movx	@dptr, a					; Save data
;
;flash_program_byte_check_loop:
;	movx	a, @dptr					; Check if data saved
;	mov	b, a						; Save a copy
;	xrl	a, r0						; 0 if the data matches
;	jz	flash_program_byte_check_loop_finish
;	mov	a, b						; Otherwise check for a timeout
;	jb	acc.5, flash_program_byte_error
;	sjmp	flash_program_byte_check_loop
;flash_program_byte_check_loop_finish:
;
;	clr	c
;	ret
;flash_program_byte_error:
;	setb	c
;	ret

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
flash_tool_ROM_bank_offset:				equ		0x8000

str_ft_err_con:					db		"This tool can only be run using a serial connection.", 0
str_ft_err_page:				db		"Incorrect page selected.", 0
str_ft_confirm:					db		"Confirm flash write [Y/N]: ", 0
str_ft_copy_rom:				db		"Copying system ROM to RAM.", 0
str_ft_device:					db		"Device: ", 0
str_ft_select_page:				db		"Select Page To Flash: ", 0
str_ft_erasing_page:				db		"Erasing Page ", 0
str_ft_flashing_page:				db		"Flashing Page ", 0
str_ft_reseting_device:				db		"Reseting device.", 0
