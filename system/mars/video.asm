; ===========================================================================
; ----------------------------------------------------------------
; 32X Video, MASTER side.
;
; SOME routines are located on the cache for speed reasons.
; ----------------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

SET_MSCRLSIZE		equ 16		; !! Hard-coded, can't change for now.
SET_MSCRLWDTH		equ 320		; Affects scrolling and SuperSprites
SET_MSCRLHGHT		equ 240		;                 ''
SET_FBVRAM_BLANK	equ $1FD80	; Framebuffer location of the BLANK line
SET_FBVRAM_PATCH	equ $1E000	; Framebuffer location to store the affected XShift lines.

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

; ** see shared.asm

; ====================================================================
; --------------------------------------------------------
; Init MARS Video
;
; Breaks:
; r1-r4
; --------------------------------------------------------

		align 4
MarsVideo_Init:
		mov	#_sysreg,r1
		mov 	#FM,r0				; Set SuperVDP permission for SH2
  		mov.b	r0,@(adapter,r1)		; ** The Genesis side will write the palette**
		mov	#_vdpreg,r1
		mov	#0,r0				; BLANK mode
		mov.b	r0,@(bitmapmd,r1)
		mov	#SET_MSCRLWDTH+SET_MSCRLSIZE,r1	; Set scroll-area settings
		mov	#SET_MSCRLHGHT+SET_MSCRLSIZE,r2
		mulu	r1,r2
		mov	r1,r0
		mov	r0,@(marsGbl_Scrl_Wdth,gbr)
		mov	r2,r0
		mov	r0,@(marsGbl_Scrl_Hght,gbr)
		sts	macl,r0
		mov	r0,@(marsGbl_Scrl_Size,gbr)
		mov	#$200,r0
		mov	r0,@(marsGbl_Scrl_FbOut,gbr)
		mov	#0,r0
		mov.w	r0,@(marsGbl_ThisFrame,gbr)
		mov	r0,@(marsGbl_Scrl_FbY,gbr)
		mov	r0,@(marsGbl_Scrl_FbTL,gbr)
; 		mov	r0,@(marsGbl_Scrl_Xpos,gbr)	; break on HW on reset
; 		mov	r0,@(marsGbl_Scrl_Ypos,gbr)
		rts
		nop
		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_FixTblShift
;
; Fix the affected $xxFF lines by scrolling using the
; linetable. MUST call this BEFORE flipping
; the Framebuffer.
;
; Input:
; r1 | Start line
; r2 | Number of lines
; r3 | Location for the fixed lines
;
; Breaks:
; r7-r14
; --------------------------------------------------------

		align 4
MarsVideo_FixTblShift:
		mov	#_vdpreg,r14
		mov.b	@(bitmapmd,r14),r0		; Check if we are on indexed mode
		and	#%11,r0
		cmp/eq	#1,r0
		bf	.ptchset
		mov.w	@(marsGbl_XShift,gbr),r0	; XShift is set? (EXTERNAL value)
		and	#1,r0
		tst	r0,r0
		bt	.ptchset

		mov	#_framebuffer,r14		; r14 - Framebuffer BASE
		mov	r14,r12				; r12 - Framebuffer output for the patched pixel lines
		add	r3,r12
		mov	r1,r0
		shll2	r0
		add	r0,r14
		mov	r14,r13				; r13 - Framebuffer lines to check
		mov	r2,r11				; r11 - Lines to check
		mov	#-1,r0
		extu.b	r0,r10				; r10 - AND byte to check ($FF)
		extu.w	r0,r9				;  r9 - AND word limit ($FFFF)
.loop:
		mov.w	@r13,r0
		and	r9,r0
		mov	r0,r7
		and	r10,r0
		cmp/eq	r10,r0
		bf	.tblexit
		shll	r7
		add	r14,r7
		mov	r12,r0
		shlr	r0
		mov.w	r0,@r13
		mov	#(320+4)/2,r3
.copy:
		mov.w	@r7,r0
		mov.w	r0,@r12
		add	#2,r7
		dt	r3
		bf/s	.copy
		add	#2,r12
.tblexit:
		dt	r11
		bf/s	.loop
		add	#2,r13
.ptchset:
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 2D scrolling-area section
; ----------------------------------------------------------------

; ----------------------------------------------------------------
; MarsVideo_MapDrawAll
;
; Draw the scrolling area to the framebuffer
;
; Input:
; r14 | Framebuffer output
; r13 | Scroll size W*H
; r12 | Scroll height
; r11 | Scroll width
; r10 | Scroll TL-pos read / 16 *
;  r9 | Scroll Y-pos read / 16 *
;  r8 | Graphics data
;  r7 | Map data
;  r6 | Map Y read index
;  r5 | Map X read index
;
; ** CPU HEAVY ROUTINE **
; ----------------------------------------------------------------

		align 4
MarsVideo_MapDrawAll:
		sts	pr,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r9,@-r15
		mov	r10,@-r15

		mov	r9,r0
		mov	#-16,r4
		and	r4,r0
		muls	r0,r11
		sts	macl,r0		; Y block pos
		mov	r10,r4
		add	r0,r4
		mov	#-4,r2
		and	r2,r4

		mov	r11,r10
		shlr2	r10
		shlr2	r10
.x_loop:
		mov	r6,r9
		cmp/ge	r13,r4
		bf	.tl_snap
		sub	r13,r4
.tl_snap:
		mov	r4,r2
		mov	r12,r3
		shlr2	r3
		shlr2	r3
.y_loop:
		lds	r3,mach
		lds	r4,macl
		mov	#(256/16)-1,r3
		mov	r9,r4		; Y pos
		shlr2	r4
		shlr2	r4
		and	r3,r4
		shll2	r4
		shll2	r4
		shll	r4
		mov	#(512/16)-1,r3
		mov	r5,r0		; X pos
		shlr2	r0
		shlr2	r0
		and	r3,r0
		add	r4,r0
		shll	r0
		mov	r7,r3
		add	r0,r3
		mov	#$7FF,r1
		mov.w	@r3,r0
		mov	r0,r3
		and	r1,r3
		mov	#0,r1
		tst	r3,r3
		bt	.blank
		dt	r3
		shll8	r3		; 16x16
		mov	r3,r1
		add	r8,r1
.blank:
		sts	macl,r4
		sts	mach,r3
		bsr	scrlDrw_DrawBlk
		mov	r4,@-r15
		mov	@r15+,r4
		dt	r3
		bf/s	.y_loop
		add	#16,r9
		add	#16,r4
		dt	r10
		bf/s	.x_loop
		add	#16,r5
.exit_lr:
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r6
		mov	@r15+,r5
		lds	@r15+,pr
		rts
		nop
		align 4

; ----------------------------------------------------------------
; MarsVideo_MapScrlLR
;
; Draws Left or Right scroll areas outside of
; the screen.
;
; Input:
; r14 | Framebuffer output
; r13 | Scroll size W*H
; r12 | Scroll height
; r11 | Scroll width
; r10 | Scroll TL-pos read
;  r9 | Scroll Y-pos read
;  r8 | Graphics data
;  r7 | Map data
;  r6 | Y pos
;  r5 | X pos
; ----------------------------------------------------------------

		align 4
MarsVideo_MapScrlLR:
		sts	pr,@-r15
		mov	r5,@-r15
		mov	r6,@-r15

		tst	r8,r8
		bt	.exit_lr
		mov	#0,r3
		mov	@(marsGbl_Scrl_DrwL,gbr),r0
		tst	r0,r0
		bf	.dir_l
		mov	#SET_MSCRLWDTH,r3
		mov	@(marsGbl_Scrl_DrwR,gbr),r0
		tst	r0,r0
		bf	.dir_r
		bra	.exit_lr
		nop	; align
		nop
.dir_l:
		dt	r0
		bra	.go_lr
		mov	r0,@(marsGbl_Scrl_DrwL,gbr)
.dir_r:
		dt	r0
		mov	r0,@(marsGbl_Scrl_DrwR,gbr)
.go_lr:
		add	r3,r5
		mov	r9,r0
		mov	#-16,r2
		and	r2,r0
		muls	r0,r11
		sts	macl,r0		; Y block pos
		mov	r10,r2
		add	r3,r2
		add	r0,r2
		mov	#-16,r3
		and	r3,r2

		mov	r12,r3
		shlr2	r3
		shlr2	r3
.y_loop:
		lds	r3,mach
		lds	r4,macl

		mov	#(256/16)-1,r3
		mov	r6,r4	; Y pos
		shlr2	r4
		shlr2	r4
		and	r3,r4
		shll2	r4
		shll2	r4
		shll	r4
		mov	#(512/16)-1,r3
		mov	r5,r0	; X pos
		shlr2	r0
		shlr2	r0
		and	r3,r0
		add	r4,r0
		shll	r0
		mov	r7,r3
		add	r0,r3

		mov	#$7FF,r1
		mov.w	@r3,r0
		mov	r0,r3
		and	r1,r3
		mov	#0,r1
		tst	r3,r3
		bt	.blank
		dt	r3
		shll8	r3		; 16x16
		mov	r3,r1
		add	r8,r1
.blank:
		sts	macl,r4
		sts	mach,r3
		bsr	scrlDrw_DrawBlk
		mov	r4,@-r15
		mov	@r15+,r4
		dt	r3
		bf/s	.y_loop
		add	#16,r6
.exit_lr:
		mov	@r15+,r6
		mov	@r15+,r5
		lds	@r15+,pr
		rts
		nop
		align 4

; ----------------------------------------------------------------
; MarsVideo_MapScrlUD
;
; Draws Up or Down scroll areas outside of
; the screen.
;
; Input:
; r14 | Framebuffer output
; r13 | Scroll size W*H
; r12 | Scroll height
; r11 | Scroll width
; r10 | Scroll TL-pos read
;  r9 | Scroll Y-pos read
;  r8 | Graphics data
;  r7 | Map data
;  r6 | Y pos
;  r5 | X pos
; ----------------------------------------------------------------

		align 4
MarsVideo_MapScrlUD:
		sts	pr,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		tst	r8,r8
		bt	.exit_ud
		mov	#0,r3
		mov	@(marsGbl_Scrl_DrwU,gbr),r0
		tst	r0,r0
		bf	.dir_u
		mov	#SET_MSCRLHGHT,r3
		mov	@(marsGbl_Scrl_DrwD,gbr),r0
		tst	r0,r0
		bf	.dir_d
		bra	.exit_ud
		nop
		nop
.dir_u:
		dt	r0
		bra	.go_ud
		mov	r0,@(marsGbl_Scrl_DrwU,gbr)
.dir_d:
		dt	r0
		mov	r0,@(marsGbl_Scrl_DrwD,gbr)
.go_ud:
		add	r3,r6
		mov	r9,r0
		add	r3,r0
		mov	#-16,r4
		and	r4,r0
		muls	r0,r11
		sts	macl,r0		; Y block pos
		mov	r10,r4
		add	r0,r4
		mov	#-16,r3
		and	r3,r4
		mov	r11,r3
		shlr2	r3
		shlr2	r3
.y_loop:
		mov	r4,r2
		lds	r3,mach
		lds	r4,macl
		mov	#(256/16)-1,r3
		mov	r6,r4	; Y pos
		shlr2	r4
		shlr2	r4
		and	r3,r4
		shll2	r4
		shll2	r4
		shll	r4
		mov	#(512/16)-1,r3
		mov	r5,r0	; X pos
		shlr2	r0
		shlr2	r0
		and	r3,r0
		add	r4,r0
		shll	r0
		mov	r7,r3
		add	r0,r3

		mov	#$7FF,r1
		mov.w	@r3,r0
		mov	r0,r3
		and	r1,r3
		mov	#0,r1
		tst	r3,r3
		bt	.blank_lr
		dt	r3
		shll8	r3		; 16x16
		mov	r3,r1
		add	r8,r1
.blank_lr:
		sts	macl,r4
		sts	mach,r3
		nop ; align
		bsr	scrlDrw_DrawBlk
		mov	r4,@-r15
		mov	@r15+,r4
		add	#16,r4	; <--
		dt	r3
		bf/s	.y_loop
		add	#16,r5
.exit_ud:
		mov	@r15+,r6
		mov	@r15+,r5
		lds	@r15+,pr
		rts
		nop
		align 4
; 		ltorg

; --------------------------------------------------------
; MarsVideo_ShowScrlBg
;
; Make a visible section of any scrolling area
; into the current framebuffer.
;
; Input:
; r1 | Top Y
; r2 | Bottom Y
;
; Breaks:
; r4-r14
;
; NOTE:
; After finishing all your screens call
; MarsVideo_FixTblShift before doing frameswap
; --------------------------------------------------------

		align 4
MarsVideo_ShowScrlBg:
		mov	#_framebuffer,r14		; r14 - Framebuffer BASE
		mov	#0,r11				; r11 - line counter
		mov	@(marsGbl_Scrl_FbOut,gbr),r0	; r13 - Framebuffer pixeldata position
		mov	r0,r13
		mov	@(marsGbl_Scrl_Size,gbr),r0	; r12 - Full size of screen-scroll
		mov	r0,r12
		mov	@(marsGbl_Scrl_Wdth,gbr),r0
		mov	r0,r10
		mov	@(marsGbl_Scrl_FbTL,gbr),r0
		mov	r0,r9
		mov	@(marsGbl_Scrl_FbY,gbr),r0
		mov	r0,r8
		cmp/eq	r2,r1
		bt	.bad_y
		cmp/ge	r2,r1
		bt	.bad_y
		mov	r1,r6
		mov	r1,r0
		shll	r0
		add	r0,r14
		mulu	r10,r8
		sts	macl,r0
		add	r0,r9
.ln_loop:
		mov	r9,r8
		cmp/ge	r12,r8
		bf	.xl_r
		sub	r12,r8
.xl_r:
; 		cmp/pz	r8
; 		bt	.xl_l
; 		add	r12,r8
; .xl_l:
		mov	r8,r9
		add	r10,r9			; Add Y
		add	r13,r8			; Add Framebuffer position
		shlr	r8			; Divide by 2, use Xshift for the missing bit
		mov.w	r8,@r14			; Send to FB's table
		add	#2,r14
		add	#2,r11
		cmp/eq	r2,r6
		bf/s	.ln_loop
		add	#1,r6
.bad_y:
		rts
		nop
		align 4

; --------------------------------------------------------
; Call this AFTER after drawing anything to the
; scrolling area.
; --------------------------------------------------------

		align 4
marsScrl_CopyTopBot:
		mov	@(marsGbl_Scrl_FbOut,gbr),r0
		mov	r0,r1
		mov	@(marsGbl_Scrl_Size,gbr),r0
		mov	r0,r3
		mov	#_framebuffer,r0
		add	r0,r1
		mov	r1,r2
		add	r3,r2
		mov	#320/4,r3
		nop
.copy_top:
		mov	@r1+,r0
		nop
		mov	r0,@r2
		add	#4,r2
		dt	r3
		bf	.copy_top
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Super sprites
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_SuperSpr_Draw
; --------------------------------------------------------

		align 4
MarsVideo_SuperSpr_Draw:
		sts	pr,@-r15
		mov	#_overwrite,r14	; <--
		mov	@(marsGbl_Scrl_Size,gbr),r0
		mov	r0,r13
		mov	@(marsGbl_Scrl_Hght,gbr),r0
		mov	r0,r12
		mov	@(marsGbl_Scrl_Wdth,gbr),r0
		mov	r0,r11
		mov	@(marsGbl_Scrl_FbTL,gbr),r0
		mov	r0,r10
		mov	@(marsGbl_Scrl_FbY,gbr),r0
		mov	r0,r9
		mov	@(marsGbl_Scrl_FbOut,gbr),r0
		mov	r0,r2
		mov	@(marsGbl_DreqRead,gbr),r0
		add	r2,r14
		mov	#Dreq_SuperSpr,r8
		add	r0,r8

	; ----------------------------------------
	; r14 - Framebuffer output
	; r13 - Scroll size W*H
	; r12 - Scroll height
	; r11 - Scroll width
	; r10 - Scroll TL-pos read *
	;  r9 - Scroll Y-pos read *
	;  r8 - Current SuperSprite
	;  r7 - Current Canvas box addr
	;  r6 - Numof sprites
	;  r5 - Index counter
	;  r4 -
	;  r3 -
	;  r2 -

		mov	#MAX_MARSSPR,r7
.next_sspr:
		mov	@(sspr_Art,r8),r0
		tst	r0,r0
		bt	.off_sspr
		lds	r0,mach
		mov.w	@(sspr_Flags,r8),r0
		extu.w	r0,r6
		mov.w	@(sspr_Size,r8),r0
		extu.b	r0,r5			; Y size
		shlr8	r0
		extu.b	r0,r4			; X size
		mov.w	@(sspr_Xpos,r8),r0
		exts.w	r0,r2
		mov.w	@(sspr_Ypos,r8),r0
		exts.w	r0,r3
		add	#1,r4
		add	#1,r5
		shll2	r4		; Expand sizes to 8pixels
		shll2	r5
		shll	r4
		shll	r5
		mov	r2,r0		; Offscreen checks
		add	r4,r0
		cmp/pl	r0
		bf	.off_sspr
		mov	r3,r0
		add	r5,r0
		cmp/pl	r0
		bf	.off_sspr
		mov	#SET_MSCRLWDTH>>2,r0
		shll2	r0
		cmp/ge	r0,r2
		bt	.off_sspr
		mov	#SET_MSCRLHGHT>>2,r0
		shll2	r0
		cmp/ge	r0,r3
		bt	.off_sspr
		sts	mach,r1
		bsr	scrlDrw_SSprDraw
		nop
.off_sspr:
		mov	#sizeof_marsspr,r0
		dt	r7
		bf/s	.next_sspr
		add	r0,r8
.exit_sspr:

		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; MarsVideo_MkFillBlk
;
; Generate Block-Refill blocks from Super sprites
; for the next frame
;
; 16x16 blocks.
; --------------------------------------------------------

		align 4
MarsVideo_MkFillBlk:
		sts	pr,@-r15
		mov	#Dreq_SuperSpr,r14
		mov	@(marsGbl_DreqRead,gbr),r0
		add	r0,r14
		mov	#RAM_Mars_ScrlRefill_0,r13
		mov	#MAX_MARSSPR,r12
.next_sspr:
		mov	@(sspr_Art,r14),r0
		tst	r0,r0
		bt	.off_sspr
		nop
		mov.w	@(sspr_Size,r14),r0
		extu.b	r0,r5			; Y size
		shlr8	r0
		extu.b	r0,r4			; X size
		mov.w	@(sspr_Frame,r14),r0
		extu.w	r0,r1
		mov.w	@(sspr_Xpos,r14),r0
		exts.w	r0,r2
		mov.w	@(sspr_Ypos,r14),r0
		exts.w	r0,r3
		shlr	r4		; /2 for 16
		shlr	r5
		add	#1,r4
		add	#1,r5
		mov	@(marsGbl_Scrl_Xpos,gbr),r0
		exts.w	r0,r8
		mov	#16-1,r6	; MANUAL SIZE 16x16
		nop
		mov	@(marsGbl_Scrl_Ypos,gbr),r0
		exts.w	r0,r9
		mov	r2,r0
		add	r8,r0
		and	r6,r0
		tst	r0,r0
		bt	.x_szex
		add	#1,r4
.x_szex:
		mov	r3,r0
		add	r9,r0
		and	r6,r0
		tst	r0,r0
		bt	.y_szex
		add	#1,r5
.y_szex:
		shll2	r4		; Expand sizes to 16pixels
		shll2	r4
		shll2	r5
		shll2	r5

		add	r2,r4
		add	r3,r5
		mov	#SET_MSCRLWDTH>>2,r6
		mov	#SET_MSCRLHGHT>>2,r7
		shll2	r6
		shll2	r7
	; Off-screen limits
		cmp/pl	r4
		bf	.off_sspr
		cmp/pl	r5
		bf	.off_sspr
		cmp/ge	r6,r2		; Xleft < 0?
		bt	.off_sspr
		cmp/ge	r7,r3		; Yup < 0?
		bt	.off_sspr
	; Squeeze screen coords
		add	#16,r6
		add	#16,r7
		cmp/pl	r2
		bt	.x_sqz
		mov	#0,r2
.x_sqz:		cmp/pl	r3
		bt	.y_sqz
		mov	#0,r3
.y_sqz:		cmp/ge	r6,r4
		bf	.x_sqend
		mov	r6,r4
.x_sqend:	cmp/ge	r7,r5
		bf	.y_sqend
		mov	r7,r5
.y_sqend:

	; r2 - X pos
	; r3 - Y pos
	; r4 - X end
	; r5 - Y end
.y_row:
		mov	r2,r6
.x_row:
		mov	r3,r0
		add	r9,r0
		shlr2	r0
		shlr2	r0
		and	#(256/16)-1,r0
		shll2	r0
		shll2	r0
		shll2	r0
		mov	r0,r7
		mov	r6,r0
		add	r8,r0
		shlr2	r0
		shlr2	r0
		and	#(512/16)-1,r0
		shll	r0
		add	r0,r7
		add	r13,r7
		mov	#%11,r0		; Write flag
		mov.w	r0,@r7
		add	#16,r6
		cmp/ge	r4,r6
		bf	.x_row
		add	#16,r3
		cmp/ge	r5,r3
		bf	.y_row

.off_sspr:
		mov	#sizeof_marsspr,r0
		dt	r12
		bf/s	.next_sspr
		add	r0,r14

.exit_sspr:
		lds	@r15+,pr
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_DrawFillBlk
;
; r14 - Framebuffer output
; r13 - Scroll size W*H
; r12 - Scroll height
; r11 - Scroll width
; r10 - Scroll TL-pos read / 16 *
;  r9 - Scroll Y-pos read / 16 *
;  r8 - Graphics data
;  r7 - Map data
;  r6 - Map Y read index
;  r5 - Map X read index
; --------------------------------------------------------

		align 4
MarsVideo_DrawFillBlk:
		sts	pr,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r9,@-r15
		mov	r10,@-r15
		mov.w	@(marsGbl_SSprFlip,gbr),r0
		mov	#RAM_Mars_ScrlRefill_0,r3
		mov	r9,r0
		mov	#-16,r4
		and	r4,r0
		muls	r0,r11
		sts	macl,r0		; Y block pos
		mov	r10,r4
		add	r0,r4
		mov	#-4,r2
		and	r2,r4

		mov	r11,r10
		shlr2	r10
		shlr2	r10
.x_loop:
		mov	r6,r9
		cmp/ge	r13,r4
		bf	.tl_snap
		sub	r13,r4
.tl_snap:
		mov	r4,r2
		mov	r4,@-r15
		mov	r12,@-r15
		shlr2	r12
		shlr2	r12
.y_loop:
		mov	#(256/16)-1,r0
		mov	r9,r4		; Y pos
		shlr2	r4
		shlr2	r4
		and	r0,r4
		shll2	r4
		shll2	r4
		shll	r4
		mov	#(512/16)-1,r0
		mov	r5,r1		; X pos
		shlr2	r1
		shlr2	r1
		and	r0,r1
		add	r4,r1
		shll	r1
		lds	r1,macl

		add	r3,r1
		mov.w	@r1,r0
		tst	r0,r0
		bt	.no_flag
		shlr	r0
		mov.w	r0,@r1

		sts	macl,r1
		add	r7,r1
		lds	r3,mach
		mov.w	@r1,r0
		mov	#$7FF,r1
		mov	r0,r3
		and	r1,r3
		mov	#0,r1
		tst	r3,r3
		bt	.blank
		dt	r3
		shll8	r3		; 16x16
		mov	r3,r1
		add	r8,r1
.blank:
		sts	mach,r3
; 		mov	#0,r1	; TEMPORAL
		bsr	scrlDrw_DrawBlk
		mov	r4,@-r15
		mov	@r15+,r4
		bra	.next_yblk
		nop
.no_flag:
		mov	#16,r0
		mulu	r11,r0
		sts	macl,r0
		add	r0,r2
.next_yblk:
		dt	r12
		bf/s	.y_loop
		add	#16,r9
		mov	@r15+,r12
		mov	@r15+,r4
		add	#16,r4
		dt	r10
		bf/s	.x_loop
		add	#16,r5
.exit_lr:
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r6
		mov	@r15+,r5
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; scrlDrw_SSprDraw
;
; Inputs:
; r1 - Graphics data *
; r2 - Xpos *
; r3 - Ypos *
; r4 - Xsize *
; r5 - Ysize *
; r6 - Flags *
;
; In Loop:
; r14 - Framebuffer output
; r13 - Scroll size W*H
; r12 - Scroll height
; r11 - Scroll width
; r10 - Scroll TL-pos read
;  r9 - Scroll Y-pos read
;
; Breaks:
; r1-r6
; --------------------------------------------------------

		align 4
scrlDrw_SSprDraw:
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		mov	r10,@-r15
		mov	r12,@-r15

	; Y limits
		mov	r3,r0
.y_low:		cmp/pz	r0
		bt	.y_mid
		mov	#0,r0
.y_mid:		cmp/ge	r12,r0
		bf	.y_ok
		mov	#(SET_MSCRLHGHT)>>2,r0	; 240
		shll2	r0
.y_ok:
		add	r9,r0
		muls	r11,r0	; macl - Y pos
	; No X limits
		mov	r2,r7	; X-pos
		add	r10,r7
		sts	macl,r0
		add	r0,r7
		cmp/ge	r13,r7
		bf	.xy_flip
		sub	r13,r7
.xy_flip:
		mov	r6,r0		; Y flip? start
		tst	#%10,r0
		bt	.y_flip
		muls	r4,r5
		sts	macl,r0
		add	r0,r1		; Flip Y src
		sub	r4,r1
.y_flip:
		mov	#4,r8
		mov	r6,r0		; X flip?
		tst	#%01,r0
		bt	.x_flip
		neg	r8,r8
		mov	r4,r0
		add	#-4,r0
		add	r0,r1
.x_flip:

	; ---------------------------------------
	; LOOP
	; ---------------------------------------
		cmp/pz	r3
		bt	.y_top
		add	r3,r5
		muls	r4,r3
		mov	r6,r0
		tst	#%10,r0
		bt	.y_rflip
		sts	macl,r0
		bra	.y_rflipc
		neg	r0,r0
.y_rflip:
		sts	macl,r0
.y_rflipc:
		sub	r0,r1

.y_top:
		mov	r3,r0
		add	r5,r0
; 		mov	#240,r10
		mov	#(SET_MSCRLHGHT+4)>>2,r10	; 240
		shll2	r10
		cmp/ge	r10,r0
		bf	.y_bot
		sub	r10,r0
		sub	r0,r5
.y_bot:
		nop
		mov	r4,r10
		mov	r6,r0		; Y flip? start
		tst	#%10,r0
		bt	.y_loop
		neg	r4,r4

	; r1 - Frame data line pos
	; r2 - X pos
	; r3 -
	; r4 - Y increment f/b
	; r5 - Y lines / X current beam
	; r6 - flags (X flip only)
	; r7 - current TL pos
	; r8 - X increment f/b
	; r9 -
	; r10 - X loop current
	; r11
	; r12
.y_loop:
		lds	r7,mach
		lds	r5,macl
		mov	r10,r12
		shlr2	r12
		tst	r12,r12
		bt	.y_last
		mov	r1,r3		; Line in
		mov	r2,r5
.x_loop:
		cmp/ge	r13,r7
		bf	.tl_snap
		sub	r13,r7
.tl_snap:

; ---------------------------------------
; r3 - Pixel data pos
; r5 - Current X pos
;
; r9 - Pixel data $12345678

.x_swap:
		mov	@r3,r9		; 11 22 33 44
		mov	r6,r0
		tst	#%01,r0
		bt	.x_mswap
		swap.b	r9,r9
		swap.w	r9,r9
		swap.b	r9,r9
.x_mswap:
		cmp/pz	r5
		bf	.x_left
		mov	#SET_MSCRLWDTH-4,r0
		cmp/gt	r0,r5
		bf	.x_mid

; ---------------------------------------
; RIGHT SIDE
;
; r5 is lost after this
; ---------------------------------------

		mov	r5,r0
		and	#%011,r0
		tst	r0,r0
		bt	.x_end
		mov	#4,r5
		sub	r0,r5
		swap.b	r9,r9	; 1 2 4 3
		swap.w	r9,r9	; 4 3 1 2
		swap.b	r9,r9	; 4 3 2 1
		mov	r7,r0
		add	r14,r0
		mov.b	r9,@r0
		shlr8	r9
		add	#1,r0
		dt	r5
		bt	.x_end
		mov.b	r9,@r0
		shlr8	r9
		add	#1,r0
		dt	r5
		bt	.x_end
		bra	.x_end
		mov.b	r9,@r0

; ---------------------------------------
; LEFT SIDE
; ---------------------------------------

.x_left:
		mov	#-4,r0
		cmp/gt	r0,r5
		bf	.xl_far
		neg	r5,r0
		add	#3,r0
		add	r5,r0
		and	#%011,r0
		add	#1,r0
		add	r7,r0
		add	r14,r0
		add	#4,r5
	rept 3
		mov.b	r9,@-r0
		shlr8	r9
		dt	r5
		bt	.xl_far
	endm
		mov	#-4,r0
		and	r5,r0
.xl_far:
		bra	.x_bad
		add	#4,r5

; ---------------------------------------
; MIDDLE SIDE
; ---------------------------------------

.x_mid:
		mov	r7,r0
		add	r14,r0
		add	#4,r0
		mov.b	r9,@-r0
		shlr8	r9
		mov.b	r9,@-r0
		shlr8	r9
		mov.b	r9,@-r0
		shlr8	r9
		mov.b	r9,@-r0
		add	#4,r5
.x_bad:
		add	r8,r3
		dt	r12
		bf/s	.x_loop
		add	#4,r7
.x_end:

; ---------------------------------------
		sts	macl,r5
		sts	mach,r7
		add	r4,r1		; Next line FOWARD
		dt	r5
		bf/s	.y_loop
		add	r11,r7
.y_last:

.y_end:
		mov	@r15+,r12
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; scrlDrw_DrawBlk
;
; Currents:
; r0 - Block data and index flags (if r1 != 0)
; r1 - Graphics data, 0 = blank mode
; r2 - FB TL position
;
; InLoop:
; r14 - Framebuffer BASE
; r13 - Scrl W*H
; r11 - Scrl width
;
; Uses:
; r4,macl,mach
; --------------------------------------------------------

		align 4
scrlDrw_DrawBlk:
		cmp/pl	r1
		bf	.blank
		bra	.normal
		nop
; TODO: CHECAR ESTO EN HARDWARE
.blank:
		mov	#0,r0
		mov	#16,r4
.blnk_line:
		cmp/ge	r13,r2
		bf	.tl_snapb
; 		bra	.blnk_line		; <-- Broken
		sub	r13,r2
.tl_snapb:
		lds	r2,macl
		add	r14,r2
	rept 16/4
		mov	r0,@r2
		add	#4,r2
	endm
		sts	macl,r2
		dt	r4
		bf/s	.blnk_line
		add	r11,r2
		rts
		nop
		align 4

; ----------------------------------------

.normal:
		lds	r3,mach
		shlr8	r0		; Get index increment
		and	#$F8,r0		; Filter these bits only
		mov	r0,r3
		mov	#16,r4
.next_line:
		cmp/ge	r13,r2
		bf	.tl_snap
		bra	.next_line
		sub	r13,r2
.tl_snap:
		lds	r2,macl
		add	r14,r2
	rept 16/4
		mov	@r1,r0
		swap.w	r0,r0		; 3 4 1 2
		swap.b	r0,r0		; 3 4 2 1
		tst	#$FF,r0
		bt	.z_0
		add	r3,r0
.z_0:		swap.b	r0,r0		; 3 4 1 2
		tst	#$FF,r0
		bt	.z_1
		add	r3,r0
.z_1:		swap.w	r0,r0		; 1 2 3 4
		swap.b	r0,r0		; 1 2 4 3
		tst	#$FF,r0
		bt	.z_2
		add	r3,r0
.z_2:		swap.b	r0,r0		; 1 2 3 4
		tst	#$FF,r0
		bt	.z_3
		add	r3,r0
.z_3:
		add	#4,r1		; <-- src incr
		mov	r0,@r2
		add	#4,r2
	endm
		sts	macl,r2
		dt	r4
		bf/s	.next_line
		add	r11,r2

		sts	mach,r3
		rts
		nop
		align 4
		ltorg
