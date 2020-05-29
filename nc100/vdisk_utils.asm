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

	cp	vdisk_utils_key_quit					; Quit?
	jr	nz, vdisk_utils_command_prompt_loop
	call	monlib_console_out
	call	print_newline
	pop	af							; Clear extraneous return address

;	call	vdisk_card_display_index
;	call	vdisk_card_display_drive_index
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
	ld	b, vdisk_utils_key_list_disks
	;ld	hl, vdisk_utils_tag_help
	call	command_help_line_print
	ld	b, vdisk_utils_key_list_drives
	;ld	hl, vdisk_utils_tag_help
	call	command_help_line_print
	ld	b, vdisk_utils_key_vdisk_new
	;ld	hl, vdisk_utils_tag_vdisk_new
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
	jr	nz, vdisk_utils_vdisk_create_size_loop
	ld	d, 0x10
vdisk_utils_vdisk_create_continue:
	call	monlib_console_out
	call	print_newline
	ld	hl, str_vdisk_create
	call	print_str_simple
	pop	hl
	pop	bc
	call	nc100_vdisk_create_next
	ld	hl, str_failed
	jr	nc, vdisk_utils_vdisk_create_test
	ld	hl, str_okay
vdisk_utils_vdisk_create_test:
	call	print_str_simple
	call	print_newline
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
	pop	bc							; Pop port address
	ld	b, e							; Copy vdisk address
	push	bc							; Save again
	call	print_newline
	ld	hl, str_vdisk_label
	call	print_str_simple
	ld	b, 0x20							; Buffer size: 32
	ld	de, var_vdisk_description				; Pointer to buffer
	call	input_str						; Get description string
	call	print_newline
	pop	bc
	pop	hl
	ld	de, var_vdisk_description
	call	nc100_vdisk_description_set
	ld	hl, str_failed
	jr	nc, vdisk_utils_vdisk_description_set_test
	ld	hl, str_okay
vdisk_utils_vdisk_description_set_test:
	call	print_str_simple
	call	print_newline
	ret

;; # vdisk_card_putsys
;; #################################
;	ld	hl, str_vdisk_write
;	call	print_str_simple
;	ld	de, 0x001f						; Select sector 31
;	ld	(var_vdisk_sector), de
;	ld	de, 0x001f						; Select track 31
;	ld	(var_vdisk_track), de
;	ld	de, nc100_vdisk_dma_address
;	ld	(var_vdisk_dma_addr), de				; Set DMA address
;	; Vdisk 0
;	ld	hl, nc100_vdisk_port_address				; Start address to check
;	ld	c, nc100_vdisk_port_bank				; Port address of Bank register
;	ld	b, 0x00
;	ld	ix, nc100_vdisk_sector_write				; Write operation
;	call	nc100_vdisk_sector_seek_32spt
;	ld	hl, str_failed
;	jr	nc, vdisk_utils_write_test
;	ld	hl, str_okay
;vdisk_utils_write_test:
;	call	print_str_simple
;	call	print_newline

;; # vdisk_card_assign_vdisk
;; #################################
;	ld	hl, nc100_vdisk_port_address				; Start address to check
;	ld	c, nc100_vdisk_port_bank				; Port address of Bank register
;	ld	a, 0x0d
;	ld	b, 0x00
;	call	nc100_vdisk_drive_assign


;; # vdisk_card_remove_vdisk
;; #################################
;	ld	hl, str_vdisk_delete
;	call	print_str_simple
;	ld	hl, nc100_vdisk_port_address				; Start address to check
;	ld	c, nc100_vdisk_port_bank				; Port address of Bank register
;	ld	b, 0x00
;	call	nc100_vdisk_delete
;	ld	hl, str_failed
;	jr	nc, vdisk_utils_delete_test
;	ld	hl, str_okay
;vdisk_utils_delete_test:
;	call	print_str_simple
;	call	print_newline

include	"nc100/virtual_disk.asm"
include	"nc100/virtual_disk_admin.asm"

; # Variables
; ##################################################
var_vdisk_sector:				db		0x00
var_vdisk_track:				db		0x00
var_vdisk_dma_addr:				dw		0x0000
var_vdisk_description:				ds		0x20, ' '

; # Defines
; ##################################################
nc100_vdisk_port_bank:				equ		nc100_io_membank_B
nc100_vdisk_port_address:			equ		0x4000
nc100_vdisk_dma_address:			equ		0x8000

; Command keys
vdisk_utils_key_help:				equ		'?'
vdisk_utils_key_description_edit:		equ		'e'
vdisk_utils_key_list_disks:			equ		'l'
vdisk_utils_key_list_drives:			equ		'L'
vdisk_utils_key_vdisk_new:			equ		'n'
vdisk_utils_key_quit:				equ		'q'

; Command help text
vdisk_utils_tag_help:				db		"Help list.",0
vdisk_utils_tag_description_edit:		db		"Edit vdisk description.",0
vdisk_utils_tag_list_disks:			db		"List vdisks.",0
vdisk_utils_tag_list_drives:			db		"List drive assignments.",0
vdisk_utils_tag_vdisk_new:			db		"New virtual disk.",0
vdisk_utils_tag_quit:				db		"Quit",0

str_vdisk_prompt:				db		"vdisk> ",0
str_vdisk_delete:				db		"Delete: ",0
str_vdisk_create:				db		"Create: ",0
str_vdisk_select_size:				db		"Select disk size (1=128k,2=256k,3=512k,4=1024k): ",0
str_vdisk_label:				db		"Label: ",0
str_vdisk_format:				db		"Format: ",0
str_vdisk_read:					db		"Read: ",0
str_vdisk_address:				db		"Vdisk addr: ",0
str_vdisk_write:				db		"Write: ",0
