;**************************************************************
;*
;*             CP/M (2.2) BIOS for the NC100
;*
;**************************************************************

iobyte:		equ	0003h				; intel i/o byte
current_disk:	equ	0004h				; address of current disk number 0=a,... l5=p
num_disks:	equ	04h				; number of disks in the system
nsects:		equ	($-ccp_base)/128		; warm start sector count

org	bios_base					; origin of this program
seek	bios_offset

; jump vector for individual subroutines
	jp	boot					; cold start
warmboot_entry:
	jp	warmboot				; warm start
	jp	console_status				; console status
	jp	console_in				; console character in
	jp	console_out				; console character out
	jp	list_out				; list character out
	jp	punch_out				; punch character out
	jp	reader_in				; reader character out
	jp	disk_home				; move head to home position
	jp	disk_select				; select disk
	jp	disk_track_set				; set track number
	jp	disk_sector_set				; set sector number
	jp	disk_dma_set				; set dma address
	jp	disk_read				; read disk
	jp	disk_write				; write disk
	jp	list_status				; return list status
	jp	disk_sector_translate			; sector translate

; fixed data tables for four-drive standard
; ibm-compatible 8" disks
; no translations
disk_param_header:
; disk Parameter header for disk 00
	defw	0000h, 0000h
	defw	0000h, 0000h
	defw	dirbf, disk_param_block
	defw	chk00, all00
; disk parameter header for disk 01
	defw	0000h, 0000h
	defw	0000h, 0000h
	defw	dirbf, disk_param_block
	defw	chk01, all01
; disk parameter header for disk 02
	defw	0000h, 0000h
	defw	0000h, 0000h
	defw	dirbf, disk_param_block
	defw	chk02, all02
; disk parameter header for disk 03
	defw	0000h, 0000h
	defw	0000h, 0000h
	defw	dirbf, disk_param_block
	defw	chk03, all03

; sector translate vector
sector_translate:
	defm	 1,  7, 13, 19				; sectors  1,  2,  3,  4
	defm	25,  5, 11, 17				; sectors  5,  6,  7,  6
	defm	23,  3,  9, 15				; sectors  9, 10, 11, 12
	defm	21,  2,  8, 14				; sectors 13, 14, 15, 16
	defm	20, 26,  6, 12				; sectors 17, 18, 19, 20
	defm	18, 24,  4, 10				; sectors 21, 22, 23, 24
	defm	16, 22					; sectors 25, 26

; disk parameter block for all disks.
disk_param_block:
	defw	26					; sectors per track
	defm	3					; block shift factor
	defm	7					; block mask
	defm	0					; null mask
	defw	242					; disk size-1
	defw	63					; directory max
	defm	192					; alloc 0
	defm	0					; alloc 1
	defw	0					; check size
	defw	2					; track offset

; end of fixed tables

; individual subroutines to perform each function
; simplest case is to just perform parameter initialization
boot:
	XOR	a					; zero in the accum
	LD	(iobyte),A				; clear the iobyte
	LD	(current_disk),A			; select disk zero
	JP	go_cpm					; initialize and go to cp/m

; simplest case is to read the disk until all sectors loaded
warmboot:
	LD	sp, 80h					; use space below buffer for stack
	LD 	c, 0					; select disk 0
	call	disk_select
	call	disk_home				; go to track 00

	LD 	b, nsects				; b counts * of sectors to load
	LD 	c, 0					; c has the current track number
	LD 	d, 2					; d has the next sector to read
	; note that we begin by reading track 0, sector 2 since sector 1
	; contains the cold start loader, which is skipped in a warm start
	LD	HL, ccp_base				; base of cp/m (initial load point)
load1:							; load one more sector
	PUSH	BC					; save sector count, current track
	PUSH	DE					; save next sector to read
	PUSH	HL					; save dma address
	LD 	c, d					; get sector address to register C
	call	disk_sector_set				; set sector address from register C
	pop	BC					; recall dma address to b, C
	PUSH	BC					; replace on stack for later recall
	call	disk_dma_set				; set dma address from b, C

	; drive set to 0, track set, sector set, dma address set
	call	disk_read
	CP	00h					; any errors?
	JP	NZ,warmboot				; retry the entire boot if an error occurs

	; no error, move to next sector
	pop	HL					; recall dma address
	LD	DE, 128					; dma=dma+128
	ADD	HL,DE					; new dma address is in h, l
	pop	DE					; recall sector address
	pop	BC					; recall number of sectors remaining, and current trk
	DEC	b					; sectors=sectors-1
	JP	Z,go_cpm				; transfer to cp/m if all have been loaded

	; more sectors remain to load, check for track change
	INC	d
	LD 	a,d					; sector=27?, if so, change tracks
	CP	27
	JP	C,load1					; carry generated if sector<27

	; end of current track,	go to next track
	LD 	d, 1					; begin with first sector of next track
	INC	c					; track=track+1

	; save register state, and change tracks
	PUSH	BC
	PUSH	DE
	PUSH	HL
	call	disk_track_set				; track address set from register c
	pop	HL
	pop	DE
	pop	BC
	JP	load1					; for another sector

; end of load operation, set parameters and go to cp/m
go_cpm:
	LD 	a, 0c3h					; c3 is a jmp instruction
	LD	(0),A					; for jmp to warmboot
	LD	HL, warmboot_entry			; warmboot entry point
	LD	(1),HL					; set address field for jmp at 0

	LD	(5),A					; for jmp to bdos
	LD	HL, bdos_base				; bdos entry point
	LD	(6),HL					; address field of Jump at 5 to bdos

	LD	BC, 80h					; default dma address is 80h
	call	disk_dma_set

	ei						; enable the interrupt system
	LD	A,(current_disk)			; get current disk number
	cp	num_disks				; see if valid disk number
	jp	c,diskok				; disk valid, go to ccp
	ld	a,0					; invalid disk, change to disk 0
diskok:	LD 	c, a					; send to the ccp
	JP	ccp_base				; go to cp/m for further processing


; simple i/o handlers (must be filled in by user)
; in each case, the entry point is provided, with space reserved
; to insert your own code

; console status, return 0ffh if character ready, 00h if not
console_status:
	in 	a,(3)					; get status
	and 	002h					; check RxRDY bit
	jp 	z,no_char
	ld	a,0ffh					; char ready
	ret
no_char:ld	a,00h					; no char
	ret

; console character into register a
console_in:
	in 	a,(3)					; get status
	and 	002h					; check RxRDY bit
	jp 	z,console_in				; loop until char ready
	in 	a,(2)					; get char
	AND	7fh					; strip parity bit
	ret

; console character output from register c
console_out:
	in	a,(3)
	and	001h					; check TxRDY bit
	jp	z,console_out				; loop until port ready
	ld	a,c					; get the char
	out	(2),a					; out to port
	ret

; list character from register c
list_out:
	LD 	a, c	  				; character to register a
	ret		  				; null subroutine

; return list status (0 if not ready, 1 if ready)
list_status:
	XOR	a	 				; 0 is always ok to return
	ret

; punch	character from register C
punch_out:
	LD 	a, c					; character to register a
	ret						; null subroutine

; reader character into register a from reader device
reader_in:
	LD     a, 1ah					; enter end of file for now (replace later)
	AND    7fh					; remember to strip parity bit
	ret

; i/o drivers for the disk follow
; for now, we will simply store the parameters away for use
; in the read and write	subroutines

; move to the track 00	position of current drive
disk_home:
	; translate this call into a disk_track_set call with Parameter 00
	LD     c, 0					; select track 0
	call   disk_track_set
	ret						; we will move to 00 on first read/write

; select disk given by register c
disk_select:
	LD	HL, 0000h				; error return code
	LD 	a, c
	LD	(diskno),A
	CP	num_disks				; must be between 0 and 3
	RET	NC					; no carry if 4, 5,...
	; disk number is in the proper range
	; defs	10					; space for disk select
	; compute proper disk Parameter header address
	LD	A,(diskno)
	LD 	l, a					; l=disk number 0, 1, 2, 3
	LD 	h, 0					; high order zero
	ADD	HL,HL					; *2
	ADD	HL,HL					; *4
	ADD	HL,HL					; *8
	ADD	HL,HL					; *16 (size of each header)
	LD	DE, disk_param_header
	ADD	HL,DE					; hl=,disk_param_header (diskno*16) Note typo here in original source.
	ret

; set track given by register c
disk_track_set:
	LD 	a, c
	LD	(track),A
	ret

; set sector given by register c
disk_sector_set:
	LD 	a, c
	LD	(sector),A
	ret

disk_sector_translate:
	;translate the sector given by bc using the
	;translate table given by de
	EX	DE,HL					; hl=.sector_translate
	ADD	HL,BC					; hl=.sector_translate (sector)
	ret						; debug no translation
	LD 	l, (hl)					; l=sector_translate (sector)
	LD 	h, 0					; hl=sector_translate (sector)
	ret						; with value in hl

; set dma address given by registers b and c
disk_dma_set:
	LD 	l, c					; low order address
	LD 	h, b					; high order address
	LD	(dmaad),HL				; save the address
	ret

disk_read:
;Read one CP/M sector from disk.
;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read.
;Disk number in 'diskno'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaad' (0-65535)
;
			ld	hl,hstbuf		;buffer to place disk sector (256 bytes)
rd_status_loop_1:	in	a,(0fh)			;check status
			and	80h			;check BSY bit
			jp	nz,rd_status_loop_1	;loop until not busy
rd_status_loop_2:	in	a,(0fh)			;check	status
			and	40h			;check DRDY bit
			jp	z,rd_status_loop_2	;loop until ready
			ld	a,01h			;number of sectors = 1
			out	(0ah),a			;sector count register
			ld	a,(sector)		;sector
			out	(0bh),a			;lba bits 0 - 7
			ld	a,(track)		;track
			out	(0ch),a			;lba bits 8 - 15
			ld	a,(diskno)		;disk (only bits 
			out	(0dh),a			;lba bits 16 - 23
			ld	a,11100000b		;LBA mode, select host drive 0
			out	(0eh),a			;drive/head register
			ld	a,20h			;Read sector command
			out	(0fh),a
rd_wait_for_DRQ_set:	in	a,(0fh)			;read status
			and	08h			;DRQ bit
			jp	z,rd_wait_for_DRQ_set	;loop until bit set
rd_wait_for_BSY_clear:	in	a,(0fh)
			and	80h
			jp	nz,rd_wait_for_BSY_clear
			in	a,(0fh)			;clear INTRQ
read_loop:		in	a,(08h)			;get data
			ld	(hl),a
			inc	hl
			in	a,(0fh)			;check status
			and	08h			;DRQ bit
			jp	nz,read_loop		;loop until clear
			ld	hl,(dmaad)		;memory location to place data read from disk
			ld	de,hstbuf		;host buffer
			ld	b,128			;size of CP/M sector
rd_sector_loop:		ld	a,(de)			;get byte from host buffer
			ld	(hl),a			;put in memory
			inc	hl
			inc	de
			djnz	rd_sector_loop		;put 128 bytes into memory
			in	a,(0fh)			;get status
			and	01h			;error bit
			ret

disk_write:
;Write one CP/M sector to disk.
;Return a 00h in register a if the operation completes properly, and 0lh if an error occurs during the read or write
;Disk number in 'diskno'
;Track number in 'track'
;Sector number in 'sector'
;Dma address in 'dmaad' (0-65535)
			ld	hl,(dmaad)		;memory location of data to write
			ld	de,hstbuf		;host buffer
			ld	b,128			;size of CP/M sector
wr_sector_loop:		ld	a,(hl)			;get byte from memory
			ld	(de),a			;put in host buffer
			inc	hl
			inc	de
			djnz	wr_sector_loop		;put 128 bytes in host buffer
			ld	hl,hstbuf		;location of data to write to disk
wr_status_loop_1:	in	a,(0fh)			;check status
			and	80h			;check BSY bit
			jp	nz,wr_status_loop_1	;loop until not busy
wr_status_loop_2:	in	a,(0fh)			;check	status
			and	40h			;check DRDY bit
			jp	z,wr_status_loop_2	;loop until ready
			ld	a,01h			;number of sectors = 1
			out	(0ah),a			;sector count register
			ld	a,(sector)
			out	(0bh),a			;lba bits 0 - 7 = "sector"
			ld	a,(track)
			out	(0ch),a			;lba bits 8 - 15 = "track"
			ld	a,(diskno)
			out	(0dh),a			;lba bits 16 - 23, use 16 to 20 for "disk"
			ld	a,11100000b		;LBA mode, select drive 0
			out	(0eh),a			;drive/head register
			ld	a,30h			;Write sector command
			out	(0fh),a
wr_wait_for_DRQ_set:	in	a,(0fh)			;read status
			and	08h			;DRQ bit
			jp	z,wr_wait_for_DRQ_set	;loop until bit set			
write_loop:		ld	a,(hl)
			out	(08h),a			;write data
			inc	hl
			in	a,(0fh)			;read status
			and	08h			;check DRQ bit
			jp	nz,write_loop		;write until bit cleared
wr_wait_for_BSY_clear:	in	a,(0fh)
			and	80h
			jp	nz,wr_wait_for_BSY_clear
			in	a,(0fh)			;clear INTRQ
			and	01h			;check for error
			ret

;	the remainder of the cbios is reserved uninitialized
;	data area, and does not need to be a Part of the
;	system	memory image (the space must be available,
;	however, between"begdat" and"enddat").
;
track:	defs	2		;two bytes for expansion
sector:	defs	2		;two bytes for expansion
dmaad:	defs	2		;direct memory address
diskno:	defs	1		;disk number 0-15
;
;	scratch ram area for bdos use
begdat:	equ	$	 	;beginning of data area
dirbf:	defs	128	 	;scratch directory area
all00:	defs	31	 	;allocation vector 0
all01:	defs	31	 	;allocation vector 1
all02:	defs	31	 	;allocation vector 2
all03:	defs	31	 	;allocation vector 3
chk00:	defs	16		;check vector 0
chk01:	defs	16		;check vector 1
chk02:	defs	16	 	;check vector 2
chk03:	defs	16	 	;check vector 3
;
enddat:	equ	$	 	;end of data area
datsiz:	equ	$-begdat;	;size of data area
hstbuf: ds	256		;buffer for host disk sector
