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
;   Disk Size   |  Sector Size  | Sectors/Track |  Num. Tracks
;  -------------------------------------------------------------
;     128k      |   128 Bytes   |      32       |      32
;     256k      |   128 Bytes   |      32       |      64
;     512k      |   128 Bytes   |      32       |      128
;      1M       |   128 Bytes   |      64       |      128
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
;  Next Disk		|   1	| Pointer to the start of the next virtual disk in 64k blocks (MSB: A23-A16)
;  Description		|  32	| ASCII description of the virtual disk, null terminated.
;
;  Card header:
;  ------------
;  The first vdisk header on a card also contains the card header at offset 0x40.
;  Card Size		|   1   | Total memory size in 64k blocks
;  VDisk0 Type		|   1	| Virtual disk type in CP/M drive 0
;  VDisk0 Pointer	|   1   | MSB pointer to disk image in CP/M drive 0
;  VDisk1 Type		|   1	| Virtual disk type in CP/M drive 1
;  VDisk1 Pointer	|   1   | MSB pointer to disk image in CP/M drive 1
;  VDisk2 Type		|   1	| Virtual disk type in CP/M drive 2
;  VDisk2 Pointer	|   1   | MSB pointer to disk image in CP/M drive 2
;  VDisk3 Type		|   1	| Virtual disk type in CP/M drive 3
;  VDisk3 Pointer	|   1   | MSB pointer to disk image in CP/M drive 3
;  VDisk4 Type		|   1	| Virtual disk type in CP/M drive 4
;  VDisk4 Pointer	|   1   | MSB pointer to disk image in CP/M drive 4
;  VDisk5 Type		|   1	| Virtual disk type in CP/M drive 5
;  VDisk5 Pointer	|   1   | MSB pointer to disk image in CP/M drive 5
;  VDisk6 Type		|   1	| Virtual disk type in CP/M drive 6
;  VDisk6 Pointer	|   1   | MSB pointer to disk image in CP/M drive 6
;  VDisk7 Type		|   1	| Virtual disk type in CP/M drive 7
;  VDisk7 Pointer	|   1   | MSB pointer to disk image in CP/M drive 7
;  VDisk8 Type		|   1	| Virtual disk type in CP/M drive 8
;  VDisk8 Pointer	|   1   | MSB pointer to disk image in CP/M drive 8
;  VDisk9 Type		|   1	| Virtual disk type in CP/M drive 9
;  VDisk9 Pointer	|   1   | MSB pointer to disk image in CP/M drive 9
;  VDisk10 Type		|   1	| Virtual disk type in CP/M drive 10
;  VDisk10 Pointer	|   1   | MSB pointer to disk image in CP/M drive 10
;  VDisk11 Type		|   1	| Virtual disk type in CP/M drive 11
;  VDisk11 Pointer	|   1   | MSB pointer to disk image in CP/M drive 11
;  VDisk12 Type		|   1	| Virtual disk type in CP/M drive 12
;  VDisk12 Pointer	|   1   | MSB pointer to disk image in CP/M drive 12
;  VDisk13 Type		|   1	| Virtual disk type in CP/M drive 13
;  VDisk13 Pointer	|   1   | MSB pointer to disk image in CP/M drive 13
;  VDisk14 Type		|   1	| Virtual disk type in CP/M drive 14
;  VDisk14 Pointer	|   1   | MSB pointer to disk image in CP/M drive 14
;  VDisk15 Type		|   1	| Virtual disk type in CP/M drive 15
;  VDisk15 Pointer	|   1   | MSB pointer to disk image in CP/M drive 15
; ###########################################################################

; # Defines
; ##################################################
nc100_vcard_header_vdisk_header_offset:	equ		0x40
nc100_vcard_header_size:		equ		0x00
nc100_vcard_header_vdisk0_type:		equ		0x01
nc100_vcard_header_vdisk0_pointer:	equ		0x02
nc100_vcard_header_vdisk1_type:		equ		0x03
nc100_vcard_header_vdisk1_pointer:	equ		0x04
nc100_vcard_header_vdisk2_type:		equ		0x05
nc100_vcard_header_vdisk2_pointer:	equ		0x06
nc100_vcard_header_vdisk3_type:		equ		0x07
nc100_vcard_header_vdisk3_pointer:	equ		0x08
nc100_vcard_header_vdisk4_type:		equ		0x09
nc100_vcard_header_vdisk4_pointer:	equ		0x0a
nc100_vcard_header_vdisk5_type:		equ		0x0b
nc100_vcard_header_vdisk5_pointer:	equ		0x0c
nc100_vcard_header_vdisk6_type:		equ		0x0d
nc100_vcard_header_vdisk6_pointer:	equ		0x0e
nc100_vcard_header_vdisk7_type:		equ		0x0f
nc100_vcard_header_vdisk7_pointer:	equ		0x10
nc100_vcard_header_vdisk8_type:		equ		0x11
nc100_vcard_header_vdisk8_pointer:	equ		0x12
nc100_vcard_header_vdisk9_type:		equ		0x13
nc100_vcard_header_vdisk9_pointer:	equ		0x14
nc100_vcard_header_vdisk10_type:	equ		0x15
nc100_vcard_header_vdisk10_pointer:	equ		0x16
nc100_vcard_header_vdisk11_type:	equ		0x17
nc100_vcard_header_vdisk11_pointer:	equ		0x18
nc100_vcard_header_vdisk12_type:	equ		0x19
nc100_vcard_header_vdisk12_pointer:	equ		0x1a
nc100_vcard_header_vdisk13_type:	equ		0x1b
nc100_vcard_header_vdisk13_pointer:	equ		0x1c
nc100_vcard_header_vdisk14_type:	equ		0x1d
nc100_vcard_header_vdisk14_pointer:	equ		0x1e
nc100_vcard_header_vdisk15_type:	equ		0x1f
nc100_vcard_header_vdisk15_pointer:	equ		0x20

nc100_vdisk_header_version_ptr:		equ		0x10
nc100_vdisk_header_bytes_sector_ptr:	equ		0x11
nc100_vdisk_header_sectors_track_ptr:	equ		0x12
nc100_vdisk_header_last_tracks_ptr:	equ		0x13
nc100_vdisk_header_disk_size:		equ		0x14
nc100_vdisk_header_next_disk:		equ		0x15
nc100_vdisk_header_description:		equ		0x16

nc100_vdisk_version_number:		equ		0x01

nc100_vdisk_init_header:		db		"####INITDISK####"
nc100_vdisk_magic_header:		db		"####CPMVDISK####"
str_unformat:				db		"Un"
str_format:				db		"Format",0
str_ted:				db		"ted",0
str_card:				db		"Card",0
str_disk:				db		"Disk",0
str_size:				db		"Size",0
str_virtual:				db		"Virtual",0

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

; # nc100_vdisk_card_init
; #################################
;  Write the basic card info to pointer
;	In:	C = Port address of bank
;		HL = Pointer to start of virtual disk
nc100_vdisk_card_init:
	push	hl							; Save start address
	ld	b, 16
	ld	de, nc100_vdisk_init_header				; Need different header so as not to match existing imaages
	call	nc100_vdisk_card_page_map_reset				; Select start of memory card
	; Copy init header
nc100_vdisk_card_init_magic_loop:
	ld	a, (de)							; Copy magic byte
	ld	(hl), a							; To memory card
	inc	hl
	inc	de
	djnz	nc100_vdisk_card_init_magic_loop
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
	; Clear disk selection table
	ld	l, nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_vdisk0_type
	ld	b, 0x20							; 16 disks of 2 bytes
	xor	a							; Clear A
nc100_vdisk_card_init_disk_select_table:
	ld	(hl), a
	inc	hl
	djnz	nc100_vdisk_card_init_disk_select_table

	ld	l, 0							; Reset pointer
	call	nc100_vdisk_init					; Write first disk header
	ret

; # nc100_vdisk_card_page_map_reset
; #################################
;  Resets to the first page of card memory
;	In:	C = Port address of bank
nc100_vdisk_card_page_map_reset:
	ld	a, nc100_membank_CRAM|nc100_membank_0k			; Select page(0) memory card
	out	(c), a							; Set new mapping
	ret

; # nc100_vdisk_card_page_map_set
; #################################
;  Updates the current mapped page
;	In:	B = New mapping in 64k blocks
;		C = Port address of bank
nc100_vdisk_card_page_map_set:
	ld	a, b
	sla	a							; Shift A so as to map with page register format
	sla	a
	and	0x3f							; Filter bits 6 & 7
	or	nc100_membank_CRAM					; Select memory card
	out	(c), a							; Set new mapping
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

; # nc100_vdisk_init
; #################################
;  Write the basic vdisk header to pointer
;	In:	C = Port address of bank
;		HL = Pointer to start of virtual disk
nc100_vdisk_init:
	push	hl							; Save start address
	ld	b, 16
	ld	de, nc100_vdisk_magic_header
	; Copy magic header
nc100_vdisk_init_magic_loop:
	ld	a, (de)							; Copy magic byte
	ld	(hl), a							; To memory card
	inc	hl
	inc	de
	djnz	nc100_vdisk_init_magic_loop
	; Version
	ld	a, nc100_vdisk_version_number
	ld	(hl), a
	inc	hl
	; Disk info
	ld	b, 0x05
	xor	a
nc100_vdisk_init_disk_info:
	ld	(hl), a							; Clear disk information
	inc	hl
	djnz	nc100_vdisk_init_disk_info
	; Description
	ld	b, 0x20
	ld	a, ' '
nc100_vdisk_init_description:
	ld	(hl), a
	inc	hl
	djnz	nc100_vdisk_init_description
	pop	hl							; Reload start address
	ret
