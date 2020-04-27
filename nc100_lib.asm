include	"nc100_io.asm"

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
; These are words to allow loading directly into double registers
nc100_lcd_pos_xy:			dw	0x0000			; LCD x/y cursor position (X: 0-59/Y: 0-63)
nc100_lcd_pixel_offset:			db	0x00			; LCD pixel position in data byte
nc100_lcd_draw_attributes:		db	0x00			; Cursor draw attributes

orgmem	nc100_lib_base
; # Font data
; ###########################################################################
nc100_font_6x8:
	include	'font_6x8.asm'
nc100_font_8x8:
	include	'font_8x8.asm'

; # Table data
; ###########################################################################
; x64 multiplication table
table_mul64:
	dw	0x0000, 0x0040, 0x0080, 0x00c0, 0x0100, 0x0140, 0x0180, 0x01c0	; 0-7
	dw	0x0200, 0x0240, 0x0280, 0x02c0, 0x0300, 0x0340, 0x0380, 0x03c0	; 8-15
	dw	0x0400, 0x0440, 0x0480, 0x04c0, 0x0500, 0x0540, 0x0580, 0x05c0	; 16-23
	dw	0x0600, 0x0640, 0x0680, 0x06c0, 0x0700, 0x0740, 0x0780, 0x07c0	; 24-31
	dw	0x0800, 0x0840, 0x0880, 0x08c0, 0x0900, 0x0940, 0x0980, 0x09c0	; 32-39
	dw	0x0a00, 0x0a40, 0x0a80, 0x0ac0, 0x0b00, 0x0b40, 0x0b80, 0x0bc0	; 40-47
	dw	0x0c00, 0x0c40, 0x0c80, 0x0cc0, 0x0d00, 0x0d40, 0x0d80, 0x0dc0	; 48-55
	dw	0x0e00, 0x0e40, 0x0e80, 0x0ec0, 0x0f00, 0x0f40, 0x0f80, 0x0fc0	; 56-63

; # LCD methods
; ###########################################################################
;  LCD basic specification:
; 	140x64 LCD Display.
;	Each line is comprised of 64 bytes, end 4 bytes are unused.
;	64 * 64 = 4096 bytes for the raster buffer (Must be boundary aligned).
;
;  LCD draw attributes
;	Bit 0: 0 = Normal, 1 = Invert
;	Bit 1: 0 = Overwrite, 1 = Merge (xor)
;
;  Registers:
;   As a general rule:
;    Fixed Registers:
;	D = y position (0-63)
;	E = x position/memory cell (0-59)
;	HL = Cursor address
;    Scratch Registers:
;	A/A'
;	BC

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
	ld	b, 0x00							; Set normal screen clear value
	ld	a, (nc100_lcd_draw_attributes)				; Get draw attributes
	bit	0, a							; Test invert flag
	jr	z, nc100_lcd_clear_screen_loop
	ld	b, 0xff							; Set inverted screen clear value
nc100_lcd_clear_screen_loop:
	ld	(hl), b							; Clear memory
	inc	hl							; Increment raster pointer
	dec	de							; Decrement byte count
	ld	a, d							; Check bytes left
	or	e
	jr	nz, nc100_lcd_clear_screen_loop
	ld	de, 0x0000						; Set cursor position (0,0)
	call	nc100_lcd_set_cursor_by_grid
	ret

; # nc100_lcd_set_attributes
; #################################
;  Sets the attributes that draw operations use
;	In:	A = Attributes value
nc100_lcd_set_attributes:
	ld	(nc100_lcd_draw_attributes), a				; Save attributes value
	ret

; # nc100_lcd_calc_cursor_check
; #################################
;  Check whether the cursor co-ordinates are valid
;  (Don't call directly)
;	In:	D = y position (0-63)
;		E = x position/memory cell (0-59)
;	Out:	Carry flag is set when okay, Carry flag unset on error.
nc100_lcd_calc_cursor_check:
	; Check we're not off the end of the line
	ld	a, e							; Get X value
	sub	0x3c							; -60, check if we're on the line
	jr	nc, nc100_lcd_calc_cursor_check_error
	; Check whether we're off the bottom of the screen
	ld	a, d							; Get Y value
	sub	0x3f							; -63, check if we're off the end of the screen
	jr      nc, nc100_lcd_calc_cursor_check_error
	scf								; Set Carry flag
	ret
nc100_lcd_calc_cursor_check_error:
	scf								; Set Carry flag
	ccf								; So we can clear if (complement actually)
	ret

; # nc100_lcd_calc_cursor_addr
; #################################
;  Set the cursor address using the specified co-ordinates
;  (Don't call directly)
;	In:	D = y position (0-63)
;		E = x position/memory cell (0-59)
;		(These value should be pre-filtered)
;	Out:	HL = Cursor address
nc100_lcd_calc_cursor_addr:
; This costs 57 clock ticks
	ld	hl, table_mul64						; Load multiplication table address
	ld	c, d
	sla	c							; Multiple by 2
	ld	b, 0							; Ensure B is zero
	add	hl, bc							; Add offset
	ld	c, (hl)							; Load low byte
	inc	hl							; Increment pointer
	ld	b, (hl)							; Load high byte

;; This costs 66 clock ticks
;;	add	hl, hl							; Equivalent to left-shift[6]
;;	add	hl, hl							; Which is equivalent to * 64
;;	add	hl, hl
;;	add	hl, hl
;;	add	hl, hl
;;	add	hl, hl

	ld	hl, (nc100_raster_start_addr)				; Load start address of raster
	ld	l, e							; Base address + x (We can do this because BA is on a 4k boundary)
	add	hl, bc							; base address + x + y
	ret

; # nc100_lcd_set_cursor_by_pixel
; #################################
;  Set the cursor address using the specified pixel co-ordinates
;	In:	BC = y position (0-63)
;		DE = x position (0-479)
;	Out:	D = y position (0-63)
;		E = x position/memory cell (0-59)
;		HL = Cursor address
;		Carry flag is set when okay, Carry flag unset on error.
nc100_lcd_set_cursor_by_pixel:
	ld	a, e							; First calculate pixel offset
	and	0x07							; Extract pixel offset
	ld	l, a							; Save pixel offset
	srl	d							; Shift lsb of D in to Carry
	rr	e							; Shift with carry
	rr	e							; Equivalent of right-shift[3]
	rr	e							; Equivalent to /8
	ld	d, c							; Set D with Y co-ordinate
	jr	nc100_lcd_set_cursor_by_grid_with_pixel_offset
; # nc100_lcd_set_cursor_by_grid
; #################################
;  Set the cursor address using the specified grid co-ordinates
;	In:	D = y position (0-63)
;		E = x position/memory cell (0-59)
;		L = pixel offset (0-7)
;	Out:	D = y position (0-63)
;		E = x position/memory cell (0-59)
;		HL = Cursor address
;		Carry flag is set when okay, Carry flag unset on error.
nc100_lcd_set_cursor_by_grid:
	ld	l, 0							; Zero pixel offset
nc100_lcd_set_cursor_by_grid_with_pixel_offset:
	call	nc100_lcd_calc_cursor_check				; Check co-ordinates
	jr	nc, nc100_lcd_set_cursor_by_grid_error			; If that failed, skip save
	ld	a, l
	and	0x07							; Filter pixel offset
	ld	(nc100_lcd_pixel_offset), a				; Save pixel offset
	ld	(nc100_lcd_pos_xy), de					; Save x/y position
	call	nc100_lcd_calc_cursor_addr				; Calculate cursor address
	ld	(nc100_raster_cursor_addr), hl				; Store pointer to cursor location
nc100_lcd_set_cursor_by_grid_error:
	ret

; # nc100_lcd_write_screen_data
; #################################
;  Copy 8 bits of data to current screen position.
;  Handles pixel offset
;	In:	A = Screen data
;		D = y position (0-63)
;		E = x position/memory cell (0-59)
;		HL = cursor address
nc100_lcd_write_screen_data:
	push	af							; Save screen data
	ld	a, (nc100_lcd_pixel_offset)				; Check whether there's an offset
	and	a
	jr	nz, nc100_lcd_write_2_screen_split			; There's a pixel offset
nc100_lcd_write_2_screen_single:
	pop	af							; Restore screen data
	jr	nc100_lcd_write_screen_actual				; No pixel offset so simply print
nc100_lcd_write_2_screen_split:
	pop	bc							; Restore screen data
	ld	c, 0xff							; Init mask
nc100_lcd_write_2_screen_split_loop:
	rrc	b							; Rotate right without Carry
	srl	c							; Shift right mask
	dec	a							; Decrement pixel offset
	jr	nz, nc100_lcd_write_2_screen_split_loop			; Continue looping if necessary
	ld	a, c							; Copy mask
	and	b							; Apply to screen data
	call	nc100_lcd_write_screen_actual				; Write 1st byte
	ld	a, c							; Copy mask
	cpl								; Invert mask
	and	b							; Apply to screen data
									; Write second byte
; # nc100_lcd_write_screen_actual
; #################################
;  Copy 8 bits of data to current screen position.
;	In:	A = Screen data
;		D = y position (0-63)
;		E = x position/memory cell (0-59)
;		HL = cursor address
nc100_lcd_write_screen_actual:
	ex	af, af'							; Save screen data
	; Check whether we're about to overrun screen RAM
	ld	bc, (nc100_raster_start_addr)
	ld	a, b							; Load MSB raster address
	xor	h							; XOR MSB of raster cursor address with MSB raster start address,
									; top 4 bits should be zero if we're within range
	and	0xf0							; Filter lsbs
	jr	nz, nc100_lcd_write_screen_actual_error
nc100_lcd_write_screen_actual_attrib:
	ld	a, (nc100_lcd_draw_attributes)				; Get draw attributes
	ld	c, a							; Save attributes
	ex	af, af'							; Restore screen data
nc100_lcd_write_screen_actual_attrib_invert:
	bit	0, c							; Test invert flag
	jr	z, nc100_lcd_write_screen_actual_attrib_merge		; Skip invert
	cpl								; Invert screen data
nc100_lcd_write_screen_actual_attrib_merge:
	bit	1, c							; Test merge flag
	jr	z, nc100_lcd_write_screen_actual_write			; Skip merge
	ld	b, (hl)							; Read existing data
	bit	0, c							; If normal - OR, if inverted - AND
	jr	nz, nc100_lcd_write_screen_actual_attrib_merge_AND
	or	b							; Merge: OR
	jr	nc100_lcd_write_screen_actual_write
nc100_lcd_write_screen_actual_attrib_merge_AND:
	and	b							; Merge: AND
nc100_lcd_write_screen_actual_write:
	ld	(hl), a							; Write screen data
	ret
nc100_lcd_write_screen_actual_error:
	ex	af, af'							; Restore screen data
	ret

; # Font methods
; ###########################################################################

;; # nc100_lcd_print_glyph_f68
;; #################################
;;  Prints a character to lcd (char must be <128)
;;	In:	A = ASCII character
;nc100_lcd_print_char_6x8:
;	ld	de, (nc100_lcd_pos_xy)					; Load cursor X/Y position
;	ld	hl, (nc100_raster_cursor_addr)				; Load cursor address
;
;	ld	ix, nc100_font_6x8					; Get font data address
;	and	0xef							; Remove character msb
;	sub	0x20							; Remove offset to ' ' from character
;	sla	a							; x2 result
;	ld	c, a							; Create offset to glyph data
;	ld	b, 0
;	add	ix, bc							; Add offset to glyph data (offset*2)
;	add	ix, bc							; Add offset to glyph data (offset*4)
;	add	ix, bc							; Add offset to glyph data (offset*6)
;
;	ld	a, (ix+0)
;	call	nc100_lcd_write_screen_data				; Write glyph data (0)
;	ld	bc, 0x40						; Offset to the same position in the next line
;	add	hl, bc
;	ld	a, (ix+1)
;	call	nc100_lcd_write_screen_data				; Write glyph data (1)
;	ld	bc, 0x40						; Offset to the same position in the next line
;	add	hl, bc
;	ld	a, (ix+2)
;	call	nc100_lcd_write_screen_data				; Write glyph data (2)
;	ld	bc, 0x40						; Offset to the same position in the next line
;	add	hl, bc
;	ld	a, (ix+3)
;	call	nc100_lcd_write_screen_data				; Write glyph data (3)
;	ld	bc, 0x40						; Offset to the same position in the next line
;	add	hl, bc
;	ld	a, (ix+4)
;	call	nc100_lcd_write_screen_data				; Write glyph data (4)
;	ld	bc, 0x40						; Offset to the same position in the next line
;	add	hl, bc
;	ld	a, (ix+5)
;	call	nc100_lcd_write_screen_data				; Write glyph data (5)
;
;	; Increment position
;	inc	e							; Increment x position
;	ld	(nc100_lcd_pos_xy), de					; Save cursor X/Y position
;	ld	hl, (nc100_raster_cursor_addr)				; Load cursor address
;	inc	hl
;	ld	(nc100_raster_cursor_addr), hl				; Save cursor position
;
;	ret

; # nc100_lcd_print_glyph_8x8
; #################################
;  Prints a character to lcd (char must be <128)
;	In:	A = ASCII character
;		D = y position (0-63)
;		E = x position/memory cell (0-59)
nc100_lcd_print_glyph_8x8:
	ld	hl, (nc100_raster_cursor_addr)				; Load cursor address

	ld	ix, nc100_font_8x8					; Get font data address
	sub	0x20							; Remove offset to ' ' from character
	sla	a							; x2 result
	ld	c, a							; Create offset to glyph data
	ld	b, 0
	sla	c							; x2 (original x 4)
	rl	b
	sla	c							; x2 (original x 8)
	rl	b
	add	ix, bc							; Add offset to glyph data

	ld	a, (ix+0)
	call	nc100_lcd_write_screen_data				; Write glyph data (0)
	ld	bc, 0x40						; Offset to the same position in the next line
	add	hl, bc
	ld	a, (ix+1)
	call	nc100_lcd_write_screen_data				; Write glyph data (1)
	ld	bc, 0x40						; Offset to the same position in the next line
	add	hl, bc
	ld	a, (ix+2)
	call	nc100_lcd_write_screen_data				; Write glyph data (2)
	ld	bc, 0x40						; Offset to the same position in the next line
	add	hl, bc
	ld	a, (ix+3)
	call	nc100_lcd_write_screen_data				; Write glyph data (3)
	ld	bc, 0x40						; Offset to the same position in the next line
	add	hl, bc
	ld	a, (ix+4)
	call	nc100_lcd_write_screen_data				; Write glyph data (4)
	ld	bc, 0x40						; Offset to the same position in the next line
	add	hl, bc
	ld	a, (ix+5)
	call	nc100_lcd_write_screen_data				; Write glyph data (5)
	ld	bc, 0x40						; Offset to the same position in the next line
	add	hl, bc
	ld	a, (ix+6)
	call	nc100_lcd_write_screen_data				; Write glyph data (5)
	ld	bc, 0x40						; Offset to the same position in the next line
	add	hl, bc
	ld	a, (ix+7)
	call	nc100_lcd_write_screen_data				; Write glyph data (5)

	; Increment position
	inc	e							; Increment x position
	ld	a, 60							; Maximum number of characters per line
	sub	e							; Max char - X pos
	jr	c, nc100_lcd_print_lf_8x8
	jr	z, nc100_lcd_print_lf_8x8
	ld	(nc100_lcd_pos_xy), de					; Save cursor X/Y position
	ld	hl, (nc100_raster_cursor_addr)				; Load cursor address
	inc	hl
	ld	(nc100_raster_cursor_addr), hl				; Save cursor position
	jr	nc100_lcd_print_glyph_8x8_exit
	call	nc100_lcd_set_cursor_by_grid				; Set cursor position
nc100_lcd_print_glyph_8x8_exit:
	ret

; # nc100_lcd_print_cr_8x8
; #################################
;  Resets cursors X position.
;	In:	D = y position (0-63)
;		E = x position/memory cell (0-59)
nc100_lcd_print_cr_8x8:
	ld	e, 0							; Reset X position
	call	nc100_lcd_set_cursor_by_grid
	ret

; # nc100_lcd_print_lf_8x8
; #################################
;  Increments position by one character line, reset X position.
;	In:	D = y position (0-63)
;		E = x position/memory cell (0-59)
nc100_lcd_print_lf_8x8:
	ld	e, 0							; Reset X position
	ld	a, d							; Get Y position
	add	0x08							; Add 8 lines
	ld	d, a							; Save Y position
	sub	0x40							; Y position - 64
	jr	c, nc100_lcd_print_lf_8x8_set_position
;	xor	a
	ld	d, a							; Reset Y position
nc100_lcd_print_lf_8x8_set_position:
	call	nc100_lcd_set_cursor_by_grid				; Set cursor position
	ret

; # Console routines
; ###########################################################################
; # nc100_console_linefeed
; #################################
nc100_console_linefeed:
	jr	nc100_lcd_print_lf_8x8

; # nc100_console_carriage_return
; #################################
nc100_console_carriage_return:
	jr	nc100_lcd_print_cr_8x8

; # nc100_console_char_out
; #################################
;  Copy character to selected output device
;	In:	A = ASCII character
nc100_console_char_out:
	exx								; Swap out registers
	ld	de, (nc100_lcd_pos_xy)					; Load cursor X/Y position
nc100_console_char_out_check_lf:
	cp	0x0a							; Check for LF (line feed)
	jr	nz, nc100_console_char_out_check_cr
	call	nc100_console_linefeed
	jr	nc100_console_char_out_exit
nc100_console_char_out_check_cr:
	cp	0x0d							; Check for CR (carriage return)
	jr	nz, nc100_console_char_out_print_glyph
	call	nc100_console_carriage_return
	jr	nc100_console_char_out_exit
nc100_console_char_out_print_glyph:
	call	nc100_lcd_print_glyph_8x8
nc100_console_char_out_exit:
	exx								; Swap back registers
	ret

nc100_console_char_in:
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
	; Set below screen RAM
	ld	sp, 0xf000						; So first object wil be pushed to 0xEFFF

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
	ld	hl, 0xf000						; Set screen at RAM top, above stack
	call	nc100_lcd_set_raster_addr

	ld	a, 0x01							; Set inverted attributes
	call	nc100_lcd_set_attributes
	call	nc100_lcd_clear_screen					; Clear screen memory

	; Replace dummy console routines
	ld	bc, nc100_console_char_out
	ld	(monlib_console_out+1), bc
	ld	bc, nc100_console_char_in
	ld	(monlib_console_in+1), bc

	rst	8							; Continue boot
