; # Config routines
; ###########################################################################
;  RTC has 12 bytes of storage available. These bytes are available to store
;  parameters such as serial configuration, console output selection, etc.


; ###########################################################################
; # nc100_config_uart_mode
; #################################
;  Stores the UART mode byte
;
; ###########################################################################
; # nc100_config_uart_baud
; #################################
;  Lower nibble select the baud rate.
nc100_config_uart_baud_on:			equ		6		; The serial port is currently enabled.
nc100_config_uart_baud_always:			equ		7		; The serial port is always enabled, and requests to shut it down are ignored.
										; The one exception to this is when the UART is reconfigured, but it will then be reenabled afterwards.

; ###########################################################################
; # nc100_config_misc
; #################################
;  General system parameters
nc100_config_misc_console:			equ		0		; Console interface: 1 = Serial, 0 = Local (LCD/Keyboard)
nc100_config_misc_memcard_wstates:		equ		1		; Memory card wait states: 1 = Wait states enabled (Mem. Card >=200ns), 0 = No wait

nc100_config_misc_console_mask:			equ		1 << nc100_config_misc_console
nc100_config_misc_memcard_wstates_mask:		equ		1 << nc100_config_misc_memcard_wstates

nc100_config_misc_defaults:			equ		nc100_config_misc_memcard_wstates_mask

; ###########################################################################
; # nc100_config_draw_attributes
; #################################
;  Copy of the LCD draw attributes
nc100_config_draw_attributes_defaults:		equ		nc100_draw_attrib_scroll_mask

; # Configuration bit routines
; ###########################################################################

; # nc100_config_misc_console_toggle
; #################################
;  Toggle the console source/destination.
nc100_config_misc_console_toggle:
	ld	a, (nc100_config_misc)					; Get console config
	xor	nc100_config_misc_console_mask				; Toggle console target flag
	ld	(nc100_config_misc), a					; Save console config
	ret

; # nc100_config_misc_memcard_wstates_toggle
; #################################
;  Toggle the whether memcard wait states are enabled
nc100_config_misc_memcard_wstates_toggle:
	ld	a, (nc100_config_misc)					; Get current wait states config
	xor	nc100_config_misc_memcard_wstates_mask			; Toggle whether memory card wait states are enabled
	ld	(nc100_config_misc), a					; Save wait states config
	ret

; # nc100_config_draw_attrib_invert_toggle
; #################################
;  Toggle the state of the invert draw attribute in the config copy.
nc100_config_draw_attrib_invert_toggle:
	ld	a, (nc100_config_draw_attributes)			; Get config draw attributes
	xor	nc100_draw_attrib_invert_mask				; Toggle invert flag
	ld	(nc100_config_draw_attributes), a			; Save config draw attributes
	ret

; # Config storage and retrieval routines
; ###########################################################################

; # nc100_config_checksum_create
; #################################
;  Scans the configuration storage area,
;  creates and saves a checksum
nc100_config_checksum_create:
	ld	hl, nc100_config					; Load start address of configuration area
	xor	a							; Clear A
nc100_config_checksum_create_loop:
	add	a, (hl)							; Add contents of memory to checksum
	inc	hl							; Increment pointer
	cp	nc100_config_chksum					; Check whether end address
	jr	nz, nc100_config_checksum_create_loop
	cpl								; Complement A
	ld	(hl), a							; Save checksum
	ret

; # nc100_config_checksum_validate
; #################################
;  Scans the configuration storage area, creates
;  a checksum and compares with the current one
;	Out:	Carry flag set if matches, unset if it doesn't
nc100_config_checksum_validate:
	ld	hl, nc100_config					; Load start address of configuration area
	xor	a							; Clear A
nc100_config_checksum_validate_loop:
	add	a, (hl)							; Add contents of memory to checksum
	inc	hl							; Increment pointer
	cp	nc100_config_chksum					; Check whether end address
	jr	nz, nc100_config_checksum_create_loop
	cpl								; Complement A
	ld	b, a							; Save result
	ld	a, (hl)							; Load existing
	cp	b							; Compare the two
	jr	nz, nc100_config_checksum_validate_failed
	scf								; Set Carry flag
	ret
nc100_config_checksum_validate_failed:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_config_save
; #################################
;  Recalculates the checksum and saves the
;  configuration block to the RTC.
nc100_config_save:
	call	nc100_config_checksum_create				; Create checksum
	ld	hl, nc100_config					; Load start address of configuration area
	call	nc100_rtc_ram_write					; Write configuration block to RTC
	ret

; # nc100_config_restore
; #################################
;  Restores the configuration block from the RTC,
;  checks that it's valid and applies it.
nc100_config_restore:
	ld	hl, nc100_config					; Load start address of configuration area
	call	nc100_rtc_ram_read					; Read configuration block from RTC
	call	nc100_config_checksum_validate				; Check checksum
	jr	c, nc100_config_apply					; Matches so apply
									; Otherwise load defaults
; # nc100_config_load_defaults
; #################################
;  Loads configuration block with default values.
nc100_config_load_defaults:
	ld	a, uPD71051_reg_mode_default
	ld	(nc100_config_uart_mode), a				; Serial defaults: 8 bits, no parity, 1 stop bit
	ld	a, nc100_serial_baud_9600
	ld	(nc100_config_uart_baud), a				; Serial default baud: 9600
	ld	a, nc100_config_misc_defaults
	ld	(nc100_config_misc), a
	ld	a, nc100_config_draw_attributes_defaults
	ld	(nc100_config_draw_attributes), a			; Draw attribute defaults: Scroll
; # nc100_config_save_apply
; #################################
;  Primarily used by the configuration program
nc100_config_save_apply:
	call	nc100_config_save					; Save configuration
; # nc100_config_apply
; #################################
;  Uses the information stored in the configuration
;  block to initialise aspects of the system.
nc100_config_apply:
	ld	b, (nc100_config_misc)
	bit	nc100_config_misc_memcard_wstates, b			; Check whether memory card wait states are required
	call	z, nc100_memory_memcard_wstates_off
	call	nz, nc100_memory_memcard_wstates_on

	ld	a, (nc100_config_draw_attributes)
	ld	(nc100_lcd_draw_attributes), a				; Copy config draw attributes to lcd draw attributes

	call	nc100_serial_reset_actual				; Maybe OTT, reset UART before potentially changing configuration
	call	nc100_serial_config					; Configure UART, and line driver

	ret
