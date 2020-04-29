; # Defines (I/O Port)
; #
; # Taken from: http://www.cpcwiki.eu/index.php/NC100_IO_Specification
; ###########################################################################
	nc100_io_lcd_raster_addr:	equ	0x00		; Start address of LCD raster memory
	nc100_io_membank_A:		equ	0x10		; Memory banking page(0): 0x0000-3FFF
	nc100_io_membank_B:		equ	0x11		; Memory banking page(1): 0x4000-7FFF
	nc100_io_membank_C:		equ	0x12		; Memory banking page(2): 0x8000-BFFF
	nc100_io_membank_D:		equ	0x13		; Memory banking page(3): 0xC000-FFFF
	nc100_io_memcard_wait_control:	equ	0x20		; Controls whether memory cards require wait states
	nc100_io_misc_config_A:		equ	0x30		; Controls multiple functions (baud rate, etc)
	nc100_io_parallel_data:		equ	0x40		; Data written here is latched on to the parallel port
	nc100_io_sound_A_low:		equ	0x50		; Sound device: Channel A
	nc100_io_sound_A_high:		equ	0x51
	nc100_io_sound_B_low:		equ	0x52		; Sound device: Channel B
	nc100_io_sound_B_high:		equ	0x53
	nc100_io_irq_mask:		equ	0x60		; Interrupt mask
	nc100_io_power_control:		equ	0x70		; Turns off device
	nc100_io_irq_status:		equ	0x90		; Interrupt status
	nc100_io_misc_status_A:		equ	0xA0		; State of various signals
	nc100_io_keyboard_buffer0:	equ	0xB0		; Holds state information of the keyboard matrix
	nc100_io_keyboard_buffer1:	equ	0xB1
	nc100_io_keyboard_buffer2:	equ	0xB2
	nc100_io_keyboard_buffer3:	equ	0xB3
	nc100_io_keyboard_buffer4:	equ	0xB4
	nc100_io_keyboard_buffer5:	equ	0xB5
	nc100_io_keyboard_buffer6:	equ	0xB6
	nc100_io_keyboard_buffer7:	equ	0xB7
	nc100_io_keyboard_buffer8:	equ	0xB8
	nc100_io_keyboard_buffer9:	equ	0xB9
	nc100_uart_data_register:	equ	0xC0		; NEC uPD71051 data register
	nc100_uart_control_register:	equ	0xC1		; NEC uPD71051 control register

; # Memory Bank Control (0x10-0x13)
; ###########################################################################
; # Memory bank source
	; Memory bank source select
	nc100_membank_ROM:		equ	0x00		; Selects ROM
	nc100_membank_RAM:		equ	0x40		; Selects system RAM
	nc100_membank_CRAM:		equ	0x80		; Selects card RAM

; # Memory page selection
	; Memory bank source offset
	nc100_membank_0k:		equ	0x00		; Select memory starting 0x00000
	nc100_membank_16k:		equ	0x01		; Select memory starting 0x04000
	nc100_membank_32k:		equ	0x02		; Select memory starting 0x08000
	nc100_membank_48k:		equ	0x03		; Select memory starting 0x0C000
	nc100_membank_64k:		equ	0x04		; Select memory starting 0x10000
	nc100_membank_80k:		equ	0x05		; Select memory starting 0x14000
	nc100_membank_96k:		equ	0x06		; Select memory starting 0x18000
	nc100_membank_112k:		equ	0x07		; Select memory starting 0x1C000
	nc100_membank_128k:		equ	0x08		; Select memory starting 0x20000
	nc100_membank_144k:		equ	0x09		; Select memory starting 0x24000
	nc100_membank_160k:		equ	0x0A		; Select memory starting 0x28000
	nc100_membank_176k:		equ	0x0B		; Select memory starting 0x2C000
	nc100_membank_192k:		equ	0x0C		; Select memory starting 0x30000
	nc100_membank_208k:		equ	0x0D		; Select memory starting 0x34000
	nc100_membank_224k:		equ	0x0E		; Select memory starting 0x38000
	nc100_membank_240k:		equ	0x0F		; Select memory starting 0x3C000

; # Memory Card Wait States (0x20)
; ###########################################################################
	nc100_memcard_wait:		equ	1 << 7		; 1 = Memory cards slower than 200ns, 0 = Memory card faster than 200ns

; # Misc Config A (0x30)
; ###########################################################################
	nc100_memcard_register:		equ	1 << 7		; 1 = Common register, 0 = Attributes register
	nc100_parallel_strobe:		equ	1 << 6		; Controls parallel port strobe signal
	nc100_serial_line_driver:	equ	1 << 4		; Controls serial line driver uPD4711 (1 = Off, 0 = On)
	nc100_serial_clk_rst:		equ	1 << 3		; Serial clock/reset: 1 = Device off, 0 = Device on
	nc100_serial_baud_mask:		equ	7		; Bit mask for serial baud selection
	nc100_serial_baud_150:		equ	0		; Serial baud rates
	nc100_serial_baud_300:		equ	1
	nc100_serial_baud_600:		equ	2
	nc100_serial_baud_1200:		equ	3
	nc100_serial_baud_2400:		equ	4
	nc100_serial_baud_4800:		equ	5
	nc100_serial_baud_9600:		equ	6
	nc100_serial_baud_19200:	equ	7

; # Interrupt Request Mask (0x60)
; # Interrupt Request Mask (0x90)
; ###########################################################################
	nc100_irq_key_scan:		equ	1 << 3		; Keyboard interrupt
	nc100_irq_parallel_ack:		equ	1 << 2		; Parallel port received an ACK
	nc100_irq_tx_ready:		equ	1 << 1		; Serial port is ready to transmit
	nc100_irq_rx_ready:		equ	1 << 0		; Serial port is ready to receive

; # Power control (0x70)
; ###########################################################################
	nc100_power_off:		equ	1 << 0		; 1 = no effect, 0 = power off

; # Misc Status A (0xA0)
; ###########################################################################
	nc100_memcard_present:		equ	1 << 7		; 0 = Present, 1 = Not present
	nc100_memcard_write_prot:	equ	1 << 6		; 0 = Read/Writable, 1 = Read only
	nc100_volt_in:			equ	1 << 5		; 1 if voltage in okay (>= 4V)
	nc100_volt_memcard_battery:	equ	1 << 4		; 1 if battery okay
	nc100_volt_alkaline_battery:	equ	1 << 3		; 0 if on batteries okay (>= 3.2V)
	nc100_volt_lithium_cell:	equ	1 << 2		; 0 if onboard backup battery okay (>= 2.7V)
	nc100_parallel_busy:		equ	1 << 1		; 0 if parallel port busy
	nc100_parallel_ack:		equ	1 << 0		; 1 if parallel port ack

; # Keyboard Buffer 0-9 (0xB0-0xB9)
; ###########################################################################
; Saves the state of individual key presses

; # UART Data Register (0xC0)
; ###########################################################################
; Data register of the NEC uPD71051 UART.

; # UART Control Register (0xC1)
; ###########################################################################
; Control register of the NEC uPD71051 UART.
