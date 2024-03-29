; ===========================================================================
; ----------------------------------------------------------------
; SEGA CD header
;
; Header shared for both CD and CD32X
; ----------------------------------------------------------------

		dc.b "SEGADISCSYSTEM  "		; Disc Type (Must be SEGADISCSYSTEM)
		dc.b "NIKONA-CD  ",0		; Disc ID
		dc.w $100,1			; System ID, Type
		dc.b "NIKONA-SYS ",0		; System Name
		dc.w 0,0			; System Version, Type
		dc.l IP_Start
		dc.l IP_End
		dc.l 0
		dc.l 0
		dc.l SP_Start
		dc.l SP_End
		dc.l 0
		dc.l 0
		align $100			; Pad to $100
		dc.b "SEGA GENESIS    "
		dc.b "(C)GF64 2024.???"
	if MARSCD
		dc.b "Nikona CD32X                                    "
                dc.b "Nikona CD32X                                    "
	else
		dc.b "Nikona MCD                                      "
                dc.b "Nikona SCD                                      "
	endif
		dc.b "GM HOMEBREW-02  "
		dc.b "J6M             "
		align $1F0
		dc.b "JUE             "

	if CDREGION == 0
		binclude "system/mcd/region/jap.bin"
	elseif CDREGION == 2
		binclude "system/mcd/region/eur.bin"
	else
		binclude "system/mcd/region/usa.bin"	; <-- Default
	endif

; ====================================================================
; ----------------------------------------------------------------
; IP
; ----------------------------------------------------------------

IP_Start:
		lea	(vdp_data).l,a0
.wait_vint:	move.w	4(a0),d0
		btst	#3,d0
		beq.s	.wait_vint
		move.l	#$C0000000,4(a0)
		move.w	#64-1,d1
		moveq	#0,d0
.color_out:
		move.w	d0,(a0)
		dbf	d1,.color_out
		move.w	#$FD0C,(sysmcd_reg+mcd_hint).l	; Relocate HBlank jump
		jmp	($FF0600+MCD_Main).l
IP_End:
		align 2

; ====================================================================
; ----------------------------------------------------------------
; SP
; ----------------------------------------------------------------

		align $800
SP_Start:
		include "system/mcd/subcpu.asm"
SP_End:
		align 2

; ====================================================================
; ----------------------------------------------------------------
; Super-jump to a section already loaded
; on RAM
; ----------------------------------------------------------------

		align $2000-$600
MCD_Main:
