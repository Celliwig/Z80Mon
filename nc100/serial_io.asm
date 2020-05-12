; # Serial routines
; ###########################################################################

; Status register bits
uPD71051_reg_status_TxRdy:		equ		0		; Transmit Data Buffer: 1 = Empty, 0 = Full
uPD71051_reg_status_RxRdy:		equ		1		; Receive Data Buffer: 1 = Full, 0 = Not Ready
uPD71051_reg_status_TxEmp:		equ		2		;
uPD71051_reg_status_PE:			equ		3		; Parity Error: 1 = Error, 0 = No Error
uPD71051_reg_status_Ove:		equ		4		; Overrun Error: 1 = Error, 0 = No Error
uPD71051_reg_status_FE:			equ		5		; Framing Error: 1 = Error, 0 = No Error
uPD71051_reg_status_StncBrk:		equ		6		;
uPD71051_reg_status_DSR:		equ		7		; DSR state (active low): 1 = DSR(0), 0 = DSR(1)

; Mode register bits
uPD71051_reg_mode_bclk_x1:		equ		0x01		; Baud rate clock x1
uPD71051_reg_mode_bclk_x16:		equ		0x02		; Baud rate clock x16
uPD71051_reg_mode_bclk_x64:		equ		0x03		; Baud rate clock x64
uPD71051_reg_mode_chrlen_5:		equ		0x00		; Character length: 5 bits
uPD71051_reg_mode_chrlen_6:		equ		0x04		; Character length: 6 bits
uPD71051_reg_mode_chrlen_7:		equ		0x08		; Character length: 7 bits
uPD71051_reg_mode_chrlen_8:		equ		0x0c		; Character length: 8 bits
uPD71051_reg_mode_parity_none:		equ		0x00		; Parity: None
uPD71051_reg_mode_parity_odd:		equ		0x10		; Parity: Odd
uPD71051_reg_mode_parity_even:		equ		0x30		; Parity: Even
uPD71051_reg_mode_stopbit_1:		equ		0x40		; Stop Bit(s): 1
uPD71051_reg_mode_stopbit_15:		equ		0x80		; Stop Bit(s): 1.5
uPD71051_reg_mode_stopbit_2:		equ		0xc0		; Stop Bit(s): 2

; Command register bits
uPD71051_reg_command_TxEn:		equ		0		; Transmit Enable: 1 = Enable, 0 = Disabled
uPD71051_reg_command_DTR:		equ		1		; DTR state (active low): 1 = DTR(0), 0 = DTR(1)
uPD71051_reg_command_RxEn:		equ		2		; Receive Enable: 1 = Enable, 0 = Disabled
uPD71051_reg_command_SBrk:		equ		3		; Send Break: 1 = TxData(0), 0 = TxData normal operation
uPD71051_reg_command_ECl:		equ		4		; Error Clear: 1 = Clear error flag, 0 = No operation
uPD71051_reg_command_RTS:		equ		5		; RTS state (active low): 1 = RTS(0), 0 = RTS(1)
uPD71051_reg_command_SRes:		equ		6		; Software Reset: 1 = Reset, 0 = No operation
uPD71051_reg_command_EH:		equ		7		; Enter Hunt Phase: 1 = Enter Hunt Phase, 0 = No operation

; Command register bits (mask value)
uPD71051_reg_commask_TxEn:		equ		1 << uPD71051_reg_command_TxEn
uPD71051_reg_commask_DTR:		equ		1 << uPD71051_reg_command_DTR
uPD71051_reg_commask_RxEn:		equ		1 << uPD71051_reg_command_RxEn
uPD71051_reg_commask_SBrk:		equ		1 << uPD71051_reg_command_SBrk
uPD71051_reg_commask_ECl:		equ		1 << uPD71051_reg_command_ECl
uPD71051_reg_commask_RTS:		equ		1 << uPD71051_reg_command_RTS
uPD71051_reg_commask_SRes:		equ		1 << uPD71051_reg_command_SRes
uPD71051_reg_commask_EH:		equ		1 << uPD71051_reg_command_EH
; Combined enable units
uPD71051_reg_commask_enable:		equ		uPD71051_reg_commask_TxEn | uPD71051_reg_commask_RxEn
; Combined handshake active
uPD71051_reg_commask_handshake:		equ		uPD71051_reg_commask_DTR | uPD71051_reg_commask_RTS
; Combined full
uPD71051_reg_commask_full:		equ		uPD71051_reg_commask_enable | uPD71051_reg_commask_handshake | uPD71051_reg_commask_ECl


; # nc100_serial_setup_delay
; #################################
;  Delay needed for config changes to propagate
nc100_serial_setup_delay:
	ld	b, 12
nc100_serial_setup_delay_loop:
	djnz	nc100_serial_setup_delay_loop
	ret

; # nc100_serial_init
; #################################
;  From power on (state unknown), reset UART, turn off line driver
nc100_serial_init:
	xor	a							; Clear A
	out	(nc100_uart_control_register), a			; Three writes of 0x0
	call	nc100_serial_setup_delay
	out	(nc100_uart_control_register), a			; Clears the way
	call	nc100_serial_setup_delay
	out	(nc100_uart_control_register), a			; For a new command bytes
	call	nc100_serial_setup_delay
; # nc100_serial_reset
; #################################
;  Reset UART, turn off line driver
nc100_serial_reset:
	; Software reset UART
	ld	a, uPD71051_reg_commask_SRes				; Software reset
	out	(nc100_uart_control_register), a 			; Write command byte
	call	nc100_serial_setup_delay

	; Reset UART/ turn off line driver
	ld	a, 0xF8							; Memcard register: common
									; Parallel strobe: off
									; Not used
									; Line driver: off
									; UART clock/reset: reset
	out	(nc100_io_misc_config_A), a
	call	nc100_serial_setup_delay
	ret

; # nc100_serial_config
; #################################
;  Config UART, turn on line driver
;	In:	B = Baud rate
;		C = Mode configuration
nc100_serial_config:
	; Config UART/ turn on line driver
	ld	a, b							; Copy baud config
	and	0x07							; Strip extraneous bits
	or	a, 0xe0							; Memcard: common, Parallel strobe: off
									; Line driver: on, UART: on
	out	(nc100_io_misc_config_A), a
	call	nc100_serial_setup_delay

	ld	a, c							; Copy mode configuration
	out	(nc100_uart_control_register), a 			; Write mode to control register
	call	nc100_serial_setup_delay

	; Write command byte to UART
	ld	a, uPD71051_reg_commask_full
	out	(nc100_uart_control_register), a 			; Write command byte
	call	nc100_serial_setup_delay
	ret

; # Polling routines
; ###########################################################################
; # nc100_serial_char_out_poll
; #################################
;  Write a character to the serial port
;	In:	A = ASCII character
nc100_serial_char_out_poll:
	ex	af, af'							; Save ASCII character
nc100_serial_char_out_poll_check_txrdy:
	in	a, (nc100_uart_control_register)			; Read status register
	bit	uPD71051_reg_status_TxRdy, a				; Test TxRDY
	jr	z, nc100_serial_char_out_poll_check_txrdy

	ex	af, af'
	out	(nc100_uart_data_register), a				; Write data to UART
	ret

; # nc100_serial_char_in_poll
; #################################
;  Returns a character from the serial port
;       Out:    A = ASCII character code
;       Carry flag set if character valid
nc100_serial_char_in_poll:
	ld	a, uPD71051_reg_commask_full				; Clear any errors
	out	(nc100_uart_control_register), a 			; Write command byte
	in	a, (nc100_uart_data_register)				; Dummy read (clear any pending characters)
nc100_serial_char_in_poll_check_rxrdy:
	in	a, (nc100_uart_control_register)			; Read status register
	bit	uPD71051_reg_status_RxRdy, a				; Test RxRDY
	jr	z, nc100_serial_char_in_poll_check_rxrdy

	in	a, (nc100_uart_data_register)				; Get data from UART
	ret
