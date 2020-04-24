; # Defines (I/O Port)
;
; Taken from: http://www.cpcwiki.eu/index.php/NC100_IO_Specification
; ###########################################################################
	nc100_io_membank_A:	equ	0x10		; Memory banking page(0): 0x0000-3FFF
	nc100_io_membank_B:	equ	0x11		; Memory banking page(1): 0x4000-7FFF
	nc100_io_membank_C:	equ	0x12		; Memory banking page(2): 0x8000-BFFF
	nc100_io_membank_D:	equ	0x13		; Memory banking page(3): 0xC000-FFFF
	nc100_io_irq_mask:	equ	0x60		; Interrupt mask
	nc100_io_irq_status:	equ	0x90		; Interrupt status

	; Memory bank source select
	nc100_membank_ROM:	equ	0x00		; Selects ROM
	nc100_membank_RAM:	equ	0x40		; Selects system RAM
	nc100_membank_CRAM:	equ	0x80		; Selects card RAM

	; Memory bank source offset
	nc100_membank_0k:	equ	0x00		; Select memory starting 0x00000
	nc100_membank_16k:	equ	0x01		; Select memory starting 0x04000
	nc100_membank_32k:	equ	0x02		; Select memory starting 0x08000
	nc100_membank_48k:	equ	0x03		; Select memory starting 0x0C000
	nc100_membank_64k:	equ	0x04		; Select memory starting 0x10000
	nc100_membank_80k:	equ	0x05		; Select memory starting 0x14000
	nc100_membank_96k:	equ	0x06		; Select memory starting 0x18000
	nc100_membank_112k:	equ	0x07		; Select memory starting 0x1C000
	nc100_membank_128k:	equ	0x08		; Select memory starting 0x20000
	nc100_membank_144k:	equ	0x09		; Select memory starting 0x24000
	nc100_membank_160k:	equ	0x0A		; Select memory starting 0x28000
	nc100_membank_176k:	equ	0x0B		; Select memory starting 0x2C000
	nc100_membank_192k:	equ	0x0C		; Select memory starting 0x30000
	nc100_membank_208k:	equ	0x0D		; Select memory starting 0x34000
	nc100_membank_224k:	equ	0x0E		; Select memory starting 0x38000
	nc100_membank_240k:	equ	0x0F		; Select memory starting 0x3C000
