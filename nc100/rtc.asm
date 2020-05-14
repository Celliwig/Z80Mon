; # RTC routines
; ###########################################################################
;  The RTC is accessed through ports 0xd0-0xdf. Data bus is only 4 bits wide.
;  Data is seperated in to seperate pages, with 4 in total. The first is the
;  current date/time. The second is the alarm. Third and fourth are general
;  data storage.

;  The last 3 addresses of each page access the control registers, so in fact
;  overlap. They are write only!!!
tm8521_register_page:			equ		0xd		; Page access register + Alarm/Timer enable
tm8521_register_test:			equ		0xe		; Test register (Guess what this does! Not need outside factory)
tm8521_register_reset:			equ		0xf		; Timer/Alarm reset + 1/16Hz enable

; Page register bits
tm8521_register_page_timer:		equ		0x0		; Select clock page
tm8521_register_page_alarm:		equ		0x1		; Select alarm page
tm8521_register_page_data1:		equ		0x2		; Select 1st data page
tm8521_register_page_data2:		equ		0x3		; Select 2nd data page
tm8521_register_page_enable_alarm:	equ		0x4		; Alarm enable bit
tm8521_register_page_enable_timer:	equ		0x8		; Timer enable bit

; Reset register bits
tm8521_register_reset_alarm:		equ		0x1		; Reset alarm
tm8521_register_reset_timer:		equ		0x2		; Reset timer
tm8521_register_reset_enable_16Hz:	equ		0x4		; Enable 16Hz alarm output
tm8521_register_reset_enable_1Hz:	equ		0x8		; Enable 1Hz alarm output

; Timer page
tm8521_register_timer_second_1:		equ		0x0		; Second: 8/4/2/1
tm8521_register_timer_second_10:	equ		0x1		; Second: -/40/20/10
tm8521_register_timer_minute_1:		equ		0x2		; Minute: 8/4/2/1
tm8521_register_timer_minute_10:	equ		0x3		; Minute: -/40/20/10
tm8521_register_timer_hour_1:		equ		0x4		; Hour: 8/4/2/1
tm8521_register_timer_hour_10:		equ		0x5		; Hour: -/-/20/10
tm8521_register_timer_week:		equ		0x6		; Week: -/W2/W1/W0
tm8521_register_timer_day_1:		equ		0x7		; Day: 8/4/2/1
tm8521_register_timer_day_10:		equ		0x8		; Day: -/-/20/10
tm8521_register_timer_month_1:		equ		0x9		; Month: 8/4/2/1
tm8521_register_timer_month_10:		equ		0xa		; Month: -/-/-/10
tm8521_register_timer_year_1:		equ		0xb		; Year: 8/4/2/1
tm8521_register_timer_year_10:		equ		0xc		; Year: 80/40/20/10

; Alarm page
tm8521_register_alarm_minute_1:		equ		0x2		; Minute: 8/4/2/1
tm8521_register_alarm_minute_10:	equ		0x3		; Minute: -/40/20/10
tm8521_register_alarm_hour_1:		equ		0x4		; Hour: 8/4/2/1
tm8521_register_alarm_hour_10:		equ		0x5		; Hour: -/-/20/10
tm8521_register_alarm_12_24:		equ		0xa		; Selects whether clock operates as 12 or 24 hour
tm8521_register_alarm_leap_year:	equ		0xb		; Leap year configuration

; ###########################################################################
; # Time routines
; #################################

; # nc100_rtc_init
; #################################
;  Initialise RTC after power on
nc100_rtc_init:
	xor	a							; Clear A
	out	(nc100_rtc_base_register+tm8521_register_test), a	; Be sure to zero test register

	ld	a, tm8521_register_reset_alarm|tm8521_register_reset_enable_16Hz|tm8521_register_reset_enable_1Hz
	out	(nc100_rtc_base_register+tm8521_register_reset), a	; Reset Alarm
									; Enable Timer (not reset)
									; 16Hz disabled
									; 1Hz disabled

	call	nc100_rtc_datetime_format_set_24h			; Set clock format: 24 hour

	ld	a, tm8521_register_page_enable_timer			; Enable clock
	out	(nc100_rtc_base_register+tm8521_register_page), a	; Selects the datetime page
									; Enable timer
									; Disable alarm
	ret

; # nc100_rtc_datetime_get_pair
; #################################
;  Get a pair of values from the RTC, return the combined
;  Page must already be selected.
;	In:	C = Port number (upper register)
;	Out:	A = Combined value
nc100_rtc_datetime_get_pair:
	in	a, (c)							; Get value
	and	0x0f							; Filter value
	rlc	a							; Shift to upper nibble
	rlc	a
	rlc	a
	rlc	a
	ld	b, a							; Save value
	dec	c
	in	a, (c)							; Get next value
	and	0x0f							; Filter value
	or	b							; Combine pair
	ret

; # nc100_rtc_datetime_set_pair
; #################################
;  Set a pair of values in the RTC
;  Page must already be selected.
;	In:	A = Value
;		C = Port number (upper register)
nc100_rtc_datetime_set_pair:
	ld	b, a							; Save for later
	and	0xf0							; Filter for upper nibble
	rlc	a							; Shift to lower nibble
	rlc	a
	rlc	a
	rlc	a
	out	(c), a							; Write out 10's unit
	dec	c							; Decreement to next register
	ld	a, b							; Reload value
	and	0x0f							; Filter for lower nibble
	out	(c), a							; Write out 1's unit
	ret

; # nc100_rtc_register_set_page
; #################################
;  Updates the selected page, without disturbing the alarm/timer bits
;	In:	B = Selected page
nc100_rtc_register_set_page:
	in	a, (nc100_rtc_base_register+tm8521_register_page)	; Get current page/alarm/timer bits
	and	tm8521_register_page_enable_timer|tm8521_register_page_enable_alarm
nc100_rtc_register_set_page_writeback:
	or	b							; Combine with selected page
	out	(nc100_rtc_base_register+tm8521_register_page), a	; Write value back
	ret

; ###########################################################################
; # Timer (Clock) routines
; #################################

; # nc100_rtc_register_timer_disabled
; #################################
;  Disables timer, selects timer page
nc100_rtc_register_timer_disabled:
	in	a, (nc100_rtc_base_register+tm8521_register_page)	; Get current page/alarm/timer bits
	and	tm8521_register_page_enable_alarm			; Filter out everything but alarm bit
	or	tm8521_register_page_timer				; Select timer page
	out	(nc100_rtc_base_register+tm8521_register_page), a	; Write value back
	ret

; # nc100_rtc_register_timer_enabled
; #################################
;  Enables timer, selects timer page
nc100_rtc_register_timer_enabled:
	in	a, (nc100_rtc_base_register+tm8521_register_page)	; Get current page/alarm/timer bits
	and	tm8521_register_page_enable_alarm			; Filter out everything but alarm bit
	or	tm8521_register_page_enable_timer			; Ensure timer bit set
	or	tm8521_register_page_timer				; Select timer page
	out	(nc100_rtc_base_register+tm8521_register_page), a	; Write value back
	ret

; # nc100_rtc_datetime_format_set_12h
; #################################
;  Sets the clock format as 12 hour
nc100_rtc_datetime_format_set_12h:
	ld	b, tm8521_register_page_alarm
	call	nc100_rtc_register_set_page				; Select alarm page
	xor	a							; Clear A
	out	(nc100_rtc_base_register+tm8521_register_alarm_12_24), a
	ret

; # nc100_rtc_datetime_format_set_24h
; #################################
;  Sets the clock format as 24 hour
nc100_rtc_datetime_format_set_24h:
	ld	b, tm8521_register_page_alarm
	call	nc100_rtc_register_set_page				; Select alarm page
	ld	a, 0x01
	out	(nc100_rtc_base_register+tm8521_register_alarm_12_24), a
	ret

; # nc100_rtc_datetime_format_toggle
; #################################
;  Toggles the clock format
nc100_rtc_datetime_format_toggle:
	ld	b, tm8521_register_page_alarm
	call	nc100_rtc_register_set_page				; Select alarm page
	in	a, (nc100_rtc_base_register+tm8521_register_alarm_12_24)
	xor	0x01							; Toggle bit
	out	(nc100_rtc_base_register+tm8521_register_alarm_12_24), a
	ret

; # nc100_rtc_datetime_format_check
; #################################
;  Check whether clock format is 24 hour
;	Out:	Carry flag set if 24 hour format, clear if 12 hour format
nc100_rtc_datetime_format_check:
	ld	b, tm8521_register_page_alarm
	call	nc100_rtc_register_set_page
	in	a, (nc100_rtc_base_register+tm8521_register_alarm_12_24)
	bit	0, a							; Test whether clock 24 format
	jr	z, nc100_rtc_datetime_format_check_not
	scf								; Set Carry flag
	ret
nc100_rtc_datetime_format_check_not:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_rtc_datetime_get
; #################################
;  Retrieves the current RTC date/time
;	Out:	B = Minutes
;		C = Seconds
;		D = Day
;		E = Hours
;		H = Year
;		L = Month
nc100_rtc_datetime_get:
	di								; Disable interrupts
									; while reading clock
	call	nc100_rtc_register_timer_disabled

	; Get datetime
	ld	c, nc100_rtc_base_register+tm8521_register_timer_second_10
	call	nc100_rtc_datetime_get_pair
	ld	l, a							; Temporaily save seconds
	ld	c, nc100_rtc_base_register+tm8521_register_timer_minute_10
	call	nc100_rtc_datetime_get_pair
	ld	h, a							; Temporaily save minutes
	push	hl							; Save for later
	ld	c, nc100_rtc_base_register+tm8521_register_timer_hour_10
	call	nc100_rtc_datetime_get_pair
	ld	e, a							; Save hours
	ld	c, nc100_rtc_base_register+tm8521_register_timer_day_10
	call	nc100_rtc_datetime_get_pair
	ld	d, a							; Save days
	ld	c, nc100_rtc_base_register+tm8521_register_timer_month_10
	call	nc100_rtc_datetime_get_pair
	ld	l, a							; Save months
	ld	c, nc100_rtc_base_register+tm8521_register_timer_year_10
	call	nc100_rtc_datetime_get_pair
	ld	h, a							; Save year
	pop	bc							; Restore saved values

; Disabled the timer so don't need to re-read
;	; Check datetime
;	ld	c, tm8521_register_timer_second_10
;	call	nc100_rtc_datetime_get_pair
;	cp	b							; Check seconds
;	jr	nz, nc100_rtc_datetime_get				; Don't match so reload
;	ld	c, tm8521_register_timer_minute_10
;	call	nc100_rtc_datetime_get_pair
;	cp	c							; Check minutes
;	jr	nz, nc100_rtc_datetime_get				; Don't match so reload
;	ld	c, tm8521_register_timer_hour_10
;	call	nc100_rtc_datetime_get_pair
;	cp	d							; Check hours
;	jr	nz, nc100_rtc_datetime_get				; Don't match so reload
;	ld	c, tm8521_register_timer_day_10
;	call	nc100_rtc_datetime_get_pair
;	cp	e							; Check days
;	jr	nz, nc100_rtc_datetime_get				; Don't match so reload
;	ld	c, tm8521_register_timer_month_10
;	call	nc100_rtc_datetime_get_pair
;	cp	h							; Check months
;	jr	nz, nc100_rtc_datetime_get				; Don't match so reload
;	ld	c, tm8521_register_timer_year_10
;	call	nc100_rtc_datetime_get_pair
;	cp	l							; Check years
;	jr	nz, nc100_rtc_datetime_get				; Don't match so reload

	call	nc100_rtc_register_timer_enabled
	ei								; Enable interrupts again
	ret

; # nc100_rtc_leap_year_set
; #################################
;  Sets the leap year digits
;	In:	C = Leap year config
nc100_rtc_leap_year_set:
	ld	b, tm8521_register_page_alarm
	call	nc100_rtc_register_set_page				; Select alarm page
	ld	a, c
	and	0x03							; Filter value
	out	(nc100_rtc_base_register+tm8521_register_alarm_leap_year), a
	ret

; # nc100_rtc_datetime_set
; #################################
;  Sets the current RTC date/time
;	In:	B = Minutes
;		C = Seconds
;		D = Day
;		E = Hours
;		H = Year
;		L = Month
nc100_rtc_datetime_set:
	di								; Disable interrupts
	call	nc100_rtc_register_timer_disabled

	; Set date/time
	push	bc							; Because it's going to get nuked
	ld	a, h							; Set year
	ld	c, nc100_rtc_base_register+tm8521_register_timer_year_10
	call	nc100_rtc_datetime_set_pair
	ld	a, l							; Set month
	ld	c, nc100_rtc_base_register+tm8521_register_timer_month_10
	call	nc100_rtc_datetime_set_pair
	ld	a, d							; Set day
	ld	c, nc100_rtc_base_register+tm8521_register_timer_day_10
	call	nc100_rtc_datetime_set_pair
	ld	a, e							; Set hour
	ld	c, nc100_rtc_base_register+tm8521_register_timer_hour_10
	call	nc100_rtc_datetime_set_pair
	pop	hl							; Restore saved values
	ld	a, h							; Set minutes
	ld	c, nc100_rtc_base_register+tm8521_register_timer_minute_10
	call	nc100_rtc_datetime_set_pair
	ld	a, l							; Set seconds
	ld	c, nc100_rtc_base_register+tm8521_register_timer_second_10
	call	nc100_rtc_datetime_set_pair

	call	nc100_rtc_register_timer_enabled
	ei								; Enable interrupts
	ret

; ###########################################################################
; # Alarm routines
; #################################

; # nc100_rtc_alarm_enable
; #################################
;  Enables the RTC alarm
nc100_rtc_alarm_enable:
	in	a, (nc100_rtc_base_register+tm8521_register_page)	; Get current page/alarm/timer bits
	or	tm8521_register_page_enable_alarm
	out	(nc100_rtc_base_register+tm8521_register_page), a	; Write value back
	ret

; # nc100_rtc_alarm_disable
; #################################
;  Disables the RTC alarm
nc100_rtc_alarm_disable:
	in	a, (nc100_rtc_base_register+tm8521_register_page)	; Get current page/alarm/timer bits
	and	0xff^tm8521_register_page_enable_alarm
	out	(nc100_rtc_base_register+tm8521_register_page), a	; Write value back
	ret

; # nc100_rtc_alarm_toggle
; #################################
;  Toggles the state of the alarm enable
nc100_rtc_alarm_toggle:
	in	a, (nc100_rtc_base_register+tm8521_register_page)	; Get current page/alarm/timer bits
	xor	tm8521_register_page_enable_alarm
	out	(nc100_rtc_base_register+tm8521_register_page), a	; Write value back
	ret

; # nc100_rtc_alarm_check
; #################################
;  Checks the state of alarm enable
;	Out:	Carry flag set if alarm enabled, Carry flag clear if alarm disabled
nc100_rtc_alarm_check:
	in	a, (nc100_rtc_base_register+tm8521_register_page)	; Get current page/alarm/timer bits
	bit	2, a							; Check whether alarm enabled
	jr	z, nc100_rtc_alarm_check_disabled
	scf								; Set Carry flag
	ret
nc100_rtc_alarm_check_disabled:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_rtc_alarm_get
; #################################
;  Retrieves the current RTC alarm
;	Out:	D = Hours
;		E = Minutes
nc100_rtc_alarm_get:
	ld	b, tm8521_register_page_alarm
	call	nc100_rtc_register_set_page				; Select alarm page

	; Get alarm
	ld	c, nc100_rtc_base_register+tm8521_register_alarm_minute_10
	call	nc100_rtc_datetime_get_pair
	ld	e, a							; Save minutes
	ld	c, nc100_rtc_base_register+tm8521_register_alarm_hour_10
	call	nc100_rtc_datetime_get_pair
	ld	d, a							; Save hours
	ret

; # nc100_rtc_alarm_set
; #################################
;  Sets the current RTC alarm
;	In:	D = Hours
;		E = Minutes
nc100_rtc_alarm_set:
	ld	b, tm8521_register_page_alarm
	call	nc100_rtc_register_set_page				; Select alarm page

	; Set alarm
	ld	a, d							; Set hour
	ld	c, nc100_rtc_base_register+tm8521_register_alarm_hour_10
	call	nc100_rtc_datetime_set_pair
	ld	a, e							; Set minutes
	ld	c, nc100_rtc_base_register+tm8521_register_alarm_minute_10
	call	nc100_rtc_datetime_set_pair
	ret

; ###########################################################################
; # RAM routines
; #################################
;  The RTC has 2 pages, each with 13 nibbles of storage.
;  To simplify operations, the last nibble in each page is ignored so
;  12 bytes of storage is available

; # nc100_rtc_ram_read
; #################################
;  Reads RTC RAM into system RAM
;	In:	HL = Pointer to start of 12 byte block
nc100_rtc_ram_read:
	ld	de, 0x0b
	add	hl, de							; Start at the end of the block

	ld	b, tm8521_register_page_data2
	call	nc100_rtc_register_set_page				; Selects the 2nd RAM page

	ld	b, 6							; Byte counter
	ld	c, nc100_rtc_base_register+0x0b				; End RTC register port address
nc100_rtc_ram_read_loop1:
	in	a, (c)							; Read value
	and	0x0f							; Filter value
	sla	a							; Move to upper nibble
	sla	a
	sla	a
	sla	a
	ld	d, a							; Save for later
	dec	c							; Next RTC register
	in	a, (c)
	and	0x0f							; Filter value
	or	d							; Add saved value
	ld	(hl), a							; Write value to system RAM
	dec	hl							; Decrement system RAM pointer
	dec	c							; Next RTC register
	djnz	nc100_rtc_ram_read_loop1				; Loop while bytes remain

	ld	b, tm8521_register_page_data1
	call	nc100_rtc_register_set_page				; Selects the 1st RAM page

	ld	b, 6							; Byte counter
	ld	c, nc100_rtc_base_register+0x0b				; End RTC register port address
nc100_rtc_ram_read_loop2:
	in	a, (c)							; Read value
	and	0x0f							; Filter value
	sla	a							; Move to upper nibble
	sla	a
	sla	a
	sla	a
	ld	d, a							; Save for later
	dec	c							; Next RTC register
	in	a, (c)
	and	0x0f							; Filter value
	or	d							; Add saved value
	ld	(hl), a							; Write value to system RAM
	dec	hl							; Decrement system RAM pointer
	dec	c							; Next RTC register
	djnz	nc100_rtc_ram_read_loop2				; Loop while bytes remain

	ret

; # nc100_rtc_ram_write
; #################################
;  Writes a block of system RAM into the RTC RAM
;	In:	HL = Pointer to start of 12 byte block to save
nc100_rtc_ram_write:
	ld	de, 0x0b
	add	hl, de							; Start at the end of the block

	ld	b, tm8521_register_page_data2
	call	nc100_rtc_register_set_page				; Selects the 2nd RAM page

	ld	b, 6							; Byte counter
	ld	c, nc100_rtc_base_register+0x0b				; End RTC register port address
nc100_rtc_ram_write_loop1:
	ld	d, (hl)							; Get value from system RAM
	dec	hl							; Decrement system RAM pointer
	ld	a, d							; First upper nibble
	and	0xf0							; Filter value
	srl	a							; Move to lower nibble
	srl	a
	srl	a
	srl	a
	out	(c), a							; Write nibble to RTC RAM
	dec	c							; Next RTC register
	ld	a, d							; Lower nibble
	and	0x0f							; Filter value
	out	(c), a							; Write nibble to RTC RAM
	dec	c							; Next RTC register
	djnz	nc100_rtc_ram_write_loop1				; Loop while bytes remain

	ld	b, tm8521_register_page_data1
	call	nc100_rtc_register_set_page				; Selects the 1st RAM page

	ld	b, 6							; Byte counter
	ld	c, nc100_rtc_base_register+0x0b				; End RTC register port address
nc100_rtc_ram_write_loop2:
	ld	d, (hl)							; Get value from system RAM
	dec	hl							; Decrement system RAM pointer
	ld	a, d							; First upper nibble
	and	0xf0							; Filter value
	srl	a							; Move to lower nibble
	srl	a
	srl	a
	srl	a
	out	(c), a							; Write nibble to RTC RAM
	dec	c							; Next RTC register
	ld	a, d							; Lower nibble
	and	0x0f							; Filter value
	out	(c), a							; Write nibble to RTC RAM
	dec	c							; Next RTC register
	djnz	nc100_rtc_ram_write_loop2				; Loop while bytes remain

	ret

; # nc100_rtc_ram_check
; #################################
;  Check that a 12 byte block of system RAM matches the values stored in the RTC
;	In:	HL = Pointer to start of 12 byte block to save
;	Out:	Carry flag set if it matches, clear if it doesn't
nc100_rtc_ram_check:
	ld	de, 0x0b
	add	hl, de							; Start at the end of the block

	ld	b, tm8521_register_page_data2
	call	nc100_rtc_register_set_page				; Selects the 2nd RAM page

	ld	b, 6							; Byte counter
	ld	c, nc100_rtc_base_register+0x0b				; End RTC register port address
nc100_rtc_ram_check_loop1:
	ld	d, (hl)							; Get value from system RAM
	dec	hl							; Decrement system RAM pointer
	ld	a, d							; Upper nibble
	and	0xf0							; Filter value
	srl	a							; Move to lower nibble
	srl	a
	srl	a
	srl	a
	ld	e, a							; Save for comparison
	in	a, (c)							; Get RTC RAM value
	and	0x0f							; Filter RTC value
	dec	c							; Next RTC register
	cp	e							; Compare values
	jr	nz, nc100_rtc_ram_check_failed				; RAM does not match
	ld	a, d							; Lower nibble
	and	0x0f							; Filter value
	ld	e, a							; Save for comparison
	in	a, (c)							; Get RTC RAM value
	and	0x0f							; Filter RTC value
	dec	c							; Next RTC register
	cp	e							; Compare values
	jr	nz, nc100_rtc_ram_check_failed				; RAM does not match
	djnz	nc100_rtc_ram_check_loop1				; Loop while bytes remain

	ld	b, tm8521_register_page_data1
	call	nc100_rtc_register_set_page				; Selects the 1st RAM page

	ld	b, 6							; Byte counter
	ld	c, nc100_rtc_base_register+0x0b				; End RTC register port address
nc100_rtc_ram_check_loop2:
	ld	d, (hl)							; Get value from system RAM
	dec	hl							; Decrement system RAM pointer
	ld	a, d							; Upper nibble
	and	0xf0							; Filter value
	srl	a							; Move to lower nibble
	srl	a
	srl	a
	srl	a
	ld	e, a							; Save for comparison
	in	a, (c)							; Get RTC RAM value
	and	0x0f							; Filter RTC value
	dec	c							; Next RTC register
	cp	e							; Compare values
	jr	nz, nc100_rtc_ram_check_failed				; RAM does not match
	ld	a, d							; Lower nibble
	and	0x0f							; Filter value
	ld	e, a							; Save for comparison
	in	a, (c)							; Get RTC RAM value
	and	0x0f							; Filter RTC value
	dec	c							; Next RTC register
	cp	e							; Compare values
	jr	nz, nc100_rtc_ram_check_failed				; RAM does not match
	djnz	nc100_rtc_ram_check_loop2				; Loop while bytes remain

	scf								; Set Carry flag
	ret
nc100_rtc_ram_check_failed:
	scf								; Clear Carry flag
	ccf
	ret
