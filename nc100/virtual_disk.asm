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
;   Disk Size   |  Sector Size  | Track Sectors |  Num. Tracks
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
;           Tracks (32)         |    Sectors per Track (32)   |            Sector Bytes (128)
;
;  So to access (Track: 0x05 / Sector: 0x17):
;   A16 | A15 | A14 | A13 | A12 | A11 | A10 |  A9 |  A8 |  A7 |  A6 |  A5 |  A4 |  A3 |  A2 |  A1 |  A0
;  ------------------------------------------------------------------------------------------------------
;    0  |  0  |  1  |  0  |  1  |  1  |  0  |  1  |  1  |  1  |  X  |  X  |  X  |  X  |  X  |  X  |  X
;
;  Disk id:
;  --------
;  In the original spec. the first sector of the first track is reserved for the
;  cold start loader. This is not needed as the monitor will handle loading the
;  system track. This space is reused to store information about the virtual disk
;  image.
;
;               | Bytes |        Description
;  -------------------------------------------------
;  Magic Number |  16   | 0x2323232343504D564449534B23232323 (####CPMVDISK####)
;  Version      |   1   | Format version
;  Card Size    |   1   | Total memory size in 64k blocks
;  Disk Number  |   1   | Disk number within CP/M
;  Disk Size    |   1   | Virtual disk size in 64k blocks
;  End Address  |   1   | Pointer to end of the disk (MSB: A23-A16)
;  Name		|  64   | ASCII description of the virtual disk, null terminated.
;
; ###########################################################################

; # Defines
; ##################################################
nc100_vdisk_magic_header:		db		"####CPMVDISK####"
str_unformat:				db		"Un"
str_format:				db		"Format",0
str_ted:				db		"ted",0

; # nc100_vdisk_card_check
; #################################
;  Checks whether a memory card is present and formated
;	In:	HL = Pointer to start of virtual disk
;	Out:	Carry flag set if card present, unset if not
;		A = Card size in 32k blocks if formated, -1 if not
nc100_vdisk_card_check:
	ld	de, nc100_vdisk_magic_header
nc100_vdisk_card_check_magic_loop:
	ld	a, (de)							; Get byte from disk header
	cp	(hl)							; Compare byte from magic header
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

; # nc100_vdisk_card_header_init
; #################################
;  Write the basic header info to pointer
;	In:	C = Port address of bank
;		HL = Pointer to start of virtual disk
nc100_vdisk_card_header_init:
	push	hl							; Save start address
	ld	b, 16
	ld	de, nc100_vdisk_magic_header
	; Copy magic header
nc100_vdisk_card_header_init_magic_loop:
	ld	a, (de)							; Copy magic byte
	ld	(hl), a							; To memory card
	inc	hl
	inc	de
	djnz	nc100_vdisk_card_header_init_magic_loop
	; Version
	ld	a, 0x01
	ld	(hl), a
	inc	hl
	; Card Size
	ld	a, 0x00							; Card size: not detected
	ld	(hl), a
	; Detect size by looking for the header reoccuring
	ld	b, 0x00							; 64k block count
nc100_vdisk_card_header_init_card_size:
	inc	b							; Increment block count
	in	a, (c)							; Get memory config
	and	0x3f							; Filter address bits
	add	0x04							; Increment by 64k
	cp	0x40							; Check for overrun
	jr	z, nc100_vdisk_card_header_init_finish
	or	nc100_membank_CRAM					; Select card RAM
	out	(c), a							; Select next page
	pop	hl							; Reload start address
	push	hl
	call	nc100_vdisk_card_check
	jr	nc, nc100_vdisk_card_header_init_card_size
nc100_vdisk_card_header_init_finish:
	ld	a, nc100_membank_CRAM|nc100_membank_0k			; Select first page of the card RAM
	out	(c), a							; Select next page
	pop	hl							; Reload start address
	ld	l, 0x11							; Set address of card size
	ld	(hl), b							; Save card size
	ret
