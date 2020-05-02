; # LCD font methods (8x8)
; ###########################################################################

; # nc100_lcd_print_glyph_only_8x8
; #################################
;  Prints a character to lcd (char must be <128)
;	In:	A = ASCII character
;		D = y position (0-63)
;		E = x position/memory cell (0-59)
;		HL = cursor address
nc100_lcd_print_glyph_only_8x8:
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
	jp	nc100_lcd_write_screen_data				; Write glyph data (5)

; # nc100_lcd_print_glyph_8x8
; #################################
;  Prints a character to lcd (char must be <128), and updates the cursor position
;	In:	A = ASCII character
;		D = y position (0-63)
;		E = x position/memory cell (0-59)
;		HL = cursor address
nc100_lcd_print_glyph_8x8:
	call	nc100_lcd_print_glyph_only_8x8

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
	ret

; # nc100_lcd_print_cr_8x8
; #################################
;  Resets cursors X position.
;	In:	D = y position (0-63)
;		E = x position/memory cell (0-59)
nc100_lcd_print_cr_8x8:
	ld	e, 0							; Reset X position
	jp	nc100_lcd_set_cursor_by_grid

; # nc100_lcd_print_lf_8x8
; #################################
;  Increments position by one character line, reset X position.
;	In:	D = y position (0-63)
;		E = x position/memory cell (0-59)
nc100_lcd_print_lf_8x8:
	ld	a, (nc100_lcd_draw_attributes)				; Get draw attributes
	ld	b, a							; Save draw attributes to B
	ld	a, d							; Get Y position
	add	0x08							; Add 8 lines
	ld	d, a							; Save Y position
	sub	0x40							; Y position - 64
	jr	c, nc100_lcd_print_lf_8x8_set_position
	bit	7, b							; Test scroll bit
	jr	nz, nc100_lcd_print_lf_8x8_scroll_screen
;	xor	a
;	ld	d, a							; Reset Y position
;	jr	nc100_lcd_print_lf_8x8_set_position
	jp	nc100_lcd_clear_screen
nc100_lcd_print_lf_8x8_scroll_screen:
	ld	a, d
	sub	0x08							; Undo previous add
	ld	d, a
	call	nc100_lcd_scroll_8x8					; Scroll screen up
nc100_lcd_print_lf_8x8_set_position:
	ld	e, 0							; Reset X position
	jp	nc100_lcd_set_cursor_by_grid				; Set cursor position

; # nc100_lcd_scroll_8x8
; #################################
;  Scrolls entire screen memory up 1 character line
nc100_lcd_scroll_8x8:
	push	de							; Save existing data
	push	hl
	ld	hl, (nc100_raster_start_addr)				; Source address
	ld	bc, 0x0200						; 512 = 64 * 8
	add	hl, bc
	ld	de, (nc100_raster_start_addr)				; Destination address
	ld	bc, 0x0e00						; Number of bytes to copy
	ldir
	push	de							; Copy destination address
	pop	hl							; to HL register
	ld	de, 0x0000						; Clear byte count
nc100_lcd_scroll_8x8_clear_line:
	xor	a							; Clear A
	call	nc100_lcd_write_screen_actual
	inc	hl							; Increment pointer
	inc	de							; Increment byte count
	ld	a, d
	cp	0x02							; See if 512 bytes have been cleared
	jr	nz, nc100_lcd_scroll_8x8_clear_line
	pop	hl							; Restore data
	pop	de
	ret

; # nc100_lcd_backspace_8x8
; #################################
;  Moves back one character and blanks poisition
;	In:	D = y position (0-63)
;		E = x position/memory cell (0-59)
;		HL = cursor address
nc100_lcd_backspace_8x8:
	ld	a, e							; Check if X position
	cp	0x00							; Is zero
	jr	z, nc100_lcd_backspace_8x8_update_position
	dec	e							; Decrement X position
	dec	hl							; Decrement cursor position
	jr	nc100_lcd_backspace_8x8_end
nc100_lcd_backspace_8x8_update_position:
	ld	a, d							; Get Y position
	sub	0x08							; Subtract 1 character line
	jr	c, nc100_lcd_backspace_8x8_update_position_wrapped	; Gone off the top of the screen
	ld	e, 0x3b							; Set character to the last character column
	jr	nc100_lcd_backspace_8x8_set_position
nc100_lcd_backspace_8x8_update_position_wrapped:
	add	a, 64							; Get the Y position at the bottom of the screen
	ld	d, a							; Save Y position
	ld	e, 0x3b							; Set X position (almost certainly wrong, there is no right answer here)
nc100_lcd_backspace_8x8_set_position:
	jp	nc100_lcd_set_cursor_by_grid				; Set cursor position
nc100_lcd_backspace_8x8_end:
	ld	(nc100_lcd_pos_xy), de					; Save cursor X/Y position
	ld	(nc100_raster_cursor_addr), hl				; Save cursor position
	ld	a, ' '							; Overwrite previous character with a space
	jp	nc100_lcd_print_glyph_only_8x8
