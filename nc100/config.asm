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
nc100_config_uart_baud_on:		equ		6		; The serial port is currently enabled.
nc100_config_uart_baud_always:		equ		7		; The serial port is always enabled, and requests to shut it down are ignored.
									; The one exception to this is when the UART is reconfigured, but it will then be reenabled afterwards.

; ###########################################################################
; # nc100_config_misc
; #################################
;  General system parameters
nc100_config_misc_console:			equ		0		; Console interface: 1 = Serial, 0 = Local (LCD/Keyboard)
nc100_config_misc_memcard_wstates:		equ		1		; Memory card wait states: 1 = Wait states enabled (Mem. Card >=200ns), 0 = No wait

nc100_config_misc_console_mask:			equ		1 << nc100_config_misc_console
nc100_config_misc_memcard_wstates_mask:		equ		1 << nc100_config_misc_memcard_wstates

; ###########################################################################
; # nc100_config_draw_attributes
; #################################
;  Copy of the LCD draw attributes

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
