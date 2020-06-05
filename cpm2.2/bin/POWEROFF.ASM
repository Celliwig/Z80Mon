; System poweroff
;**************************************************************
org	0x100
	ld	a, 0x00		; Clear whole register
	ld	c, 0x70		; Power control register address
	out	(c), a		; Write power control register
poweroff_loop:
	halt			; Need as the CPU continues to execute for several cycles after flag has been set
	jp	poweroff_loop	; Just in case there's an interrupt before system shutdown
