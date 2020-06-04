;**************************************************************
;*
;*             CP/M (2.2) BIOS for the NC100
;*
;**************************************************************

org	bios_base					; origin of this program
seek	bios_offset

iobyte:			equ	0003h			; intel i/o byte
current_disk:		equ	0004h			; address of current disk number 0=a,... l5=p
num_disks:		equ	04h			; number of disks in the system
nsects:			equ	($-ccp_base)/128	; warm start sector count

; Jump vector for individual subroutines
;**************************************************************
	jp	boot					; Cold start
warmboot_entry:
	jp	warmboot				; Warm start
	jp	nc100_serial_status_char_in		; Get console status
	jp	nc100_serial_polling_char_in_cpm	; Read character from console in
	jp	nc100_serial_polling_char_out_cpm	; Write character to console out
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

; 4 virtual drives
;**************************************************************
disk_param_header:
; disk Parameter header for disk 00
	dw	0x0000, 0x0000
	dw	0x0000, 0x0000
	dw	directory_buffer, 0x0000
	dw	directory_check00, storage_alloc00
; disk parameter header for disk 01
	dw	0x0000, 0x0000
	dw	0x0000, 0x0000
	dw	directory_buffer, 0x0000
	dw	directory_check01, storage_alloc01
; disk parameter header for disk 02
	dw	0x0000, 0x0000
	dw	0x0000, 0x0000
	dw	directory_buffer, 0x0000
	dw	directory_check02, storage_alloc02
; disk parameter header for disk 03
	dw	0x0000, 0x0000
	dw	0x0000, 0x0000
	dw	directory_buffer, 0x0000
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
disk_param_block_128k:
	dw	0x0020					; SPT: 32 sectors per track
	db	0x03					; BSH: Block shift factor
	db	0x07					; BLM: Block mask
	db	0x00					; EXM: Extent mask
	dw	0x007f					; DSM: Disk size (-1)
	dw	0x003f					; DRM: Directory max
	db	0xc0					; AL0: Alloc 0
	db	0x00					; AL1: Alloc 1
	dw	0x0010					; CKS: Check size
	dw	0x0002					; OFF: Track offset (Reserved tracks)
disk_param_block_256k:
	dw	0x0020					; SPT: 32 sectors per track
	db	0x03					; BSH: Block shift factor
	db	0x07					; BLM: Block mask
	db	0x00					; EXM: Extent mask
	dw	0x00ff					; DSM: Disk size (-1)
	dw	0x003f					; DRM: Directory max
	db	0xc0					; AL0: Alloc 0
	db	0x00					; AL1: Alloc 1
	dw	0x0010					; CKS: Check size
	dw	0x0002					; OFF: Track offset (Reserved tracks)
disk_param_block_512k:
	dw	0x0020					; SPT: 32 sectors per track
	db	0x04					; BSH: Block shift factor
	db	0x0f					; BLM: Block mask
	db	0x01					; EXM: Extent mask
	dw	0x00ff					; DSM: Disk size (-1)
	dw	0x007f					; DRM: Directory max
	db	0xc0					; AL0: Alloc 0
	db	0x00					; AL1: Alloc 1
	dw	0x0020					; CKS: Check size
	dw	0x0002					; OFF: Track offset (Reserved tracks)
disk_param_block_1024k:
	dw	0x0040					; SPT: 64 sectors per track
	db	0x04					; BSH: Block shift factor
	db	0x0f					; BLM: Block mask
	db	0x00					; EXM: Extent mask
	dw	0x01ff					; DSM: Disk size (-1)
	dw	0x00ff					; DRM: Directory max
	db	0xf0					; AL0: Alloc 0
	db	0x00					; AL1: Alloc 1
	dw	0x0040					; CKS: Check size
	dw	0x0001					; OFF: Track offset (Reserved tracks)

; end of fixed tables

; boot
;**************************************************************
;  Cold boot routine
boot:
	di						; Disable interrupts (for now)
	call	disk_configure				; Load in vdisk config

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
	dec	b					; Read sectors = Read sectors - 1
	jr	z, go_cpm				; Transfer to CP/M if all have been loaded

	; More sectors remain to load, check for track change
	inc	d					; Increment sector number
	ld	a, (var_vdisk_sector_size)		; Get selected vdisk sector size
	cp	d					; Check if greater than last sector
	jp	c, warmboot_sector_load_next		; Carry generated if sector < (var_vdisk_sector_size)

	; end of current track,	go to next track
	ld 	d, nc100_vdisk_sector_1st		; Begin with first sector of next track
	inc	c					; Track = Track + 1

	; save register state, and change tracks
	push	bc
	push	de
	push	hl
	call	disk_track_set				; Track address set from register c
	pop	hl
	pop	de
	pop	bc
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
;  Supplied by serial_io.asm

; console_in
;**************************************************************
;  Read in a character from console input
;	Out:	A = Character
;  Supplied by serial_io.asm

; console_out
;**************************************************************
;  Write a character out to the console
;	In:	C = Character
;  Supplied by serial_io.asm

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

; disk_page_bank_in
;**************************************************************
;  Reconfigure memory page bank to select memory card
disk_page_bank_in:
	ld	c, nc100_io_membank_A			; Use the 1st page for this
	call	nc100_memory_page_get
	push	bc					; Save 1st page config
	call	nc100_vdisk_card_page_map_reset		; Page in memory card
	ret

; disk_page_bank_reset
;**************************************************************
;  Reset memory page bank to original configuration
disk_page_bank_reset:
	pop	bc
	call	nc100_memory_page_set			; Restore 1st page config
	ret

; disk_configure
;**************************************************************
;  Read drive configuration from memory card
disk_configure:
	call	disk_page_bank_in			; Configure memory bank to select memory card
	ld	hl, nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_drive0_type
	ld	de, var_vdisk_drive0_type		; Pointer to drive config table
disk_configure_loop:
	ld	a, (hl)					; Get byte of drive config
	ld	(de), a					; Save byte of drive config
	inc	hl
	inc	de
	ld	a, l					; Check offset
	cp	nc100_vcard_header_vdisk_header_offset+nc100_vcard_header_drive4_type
	jr	nz, disk_configure_loop
	call	disk_page_bank_reset			; Reset memory bank tp original configuration
	ret

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
;	Out:	HL = Pointer to Disk Parameter Header of selected drive
disk_select:
	ld 	a, c
	cp	num_disks				; Must be between 0 and 3
	jr	nc, disk_select_error
	ld	(var_vdisk_drive_num), a		; Save selected drive
	ld	l, a
	ld	h, 0x00					; HL = Drive number
	push	hl					; Save drive number
	ld	l,0x00					; Clear HL
	ld	de, 0x0003				; Drive config table offset
	and	a					; Check if selected drive is zero
disk_select_size_loop:
	jr	z, disk_select_size			; If zero continue
	add	hl, de					; Add drive config table offset
	dec	a					; Decrement selected drive
	jr	disk_select_size_loop
disk_select_size:
	ld	de, var_vdisk_drive0_type		; Pointer to drive config table
	add	hl, de					; Add offset to pointer to drive config table
	ld	a, (hl)					; Check drive type
	cp	nc100_vdisk_type_none			; Check if disk inserted
	jr	z, disk_select_error			; If no disk, error
	inc	hl
	inc	hl
	ld	a, (hl)					; Get disk size
disk_select_size_128k:
	cp	0x02					; Is it 128k?
	jr	nz, disk_select_size_256k
	ld	bc, nc100_vdisk_sector_seek_32spt	; Use seek sector 32k
	ld	(var_vdisk_sector_seek), bc
	ld	a, 0x20					; Vdisk sector size: 32
	ld	bc, disk_param_block_128k		; Disk Parameter Block: 128k
	jr	disk_select_get_dph
disk_select_size_256k:
	cp	0x04					; Is it 256k?
	jr	nz, disk_select_size_512k
	ld	bc, nc100_vdisk_sector_seek_32spt	; Use seek sector 32k
	ld	(var_vdisk_sector_seek), bc
	ld	a, 0x20					; Vdisk sector size: 32
	ld	bc, disk_param_block_256k		; Disk Parameter Block: 256k
	jr	disk_select_get_dph
disk_select_size_512k:
	cp	0x08					; Is it 512k?
	jr	nz, disk_select_size_1024k
	ld	bc, nc100_vdisk_sector_seek_32spt	; Use seek sector 32k
	ld	(var_vdisk_sector_seek), bc
	ld	a, 0x20					; Vdisk sector size: 32
	ld	bc, disk_param_block_512k		; Disk Parameter Block: 512k
	jr	disk_select_get_dph
disk_select_size_1024k:
	cp	0x10					; Is it 1024k?
	jr	nz, disk_select_error
	ld	bc, nc100_vdisk_sector_seek_64spt	; Use seek sector 64k
	ld	(var_vdisk_sector_seek), bc
	ld	a, 0x40					; Vdisk sector size: 64
	ld	bc, disk_param_block_1024k		; Disk Parameter Block: 1024k
	;jr	disk_select_get_dph
disk_select_get_dph:
	ld	(var_vdisk_sector_size), a		; Save selected vdisk sector size
	pop	hl					; Restore drive number
	add	hl, hl					; HL*2
	add	hl, hl					; HL*4
	add	hl, hl					; HL*8
	add	hl, hl					; HL*16 (size of disk parameter header)
	ld	de, disk_param_header
	add	hl, de					; HL = Disk Parameter Header + (disknum*16)
	push	hl					; Save DPH
	ld	de, 0x000a				; Offset to DPB
	add	hl, de					; Add offset to DPB to pointer to DPH
	ld	(hl), c					; Set DPB
	inc	hl					; Increment pointer
	ld	(hl), b					; Set DPB
	pop	hl					; Restore DPH
	ret
disk_select_error:
	ld	hl, 0x0000				; error return code
	ret

; disk_track_set
;**************************************************************
;  Set disk track for following operations
;	In:	C = Disk track
disk_track_set:
	ld 	a, c
	ld	(var_vdisk_track), a
	ret

; disk_sector_set
;**************************************************************
;  Set disk sector for following operations
;	In:	C = Disk sector
disk_sector_set:
	ld 	a, c
	ld	(var_vdisk_sector), a
	ret

; disk_sector_translate
;**************************************************************
;  Translate a disk sector from virtual to physical
;	In:	BC = Logical sector
;		DE = Sector translation table
;	Out:	HL = Physical sector
disk_sector_translate:
	ld	h, b					; Logical sector is physical sector
	ld	l, c
	ret

;	;translate the sector given by bc using the
;	;translate table given by de
;	ex	de, hl					; hl=.sector_translate
;	add	hl, bc					; hl=.sector_translate (sector)
;	ret						; debug no translation
;	ld	l, (hl)					; l=sector_translate (sector)
;	ld	h, 0					; hl=sector_translate (sector)
;	ret						; with value in hl

; disk_dma_set
;**************************************************************
;  Set DMA address for following operations
;	In:	BC = DMA buffer address
disk_dma_set:
	ld	(var_vdisk_dma_addr_actual), bc		; Save the DMA address
	ret

; disk_read
;**************************************************************
;  Read one CP/M sector from disk into DMA buffer.
;	In:
;		Disk number in 'diskno'
;		Track number in 'var_vdisk_track'
;		Sector number in 'var_vdisk_sector'
;		Dma address in 'var_vdisk_dma_addr' (0-65535)
;	Out:	A = 0x0 if operation completes, 0x1 if an error occurs
disk_read:
	ld	ix, nc100_vdisk_sector_read		; It's a read operation
	ld	iy, (var_vdisk_sector_seek)		; Get selected sector seek operation
	ld	de, disk_read_error_check		; Push return address
	push	de
	call	disk_page_bank_in			; Configure memory bank to select memory card
	ld	hl, 0x0000				; Reset pointer of vdisk operation
	jp	(iy)					; Jump to sector seek routine
disk_read_error_check:
	call	disk_page_bank_reset			; Reset memory bank tp original configuration
	jr	nc, disk_read_error_check_failed	; Check if an error occured
disk_read_copy:
	; Copy from BIOS buffer to DMA address
	ld	de, (var_vdisk_bios_buffer)		; Address of BIOS buffer
	ld	hl, (var_vdisk_dma_addr_actual)		; Address to read data from
	ld	b, 0x80					; Byte count
disk_read_copy_loop:
	ld	a, (de)					; Copy byte from BIOS buffer to DMA address
	ld	(hl), a
	inc	de					; Increment pointers
	inc	hl
	djnz	disk_read_copy_loop			; Copy 128 bytes
	xor	a					; Set no error code
	ret
disk_read_error_check_failed:
	ld	a, 0x01					; Set error code
	ret

; disk_write
;**************************************************************
;  Write one CP/M sector to disk from the DMA buffer.
;	In:
;		Disk number in 'diskno'
;		Track number in 'var_vdisk_track'
;		Sector number in 'var_vdisk_sector'
;		Dma address in 'var_vdisk_dma_addr' (0-65535)
;	Out:	A = 0x0 if operation completes, 0x1 if an error occurs
disk_write:
disk_write_copy:
	; Copy from DMA address to BIOS buffer
	ld	de, (var_vdisk_dma_addr_actual)		; Address to read data from
	ld	hl, (var_vdisk_bios_buffer)		; Address of BIOS buffer
	ld	b, 0x80					; Byte count
disk_write_copy_loop:
	ld	a, (de)					; Copy byte from DMA address to BIOS buffer
	ld	(hl), a
	inc	de					; Increment pointers
	inc	hl
	djnz	disk_write_copy_loop			; Copy 128 bytes
	ld	ix, nc100_vdisk_sector_write		; It's a write operation
	ld	iy, (var_vdisk_sector_seek)		; Get selected sector seek routine
	ld	de, disk_write_error_check		; Push return address
	push	de
	call	disk_page_bank_in			; Configure memory bank to select memory card
	ld	hl, 0x0000				; Reset pointer of vdisk operation
	jp	(iy)					; Jump to sector seek routine
disk_write_error_check:
	call	disk_page_bank_reset			; Reset memory bank to original configuration
	jr	nc, disk_write_error_check_failed	; Check if an error occured
	xor	a					; Set no error code
	ret
disk_write_error_check_failed:
	ld	a, 0x01					; Set error code
	ret

include	"nc100/nc100_io.def"
include	"nc100/memory.asm"
include	"nc100/serial_io.asm"
include	"nc100/virtual_disk.asm"

;**************************************************************
;	the remainder of the cbios is reserved uninitialized
;	data area, and does not need to be a Part of the
;	system	memory image (the space must be available,
;	however, between"begdat" and"enddat").
;

;nc100_vdisk_port_bank:		equ	nc100_io_membank_B
;nc100_vdisk_port_address:	equ	0x4000
;nc100_vdisk_dma_address:	equ	0x8000

var_vdisk_sector:		dw	0x0000			; Sector number for next operation
var_vdisk_track:		dw	0x0000			; Track number for next operation
var_vdisk_dma_addr:		dw	var_vdisk_bios_buffer	; DMA address of the local (to the BIOS) buffer
var_vdisk_sector_seek:		dw	0x0000			; Routine to use for seek sector
var_vdisk_sector_size:		db	0x00			; Selected vdisk sector size
var_vdisk_drive_num:		db	0x00			; Selected disk drive

var_vdisk_bios_buffer:		ds	128, 0x00		; Buffer read/writes beween memory card and DMA address
var_vdisk_dma_addr_actual:	dw	0x0000			; DMA address to use for the next operation

; Drive config table
var_vdisk_drive0_type:		db	0x00		; Drive 0: Vdisk type
var_vdisk_drive0_pointer:	db	0x00		; Drive 0: Vdisk pointer (64k blocks)
var_vdisk_drive0_size:		db	0x00		; Drive 0: Vdisk size (64k blocks)
var_vdisk_drive1_type:		db	0x00		; Drive 1: Vdisk type
var_vdisk_drive1_pointer:	db	0x00		; Drive 1: Vdisk pointer (64k blocks)
var_vdisk_drive1_size:		db	0x00		; Drive 1: Vdisk size (64k blocks)
var_vdisk_drive2_type:		db	0x00		; Drive 2: Vdisk type
var_vdisk_drive2_pointer:	db	0x00		; Drive 2: Vdisk pointer (64k blocks)
var_vdisk_drive2_size:		db	0x00		; Drive 2: Vdisk size (64k blocks)
var_vdisk_drive3_type:		db	0x00		; Drive 3: Vdisk type
var_vdisk_drive3_pointer:	db	0x00		; Drive 3: Vdisk pointer (64k blocks)
var_vdisk_drive3_size:		db	0x00		; Drive 3: Vdisk size (64k blocks)

; scratch ram area for bdos use
begdat:				equ	$		; beginning of data area
directory_buffer:		defs	128	 	; scratch directory area
storage_alloc00:		defs	31	 	; allocation vector 0
storage_alloc01:		defs	31	 	; allocation vector 1
storage_alloc02:		defs	31	 	; allocation vector 2
storage_alloc03:		defs	31	 	; allocation vector 3
directory_check00:		defs	16		; check vector 0
directory_check01:		defs	16		; check vector 1
directory_check02:		defs	16	 	; check vector 2
directory_check03:		defs	16	 	; check vector 3

enddat:				equ	$	 	; end of data area
datsiz:				equ	$-begdat;	; size of data area

; Check that the everything thing fits within the 0x600 bytes
; allocated for the BIOS, otherwise throw an error
bios_end_addr:		equ	$
if bios_end_addr>bios_base+0x600
	ld	hl, bios_too_big
endif
