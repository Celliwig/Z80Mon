; # I/O routines
; ###########################################################################
;  A number of registers attached to the I/O port are write only. To handle
;  different fuctions accessing them a copy of the data is stored in RAM so
;  that the contents of the register can be interogated.

; # nc100_io_misc_config_A_write
; #################################
;  Masks the saved register value, then applies
;  supplied value which is then written to the port
;	In:	A = Value to apply
;		B = Bitmask of values to keep
nc100_io_misc_config_A_write:
	ex	af, af'							; Swap register to save A
	ld	a, (nc100_io_mirror_misc_config_A)			; Get current I/O register value
	and	b							; Apply bitmask
	ld	b, a							; Save current bitmasked value
	ex	af, af'							; Swap A back in
	or	b							; Combine bitmasked current value with new value
	ld	(nc100_io_mirror_misc_config_A), a			; Save new value
	out	(nc100_io_misc_config_A), a				; Write value to I/O port
	ret
