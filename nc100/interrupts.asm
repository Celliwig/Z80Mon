; # Interrupt handlers
; ###########################################################################
; # interrupt_set_mask_enabled
; #################################
;  Enable given interrupts (register is write only)
;  Should probably disable interrupts before calling this
;	In:	A = ORed list of interrupts to enable
interrupt_set_mask_enabled:
	out	(nc100_io_irq_mask), a					; Set mask configuration
	ret

; # interrupt_source_check
; #################################
;  Check whether a source produced an interrupt
;	In:	A = interrupt to check
;	Out:	Z flag set if interrupt source pending
interrupt_source_check:
	ld	b, a							; Save interrupt source
	in	a, (nc100_io_irq_status)				; Get current interrupt source status
	and	b							; Get the status of the interrupt
	ret

; # interrupt_source_clear
; #################################
;  Clear interrupt source flag
;  Write 0 to clear a 0, who does this???
;	In:	A = interrupt to check
interrupt_source_clear:
	cpl								; Produce a bit mask from the interrupt source
	out	(nc100_io_irq_status), a				; Apply bit mask to clear flag
	ret
