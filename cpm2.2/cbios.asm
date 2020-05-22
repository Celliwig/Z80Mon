;**************************************************************
;*
;*             CP/M (2.2) BIOS for the NC100
;*
;**************************************************************

iobyte:			equ	0003h			; intel i/o byte
current_disk:		equ	0004h			; address of current disk number 0=a,... l5=p
num_disks:		equ	04h			; number of disks in the system
nsects:			equ	($-ccp_base)/128	; warm start sector count

org	bios_base					; origin of this program
seek	bios_offset

; Jump vector for individual subroutines
;**************************************************************
	jp	boot					; Cold start
warmboot_entry:
	jp	warmboot				; Warm start
	jp	console_status				; Console status
	jp	console_in				; Read character from console in
	jp	console_out				; Write character to console out
	jp	list_out				; Write character to list device
	jp	punch_out				; Write character to punch device
	jp	reader_in				; Read character from reader device
	jp	disk_home				; Move disk head to home position
	jp	disk_select				; Select disk drive
	jp	disk_track_set				; Set disk track number
	jp	disk_sector_set				; Set disk sector number
	jp	disk_dma_set				; Set dma address for disk operations
	jp	disk_read				; Read from disk
	jp	disk_write				; Write to disk
	jp	list_status				; Return list device status
	jp	disk_sector_translate			; Translate disk sector from virtual to physical

; Fixed data tables for four-drive standard ibm-compatible
; 8" disks no translations
;**************************************************************
disk_param_header:
; disk Parameter header for disk 00
	dw	0000h, 0000h
	dw	0000h, 0000h
	dw	directory_buffer, disk_param_block
	dw	directory_check00, storage_alloc00
; disk parameter header for disk 01
	dw	0000h, 0000h
	dw	0000h, 0000h
	dw	directory_buffer, disk_param_block
	dw	directory_check01, storage_alloc01
; disk parameter header for disk 02
	dw	0000h, 0000h
	dw	0000h, 0000h
	dw	directory_buffer, disk_param_block
	dw	directory_check02, storage_alloc02
; disk parameter header for disk 03
	dw	0000h, 0000h
	dw	0000h, 0000h
	dw	directory_buffer, disk_param_block
	dw	directory_check03, storage_alloc03

;; Sector translate vector
;;**************************************************************
;sector_translate:
;	db	 1,  7, 13, 19				; sectors  1,  2,  3,  4
;	db	25,  5, 11, 17				; sectors  5,  6,  7,  6
;	db	23,  3,  9, 15				; sectors  9, 10, 11, 12
;	db	21,  2,  8, 14				; sectors 13, 14, 15, 16
;	db	20, 26,  6, 12				; sectors 17, 18, 19, 20
;	db	18, 24,  4, 10				; sectors 21, 22, 23, 24
;	db	16, 22					; sectors 25, 26

; Disk parameter block for all disks.
;**************************************************************
disk_param_block:
	dw	26					; sectors per track
	db	3					; block shift factor
	db	7					; block mask
	db	0					; null mask
	dw	242					; disk size-1
	dw	63					; directory max
	db	192					; alloc 0
	db	0					; alloc 1
	dw	0					; check size
	dw	2					; track offset

; end of fixed tables

; boot
;**************************************************************
;  Cold boot routine
boot:
	xor	a					; Clear A
	ld	(iobyte), a				; Clear the iobyte
	ld	(current_disk), a			; Select disk zero
	jr	go_cpm					; Initialize and go to cp/m

; warmboot
;**************************************************************
;  Simplest case is to read the disk until all sectors loaded
warmboot:
	ld	sp, 0x80				; Use space below buffer for stack
	ld 	c, 0					; Select disk 0
	call	disk_select
	call	disk_home				; Go to track 00

	ld 	b, nsects				; B counts * of sectors to load
	ld 	c, 0					; C has the current track number
	ld 	d, nc100_vdisk_sector_1st+1		; D has the next sector to read (skip first sector)
							; Note that we begin by reading track 0, sector 1 since sector 0
							; contains the cold start loader, which is skipped in a warm start
	ld	hl, ccp_base				; Base of cp/m (initial load point)
warmboot_sector_load_next:				; Load one more sector
	push	bc					; Save sector count, current track
	push	de					; Save next sector to read
	push	hl					; Save dma address
	ld	c, d					; Get sector address to C
	call	disk_sector_set				; Set sector address from C
	pop	bc					; Recall dma address to BC
	push	bc					; Replace on stack for later recall
	call	disk_dma_set				; Set dma address from BC

	; drive set to 0, track set, sector set, dma address set
	call	disk_read
	cp	0x00					; Any errors?
	jr	nz, warmboot				; Retry the entire boot if an error occurs

	; no error, move to next sector
	pop	hl					; Recall dma address
	ld	de, 128					; DMA = DMA + 128
	add	hl, de					; New DMA address is in HL
	pop	de					; Recall sector address
	pop	bc					; Recall number of sectors remaining, and current track
	dec	b					; Sectors = Sectors - 1
	jr	z, go_cpm				; Transfer to CP/M if all have been loaded

	; more sectors remain to load, check for track change
	inc	d
; It's all on one track so disable track change
;	ld	a, d					; Sector = 27?, if so, change tracks
;	cp	27
;	jp	c, warmboot_sector_load_next		; Carry generated if sector<27
;
;	; end of current track,	go to next track
;	ld 	d, 1					; Begin with first sector of next track
;	inc	c					; Track=track+1
;
;	; save register state, and change tracks
;	push	bc
;	push	de
;	push	hl
;	call	disk_track_set				; Track address set from register c
;	pop	hl
;	pop	de
;	pop	bc
	jr	warmboot_sector_load_next		; for another sector

; end of load operation, set parameters and go to CP/M
go_cpm:
	ld 	a, 0xc3					; C3 is a jmp instruction
	ld	(0), a					; For jmp to warmboot
	ld	hl, warmboot_entry			; Warmboot entry point
	ld	(1), hl					; Set address field for jmp at 0

	ld	(5), a					; For jmp to bdos
	ld	hl, bdos_base				; BDOS entry point
	ld	(6), hl					; Set address field for jmp at 5 to BDOS

	ld	bc, 0x80				; Default DMA address is 0x80
	call	disk_dma_set

	ei						; Enable the interrupt system
	ld	a, (current_disk)			; Get current disk number
	cp	num_disks				; See if valid disk number
	jp	c, go_cpm_disk_ok			; Disk valid, go to CCP
	ld	a, 0					; Invalid disk, change to disk 0
go_cpm_disk_ok:
	ld 	c, a					; Send to the CCP
	jp	ccp_base				; Go to CP/M for further processing

;**************************************************************
; I/O device handlers (console/list/punch/reader)
;**************************************************************

; console_status
;**************************************************************
;  Returns the console input status
;	Out:	A = 0xff if character ready, 0x00 if not
console_status:
	in 	a,(3)					; get status
	and 	002h					; check RxRDY bit
	jp 	z,no_char
	ld	a,0ffh					; char ready
	ret
no_char:ld	a,00h					; no char
	ret

; console_in
;**************************************************************
;  Read in a character from console input
;	Out:	A = Character
console_in:
	in 	a,(3)					; get status
	and 	002h					; check RxRDY bit
	jp 	z,console_in				; loop until char ready
	in 	a,(2)					; get char
	AND	7fh					; strip parity bit
	ret

; console_out
;**************************************************************
;  Write a character out to the console
;	In:	C = Character
console_out:
	in	a,(3)
	and	001h					; check TxRDY bit
	jp	z,console_out				; loop until port ready
	ld	a,c					; get the char
	out	(2),a					; out to port
	ret

; list_out
;**************************************************************
;  Write out a character to the list device
;	In:	C = Character
list_out:
	ld 	a, c	  				; Character to A
	ret		  				; Null subroutine

; list_status
;**************************************************************
;  Returns the status of the list device
;	Out:	A = 1 if ready, 0 if not
list_status:
	xor	a	 				; 0 is always ok to return
	ret

; punch_out
;**************************************************************
;  Write a character to the punch device
;	In:	C = Character
punch_out:
	ld 	a, c					; Character to A
	ret						; Null subroutine

; reader_in
;**************************************************************
;  Read a character from the reader device
;	Out:	A = Character
reader_in:
	ld	a, 0x1a					; Enter end of file for now (replace later)
	and	0x7f					; Remember to strip parity bit
	ret

;**************************************************************
; Disk device handler
;**************************************************************

; disk_home
;**************************************************************
;  Move the head to the first track (00)
disk_home:
	; translate this call into a disk_track_set call with Parameter 00
	ld	c, 0					; select track 0
	call	disk_track_set
	ret						; we will move to 00 on first read/write

; disk_select
;**************************************************************
;  Select disk drive
;	In:	C = Drive to select
disk_select:
	ld	hl, 0000h				; error return code
	ld 	a, c
	ld	(diskno), a
	cp	num_disks				; must be between 0 and 3
	ret	nc					; no carry if 4, 5,...
	; disk number is in the proper range
	; defs	10					; space for disk select
	; compute proper disk Parameter header address
	ld	a, (diskno)
	ld 	l, a					; l=disk number 0, 1, 2, 3
	ld 	h, 0					; high order zero
	add	hl, hl					; *2
	add	hl, hl					; *4
	add	hl, hl					; *8
	add	hl, hl					; *16 (size of each header)
	ld	de, disk_param_header
	add	hl, de					; hl=,disk_param_header (diskno*16) Note typo here in original source.
	ret

; disk_track_set
;**************************************************************
;  Set disk track for following operations
;	In:	C = Disk track
disk_track_set:
	ld 	a, c
	ld	(track), a
	ret

; disk_sector_set
;**************************************************************
;  Set disk sector for following operations
;	In:	C = Disk sector
disk_sector_set:
	ld 	a, c
	ld	(sector), a
	ret

; disk_sector_translate
;**************************************************************
;  Translate a disk sector from virtual to physical
;	In:	BC = Virtual sector
;		DE = Sector translation table
;	Out:	HL = Physical sector
disk_sector_translate:
	;translate the sector given by bc using the
	;translate table given by de
	ex	de, hl					; hl=.sector_translate
	add	hl, bc					; hl=.sector_translate (sector)
	ret						; debug no translation
	ld	l, (hl)					; l=sector_translate (sector)
	ld	h, 0					; hl=sector_translate (sector)
	ret						; with value in hl

; disk_dma_set
;**************************************************************
;  Set DMA address for following operations
;	In:	BC = DMA buffer address
disk_dma_set:
	ld	l, c					; low order address
	ld	h, b					; high order address
	ld	(dmaad), hl				; save the address
	ret

; disk_read
;**************************************************************
;  Read one CP/M sector from disk into DMA buffer.
;	In:
;		Disk number in 'diskno'
;		Track number in 'track'
;		Sector number in 'sector'
;		Dma address in 'dmaad' (0-65535)
;	Out:	A = 0x0 if operation completes, 0x1 if an error occurs
disk_read:
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

; disk_write
;**************************************************************
;  Write one CP/M sector to disk from the DMA buffer.
;	In:
;		Disk number in 'diskno'
;		Track number in 'track'
;		Sector number in 'sector'
;		Dma address in 'dmaad' (0-65535)
;	Out:	A = 0x0 if operation completes, 0x1 if an error occurs
disk_write:
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

include	"nc100/nc100_io.def"
include	"nc100/virtual_disk.asm"

;**************************************************************
;	the remainder of the cbios is reserved uninitialized
;	data area, and does not need to be a Part of the
;	system	memory image (the space must be available,
;	however, between"begdat" and"enddat").
;
track:			defs	2			; two bytes for expansion
sector:			defs	2			; two bytes for expansion
dmaad:			defs	2			; direct memory address
diskno:			defs	1			; disk number 0-15

; scratch ram area for bdos use
begdat:			equ	$			; beginning of data area
directory_buffer:	defs	128	 		; scratch directory area
storage_alloc00:	defs	31	 		; allocation vector 0
storage_alloc01:	defs	31	 		; allocation vector 1
storage_alloc02:	defs	31	 		; allocation vector 2
storage_alloc03:	defs	31	 		; allocation vector 3
directory_check00:	defs	16			; check vector 0
directory_check01:	defs	16			; check vector 1
directory_check02:	defs	16	 		; check vector 2
directory_check03:	defs	16	 		; check vector 3

enddat:			equ	$	 		; end of data area
datsiz:			equ	$-begdat;		; size of data area
hstbuf: 		ds	256			; buffer for host disk sector

; Check that the everything thing fits within the 0x600 bytes
; allocated for the BiOS, otherwise throw an error
bios_end_addr:		equ	$
if bios_end_addr>bios_base+0x600
	ld	hl, bios_too_big
endif
