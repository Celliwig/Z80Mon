; # Power routines
; ###########################################################################

; # nc100_power_off
; #################################
;  Turns off the system
nc100_power_off:
	xor	a
	out	(nc100_io_power_control), a				; Power off system
	ret

; # nc100_power_check_in_gt_4v
; #################################
;  Checks that the voltage in is greater than 4.2V
;	Out:	Carry flag set if okay, clear if not
nc100_power_check_in_gt_4v:
	in	a, (nc100_io_misc_status_A)				; Read port
	and	nc100_volt_in_gt_4v					; Filter bits
	jr	z, nc100_power_check_in_gt_4v_failed
	scf								; Set Carry flag
	ret
nc100_power_check_in_gt_4v_failed:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_power_check_in_gt_3v
; #################################
;  Checks that the voltage in is greater than 3.2V
;	Out:	Carry flag set if okay, clear if not
nc100_power_check_in_gt_3v:
	in	a, (nc100_io_misc_status_A)				; Read port
	and	nc100_volt_in_gt_3v					; Filter bits
	jr	nz, nc100_power_check_in_gt_3v_failed
	scf								; Set Carry flag
	ret
nc100_power_check_in_gt_3v_failed:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_power_check_battery_backup
; #################################
;  Checks that the voltage of the backup battery
;  is greater than 2.7V
;	Out:	Carry flag set if okay, clear if not
nc100_power_check_battery_backup:
	in	a, (nc100_io_misc_status_A)				; Read port
	and	nc100_volt_backup_cell					; Filter bits
	jr	nz, nc100_power_check_battery_backup_failed
	scf								; Set Carry flag
	ret
nc100_power_check_battery_backup_failed:
	scf								; Clear Carry flag
	ccf
	ret

; # nc100_power_check_battery_memcard
; #################################
;  Checks the status of the memory card battery (if it exists)
;	Out:	Carry flag set if okay, clear if not
nc100_power_check_battery_memcard:
	in	a, (nc100_io_misc_status_A)				; Read port
	and	nc100_volt_memcard_battery				; Filter bits
	jr	z, nc100_power_check_battery_memcard_failed
	scf								; Set Carry flag
	ret
nc100_power_check_battery_memcard_failed:
	scf								; Clear Carry flag
	ccf
	ret
