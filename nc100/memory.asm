; # Memory routines
; ###########################################################################
; # nc100_memory_page_set
; #################################
;  Assigns a 16k page from a particular source to an address range.
;	In:	B = Page config
;		C = Bank address

; # Page operations
; ###########################################################################
nc100_memory_page_set:
	out	(c), b						; Assign memory page to address bank
	ret

; # nc100_memory_page_get
; #################################
;  Read in the current memory config for a particular bank address.
;	In:	C = Bank address
;	Out:	B = Page config
nc100_memory_page_get:
	in	b, (c)						; Read address bank config
	ret

; # Memory card  operations
; ###########################################################################
; # nc100_memory_memcard_present
; #################################
;  Checks whether there is a memory card available
;	Out:	Carry flag set if present, clear if not
nc100_memory_memcard_present:
	in	a, (nc100_io_misc_status_A)			; Read general status
	and	nc100_memcard_present				; Check memcard present bit
	scf							; Set Carry flag
	jr	z, nc100_memory_memcard_present_exit		; Memcard present
	ccf							; Clear (complement) Carry flag
nc100_memory_memcard_present_exit:
	ret

; # nc100_memory_memcard_read_only
; #################################
;  Checks whether a memory card is write protected
;	Out:	Carry flag set if read only, clear if not
nc100_memory_memcard_read_only:
	in	a, (nc100_io_misc_status_A)			; Read general status
	and	nc100_memcard_write_prot			; Check memcard write protected
	scf							; Set Carry flag
	jr	nz, nc100_memory_memcard_read_only_exit		; Memcard write protected
	ccf							; Clear (complement) Carry flag
nc100_memory_memcard_read_only_exit:
	ret

; # nc100_memory_memcard_wstates_on
; #################################
;  Turns on wait states for memory cards that are 200ns or slower
nc100_memory_memcard_wstates_on:
	ld	a, 0xff
	out	(nc100_io_memcard_wait_control), a
	ret

; # nc100_memory_memcard_wstates_off
; #################################
;  Turns off wait states for memory cards that are faster than 200ns
nc100_memory_memcard_wstates_off:
	ld	a, 0x7f
	out	(nc100_io_memcard_wait_control), a
	ret
