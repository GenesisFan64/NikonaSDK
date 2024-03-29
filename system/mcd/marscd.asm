; ====================================================================
; ----------------------------------------------------------------
; 32X BOOT ON SEGA CD
; ----------------------------------------------------------------

; Load the SH2 code from disc to WORD-RAM from here:

		lea	.file_marscode(pc),a0		; Load SH2 code from disc to WORD-RAM
		jsr	(System_McdTrnsfr_WRAM).l
		bra.s	MarsCd_Boot
.file_marscode:
		dc.b "MARSCODE.BIN",0
		align 2

; ----------------------------------------------------------------

; MarsCd_Retry:
; 		lea	($A15100).l,a5
; 		move.b	#0,1(a5)
MarsCd_Boot:
		lea	($A10000).l,a5
		cmp.l	#"MARS",$30EC(a5)	; check MARS ID
		bne	MarsError
.sh_wait:
		btst.b	#7,$5101(a5)		; adapter control reg. REN=1 ?
		beq.b	.sh_wait
		btst.b	#0,$5101(a5)		; check adapter mode
		bne	Hot_Start
.cold_start:					; power on (cold_start)
		move.b	#1,$5101(a5)		; MARS mode
						; SH2 reset - wait 10ms -
		bra	RestartPrg

; ----------------------------------------------------------------
; Clear framebuffer
; ----------------------------------------------------------------

		align 4
FrameClear:
		movem.l	d0/d1/d7/a1,-(a7)
		lea	($A15180).l,a1
.fm1
		bclr.b	#7,-$80(a1)		; MD access
		bne.b	.fm1
		move.w	#($20000/$200-1),d7
		moveq	#0,d0
		moveq	#0,d1
		move.w	#-1,$4(a1)		; Fill Length Reg.
.fill0:
		move.w	d1,$6(a1)		; Fill Start Address Reg.
		move.w	d0,$8(a1)		; Fill Data Reg.
		nop
.fen0:
		btst.b	#1,$B(a1)		; FEN = 0 ?
		bne.b	.fen0
		add.w	#$100,d1		; Address = +200H
		dbra	d7,.fill0
		movem.l	(a7)+,d0/d1/d7/a1
		rts

; ----------------------------------------------------------------
; Palette RAM Clear
; ----------------------------------------------------------------

PaletteClear:
		movem.l	d0/d7/a0,-(a7)
		lea	($A15200).l,a0
.fm2
		bclr.b	#7,-$100(a0)		; MD access
		bne.b	.fm2
		move.w	#(256/2/4-1),d7
.pl:
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d7,.pl
		movem.l	(a7)+,d0/d7/a0
		rts

; ----------------------------------------------------------------
; (Re)Start
; ----------------------------------------------------------------

RestartPrg:
		move.w	#19170,d7		; 8
.res_wait:
		dbra	d7,.res_wait		; 12*d7+10
		lea	($A15100).l,a1		; ----	Mars Register Initialize
		moveq	#0,d0			; ----	Communication Reg. Clear
		move.l	d0,$20(a1)		; 0
		move.l	d0,$24(a1)		; 4
		move.b	#3,$5101(a5)		; SH2 start
.fm3
		bclr.b	#7,(a1)			; MD access
		bne.b	.fm3
		moveq	#0,d0
		move.w	d0,2(a1)		; Interrupt Reg.
		move.w	d0,4(a1)		; Bank Reg.
		move.w	d0,6(a1)		; DREQ Control Reg.
		move.l	d0,8(a1)		; DREQ Source Address Reg.
		move.l	d0,$c(a1)		; DREQ Destination Address Reg.
		move.w	d0,$10(a1)		; DREQ Length Reg.
		move.w	d0,$30(a1)		; PWM Control
		move.w	d0,$32(a1)		; PWM fs Reg.
		move.w	d0,$38(a1)		; PWM Mono Reg.
		move.w	d0,$80(a1)		; Bitmap Mode Reg.
		move.w	d0,$82(a1)		; Shift Reg.
.fs0:						; ----	Mars Frame Buffer Clear
		bclr.b	#0,$8b(a1)		; FS = 0
		bne.b	.fs0
		bsr	FrameClear
.fs1:
		bset.b	#0,$8b(a1)		; FS = 1
		beq.b	.fs1
		bsr	FrameClear
		bclr.b	#0,$8b(a1)		; FS = 0
		bsr	PaletteClear		; ----	Palette RAM Clear
		move	#$80,d0			; ----	SH2 Check
		move.l	$20(a1),d1		; SDRAM Self Check
		cmp.l	#"SDER",d1
		beq	MarsError
		moveq	#0,d0			; ----	Communication Reg. Clear
		move.l	d0,$28(a1)		; 8
		move.l	d0,$2C(a1)		; 12
; 		movea.l	#-64,a6
; 		movem.l	(a6),d0/d3-d7/a0-a6
		move	#0,ccr			; Complete
		bra.b	IcdAllEnd
Hot_Start:
		lea	($A15100).l,a1
		move.w	d0,6(a1)		; DREQ Control Reg.
		move.w	#$8000,d0
		bra.b	IcdAllEnd
MarsError:
		move	#1,ccr			; Error
		vdp_showme $00E
		bra	*
IcdAllEnd:
; 		bcs	_error

; ----------------------------------------------------------------
; Send the entire SH2 code in split FrameBuffer sections
; ----------------------------------------------------------------

		lea	(sysmars_reg).l,a6
.wait_fb:
		bclr	#7,(a6)				; Set FM bit to MD
		bne.s	.wait_fb			; Wait until it accepts.
	; --------------------------------
	; FRAMEBUFFER 1
.wait_f1:	bset	#0,$8B(a6)			; Set BUFFER 1
		beq.s	.wait_f1
		lea	($840000).l,a1
		lea	($200000+($20000-$38)).l,a0	; Read SECOND half of SH2
		move.l	#(($20000)/4)-1,d7		; Size for this section
.send_half:
		move.l	(a0)+,(a1)+
		dbf	d7,.send_half
	; --------------------------------
	; FRAMEBUFFER 0
.wait_f0:	bclr	#0,$8B(a6)			; Set BUFFER 0
		bne.s	.wait_f0
		lea	($840000).l,a1
		lea	MarsInitHeader(pc),a0		; Module header
		move.w	#$0E-1,d7
.send_head:
		move.l	(a0)+,(a1)+
		dbf	d7,.send_head
		lea	($200000).l,a0			; Read the FIRST half of SH2
		move.l	#(($20000-$38)/4)-1,d7		; Size for this section
.send_code:
		move.l	(a0)+,(a1)+
		dbf	d7,.send_code
	; --------------------------------
.wait_adapter:
		bset	#7,(a6)				; Set FM bit to 32X
		beq.s	.wait_adapter
		lea	($A15100).l,a6
		move.l	#"_CD_",$20(a6)			; Write CD32X boot flag.
.wait_f1fb:	btst	#7,$8A(a6)			; Wait SVDP's VBlank
		beq.s	.wait_f1fb
.master:	cmp.l	#"M_OK",$20(a6)			; Check SH2 status tags
		bne.s	.master
.slave:		cmp.l	#"S_OK",$24(a6)
		bne.s	.slave
.wait_mstr:	move.l	$20(a6),d0			; Status tags cleared?
		bne.s	.wait_mstr
.wait_slv:	move.l	$24(a6),d0
		bne.s	.wait_slv
		lea	(vdp_ctrl).l,a6
		move.l	#$80048104,(a6)			; Default top VDP regs
		moveq	#0,d0				; Clear both Master and Slave comm's
		move.l	d0,comm12(a5)
		move.w	#$FF,d7				; Delay until SH2 gets first.
.wait_sh2:
		move.w	#$7F,d6
		dbf	d6,*
		dbf	d7,.wait_sh2
		bra	MarsJumpHere

; ----------------------------------------------------------------
; MARS CD header
; ----------------------------------------------------------------
MarsInitHeader:
		dc.b "MARS CDROM      "			; Module name
		dc.l $00000000				; Version
		dc.l $00000000				; Not Used
		dc.l $06000000				; SDRAM area
	if EMU
		dc.l MARS_RAMCODE_E-MARS_RAMCODE	; <-- Fusion needs full size, this will breaks on HW.
	else
		dc.l $1FFC8				; SDRAM code size, maximum: $1FFC8
	endif
		dc.l SH2_M_Entry			; Master SH2 PC (SH2 area)
		dc.l SH2_S_Entry			; Slave SH2 PC (SH2 area)
		dc.l SH2_Master				; Master SH2 default VBR
		dc.l SH2_Slave				; Slave SH2 default VBR
		dc.l $00000000				; Not Used
		dc.l $00000000				; Not Used
		align 2
; ----------------------------------------------------------------
MarsJumpHere:
