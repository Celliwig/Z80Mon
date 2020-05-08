; # Keyboard routines
; ###########################################################################
;  The interrupt handler reads the state stored in the keyboard buffers (0xB0-0xB9)
;  and stores the raw keycode of the depressed key, and possible state keys (shift, etc).
;  The raw key code is then converted to an ASCII keycode in the main keyboard routines.
;

; Keyboard raw keycodes
nc100_rawkey_na:			equ		0x0		; Not Applicable
; Row 1
nc100_rawkey_1:				equ		0x01
nc100_rawkey_2:				equ		0x02
nc100_rawkey_3:				equ		0x03
nc100_rawkey_4:				equ		0x04
nc100_rawkey_5:				equ		0x05
nc100_rawkey_6:				equ		0x06
nc100_rawkey_7:				equ		0x07
nc100_rawkey_8:				equ		0x08
nc100_rawkey_9:				equ		0x09
nc100_rawkey_0:				equ		0x0a
nc100_rawkey_minus:			equ		0x0b
nc100_rawkey_equal:			equ		0x0c
nc100_rawkey_delete:			equ		0x0d
nc100_rawkey_bspace:			equ		0x0e
; Row 2
nc100_rawkey_tab:			equ		0x0f
nc100_rawkey_q:				equ		0x10
nc100_rawkey_w:				equ		0x11
nc100_rawkey_e:				equ		0x12
nc100_rawkey_r:				equ		0x13
nc100_rawkey_t:				equ		0x14
nc100_rawkey_y:				equ		0x15
nc100_rawkey_u:				equ		0x16
nc100_rawkey_i:				equ		0x17
nc100_rawkey_o:				equ		0x18
nc100_rawkey_p:				equ		0x19
nc100_rawkey_lbrace:			equ		0x1a
nc100_rawkey_rbrace:			equ		0x1b
nc100_rawkey_enter:			equ		0x1c
; Row 3
nc100_rawkey_a:				equ		0x1d
nc100_rawkey_s:				equ		0x1e
nc100_rawkey_d:				equ		0x1f
nc100_rawkey_f:				equ		0x20
nc100_rawkey_g:				equ		0x21
nc100_rawkey_h:				equ		0x22
nc100_rawkey_j:				equ		0x23
nc100_rawkey_k:				equ		0x24
nc100_rawkey_l:				equ		0x25
nc100_rawkey_scolon:			equ		0x26
nc100_rawkey_apos:			equ		0x27
nc100_rawkey_hash:			equ		0x28
; Row 4
nc100_rawkey_z:				equ		0x29
nc100_rawkey_x:				equ		0x2a
nc100_rawkey_c:				equ		0x2b
nc100_rawkey_v:				equ		0x2c
nc100_rawkey_b:				equ		0x2d
nc100_rawkey_n:				equ		0x2e
nc100_rawkey_m:				equ		0x2f
nc100_rawkey_comma:			equ		0x30
nc100_rawkey_period:			equ		0x31
nc100_rawkey_fslash:			equ		0x32
; Row 5
nc100_rawkey_space:			equ		0x33
nc100_rawkey_bslash:			equ		0x34
nc100_rawkey_left:			equ		0x35
nc100_rawkey_right:			equ		0x36
nc100_rawkey_up:			equ		0x37
nc100_rawkey_down:			equ		0x38
; Control key codes
nc100_rawkey_capslock:			equ		0x81		; Capslock key
nc100_rawkey_capslock_bit:		equ		0
nc100_rawkey_shift:			equ		0x82		; Shift key
nc100_rawkey_shift_bit:			equ		1
nc100_rawkey_function:			equ		0x84		; Function key
nc100_rawkey_function_bit:		equ		2
nc100_rawkey_control:			equ		0x88		; Control key
nc100_rawkey_control_bit:		equ		3
nc100_rawkey_stop:			equ		0x90		; Stop key
nc100_rawkey_stop_bit:			equ		4
nc100_rawkey_symbol:			equ		0xa0		; Symbol key
nc100_rawkey_symbol_bit:		equ		5
nc100_rawkey_menu:			equ		0xc0		; Menu key
nc100_rawkey_menu_bit:			equ		6
nc100_rawkey_capslock_state_bit:	equ		7		; Reuse msb as storage for capslock state

nc100_keyboard_keytable_raw:
	db	nc100_rawkey_shift	, nc100_rawkey_shift	, nc100_rawkey_na	, nc100_rawkey_left	, nc100_rawkey_enter	, nc100_rawkey_na	, nc100_rawkey_na	, nc100_rawkey_na
	db	nc100_rawkey_function	, nc100_rawkey_control	, nc100_rawkey_stop	, nc100_rawkey_space	, nc100_rawkey_na	, nc100_rawkey_na	, nc100_rawkey_5	, nc100_rawkey_na
	db	nc100_rawkey_capslock	, nc100_rawkey_symbol	, nc100_rawkey_1	, nc100_rawkey_tab	, nc100_rawkey_na	, nc100_rawkey_na	, nc100_rawkey_na	, nc100_rawkey_na
	db	nc100_rawkey_3		, nc100_rawkey_2	, nc100_rawkey_q	, nc100_rawkey_w	, nc100_rawkey_e	, nc100_rawkey_na	, nc100_rawkey_s	, nc100_rawkey_d
	db	nc100_rawkey_4		, nc100_rawkey_na	, nc100_rawkey_z	, nc100_rawkey_x	, nc100_rawkey_a	, nc100_rawkey_na	, nc100_rawkey_r	, nc100_rawkey_f
	db	nc100_rawkey_na		, nc100_rawkey_na	, nc100_rawkey_b	, nc100_rawkey_v	, nc100_rawkey_t	, nc100_rawkey_y	, nc100_rawkey_g	, nc100_rawkey_c
	db	nc100_rawkey_6		, nc100_rawkey_down	, nc100_rawkey_delete	, nc100_rawkey_right	, nc100_rawkey_hash	, nc100_rawkey_fslash	, nc100_rawkey_h	, nc100_rawkey_n
	db	nc100_rawkey_equal	, nc100_rawkey_7	, nc100_rawkey_bslash	, nc100_rawkey_up	, nc100_rawkey_menu	, nc100_rawkey_u	, nc100_rawkey_m	, nc100_rawkey_k
	db	nc100_rawkey_8		, nc100_rawkey_minus	, nc100_rawkey_rbrace	, nc100_rawkey_lbrace	, nc100_rawkey_apos	, nc100_rawkey_i	, nc100_rawkey_j	, nc100_rawkey_comma
	db	nc100_rawkey_0		, nc100_rawkey_9	, nc100_rawkey_bspace	, nc100_rawkey_p	, nc100_rawkey_scolon	, nc100_rawkey_l	, nc100_rawkey_o	, nc100_rawkey_period

; Lowercase key translation table
nc100_keyboard_keytable_lower:
	db	'1', '2', '3', '4', '5', '6', '7', '8'
	db	'9', '0', '-', '=', character_code_delete, character_code_backspace, character_code_tab, 'q'
	db	'w', 'e', 'r', 't', 'y', 'u', 'i', 'o'
	db	'p', '[', ']', character_code_carriage_return, 'a', 's', 'd', 'f'
	db	'g', 'h', 'j', 'k', 'l', ';', 0x27, '#'
	db	'z', 'x', 'c', 'v', 'b', 'n', 'm', ','
	db	'.', '/', ' ', '\\', character_code_left, character_code_right, character_code_up, character_code_down

; Uppercase key translation table
nc100_keyboard_keytable_upper:
; Need to work out a keycode for the pound sign
;	db	'!', '"', '£', '$', '%', '^', '&', '*'
	db	'!', '"', '$', '$', '%', '^', '&', '*'
	db	'(', ')', '_', '+', character_code_delete, character_code_backspace, character_code_tab, 'Q'
	db	'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O'
	db	'P', '{', '}', character_code_carriage_return, 'A', 'S', 'D', 'F'
	db	'G', 'H', 'J', 'K', 'L', ':', '@', '~'
	db	'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<'
	db	'>', '?', ' ', '|', character_code_left, character_code_right, character_code_up, character_code_down


;nc100_keyboard_controller_capslock_key:	equ		1 << 0		; Bit: capslock key state: 1 = Down, 0 = Up
;nc100_keyboard_controller_capslock_on:	equ		1 << 1		; Bit: capslock state: 1 = On, 0 = Off

; ###########################################################################
; # nc100_keyboard_char_in
; #################################
;  Returns a character from the keyboard if one is depressed
;	Out:	A = ASCII character code
;	Carry flag set if character valid
nc100_keyboard_char_in:
	ld	bc, (nc100_keyboard_raw_control)			; B = nc100_keyboard_raw_control_prev, C = nc100_keyboard_raw_control
	ld	de, (nc100_keyboard_raw_keycode)			; D = nc100_keyboard_raw_keycode_prev, E = nc100_keyboard_raw_keycode
	ld	hl, (nc100_keyboard_controller_state)			; H = nc100_keyboard_raw_character_count, L = nc100_keyboard_controller_state

; Copy msb from previous control to current
	bit	nc100_rawkey_capslock_state_bit, b
	jr	z, nc100_keyboard_char_in_control
	set	nc100_rawkey_capslock_state_bit, c

; Check if Escape (Stop), is pressed
; Overrides everything else
nc100_keyboard_char_in_control:
	ld	a, b							; Diff current/previous control key state
	xor	c
	jr	z, nc100_keyboard_char_in_check				; If no bits have change, process character
	bit	nc100_rawkey_capslock_bit, a				; Check capslock
	jr	nz, nc100_keyboard_char_in_capslock_update
	bit	nc100_rawkey_stop_bit, a				; Check escape
	jr	z, nc100_keyboard_char_in_check
	bit	nc100_rawkey_stop_bit, c
	jr	z, nc100_keyboard_char_in_check
	ld	b, c							; Update control state
	ld	(nc100_keyboard_raw_control), bc			; Update the previous state variable
	ld	a, character_code_escape
	scf								; Set Carry flag (valid character)
	ret

nc100_keyboard_char_in_capslock_update:
	bit	nc100_rawkey_capslock_bit, c
	jr	z, nc100_keyboard_char_in_check
	ld	a, c							; Get current control state
	xor	1 << nc100_rawkey_capslock_state_bit			; Flip capslock state
	ld	c, a							; Save control state

nc100_keyboard_char_in_check:
	ld	a, h							; Get character count
	cp	1							; Check there's only 1 character
	jr	nz, nc100_keyboard_char_in_none				; If no character, return

nc100_keyboard_char_in_check_change:
	ld	a, e							; Load character code
	xor	d							; Check if key changed
	jr	z, nc100_keyboard_char_in_none
	ld	d, e							; Update previous state information
	ld	b, c
	ld	(nc100_keyboard_raw_control), bc			; Update the previous state variable
	ld	(nc100_keyboard_raw_keycode), de			; Update the previous state variable

	ld	a, c
	and	nc100_rawkey_shift					; Check whether shift is depressed (or capslock is on as msb not stripped)
	jr	nz, nc100_keyboard_char_in_case_upper
	ld	hl, nc100_keyboard_keytable_lower			; Get ASCII keycode from translation table
	jr	nc100_keyboard_char_in_case_selected
nc100_keyboard_char_in_case_upper:
	ld	hl, nc100_keyboard_keytable_upper			; Get ASCII keycode from translation table
nc100_keyboard_char_in_case_selected:
	ld	d, 0
	dec	e
	add	hl, de
	ld	a, (hl)

nc100_keyboard_char_in_finished:
	scf								; Set Carry flag (valid character)
	ret
nc100_keyboard_char_in_none:
	ld	d, e							; Update previous state information
	ld	b, c
	ld	(nc100_keyboard_raw_control), bc			; Update the previous state variable
	ld	(nc100_keyboard_raw_keycode), de			; Update the previous state variable
	scf								; Clear Carry flag (invalid character)
	ccf
	ret

; ###########################################################################
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
	ld	hl, nc100_keyboard_keytable_raw-1			; HL = Pointer to raw keymap
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
	and	0x7f							; Strip msb (it's used to indicate that this is a control character)
	ld	(nc100_keyboard_raw_control), a				; Save control key values
	db	0xdd, 0x7d						; Undocumented instruction: LD	A, IXl
	ld	(nc100_keyboard_raw_character_count), a			; Save character count

	ld	a, nc100_irq_key_scan
	jp	interrupt_source_clear					; Clear keyboard interrupt

