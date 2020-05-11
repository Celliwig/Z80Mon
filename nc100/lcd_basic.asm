; # LCD basic methods
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
	bit	nc100_draw_attrib_invert_bit, a				; Test invert flag
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
	bit	nc100_draw_attrib_invert_bit, c				; Test invert flag
	jr	z, nc100_lcd_write_screen_actual_attrib_merge		; Skip invert
	cpl								; Invert screen data
nc100_lcd_write_screen_actual_attrib_merge:
	bit	nc100_draw_attrib_merge_bit, c				; Test merge flag
	jr	z, nc100_lcd_write_screen_actual_write			; Skip merge
	ld	b, (hl)							; Read existing data
	bit	nc100_draw_attrib_invert_bit, c				; If normal - OR, if inverted - AND
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
