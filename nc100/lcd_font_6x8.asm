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

