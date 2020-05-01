; # Keyboard routines
; ###########################################################################
; Control key codes
nc100_key_capslock:			equ		0x81		; Capslock key
nc100_key_shift:			equ		0x82		; Shift key
nc100_key_function:			equ		0x84		; Function key
nc100_key_control:			equ		0x88		; Control key
nc100_key_stop:				equ		0x90		; Stop key
nc100_key_symbol:			equ		0xa0		; Symbol key
nc100_key_menu:				equ		0xc0		; Menu key

; Cursor keys
nc100_key_left:				equ		0x11		; Repurpose 'Device Control' ASCII codes
nc100_key_right:			equ		0x12
nc100_key_up:				equ		0x13
nc100_key_down:				equ		0x14

; Other keys
nc100_key_enter:			equ		0x0d		; Carriage return
nc100_key_tab:				equ		0x09		; Tab
nc100_key_backspace:			equ		0x08		; Backspace
nc100_key_delete:			equ		0x7f		; Delete

nc100_keyboard_raw_keytable:
		db		nc100_key_shift, nc100_key_shift, 0x00, nc100_key_left, nc100_key_enter, 0x00, 0x00, 0x00
		db		nc100_key_function, nc100_key_control, nc100_key_stop, ' ', 0x00, 0x00, '5', 0x00
		db		nc100_key_capslock, nc100_key_symbol, '1', nc100_key_tab, 0x00, 0x00, 0x00, 0x00
		db		'3', '2', 'Q', 'W', 'E', 0x00, 'S', 'D'
		db		'4', 0x00, 'Z', 'X', 'A', 0x00, 'R', 'F'
		db		0x00, 0x00, 'B', 'V', 'T', 'Y', 'G', 'C'
		db		'6', nc100_key_down, nc100_key_delete, nc100_key_right, '#', '?', 'H', 'N'
		db		'=', '7', '\\', nc100_key_up, nc100_key_menu, 'U', 'M', 'K'
		db		'8', '-', ']', '[', "'", 'I', 'J', ','
		db		'0', '9', nc100_key_backspace, 'P', ';', 'L', 'O', '.'

nc100_keyboard_controller_capslock_key:	equ		1 << 0		; Bit: capslock key state: 1 = Down, 0 = Up
nc100_keyboard_controller_capslock_on:	equ		1 << 1		; Bit: capslock state: 1 = On, 0 = Off

; # nc100_keyboard_char_in
; #################################
;  Returns a character from the keyboard if one is depressed
;	Out:	A = ASCII character code
;	Carry flag set if character valid
nc100_keyboard_char_in:
	ld	bc, (nc100_keyboard_raw_control_prev)			; B = nc100_keyboard_raw_control, C = nc100_keyboard_raw_control_prev
	ld	de, (nc100_keyboard_raw_keycode_prev)			; D = nc100_keyboard_raw_keycode, E = nc100_keyboard_raw_keycode_prev
	ld	hl, (nc100_keyboard_controller_state)			; H = nc100_keyboard_raw_character_count, L = nc100_keyboard_controller_state

nc100_keyboard_char_in_capslock_update:
	ld	a, b							; Diff current/previous control key state
	xor	c
	and	nc100_key_capslock					; Check Capslock state
	jr	z, nc100_keyboard_char_in_check				; Skip if no change
	xor	a							; Clear A
	bit	0, l							; Check capslock key state
	jr	z, nc100_keyboard_char_in_capslock_update_end
	or	nc100_keyboard_controller_capslock_on			; Add capslock on flag
nc100_keyboard_char_in_capslock_update_end:
	or	nc100_keyboard_controller_capslock_key			; Add capslock key state flag
	xor	l							; Flip flag(s) state
	ld	l, a							; Save controller state
	ld	(nc100_keyboard_controller_state), hl			; Really save controller state

nc100_keyboard_char_in_check:
	ld	a, h							; Get character count
	cp	1							; Check there's only 1 character
	jr	nz, nc100_keyboard_char_in_none				; If no character, return

	ld	a, d							; Load character code
	xor	e							; Check if key changed
	jr	z, nc100_keyboard_char_in_none
	ld	a, d							; Reload character value

	ld	e, d							; Update previous state information
	ld	c, b
	ld	(nc100_keyboard_raw_control_prev), bc			; Update the previous state variable
	ld	(nc100_keyboard_raw_keycode_prev), de			; Update the previous state variable
	scf								; Set Carry flag (valid character)
	ret
nc100_keyboard_char_in_none:
	ld	e, d							; Update previous state information
	ld	c, b
	ld	(nc100_keyboard_raw_control_prev), bc			; Update the previous state variable
	ld	(nc100_keyboard_raw_keycode_prev), de			; Update the previous state variable
	scf								; Clear Carry flag (invalid character)
	ccf
	ret

; # interrupt_handler_keyboard
; #################################
;  Keyboard interrupt handler
;  Every 10ms the keyboard is scanned and an interrupt is generate.
interrupt_handler_keyboard:

;	ld	a, 0							; A = mapped key value
;	ld	bc, 0x0ab0						; B = register count, C = port number
;	ld	de, 0x0000						; D = keyboard buffer value, E = accumulative character value
;	ld	hl, 0x0000						; H = control keys, L = character count
;	ld	ix, 
;
; Paths:
;	No key: 10 + 8 + 12 = 30
;	Normal key: 10 + 8 + 7 + 19 + 8 + 7 + 4 + 4 + 4 + 12 = 83
;	Control key: 10 + 8 + 7 + 19 + 8 + 12 + 4 + 4 = 72
;interrupt_handler_keyboard_loop:
;12:	in	d, (c)							; Get keyboard buffer
;interrupt_handler_keyboard_loop_bit0:
;10:	inc	ix							; Increment raw keymap pointer
;8:	bit	0, d							; Test bit 0
;12/7:	jr	z, interrupt_handler_keyboard_loop_bit1			; Bit isn't set, so jump to next bit
;19:	ld	a, (ix+0)						; Get associated character value
;8:	bit	7, a							; Test if control key
;12/7:	jr	nz, interrupt_handler_keyboard_loop_bit0_control_key
;4:	xor	e							; XORed, so that, when 2 characters are registered a new character can be determined from the previous value
;4:	ld	e, a							; Save accumulative character value
;4:	inc	l							; Increment character count
;12/7	jr	interrupt_handler_keyboard_loop_bit1			; Test next bit
;interrupt_handler_keyboard_loop_bit0_control_key:
;4:	or	h							; OR control key values
;4:	ld	h, a							; Save control key values

	ld	a, 0							; A = mapped key value
	ld	bc, 0x00b0						; B = keyboard buffer value, C = port number
	ld	de, 0x0000						; D = accumulative character value, E = control keys
	ld	hl, nc100_keyboard_raw_keytable-1			; HL = Pointer to raw keymap
	ld	ix, 0x0000						; IX = character count

; Paths:
;	No key: 6 + 8 + 12 = 26
;	Normal key: 6 + 8 + 7 + 7 + 8 + 7 + 4 + 4 + 10 + 10 = 71
;	Control key: 6 + 8 + 7 + 7 + 8 + 12 + 4 + 4 = 56
interrupt_handler_keyboard_loop:
	in	b, (c)							; Get keyboard buffer

	; Bypass bitchecks where no bits are set
	ld	a, b
	and	a							; Check whether bits are all zero
	jr	nz, interrupt_handler_keyboard_loop_bit0		; Only check bits if some are set
	ld	a, 8							; Increment HL by 8 (which would happen if executing main body)
	add	a, l							; Doesn't require additional 16 bit reg
	ld	l, a							; Ticks = 27
	ld	a, 0
	adc	a, h
	ld	h, a

;	inc	hl							; Increment HL by 8
;	inc	hl							; All other 16 bit registers in use
;	inc	hl							; Ticks = 48
;	inc	hl
;	inc	hl
;	inc	hl
;	inc	hl
;	inc	hl
	jp	interrupt_handler_keyboard_loop_port_check
interrupt_handler_keyboard_loop_bit0:
	inc	hl							; Increment raw keymap pointer
	bit	0, b							; Test bit 0
	jr	z, interrupt_handler_keyboard_loop_bit1			; Bit isn't set, so jump to next bit
	ld	a, (hl)							; Get associated character value
	bit	7, a							; Test if control key
	jr	nz, interrupt_handler_keyboard_loop_bit0_control_key
	xor	d							; XORed, so that, when 2 characters are registered a new character can be determined from the previous value
	ld	d, a							; Save accumulative character value
	inc	ix							; Increment character count
	jp	interrupt_handler_keyboard_loop_bit1			; Test next bit
interrupt_handler_keyboard_loop_bit0_control_key:
	or	e							; OR control key values
	ld	e, a							; Save control key values
interrupt_handler_keyboard_loop_bit1:
	inc	hl							; Increment raw keymap pointer
	bit	1, b							; Test bit 1
	jr	z, interrupt_handler_keyboard_loop_bit2			; Bit isn't set, so jump to next bit
	ld	a, (hl)							; Get associated character value
	bit	7, a							; Test if control key
	jr	nz, interrupt_handler_keyboard_loop_bit1_control_key
	xor	d							; XORed, so that, when 2 characters are registered a new character can be determined from the previous value
	ld	d, a							; Save accumulative character value
	inc	ix							; Increment character count
	jp	interrupt_handler_keyboard_loop_bit2			; Test next bit
interrupt_handler_keyboard_loop_bit1_control_key:
	or	e							; OR control key values
	ld	e, a							; Save control key values
interrupt_handler_keyboard_loop_bit2:
	inc	hl							; Increment raw keymap pointer
	bit	2, b							; Test bit 2
	jr	z, interrupt_handler_keyboard_loop_bit3			; Bit isn't set, so jump to next bit
	ld	a, (hl)							; Get associated character value
	bit	7, a							; Test if control key
	jr	nz, interrupt_handler_keyboard_loop_bit2_control_key
	xor	d							; XORed, so that, when 2 characters are registered a new character can be determined from the previous value
	ld	d, a							; Save accumulative character value
	inc	ix							; Increment character count
	jp	interrupt_handler_keyboard_loop_bit3			; Test next bit
interrupt_handler_keyboard_loop_bit2_control_key:
	or	e							; OR control key values
	ld	e, a							; Save control key values
interrupt_handler_keyboard_loop_bit3:
	inc	hl							; Increment raw keymap pointer
	bit	3, b							; Test bit 3
	jr	z, interrupt_handler_keyboard_loop_bit4			; Bit isn't set, so jump to next bit
	ld	a, (hl)							; Get associated character value
	bit	7, a							; Test if control key
	jr	nz, interrupt_handler_keyboard_loop_bit3_control_key
	xor	d							; XORed, so that, when 2 characters are registered a new character can be determined from the previous value
	ld	d, a							; Save accumulative character value
	inc	ix							; Increment character count
	jp	interrupt_handler_keyboard_loop_bit4			; Test next bit
interrupt_handler_keyboard_loop_bit3_control_key:
	or	e							; OR control key values
	ld	e, a							; Save control key values
interrupt_handler_keyboard_loop_bit4:
	inc	hl							; Increment raw keymap pointer
	bit	4, b							; Test bit 4
	jr	z, interrupt_handler_keyboard_loop_bit5			; Bit isn't set, so jump to next bit
	ld	a, (hl)							; Get associated character value
	bit	7, a							; Test if control key
	jr	nz, interrupt_handler_keyboard_loop_bit4_control_key
	xor	d							; XORed, so that, when 2 characters are registered a new character can be determined from the previous value
	ld	d, a							; Save accumulative character value
	inc	ix							; Increment character count
	jp	interrupt_handler_keyboard_loop_bit5			; Test next bit
interrupt_handler_keyboard_loop_bit4_control_key:
	or	e							; OR control key values
	ld	e, a							; Save control key values
interrupt_handler_keyboard_loop_bit5:
	inc	hl							; Increment raw keymap pointer
	bit	5, b							; Test bit 5
	jr	z, interrupt_handler_keyboard_loop_bit6			; Bit isn't set, so jump to next bit
	ld	a, (hl)							; Get associated character value
	bit	7, a							; Test if control key
	jr	nz, interrupt_handler_keyboard_loop_bit5_control_key
	xor	d							; XORed, so that, when 2 characters are registered a new character can be determined from the previous value
	ld	d, a							; Save accumulative character value
	inc	ix							; Increment character count
	jp	interrupt_handler_keyboard_loop_bit6			; Test next bit
interrupt_handler_keyboard_loop_bit5_control_key:
	or	e							; OR control key values
	ld	e, a							; Save control key values
interrupt_handler_keyboard_loop_bit6:
	inc	hl							; Increment raw keymap pointer
	bit	6, b							; Test bit 6
	jr	z, interrupt_handler_keyboard_loop_bit7			; Bit isn't set, so jump to next bit
	ld	a, (hl)							; Get associated character value
	bit	7, a							; Test if control key
	jr	nz, interrupt_handler_keyboard_loop_bit6_control_key
	xor	d							; XORed, so that, when 2 characters are registered a new character can be determined from the previous value
	ld	d, a							; Save accumulative character value
	inc	ix							; Increment character count
	jp	interrupt_handler_keyboard_loop_bit7			; Test next bit
interrupt_handler_keyboard_loop_bit6_control_key:
	or	e							; OR control key values
	ld	e, a							; Save control key values
interrupt_handler_keyboard_loop_bit7:
	inc	hl							; Increment raw keymap pointer
	bit	7, b							; Test bit 7
	jr	z, interrupt_handler_keyboard_loop_port_check		; Bit isn't set, so jump to next bit
	ld	a, (hl)							; Get associated character value
	bit	7, a							; Test if control key
	jr	nz, interrupt_handler_keyboard_loop_bit7_control_key
	xor	d							; XORed, so that, when 2 characters are registered a new character can be determined from the previous value
	ld	d, a							; Save accumulative character value
	inc	ix							; Increment character count
	jp	interrupt_handler_keyboard_loop_port_check		; Test next bit
interrupt_handler_keyboard_loop_bit7_control_key:
	or	e							; OR control key values
	ld	e, a							; Save control key values
interrupt_handler_keyboard_loop_port_check:
	inc	c							; Increment port number
	ld	a, c
	cp	0xba							; Check port number (loop through 0xb0-0xb9)
	jr	z, interrupt_handler_keyboard_finish			; We're done
	jp	interrupt_handler_keyboard_loop

interrupt_handler_keyboard_finish:
	ld	a, d
	ld	(nc100_keyboard_raw_keycode), a				; Save accumulative character value
	ld	a, e
	ld	(nc100_keyboard_raw_control), a				; Save control key values
	db	0xdd, 0x7d						; Undocumented instruction: LD	A, IXl
	ld	(nc100_keyboard_raw_character_count), a			; Save character count

	ld	a, nc100_irq_key_scan
	jp	interrupt_source_clear					; Clear keyboard interrupt

