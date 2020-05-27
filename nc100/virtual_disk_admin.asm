; # Virtual disk administration routines
; ###########################################################################
nc100_vdisk_init_header:		db		"####INITDISK####"
str_unformat:				db		"Un"
str_format:				db		"Format",0
str_ted:				db		"ted",0
str_card:				db		"Card",0
str_disk:				db		"Disk",0
str_size:				db		"Size",0
str_virtual:				db		"Virtual",0

; ###########################################################################
; # Card operations
; ###########################################################################

; # nc100_vdisk_card_init
; #################################
;  Write the basic card info to pointer
;	In:	C = Port address of bank
;		HL = Pointer to start of virtual disk
nc100_vdisk_card_init:
	push	hl							; Save start address
	ld	b, 16							; Byte count to copy
	ld	de, nc100_vdisk_init_header				; Need different header so as not to match existing imaages
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	; Copy init header
nc100_vdisk_card_init_magic_loop:
	ld	a, (de)							; Copy magic byte
	ld	(hl), a							; To memory card
	inc	hl							; Increment pointers
	inc	de
	djnz	nc100_vdisk_card_init_magic_loop			; Loop over header
	; Card Size
	ld	l, nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_size
	ld	a, 0x00							; Card size: not detected
	ld	(hl), a
	; Detect size by looking for the header reoccuring
	ld	b, 0x00							; 64k block count
nc100_vdisk_card_init_size_loop:
	inc	b							; Increment block count
	in	a, (c)							; Get memory config
	and	0x3f							; Filter address bits
	add	0x04							; Increment by 64k
	cp	0x40							; Check for overrun
	jr	z, nc100_vdisk_card_init_size_set
	or	nc100_membank_CRAM					; Select card RAM
	out	(c), a							; Select next page
	pop	hl							; Reload start address
	push	hl
	ld	de, nc100_vdisk_init_header				; Check for the init header
	call	nc100_vdisk_card_check_magic_loop
	jr	nc, nc100_vdisk_card_init_size_loop
nc100_vdisk_card_init_size_set:
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	pop	hl							; Reload start address
	ld	l, nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_size
	ld	(hl), b							; Save card size
	; Initialise vdisk drive table
	call	nc100_vdisk_drive_init

	ld	l, 0							; Reset pointer
	call	nc100_vdisk_init					; Write first disk header
	ret

; # nc100_vdisk_card_select_next
; #################################
;  Sets the page map configuration to the start of the next vdisk
;       In:     C = Port address of bank
;               HL = Pointer to start of virtual disk
;		A' = In use
;	Out:	Carry flag set when next vdisk selected, unset if not (doesn't exist)
nc100_vdisk_card_select_next:
	xor	a							; Clear A
	ld	l, nc100_vdisk_header_next_disk
	ld	b, (hl)							; Get MSB pointer to next disk
	cp	b							; Check if zero
	jr	z, nc100_vdisk_card_select_next_failed			; If pointer zero, finish
	call	nc100_vdisk_card_page_map_set				; Update page mapping
	scf								; Set Carry flag
	ret
nc100_vdisk_card_select_next_failed:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_vdisk_card_select_last
; #################################
;  Sets the page map configuration to the start of the last vdisk
;       In:     C = Port address of bank
;               HL = Pointer to start of virtual disk
;		A' = In use
nc100_vdisk_card_select_last:
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
nc100_vdisk_card_select_last_loop:
	xor	a							; Clear A
	ld	l, nc100_vdisk_header_next_disk
	ld	b, (hl)							; Get MSB pointer to next disk
	cp	b							; Check if zero
	jr	z, nc100_vdisk_card_select_last_finish			; If pointer zero, finish
	call	nc100_vdisk_card_page_map_set				; Update page mapping
	jr	nc100_vdisk_card_select_last_loop
nc100_vdisk_card_select_last_finish:
	ret

; # nc100_vdisk_card_free_space_total
; #################################
;  Returns the total amount of free space on the memory card
;       In:     C = Port address of bank
;               HL = Pointer to start of virtual disk
;	Out:	A = Free space in 64k blocks
nc100_vdisk_card_free_space_total:
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	; Get card size
	ld	l, nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_size
	ld	a, (hl)							; Save card size
	ex	af, af'							; Swap out A
nc100_vdisk_card_free_space_total_loop:
	xor	a							; Clear A
	ld	l, nc100_vdisk_header_disk_size
	ld	b, (hl)							; Get disk size
	cp	b							; Check if zero
	jr	z, nc100_vdisk_card_free_space_total_finish		; If disk size zero, finish
	ex	af, af'							; Swap A (Size) back in
	sub	b							; Subtract disk space from card space
	ex	af, af'
	call	nc100_vdisk_card_select_next				; Select next vdisk
	jr	nc, nc100_vdisk_card_free_space_total_finish
	jr	nc100_vdisk_card_free_space_total_loop			; Loop
nc100_vdisk_card_free_space_total_finish:
	ex	af, af'							; Swap A (Size) back in
	ret

; # nc100_vdisk_card_free_space_remaining
; #################################
;  Returns the amount of free space at the end of the memory card
;       In:     C = Port address of bank
;               HL = Pointer to start of virtual disk
;	Out:	A = Free space in 64k blocks
nc100_vdisk_card_free_space_remaining:
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	; Get card size
	ld	l, nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_size
	ld	a, (hl)							; Save card size
	ex	af, af'							; Swap out A
	call	nc100_vdisk_card_select_last				; Seek to last vdisk
	ld	l, nc100_vdisk_header_disk_size
	ld	b, (hl)							; Get disk size
	in	a, (c)							; Get current page mapping
	and	0x3f							; Filter bits 6 & 7
	srl	a							; Shift A so as to map with 64k blocks
	srl	a
	add	b							; Add disk size
	ld	b, a							; Save for next calculation
	ex	af, af'							; Swap A (Size) back in
	sub	b							; Subtract from card size
	ret

; ###########################################################################
; # Drive configuration operations
; ###########################################################################

; # nc100_vdisk_drive_init
; #################################
;  Initialise the vdisk drive header
;	In:	C = Port address of bank
;		HL = Pointer to start of virtual disk
nc100_vdisk_drive_init:
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	; Clear disk selection table
	ld	l, nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_vdrive0_type
	ld	b, 0x20							; 16 disks of 2 bytes
	xor	a							; Clear A
nc100_vdisk_drive_init_loop:
	ld	(hl), a							; Clear byte
	inc	hl							; Increment pointer
	djnz	nc100_vdisk_drive_init_loop
	ret

; # nc100_vdisk_drive_remove
; #################################
;  Remove a vdisk from a drive
;	In:	B = Drive address in 64k blocks
;		C = Port address of bank
;		HL = Pointer to start of virtual disk
nc100_vdisk_drive_remove:
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	ld	l, nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_vdrive0_pointer
nc100_vdisk_drive_remove_loop:
	ld	a, b
	cp	(hl)							; Check if addresses match
	jr	nz, nc100_vdisk_drive_remove_continue			; If they don't match, continue to next entry
	xor	a							; Clear A
	dec	hl
	ld	(hl), a							; Clear drive's type
	inc	hl
	ld	(hl), a							; Clear drive's pointer
nc100_vdisk_drive_remove_continue:
	ld	a, l
	cp	nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_vdrive15_pointer
	jr	z, nc100_vdisk_drive_remove_finish			; Finish if last pointer
	inc	hl							; Increment pointer to next drive pointer
	inc	hl
	jr	nc100_vdisk_drive_remove_loop				; Loop
nc100_vdisk_drive_remove_finish:
	ret

; # nc100_vdisk_drive_assign
; #################################
;  Remove a vdisk from a drive
;	In:	A = Drive index
;		B = Drive address in 64k blocks
;		C = Port address of bank
;		HL = Pointer to start of virtual disk
nc100_vdisk_drive_assign:
	ex	af, af'							; Swap out drive index
	call	nc100_vdisk_drive_remove				; Remove all current references to the disk
	ex	af, af'							; Swap drive index back
	and	0x0f							; Filter value
	rlca								; x2 (as top nibble stripped)
	add	nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_vdrive0_pointer
	ld	l, a
	ld	(hl), b							; Save vdisk address pointer to drive
	ld	a, nc100_vdisk_type_ram					; Get drive type
	dec	hl							; Decrement to drive type
	ld	(hl), a							; Save drive type
	ret

; # nc100_vdisk_drive_get
; #################################
;  Retreive the pointer assigned to a drive
;	In:	A = Drive index
;		C = Port address of bank
;		HL = Pointer to start of virtual disk
;	Out:	B = Drive address in 64k blocks
;		Carry flag set if drive has assigned vdisk, unset if not
nc100_vdisk_drive_get:
	ex	af, af'							; Swap out drive index
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	ex	af, af'							; Swap drive index back in
	and	0x0f							; Filter value
	rlca								; x2 (as top nibble stripped)
	add	nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_vdrive0_type
	ld	l, a
	ld	a, (hl)							; Get vdisk type
	cp	nc100_vdisk_type_none					; Check if the drive is assigned
	jr	z, nc100_vdisk_drive_get_none
	inc	hl							; Increment pointer
	ld	b, (hl)							; Get drive pointer
	scf								; Set Carry flag
	ret
nc100_vdisk_drive_get_none:
	scf								; Clear Carry flag
	ccf
	ret

; ###########################################################################
; # Disk operations
; ###########################################################################

; # nc100_vdisk_init
; #################################
;  Write the basic vdisk header to pointer
;	In:	C = Port address of bank
;		HL = Pointer to start of virtual disk
nc100_vdisk_init:
	push	hl							; Save start address
	ld	b, 16							; Byte count to copy
	ld	de, nc100_vdisk_magic_header				; Disk magic header
	; Copy magic header
nc100_vdisk_init_magic_loop:
	ld	a, (de)							; Copy magic byte
	ld	(hl), a							; To memory card
	inc	hl							; Increment pointers
	inc	de
	djnz	nc100_vdisk_init_magic_loop				; Loop over header
	; Version
	ld	a, nc100_vdisk_version_number
	ld	(hl), a							; Set version number
	inc	hl
	; Disk info
	ld	b, 0x06
	xor	a
nc100_vdisk_init_disk_info:
	ld	(hl), a							; Clear disk information
	inc	hl
	djnz	nc100_vdisk_init_disk_info
	; Description
	ld	b, 0x20
	ld	a, ' '							; Blank disk description
nc100_vdisk_init_description:
	ld	(hl), a
	inc	hl
	djnz	nc100_vdisk_init_description
	pop	hl							; Reload start address
	ret

; # nc100_vdisk_create
; #################################
;  Create a vdisk of specfied size
;	In:	A = Drive size in 64k blocks
;		B = Drive address in 64k blocks
;		C = Port address of bank
;		HL = Pointer to start of virtual disk
;	Out:	Carry flag set if operation okay, unset if not
nc100_vdisk_create:
	ex	af, af'							; Swap out disk size
	call	nc100_vdisk_card_page_map_set				; Select vdisk
	ld	l, 0x00							; Reset pointer
	call	nc100_vdisk_card_check					; Check if there is a valid vdisk header
	jr	nc, nc100_vdisk_create_continue				; If there isn't, just proceed to create
	ld	l, nc100_vdisk_header_disk_size				; Get existing disk size
	ld	a, (hl)
	and	a							; Check if vdisk deleted
	jr	nz, nc100_vdisk_create_error				; It's not deleted, so error
nc100_vdisk_create_continue:
	ld	l, 0x00							; Reset pointer
	call	nc100_vdisk_init					; Create template header
	ld	l, nc100_vdisk_header_disk_size				; Set offset to disk size
	ld	ix, nc100_vdisk_parameters_table			; Get pointer to vdisk parameters table
	ex	af, af'							; Swap disk size back
	ld	d, a							; Copy size
nc100_vdisk_create_parameters_loop:
	ld	a, (ix+0)						; Get vdisk size from table
	cp	d							; Compare with selected vdisk size
	jr	z, nc100_vdisk_create_parameters_set
	cp	0xff							; Compare with stop byte
	jr	z, nc100_vdisk_create_error				; End of table, so error
	inc	ix							; Increment to next parameter set
	inc	ix
	inc	ix
	inc	ix
	jr	nc100_vdisk_create_parameters_loop			; Keep looping
nc100_vdisk_create_parameters_set:
	ld	(hl), a							; Set vdisk size
	dec	hl							; Decrement pointer
	ld	a, (ix+1)						; Get number of tracks
	ld	(hl), a							; Set vdisk number of tracks
	dec	hl							; Decrement pointer
	ld	a, (ix+2)						; Get sectors per track
	ld	(hl), a							; Set vdisk sectors per track
	dec	hl							; Decrement pointer
	ld	a, (ix+3)						; Get number of sectors
	ld	(hl), a							; Save vdisk number of sectors
nc100_vdisk_create_finish:
	scf								; Set Carry flag
	ret
nc100_vdisk_create_error:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_vdisk_delete
; #################################
;  Delete a selected vdisk (remove references from other vdisks, destroy header)
;	In:	B = Drive address in 64k blocks
;		C = Port address of bank
;		HL = Pointer to start of virtual disk
;	Out:	Carry flag set if operation okay, unset if not
nc100_vdisk_delete:
	call	nc100_vdisk_drive_remove				; Remove disk from any drive
	call	nc100_vdisk_card_page_map_set				; Select vdisk
	ld	l, 0x00							; Reset pointer
	call	nc100_vdisk_card_check					; Check if there is a valid vdisk header
	jr	nc, nc100_vdisk_delete_error
	ld	l, nc100_vdisk_header_disk_size				; Set offset to vdisk size
	ld	a, (hl)							; Check size
	and	a
	jr	z, nc100_vdisk_delete_error				; Do nothing if size zero
	xor	a							; Clear A
	ld	(hl), a							; Clear size
	cp	b							; Check if vdisk is the primary header (which can't be deleted)
	jr	z, nc100_vdisk_delete_finish
	ld	l, nc100_vdisk_header_prev_disk				; Set offset to vdisk previous
	ld	d, (hl)							; Load address of previous vdisk
	inc	hl
	ld	e, (hl)							; Load address of next vdisk
	ld	b, d
	call	nc100_vdisk_card_page_map_set				; Select previous vdisk
	ld	l, nc100_vdisk_header_next_disk
	ld	(hl), e							; Update with next pointer from deleted vdisk
	ld	b, e
	call	nc100_vdisk_card_page_map_set				; Select next vdisk
	ld	l, nc100_vdisk_header_prev_disk
	ld	(hl), d							; Update with previous pointer from deleted vdisk
nc100_vdisk_delete_finish:
	scf								; Set Carry flag
	ret
nc100_vdisk_delete_error:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_vdisk_size_convert
; #################################
;  Convert disk size from 64k to 1k
;	In:	A = Size in 64k blocks
;	Out:	HL = Size in 1k blocks
nc100_vdisk_size_convert:
	ld	hl, 0x0000
	ld	bc, 0x0040						; Increment value
nc100_vdisk_size_convert_loop:
	and	a
	jr	z, nc100_vdisk_size_convert_end				; If zero, just finish
	add	hl, bc							; Increment size
	dec	a
	jr	nc100_vdisk_size_convert_loop
nc100_vdisk_size_convert_end:
	ret
