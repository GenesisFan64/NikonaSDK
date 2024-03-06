; ====================================================================
; ----------------------------------------------------------------
; Fade-out effect on boot
;
; ROUTINE CALLS CAN'T BE USED HERE.
; ----------------------------------------------------------------

; 		lea	(vdp_data),a6
; 		lea	(RAM_Palette).w,a5	; <- Use this RAM section
; 		move.w	#$8144,4(a6)		; Enable display
; .wait_in:	move.w	4(a6),d7		; Vblank started?
; 		btst	#bitVBlk,d7
; 		beq.s	.wait_in
; 		move.l	a5,a4			; a4 - RAM palette
; 		move.l	#$40000010,4(a6)	; VDP: Palette READ
; 		moveq	#64-1,d7		; d7 - Palette number
; 		move.w	d7,d6
; .copy_pal:	move.w	(a6),d0
; 		move.w	d0,(a4)+
; 		dbf	d7,.copy_pal
; 		moveq	#-1,d4
;
; 	; Fade-out now
; .wait_vblk:	move.w	4(a6),d0
; 		btst	#bitVBlk,d0
; 		beq.s	.wait_vblk
; 		tst.w	d4
; 		beq.s	.finish_now
; 		move.l	#$C0000000,4(a6)	; VDP: Palette WRITE
; 		move.w	d7,d6
; 		move.l	a5,a4
; 		moveq	#0,d4
; .write_pal:
; 		move.w	(a4)+,d0
; 		move.w	d0,d1
;
;
;
; 		or.w	d0,d4
; 		move.w	d0,(a6)
; 		dbf	d6,.write_pal
; 		bra.s	.wait_vblk
;
; .finish_now:
; ; 		move.l	a5,a4
; 		bra *
