; # Virtual disk utils
; ###########################################################################

; ###########################################################################
; #                                                                         #
; #                           Virtual Disk Utils                            #
; #                                                                         #
; ###########################################################################

orgmem  extras_cmd_base+0x0000
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	254,'"',0,0						; id (254=cmd)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"Virtual disk utils",0

orgmem  extras_cmd_base+0x0040
vdisk_utils:
	call	print_newline
	ld	hl, str_memory_card
	call	print_str_simple_space

	ld	hl, str_missing
	call	nc100_memory_memcard_present				; Check if memory card present
	jp	nc, print_str_simple_newline				; If it's not, print message and exit

	; Save existing config
	ld	c, nc100_vdisk_port_bank
	call	nc100_memory_page_get					; Get Bank B configuration
	push	bc							; Save Bank B config

	call	nc100_vdisk_card_page_map_reset				; Page in memory card
	ld	hl, nc100_vdisk_port_address
	call	nc100_vdisk_card_check					; Check if formated
	jr	c, vdisk_utils_formated
vdisk_utils_unformated:
	ld	hl, str_unformat
	call	print_str_simple
	ld	hl, str_ted
	call	print_str_simple_newline
	ld	hl, str_format
	call	print_str_simple
	ld	hl, str_ny
	call	print_str_simple

	call	input_character_filter					; Get character
	call	char_2_upper						; Convert to uppercase
	cp	'Y'							; Check response
	jp	nz, vdisk_utils_cleanup
	call	monlib_console_out					; Print character
	call	print_newline

	; Initialise the card header
	ld	hl, nc100_vdisk_port_address				; Start address to check
	ld	c, nc100_vdisk_port_bank				; Port address of Bank register
	call	nc100_vdisk_card_init
	jr	vdisk_utils_command_prompt
vdisk_utils_formated:
	ld	hl, str_present
	call	print_str_simple_newline
vdisk_utils_command_prompt:
	ld	hl, str_vdisk_prompt
	call	print_str_simple					; Print prompt
vdisk_utils_command_prompt_loop:
	call	input_character_filter					; Get character
	ld	de, vdisk_utils_command_prompt				; Return address for any commands
	push	de

	ld	hl, nc100_vdisk_port_address				; Start address to check
	ld	c, nc100_vdisk_port_bank				; Port address of Bank register
	cp	vdisk_utils_key_help
	jr	z, vdisk_utils_cmd_help
	cp	vdisk_utils_key_list_disks
	jp	z, vdisk_utils_print_vdisks
	cp	vdisk_utils_key_list_drives
	jp	z, vdisk_utils_print_drives
	cp	vdisk_utils_key_vdisk_new
	jp	z, vdisk_utils_vdisk_create
	cp	vdisk_utils_key_description_edit
	jp	z, vdisk_utils_vdisk_description_set
	cp	vdisk_utils_key_vdisk_delete
	jp	z, vdisk_utils_vdisk_delete
	cp	vdisk_utils_key_vdisk_eject
	jp	z, vdisk_utils_vdisk_eject
	cp	vdisk_utils_key_vdisk_insert
	jp	z, vdisk_utils_vdisk_insert
	cp	vdisk_utils_key_vdisk_getsys
	jp	z, vdisk_utils_vdisk_getsys
	cp	vdisk_utils_key_vdisk_putsys
	jp	z, vdisk_utils_vdisk_putsys
	cp	vdisk_utils_key_card_format
	jp	z, vdisk_utils_card_format
	cp	vdisk_utils_key_quit					; Quit?
	jr	nz, vdisk_utils_command_prompt_loop
	call	monlib_console_out
	call	print_newline
	pop	af							; Clear extraneous return address
vdisk_utils_cleanup:
	pop	bc							; Get Bank B configuration
	call	nc100_memory_page_set					; Restore Bank B configuration

	jp	print_newline

; ##################################################
; # Commands
; ##################################################

; # vdisk_utils_cmd_help
; #################################
;  Display the command list
vdisk_utils_cmd_help:
	ld	hl, vdisk_utils_tag_help
	call	print_str_simple
	call	print_newline

	ld	b, vdisk_utils_key_help
	ld	hl, vdisk_utils_tag_help
	call	command_help_line_print
	ld	b, vdisk_utils_key_description_edit
	;ld	hl, vdisk_utils_tag_description_edit
	call	command_help_line_print
	ld	b, vdisk_utils_key_vdisk_delete
	;ld	hl, vdisk_utils_tag_vdisk_delete
	call	command_help_line_print
	ld	b, vdisk_utils_key_vdisk_eject
	;ld	hl, vdisk_utils_tag_vdisk_eject
	call	command_help_line_print
	ld	b, vdisk_utils_key_card_format
	;ld	hl, vdisk_utils_tag_card_format
	call	command_help_line_print
	ld	b, vdisk_utils_key_vdisk_getsys
	;ld	hl, vdisk_utils_tag_vdisk_getsys
	call	command_help_line_print
	ld	b, vdisk_utils_key_vdisk_insert
	;ld	hl, vdisk_utils_tag_vdisk_insert
	call	command_help_line_print
	ld	b, vdisk_utils_key_list_disks
	;ld	hl, vdisk_utils_tag_help
	call	command_help_line_print
	ld	b, vdisk_utils_key_list_drives
	;ld	hl, vdisk_utils_tag_help
	call	command_help_line_print
	ld	b, vdisk_utils_key_vdisk_new
	;ld	hl, vdisk_utils_tag_vdisk_new
	call	command_help_line_print
	ld	b, vdisk_utils_key_vdisk_putsys
	;ld	hl, vdisk_utils_tag_vdisk_putsys
	call	command_help_line_print
	ld	b, vdisk_utils_key_quit
	;ld	hl, vdisk_utils_tag_quit
	call	command_help_line_print

	ret

; # vdisk_utils_print_vdisk_row
; #################################
;	In:	B = Index
;		HL = Pointer to vdisk header
vdisk_utils_print_vdisk_row:
	ld	a, b							; Print index
	call	print_hex8
	call	print_space
	ld	a, '|'
	call	monlib_console_out
vdisk_utils_print_vdisk_row_size:
	push	hl							; Save vdisk header pointer
	push	bc
	push	de
	call	print_space
	ld	l, nc100_vdisk_header_disk_size				; Get vdisk size
	ld	a, (hl)
	call	nc100_vdisk_size_convert				; Get from 64k blocks to 1k blocks
	ld	b, h
	ld	c, l
	call	print_dec16u
	ld	a, 'k'
	call	monlib_console_out
	call	print_space
	ld	a, (z80mon_temp1)					; Check whether to pad the entry
	and	0x08
	jr	nz, vdisk_utils_print_vdisk_row_size_end
	call	print_space
vdisk_utils_print_vdisk_row_size_end:
	pop	de
	pop	bc
	pop	hl
	ld	a, '|'
	call	monlib_console_out
vdisk_utils_print_vdisk_row_description:
	call	print_space
	ld	l, nc100_vdisk_header_description			; Print the vdisk description
	call	print_str_simple
	call	print_newline
	ret

; # vdisk_utils_print_vdisks
; #################################
;  Displays the vdisks on a card
;	In:	C = Port address of bank
;		HL = Pointer to vdisk header
vdisk_utils_print_vdisks:
	push	bc
	push	hl
	ld	hl, vdisk_utils_tag_list_disks
	call	print_str_simple
	call	print_newline
	pop	hl
	pop	bc
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	ld	b, 0
vdisk_utils_print_vdisks_loop:
	ld	l, 0x00							; Reset LSB
	call	nc100_vdisk_card_check					; Check if valid vdisk
	jr	nc, vdisk_utils_print_vdisks_end
	call	vdisk_utils_print_vdisk_row				; Print the current vdisk information
	call	nc100_vdisk_card_select_next				; Select next vdisk, if it exists
	jr	nc, vdisk_utils_print_vdisks_end			; If it doesn't, exit
	jr	vdisk_utils_print_vdisks_loop
vdisk_utils_print_vdisks_end:
	ret

; # vdisk_utils_print_drives
; #################################
;  Displays the vdisks assigned to drives
;	In:	C = Port address of bank
;		HL = Pointer to vdisk header
vdisk_utils_print_drives:
	push	bc
	push	hl
	ld	hl, vdisk_utils_tag_list_drives
	call	print_str_simple
	call	print_newline
	pop	hl
	pop	bc
	ld	d, 0x00
vdisk_utils_print_drives_loop:
	ld	a, d							; Set drive index
	cp	nc100_vdisk_max_drives					; Check if looped through all the drives
	jr	z, vdisk_utils_print_drives_finish
	call	nc100_vdisk_drive_get					; Get drive pointer
	jr	nc, vdisk_utils_print_drives_continue
	call	nc100_vdisk_card_page_map_set_64k
	ld	a, d							; Set drive index
	call	print_hex8
	call	print_space
	ld	a, '|'
	call	monlib_console_out
	call	vdisk_utils_print_vdisk_row
vdisk_utils_print_drives_continue:
	inc	d							; Increment drive index
	jr	vdisk_utils_print_drives_loop				; Loop
vdisk_utils_print_drives_finish:
	ret

; # vdisk_utils_vdisk_create
; #################################
;  Creates a new vdisk on the memory card
;       In:     C = Port address of bank
;               HL = Pointer to vdisk header
vdisk_utils_vdisk_create:
	push	bc
	push	hl
	ld	hl, vdisk_utils_tag_vdisk_new
	call	print_str_simple
	call	print_newline
	ld	hl, str_vdisk_select_size
	call	print_str_simple
vdisk_utils_vdisk_create_size_loop:
	call	input_character_filter					; Get disk size
vdisk_utils_vdisk_create_size_loop_128k:
	cp	0x31
	jr	nz, vdisk_utils_vdisk_create_size_loop_256k
	ld	d, 0x02
	jr	vdisk_utils_vdisk_create_continue
vdisk_utils_vdisk_create_size_loop_256k:
	cp	0x32
	jr	nz, vdisk_utils_vdisk_create_size_loop_512k
	ld	d, 0x04
	jr	vdisk_utils_vdisk_create_continue
vdisk_utils_vdisk_create_size_loop_512k:
	cp	0x33
	jr	nz, vdisk_utils_vdisk_create_size_loop_1024k
	ld	d, 0x08
	jr	vdisk_utils_vdisk_create_continue
vdisk_utils_vdisk_create_size_loop_1024k:
	cp	0x34
	jr	nz, vdisk_utils_vdisk_create_escape
	ld	d, 0x10
	jr	vdisk_utils_vdisk_create_continue
vdisk_utils_vdisk_create_escape:
	cp	character_code_escape
	jr	z, vdisk_utils_vdisk_create_abort
	jr	vdisk_utils_vdisk_create_size_loop
vdisk_utils_vdisk_create_continue:
	call	monlib_console_out
	call	print_newline
	pop	hl
	pop	bc
	call	nc100_vdisk_create_next
	jr	c, vdisk_utils_vdisk_create_finish
	ld	hl, str_failed
	call	print_str_simple
	call	print_newline
vdisk_utils_vdisk_create_finish:
	ret
vdisk_utils_vdisk_create_abort:
	call	print_newline
	pop	af							; Pop extraneous values
	pop	af
	ret

; # vdisk_utils_vdisk_description_set
; #################################
;  Edits a vdisk description
;       In:     C = Port address of bank
;               HL = Pointer to vdisk header
vdisk_utils_vdisk_description_set:
	push	hl
	push	bc
	ld	hl, vdisk_utils_tag_description_edit
	call	print_str_simple
	call	print_newline
	ld	hl, str_vdisk_address
	call	print_str_simple
	call	input_hex8
	jr	nc, vdisk_utils_vdisk_description_set_abort
	pop	bc							; Pop port address
	ld	b, e							; Copy vdisk address
	push	bc							; Save again
	call	print_newline
	ld	hl, str_vdisk_label
	call	print_str_simple
	ld	b, 0x20							; Buffer size: 32
	ld	de, var_vdisk_description				; Pointer to buffer
	call	input_str						; Get description string
	jr	nc, vdisk_utils_vdisk_description_set_abort
	call	print_newline
	pop	bc
	pop	hl
	ld	de, var_vdisk_description
	call	nc100_vdisk_description_set
	jr	c, vdisk_utils_vdisk_description_set_finish
	ld	hl, str_failed
	call	print_str_simple
	call	print_newline
vdisk_utils_vdisk_description_set_finish:
	ret
vdisk_utils_vdisk_description_set_abort:
	pop	af
	pop	af
	jp	print_abort

; # vdisk_utils_vdisk_delete
; #################################
;  Deletes a vdisk on the memory card (and from drive assignments)
;       In:     C = Port address of bank
;               HL = Pointer to vdisk header
vdisk_utils_vdisk_delete:
	push	hl
	push	bc
	ld	hl, vdisk_utils_tag_vdisk_delete
	call	print_str_simple
	call	print_newline
	ld	hl, str_vdisk_address
	call	print_str_simple
	call	input_hex8
	pop	bc							; Pop port address
	ld	b, e							; Copy vdisk address
	push	bc
	call	print_newline
	pop	bc
	pop	hl
	call	nc100_vdisk_delete
	jr	c, vdisk_utils_vdisk_delete_finish
	ld	hl, str_failed
	call	print_str_simple
	call	print_newline
vdisk_utils_vdisk_delete_finish:
	ret

; # vdisk_utils_vdisk_eject
; #################################
;  Remove a vdisk from a drive
;       In:     C = Port address of bank
;               HL = Pointer to vdisk header
vdisk_utils_vdisk_eject:
	push	hl
	push	bc
	ld	hl, vdisk_utils_tag_vdisk_eject
	call	print_str_simple
	call	print_newline
	ld	hl, str_vdisk_address
	call	print_str_simple
	call	input_hex8
	pop	bc							; Pop port address
	ld	b, e							; Copy vdisk address
	push	bc
	call	print_newline
	pop	bc
	pop	hl
	call	nc100_vdisk_drive_remove
;	jr	c, vdisk_utils_vdisk_eject_finish
;	ld	hl, str_failed
;	call	print_str_simple
;	call	print_newline
;vdisk_utils_vdisk_eject_finish:
	ret

; # vdisk_utils_vdisk_insert
; #################################
;  Assign a vdisk to a drive
;       In:     C = Port address of bank
;               HL = Pointer to vdisk header
vdisk_utils_vdisk_insert:
	push	hl
	push	bc
	ld	hl, vdisk_utils_tag_vdisk_insert
	call	print_str_simple
	call	print_newline
	ld	hl, str_vdisk_address
	call	print_str_simple
	call	input_hex8
	pop	bc							; Pop port address
	ld	b, e							; Copy vdisk address
	push	bc
	call	print_newline
	ld	hl, str_vdisk_drive
	call	print_str_simple
	call	input_hex8
	ld	d, e							; Copy to D, as this will be restored as A
	push	de
	call	print_newline
	pop	af
	pop	bc
	pop	hl
	call	nc100_vdisk_drive_assign
;	jr	c, vdisk_utils_vdisk_insert_finish
;	ld	hl, str_failed
;	call	print_str_simple
;	call	print_newline
;vdisk_utils_vdisk_insert_finish:
	ret

; # vdisk_utils_vdisk_getsys
; #################################
;  Read vdisk boot area in to memory
;	In:	C = Port address of bank
;		HL = Pointer to vdisk header
vdisk_utils_vdisk_getsys:
	push	hl
	push	bc
	ld	hl, vdisk_utils_tag_vdisk_getsys
	call	print_str_simple
	call	print_newline
	ld	hl, str_vdisk_load_location
	call	print_str_simple
	call	input_hex16						; Get address to load boot area into
	jp	nc, vdisk_utils_vdisk_getsys_abort
	push	de
	call	print_newline
	pop	de
	pop	bc
	pop	hl
	xor	a							; Clear A
	call	nc100_vdisk_drive_get					; Get vdisk in 1st drive
	jr	c, vdisk_utils_vdisk_getsys_continue
	ld	hl, str_vdisk_no_disk
	call	print_str_simple
	call	print_newline
	ret
vdisk_utils_vdisk_getsys_continue:
	ld	a, nc100_vdisk_sys_sectors				; Total number of sectors to write
	ld	(var_vdisk_sys_sector_count), a
	; Boot sector read
	ld	(var_vdisk_dma_addr), de				; Set DMA address
	ld	de, 0x0000						; Select track 0
	ld	(var_vdisk_track), de
	ld	de, 0x0001						; Select sector 1 (track 0/sector 0 is reserved)
	ld	(var_vdisk_sector), de
	ld	ix, nc100_vdisk_sector_read				; Read operation
	ld	l, nc100_vdisk_header_sectors_track_ptr
	ld	a, (hl)							; Get sectors per track
	ld	(var_vdisk_sectors_per_track), a			; Set sectors per track variable
	cp	0x20							; Check if 32 sectors per track
	jr	z, vdisk_utils_vdisk_getsys_setup_32spt
vdisk_utils_vdisk_getsys_setup_64spt:
	ld	a, 0x01							; Load 1 track
	ld	(var_vdisk_sys_track_count), a
	ld	iy, nc100_vdisk_sector_seek_64spt			; Seek operation
	jr	vdisk_utils_vdisk_getsys_loop
vdisk_utils_vdisk_getsys_setup_32spt:
	ld	a, 0x02							; Load 2 tracks
	ld	(var_vdisk_sys_track_count), a
	ld	iy, nc100_vdisk_sector_seek_32spt			; Seek operation
vdisk_utils_vdisk_getsys_loop:
	ld	a, (var_vdisk_sys_sector_count)				; Get number of sectors remaining
	dec	a							; Decrement number of sectors remaining
	jr	z, vdisk_utils_vdisk_getsys_finish			; If zero, finish
	ld	(var_vdisk_sys_sector_count), a				; Store sectors remaining

	push	hl							; Save vdisk pointer
	push	bc							; Save vdisk address/port
	ld	de, vdisk_utils_vdisk_getsys_loop_cont
	push	de							; Push return address
	jp	(iy)							; Sector seek
vdisk_utils_vdisk_getsys_loop_cont:
	pop	bc							; Restore vdisk address/port
	pop	hl							; Restore vdisk pointer

	ld	(var_vdisk_dma_addr), de				; Save DMA address
	ld	de, (var_vdisk_sector)					; Get current sector
	inc	de							; Next sector
	ld	a, (var_vdisk_sectors_per_track)
	cp	e							; Check sector number
	jr	z, vdisk_utils_vdisk_getsys_loop_next_track
	ld	(var_vdisk_sector), de					; Update sector
	jr	vdisk_utils_vdisk_getsys_loop				; Read next sector
vdisk_utils_vdisk_getsys_loop_next_track:
	ld	a, (var_vdisk_sys_track_count)				; Get remaining track count
	dec	a
	jr	z, vdisk_utils_vdisk_getsys_finish
	ld	(var_vdisk_sys_track_count), a				; Save remaining track count
	ld	de, (var_vdisk_track)					; Get current track
	inc	de							; Next track
	ld	(var_vdisk_track), de					; Update track
	ld	de, 0x0000
	ld	(var_vdisk_sector), de					; Reset sector
	jr	vdisk_utils_vdisk_getsys_loop
vdisk_utils_vdisk_getsys_finish:
	ret
vdisk_utils_vdisk_getsys_failed:
	ld	hl, str_failed
	call	print_str_simple
	jp	print_newline
vdisk_utils_vdisk_getsys_abort:
	pop	af							; Pop extraneous values
	pop	af
	jp	print_newline

; # vdisk_utils_vdisk_putsys
; #################################
;  Write memory to vdisk boot area
;	In:	C = Port address of bank
;		HL = Pointer to vdisk header
vdisk_utils_vdisk_putsys:
	push	hl
	push	bc
	ld	hl, vdisk_utils_tag_vdisk_putsys
	call	print_str_simple
	call	print_newline
	ld	hl, str_vdisk_load_location
	call	print_str_simple
	call	input_hex16						; Get address to load boot area into
	jp	nc, vdisk_utils_vdisk_putsys_abort
	push	de
	call	print_newline
	pop	de
	pop	bc
	pop	hl
	xor	a							; Clear A
	call	nc100_vdisk_drive_get					; Get vdisk in 1st drive
	jr	c, vdisk_utils_vdisk_putsys_continue
	ld	hl, str_vdisk_no_disk
	call	print_str_simple
	call	print_newline
	ret
vdisk_utils_vdisk_putsys_continue:
	ld	a, nc100_vdisk_sys_sectors				; Total number of sectors to write
	ld	(var_vdisk_sys_sector_count), a
	; Boot sector write
	ld	(var_vdisk_dma_addr), de				; Set DMA address
	ld	de, 0x0000						; Select track 0
	ld	(var_vdisk_track), de
	ld	de, nc100_vdisk_sector_1st+1				; Select sector 1 (track 0/sector 0 is reserved)
	ld	(var_vdisk_sector), de
	ld	ix, nc100_vdisk_sector_write				; Write operation
	ld	l, nc100_vdisk_header_sectors_track_ptr
	ld	a, (hl)							; Get sectors per track
	ld	(var_vdisk_sectors_per_track), a			; Set sectors per track variable
	cp	0x20							; Check if 32 sectors per track
	jr	z, vdisk_utils_vdisk_putsys_setup_32spt
vdisk_utils_vdisk_putsys_setup_64spt:
	ld	a, 0x01							; Load 1 track
	ld	(var_vdisk_sys_track_count), a
	ld	iy, nc100_vdisk_sector_seek_64spt			; Seek operation
	jr	vdisk_utils_vdisk_putsys_loop
vdisk_utils_vdisk_putsys_setup_32spt:
	ld	a, 0x02							; Load 2 tracks
	ld	(var_vdisk_sys_track_count), a
	ld	iy, nc100_vdisk_sector_seek_32spt			; Seek operation
vdisk_utils_vdisk_putsys_loop:
	ld	a, (var_vdisk_sys_sector_count)				; Get number of sectors remaining
	dec	a							; Decrement number of sectors remaining
	jr	z, vdisk_utils_vdisk_putsys_finish			; If zero, finish
	ld	(var_vdisk_sys_sector_count), a				; Store sectors remaining

	push	hl							; Save vdisk pointer
	push	bc							; Save vdisk address/port
	ld	de, vdisk_utils_vdisk_putsys_loop_cont
	push	de							; Push return address
	jp	(iy)							; Sector seek
vdisk_utils_vdisk_putsys_loop_cont:
	pop	bc							; Restore vdisk address/port
	pop	hl							; Restore vdisk pointer

	ld	(var_vdisk_dma_addr), de				; Save DMA address
	ld	de, (var_vdisk_sector)					; Get current sector
	inc	de							; Next sector
	ld	a, (var_vdisk_sectors_per_track)
	cp	e							; Check sector number
	jr	z, vdisk_utils_vdisk_putsys_loop_next_track
	ld	(var_vdisk_sector), de					; Update sector
	jr	vdisk_utils_vdisk_putsys_loop				; Read next sector
vdisk_utils_vdisk_putsys_loop_next_track:
	ld	a, (var_vdisk_sys_track_count)				; Get remaining track count
	dec	a
	jr	z, vdisk_utils_vdisk_putsys_finish
	ld	(var_vdisk_sys_track_count), a				; Save remaining track count
	ld	de, (var_vdisk_track)					; Get current track
	inc	de							; Next track
	ld	(var_vdisk_track), de					; Update track
	ld	de, 0x0000
	ld	(var_vdisk_sector), de					; Reset sector
	jr	vdisk_utils_vdisk_putsys_loop
vdisk_utils_vdisk_putsys_finish:
	ret
vdisk_utils_vdisk_putsys_failed:
	ld	hl, str_failed
	call	print_str_simple
	jp	print_newline
vdisk_utils_vdisk_putsys_abort:
	pop	af							; Pop extraneous values
	pop	af
	jp	print_newline

; # vdisk_utils_card_format
; #################################
;  Initialise a memory card
;       In:     C = Port address of bank
;               HL = Pointer to vdisk header
vdisk_utils_card_format:
	push	hl
	push	bc
	ld	hl, vdisk_utils_tag_card_format
	call	print_str_simple
	call	print_newline
	ld	hl, str_format
	call	print_str_simple
	ld	hl, str_ny
	call	print_str_simple
	call	input_character_filter					; Get character
	call	char_2_upper						; Convert to uppercase
	cp	'Y'							; Check response
	jp	nz, vdisk_utils_card_format_abort
	call	monlib_console_out					; Print character
	pop	bc
	pop	hl
	call	nc100_vdisk_card_page_map_reset				; Page in memory card
	call	nc100_vdisk_card_init
vdisk_utils_card_format_finish:
	call	print_newline
	ret
vdisk_utils_card_format_abort:
	call	print_newline
	pop	af							; Pop extraneous values
	pop	af
	ret


include	"nc100/virtual_disk.asm"
include	"nc100/virtual_disk_admin.asm"

; # Variables
; ##################################################
var_vdisk_sector:				dw		0x0000
var_vdisk_track:				dw		0x0000
var_vdisk_dma_addr:				dw		0x0000
var_vdisk_description:				ds		0x20, 0x00
var_vdisk_sectors_per_track:			db		0x00
var_vdisk_sys_track_count:			db		0x00
var_vdisk_sys_sector_count:			db		0x00

; # Defines
; ##################################################
nc100_vdisk_port_bank:				equ		nc100_io_membank_B
nc100_vdisk_port_address:			equ		0x4000
nc100_vdisk_dma_address:			equ		0x8000

; Command keys
vdisk_utils_key_help:				equ		'?'
vdisk_utils_key_description_edit:		equ		'd'
vdisk_utils_key_vdisk_delete:			equ		'D'
vdisk_utils_key_vdisk_eject:			equ		'e'
vdisk_utils_key_card_format:			equ		'f'
vdisk_utils_key_vdisk_getsys:			equ		'g'
vdisk_utils_key_vdisk_insert:			equ		'i'
vdisk_utils_key_list_disks:			equ		'l'
vdisk_utils_key_list_drives:			equ		'L'
vdisk_utils_key_vdisk_new:			equ		'n'
vdisk_utils_key_vdisk_putsys:			equ		'p'
vdisk_utils_key_quit:				equ		'q'

; Command help text
vdisk_utils_tag_help:				db		"Help list.",0
vdisk_utils_tag_description_edit:		db		"Edit vdisk description.",0
vdisk_utils_tag_vdisk_delete:			db		"Delete vdisk.",0
vdisk_utils_tag_vdisk_eject:			db		"Eject vdisk from drive.", 0
vdisk_utils_tag_card_format:			db		"Format memory card.",0
vdisk_utils_tag_vdisk_getsys:			db		"Vdisk getsys.",0
vdisk_utils_tag_vdisk_insert:			db		"Insert vdisk into drive.", 0
vdisk_utils_tag_list_disks:			db		"List vdisks.",0
vdisk_utils_tag_list_drives:			db		"List drive assignments.",0
vdisk_utils_tag_vdisk_new:			db		"New virtual disk.",0
vdisk_utils_tag_vdisk_putsys:			db		"Vdisk putsys.",0
vdisk_utils_tag_quit:				db		"Quit",0

str_vdisk_prompt:				db		"vdisk> ",0
str_vdisk_drive:				db		"Drive: ",0
str_vdisk_select_size:				db		"Select disk size (1=128k,2=256k,3=512k,4=1024k): ",0
str_vdisk_label:				db		"Label: ",0
str_vdisk_address:				db		"Vdisk addr: ",0
str_vdisk_load_location:			db		"Load location: ",0
str_vdisk_no_disk:				db		"No disk!",0
