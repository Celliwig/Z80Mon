; ###########################################################################
; #                                                                         #
; #                                 Z80Mon                                  #
; #                                                                         #
; ###########################################################################
;
; Z80 monitor inspired by PaulMON2
;
; Assumes RAM is not necessarily available at startup, and that an init
; module will page in RAM and set stack pointer.
;
; See also:
; 	https://www.pjrc.com/tech/8051/paulmon2.html

; include definitions
include "z80mon.def"

; # Architecture Jump Table
; ###########################################################################
; RST 0 / Processor cold start
orgmem	mem_base
	jp	startup_cold				; Cold startup

; RST 8
orgmem	mem_base+0x08
	jp	startup_warm				; Main startup routine (stack must be available)

; RST 16
orgmem	mem_base+0x10
	jp	startup_final				; Startup completed

; RST 24
orgmem	mem_base+0x18
	ds	8

; RST 32
orgmem	mem_base+0x20
	ds	8

; RST 40
orgmem	mem_base+0x28
	ds	8

; RST 48
orgmem	mem_base+0x30
	ds	8

; RST 56 / Mode 1 maskable interrupt
orgmem	mem_base+0x38
z80_interrupt_handler:
	reti						; RETI added to ignore maskable interrupt
	reti						; Additional library may overwrite
	reti						; With actual interrupt handler
	reti

; NMI
orgmem	mem_base+0x66
z80_nm_interrupt_handler:
	retn						; RETN added to ignore non-maskable interrupt
	retn						; Additional library may overwrite
	retn						; With actual interrupt handler
	retn

; # Subroutine Jump Table
; ###########################################################################
orgmem	mem_base+0x80

monlib_console_out:
	jp	dummy_char_out
monlib_console_in:
	jp	dummy_char_in
monlib_print_newline:
	jp	print_newline
monlib_print_hex_digit:
	jp	print_hex_digit
monlib_print_hex8:
	jp	print_hex8
monlib_print_hex16:
	jp	print_hex16
monlib_print_dec8u:
	jp	print_dec8u
monlib_print_dec8s:
	jp	print_dec8s
monlib_print_str:
	jp	print_str
monlib_char_2_upper:
	jp	char_2_upper
monlib_string_length:
	jp	string_length

;	ajmp	ghex
;	ajmp	ghex16
;	ajmp	esc
;	ljmp	autobaud
;pcstr_h:ljmp	pcstr
;	ljmp	pint16u
;	ljmp	module_find
;input_character_filter_h:
;	ljmp	input_character_filter
;	ajmp	asc2hex

; # Monitor Variables
; ###########################################################################
z80mon_default_addr:
	dw	0x1000
z80mon_temp1:
	dw	0x0000
z80mon_temp2:
	dw	0x0000

; # Monitor
; ###########################################################################
orgmem	mon_base

; # Dummy I/O routines
; ###########################################################################
; # dummy_char_in
; #################################
; Dummy character in routine
;	Out: A = Character
dummy_char_in:
	xor	a
	ret

; # dummy_char_out
; #################################
; Dummy character out routine
;	In: A = Character
dummy_char_out:
	nop
	ret

; # Print routines
; ###########################################################################
; Note: will not alter any registers other than AF.
; Shadow registers fair game.
;
; # print_spacex2
; #################################
;  Print double space
print_spacex2:
	call	print_space
; # print_space
; #################################
;  Print a space
print_space:
	ld	a, ' '
	jp	monlib_console_out
; # print_spaces_n
; #################################
;  Print n spaces
;	In:	B = Number of spaces
print_spaces_n:
	call	print_space
	dec	b
	jr	nz, print_spaces_n
print_spaces_n_exit:
	ret

; # print_dash
; #################################
;  Print '-'
print_dash:
	ld	a, '-'
	jp	monlib_console_out
; # print_dash_spaces
; #################################
;  Print ' - '
print_dash_spaces:
	call	print_space
	call	print_dash
	jr	print_space

; # print_colon_space
; #################################
;  Print ': '
print_colon_space:
	ld	a, ":"
	call	monlib_console_out
	jp	print_space

;cout_sp:acall	cout
;	ajmp	space
;	nop
;

; # print_newlinex2
; #################################
;  Print 2 new lines
print_newlinex2:					; Print two newlines
	call	print_newline
; # print_newline
; #################################
;  Print a new line
print_newline:
	ld	a, character_code_carriage_return
	call	monlib_console_out
	ld	a, character_code_linefeed
	call	monlib_console_out
	ret

; # print_hex16
; #################################
;  Print 16 bit number as hex
; 	In:	BC = 16-bit Integer
print_hex16:
	ld	a, b
	call	print_hex8
	ld	a, c
; # print_hex8
; #################################
;  Print 8 bit number as hex
; 	In:	A = 8-bit Integer
print_hex8:
	push	af
	rrca
	rrca
	rrca
	rrca
	call	print_hex_digit
	pop	af
print_hex_digit:
	and	0x0F
	add	a, 0x90
	daa
	adc	a, 0x40
	daa
	call	monlib_console_out
	ret

; # print_dec8u
; #################################
;  Print 8 bit number as unsigned decimal
;	In:	A = 8-bit Integer
print_dec8u:
	push	bc
	jr	print_dec8
; # print_dec8s
; #################################
;  Print 8 bit number as signed decimal
;	In:	A = 8-bit Integer
print_dec8s:
	push	bc
	bit	7, a					; Test whether negative
	jr	z, print_dec8				; If it's not just continue
	push	af					; Save value
	ld	a, '-'
	call	monlib_console_out
	pop	af					; Restore value
	cpl						; Remove sign, and create positive value - 1
	inc	a
print_dec8:
	ld	b, 100
	call	print_dec8_digit
	ld	b, 10
	call	print_dec8_digit
	ld	b, 1
	call	print_dec8_digit
	pop	bc
	ret
; # print_dec8_digit
; #################################
;	In:	A = Value
;		B = Divider
print_dec8_digit:
	ld	c, '0' - 1				; Setup digit character
print_dec8_digit_loop:
	inc	c					; Increment character digit
	sub	a, b					; Subtract divisor
	jr	nc, print_dec8_digit_loop		; Loop if still greater than zero
	add	b					; Undo last operation
	push	af					; Save current result
	ld	a, c
	call	monlib_console_out
	pop	af					; Restore result
	ret

;	;print 16 bit unsigned integer in DPTR, using base 10.
;pint16u:	;warning, destroys r2, r3, r4, r5, psw.5
;	push	acc
;	mov	a, r0
;	push	acc
;	clr	psw.5
;	mov	r2, dpl
;	mov	r3, dph
;
;pint16a:mov	r4, #16		;ten-thousands digit
;	mov	r5, #39
;	acall	pint16x
;	jz	pint16b
;	add	a, #'0'
;	lcall	cout
;	setb	psw.5
;
;pint16b:mov	r4, #232	;thousands digit
;	mov	r5, #3
;	acall	pint16x
;	jnz	pint16c
;	jnb	psw.5, pint16d
;pint16c:add	a, #'0'
;	lcall	cout
;	setb	psw.5
;
;pint16d:mov	r4, #100	;hundreds digit
;	mov	r5, #0
;	acall	pint16x
;	jnz	pint16e
;	jnb	psw.5, pint16f
;pint16e:add	a, #'0'
;	lcall	cout
;	setb	psw.5
;
;pint16f:mov	a, r2		;tens digit
;	mov	r3, b
;	mov	b, #10
;	div	ab
;	jnz	pint16g
;	jnb	psw.5, pint16h
;pint16g:add	a, #'0'
;	lcall	cout
;
;pint16h:mov	a, b		;and finally the ones digit
;	mov	b, r3
;	add	a, #'0'
;	lcall	cout
;
;	pop	acc
;	mov	r0, a
;	pop	acc
;	ret
;
;;ok, it's a cpu hog and a nasty way to divide, but this code
;;requires only 21 bytes!  Divides r2-r3 by r4-r5 and leaves
;;quotient in r2-r3 and returns remainder in acc.  If Intel
;;had made a proper divide, then this would be much easier.
;
;pint16x:mov	r0, #0
;pint16y:inc	r0
;	clr	c
;	mov	a, r2
;	subb	a, r4
;	mov	r2, a
;	mov	a, r3
;	subb	a, r5
;	mov	r3, a
;	jnc	pint16y
;	dec	r0
;	mov	a, r2
;	add	a, r4
;	mov	r2, a
;	mov	a, r3
;	addc	a, r5
;	mov	r3, a
;	mov	a, r0
;	ret

; # print_str
; #################################
;  Prints a null terminated string.
;  Retains the ability ability to print consecutive strings.
;	In:	HL = Pointer to string
print_str:
	ld	a, (hl)					; Get next character
	inc	hl					; Increment pointer
	and	a					; Test if value is zero
	jr	z, print_str_end			; Check whether NULL character
	push	af					; Save value
	and	0x7f					; Strip msb
	call	monlib_console_out			; Print character
	pop	af					; Restore value
	bit	7, a					; Test value msb
	jr	nz, print_str_end			; If msb set, stop
	jr	print_str				; Loop
print_str_end:
	ret

; # print_cstr
; #################################
;  Prints compressed strings. A dictionary of 128 words is stored in 4
;  bit packed binary format. When it finds a byte in a string with the
;  high bit set, it prints the word from the dictionary. A few bytes
;  have special functions and everything else prints as if it were an
;  ordinary string.
;
;  Special codes for pcstr:
;	0 = end of string
;	13 = CR/LF
;	14 = CR/LF and end of string
;	31 = next word code should be capitalized
;
;	In:	HL = Pointer to compressed string
print_cstr:
	ld	b, 0					; B is used to store state information
	set	1, b					; If unset, prints a space in front of compressed word
	set	5, b					; If unset, prints word with capitalised first letter
print_cstr_next:
	ld	a, (hl)					; Get next character
	inc	hl					; Increment pointer
	and	a					; Test if value is zero
	jr	z, print_cstr_end			; Check whether NULL character
	bit	7, a					; Test msb
	jr	z, print_cstr_check_13
	call	dictionary_print_word			; It's a dictionary word, so print it
	jr	print_cstr_next
print_cstr_check_13:
	cp	13					; Check for control code
	jr	nz, print_cstr_check_14
	call	print_newline
	set	1, b					; Print a space in front of compressed word
	jr	print_cstr_next				; Loop for next character
print_cstr_check_14:
	cp	14					; Check for control code
	jr	nz, print_cstr_check_31
	call	print_newline
	jr	print_cstr_end
print_cstr_check_31:
	cp	31					; Check for control code
	jr	nz, print_cstr_char
	res	5, b					; Reset B(5) so as to capitalise next word
	jr	print_cstr_next
print_cstr_char:
	res	1, b					; Print a space in front of next compressed word.
	call	monlib_console_out			; Print character
	jr	print_cstr_next
print_cstr_end:
	ret

; # dictionary_print_word
; #################################
;  Prints a selected word from the built-in dictionary
;	In:	A = Selected word index
;		B = Control byte
;			bit 1 - 0 = Print space / 1 = Don't print space
;			bit 5 - 0 = Capitalise first letter / 1 = Don't capitalise first letter
;			bit 7 - Used to indicate top/bottom nibble
dictionary_print_word:
	and	0x7F					; Clear msb on A
	ld	c, a					; Save word index
	bit	1, b					; If unset, print a space
	jr	nz, dictionary_print_word_search_setup
	call	print_space				; Print a space
dictionary_print_word_search_setup:
	res	1, b					; Be sure to print a space next time
	ld	ix, common_words			; Get pointer to dictionary
	res	7, b					; Make sure we get the bottom nibble to start
	ld	a, c					; Reload word index
	and	c					; Update flags
dictionary_print_word_search_loop:
	jr	z, dictionary_print_word_selected_loop	; Found the word, so print it
dictionary_print_word_nibble_loop:
	call	dictionary_get_next_nibble		; Scan through nibbles
	jr	nz, dictionary_print_word_nibble_loop	; Searching for the end of a word (A = 0)
	dec	c					; Found the end of the word, so decrement word index
	jr	dictionary_print_word_search_loop	; Search again
dictionary_print_word_selected_loop:
	call	dictionary_get_next_nibble		; Get next compressed character
	jr	z, dictionary_print_word_end		; End of the word, so finish
	cp	0x0f					; Check whether to select alternate letters
	jr	z, dictionary_print_word_select_unloved
dictionary_print_word_select_loved:
	ld	iy, dictionary_loved_letters		; Get pointer to loved letters
	jr	dictionary_print_word_get_char
dictionary_print_word_select_unloved:
	call	dictionary_get_next_nibble		; Get the next character
	ld	iy, dictionary_unloved_letters		; Get pointer to unloved letters
dictionary_print_word_get_char:
	dec	a					; Decrement index
	ld	d, 0
	ld	e, a					; Create offset
	add	iy, de					; Add offset to pointer
	ld	a, (iy+0)				; Get letter
	bit	5, b					; Test whether to capitalise letter
	jr	nz, dictionary_print_word_print_char
	call	char_2_upper				; Capitalise letter
	set	5, b					; Disable capitalisation for the rest of the word
dictionary_print_word_print_char:
	push	ix					; Save IX
	call	monlib_console_out			; Print character
	pop	ix					; Restore IX
	jr	dictionary_print_word_selected_loop	; Loop through additional characters
dictionary_print_word_end:
	ret

dictionary_loved_letters:	db	"etarnisolumpdc"	; 14 most commonly used letters
dictionary_unloved_letters:	db	"hfwgybxvkqjz"		; 12 least commonly used letters

; # dictionary_get_next_nibble
; #################################
;  Returns the selected nibble from the memory location
;  Prints a selected word from the built-in dictionary
;	In:	IX = Pointer to memory location
;		B = Control byte
;			bit 7 - Used to indicate top/bottom nibble
dictionary_get_next_nibble:
	ld	a, (IX+0)
	bit	7, b					; Test whether we want top or bottom nibble
	jr	nz, dictionary_get_next_nibble_top	; We want the top nibble
dictionary_get_next_nibble_bottom:
	and	0x0f
	set	7, b					; Select top nibble on the next read
	ret
dictionary_get_next_nibble_top:
	inc	ix					; Increment pointer
	srl	a
	srl	a
	srl	a
	srl	a					; Top nibble shifted to the bottom
	and	0x0f
	res	7, b					; Select bottom nibble on the next read
	ret

; # print_abort
; #################################
;  Print the abort string
print_abort:
	ld	hl, str_abort
	jp	print_cstr

; # print_registers
; #################################
;  Print out the contents of all registers (without altering them!)
print_registers:
	ld	(z80mon_temp1), sp			; Save stack pointer address
	ex	(sp), hl				; Swap HL <-> return address
	ld	(z80mon_temp2), hl			; Save return address
	ex	(sp), hl				; Swap return address <-> HL

	push	af					; Make a copy of all registers
	push	bc					; Need to restore them later
	push	de
	push	hl
	ex	af, af'					; Swap AF for shadow registers
	exx						; Swap for shadow registers
	push	af					; Make a copy of all registers
	push	bc					; Need to restore them later
	push	de
	push	hl
	push	ix
	push	iy

	; Now push a copy of everything on to the stack to print (in the order we're going to read)
	push	iy
	push	hl
	push	de
	push	bc
	push	af
	ex	af, af'
	exx
	push	ix
	push	hl
	push	de
	push	bc
	push	af

	; Print registers
	call	print_newline
	ld	hl, str_reg_af1
	call	print_str
	pop	bc
	call	print_hex16
	ld	hl, str_reg_bc1
	call	print_str
	pop	bc
	call	print_hex16
	ld	hl, str_reg_de1
	call	print_str
	pop	bc
	call	print_hex16
	ld	hl, str_reg_hl1
	call	print_str
	pop	bc
	call	print_hex16
	ld	hl, str_reg_ix
	call	print_str
	pop	bc
	call	print_hex16
	call	print_newline

	; Print shadow registers
	ld	hl, str_reg_af2
	call	print_str
	pop	bc
	call	print_hex16
	ld	hl, str_reg_bc2
	call	print_str
	pop	bc
	call	print_hex16
	ld	hl, str_reg_de2
	call	print_str
	pop	bc
	call	print_hex16
	ld	hl, str_reg_hl2
	call	print_str
	pop	bc
	call	print_hex16
	ld	hl, str_reg_iy
	call	print_str
	pop	bc
	call	print_hex16
	call	print_newline

	; Print additional registers
	ld	hl, str_reg_sra
	call	print_str
	ld	bc, (z80mon_temp2)
	call	print_hex16
	ld	hl, str_reg_sp
	call	print_str
	ld	bc, (z80mon_temp1)
	call	print_hex16
	call	print_newline

	pop	iy					; Restore shadow register contents
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
	exx						; Exchange
	ex	af, af'
	pop	hl					; Restore register contents
	pop	de
	pop	bc
	pop	af

	ret

; # String routines
; ###########################################################################
; # char_2_upper
; #################################
;  Converts ASCII letter to uppercase if necessary
;	In:	A = ASCII character
;	Out:	A = ASCII character
char_2_upper:
	cp	97					; 'a'
	jr	c, char_2_upper_end
	cp	123					; 'z' + 1
	jr	nc, char_2_upper_end
	add	224
char_2_upper_end:
	ret

; # char_2_hex
; #################################
;  Converts (if possible) a character (A-Z/0-9) to hex value
;	In:	A = ASCII character
;	Out:	A = Hex value
;		Carry set if value valid, not otherwise
char_2_hex:
	add	a, 208
	jr	nc, char_2_hex_not
	add	a, 246
	jr	c, char_2_hex_maybe
	add	a, 10
	scf						; Set Carry flag
	ret
char_2_hex_maybe:
	add	a, 249
	jr	nc, char_2_hex_not
	add	a, 250
	jr	c, char_2_hex_not
	add	a, 16
	scf						; Set Carry flag
	ret
char_2_hex_not:
	scf						; Clear Carry flag
	ccf
	ret

; # string_length
; #################################
;  Calculates the length of the string
;	In:	HL = Pointer to string
;	Out:	BC = String length
string_length:
	push	hl
	ld	bc, 0					; Clear count
string_length_loop:
	ld	a, (hl)					; Get byte to test
	and	a					; Set flags
	jr	z, string_length_end			; Have we reached the end
	inc	bc					; Increment count
	bit	7, a					; See if we have a multi-part string
	jr	nz, string_length_end
	inc	hl					; Increment pointer
	jr	string_length_loop
string_length_end:
	pop	hl
	ret

; # Input routines
; ###########################################################################
; # input_character_filter
; #################################
;  Routine replaces character sequences for up/down/left/right & PageUp/PageDown
;  with values noted below.
;	Return Value	Key		Escape Sequence
;	11 (^K)		Up		1B 5B 41
;	10 (^J)		Down		1B 5B 42
;	21 (^U)		Right		1B 5B 43
;	8 (^H)		Left		1B 5B 44
;	25 (^Y)		PageUp		1B 5B 35 7E
;	26 (^Z)		PageDown	1B 5B 36 7E
;
;	Out:	A = ASCII character code
;	Carry flag set is character value
input_character_filter:
	call	monlib_console_in			; Get character if there is one
;	jnc	input_character_filter_end		; No character available, so finish
;
;	cp	character_code_escape			; Compare character to Escape character
;	jr	nz, input_character_filter_end		; It's not, so finish

	; Need serial port!!!
	; So just pass through

input_character_filter_end:
	ret


;input_character_filter:
;	jnb	ri, cinf1
;	lcall	cin
;	cjne	a, #esc_char, cinf_end
;	;if esc was already in sbuf, just ignore it
;cinf1:
;	lcall	cin
;	cjne	a, #esc_char, cinf_end
;cinf2:
;	acall	cinf_wait
;	jb	ri, cinf4
;	mov	a, #esc_char
;	ret			;an ordinary ESC
;
;cinf4:	;if we get here, it's a control code, since a character
;	;was received shortly after receiving an ESC character
;	lcall	cin
;	cjne	a, #'[', cinf_consume
;	acall	cinf_wait
;	jnb	ri, input_character_filter
;	lcall	cin
;cinf5a:
;	cjne	a, #'A', cinf5b
;	mov	a, #11
;	ret
;cinf5b:
;	cjne	a, #'B', cinf5c
;	mov	a, #10
;	ret
;cinf5c:
;	cjne	a, #'C', cinf5d
;	mov	a, #21
;	ret
;cinf5d:
;	cjne	a, #'D', cinf5e
;	mov	a, #8
;	ret
;cinf5e:
;	cjne	a, #0x35, cinf5f
;	sjmp	cinf8
;cinf5f:
;	cjne	a, #0x36, cinf5g
;	sjmp	cinf8
;cinf5g:
;	sjmp	cinf_consume		;unknown escape sequence
;
;cinf8:	;when we get here, we've got the sequence for pageup/pagedown
;	;but there's one more incoming byte to check...
;	push	acc
;	acall	cinf_wait
;	jnb	ri, cinf_restart
;	lcall	cin
;	cjne	a, #0x7E, cinf_notpg
;	pop	acc
;	add	a, #228
;cinf_end:
;	ret
;cinf_restart:
;	pop	acc
;	sjmp	input_character_filter
;cinf_notpg:
;	pop	acc
;;unrecognized escape... eat up everything that's left coming in
;;quickly, then begin looking again
;cinf_consume:
;	acall	cinf_wait
;	jnb	ri, input_character_filter
;	lcall	cin
;	cjne	a, #esc_char, cinf_consume
;	sjmp	cinf2
;
;;this thing waits for a character to be received for approx
;;4 character transmit time periods.  It returns immedately
;;or after the entire wait time.	 It does not remove the character
;;from the buffer, so ri should be checked to see if something
;;actually did show up while it was waiting
;	.equ	char_delay, 4		;number of char xmit times to wait
;cinf_wait:
;	mov	a, r2
;	push	acc
;	mov	r2, #char_delay*5
;cinfw2:
;	mov	a, th0
;cinfw3:
;	jb	ri, cinfw4
;	inc	a
;	jnz	cinfw3
;	djnz	r2, cinfw2
;cinfw4:
;	pop	acc
;	mov	r2, a
;	ret


;;clearing ti before reading sbuf takes care of the case where
;;interrupts may be enabled... if an interrupt were to happen
;;between those two instructions, the serial port will just
;;wait a while, but in the other order and the character could
;;finish transmitting (during the interrupt routine) and then
;;ti would be cleared and never set again by the hardware, causing
;;the next call to cout to hang forever!
;
;	;get 2 digit hex number from serial port
;	; c = set if ESC pressed, clear otherwise
;	; psw.5 = set if return w/ no input, clear otherwise
;ghex:
;ghex8:	clr	psw.5
;ghex8c:
;	acall	input_character_filter_h	;get first digit
;	acall	char_2_upper
;	cjne	a, #27, ghex8f
;ghex8d: setb	c
;	clr	a
;	ret
;ghex8f: cjne	a, #13, ghex8h
;	setb	psw.5
;	clr	c
;	clr	a
;	ret
;ghex8h: mov	r2, a
;	acall	asc2hex
;	jc	ghex8c
;	xch	a, r2		;r2 will hold hex value of 1st digit
;	acall	cout
;ghex8j:
;	acall	input_character_filter_h	;get second digit
;	acall	char_2_upper
;	cjne	a, #27, ghex8k
;	sjmp	ghex8d
;ghex8k: cjne	a, #13, ghex8m
;	mov	a, r2
;	clr	c
;	ret
;ghex8m: cjne	a, #8, ghex8p
;ghex8n: acall	cout
;	sjmp	ghex8c
;ghex8p: cjne	a, #21, ghex8q
;	sjmp	ghex8n
;ghex8q: mov	r3, a
;	acall	asc2hex
;	jc	ghex8j
;	xch	a, r3
;	acall	cout
;	mov	a, r2
;	swap	a
;	orl	a, r3
;	clr	c
;	ret

; # input_hex16_preloaded
; #################################
;  Routine to enter up to 4 digit hexadecimal number
;	In:	BC = Preload value
;	Out:	DE = Hex value
;		Carry flag set if value valid
input_hex16_preloaded:
	ld	a, b					; Get first digit
	srl	a					; Shift top nible to the bottom
	srl	a
	srl	a
	srl	a
	push	af					; Push digit onto the stack
	call	print_hex_digit				; Print digit
	ld	a, b					; Get second digit
	and	0x0f					; Remove top nibble
	push	af					; Push digit onto the stack
	call	print_hex_digit				; Print digit

	ld	a, c					; Get third digit
	srl	a					; Shift top nible to the bottom
	srl	a
	srl	a
	srl	a
	push	af					; Push digit onto the stack
	call	print_hex_digit				; Print digit
	ld	a, c					; Get fourth digit
	and	0x0f					; Remove top nibble
	push	af					; Push digit onto the stack
	call	print_hex_digit				; Print digit

	ld	b, 4					; Set digit count to max
	jr	input_hex16_get_char
; # input_hex16
; #################################
;  Routine to enter up to 4 digit hexadecimal number
;	Out:	DE = Hex value
;		Carry flag set if value valid
input_hex16:
	ld	b, 0x00					; Digit count

input_hex16_get_char:
	call	input_character_filter			; Get character
	call	char_2_upper
input_hex16_process_char:
	ld	c, a					; Copy character

	cp	character_code_escape			; Check whether character is escape key
	jr	z, input_hex16_abort
	cp	character_code_backspace		; Check whether character is backspace key
	jr	z, input_hex16_delete_digit
	cp	character_code_delete			; Check whether character is delete key
	jr	z, input_hex16_delete_digit
	cp	character_code_carriage_return		; Check whether character is CR key
	jr	z, input_hex16_complete

	ld	a, b					; Check that number of digits <= 4
	sub	0x04
	jr	nc, input_hex16_get_char		; Already have 4 digits, so just loop
	ld	a, c					; Reload character
	call	char_2_hex				; Convert ASCII to hex
	jr	nc, input_hex16_get_char		; Character not valid hex digit so loop
	push	af					; Push hex value on to stack
	inc	b					; Increment digit count
	ld	a, c					; Reload character
	call	monlib_console_out			; Output character
	jr	input_hex16_get_char
input_hex16_delete_digit:
	ld	a, b					; Check if there are digits to delete
	cp	0x00
	jr	z, input_hex16_get_char			; No existing digits, so just wait for next character
	ld	a, c					; Reload character
	call	monlib_console_out			; Update display
	pop	af					; Pop digit from stack
	dec	b					; Decrement digit count
	jr	input_hex16_get_char
input_hex16_abort:
	xor	a					; Clear A
	cp	b					; Check if there's anything to remove from the stack
	jr	z, input_hex16_abort_end		; Nothing to pop, so finish
input_hex16_abort_loop:
	pop	af					; Pop digit
	djnz	input_hex16_abort_loop			; Keep looping until all digits removed
input_hex16_abort_end:
	ld	de, 0x0000				; Zero register
	scf						; Clear Carry flag
	ccf
	ret
input_hex16_complete:
	ld	de, 0x0000				; Zero register
	ld	c, b					; Swap number of digits
	ld	b, 4					; Total number of shifts
	xor	a					; Clear A
	cp	c					; Check if there's anything to remove from the stack
	jr	z, input_hex16_complete_end		; Nothing to pop, so finish
input_hex16_complete_loop:
	; Make some room for a nibble
	srl	d					; Right shift into Carry MSB (bit 1)
	rr	e
	srl	d					; Right shift into Carry MSB (bit 2)
	rr	e
	srl	d					; Right shift into Carry MSB (bit 3)
	rr	e
	srl	d					; Right shift into Carry MSB (bit 4)
	rr	e

	xor	a					; Clear A
	cp	c					; Check whether we have all the digits
	jr	z, input_hex16_complete_check_remainder
	; Add digit
	pop	af					; Pop digit
	sla	a					; Shit digit in to upper nibble
	sla	a
	sla	a
	sla	a
	or	d					; OR bits from D (LSB) and shifted digit
	ld	d, a					; Save combined digit
	dec	c					; Decrement digit count
input_hex16_complete_check_remainder:
	djnz	input_hex16_complete_loop		; Keep looping until all digits moved
input_hex16_complete_end:
	scf						; Set Carry flag
	ret

; # Memory routines
; ###########################################################################
; # memory_copy
; #################################
;  Copies a region of memory to another region
;	In:	BC -> Source Address
;		DE -> Destination Address
;		HL -> Num. bytes
memory_copy:
	ld	a, (bc)					; Get byte to copy
	ld	(de), a					; Save byte
	inc	bc					; Increment pointers
	inc	de
	dec	hl					; Decrement byte count
	ld	a, l
	or	h					; See if we've reached zero
	jr	nz, memory_copy				; If there are remaining bytes to copy
	ret

; # Module routines
; ###########################################################################
; # module_find
; #################################
;  Finds the next header in the external memory. (Has to be able to work without stack)
;  	In:	HL = point to start of search (only MSB used)
;		DE = point to end of search
;		IX = Return address
;  	Out:	BC = location of next module
;		A = module type, or unset if no module found
;		Carry flag is set on success, Carry flag is unset on failure
module_find:
	ld	l, 0x0					; Make sure we are on a boundary
	ld	b, h					; Copy HL -> BC
	ld	c, l

	ld	a, 0xA5					; First identity byte
	cp	(hl)					; Compare memory
	jr	nz, module_find_next			; Not equal, so check next range
	inc	hl					; Increment pointer
	ld	a, 0xE5					; Second identity byte
	cp	(hl)					; Compare memory
	jr	nz, module_find_next			; Not equal, so check next range
	inc	hl					; Increment pointer
	ld	a, 0xE0					; Third identity byte
	cp	(hl)					; Compare memory
	jr	nz, module_find_next			; Not equal, so check next range
	inc	hl					; Increment pointer
	ld	a, 0xA5					; Fourth identity byte
	cp	(hl)					; Compare memory
	jr	nz, module_find_next			; Not equal, so check next range
	inc	hl					; Increment pointer
	ld	a, (hl)					; Get module type
	scf						; Set Carry flag
	jp	(ix)					; Resume execution from where we left off
module_find_next:
	ld	a, d					; Get end address MSB
	cp	h					; Compare to current address
	jr	z, module_find_end			; Were at the end so finish
	inc	h					; Increment MSB of pointer
	jr	module_find				; Repeat search
module_find_end:
	xor	a					; Clear A to indicate no module
	scf						; Clear Carry flag
	ccf
	jp	(ix)					; Resume execution from where we left off

; # module_search
; #################################
;  Finds the next header in the external memory.
;	In:	A = Module type to search for
;		HL = Address to start searching from
;	Out:	HL = location of next module
;		Carry flag is set on success, Carry flag is unset on failure
module_search:
	ld	de, mem_srch_end			; Set search end
	inc	d					; Increment search end address (so as to search up to and including)
	ld	ix, module_search_reenter		; Set return address
	ex	af, af'					; Swap out module type
module_search_next:
	ld	a, d					; Copy end search pointer MSB for compare
	cp	h					; Check whether we are at the end of the search space
	jr	z, module_search_failed			; We've reached the end, so we've failed to find a module
	jr	module_find
module_search_reenter:
	jr	nc, module_search_failed		; No module, exit
	ld	h, b					; Copy BC -> HL
	ld	l, c
	ld	b, a					; Copy module type
	ex	af, af'					; Swap in module type
	cp	b					; Check module type
	jr	z, module_search_end			; If they're the same, return
	ex	af, af'					; Swap out module type
	inc	h					; Increment pointer MSB
	jr	module_search_next			; Continue search
module_search_end:
	scf						; Set Carry flag
	ret
module_search_failed:
	scf
	ccf						; Clear Carry flag
	ret

; # module_list_commands
; #################################
;  Print a list of additional commands
module_list_commands:
	ld	hl, str_prompt9
	call	print_cstr
	ld	b, 21
	call	print_spaces_n
	;ld	hl, str_prompt9b
	call	print_cstr

	ld	hl, mem_srch_start			; Set search start
	ld	de, mem_srch_end			; Set search end
module_list_commands_next:
	ld	ix, module_list_commands_reenter	; Set return address
	jr	module_find
module_list_commands_reenter:
	cp	0x00					; Check if we have a module
	jr	z, module_list_commands_exit		; If not, return
	ld	h, b					; Copy BC -> HL
	;ld	l, c					; Don't actually need C as it's overwritten
	push	de					; Save search end
	push	bc					; Save module pointer (Restored as HL)

	call	print_spacex2
	ld	l, 0x20					; Offset to command name
	call	print_str				; Print command name
	ld	l, 0x20					; Reset offset
	call	string_length				; Get command name length
	ld	l, 0x0					; Reset offset
	ld	a, 33					; Calculate padding
	sub	c
	ld	b, a
	call	print_spaces_n				; Print padding
	ld	b, h
	ld	c, l
	call	print_hex16				; Print command address
	ld	b, 0x06
	call	print_spaces_n				; Print padding
	ld	l, 0x04					; Offset to command type
	ld	a, (hl)					; Get command type

	ld	hl, str_type5				; Type unknown
module_list_commands_type_35:
	cp	35					; Program
	jr	nz, module_list_commands_type_249
	ld	hl, str_type2
	jr	module_list_commands_type_print
module_list_commands_type_249:
	cp	249					; Init
	jr	nz, module_list_commands_type_253
	ld	hl, str_type3
	jr	module_list_commands_type_print
module_list_commands_type_253:
	cp	253					; Startup command
	jr	nz, module_list_commands_type_254
	ld	hl, str_type4
	jr	module_list_commands_type_print
module_list_commands_type_254:
	cp	254					; External command
	jr	nz, module_list_commands_type_print
	ld	hl, str_type1
module_list_commands_type_print:
	call	print_cstr				; Print type
	call	print_newline

	pop	hl					; Restore module pointer
	pop	de					; Restore search end
	ld	a, d					; Copy end search pointer MSB for compare
	cp	h					; Check whether we are at the end of the search space
	jr	z, module_list_commands_exit		; We've reached the end, so no more modules
	inc	h					; Increment pointer MSB
	jr	module_list_commands_next		; Continue search
module_list_commands_exit:
	jp	print_newline				; Finish

; # Main routines
; ###########################################################################

; # command_help_line_print
; #################################
;  Prints a line of help text
;	In:	B = Command key
;		HL = Command help string
command_help_line_print:
	call	print_spacex2
	ld	a, b
	call	monlib_console_out
	call	print_dash_spaces
	call	print_cstr
	jp	print_newline

; # command_help
; #################################
;  Prints help text
command_help:
command_help_internal_commands:
	ld	hl, str_help1
	call	print_cstr

	ld	b, command_key_help
	ld	hl, str_tag_help1
	call	command_help_line_print
	ld	b, command_key_listm
	;ld	hl, str_tag_listm
	call	command_help_line_print
	ld	b, command_key_run
	;ld	hl, str_tag_run
	call	command_help_line_print
	ld	b, command_key_download
	;ld	hl, str_tag_dnld
	call	command_help_line_print
	ld	b, command_key_upload
	;ld	hl, str_tag_upld
	call	command_help_line_print
	ld	b, command_key_new_locat
	;ld	hl, str_tag_nloc
	call	command_help_line_print
	ld	b, command_key_jump
	;ld	hl, str_tag_jump
	call	command_help_line_print
	ld	b, command_key_hexdump
	;ld	hl, str_tag_hexdump
	call	command_help_line_print
	ld	b, command_key_regdump
	;ld	hl, str_tag_regdump
	call	command_help_line_print
	ld	b, command_key_clrmem
	;ld	hl, str_tag_clrm
	call	command_help_line_print

command_help_external_commands:
	ld	hl, str_help2
	call	print_cstr
	ld	hl, mem_srch_start			; Set search start
command_help_external_commands_loop:
	ld	a, 0xfe					; Search for external command
	call	module_search
	jr	nc, command_help_end			; No command found so finish
	call	print_spacex2
	ld	l, 0x05					; Offset to module command character
	ld	a, (hl)					; Get module command character
	call	monlib_console_out			; Print character
	call	print_dash_spaces
	ld	l, 0x20					; Offset to module name
	call	print_str				; Print module name
	call	print_newline
	inc	h					; Increment module search start address
	jr	command_help_external_commands_loop	; Loop around again

command_help_end:
	jp	print_newline				; Print newline and return

; # command_location_new
; #################################
;  Sets the monitor pointer to where default operations are performed
command_location_new:
	ld	hl, str_prompt6				; Print location prompt
	call	print_cstr
	call	input_hex16				; Get value
	jp	nc, print_abort				; If escaped, print abort message
	ld	(z80mon_default_addr), de		; Save value
	jp	print_newline

; # command_jump
; #################################
;  Request an address, and jump to the code at that location
command_jump:
	ld	hl, str_prompt8
	call	print_cstr
	ld	hl, str_prompt4
	call	print_cstr
	ld	bc, (z80mon_default_addr)
	call	input_hex16_preloaded
	jr	c, command_jump_prep
	jp	print_abort
command_jump_prep:
	push	de
	ld	hl, str_runs
	call	print_cstr
	pop	hl
	ld	b, h					; Copy HL->BC
	ld	c, l
	call	print_hex16
	call	print_newline

	ld	bc, 0x0010				; Reset address (RST 16: z80Mon final startup)
	push	bc					; Push reset address on stack
	push	bc					; In case there's a RET at the end of the code
command_jump_brkpnt:
	jp	(hl)					; Execute startup module


; # command_hexdump
; #################################
;  Dump memory at the default location
command_hexdump:
	ld	hl, (z80mon_default_addr)
	ld	de, 0x0600

	call	print_newline
command_hexdump_line_print:
	ld	e, 0x08					; Number of bytes per line
	call	print_spacex2
	ld	b, h					; Copy HL->BC
	ld	c, l
	call	print_hex16
	call	print_colon_space
command_hexdump_line_print_loop:
	ld	a, (hl)
	call	print_hex8
	inc	hl
	ld	a, (hl)
	call	print_hex8
	inc	hl
	call	print_spacex2
	dec	e					; Decrement line byte count
	jr	nz, command_hexdump_line_print_loop
	call	print_newline
	dec	d					; Decrement line count
	jr	nz, command_hexdump_line_print

	ret

; # menu_main
; #################################
;  Implements interactive menu
menu_main:
	; First we print out the prompt, which isn't as simple
	; as it may seem, since external code can add to the
	; prompt, so we've got to find and execute all of 'em.
	ld	hl, str_prompt1				; First part of the prompt
	call	print_cstr
	ld	bc, (z80mon_default_addr)		; Get current address
	call	print_hex16
	;ld	hl, str_prompt2				; Second part of the prompt
	call	print_str

	call	input_character_filter			; Get character input

;	cp	':'					; Check for ':' from pushing a HEX file from a terminal
;	jr	nz, menu_main_push_address
;	call	dnld_now
;	jr	menu_main

menu_main_push_address:
	call	char_2_upper				; Convert to uppercase to simplify matching
	ld	bc, menu_main
	push	bc					; Push menu_main address to stack to make returning easier
	push	af					; Save command character

menu_main_external_commands:
	ld	hl, mem_srch_start			; Set search start
menu_main_external_commands_loop:
	ld	a, 0xfe					; Search for startup application
	call	module_search
	jr	nc, menu_main_builtin_commands		; No command found so procede with builtin commands
	pop	bc					; Restore command character
	ld	l, 0x05					; Offset to module command character
	ld	a, (hl)					; Get module command character
	cp	b					; Are they the same character?
	jr	z, menu_main_external_commands_exec	; Execute external command
	push	bc					; Store command character again
	inc	h					; Increment module search start address
	jr	menu_main_external_commands_loop	; Loop around again
menu_main_external_commands_exec:
	call	print_space
	ld	l, 0x20					; Offset to module command name
	call	print_str				; Print module command name
	call	print_newline
	ld	l, 0x40					; Offset to module code
	xor	a
	jp	(hl)

menu_main_builtin_commands:
	pop	af					; Restore command character
menu_main_builtin_help:
	cp	command_key_help			; Check if help key
	jr	nz, menu_main_builtin_list_modules	; If not, next command
	ld	hl, str_tag_help2
	call	print_cstr				; Print message
	jp	command_help				; Run command
menu_main_builtin_list_modules:
	cp	command_key_listm			; Check if list modules key
	jr	nz, menu_main_builtin_dump_registers	; If not, next command
	ld	hl, str_tag_listm
	call	print_cstr				; Print message
	jp	module_list_commands			; Run command
menu_main_builtin_dump_registers:
	cp	command_key_regdump			; Check if dump registers key
	jr	nz, menu_main_builtin_location_new	; If not, next command
	ld	hl, str_tag_regdump
	call	print_cstr				; Print message
	jp	print_registers				; Run command
menu_main_builtin_location_new:
	cp	command_key_new_locat			; Check if new location key
	jr	nz, menu_main_builtin_jump		; If not, next command
	ld	hl, str_tag_nloc
	call	print_cstr				; Print message
	jp	command_location_new			; Run command
menu_main_builtin_jump:
	cp	command_key_jump			; Check if jump key
	jr	nz, menu_main_builtin_hexdump		; If not, next command
	ld	hl, str_tag_jump
	call	print_cstr				; Print message
	jp	command_jump				; Run command
menu_main_builtin_hexdump:
	cp	command_key_hexdump			; Check if hexdump key
	jr	nz, menu_main_builtin_run		; If not, next command
	ld	hl, str_tag_hexdump
	call	print_cstr				; Print message
	jp	command_hexdump				; Run command

menu_main_builtin_run:
;	cjne	a, #run_key, menu1e
;	mov	dptr, #run_cmd
;	acall	pcstr_h
;	ajmp	run

;menu1e:
;	cjne	a, #dnld_key, menu1f
;	mov	dptr, #dnld_cmd
;	acall	pcstr_h
;	ajmp	dnld
;menu1f:
;	cjne	a, #upld_key, menu1g
;	mov	dptr, #upld_cmd
;	acall	pcstr_h
;	ajmp	upld
;menu1g:
;;	 cjne	a, #edit_key, menu1k
;;	mov	dptr, #edit_cmd
;;	acall	pcstr_h
;;	ajmp	edit
;menu1k:
;	cjne	a, #clrm_key, menu1l
;	mov	dptr, #clrm_cmd
;	acall	pcstr_h
;	ajmp	clrm

;/////////////////////////////////////////////////////////////////////////////////////////////////
;        command_key_run:                equ     '@'             ; Run program
;        command_key_download:           equ     'D'             ; Download
;        command_key_upload:             equ     'U'             ; Upload
;        command_key_edit:               equ     'E'             ; Edit memory
;        command_key_clrmem:             equ     'C'             ; Clear memory
;/////////////////////////////////////////////////////////////////////////////////////////////////

menu_main_end:
	jp	print_newline				; This will return to menu_main

; # Startup routines
; ###########################################################################
; # startup_cold
; #################################
; This is the first section of code executed on startup before any
; hardware is initialised.
startup_cold:
	; Basic initialisation
	di						; Disable interrupts
	im	1					; Set interrupt mode 1
	ld	sp, 0x0					; Zero stack pointer

	; Search for an init module
	ld	hl, mem_srch_start			; Set search start
	ld	de, mem_srch_end			; Set search end
	ld	ix, startup_cold_search_rtn		; Set return address
startup_cold_search:
	jp	module_find
startup_cold_search_rtn:
	cp	0x00					; Check if we have a module
	jr	z, startup_cold_end			; If don't find a module, just continue boot
	ld	h, b					; Copy BC -> HL
	ld	l, c
	cp	249					; Check if it's an init module
	jr	nz, startup_cold_search_next		; It's not an init module, keep searching
	ld	sp, hl					; Load module base addess in to stack pointer (we can't load IX directly)
	ld	ix, 0x40				; Load offset in to IX
	add	ix, sp					; Create pointer to init module
	jp	(ix)					; Execute init module
startup_cold_search_next:
	inc	h					; Increment pointer MSB
	ld	a, d					; Copy end search pointer MSB for compare
	cp	h					; Check whether we are at the end of the search space
	jr	nz, startup_cold_search			; We're not at the end so keep searching

startup_cold_end:
	rst	8					; We've done basic system init so warm boot rest

; # startup_warm
; #################################
; This code is executed once basic system is initialised
; It's assumed that a stack is available at this point
startup_warm:
	ld	a, #253					; Search for startup application
	ld	hl, mem_srch_start			; Set search start
	call	module_search
	jr	nc, startup_warm_end			; No module found, so finish

	ld	de, 0x40				; Load offset to module code
	add	hl, de					; Create pointer to init module
	jp	(hl)					; Execute startup module

startup_warm_end:
	rst	16

; # startup_final
; #################################
;  Final section of startup, executes menu system
startup_final:
	call	print_newline
	ld	hl, str_logon1				; Print greeting
	call	print_cstr
	;ld	hl, str_logon2				; Print documentation notes
	;call	print_cstr

	call	module_list_commands			; Print included commands

	jp	menu_main				; Enter main menu

; # stop_loop
; #################################
;  Emulator function, halt doesn't work
stop_loop:
	jr	stop_loop
	halt						; Doesn't work on emulator

; # Fixed data structures
; ###########################################################################

; # Dictionary of common words
; #################################
;  This is the dictionary of 128 words used by print_cstr.
; 0 - to		32 - abort		64 - internal		 96 - support
; 1 - location		33 - you		65 - complete		 97 - write
; 2 - program		34 - the		66 - an			 98 - up
; 3 - memory		35 - is			67 - header		 99 - stack
; 4 - hex		36 - and		68 - register		100 - press
; 5 - unexpected	37 - interrupt		69 - must		101 - see
; 6 - run		38 - in			70 - line		102 - reset
; 7 - new		39 - be			71 - found		103 - pointer
; 8 - jump		40 - with		72 - quit		104 - fixed
; 9 - file		41 - as			73 - type		105 - detection
;10 - download		42 - code		74 - which		106 - may
;11 - bytes		43 - will		75 - erase		107 - has
;12 - esc		44 - from		76 - step		108 - assemble
;13 - information	45 - that		77 - provide		109 - clear
;14 - this		46 - at			78 - so			110 - configure
;15 - start		47 - used		79 - single		111 - data
;16 - rom		48 - if			80 - should		112 - change
;17 - receive		49 - by			81 - list		113 - allow
;18 - ram		50 - value		82 - search		114 - written
;19 - upload		51 - not		83 - eprom		115 - interface
;20 - paulmon		52 - for		84 - next		116 - install
;21 - or		53 - baud		85 - more		117 - checksum
;22 - of		54 - when		86 - available		118 - instruction
;23 - no		55 - rate		87 - help		119 - unchanged
;24 - intel		56 - can		88 - edit		120 - paul
;25 - flash		57 - are		89 - well		121 - transfer
;26 - external		58 - use		90 - user		122 - time
;27 - errors		59 - serial		91 - dump		123 - any
;28 - editing		60 - auto		92 - delays		124 - skip
;29 - digits		61 - port		93 - these		125 - name
;30 - command		62 - all		94 - terminal		126 - stoffregen
;31 - begin		63 - make		95 - system		127 - print
common_words:
	db	0x82, 0x90, 0xE8, 0x23, 0x86, 0x05, 0x4C, 0xF8
	db	0x44, 0xB3, 0xB0, 0xB1, 0x48, 0x5F, 0xF0, 0x11
	db	0x7F, 0xA0, 0x15, 0x7F, 0x1C, 0x2E, 0xD1, 0x40
	db	0x5A, 0x50, 0xF1, 0x03, 0xBF, 0xBA, 0x0C, 0x2F
	db	0x96, 0x01, 0x8D, 0x3F, 0x95, 0x38, 0x0D, 0x6F
	db	0x5F, 0x12, 0x07, 0x71, 0x0E, 0x56, 0x2F, 0x48
	db	0x3B, 0x62, 0x58, 0x20, 0x1F, 0x76, 0x70, 0x32
	db	0x24, 0x40, 0xB8, 0x40, 0xE1, 0x61, 0x8F, 0x01
	db	0x34, 0x0B, 0xCA, 0x89, 0xD3, 0xC0, 0xA3, 0xB9
	db	0x58, 0x80, 0x04, 0xF8, 0x02, 0x85, 0x60, 0x25
	db	0x91, 0xF0, 0x92, 0x73, 0x1F, 0x10, 0x7F, 0x12
	db	0x54, 0x93, 0x10, 0x44, 0x48, 0x07, 0xD1, 0x26
	db	0x56, 0x4F, 0xD0, 0xF6, 0x64, 0x72, 0xE0, 0xB8
	db	0x3B, 0xD5, 0xF0, 0x16, 0x4F, 0x56, 0x30, 0x6F
	db	0x48, 0x02, 0x5F, 0xA8, 0x20, 0x1F, 0x01, 0x76
	db	0x30, 0xD5, 0x60, 0x25, 0x41, 0xA4, 0x2C, 0x60
	db	0x05, 0x6F, 0x01, 0x3F, 0x26, 0x1F, 0x30, 0x07
	db	0x8E, 0x1D, 0xF0, 0x63, 0x99, 0xF0, 0x42, 0xB8
	db	0x20, 0x1F, 0x23, 0x30, 0x02, 0x7A, 0xD1, 0x60
	db	0x2F, 0xF0, 0xF6, 0x05, 0x8F, 0x93, 0x1A, 0x50
	db	0x28, 0xF0, 0x82, 0x04, 0x6F, 0xA3, 0x0D, 0x3F
	db	0x1F, 0x51, 0x40, 0x23, 0x01, 0x3E, 0x05, 0x43
	db	0x01, 0x7A, 0x01, 0x17, 0x64, 0x93, 0x30, 0x2A
	db	0x08, 0x8C, 0x24, 0x30, 0x99, 0xB0, 0xF3, 0x19
	db	0x60, 0x25, 0x41, 0x35, 0x09, 0x8E, 0xCB, 0x19
	db	0x12, 0x30, 0x05, 0x1F, 0x31, 0x1D, 0x04, 0x14
	db	0x4F, 0x76, 0x12, 0x04, 0xAB, 0x27, 0x90, 0x56
	db	0x01, 0x2F, 0xA8, 0xD5, 0xF0, 0xAA, 0x26, 0x20
	db	0x5F, 0x1C, 0xF0, 0xF3, 0x61, 0xFE, 0x01, 0x41
	db	0x73, 0x01, 0x27, 0xC1, 0xC0, 0x84, 0x8F, 0xD6
	db	0x01, 0x87, 0x70, 0x56, 0x4F, 0x19, 0x70, 0x1F
	db	0xA8, 0xD9, 0x90, 0x76, 0x02, 0x17, 0x43, 0xFE
	db	0x01, 0xC1, 0x84, 0x0B, 0x15, 0x7F, 0x02, 0x8B
	db	0x14, 0x30, 0x8F, 0x63, 0x39, 0x6F, 0x19, 0xF0
	db	0x11, 0xC9, 0x10, 0x6D, 0x02, 0x3F, 0x91, 0x09
	db	0x7A, 0x41, 0xD0, 0xBA, 0x0C, 0x1D, 0x39, 0x5F
	db	0x07, 0xF2, 0x11, 0x17, 0x20, 0x41, 0x6B, 0x35
	db	0x09, 0xF7, 0x75, 0x12, 0x0B, 0xA7, 0xCC, 0x48
	db	0x02, 0x3F, 0x64, 0x12, 0xA0, 0x0C, 0x27, 0xE3
	db	0x9F, 0xC0, 0x14, 0x77, 0x70, 0x11, 0x40, 0x71
	db	0x21, 0xC0, 0x68, 0x25, 0x41, 0xF0, 0x62, 0x7F
	db	0xD1, 0xD0, 0x21, 0xE1, 0x62, 0x58, 0xB0, 0xF3
	db	0x05, 0x1F, 0x73, 0x30, 0x77, 0xB1, 0x6F, 0x19
	db	0xE0, 0x19, 0x43, 0xE0, 0x58, 0x2F, 0xF6, 0xA4
	db	0x14, 0xD0, 0x23, 0x03, 0xFE, 0x31, 0xF5, 0x14
	db	0x30, 0x99, 0xF8, 0x03, 0x3F, 0x64, 0x22, 0x51
	db	0x60, 0x25, 0x41, 0x2F, 0xE3, 0x01, 0x56, 0x27
	db	0x93, 0x09, 0xFE, 0x11, 0xFE, 0x79, 0xBA, 0x60
	db	0x75, 0x42, 0xEA, 0x62, 0x58, 0xA0, 0xE5, 0x1F
	db	0x53, 0x4F, 0xD1, 0xC0, 0xA3, 0x09, 0x42, 0x53
	db	0xF7, 0x12, 0x04, 0x62, 0x1B, 0x30, 0xF5, 0x05
	db	0xF7, 0x69, 0x0C, 0x35, 0x1B, 0x70, 0x82, 0x2F
	db	0x2F, 0x14, 0x4F, 0x51, 0xC0, 0x64, 0x25, 0x00

; # List of strings
; #################################
; Strings used to dump register contents
str_reg_af1:		db	" AF =&",0
str_reg_af2:		db	" AF'=&",0
str_reg_bc1:		db	" BC =&",0
str_reg_bc2:		db	" BC'=&",0
str_reg_de1:		db	" DE =&",0
str_reg_de2:		db	" DE'=&",0
str_reg_hl1:		db	" HL =&",0
str_reg_hl2:		db	" HL'=&",0
str_reg_ix:		db	" IX =&",0
str_reg_iy:		db	" IY =&",0
str_reg_sp:		db	" SP =&",0
str_reg_sra:		db	" SRA =&",0

;str_logon1:		db	"Welcome",128," z80Mon v0.1",13,14			; Welcome string (OLD)
str_logon1:		db	"Welcome",128," z80Mon v0.1",14				; Welcome string
str_logon2:	 	db	32,32,"See",148,"2.DOC,",148,"2.EQU",164
			db	148,"2.HDR",180,213,141,".",14				; Documentation string

;str_prompt1:		db	148,"2 Loc:",0						; Paulmon2 Loc: (OLD)
str_prompt1:		db	"z80Mon:",0						; z80Mon:
str_prompt2:		db	" >", 160						;  > abort run which program(	(must follow after prompt1)
str_prompt3:		db	134,202,130,'(',0					; run which program(
;str_prompt4:		db	"),",149,140,128,200,": ",0				; ), or esc to quit: (OLD)
str_prompt4:		db	",",149,31,140,": ",0					; , or press escape:
str_prompt5:		db	31,151,130,195,"s",199,166,131,","
			db	186," JUMP",128,134,161,"r",130,13,14			; No program headers found in memory, use JUMP to run your program
str_prompt6:		db	13,13,31,135,131,129,": ",0				; \n\nNew memory location:
str_prompt7:		db	31,228,251," key: ",0					; Press any key:
;str_prompt8:		db	13,13,31,136,128,131,129," (",0				; \n\nJump to memory location ( (OLD)
str_prompt8:		db	13,13,31,136,128,131,129,0				; \n\nJump to memory location
;str_prompt9:		db	13,13,31,130,31,253,0					; \n\nProgram Name (OLD)
str_prompt9:		db	13,31,130,31,253,0					; \nProgram Name
str_prompt9b:		db	31,129,32,32,32,32,32,31,201,14				; Location      Type	 (must follow prompt9)
str_prompt10:		db	") ",31,135,31,178,": ",0				; ) New Value:
str_type1:		db	31,154,158,0						; External command
str_type2:		db	31,130,0						; Program
str_type3:		db	"Init",0						; Init
str_type4:		db	31,143,31,226,31,170,0					; Start Up Code
str_type5:		db	"???",0							; ???

str_tag_help2:		db	31,215,0						; Help
str_tag_help1: 		db	31,142,215,209,0					; This help list (these 11 _cmd string must be in order)
str_tag_listm:  	db	31,209,130,"s",0					; List Programs
str_tag_run:  		db	31,134,130,0						; Run Program
str_tag_dnld: 		db	31,138,0						; Download
str_tag_upld: 		db	31,147,0						; Upload
str_tag_nloc: 		db	31,135,129,0						; New Location
str_tag_jump: 		db	31,136,128,131,129,0					; Jump to memory location
;str_tag_dump: 		db	31,132,219,154,131,0					; Hex dump external memory (OLD)
str_tag_hexdump: 	db	31,132,219,131,0					; Hex dump memory
str_tag_regdump: 	db	31,219,31,196,"s",0					; Dump Registers
;str_tag_edit: 		db	31,156,154,146,0					; Editing external ram
str_tag_clrm: 		db	31,237,131,0						; Clear memory

str_help1:		db	13,13,"Standard",31,158,"s",14				; \n\nStandard Commands
str_help2:		db	31,218,31,244,"ed",31,158,"s",14			; User Installed Commands
;str_abort:		db	" ",31,158,31,160,"!",13,14				;  Command Abort!\n\n
str_abort:		db	" ",31,158,31,160,"!",14				;  Command Abort!\n
;str_runs:		db	13,134,"ning",130,":",13,14				; \nRunning program:\n\n
str_runs:		db	13,134,"ning",130," @",0				; \nRunning program @

beg_str:		db	"First",31,129,": ",0
end_str:		db	"Last",31,129,":",32,32,0
sure:			db	31,185,161," sure?",0
edits1: 		db	13,13,31,156,154,146,",",140,128,200,14
edits2: 		db	"  ",31,156,193,",",142,129,247,13,14
dnlds1: 		db	13,13,31,159," ascii",249,150,31,152,132,137
			db	",",149,140,128,160,13,14
dnlds2: 		db	13,31,138,160,"ed",13,14
dnlds3: 		db	13,31,138,193,"d",13,14
dnlds4: 		db	"Summary:",14
dnlds5: 		db	" ",198,"s",145,"d",14
dnlds6a:		db	" ",139,145,"d",14
dnlds6b:		db	" ",139," written",14
dnlds7: 		db	31,155,":",14
dnlds8: 		db	" ",139," unable",128," write",14
dnlds9: 		db	32,32,"bad",245,"s",14
dnlds10:		db	" ",133,159,150,198,14
dnlds11:		db	" ",133,132,157,14
dnlds12:		db	" ",133," non",132,157,14
dnlds13:		db	31,151,155," detected",13,14
uplds3: 		db	13,13,"Sending",31,152,132,137,172,32,32,0
uplds4: 		db	" ",128,32,32,0		;must follow uplds3
erfr_cmd: 		db	31,203,153,144,0
erfr_ok:  		db	31,153,144,203,'d',13,14
erfr_err: 		db	31,133,155,13,14

; ##########################################################################################################################################
; ##########################################################################################################################################
; ##########################################################################################################################################
;; These three parameters tell PAULMON2 where the user's memory is
;; installed.  "bmem" and "emem" define the space that will be searched
;; for program headers, user installed commands, start-up programs, etc.
;; "bmem" and "emem" should be use so they exclude memory areas where
;; perphreal devices may be mapped, as reading memory from an io chip
;; may reconfigure it unexpectedly.  If flash rom is used, "bmem" and "emem"
;; should also include the space where the flash rom is mapped.
;
;.equ	pgm, 0x8000+base			; default location for the user program
;.equ	bmem, 0x1000+base			; where is the beginning of memory
;.equ	emem, 0xFFFF+base			; end of the memory
;
;;---------------------------------------------------------;
;;							  ;
;;	                OsyterLib			  ;
;;							  ;
;;---------------------------------------------------------;
;.equ	oysterlib_base,  0x1000+base
;.equ	oysterlib_locat, 0x80+oysterlib_base
;.equ	oysterlib_cout, 0x00+oysterlib_locat
;.equ	oysterlib_newline, 0x03+oysterlib_locat
;.equ	oysterlib_cin, 0x06+oysterlib_locat
;.flag   use_oysterlib, 0x20.0
;
;; To set the baud rate, use this formula or set to 0 for auto detection
;; baud_const = 256 - (crystal / (12 * 16 * baud))
;
;.equ	baud_const, 0				; automatic baud rate detection
;;.equ	baud_const, 255				; 57600 baud w/ 11.0592 MHz
;;.equ	baud_const, 253				; 19200 baud w/ 11.0592 MHz
;;.equ	baud_const, 252				; 19200 baud w/ 14.7456 MHz
;;.equ	baud_const, 243				; 4808 baud w/ 12 MHz
;
;.equ	line_delay, 6				; num of char times to pause during uploads
;
;; About download speed: when writing to ram, PAULMON2 can accept data
;; at the maximum baud rate (baud_const=255 or 57600 baud w/ 11.0592 MHz).
;; Most terminal emulation programs introduce intentional delays when
;; sending ascii data, which you would want to turn off for downloading
;; larger programs into ram.  For Flash ROM, the maximum speed is set by
;; the time it takes to program each location... 9600 baud seems to work
;; nicely for the AMD 28F256 chip.  The "character pacing" delay in a
;; terminal emulation program should be sufficient to download to flash
;; rom and any baud rate.  Some flash rom chips can write very quickly,
;; allowing high speed baud rates, but other chips can not.  You milage
;; will vary...
;
;; These symbols configure paulmon2's internal memory usage.
;; It is usually not a good idea to change these unless you
;; know that you really have to.
;
;.equ	psw_init, 0				; value for psw (which reg bank to use)
;.equ	dnld_parm, 0x10				; block of 16 bytes for download
;;.equ	stack, 0x30				; location of the stack
;.equ	stack, 0x70				; location of the stack
;.equ	baud_save, 0x68				; save baud for warm boot, 4 bytes
;
;;---------------------------------------------------------;
;;							  ;
;;		     Interrupt Vectors			  ;
;;  (and little bits of code crammed in the empty spaces)  ;
;;							  ;
;;---------------------------------------------------------;
;
;.org	base
;
;r6r7todptr:
;	mov	dpl, r6
;	mov	dph, r7
;	ret
;
;dptrtor6r7:
;	mov	r6, dpl
;	mov	r7, dph
;	ret
;
;
;esc:  ;checks to see if <ESC> is waiting on serial port
;      ;C=clear if no <ESC>, C=set if <ESC> pressed
;      ;buffer is flushed
;	push	acc
;	clr	c
;	jnb	ri,esc2
;	mov	a,sbuf
;	cjne	a,#27,esc1
;	setb	c
;esc1:	clr	ri
;esc2:	pop	acc
;	ret
;
;
;;---------------------------------------------------------;
;;							  ;
;;    The 'high-level' stuff to interact with the user	  ;
;;							  ;
;;---------------------------------------------------------;
;
;
;;..........................................................
;
;;---------------------------------------------------------;
;
;;dnlds1 = "Begin sending Intel HEX format file <ESC> to abort"
;;dnlds2 = "Download aborted"
;;dnlds3 = "Download completed"
;
;
;;16 byte parameter table: (eight 16 bit values)
;;  *   0 = lines received
;;  *   1 = bytes received
;;  *   2 = bytes written
;;  *   3 = bytes unable to write
;;  *   4 = incorrect checksums
;;  *   5 = unexpected begin of line
;;  *   6 = unexpected hex digits (while waiting for bol)
;;  *   7 = unexpected non-hex digits (in middle of a line)
;
;
;
;dnld:
;	mov	dptr, #dnlds1		 
;	acall	pcstr_h		   ;"begin sending file <ESC> to abort"
;	acall	dnld_init
;
;	  ;look for begining of line marker ':'
;dnld1:	acall	cin
;	cjne	a, #27, dnld2	;Test for escape
;	sjmp	dnld_esc
;
;dnld2:	cjne	a, #':', dnld2b
;	sjmp	dnld2d
;dnld2b:	  ;check to see if it's a hex digit, error if it is
;	acall	asc2hex
;	jc	dnld1
;	mov	r1, #6
;	acall	dnld_inc
;	sjmp	dnld1
;
;dnld_now: ;entry point for main menu detecting ":" character
;	mov	a, #'^'
;	acall	cout
;	acall	dnld_init
;
;dnld2d:	mov	r1, #0
;	acall	dnld_inc
;
;	  ;begin taking in the line of data
;dnld3:	;mov	a, #'.'
;	;acall	cout
;	mov	r4, #0		;r4 will count up checksum
;	acall	dnld_ghex
;	mov	r0, a		;R0 = # of data bytes
;	mov	a, #'.'
;	acall	cout
;	acall	dnld_ghex
;	mov	dph, a		;High byte of load address
;	acall	dnld_ghex
;	mov	dpl, a		;Low byte of load address
;	acall	dnld_ghex	;Record type
;	cjne	a, #1, dnld4	;End record?
;	sjmp	dnld_end
;dnld4:	jnz	dnld_unknown	;is it a unknown record type???
;dnld5:	mov	a, r0
;	jz	dnld_get_cksum
;	acall	dnld_ghex	;Get data byte
;	mov	r2, a
;	mov	r1, #1
;	acall	dnld_inc	;count total data bytes received
;	mov	a, r2
;	lcall	smart_wr	;c=1 if an error writing
;	clr	a
;	addc	a, #2
;	mov	r1, a
;;     2 = bytes written
;;     3 = bytes unable to write
;	acall	dnld_inc
;	inc	dptr
;	djnz	r0, dnld5
;dnld_get_cksum:
;	acall	dnld_ghex	;get checksum
;	mov	a, r4
;	jz	dnld1		;should always add to zero
;dnld_sumerr:
;	mov	r1, #4
;	acall	dnld_inc	;all we can do it count # of cksum errors
;	sjmp	dnld1
;
;dnld_unknown:	;handle unknown line type
;	mov	a, r0
;	jz	dnld_get_cksum	;skip data if size is zero
;dnld_ukn2:
;	acall	dnld_ghex	;consume all of unknown data
;	djnz	r0, dnld_ukn2
;	sjmp	dnld_get_cksum
;
;dnld_end:   ;handles the proper end-of-download marker
;	mov	a, r0
;	jz	dnld_end_3	;should usually be zero
;dnld_end_2:
;	acall	dnld_ghex	;consume all of useless data
;	djnz	r0, dnld_ukn2
;dnld_end_3:
;	acall	dnld_ghex	;get the last checksum
;	mov	a, r4
;	jnz	dnld_sumerr
;	acall	dnld_dly
;	mov	dptr, #dnlds3
;	acall	pcstr_h		   ;"download went ok..."
;	;consume any cr or lf character that may have been
;	;on the end of the last line
;	jnb	ri, dnld_sum
;	acall	cin
;	sjmp	dnld_sum
;
;
;
;dnld_esc:   ;handle esc received in the download stream
;	acall	dnld_dly
;	mov	dptr, #dnlds2	 
;	acall	pcstr_h		   ;"download aborted."
;	sjmp	dnld_sum
;
;dnld_dly:   ;a short delay since most terminal emulation programs
;	    ;won't be ready to receive anything immediately after
;	    ;they've transmitted a file... even on a fast Pentium(tm)
;	    ;machine with 16550 uarts!
;	mov	r0, #0
;dnlddly2:mov	r1, #0
;	djnz	r1, *		;roughly 128k cycles, appox 0.1 sec
;	djnz	r0, dnlddly2
;	ret
;
;dnld_inc:     ;increment parameter specified by R1
;	      ;note, values in Acc and R1 are destroyed
;	mov	a, r1
;	anl	a, #00000111b	;just in case
;	rl	a
;	add	a, #dnld_parm
;	mov	r1, a		;now r1 points to lsb
;	inc	@r1
;	mov	a, @r1
;	jnz	dnldin2
;	inc	r1
;	inc	@r1
;dnldin2:ret
;
;dnld_gp:     ;get parameter, and inc to next one (@r1)
;	     ;carry clear if parameter is zero.
;	     ;16 bit value returned in dptr
;	setb	c
;	mov	dpl, @r1
;	inc	r1
;	mov	dph, @r1
;	inc	r1
;	mov	a, dpl
;	jnz	dnldgp2
;	mov	a, dph
;	jnz	dnldgp2
;	clr	c
;dnldgp2:ret
;
;
;
;;a spacial version of ghex just for the download.  Does not
;;look for carriage return or backspace.	 Handles ESC key by
;;poping the return address (I know, nasty, but it saves many
;;bytes of code in this 4k ROM) and then jumps to the esc
;;key handling.	This ghex doesn't echo characters, and if it
;;sees ':', it pops the return and jumps to an error handler
;;for ':' in the middle of a line.  Non-hex digits also jump
;;to error handlers, depending on which digit.
;	  
;dnld_ghex:
;dnldgh1:acall	cin
;	acall	char_2_upper
;	cjne	a, #27, dnldgh3
;dnldgh2:pop	acc
;	pop	acc
;	sjmp	dnld_esc
;dnldgh3:cjne	a, #':', dnldgh5
;dnldgh4:mov	r1, #5		;handle unexpected beginning of line
;	acall	dnld_inc
;	pop	acc
;	pop	acc
;	ajmp	dnld3		;and now we're on a new line!
;dnldgh5:acall	asc2hex
;	jnc	dnldgh6
;	mov	r1, #7
;	acall	dnld_inc
;	sjmp	dnldgh1
;dnldgh6:mov	r2, a		;keep first digit in r2
;dnldgh7:acall	cin
;	acall	char_2_upper
;	cjne	a, #27, dnldgh8
;	sjmp	dnldgh2
;dnldgh8:cjne	a, #':', dnldgh9
;	sjmp	dnldgh4
;dnldgh9:acall	asc2hex
;	jnc	dnldghA
;	mov	r1, #7
;	acall	dnld_inc
;	sjmp	dnldgh7
;dnldghA:xch	a, r2
;	swap	a
;	orl	a, r2
;	mov	r2, a
;	add	a, r4		;add into checksum
;	mov	r4, a
;	mov	a, r2		;return value in acc
;	ret
;
;;dnlds4 =  "Summary:"
;;dnlds5 =  " lines received"
;;dnlds6a = " bytes received"
;;dnlds6b = " bytes written"
;
;dnld_sum:    ;print out download summary
;	mov	a, r6
;	push	acc
;	mov	a, r7
;	push	acc
;	mov	dptr, #dnlds4
;	acall	pcstr_h
;	mov	r1, #dnld_parm
;	mov	r6, #dnlds5 & 255
;	mov	r7, #dnlds5 >> 8
;	acall	dnld_i0
;	mov	r6, #dnlds6a & 255
;	mov	r7, #dnlds6a >> 8
;	acall	dnld_i0
;	mov	r6, #dnlds6b & 255
;	mov	r7, #dnlds6b >> 8
;	acall	dnld_i0
;
;dnld_err:    ;now print out error summary
;	mov	r2, #5
;dnlder2:acall	dnld_gp
;	jc	dnlder3		;any errors?
;	djnz	r2, dnlder2
;	 ;no errors, so we print the nice message
;	mov	dptr, #dnlds13
;	acall	pcstr_h
;	sjmp	dlnd_sum_done
;
;dnlder3:  ;there were errors, so now we print 'em
;	mov	dptr, #dnlds7
;	acall	pcstr_h
;	  ;but let's not be nasty... only print if necessary
;	mov	r1, #(dnld_parm+6)
;	mov	r6, #dnlds8 & 255
;	mov	r7, #dnlds8 >> 8
;	acall	dnld_item
;	mov	r6, #dnlds9 & 255
;	mov	r7, #dnlds9 >> 8
;	acall	dnld_item
;	mov	r6, #dnlds10 & 255
;	mov	r7, #dnlds10 >> 8
;	acall	dnld_item
;	mov	r6, #dnlds11 & 255
;	mov	r7, #dnlds11 >> 8
;	acall	dnld_item
;	mov	r6, #dnlds12 & 255
;	mov	r7, #dnlds12 >> 8
;	acall	dnld_item
;dlnd_sum_done:
;	pop	acc
;	mov	r7, a
;	pop	acc
;	mov	r6, a
;	ajmp	newline
;
;dnld_item:
;	acall	dnld_gp		;error conditions
;	jnc	dnld_i3
;dnld_i2:acall	space
;	lcall	pint16u
;	acall	r6r7todptr
;	acall	pcstr_h
;dnld_i3:ret
;
;dnld_i0:acall	dnld_gp		;non-error conditions
;	sjmp	dnld_i2
;
;
;dnld_init:
;	;init all dnld parms to zero.
;	mov	r0, #dnld_parm
;dnld0:	mov	@r0, #0
;	inc	r0
;	cjne	r0, #dnld_parm + 16, dnld0
;	ret
;
;
;;dnlds7:  = "Errors:"
;;dnlds8:  = " bytes unable to write"
;;dnlds9:  = " incorrect checksums"
;;dnlds10: = " unexpected begin of line"
;;dnlds11: = " unexpected hex digits"
;;dnlds12: = " unexpected non-hex digits"
;;dnlds13: = "No errors detected"
;
;
;;---------------------------------------------------------;
;
;;edit:	   					; edit external ram...
;;	mov	dptr, #edits1
;;	acall	pcstr_h
;;	acall	r6r7todptr
;;edit1:	acall	phex16
;;	mov	a,#':'
;;	acall	cout_sp
;;	mov	a,#'('
;;	acall	cout
;;	acall	dptrtor6r7
;;	clr	a
;;	movc	a, @a+dptr
;;	acall	phex
;;	mov	dptr,#prompt10
;;	acall	pcstr_h
;;	acall	ghex
;;	jb	psw.5,edit2
;;	jc	edit2
;;	acall	r6r7todptr
;;	lcall	smart_wr
;;	acall	newline
;;	acall	r6r7todptr
;;	inc	dptr
;;	acall	dptrtor6r7
;;	ajmp	edit1
;;edit2:	mov	dptr,#edits2
;;	ajmp	pcstr_h
;
;;---------------------------------------------------------;
;
;
;;---------------------------------------------------------;
;
;
;run:   
;	acall	newline2
;	mov	r2, #255	;first print the menu, count items
;	mov	dptr, #bmem
;	dec	dph
;run2:	inc	dph
;	mov	a, dph
;	cjne	a, #((emem+1) >> 8) & 255, run2b
;	sjmp	run3
;run2b:	acall	module_find
;	jnc	run3		;have we found 'em all??
;	mov	dpl, #4
;	clr	a
;	movc	a, @a+dptr
;	orl	a, #00000011b
;	cpl	a
;	jz	run2		;this one doesn't run... find next
;	acall	dspace
;	inc	r2
;	mov	a, #'A'		;print the key to press
;	add	a, r2
;	acall	cout_sp
;	acall	dash_sp
;	mov	dpl, #32
;	acall	pstr		;and the command name
;	acall	newline
;	ajmp	run2		;and continue doing this
;run3:	cjne	r2, #255, run4	;are there any to run??
;	mov	dptr, #prompt5
;	ajmp	pcstr_h
;run4:	mov	dptr, #prompt3	;ask the big question!
;	acall	pcstr_h
;	mov	a, #'A'
;	acall	cout
;	acall	dash
;	mov	a, #'A'		;such user friendliness...
;	add	a, r2		;even tell 'em the choices
;	acall	cout
;	mov	dptr, #prompt4
;	acall	pcstr_h
;	acall	input_character_filter_h
;	cjne	a, #27, run4aa	;they they hit <ESC>
;	ajmp	newline
;run4aa: mov	r3, a
;	mov	a, #31
;	clr	c
;	subb	a, r2
;	mov	a, r3
;	jc	run4a
;	acall	char_2_upper
;run4a:	acall	cout
;	mov	r3, a
;	acall	newline
;	;check to see if it's under 32, if so convert to uppercase
;	mov	a, r3
;	add	a, #(256 - 'A')
;	jnc	run4		;if they typed less than 'A'
;	mov	r3, a		;R3 has the number they typed
;	mov	a, r2		;A=R2 has the maximum number
;	clr	c
;	subb	a, r3
;	jc	run4		;if they typed over the max
;	inc	r3
;	mov	dptr, #bmem
;	dec	dph
;run5:	inc	dph
;	mov	a, dph
;	cjne	a, #((emem+1) >> 8) & 255, run5b
;	sjmp	run8
;run5b:	acall	module_find
;	jnc	run8		;Shouldn't ever do this jump!
;	mov	dpl, #4
;	clr	a
;	movc	a, @a+dptr
;	orl	a, #00000011b
;	cpl	a
;	jz	run5		;this one doesn't run... find next
;	djnz	r3, run5	;count til we find the one they want
;	acall	newline
;	mov	dpl, #64
;	ajmp	jump_doit
;run8:	ret
;
;;---------------------------------------------------------;
;
;
;;---------------------------------------------------------;
;
;upld:
;
;	acall	get_mem
;	;assume we've got the beginning address in r3/r2
;	;and the final address in r5/r4 (r4=lsb)...
;
;	;print out what we'll be doing
;	mov	dptr, #uplds3
;	acall	pcstr_h
;	mov	a, r3
;	acall	phex
;	mov	a, r2
;	acall	phex
;	;mov	 dptr, #uplds4
;	acall	pcstr_h
;	mov	a, r5
;	acall	phex
;	mov	a, r4
;	acall	phex
;	acall	newline
;
;	;need to adjust end location by 1...
;	mov	dph, r5
;	mov	dpl, r4
;	inc	dptr
;	mov	r4, dpl
;	mov	r5, dph
;
;	mov	dptr, #prompt7
;	acall	pcstr_h
;	acall	cin
;	cjne	a, #27, upld2e
;	ajmp	abort_it
;upld2e: acall	newline
;	mov	dpl, r2
;	mov	dph, r3
;
;upld3:	mov	a, r4		;how many more bytes to output??
;	clr	c
;	subb	a, dpl
;	mov	r2, a
;	mov	a, r5
;	subb	a, dph
;	jnz	upld4		;if >256 left, then do next 16
;	mov	a, r2
;	jz	upld7		;if we're all done
;	anl	a, #11110000b
;	jnz	upld4		;if >= 16 left, then do next 16
;	sjmp	upld5		;otherwise just finish it off
;upld4:	mov	r2, #16
;upld5:	mov	a, #':'		;begin the line
;	acall	cout
;	mov	a, r2
;	acall	phex		;output # of data bytes
;	acall	phex16		;output memory location
;	mov	a, dph
;	add	a, dpl
;	add	a, r2
;	mov	r3, a		;r3 will become checksum
;	clr	a
;	acall	phex		;output 00 code for data
;upld6:	clr	a
;	movc	a, @a+dptr
;	acall	phex		;output each byte
;	add	a, r3
;	mov	r3, a
;	inc	dptr
;	djnz	r2, upld6	;do however many bytes we need
;	mov	a, r3
;	cpl	a
;	inc	a
;	acall	phex		;and finally the checksum
;	acall	newline
;	acall	line_dly
;	acall	esc
;	jnc	upld3		;keep working if no esc pressed
;	sjmp	abort_it
;upld7:	mov	a, #':'
;	acall	cout
;	clr	a
;	acall	phex
;	acall	phex
;	acall	phex
;	inc	a
;	acall	phex
;	mov	a, #255
;	acall	phex
;upld8:	ajmp	newline2
;
;
;line_dly: ;a brief delay between line while uploading, so the
;	;receiving host can be slow (i.e. most windows software)
;	mov	a, r0
;	push	acc
;	mov	r0, #line_delay*2
;line_d2:mov	a, th0		;get baud rate const
;line_d3:inc	a
;	nop
;	nop
;	jnz	line_d3
;	djnz	r0, line_d2
;	pop	acc
;	mov	r0, a
;	ret
;
;;---------------------------------------------------------;
;
;get_mem:     ;this thing gets the begin and end locations for
;	     ;a few commands.  If an esc or enter w/ no input,
;	     ;it pops it's own return and returns to the menu
;	     ;(nasty programming, but we need tight code for 4k rom)
;	acall	newline2
;	mov	dptr, #beg_str
;	acall	pcstr_h
;	acall	ghex16
;	jc	pop_it
;	jb	psw.5, pop_it
;	push	dph
;	push	dpl
;	acall	newline
;	mov	dptr, #end_str
;	acall	pcstr_h
;	acall	ghex16
;	mov	r5, dph
;	mov	r4, dpl
;	pop	acc
;	mov	r2, a
;	pop	acc
;	mov	r3, a
;	jc	pop_it
;	jb	psw.5, pop_it
;	ajmp	newline
;
;pop_it: pop	acc
;	pop	acc
;abort_it:
;	acall	newline
;abort2: mov	dptr, #abort
;	ajmp	pcstr_h
;
;
;clrm:
;	acall	get_mem
;	mov	dptr, #sure
;	acall	pcstr_h
;	acall	input_character_filter_h
;	acall	char_2_upper
;	cjne	a, #'Y', abort_it
;	acall	newline2
;     ;now we actually do it
;
;clrm2:	mov	dph, r3
;	mov	dpl, r2
;clrm3:	clr	a
;	lcall	smart_wr
;	mov	a, r5
;	cjne	a, dph, clrm4
;	mov	a, r4
;	cjne	a, dpl, clrm4
;	ret
;clrm4:	inc	dptr
;	sjmp	clrm3
;
;;---------------------------------------------------------;
;
;;---------------------------------------------------------;
;
;
;;**************************************************************
;;**************************************************************
;;*****							  *****
;;*****	     2k page boundry is somewhere near here	  *****
;;*****	       (no ajmp or acall past this point)	  *****
;;*****							  *****
;;**************************************************************
;;**************************************************************
;
;
;
;;---------------------------------------------------------;
;;							  ;
;;   Subroutines for memory managment and non-serial I/O	  ;
;;							  ;
;;---------------------------------------------------------;
;
;
;;a routine that writes ACC to into flash memory at DPTR
;; C is set if error occurs, C is clear if it worked
;
;
;;************************************
;;To make PAULMON2 able to write to other
;;types of memory than RAM and flash rom,
;;modify this "smart_wr" routine.  This
;;code doesn't accept any inputs other
;;that the address (dptr) and value (acc),
;;so this routine must know which types
;;of memory are in what address ranges
;;************************************
;
;
;;Write to Flash ROM or ordinary RAM.  Carry bit will indicate
;;if the value was successfully written, C=1 if not written.
;
;
;smart_wr:
;	push	acc
;	push	b
;	mov	b, a
;	;do we even have a flash rom?
;	mov	a, #has_flash
;	jz	wr_ram
;	;there is a flash rom, but is this address in it?
;	mov	a, dph
;	cjne	a, #(eflash >> 8), isfl3
;	sjmp	wr_flash
;isfl3:	jnc	wr_ram
;	cjne	a, #(bflash >> 8), isfl4
;	sjmp	wr_flash
;isfl4:	jnc	wr_flash
;	;sjmp	wr_ram
;
;wr_ram: mov	a, b
;	movx	@dptr, a	;write the value to memory
;	clr	a
;	movc	a, @a+dptr	;read it back from code memory
;	clr	c
;	subb	a, b
;	jz	smwrok
;	movx	a, @dptr	;read it back from data memory
;	clr	c
;	subb	a, b
;	jz	smwrok
;smwrbad:setb	c
;	sjmp	smwrxit
;smwrok: clr	c
;smwrxit:pop	b
;	pop	acc
;	ret
;
;wr_flash:
;	mov	a, b
;	lcall	prgm
;	pop	b
;	pop	acc
;	ret
;
;
;
;
;;---------------------------------------------------------;
;;							  ;
;;	Power-On initialization code and such...	  ;
;;							  ;
;;---------------------------------------------------------;
;
;;first the hardware has to get initialized.
;
;intr_return:
;	reti
;
;;to do automatic baud rate detection, we assume the user will
;;press the carriage return, which will cause this bit pattern
;;to appear on port 3 pin 0 (CR = ascii code 13, assume 8N1 format)
;;
;;	       0 1 0 1 1 0 0 0 0 1
;;	       | |	       | |
;; start bit----+ +--lsb	  msb--+ +----stop bit
;;
;;we'll start timer #1 in 16 bit mode at the transition between the
;;start bit and the LSB and stop it between the MBS and stop bit.
;;That will give approx the number of cpu cycles for 8 bits.  Divide
;;by 8 for one bit and by 16 since the built-in UART takes 16 timer
;;overflows for each bit.  We need to be careful about roundoff during
;;division and the result has to be inverted since timer #1 counts up.  Of
;;course, timer #1 gets used in 8-bit auto reload mode for generating the
;;built-in UART's baud rate once we know what the reload value should be.
;
;
;autobaud:
;	mov	a, #baud_const	;skip if user supplied baud rate constant
;	jnz	autoend_jmp
;	mov	a, baud_save+3	;is there a value from a previous boot?
;	xrl	baud_save+2, #01010101b
;	xrl	baud_save+1, #11001100b
;	xrl	baud_save+0, #00011101b
;	cjne	a, baud_save+2, autob1
;	cjne	a, baud_save+1, autob1
;	cjne	a, baud_save+0, autob1
;autoend_jmp:
;	ajmp	autoend
;
;autob1: ;wait for inactivity
;
;	mov	pcon, #0x80	;configure uart, fast baud
;	mov	scon, #0x42	;configure uart, but receive disabled
;	mov	tmod, #0x11	;get timers ready for action (16 bit mode)
;	clr	a
;	mov	tcon, a
;	mov	tl0, a
;	mov	th0, a
;	mov	tl1, a
;	mov	th1, a
;
;	;make sure there is no activity on the line
;	;before we actually begin looking for the carriage return
;	mov	r0, #200
;autob1b:mov	r1, #30
;autob1c:jnb	p3.0, autob1
;	djnz	r1, autob1c
;	djnz	r0, autob1b
;
;autob2: ;look for the bits of the carriage return
;	jb	p3.0, autob2	;wait for start bit
;	jb	p3.0, autob2
;	jb	p3.0, autob2	;  check it a few more times to make
;	jb	p3.0, autob2	;  sure we don't trigger on some noise
;	jb	p3.0, autob2
;autob2b:jnb	p3.0, autob2b	;wait for bit #0 to begin
;	setb	tr1		;and now we're timing it
;autob2c:jb	tf1, autob1	;check for timeout while waiting
;	jb	p3.0, autob2c	;wait for bit #1 to begin
;autob2d:jb	tf1, autob1	;check for timeout while waiting
;	jnb	p3.0, autob2d	;wait for bit #2 to begin
;autob2e:jb	tf1, autob1	;check for timeout while waiting
;	jb	p3.0, autob2e	;wait for bit #4 to begin
;	setb	tr0		;start timing last 4 bits
;autob2f:jb	tf1, autob1	;check for timeout while waiting
;	jnb	p3.0, autob2f	;wait for stop bit to begin
;	clr	tr1		;stop timing (both timers)
;	clr	tr0
;
;	jb	tf1, autob1	;check for timeout one last time
;
;	;compute the baud rate based on timer1
;	mov	a, tl1
;	rlc	a
;	mov	b, a
;	mov	a, th1
;	rlc	a
;	jc	autob1		;error if timer0 > 32767
;	mov	c, b.7
;	addc	a, #0
;	cpl	a
;	inc	a		;now a has the value to load into th1
;	jz	autob1		;error if baud rate too fast
;
;	;after we get the carriage return, we need to make sure there
;	;isn't any "crap" on the serial line, as there is in the case
;	;were we get the letter E (and conclude the wrong baud rate).
;	;unfortunately the simple approach of just looking at the line
;	;for silence doesn't work, because we have to accept the case
;	;where the user's terminal emulation is configured to send a
;	;line feed after the carriage return.  The best thing to do is
;	;use the uart and look see if it receives anything
;
;autob3: mov	th1, a		;config timer1
;	mov	tl1, #255	;start asap!
;	mov	tmod, #0x21	;autoreload mode
;	setb	ren		;turn on the uart
;	setb	tr1		;turn on timer1 for its clock
;
;	mov	a, th1
;	cpl	a
;	inc	a
;	mov	r1, a
;autob3b:mov	r0, #255
;autob3c:djnz	r0, autob3c
;	djnz	r1, autob3b
;
;	jnb	ri, autob4
;	;if we got here, there was some stuff after the carriage
;	;return, so we'll read it and see if it was the line feed
;	clr	ri
;	mov	a, sbuf
;	anl	a, #01111111b
;	add	a, #246
;	jz	autob4		;ok if 0A, the line feed character
;	add	a, #5
;	jz	autob4		;of if 05, since we may have missed start bit
;autob1_jmp:
;	ljmp	autob1
;autob4:
;	;compute the baud rate based on timer0, check against timer1 value
;	mov	a, tl0
;	rlc	a
;	mov	r0, a
;	mov	a, th0
;	rlc	a
;	mov	r1, a
;	jc	autob1_jmp	;error if timer0 > 32767
;	mov	a, r0
;	rlc	a
;	mov	b, a
;	mov	a, r1
;	rlc	a
;	mov	c, b.7
;	addc	a, #0
;	jz	autob1_jmp	;error if baud too fast!
;	cpl	a
;	inc	a
;	cjne	a, th1, autob1_jmp
;	;acc has th1 value at this point
;
;autoend:mov	baud_save+3, a
;	mov	baud_save+2, a	;store the baud rate for next warm boot.
;	mov	baud_save+1, a
;	mov	baud_save+0, a
;	xrl	baud_save+2, #01010101b
;	xrl	baud_save+1, #11001100b 
;	xrl	baud_save+0, #00011101b 
;	mov	th1, a
;	mov	tl1, a
;	mov	tmod, #0x21	;set timer #1 for 8 bit auto-reload
;	mov	pcon, #0x80	;configure built-in uart
;	mov	scon, #0x52
;	setb	tr1		;start the baud rate timer
;	ret
