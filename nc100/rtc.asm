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

; ###########################################################################
; # Time routines
; #################################

; # nc100_rtc_datetime_get_pair
; #################################
;  Get a pair of values from the RTC, return the combined
;  Page must already be selected.
;	In:	C = Port number (upper register)
;	Out:	A = Combined value
nc100_rtc_datetime_get_pair:
	in	a, (c)							; Get value
	and	0x0f							; Filter value
	ld	b, a							; Save value
	xor	a							; Clear A
nc100_rtc_datetime_get_pair_loop_x10:
	add	0xa							; Multiply B by 10
	djnz	nc100_rtc_datetime_get_pair_loop_x10
	ld	b, a							; Save value
	dec	c
	in	a, (c)							; Get next value
	and	0x0f							; Filter value
	add	b							; Add pair
	ret

; ###########################################################################
; # Timer (Clock) routines
; #################################

; # nc100_rtc_datetime_get
; #################################
;  Retrieves the current RTC date/time
;	Out:	B = Seconds
;		C = Minutes
;		D = Hours
;		E = Day
;		H = Month
;		L = Year
nc100_rtc_datetime_get:
	di								; Disable interrupts
									; while reading clock

	xor	a							; Clear A
	out	(nc100_rtc_base_register+tm8521_register_page), a	; Selects the datetime page
									; Disable timer
									; Disable alarm

	; Get datetime
	ld	c, nc100_rtc_base_register+tm8521_register_timer_second_10
	call	nc100_rtc_datetime_get_pair
	ld	h, a							; Temporaily save seconds
	ld	c, nc100_rtc_base_register+tm8521_register_timer_minute_10
	call	nc100_rtc_datetime_get_pair
	ld	l, a							; Temporaily save minutes
	push	hl							; Save for later
	ld	c, nc100_rtc_base_register+tm8521_register_timer_hour_10
	call	nc100_rtc_datetime_get_pair
	ld	d, a							; Save hours
	ld	c, nc100_rtc_base_register+tm8521_register_timer_day_10
	call	nc100_rtc_datetime_get_pair
	ld	e, a							; Save days
	ld	c, nc100_rtc_base_register+tm8521_register_timer_month_10
	call	nc100_rtc_datetime_get_pair
	ld	h, a							; Save months
	ld	c, nc100_rtc_base_register+tm8521_register_timer_year_10
	call	nc100_rtc_datetime_get_pair
	ld	l, a							; Save year
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

	ld	a, tm8521_register_page_enable_timer
	out	(nc100_rtc_base_register+tm8521_register_page), a	; Selects the datetime page
									; Enable timer
									; Disable alarm

	ei								; Enable interrupts again
	ret

; ###########################################################################
; # Alarm routines
; #################################

; ###########################################################################
; # RAM routines
; #################################
