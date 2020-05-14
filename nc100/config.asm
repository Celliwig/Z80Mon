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
nc100_config_misc_console:		equ		0		; Console interface: 1 = Serial, 0 = Local (LCD/Keyboard)

; ###########################################################################
; # nc100_config_draw_attributes
; #################################
;  Copy of the LCD draw attributes
