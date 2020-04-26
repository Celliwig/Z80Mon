; # Defines
; ###########################################################################
nc100_lib_base:				equ	mem_base+0x1000		; nc100_lib offset

; # Library variable storage
; ###########################################################################
orgmem	mon_base-0x0f
nc100_raster_start_addr:		dw	0x0000			; Address of LCD raster memory
; Possibly move these into the raster memory
; Last 4 bytes of each line are not used
nc100_raster_cursor_addr:		dw	0x0000			; Cursor position in raster memory
nc100_lcd_draw_attributes:		db	0x00			; Cursor draw attributes
nc100_lcd_posx:				dw	0x00			; LCD x cursor position, with regards to memory cell (0-59)
nc100_lcd_posy:				db	0x00			; LCD y cursor position (0-63)
nc100_lcd_pixel_offset:			db	0x00			; LCD pixel position in data byte

orgmem	nc100_lib_base
; # Font data
; ###########################################################################
nc100_font_6x8:
	include	'font_6x8.asm'

; # LCD methods
; ###########################################################################
; # nc100_lcd_set_raster_addr
; #################################
;  Set the start address of the LCD raster memory.
;  Needs to lie on a 4k memory boundary.
;	In:	HL = Start address of memory raster
nc100_lcd_set_raster_addr:
	ld	(nc100_raster_start_addr), hl				; Save raster memory address for later
	ld	a, h							; Grab MSB
	and	a, 0xF0							; Filter for most significant nibble
	out	(nc100_io_lcd_raster_addr), a				; Write raster address to store
	ret

; # nc100_lcd_clear_screen
; #################################
;  Clear LCD raster memory
nc100_lcd_clear_screen:
	ld	hl, (nc100_raster_start_addr)				; Load raster memory address
	ld	de, 0x1000						; Num. bytes to clear
nc100_lcd_clear_screen_loop:
	ld	(hl), 0x00						; Clear memory
	dec	de
	ld	a, d							; Check bytes left
	or	e
	jr	nz, nc100_lcd_clear_screen_loop
	ret

;; # nc100_lcd_print_char
;; #################################
;;  Prints a character to lcd
;;	In:	A = ASCII character
;nc100_lcd_print_char_6x8:
;
;	ld	hl, nc100_font_6x8					; Get font data offset
;	and	0xef							; Remove character msb
;	sub	0x20							; Remove offset to ' ' from character
;	ld	de, 0x0006						; Font data size
;nc100_lcd_print_char_6x8_font_calc_offset:
;	and	a
;	jr	z, nc100_lcd_print_char_6x8_font_copy_init		; Check whether we have the character we want
;	add	hl, de							; Skip one set of character font data
;	dec	a							; Decrement to check next character
;	jr	nc100_lcd_print_char_6x8_font_calc_offset		; Check next character
;nc100_lcd_print_char_6x8_font_copy_init:
;	ld	ix, (nc100_raster_start_addr)				; Load raster memory address
;	ld	de, (nc100_raster_start_addr)				; Calculate raster memory end address
;	ld	bc, 0x3fff
;	add	de, bc
;	ld	b, 6							; Number of bytes to copy
;
;;nc100_lcd_print_char_6x8_loop:
;
;	ret

; # nc100_lcd_copy_2_screen
; #################################
;  Copy 8 bits of data to current screen position
;	In:	A = Screen data
;nc100_lcd_copy_2_screen:
;	ld	hl, (nc100_lcd_posx)					; Get LCD cursor X position

; # nc100_lcd_set_cursor_by_pixel
; #################################
;  Set the cursor address using the specified pixel co-ordinates
;	In:	DE = x position (0-479)
;		HL = y position (0-63)
nc100_lcd_set_cursor_by_pixel:
	ld	a, e							; First calculate pixel offset
	and	0x07							; Extract pixel offset
	ld	(nc100_lcd_pixel_offset), a				; Save pixel offset
	srl	d							; Shift lsb of D in to Carry
	rr	e							; Shift with carry
	rr	e
	rr	e
	ld	a,e
	and	0x3f							; We only want 6 bits
	ld	(nc100_lcd_posx), a					; Save x position
	ld	e, a							; We want the filtered version later
	xor	d							; Ensure D is zero
	ld	a, l							; Filter y position
	and	0x3f							; We only want 6 bits
	ld	(nc100_lcd_posy), a					; Save y position
	ld	l, a							; We want the filtered version later
	xor	h							; Ensure H is zero
	jr	nc100_lcd_set_cursor
; # nc100_lcd_set_cursor_by_grid
; #################################
;  Set the cursor address using the specified grid co-ordinates
;	In:	DE = x position (0-59)
;		HL = y position (0-63)
nc100_lcd_set_cursor_by_grid:
	xor	a							; Zero pixel offset
	ld	(nc100_lcd_pixel_offset), a				; Save pixel offset
	ld	a,e							; X position
	and	0x3f							; We only want 6 bits (<64)
	ld	(nc100_lcd_posx), a					; Save x position
	ld	e, a							; We want the filtered version later
	xor	d							; Ensure D is zero
	ld	a, l							; Y position
	and	0x3f							; We only want 6 bits (<64)
	ld	(nc100_lcd_posy), a					; Save y position
	ld	l, a							; We want the filtered version later
	xor	h							; Ensure H is zero
; # nc100_lcd_set_cursor
; #################################
;  Set the cursor address using the specified co-ordinates
;	In:	DE = x position/memory cell (0-59)
;		HL = y position (0-63)
;		These value should be prefiltered
nc100_lcd_set_cursor:
	ld	a, e							; Check we're not try to select a memory cell
	and	0x3c							; off the end of the line
	sub	0x3c
	jr	z, nc100_lcd_set_cursor_error				; Trying to select a memory cell >=60 which is off the line
	ld	bc, (nc100_raster_start_addr)				; Load start address of raster
	add	hl, hl							; Equivalent to right-shift * 6
	add	hl, hl							; Which is equivalent to * 64
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, de							; x + y offsets
	add	hl, bc							; base address + x + y
	ld	(nc100_raster_cursor_addr), hl				; Store pointer to cursor location
nc100_lcd_set_cursor_error:
	ret

; # Commands
; ###########################################################################

; ###########################################################################
; #                                                                         #
; #                              System init                                #
; #                                                                         #
; ###########################################################################

orgmem	nc100_lib_base+0x1000
	db	0xA5,0xE5,0xE0,0xA5					; signiture bytes
	db	249,',',0,0						; id (249=init)
	db	0,0,0,0							; prompt code vector
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; reserved
	db	0,0,0,0							; user defined
	db	255,255,255,255						; length and checksum (255=unused)
	db	"System init",0

orgmem	nc100_lib_base+0x1040						; executable code begins here
system_init:
	; Reset interrupts
	xor	a							; Clear A
	out	(nc100_io_irq_mask), a					; Clear interrupt mask
	out	(nc100_io_irq_status), a				; Clear interrupt status flags

	; Configure RAM/ROM
	ld	a, nc100_membank_RAM|nc100_membank_48k
	out	(nc100_io_membank_D), a					; Select RAM for next page
	ld	a, nc100_membank_RAM|nc100_membank_32k
	out	(nc100_io_membank_C), a					; Select RAM for next page

	; We've got RAM now so set stack pointer (Yay!)
	ld	sp, 0x0000						; So first object wil be pushed to 0xFFFF

	; Copy ROM to RAM
	ld	a, nc100_membank_RAM|nc100_membank_16k
	out	(nc100_io_membank_B), a					; Select RAM for next page
	ld	bc, 0x0000						; Source: Page 0 (ROM)
	ld	de, 0x4000						; Destination: Page 1 (RAM)
	ld	hl, 0x4000						; Num. bytes: 16k
	call	memory_copy

	; RAM pages 0 & 1 are swapped.
	; That way we can swap them back when something else is loaded
	ld	a, nc100_membank_RAM|nc100_membank_0k
	out	(nc100_io_membank_B), a					; Select RAM for next page
	ld	a, nc100_membank_RAM|nc100_membank_16k
	out	(nc100_io_membank_A), a					; Select RAM for lowest page

	; Setup screen
	ld	hl, 0xe000						; Set screen at RAM top, below stack
	call	nc100_lcd_set_raster_addr

	call	nc100_lcd_clear_screen					; Clear screen memory

	ld	hl, 0xe000
	ld	(hl), 0xff
	inc	hl
	ld	(hl), 0xff
	inc	hl
	ld	(hl), 0xff
	inc	hl
	ld	(hl), 0xff

	rst	8							; Continue boot
