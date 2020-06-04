; # Virtual disk routines
; ###########################################################################
;  A memory card can act as a virtual disk(s) for CP/M. A variety of disk sizes
;  can be supported 128k, 256k, 512k, and 1M depending on the size of the card.
;
;  Original spec:
;  --------------
;  The original disk specification was for a disk with a 128 bytes per sector,
;  26 sectors per track, and 73 tracks per disk. This gave a storage capacity
;  of 242944 bytes. The 1st 2 tracks in the original specification is reserved
;  for the system (CCP/BDOS/CBIOS) however. This is 0x1a00 (6656) bytes of data,
;  so in fact leaves a capacity of 236288 bytes.
;
;  Virtual disk:
;  -------------
;  To simplify the code, the original 128 byte sector size is retained.
;  The sectors per track is more than doubled to 0x2000 (8192) bytes, which
;  will waste storage in the system track, but make any address calculations
;  much easier. This can be double again for larger disk sizes where the wasted
;  storage will not be missed (much).
;
;   Disk Size   |  64k blocks   |  Sector Size  | Sectors/Track |  Num. Tracks
;  -----------------------------------------------------------------------------
;     128k      |     0x02      |   128 Bytes   |      32       |      32
;     256k      |     0x04      |   128 Bytes   |      32       |      64
;     512k      |     0x08      |   128 Bytes   |      32       |      128
;      1M       |     0x10      |   128 Bytes   |      64       |      128
;
;  Memory addressing:
;  Theoretical situation of accessing a 128k disk image starting at 0x0.
;
;   A16 | A15 | A14 | A13 | A12 | A11 | A10 |  A9 |  A8 |  A7 |  A6 |  A5 |  A4 |  A3 |  A2 |  A1 |  A0
;  ------------------------------------------------------------------------------------------------------
;        Num. Tracks (32)       |    Sectors per Track (32)   |             Sector Size (128)
;
;  So to access (Track: 0x05 / Sector: 0x17):
;   A16 | A15 | A14 | A13 | A12 | A11 | A10 |  A9 |  A8 |  A7 |  A6 |  A5 |  A4 |  A3 |  A2 |  A1 |  A0
;  ------------------------------------------------------------------------------------------------------
;    0  |  0  |  1  |  0  |  1  |  1  |  0  |  1  |  1  |  1  |  X  |  X  |  X  |  X  |  X  |  X  |  X
;
;  VDisk header:
;  -------------
;  In the original spec. the first sector of the first track is reserved for the
;  cold start loader. This is not needed as the monitor will handle loading the
;  system track. This space is reused to store information about the virtual disk
;  image.
;
;			| Bytes |        Description
;  ---------------------------------------------------------
;  Magic Number		|  16	| 0x2323232343504D564449534B23232323 (####CPMVDISK####)
;  Version		|   1	| Header version number
;  Bytes per Sector	|   1	|
;  Sectors per Track	|   1	|
;  Last Track		|   1	| Number of tracks - 1
;  Disk Size		|   1	| Virtual disk size in 64k blocks
;  Prev Disk		|   1	| Pointer to the start of the previous virtual disk in 64k blocks (MSB: A23-A16)
;  Next Disk		|   1	| Pointer to the start of the next virtual disk in 64k blocks (MSB: A23-A16)
;  Description		|  32	| ASCII description of the virtual disk, null terminated.
;
;  Card header:
;  ------------
;  The first vdisk header on a card also contains the card header at offset 0x40.
;  Card Size		|   1   | Total memory size in 64k blocks
;  VDisk0 Type		|   1	| Virtual disk type in CP/M drive 0
;  VDisk0 Pointer	|   1   | MSB pointer to disk image in CP/M drive 0
;  VDisk0 Size		|   1	| Virtual disk size
;  VDisk1 Type		|   1	| Virtual disk type in CP/M drive 1
;  VDisk1 Pointer	|   1   | MSB pointer to disk image in CP/M drive 1
;  VDisk1 Size		|   1	| Virtual disk size
;  VDisk2 Type		|   1	| Virtual disk type in CP/M drive 2
;  VDisk2 Pointer	|   1   | MSB pointer to disk image in CP/M drive 2
;  VDisk2 Size		|   1	| Virtual disk size
;  VDisk3 Type		|   1	| Virtual disk type in CP/M drive 3
;  VDisk3 Pointer	|   1   | MSB pointer to disk image in CP/M drive 3
;  VDisk3 Size		|   1	| Virtual disk size
;  VDisk4 Type		|   1	| Virtual disk type in CP/M drive 4
;  VDisk4 Pointer	|   1   | MSB pointer to disk image in CP/M drive 4
;  VDisk4 Size		|   1	| Virtual disk size
;  VDisk5 Type		|   1	| Virtual disk type in CP/M drive 5
;  VDisk5 Pointer	|   1   | MSB pointer to disk image in CP/M drive 5
;  VDisk5 Size		|   1	| Virtual disk size
;  VDisk6 Type		|   1	| Virtual disk type in CP/M drive 6
;  VDisk6 Pointer	|   1   | MSB pointer to disk image in CP/M drive 6
;  VDisk6 Size		|   1	| Virtual disk size
;  VDisk7 Type		|   1	| Virtual disk type in CP/M drive 7
;  VDisk7 Pointer	|   1   | MSB pointer to disk image in CP/M drive 7
;  VDisk7 Size		|   1	| Virtual disk size
;  VDisk8 Type		|   1	| Virtual disk type in CP/M drive 8
;  VDisk8 Pointer	|   1   | MSB pointer to disk image in CP/M drive 8
;  VDisk8 Size		|   1	| Virtual disk size
;  VDisk9 Type		|   1	| Virtual disk type in CP/M drive 9
;  VDisk9 Pointer	|   1   | MSB pointer to disk image in CP/M drive 9
;  VDisk9 Size		|   1	| Virtual disk size
;  VDisk10 Type		|   1	| Virtual disk type in CP/M drive 10
;  VDisk10 Pointer	|   1   | MSB pointer to disk image in CP/M drive 10
;  VDisk10 Size		|   1	| Virtual disk size
;  VDisk11 Type		|   1	| Virtual disk type in CP/M drive 11
;  VDisk11 Pointer	|   1   | MSB pointer to disk image in CP/M drive 11
;  VDisk11 Size		|   1	| Virtual disk size
;  VDisk12 Type		|   1	| Virtual disk type in CP/M drive 12
;  VDisk12 Pointer	|   1   | MSB pointer to disk image in CP/M drive 12
;  VDisk12 Size		|   1	| Virtual disk size
;  VDisk13 Type		|   1	| Virtual disk type in CP/M drive 13
;  VDisk13 Pointer	|   1   | MSB pointer to disk image in CP/M drive 13
;  VDisk13 Size		|   1	| Virtual disk size
;  VDisk14 Type		|   1	| Virtual disk type in CP/M drive 14
;  VDisk14 Pointer	|   1   | MSB pointer to disk image in CP/M drive 14
;  VDisk14 Size		|   1	| Virtual disk size
;  VDisk15 Type		|   1	| Virtual disk type in CP/M drive 15
;  VDisk15 Pointer	|   1   | MSB pointer to disk image in CP/M drive 15
;  VDisk15 Size		|   1	| Virtual disk size
; ###########################################################################

; # Defines
; ##################################################
nc100_vcard_header_vdisk_header_offset:	equ		0x40
nc100_vcard_header_size:		equ		0x00
nc100_vcard_header_drive0_type:		equ		0x01
nc100_vcard_header_drive0_pointer:	equ		0x02
nc100_vcard_header_drive0_size:		equ		0x03
nc100_vcard_header_drive1_type:		equ		0x04
nc100_vcard_header_drive1_pointer:	equ		0x05
nc100_vcard_header_drive1_size:		equ		0x06
nc100_vcard_header_drive2_type:		equ		0x07
nc100_vcard_header_drive2_pointer:	equ		0x08
nc100_vcard_header_drive2_size:		equ		0x09
nc100_vcard_header_drive3_type:		equ		0x0a
nc100_vcard_header_drive3_pointer:	equ		0x0b
nc100_vcard_header_drive3_size:		equ		0x0c
nc100_vcard_header_drive4_type:		equ		0x0d
nc100_vcard_header_drive4_pointer:	equ		0x0e
nc100_vcard_header_drive4_size:		equ		0x0f
nc100_vcard_header_drive5_type:		equ		0x10
nc100_vcard_header_drive5_pointer:	equ		0x11
nc100_vcard_header_drive5_size:		equ		0x12
nc100_vcard_header_drive6_type:		equ		0x13
nc100_vcard_header_drive6_pointer:	equ		0x14
nc100_vcard_header_drive6_size:		equ		0x15
nc100_vcard_header_drive7_type:		equ		0x16
nc100_vcard_header_drive7_pointer:	equ		0x17
nc100_vcard_header_drive7_size:		equ		0x18
nc100_vcard_header_drive8_type:		equ		0x19
nc100_vcard_header_drive8_pointer:	equ		0x1a
nc100_vcard_header_drive8_size:		equ		0x1b
nc100_vcard_header_drive9_type:		equ		0x1c
nc100_vcard_header_drive9_pointer:	equ		0x1d
nc100_vcard_header_drive9_size:		equ		0x1e
nc100_vcard_header_drive10_type:	equ		0x1f
nc100_vcard_header_drive10_pointer:	equ		0x20
nc100_vcard_header_drive10_size:	equ		0x21
nc100_vcard_header_drive11_type:	equ		0x22
nc100_vcard_header_drive11_pointer:	equ		0x23
nc100_vcard_header_drive11_size:	equ		0x24
nc100_vcard_header_drive12_type:	equ		0x25
nc100_vcard_header_drive12_pointer:	equ		0x26
nc100_vcard_header_drive12_size:	equ		0x27
nc100_vcard_header_drive13_type:	equ		0x28
nc100_vcard_header_drive13_pointer:	equ		0x29
nc100_vcard_header_drive13_size:	equ		0x2a
nc100_vcard_header_drive14_type:	equ		0x2b
nc100_vcard_header_drive14_pointer:	equ		0x2c
nc100_vcard_header_drive14_size:	equ		0x2d
nc100_vcard_header_drive15_type:	equ		0x2e
nc100_vcard_header_drive15_pointer:	equ		0x2f
nc100_vcard_header_drive15_size:	equ		0x30

nc100_vdisk_type_none:			equ		0x00
nc100_vdisk_type_ram:			equ		0x01
nc100_vdisk_type_rom:			equ		0x02

nc100_vdisk_header_version_ptr:		equ		0x10
nc100_vdisk_header_bytes_sector_ptr:	equ		0x11
nc100_vdisk_header_sectors_track_ptr:	equ		0x12
nc100_vdisk_header_last_tracks_ptr:	equ		0x13
nc100_vdisk_header_disk_size:		equ		0x14
nc100_vdisk_header_prev_disk:		equ		0x15
nc100_vdisk_header_next_disk:		equ		0x16
nc100_vdisk_header_description:		equ		0x17
nc100_vdisk_header_description_length:	equ		0x20				; Vdisk description width
nc100_vdisk_header_description_max:	equ		nc100_vdisk_header_description+nc100_vdisk_header_description_length-1

nc100_vdisk_version_number:		equ		0x01
nc100_vdisk_sector_1st:			equ		0x00
nc100_vdisk_max_drives:			equ		0x10
nc100_vdisk_format_char:		equ		0xe5
nc100_vdisk_sys_sectors:		equ		7168/128			; Total SYS bytes loadable/bytes per sector

nc100_vdisk_magic_header:		db		"####CPMVDISK####"

; # nc100_vdisk_card_check
; #################################
;  Checks whether a memory card is present and formated
;	In:	HL = Pointer to start of virtual disk
;	Out:	Carry flag set if card present, unset if not
nc100_vdisk_card_check:
	ld	de, nc100_vdisk_magic_header
nc100_vdisk_card_check_magic_loop:
	ld	a, (de)							; Get byte from magic header
	cp	(hl)							; Compare byte from disk header
	jr	nz, nc100_vdisk_card_check_failed
	inc	hl							; Increment pointers
	inc	de
	ld	a, l							; Check address
	cp	0x10
	jr	nz, nc100_vdisk_card_check_magic_loop
	scf								; Set Carry flag
	ret
nc100_vdisk_card_check_failed:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_vdisk_card_page_map_reset
; #################################
;  Resets to the first page of card memory
;	In:	C = Port address of bank
;	Out	B = Zeroed for other operations
nc100_vdisk_card_page_map_reset:
	ld	a, nc100_membank_CRAM|nc100_membank_0k			; Select page(0) memory card
	out	(c), a							; Set new mapping
	ld	b, 0x00
	ret

; # nc100_vdisk_card_page_map_get_64k
; #################################
;  Get the current mapped page
;	In:	C = Port address of bank
;	Out:	B = Mapping in 64k blocks
nc100_vdisk_card_page_map_get_64k:
	in	a, (c)							; Get the current memory bank configuration
	and	0x3f							; Filter bits 6 & 7
	srl	a							; Shift A so as to map to 64k blocks
	srl	a
	ld	b, a
	ret

; # nc100_vdisk_card_page_map_set_64k
; #################################
;  Updates the current mapped page
;	In:	B = New mapping in 64k blocks
;		C = Port address of bank
nc100_vdisk_card_page_map_set_64k:
	ld	a, b
	sla	a							; Shift A so as to map with page register format
	sla	a
	and	0x3f							; Filter bits 6 & 7
	or	nc100_membank_CRAM					; Select memory card
	out	(c), a							; Set new mapping
	ret

; # nc100_vdisk_card_page_map_next
; #################################
;  Updates to the next mapped page
;	In:	C = Port address of bank
;	Out:	B = Mapping in 64k blocks
;		Carry flag set if operation completed, unset if not (this will happen if the page mapping is out of bounds)
nc100_vdisk_card_page_map_next:
	in	a, (c)							; Get the current memory bank configuration
	and	0x3f							; Filter bits 6 & 7
	inc	a							; Increment page
	bit	6, a
	jr	nz, nc100_vdisk_card_page_map_next_rollover
	or	nc100_membank_CRAM					; Select memory card
	out	(c), a							; Set new mapping
	and	0x3f							; Filter bits 6 & 7
	srl	a							; Shift A so as to map to 64k blocks
	srl	a
	ld	b, a
	scf								; Set Carry flag
	ret
nc100_vdisk_card_page_map_next_rollover:
	scf								; Clear Carry flag
	ccf
	ret

; ###########################################################################
; # Drive operations
; ###########################################################################

; # nc100_vdisk_drive_get
; #################################
;  Retreive the pointer assigned to a drive
;	In:	A = Drive index
;		C = Port address of bank
;		HL = Pointer to start of virtual disk
;	Out:	B = Disk address in 64k blocks
;		Carry flag set if drive has assigned vdisk, unset if not
nc100_vdisk_drive_get:
	ex	af, af'							; Swap out drive index
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	ex	af, af'							; Swap drive index back in
	and	0x0f							; Filter value
	jr	z, nc100_vdisk_drive_get_continue			; If zero, skip calculating offset
	push	bc							; Save vdisk address/port
	ld	b, a							; Copy disk index
	xor	a							; Clear A
nc100_vdisk_drive_get_loop:
	add	0x03							; Drive config table offset
	djnz	nc100_vdisk_drive_get_loop
	pop	bc							; Restore vdisk address/port
nc100_vdisk_drive_get_continue:
	add	nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_drive0_type
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
; # VDisk operations
; ###########################################################################
;  Requires a number of memory based variables to be set beforehand.
;	var_vdisk_sector - Sector number of disk operation
;	var_vdisk_track - Track number of disk operation
;	var_vdisk_dma_addr - Address pointer to DMA memory area

; # nc100_vdisk_sector_seek_32spt
; #################################
;  Create the address to a memory position from track/sector info (32 sectors per track).
;	In:	B = Start address of vdisk in 64k blocks
;		C = Port address of bank
;		HL = Pointer to start of vdisk
;		IX = Operation to execute
;	Out:	Carry flag set if card present, unset if not
nc100_vdisk_sector_seek_32spt:
	; Track 0/Sector 0 is protected
	ld	a, (var_vdisk_track)
	and	a
	jr	nz, nc100_vdisk_sector_seek_32spt_cont
	ld	a, (var_vdisk_sector)
	and	a
	jr	nz, nc100_vdisk_sector_seek_32spt_cont
	scf								; Clear Carry flag
	ccf
	ret
nc100_vdisk_sector_seek_32spt_cont:
	ld	l, 0x00							; Make sure to reset LSB
	push	hl							; Save vdisk pointer
	; Process sector
	; With 32 sectors per track, value maps to A11-A7
	ld	a, (var_vdisk_sector)
	and	0x1f							; Filter sector value
	ld	h, a
	srl	h							; Right shift H into Carry
	rr	l							; And into L
	; Process track
	; Value maps to A19-A12
	; Split between:
	;	Page selection bits A19-A14
	;	Memory selection bits A13-A12
	ld	e, 0x00
	ld	a, (var_vdisk_track)
	and	0x7f							; Filter track value
	ld	d, a
	srl	d							; Split value in to page selection
	rr	e							; And memory bits
	srl	d
	rr	e
	; A13-A12
	srl	e							; Shift Memory bits
	srl	e							; To correct position
	; Calculate memory page
	ld	a, b
	sla	a							; Shift A so as to map with page register format
	sla	a
	and	0x3f							; Filter bits 6 & 7
	or	d							; Combine with track bits
	or	nc100_membank_CRAM					; Select memory card
	out	(c), a							; Set memory card page
	; Combine track/sector addresses
	ld	a, h							; Sector offset
	or	e							; Track offset
	ld	h, a							; Save combined offset
	ex	de,hl							; Exchange calculated offset
	pop	hl							; Restore vdisk pointer
	add	hl, de							; Combine vdisk pointer and offset

	jp	(ix)							; Jump to operation

; # nc100_vdisk_sector_seek_64spt
; #################################
;  Create the address to a memory position from track/sector info (64 sectors per track).
;	In:	B = Start address of vdisk in 64k blocks
;		C = Port address of bank
;		HL = Pointer to start of vdisk
;		IX = Operation to execute
;	Out:	Carry flag set if card present, unset if not
nc100_vdisk_sector_seek_64spt:
	; Track 0/Sector 0 is protected
	ld	a, (var_vdisk_track)
	and	a
	jr	nz, nc100_vdisk_sector_seek_64spt_cont
	ld	a, (var_vdisk_sector)
	and	a
	jr	nz, nc100_vdisk_sector_seek_64spt_cont
	scf								; Clear Carry flag
	ccf
	ret
nc100_vdisk_sector_seek_64spt_cont:
	ld	l, 0x00							; Make sure to reset LSB
	push	hl							; Save vdisk pointer
	; Process sector
	; With 64 sectors per track, value maps to A12-A7
	ld	a, (var_vdisk_sector)
	and	0x3f							; Filter sector value
	ld	h, a
	srl	h							; Right shift H into Carry
	rr	l							; And into L
	; Process track
	; Value maps to A19-A13
	; Split between:
	;	Page selection bits A19-A14
	;	Memory selection bits A13
	ld	e, 0x00
	ld	a, (var_vdisk_track)
	and	0x7f							; Filter track value
	ld	d, a
	srl	d							; Split value in to page selection
	rr	e							; And memory bits
	; A13
	srl	e							; Shift Memory bit
	srl	e							; To correct position
	; Calculate memory page
	ld	a, b
	sla	a							; Shift A so as to map with page register format
	sla	a
	and	0x3f							; Filter bits 6 & 7
	or	d							; Combine with track bits
	or	nc100_membank_CRAM					; Select memory card
	out	(c), a							; Set memory card page
	; Combine track/sector addresses
	ld	a, h							; Sector offset
	or	e							; Track offset
	ld	h, a							; Save combined offset
	ex	de,hl							; Exchange calculated offset
	pop	hl							; Restore vdisk pointer
	add	hl, de							; Combine vdisk pointer and offset

	jp	(ix)							; Jump to operation

; # nc100_vdisk_sector_read
; #################################
;  Read a sector from vdisk to DMA area
;  Note: memory page has already been set by sector seek operation)
;	In:	HL = Pointer to start of vdisk
;	Out:	Carry flag set if card present, unset if not
nc100_vdisk_sector_read:
	call	nc100_memory_memcard_present				; Check if memory card present
	ret	nc							; Exit if not
	ld	de, (var_vdisk_dma_addr)				; Get address of DMA area to read vdisk sector into
	ld	b, 0x80							; Number of bytes to read from vdisk
nc100_vdisk_sector_read_loop:
	ld	a, (hl)							; Get byte from vdisk
	ld	(de), a							; Write to DMA area
	inc	de							; Increment pointers
	inc	hl
	djnz	nc100_vdisk_sector_read_loop				; Loop over remain byte reads
	scf								; Set Carry flag
	ret

; # nc100_vdisk_sector_write
; #################################
;  Write the DMA area to a vdisk sector
;  Note: memory page has already been set by sector seek operation)
;	In:	HL = Pointer to start of vdisk
;	Out:	Carry flag set if card present, unset if not
nc100_vdisk_sector_write:
	call	nc100_memory_memcard_present				; Check if memory card present
	ret	nc							; Exit if not
	ld	de, (var_vdisk_dma_addr)				; Get address of DMA area to read vdisk sector into
	ld	b, 0x80							; Number of bytes to read from vdisk
nc100_vdisk_sector_write_loop:
	ld	a, (de)							; Get byte from DMA area
	ld	(hl), a							; Write to vdisk
	inc	de							; Increment pointers
	inc	hl
	djnz	nc100_vdisk_sector_write_loop				; Loop over remain byte reads
	scf								; Set Carry flag
	ret
