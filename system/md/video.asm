; ===========================================================================
; ----------------------------------------------------------------
; Genesis VDP section
; ----------------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_MDOBJ	equ 24		; MAX Objects
MAX_MDDMATSK	equ 24		; MAX DMA BLAST entries
SET_NullVram	equ $07FF	; Default Blank cell
SET_PrintVram	equ $0580	; Default VRAM location of the PRINT text graphics
SET_DefAutoDma	equ $0480	; Default VRAM location for auto-DMA storage
SET_PrintPal	equ 3		; Palette line to use for the printable text

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; ------------------------------------------------
; VDP Register $80
; ------------------------------------------------

HVStop		equ $02
HintEnbl	equ $10
bitHVStop	equ 1
bitHintEnbl	equ 4

; ------------------------------------------------
; VDP Register $81
; ------------------------------------------------

DispEnbl 	equ $40
VintEnbl 	equ $20
DmaEnbl		equ $10
bitDispEnbl	equ 6
bitVintEnbl	equ 5
bitDmaEnbl	equ 4
bitV30		equ 3

; ------------------------------------------------
; vdp_ctrl READ bits (full WORD)
; ------------------------------------------------

bitFifoE	equ 9		; DMA FIFO empty
bitFifoF	equ 8		; DMA FIFO full
bitVInt		equ 7		; Vertical interrupt
bitSprOvr	equ 6		; Sprite overflow
bitSprCol	equ 5		; Sprite collision
bitOdd		equ 4		; EVEN or ODD frame displayed on interlace mode
bitVBlk		equ 3		; Inside VBlank
bitHBlk		equ 2		; Inside HBlank
bitDma		equ 1		; This bit only works on FILL and COPY
bitPal		equ 0

; ====================================================================
; ----------------------------------------------------------------
; Structs
; ----------------------------------------------------------------

; ------------------------------------------------
; Genesis object
;
; obj_set: %M--- --vh
; 	| M - Draw this object on
;             Genesis or 32X
; 	| h - Flip Y
; 	| v - Flip X
;
; obj_size: $uuddllrr
; 	| u - Up/8
; 	| d - Down/8
; 	| l - Left/8
; 	| r - Right/8
; ------------------------------------------------

		strct 0
obj_code	ds.l 1		; Object code, If 0 slot is unused.
obj_x		ds.l 1		; Object X Position $xxxx.0000
obj_y		ds.l 1		; Object Y Position $yyyy.0000
obj_map		ds.l 1		; Object Sprite-map data location
obj_size	ds.l 1		; Object Size starting from center point X/Y, also used for obj-to-obj collision detection.
obj_vram	ds.w 1		; Object VRAM position (If DMA enabled: output location)
obj_x_spd	ds.w 1		; Object X Speed $xx.00
obj_y_spd	ds.w 1		; Object Y Speed $yy.00
obj_anim_indx	ds.w 1		; *internal* Object animation script index (obj_anim + obj_anim_indx)
obj_frame	ds.w 1		; Object current frame (overwritten by object_Animate)
obj_anim_id	ds.b 1		; Object animation number
obj_anim_icur	ds.b 1		; *internal* Object current animation id (DONT SEPARATE THIS FROM obj_anim_id)
obj_anim_spd	ds.b 1		; *internal* Object animation delay
obj_index	ds.b 1		; Object code-index
obj_set		ds.b 1		; Object settings
obj_subid	ds.b 1		; Object Sub-ID (for object placement)
obj_status	ds.b 1		; Object USER status (falling, collision, etc.)
obj_FREE	ds.b 1		; (FILLER align byte)
obj_ram		ds.b $40	; Object's own RAM
sizeof_mdobj	ds.l 0
		endstrct
; 		message "\{sizeof_mdobj}"

; ------------------------------------------------
; ** obj_set
; ------------------------------------------------

bitobj_Mars	equ	7	; 32X ONLY: This objects draws to the 32X side (256-color sprite)
bitobj_flipV	equ	1	; Set to flip object Vertically
bitobj_flipH	equ	0	; Set to flip object Horizontally

; ====================================================================
; ----------------------------------------------------------------
; Video RAM
; ----------------------------------------------------------------

			strct RAM_MdVideo
RAM_HorScroll		ds.l 240			; DMA Horizontal scroll data
RAM_VerScroll		ds.l 320/16			; DMA Vertical scroll data
RAM_Sprites		ds.w 8*80			; DMA Sprites
RAM_Palette		ds.w 64				; DMA palette
; RAM_SprDrwPz		ds.w 8*80			; External sprite pieces
RAM_MdMarsPalFd		ds.w 256			; Target 32X palette for FadeIn/Out
RAM_PaletteFd		ds.w 64				; Target MD palette for FadeIn/Out
RAM_VdpDmaList		ds.b $10*MAX_MDDMATSK		; DMA BLAST list for VBlank
RAM_Objects		ds.b MAX_MDOBJ*sizeof_mdobj	; Objects
RAM_ObjDispList		ds.w MAX_MDOBJ			; half-RAM pointers for display (Obj|Extra)
RAM_VidPrntList		ds.w 3*64			; Video_Print list: Address, Type
RAM_FrameCount		ds.l 1				; Frames counter
RAM_SprAutoDmaSet	ds.w 1				; VRAM location setting for Auto-DMA VRAM
RAM_SprAutoDmaCurr	ds.w 1				; CURRENT reading location for Auto-DMA
RAM_SprDrwCntr		ds.w 1				; TODO
RAM_SprLinkNum		ds.w 1				; Current sprite-link for building sprites
; RAM_VdpExWrite		ds.w 1
RAM_VdpDmaIndx		ds.w 1				; Current index in DMA BLAST list
RAM_VdpDmaMod		ds.w 1				; Mid-write flag
RAM_VidPrntVram		ds.w 1				; Default VRAM location for ASCII text used by Video_Print
RAM_FadeMdReq		ds.w 1				; FadeIn/Out request for Genesis palette (01-FadeIn 02-FadeOut)
RAM_FadeMdIncr		ds.w 1				; Fading increment count
RAM_FadeMdDelay		ds.w 1				; Fading delay
RAM_FadeMdTmr		ds.w 1				; Fading delay timer
RAM_FadeMarsReq		ds.w 1				; Same thing but for 32X's 256-color (01-FadeIn 02-FadeOut)
RAM_FadeMarsIncr	ds.w 1				; (Hint: Set to 4 to syncronize with Genesis' FadeIn/Out)
RAM_FadeMarsDelay	ds.w 1
RAM_FadeMarsTmr		ds.w 1
RAM_MdMars_DrawAll	ds.w 1
RAM_VdpRegs		ds.b 24				; VDP Register cache
sizeof_mdvid		ds.l 0
			endstrct

		erreport "MD VIDEO RAM",sizeof_mdvid-RAM_MdVideo,MAX_MdVideo

; ====================================================================
; --------------------------------------------------------
; Initialize Genesis video
;
; Breaks:
; d6-d7/a5-a6
; --------------------------------------------------------

Video_Init:
		lea	(RAM_MdVideo).w,a6		; Clear our RAM section
		move.w	#$8000,d6
		move.w	#(sizeof_mdvid-RAM_MdVideo)-1,d7
.clr_ram:
		move.b	d6,(a6)+			; (Write the LSB zero)
		dbf	d7,.clr_ram
		lea	(RAM_VdpDmaList),a6
		lea	.dma_entry(pc),a5
		move.w	#MAX_MDDMATSK,d7
.copy_dma:
		move.l	(a5),(a6)+
		move.l	4(a5),(a6)+
		move.l	8(a5),(a6)+
		move.l	$C(a5),(a6)+
		dbf	d7,.copy_dma
		move.w	#SET_DefAutoDma,(RAM_SprAutoDmaSet).w
		move.w	#1,(RAM_SprLinkNum).w
		move.w	(RAM_SprAutoDmaSet).w,(RAM_SprAutoDmaCurr).w
		lea	.list_vdpregs(pc),a6		; Write "cache'd" VDP registers
		lea	(RAM_VdpRegs).w,a5
		move.w	#17-1,d7
.loop:
		move.b	(a6)+,d6
		move.b	d6,(a5)+
		dbf	d7,.loop
		bra	Video_Update

; ------------------------------------------------
; Default VDP register settings
; ------------------------------------------------

.list_vdpregs:
		dc.b $04			; No HBlank interrupt, HV Counter on
		dc.b $04			; Display ON, No VBlank interrupt
		dc.b (($C000)>>10)		; Layer A at VRAM $C000 (%00xxx000)
		dc.b (($D000)>>10)		; Window  at VRAM $D000 (%00xxxxy0)
		dc.b (($E000)>>13)		; Layer B at VRAM $E000 (%00000xxx)
		dc.b (($F800)>>9)		; Sprites at VRAM $F800 (%0xxxxxxy) (OLD $F800)
		dc.b $00			; Unused
		dc.b $00			; Background color: $00
		dc.b $00			; Unused
		dc.b $00			; Unused
		dc.b $00			; HInt line number trigger
		dc.b (%000|%00)			; No ExtInt, Scroll: VSCR:full HSCR:full
		dc.b $81			; H40, No shadow mode, 320-pixel resolution mode
		dc.b (($FC00)>>10)		; HScroll at VRAM $FC00 (%00xxxxxx)
		dc.b $00			; Unused
		dc.b $02			; VDP auto-increment: $02
		dc.b (%00<<4)|%01		; Scroll area size: V32 H64
		dc.b $00
		dc.b $00
		align 2

; ------------------------------------------------
; DMA blast entry
; ------------------------------------------------

.dma_entry:
		dc.w $9400,$9300		; Size
		dc.w $9600,$9500,$9700		; Source
		dc.l $40000080 			; VDP destination with DMA bit
		dc.w $0000			; SegaCD/CD32X only: Patch for the first 4 pixels
		align 2

; ------------------------------------------------

; Default ASCII PRINT palette
ASCII_PAL:	dc.w $0000,$0EEE,$0CCC,$0AAA,$0888,$0444,$000E,$0008
		dc.w $00EE,$0088,$00E0,$0080,$0E00,$0800,$0000,$0000
		align 2

; --------------------------------------------------------
; Video_Update
;
; Writes register data stored in RAM to VDP
; from registers $80 to $90
;
; WINDOW registers $91 and $92 are written
; manually.
;
; Breaks:
; d6-d7/a5-a6
; --------------------------------------------------------

Video_Update:
		lea	(RAM_VdpRegs).w,a6
		lea	(vdp_ctrl),a5
		move.w	#$8000,d6
		moveq	#17-1,d7
.loop:
		move.b	(a6)+,d6
		move.w	d6,(a5)
		addi.w	#$0100,d6
		dbf	d7,.loop
.exit:
		rts



; --------------------------------------------------------
; Video_Clear
;
; Clear all video data from VRAM
;
; Breaks:
; ALL
; --------------------------------------------------------

Video_Clear:
; 		move.w	#0,d0			; Clears until $57F
; 		move.w	#0,d1
; 		move.w	#$57F*$20,d2
; 		bsr	Video_Fill

; --------------------------------------------------------
; Video_ClearScreen
;
; Clears ALL Genesis screens FG/BG/WIN
;
; Breaks:
; d0-d2/d6-d7/a5-a6
; --------------------------------------------------------

Video_ClearScreen:
		moveq	#0,d0
		move.w	#$1000,d2		; FG/BG size
		move.b	(RAM_VdpRegs+2).w,d1	; FG
		andi.w	#%111000,d1
		lsl.w	#8,d1
		lsl.w	#2,d1
		bsr	Video_Fill
		move.b	(RAM_VdpRegs+4).w,d1	; BG
		andi.w	#%000111,d1
		lsl.w	#8,d1
		lsl.w	#5,d1
		bsr	Video_Fill
		move.w	#$1000,d2		; WD Size
		move.b	(RAM_VdpRegs+3).w,d1	; Window
		andi.w	#%111110,d1
		lsl.w	#8,d1
		lsl.w	#2,d1
		bsr	Video_Fill
		lea	(RAM_HorScroll).w,a6	; RAM cleanup
		move.w	#240-1,d7
		moveq	#0,d6
.xnext:
		move.l	d6,(a6)+
		dbf	d7,.xnext
		lea	(RAM_VerScroll).w,a6
		move.w	#(320/16)-1,d7
.ynext:
		move.l	d6,(a6)+
		dbf	d7,.ynext
		lea	(RAM_Sprites).w,a6
		move.w	#((80*8)/4)-1,d7
.snext:
		move.l	d6,(a6)+
		dbf	d7,.snext
		lea	(RAM_Palette).w,a6
		lea	(RAM_PaletteFd).w,a5
		move.w	#(64/2)-1,d7
.pnext:
		move.l	d6,(a6)+
		move.l	d6,(a5)+
		dbf	d7,.pnext
	if MARS|MARSCD
		lea	(RAM_MdDreq+Dreq_Palette).w,a6
		lea	(RAM_MdMarsPalFd).w,a5
		move.w	#(256/2)-1,d7
; 		moveq	#0,d6
.pmnext:
		move.l	d6,(a6)+
		move.l	d6,(a5)+
		dbf	d7,.pmnext
		lea	(RAM_MdDreq+Dreq_SuperSpr).w,a6
		move.w	#((sizeof_marsspr*MAX_MARSSPR)/2)-1,d7
.ssp_next:
		move.w	d6,(a6)+
		dbf	d7,.ssp_next
	endif
		rts

; ====================================================================
; ----------------------------------------------------------------
; Palette fading system
; ----------------------------------------------------------------

; --------------------------------------------------------
; FULL Fade in
; --------------------------------------------------------

Video_FullFadeIn:
		move.w	#1,(RAM_FadeMdReq).w	; Fade-in mode
		move.w	#1,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMdDelay).w
		move.w	#2,(RAM_FadeMarsIncr).w
		move.w	#0,(RAM_FadeMarsDelay).w
		bra	Video_WaitFade

; --------------------------------------------------------
; FULL Fade out
; --------------------------------------------------------

Video_FullFadeOut:
		move.w	#2,(RAM_FadeMdReq).w	; Fade-out mode
		move.w	#2,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMdDelay).w
		move.w	#2,(RAM_FadeMarsIncr).w
		move.w	#0,(RAM_FadeMarsDelay).w
; 		bra	Video_WaitFade

; --------------------------------------------------------
; Video_WaitFade
;
; *** External VBlank loop ***
; --------------------------------------------------------

Video_WaitFade:
		bsr	System_Render		; Render one frame normally
.wait_fade:
		move.w	(vdp_ctrl).l,d7		; Wait VBlank
		btst	#bitVBlk,d7
		beq.s	.wait_fade
		bsr	Video_Render		; Render VDP Visuals
	if MARS|MARSCD
		bsr	System_MarsUpdate	; Update DREQ RAM
		bsr	Video_DoPalFade
		bsr	Video_MdMars_DoPalFade
		move.w	(RAM_FadeMdReq).w,d7	; Check both req status.
		move.w	(RAM_FadeMarsReq).w,d6
		or.w	d6,d7
	else
		bsr	Video_DoPalFade
		move.w	(RAM_FadeMdReq).w,d7
	endif
		tst.w	d7
		bne.s	.wait_fade
		rts

; --------------------------------------------------------
; Video_LoadPal, Video_FadePal
;
; Loads VDP palette data to either
; CURRENT palette or FADING palette buffers.
;
; Input:
; a0   | Palette data
; d0.w | Starting color index
; d1.w | Number of colors
;
; Breaks:
; d6-d7,a6
; --------------------------------------------------------

Video_FadePal:
		lea	(RAM_PaletteFd).w,a6
		clr.w	(RAM_FadeMdTmr).w	; Clear fading timer.
		bra.s	vidMd_Pal
Video_LoadPal:
		lea	(RAM_Palette).w,a6
vidMd_Pal:
		move.l	a0,a5
		moveq	#0,d7
		move.w	d0,d7
		add.w	d7,d7
		adda	d7,a6
		move.w	d1,d7
		subi.w	#1,d7
		move.w	d2,d6
		andi.w	#1,d6
		ror.w	#1,d6
.loop:
		move.w	(a5)+,(a6)+
		dbf	d7,.loop
		rts

; --------------------------------------------------------
; Video_RunFade
;
; Processes palette fading for one frame
;
; Returns:
; bne | Still active
; beq | Finished
;
; Breaks:
; ALL
;
; Notes:
; Call this during DISPLAY only.
; --------------------------------------------------------

Video_RunFade:
	if MARS|MARSCD
		bsr	Video_DoPalFade
		bsr	Video_MdMars_DoPalFade
		move.w	(RAM_FadeMdReq).w,d7
		move.w	(RAM_FadeMarsReq).w,d6
		or.w	d6,d7
	else
		bsr	Video_DoPalFade
		move.w	(RAM_FadeMdReq).w,d7
	endif
		rts

; --------------------------------------------------------
; Video_DoPalFade
; --------------------------------------------------------

Video_DoPalFade:
		subi.w	#1,(RAM_FadeMdTmr).w
		bpl.s	.active
		move.w	(RAM_FadeMdDelay).w,(RAM_FadeMdTmr).w
		move.w	(RAM_FadeMdReq).w,d7
		add.w	d7,d7
		move.w	.fade_list(pc,d7.w),d7
		jmp	.fade_list(pc,d7.w)
.active:
		rts

; --------------------------------------------

.fade_list:
		dc.w .fade_done-.fade_list
		dc.w .fade_in-.fade_list
		dc.w .fade_out-.fade_list

; --------------------------------------------
; No fade or finished.
; --------------------------------------------

.fade_done:
		rts

; --------------------------------------------
; Fade in
; --------------------------------------------

.fade_in:
		lea	(RAM_PaletteFd).w,a6
		lea	(RAM_Palette).w,a5
		moveq	#64,d0				; Num of colors
		move.w	(RAM_FadeMdIncr).w,d1		; Speed
		add.w	d1,d1
		move.w	d0,d6
		swap	d6
		subi.w	#1,d0
.nxt_pal:
		clr.w	d2		; Reset finished colorbits
		move.w	(a6),d7		; d7 - Input
		move.w	(a5),d6		; d6 - Output
		move.w	d7,d3		; RED
		move.w	d6,d4
		andi.w	#%0000111011100000,d6
		andi.w	#%0000000000001110,d4
		andi.w	#%0000000000001110,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_red
		move.w	d3,d4
		ori.w	#%001,d2	; RED is ready
.no_red:
		or.w	d4,d6
		lsl.w	#4,d1
		move.w	d7,d3		; GREEN
		move.w	d6,d4
		andi.w	#%0000111000001110,d6
		andi.w	#%0000000011100000,d4
		andi.w	#%0000000011100000,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_grn
		move.w	d3,d4
		ori.w	#%010,d2	; GREEN is ready
.no_grn:
		or.w	d4,d6
		lsl.w	#4,d1
		move.w	d7,d3		; BLUE
		move.w	d6,d4
		andi.w	#%0000000011101110,d6
		andi.w	#%0000111000000000,d4
		andi.w	#%0000111000000000,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_blu
		move.w	d3,d4
		ori.w	#%100,d2	; BLUE is ready
.no_blu:
		or.w	d4,d6
		lsr.w	#8,d1
		move.w	d6,(a5)+
		adda	#2,a6
		cmpi.w	#%111,d2
		bne.s	.no_fnsh
		swap	d6
		subi.w	#1,d6
		swap	d6
.no_fnsh:
		dbf	d0,.nxt_pal
		swap	d6
		tst.w	d6
		bne.s	.no_move
		clr.w	(RAM_FadeMdReq).w
.no_move:
		rts

; --------------------------------------------
; Fade out
; --------------------------------------------

.fade_out:
		lea	(RAM_Palette).w,a6
		moveq	#64,d0				; Num of colors
		move.w	(RAM_FadeMdIncr).w,d1		; Speed
		move.w	d0,d6
		swap	d6
		subi.w	#1,d0
.nxt_pal_o:
		clr.w	d2			; Reset finished colorbits
		move.w	(a6),d7			; d7 - Input
		move.w	d7,d6
		andi.w	#%0000111011100000,d7
		andi.w	#%0000000000001110,d6
		sub.w	d1,d6
		bpl.s	.no_red_o
		clr.w	d6
		ori.w	#%001,d2		; RED is ready
.no_red_o:
		or.w	d6,d7
		lsl.w	#4,d1
		move.w	d7,d6
		andi.w	#%0000111000001110,d7
		andi.w	#%0000000011100000,d6
		sub.w	d1,d6
		bpl.s	.no_grn_o
		clr.w	d6
		ori.w	#%010,d2		; GREEN is ready
.no_grn_o:
		or.w	d6,d7
		lsl.w	#4,d1
		move.w	d7,d6
		andi.w	#%0000000011101110,d7
		andi.w	#%0000111000000000,d6
		sub.w	d1,d6
		bpl.s	.no_blu_o
		clr.w	d6
		ori.w	#%100,d2		; BLUE is ready
.no_blu_o:
		or.w	d6,d7
		lsr.w	#8,d1
		move.w	d7,(a6)+
		cmpi.w	#%111,d2
		bne.s	.no_fnsh_o
		swap	d6
		subi.w	#1,d6
		swap	d6
.no_fnsh_o:
		dbf	d0,.nxt_pal_o
		swap	d6
		tst.w	d6
		bne.s	.no_move_o
		clr.w	(RAM_FadeMdReq).w
.no_move_o:
		rts

; ====================================================================
; --------------------------------------------------------
; Genesis DMA
; --------------------------------------------------------

; --------------------------------------------------------
; Video_LoadArt
;
; Loads VDP Graphics using DMA
;
; Input:
; d0.l | Graphics data (NOT a0)
; d1.w | VRAM location, cell_vram(vram_pos)
; d2.w | Size (FULL)
;
; Breaks:
; d4-d7,a4
;
; Notes:
; - For a fast transfer call this during VBlank
; * 32X: MAKE SURE THE SH2 SIDE IS NOT READING ROM
;        WHEN GETTING HERE.
; --------------------------------------------------------

Video_LoadArt:
		move.l	d0,d5
		add.w	d2,d5
		bcc.s	.normal
		move.l	d0,d5		; <-- DOUBLE TRANSFER
		move.w	d1,d6
		move.l	d5,d7		; Top
		addi.l	#$010000,d7
		andi.l	#$FF0000,d7
		sub.l	d0,d7
		bsr.s	.mk_set
		move.l	d0,d5		; Bottom
		addi.l	#$010000,d5
		andi.l	#$FF0000,d5
		move.l	d5,d6
		sub.l	d0,d6
		move.w	d2,d7
		sub.w	d6,d7
		add.w	d1,d6
		bra.s	.mk_set
.normal:
		move.l	d0,d5
		move.w	d1,d6
		move.w	d2,d7
; d7 - size
; d6 - vram
; d5 - data
.mk_set:
		lea	(vdp_ctrl),a4
		move.w	#$8100,d4		; DMA ON
		move.b	(RAM_VdpRegs+1).w,d4
		bset	#bitDmaEnbl,d4
		move.w	d4,(a4)
		andi.l	#$0000FFFE,d7
		beq.s	.bad_size
; 		tst.w	d7
; 		bmi.s	.bad_size
	if MCD|MARSCD
		swap	d6
		swap	d5
		move.w	d5,d6
		swap	d5
		andi.w	#$F0,d6
		cmpi.b	#$20,d6
		bne.s	.non_wram
		movem.l	d5-d6,-(sp)		; <-- Save data on stack
		addi.l	#2,d5
.non_wram:
		swap	d6
	endif
		bsr.s	.shared_setup
		move.w	d6,(a4)
		bsr	System_DmaEnter_ROM
		move.w	d7,(a4)			; <-- second write
		bsr	System_DmaExit_ROM
		move.w	#$8100,d4		; DMA OFF
		move.b	(RAM_VdpRegs+1).w,d4
		move.w	d4,(a4)
	if MCD|MARSCD
		movem.l	(sp)+,d5-d6		; --> Get data as d7
		move.l	d5,d7
		cmpi.b	#$20,d6			; Word-RAM?
		bne.s	.non_wram_l
		swap	d6
		move.w	d6,d7			; Destination
		andi.l	#$3FFF,d6
		ori.w	#$4000,d6
		lsr.w	#8,d7
		lsr.w	#6,d7
		andi.w	#%11,d7
		move.w	d6,(a4)			; VDP destination
		move.w	d7,(a4)			;
		move.l	a4,d7
		move.l	d5,a4
		move.w	(a4),d6
		move.l	d7,a4
		move.w	d6,-4(a4)		; DATA port -4
.non_wram_l:
	endif
.bad_size:
		rts

; --------------------------------------------------------

.from_ram:
	; TODO
		rts

; --------------------------------------------------------

.shared_setup:
		lsl.l	#7,d7
		lsr.w	#8,d7
		ori.l	#$94009300,d7
		move.l	d7,(a4)
  		lsr.l	#1,d5			; d5 - Source
 		move.l	#$96009500,d7
 		move.b	d5,d7
 		lsr.l	#8,d5
 		swap	d7
 		move.b	d5,d7
 		move.l	d7,(a4)
 		move.w	#$9700,d7
 		lsr.l	#8,d5
 		move.b	d5,d7
 		move.w	d7,(a4)
		move.w	d6,d7			; Destination
		andi.l	#$3FFF,d6
		ori.w	#$4000,d6
		lsr.w	#8,d7
		lsr.w	#6,d7
		andi.w	#%11,d7
		ori.w	#$80,d7
		rts

; --------------------------------------------------------
; Video_DmaMkEntry
;
; Makes a new entry in the DMA BLAST list
; to be processed on VBlank for the next frame.
;
; Input:
; d0.l | Graphics data location
; d1.w | VRAM location - cell_vram(vram_pos)
; d2.w | Size
;
; Breaks:
; d5-d7,a6
;
; Notes:
; - Can only be called during DISPLAY ONLY.
; - For loading graphics as normal use Video_LoadArt
; - SegaCD/CD32X:
;   The 4 pixels patch is always applied even
;   if not reading from WORD-RAM
; --------------------------------------------------------

Video_DmaMkEntry:
		move.l	d0,d5
		add.w	d2,d5
		bcc.s	.normal
		move.l	d0,d5		; d5 - TOP point
		move.w	d1,d6		; d6 - VRAM position
		move.l	d5,d7
		andi.l	#$FF0000,d7
		addi.l	#$010000,d7
		sub.l	d0,d7		; d7 - TOP Size
		bsr.s	.mk_set
		move.l	d0,d5		; d5 - BOTTOM point
		addi.l	#$010000,d5
		andi.l	#$FF0000,d5
		move.l	d5,d6
		sub.l	d0,d6
		move.w	d2,d7
		sub.w	d6,d7
		add.w	d1,d6
		bra.s	.mk_set
.normal:
		move.l	d0,d5
		move.w	d1,d6
		move.w	d2,d7
; d7 - size
; d6 - vram
; d5 - data
.mk_set:
		swap	d7
		move.w	(RAM_VdpDmaIndx).w,d7
		cmpi.w	#MAX_MDDMATSK,d7
		bge	.ran_out
		lsl.w	#4,d7			; Size $10
		lea	(RAM_VdpDmaList).w,a6
		adda	d7,a6
		swap	d7
		andi.l	#$0000FFFE,d7		; d7 - Size
		beq.s	.ran_out		; If == 0, bad
		tst.w	d7
		bmi.s	.ran_out		; If negative, bad
		move.w	#1,(RAM_VdpDmaMod).w
		addq.w	#1,(RAM_VdpDmaIndx).w
		lsr.w	#1,d7
		movep.w	d7,1(a6)
	if MCD|MARSCD
  		move.l	d5,-(sp)		; Save TOP point
  		move.l	d5,d7
  		andi.l	#$F00000,d7
  		cmpi.l	#$200000,d7
  		bne.s	.not_wram
  		addq.l	#2,d5			; WORD-RAM patch
.not_wram:
	endif
  		lsr.l	#1,d5			; d5 - Source
  		move.l	d5,d7
  		swap	d7
 		movep.w	d5,5(a6)
 		move.b	d7,9(a6)
		move.w	d6,d7			; Destination
		andi.l	#$3FFF,d6
		ori.w	#$4000,d6
		lsr.w	#8,d7
		lsr.w	#6,d7
		andi.w	#%11,d7
		ori.w	#$80,d7
		move.w	d6,$A(a6)
		move.w	d7,$C(a6)
	if MCD|MARSCD
	; *** 4pixel PATCH IS ALWAYS APPLIED
	; EVEN IF NOT IN WORD-RAM ***
		move.l	a6,d7		; Save a6
		move.l	(sp)+,a6	; Restore TOP point
		move.w	(a6),d6		; Grab the graphs first word
		move.l	d7,a6		; Restore a6
		move.w	d6,$E(a6)	; Copy to last entry
	endif
		move.w	#0,(RAM_VdpDmaMod).w
.ran_out:
		rts

; --------------------------------------------------------
; Video_Fill
;
; Fill data to VRAM
;
; d0.w | WORD to fill
; d1.w | VRAM destination - cell_vram(dest)
; d2.w | Size
;
; Notes:
; FILL writes in this order: $56781234, Size $0001 is
; invalid.
; --------------------------------------------------------

Video_Fill:
		movem.l	d6-d7/a6,-(sp)
		lea	(vdp_ctrl).l,a6
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1).w,d7
		bset	#bitDmaEnbl,d7
		move.w	d7,(a6)
.dmaw:		move.w	(a6),d7
		btst	#bitDma,d7
		bne.s	.dmaw
		move.w	#$8F01,(a6)	; Set increment to $01
		move.w	d2,d7		; d2 - Size
		subi.w	#1,d7
		move.l	#$94009300,d6
		move.b	d7,d6
		swap	d6
		lsr.w	#8,d7
		move.b	d7,d6
		swap	d6
		move.l	d6,(a6)
		move.w	#$9780,(a6)	; DMA Fill mode
		move.w	d1,d7		; d1 - Destination
		move.w	d7,d6
		andi.w	#$3FFF,d6
		ori.w	#$4000,d6
		swap	d6
		move.w	d7,d6
		lsr.w	#8,d6
		lsr.w	#6,d6
		andi.w	#%11,d6
		ori.w	#$80,d6
		move.l	d6,(a6)
		move.w	d0,-4(a6)
.dma_w:		move.w	(a6),d7
		btst	#bitDma,d7
		bne.s	.dma_w
		move.w	#$8F02,(a6)	; Set increment to $02
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1).w,d7
		move.w	d7,(a6)
		movem.l	(sp)+,d6-d7/a6
		rts

; --------------------------------------------------------
; Video_Copy
;
; Copy VRAM data to another location
;
; Input:
; d0.w | VRAM Source      - cell_vram(src)
; d1.w | VRAM Destination - cell_vram(dest)
; d2.w | Size
; --------------------------------------------------------

; TODO: test if this works again...
Video_Copy:
		movem.l	d6-d7/a6,-(sp)
		lea	(vdp_ctrl),a6
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1).w,d7
		bset	#bitDmaEnbl,d7
		move.w	d7,(a6)
.dmaw:		move.w	(a6),d7
		btst	#bitDma,d7
		bne.s	.dmaw
		move.w	#$8F01,(a6)		; Increment $01
		move.w	d2,d7			; SIZE
		move.l	#$94009300,d6
; 		lsr.w	#1,d7
		move.b	d7,d6
		swap	d6
		lsr.w	#8,d7
		move.b	d7,d6
		swap	d6
		move.l	d6,(a6)
		move.l	#$96009500,d6		; SOURCE
		move.w	d0,d7
		move.b	d7,d6
		swap	d6
		lsr.w	#8,d7
		move.b	d7,d6
		move.l	d6,(a6)
		move.w	#$97C0,(a6)		; DMA Copy mode
		move.l	d2,d7			; DESTINATION
		move.w	d7,d6
		andi.w	#$3FFF,d6
		ori.w	#$4000,d6
		swap	d6
		move.w	d7,d6
		lsr.w	#8,d6
		lsr.w	#6,d6
		andi.w	#%11,d6
		ori.w	#$C0,d6
		move.l	d6,(a6)
		move.w	d1,-4(a6)
.dma_w:		move.w	(a6),d7
		btst	#bitDma,d7
		bne.s	.dma_w
		move.w	#$8F02,(a6)		; Increment $02
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1).w,d7
		move.w	d7,(a6)
		movem.l	(sp)+,d6-d7/a6
		rts

; --------------------------------------------------------
; Video_Render
;
; Call this during VBlank to update visuals, watch out
; for the timing for this to properly hide the CRAM dots.
;
; This gets normally called on System_Render
; --------------------------------------------------------

; TODO: automate the DMA destination(s)

Video_Render:
		lea	(vdp_ctrl),a6
		move.w	#$8100,d7		; DMA ON
		move.b	(RAM_VdpRegs+1).w,d7
		bset	#bitDmaEnbl,d7
		move.w	d7,(a6)
		bsr	System_DmaEnter_RAM
		move.l	#$94009328,(a6)
		move.l	#$96009500|(RAM_VerScroll<<7&$FF0000)|(RAM_VerScroll>>1&$FF),(a6)
		move.w	#$9700|(RAM_VerScroll>>17&$7F),(a6)
		move.w	#$4000,(a6)
		move.w	#$0010|$80,-(sp)
		move.w	(sp)+,(a6)
		move.l	#$940193E0,(a6)
		move.l	#$96009500|(RAM_HorScroll<<7&$FF0000)|(RAM_HorScroll>>1&$FF),(a6)
		move.w	#$9700|(RAM_HorScroll>>17&$7F),(a6)
		move.w	#$7C00,(a6)
		move.w	#$0003|$80,-(sp)
		move.w	(sp)+,(a6)
		move.l	#$94029300,(a6)
		move.l	#$96009500|(RAM_Sprites<<7&$FF0000)|(RAM_Sprites>>1&$FF),(a6)
		move.w	#$9700|(RAM_Sprites>>17&$7F),(a6)
		move.w	#$7800,(a6)
		move.w	#$0003|$80,-(sp)
		move.w	(sp)+,(a6)
		move.l	#$94009340,(a6)
		move.l	#$96009500|(RAM_Palette<<7&$FF0000)|(RAM_Palette>>1&$FF),(a6)
		move.w	#$9700|(RAM_Palette>>17&$7F),(a6)
		move.w	#$C000,(a6)
		move.w	#$0000|$80,-(sp)
		move.w	(sp)+,(a6)
		bsr	System_DmaExit_RAM
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1).w,d7
		move.w	d7,(a6)
		move.w	#1,(RAM_SprLinkNum).w				; Reset SPRITE LINK number
		move.w	(RAM_SprAutoDmaSet).w,(RAM_SprAutoDmaCurr).w	; Reset Auto-DMA VRAM

; --------------------------------------------------------
; Video_DmaBlast
;
; Process DMA tasks from a predefined list in RAM
;
; Breaks:
; d5-d7,a3-a4
;
; Notes:
; - Call this on VBlank ONLY
; * 32X: This code must be located on RAM as this
;        sets the RV bit
; --------------------------------------------------------

; Struct:
; dc.w $94xx,$93xx		; Size
; dc.w $96xx,$95xx,$97xx	; Source
; dc.l $4xxx008x 		; VDP destination with DMA bit
; dc.w $xxxx			; SegaCD/CD32X only: Patch for the first 4 pixels

; Video_DmaBlast:
		tst.w	(RAM_VdpDmaMod).w		; Got mid-write?
		bne.s	.exit				; then can't transfer this.
		tst.w	(RAM_VdpDmaIndx).w		; Any requests?
		beq.s	.exit
		lea	(vdp_ctrl),a4			; a4 - vdp_ctrl
		lea	(RAM_VdpDmaList).w,a3		; a3 - Blast list
		move.w	#$8100,d7			; DMA ON
		move.b	(RAM_VdpRegs+1).w,d7
		bset	#bitDmaEnbl,d7
		move.w	d7,(a4)
		bsr	System_DmaEnter_ROM
.next:		tst.w	(RAM_VdpDmaIndx).w
		beq.s	.end
		move.l	(a3)+,(a4)		; Size
		move.l	(a3)+,(a4)		; Source
		move.w	(a3)+,(a4)
	if MCD|MARSCD
		move.w	(a3)+,d3		; Destination
		move.w	(a3)+,d2
		move.w	d2,-(sp)		; Use stack for this write
		move.w	d3,(a4)
		move.w	(sp)+,(a4)		; *** CPU freezes ***
		andi.w	#$FF7F,d2		; Remove DMA bit
		move.w	d3,(a4)			; Set VDP control normally
		move.w	d2,(a4)
		move.w	(a3)+,-4(a4)		; Write the patched pixels
	else
		move.w	(a3)+,(a4)		; Normal VDP control write
		move.w	(a3)+,(a4)		; *** CPU freezes ***
		adda	#2,a3
	endif
		subq.w	#1,(RAM_VdpDmaIndx).w
		bra.s	.next
.end:
		bsr	System_DmaExit_ROM
		move.w	#$8100,d7		; DMA OFF
		move.b	(RAM_VdpRegs+1).w,d7
		move.w	d7,(a4)
.exit:
		rts

; ====================================================================
; ----------------------------------------------------------------
; Video routines for 32X
; ----------------------------------------------------------------

; --------------------------------------------------------
; Video_MdMars_SyncFrame
;
; Syncronize VBlank with the 32X
; --------------------------------------------------------

Video_MdMars_SyncFrame:
	if MARS|MARSCD
		bset	#4,(sysmars_reg+comm12+1).l
.wait_mars:	btst	#4,(sysmars_reg+comm12+1).l
		bne.s	.wait_mars
	endif
		rts

; --------------------------------------------------------
; Video_MdMars_VideoMode
;
; Sets Pseudo-Graphics mode on the 32X side.
;
; Input:
; d0.w | Mode number
;        Write $00 to disable all 32X visuals.
;
; Uses:
; d7/a0
;
; Notes:
; Changing modes takes 3 FRAMES to process.
; --------------------------------------------------------

Video_MdMars_VideoMode:
	if MARS|MARSCD
		movem.l	d7/a0,-(sp)
		move.l	d0,-(sp)
	rept 3
		bsr	Video_MdMars_SyncFrame	; Wait frame and update DREQ RAM
		bsr	System_MarsUpdate
	endm
		move.l	(sp)+,d0
		move.w	d0,d7
		ori.w	#%00001000,d7
		move.b	d7,(sysmars_reg+(comm12+1)).l
		movem.l	(sp)+,d7/a0
	endif
		rts

; --------------------------------------------------------
; Video_MdMars_LoadPal, Video_MdMars_FadePal
;
; Loads SVDP 256-color palette data to either
; CURRENT palette or FADING palette buffers.
;
; Input:
; d0.w | Start from
; d1.w | Number of colors
; d2.w | Priority bit 0/1
;
; Breaks:
; d5-d7/a6
; --------------------------------------------------------

Video_MdMars_FadePal:
	if MARS|MARSCD
		lea	(RAM_MdMarsPalFd).w,a6
		clr.w	(RAM_FadeMarsTmr).w	; Clear fade timer
		bra.s	vidMars_Pal
Video_MdMars_LoadPal:
		lea	(RAM_MdDreq+Dreq_Palette).w,a6
vidMars_Pal:
		move.l	a0,a5
		moveq	#0,d7
		move.w	d0,d7
		add.w	d7,d7
		adda	d7,a6
		move.w	d1,d7
		subi.w	#1,d7
		move.w	d2,d6
		andi.w	#1,d6
		ror.w	#1,d6
.loop:
		move.w	(a5)+,d5
		or.w	d6,d5
		move.w	d5,(a6)+
		dbf	d7,.loop
	endif
		rts

; --------------------------------------------------------
; Video_MdMars_DoPalFade
;
; Process the 256-color fading
;
; Input:
; a0   | Palette data
; d0.w | Number of colors
; d1.w | Speed
;
; Breaks:
; ALL
;
; Notes:
; - CALL THIS OUTSIDE OF VBLANK
; - This keeps the Priority bit intact.
; ** This takes A LOT of CPU if fading all 256-colors **
; --------------------------------------------------------

Video_MdMars_DoPalFade:
	if MARS|MARSCD
		subi.w	#1,(RAM_FadeMarsTmr).w
		bpl.s	.active
		bset	#5,(sysmars_reg+comm12+1).l		; PAUSE rendering
		move.w	(RAM_FadeMarsDelay).w,(RAM_FadeMarsTmr).w
		move.w	(RAM_FadeMarsReq).w,d7
		add.w	d7,d7
		move.w	.fade_list(pc,d7.w),d7
		jsr	.fade_list(pc,d7.w)
		bclr	#5,(sysmars_reg+comm12+1).l		; RESTORE rendering
.active:
		rts

; --------------------------------------------

.fade_list:
		dc.w .fade_done-.fade_list
		dc.w .fade_in-.fade_list
		dc.w .fade_out-.fade_list

; --------------------------------------------
; No fade or finished.
; --------------------------------------------

.fade_done:
		rts

; --------------------------------------------
; Fade in
; --------------------------------------------

.fade_in:
		lea	(RAM_MdMarsPalFd).w,a6
		lea	(RAM_MdDreq+Dreq_Palette).w,a5
		move.w	#256,d0				; Num of colors
		move.w	(RAM_FadeMarsIncr).w,d1		; Speed
		move.w	d0,d6
		swap	d6
		subi.w	#1,d0
.nxt_pal:
		clr.w	d2		; Reset finished colorbits
		move.w	(a6),d7		; d7 - Input
		move.w	(a5),d6		; d6 - Output
		move.w	d7,d3		; RED
		move.w	d6,d4
		andi.w	#%1111111111100000,d6
		andi.w	#%0000000000011111,d4
		andi.w	#%0000000000011111,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_red
		move.w	d3,d4
		ori.w	#%001,d2	; RED is ready
.no_red:
		or.w	d4,d6
		lsl.w	#5,d1
		move.w	d7,d3		; GREEN
		move.w	d6,d4
		andi.w	#%1111110000011111,d6
		andi.w	#%0000001111100000,d4
		andi.w	#%0000001111100000,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_grn
		move.w	d3,d4
		ori.w	#%010,d2	; GREEN is ready
.no_grn:
		or.w	d4,d6
		lsl.w	#5,d1
		move.w	d7,d3		; BLUE
		move.w	d6,d4
		andi.w	#%1000001111111111,d6
		andi.w	#%0111110000000000,d4
		andi.w	#%0111110000000000,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_blu
		move.w	d3,d4
		ori.w	#%100,d2	; BLUE is ready
.no_blu:
		or.w	d4,d6
		lsr.w	#8,d1
		lsr.w	#2,d1
		andi.w	#$8000,d7	; Keep priority bit
		or.w	d7,d6
		move.w	d6,(a5)+
		adda	#2,a6
		cmpi.w	#%111,d2
		bne.s	.no_fnsh
		swap	d6
		subi.w	#1,d6
		swap	d6
.no_fnsh:
		dbf	d0,.nxt_pal
		swap	d6
		tst.w	d6
		bne.s	.no_move
		clr.w	(RAM_FadeMarsReq).w
.no_move:
		rts

; --------------------------------------------
; Fade out
; --------------------------------------------

.fade_out:
		lea	(RAM_MdDreq+Dreq_Palette).w,a6
		move.w	#256,d0				; Num of colors
		move.w	(RAM_FadeMarsIncr).w,d1		; Speed
		move.w	d0,d6
		swap	d6
		subi.w	#1,d0
.nxt_pal_o:
		clr.w	d2		; Reset finished colorbits
		move.w	(a6),d7		; d7 - Input
		move.w	d7,d6
		andi.w	#%1111111111100000,d7
		andi.w	#%0000000000011111,d6
		sub.w	d1,d6
		bpl.s	.no_red_o
		clr.w	d6
		ori.w	#%001,d2	; RED is ready
.no_red_o:
		or.w	d6,d7
		lsl.w	#5,d1
		move.w	d7,d6
		andi.w	#%1111110000011111,d7
		andi.w	#%0000001111100000,d6
		sub.w	d1,d6
		bpl.s	.no_grn_o
		clr.w	d6
		ori.w	#%010,d2	; GREEN is ready
.no_grn_o:
		or.w	d6,d7
		lsl.w	#5,d1
		move.w	d7,d6
		andi.w	#%1000001111111111,d7
		andi.w	#%0111110000000000,d6
		sub.w	d1,d6
		bpl.s	.no_blu_o
		clr.w	d6
		ori.w	#%100,d2	; BLUE is ready
.no_blu_o:
		or.w	d6,d7
		lsr.w	#8,d1
		lsr.w	#2,d1
		move.w	d7,(a6)+
		cmpi.w	#%111,d2
		bne.s	.no_fnsh_o
		swap	d6
		subi.w	#1,d6
		swap	d6
.no_fnsh_o:
		dbf	d0,.nxt_pal_o
		swap	d6
		tst.w	d6
		bne.s	.no_move_o
		clr.w	(RAM_FadeMarsReq).w
.no_move_o:
	endif
		rts

; ====================================================================
; ----------------------------------------------------------------
; Genesis VDP screen layer routines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Video_LoadMap
;
; Loads screen map data
; Horizontal order: LEFT to RIGHT, TOP to BOTTOM
;
; Input:
; a0   | Map data
; d0.l | Screen location:
;        locate(x_pos,y_pos,layer)
; d1.l | Map size X/Y:
;        map_size(width,height)
; d2.l | VRAM-cell increment
;
; Breaks:
; --------------------------------------------------------

Video_LoadMap:
		movem.l	d4-d7/a6,-(sp)
		lea	(vdp_data),a6
		bsr	vid_PickLayer
		move.w	d1,d4			; d4 - Y-cell loop
.yloop:
		swap	d4			; YYYY----
		move.l	d5,4(a6)		; d5 - Set VDP address
		move.l	d1,d7
		swap	d7			; d7 - X-cell loop
.xloop:
		move.w	(a0)+,d4
		cmpi.w	#-1,d4			; -1?
		bne.s	.nonull
		move.w	d2,d4
		andi.w	#$8000,d4
		addi.w	#SET_NullVram,d4		; Replace with custom blank tile plus priority
		bra.s	.cont
.nonull:
		add.w	d2,d4
.cont:
		swap	d7			; Check for double interlace
		move.b	(RAM_VdpRegs+$C).w,d7
		andi.w	#%110,d7
		cmpi.w	#%110,d7
		bne.s	.nodble
		move.w	d4,d7
		lsr.w	#1,d7
		andi.w	#$7FF,d7
		andi.w	#$F800,d4
		or.w	d7,d4
.nodble:
		swap	d7
		move.w	d4,(a6)
		dbf	d7,.xloop
		add.l	d6,d5
		swap	d4			; ----YYYY
		dbf	d4,.yloop
		movem.l	(sp)+,d4-d7/a6
		rts

; ====================================================================
; ----------------------------------------------------------------
; Text PRINT system, for debugging or quick texts.
; ----------------------------------------------------------------

; --------------------------------------------------------
; Video_PrintInit
;
; Initializes the default Graphics and Palette
; for the font.
;
; Input:
; a0 | Graphics for the ASCII characters from
;      $20 (" ") to $7F ("[DEL]")
; a1 | Palette data to load and use
;      - Set to 0 to skip
;
; Breaks:
; ALL
;
; Notes:
; - Only call this when the VDP DISPLAY is Off, or
;   during VBlank
; --------------------------------------------------------

Video_PrintInit:
; 		lea	(ASCII_FONT).l,a0
; 		lea	(ASCII_PAL).l,a1
		move.l	a0,d0
		move.w	#cell_vram(SET_PrintVram),d1
		move.w	#($60*$20),d2			; Graphics data from " " to "[DEL]"
		move.w	#(SET_PrintPal<<13)|SET_PrintVram,d3
		subi.w	#$20,d3
		move.w	d3,(RAM_VidPrntVram).w
		bsr	Video_LoadArt
Video_PrintPal:
		move.l	a1,d0
		beq.s	.skip_pal
		movea.l	d0,a0
		moveq	#(SET_PrintPal<<4),d0
		move.w	#$0F,d1
		bsr	Video_LoadPal			; Write to both palette buffers
		bra	Video_FadePal
.skip_pal:
		rts

; --------------------------------------------------------
; Video_Print
;
; Prints string to layer
;
; Input:
; a0   | String data incl. RAM locations if used.
; d0.l | Screen location:
;        locate(x_pos,y_pos,layer)
;
; Notes:
; - CALL Video_PrintInit FIRST
; - YOU MUST put an "align 2" at the end of the
;   text string to prevent an ADDRESS ERROR
; --------------------------------------------------------

; Text string special codes:
; $00 - End of line
; $0A - Next line
; "//b" - Show BYTE value
; "//w" - Show WORD value
; "//l" - Show LONG value
;
; If using //b //w //l:
; After $00, put your RAM addresses in LONGS in the
; same order you placed your value tags, don't forget to
; put "align 2" at the end of the string or it will
; trigger and ADDRESS ERROR
;
; TODO: negative values might break

Video_Print:
		movem.l	d4-d7/a4-a6,-(sp)
		lea	(vdp_data).l,a6
		bsr	vid_PickLayer
		lea	(RAM_VidPrntList).w,a5
.newjump:
		move.l	d5,4(a6)
		move.l	d5,d4
.loop:
		move.b	(a0)+,d7
		andi.w	#$FF,d7
		beq	.exit
		cmpi.b	#$0A,d7			; $0A - next line?
		beq.s	.next
		cmpi.b	#$5C,d7			; $5C ("\") special?
		bne.s	.puttext
		move.b	(a0)+,d7		; Read next chr
		cmpi.b	#"b",d7
		beq.s	.isbyte
		cmpi.b	#"w",d7
		beq.s	.isword
		cmpi.b	#"l",d7
		beq.s	.islong
		move.w	#"\\",d7		; normal "\"
.puttext:
		add.w	(RAM_VidPrntVram).w,d7	; VRAM pos increment
		move.w	d7,(a6)
		addi.l	#$20000,d4		; Next X
		bra.s	.loop
.next:
		add.l	d6,d5			; Next line
		bra.s	.newjump

; Set print values
.isbyte:
		move.l	d4,(a5)+
		move.w	#1,(a5)+
		addi.l	#$40000,d4
		move.l	d4,4(a6)
		bra	.loop
.isword:
		move.l	d4,(a5)+
		move.w	#2,(a5)+
		addi.l	#$80000,d4
		move.l	d4,4(a6)
		bra	.loop
.islong:
		move.l	d4,(a5)+
		move.w	#3,(a5)+
		addi.l	#$100000,d4
		move.l	d4,4(a6)
		bra	.loop
.exit:

; ----------------------------------------
; Print values
;
; vvvv vvvv tttt
; v - vdp pos
; t - value type
; ----------------------------------------

; reading byte by byte so you don't need
; to re-align anything...
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		lea	(RAM_VidPrntList).w,a5
.nextv:
		tst.l	(a5)
		beq	.nothing
		moveq	#0,d4		; grab value
		move.b	(a0)+,d4
		rol.l	#8,d4
		move.b	(a0)+,d4
		rol.l	#8,d4
		move.b	(a0)+,d4
		rol.l	#8,d4
		move.b	(a0)+,d4
		movea.l	d4,a4
		moveq	#0,d4
	; get value
		move.w	4(a5),d6
		cmpi.w	#1,d6		; byte?
		bne.s	.vbyte
		move.b	(a4),d4
		move.l	(a5),4(a6)
		rol.b	#4,d4
		bsr.s	.donibl
		rol.b	#4,d4
		bsr.s	.donibl
.vbyte:
		cmpi.w	#2,d6		; word?
		bne.s	.vword
		move.b	(a4),d4
		rol.w	#8,d4
		move.b	1(a4),d4
		move.l	(a5),4(a6)
		rol.w	#4,d4
		bsr.s	.donibl
		rol.w	#4,d4
		bsr.s	.donibl
		rol.w	#4,d4
		bsr.s	.donibl
		rol.w	#4,d4
		bsr.s	.donibl
.vword:
		cmpi.w	#3,d6		; long?
		bne.s	.vlong
		move.b	(a4),d4
		rol.l	#8,d4
		move.b	1(a4),d4
		rol.l	#8,d4
		move.b	2(a4),d4
		rol.l	#8,d4
		move.b	3(a4),d4
		move.l	(a5),4(a6)
		move.w	#7,d6
.lngloop:	rol.l	#4,d4
		bsr.s	.donibl
		dbf	d6,.lngloop
.vlong:
		clr.l	(a5)+
		clr.w	(a5)+
		bra	.nextv
; make nibble byte
.donibl:
		move.w	d4,d5
		andi.w	#%1111,d5
		cmpi.b	#$A,d5
		blt.s	.lowr
		add.b	#7,d5
.lowr:
		add.w	#"0",d5
		add.w	(RAM_VidPrntVram).w,d5
		move.w	d5,(a6)
		rts
; exit
.nothing:
		movem.l	(sp)+,d4-d7/a4-a6
		rts

; ------------------------------------------------
; Shared: pick layer / x pos / y pos and set size
;
; Input:
; d0.l | locate(layer,x,y)
;
; Returns:
; d5.l | VRAM position
; d6.l | Width
; ------------------------------------------------

vid_PickLayer:
		move.l	d0,d6			; d6 - pick layer
		swap	d6
		btst	#0,d6
		beq.s	.plawnd
		move.b	(RAM_VdpRegs+4).w,d5	; BG
		move.w	d5,d4
		lsr.w	#1,d4
		andi.w	#%11,d4
		swap	d5
		move.w	d4,d5
		swap	d5
		andi.w	#1,d5
		lsl.w	#8,d5
		lsl.w	#5,d5
		bra.s	.golyr
.plawnd:
		move.b	(RAM_VdpRegs+2).w,d5	; FG
		btst	#1,d6
		beq.s	.nowd
		move.b	(RAM_VdpRegs+3).w,d5	; WINDOW
.nowd:
		move.w	d5,d4
		lsr.w	#4,d4
		andi.w	#%11,d4
		swap	d5
		move.w	d4,d5
		swap	d5
		andi.w	#%00001110,d5
		lsl.w	#8,d5
		lsl.w	#2,d5
.golyr:
		ori.w	#$4000,d5
		move.w	d0,d4			; Y start pos
		andi.w	#$FF,d4			; Y only
		lsl.w	#6,d4
		move.b	(RAM_VdpRegs+$10).w,d6
		andi.w	#%11,d6
		beq.s	.thissz
		add.w	d4,d4			; H64
		andi.w	#%10,d6
		beq.s	.thissz
		add.w	d4,d4			; H128
.thissz:
		add.w	d4,d5
		move.w	d0,d4
		andi.w	#$FF00,d4		; X only
		lsr.w	#7,d4
		add.w	d4,d5			; X add
		swap	d5
		moveq	#0,d6
		move.w	#$40,d6			; Set jump size
		move.b	(RAM_VdpRegs+$10).w,d4
		andi.w	#%11,d4
		beq.s	.thisszj
		add.w	d6,d6			; H64
		andi.w	#%10,d4
		beq.s	.thisszj
		add.w	d6,d6			; H128
.thisszj:
		swap	d6
		rts

; ====================================================================
; ----------------------------------------------------------------
; Objects system
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init/Clear Objects system
; --------------------------------------------------------

Objects_Clear:
		lea	(RAM_Objects).w,a6
		move.w	#(sizeof_mdobj*MAX_MDOBJ)-1,d7
.clr:
		clr.b	(a6)+
		dbf	d7,.clr
		lea	(RAM_ObjDispList).w,a6
		move.w	#MAX_MDOBJ-1,d7
.clr_d:
		clr.w	(a6)+
		dbf	d7,.clr_d
		move.w	#1,(RAM_SprLinkNum).w
		move.w	(RAM_SprAutoDmaSet).w,(RAM_SprAutoDmaCurr).w
		clr.w	(RAM_SprDrwCntr).w
		rts

; --------------------------------------------------------
; Process object code
; --------------------------------------------------------

Objects_Run:
		lea	(RAM_Objects).w,a6
		move.w	#MAX_MDOBJ-1,d7
.next_one:
		move.l	obj_code(a6),d6
		beq.s	.no_code	; Free slot
		move.l	d7,-(sp)
		move.l	d6,a5
		jsr	(a5)
		move.l	(sp)+,d7
.no_code:
		adda	#sizeof_mdobj,a6
		dbf	d7,.next_one
		rts

; --------------------------------------------------------
; Objects_Set
;
; Input:
; d0.l | Object code pointer
;        If 0: Delete the object
; d1.w | Object slot
; d2.b | Object sub-type (obj_subid)
;
; Breaks:
; d7,a5-a6
; --------------------------------------------------------

Objects_Set:
		movem.l	d7/a5-a6,-(sp)
		lea	(RAM_Objects).w,a6
		move.l	a6,a5
		move.w	#sizeof_mdobj-1,d7
.clr:
		clr.b	(a5)+
		dbf	d7,.clr
		move.w	d1,d7
		mulu.w	#sizeof_mdobj,d7
		adda	d7,a6
		tst.l	d0
		beq.s	.from_del
		move.l	d0,obj_code(a6)
		move.b	d2,obj_subid(a6)
.from_del:
		lea	(RAM_ObjDispList).w,a6	; Remove last display slot
		move.w	d1,d7
		add.w	d7,d7
		move.w	#0,(a6,d7.w)
		movem.l	(sp)+,d7/a5-a6
		rts

; --------------------------------------------------------
; Objects_Add
;
; Input:
; d0.l | Object code pointer
; d1.b | Object sub-type (obj_subid)
;
; Returns:
; d0.l | Sets -1 if no free slot found.
;
; Breaks:
; d6-d7,a5-a6
; --------------------------------------------------------

Objects_Add:
		movem.l	d6-d7/a5-a6,-(sp)
		lea	(RAM_Objects).w,a6
		lea	(RAM_ObjDispList).w,a5
		moveq	#0,d6
		move.w	#MAX_MDOBJ-1,d7
.search:
		move.l	obj_code(a6),d7
		beq.s	.use_it
		addq.w	#1*2,d6
		adda	#sizeof_mdobj,a6
		dbf	d7,.search
		moveq	#-1,d0			; Return ran-out flag
		rts
.use_it:
; 		add.w	d6,d6
		move.w	#0,(a5,d6.w)		; Remove last display slot
		move.l	a6,a5
		move.w	#sizeof_mdobj-1,d7
.clr:
		clr.b	(a5)+
		dbf	d7,.clr
		tst.l	d0
		beq.s	.from_del
		move.l	d0,obj_code(a6)
		move.b	d1,obj_subid(a6)
.from_del:
		movem.l	(sp)+,d6-d7/a5-a6
		rts

; --------------------------------------------------------
; Draw ALL Objects from display list
;
; Call this BEFORE VBlank.
;
; Breaks:
; d0-d7/a4-a6
; --------------------------------------------------------

Objects_Show:
		move.w	(RAM_SprLinkNum).w,d6	; d6 - Starting sprite link
		lea	(RAM_Sprites).w,a6	; a6 - Genesis sprites
		lea	(RAM_ObjDispList).w,a5
		move.w	#MAX_MDOBJ-1,d7
.next:
		move.w	(a5),d0
		beq	.finish
		clr.w	(a5)+			; Clear original slot
		moveq	#-1,d1			; Write the $FFFFxxxx part and
		move.w	d0,d1			; the half-address
		move.l	d1,a4			; Read object to a4
		move.l	obj_map(a4),a0		; Read this object's map
		move.w	obj_frame(a4),d0
		move.b	obj_set(a4),d4
		add.w	d0,d0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
		move.w	(a0)+,d5
		beq	.mk_spr
		subi.w	#1,d5
.mk_pz:
		cmpi.w	#80,d6
		bgt	.ran_out
		swap	d5
		swap	d6
		move.b	(a0)+,d0		; d0 - Y pos
		move.b	(a0)+,d1		; d1 - Size
		move.w	(a0)+,d2		; d2 - VRAM main
		adda	#2,a0			; <-- Reserved for VRAM double-interlace
		move.w	(a0)+,d3		; d3 - X pos
		ext.w	d0
	; X/Y flip checks
		move.w	obj_vram(a4),d5
		btst	#bitobj_flipV,d4
		beq.s	.vram_v
		neg.w	d0
		subi.w	#8,d0
		move.w	d1,d6
		andi.w	#%0011,d6
		lsl.w	#3,d6
		sub.w	d6,d0
		ori.w	#$1000,d5
.vram_v:
		btst	#bitobj_flipH,d4
		beq.s	.vram_h
		neg.w	d3
		subi.w	#8,d3
		move.w	d1,d6
		andi.w	#%1100,d6
		add.w	d6,d6
		sub.w	d6,d3
		ori.w	#$0800,d5
.vram_h:
		add.w	d5,d2
		add.w	obj_y(a4),d0
		add.w	obj_x(a4),d3
		add.w	#$80,d0
		add.w	#$80,d3
		swap	d6
		lsl.w	#8,d1			; Size + Link
		or.w	d6,d1
		move.w	d0,(a6)+
		move.w	d1,(a6)+
		move.w	d2,(a6)+
		move.w	d3,(a6)+
		add.w	#1,d6
		swap	d5
		dbf	d5,.mk_pz
.mk_spr:
		dbf	d7,.next
.finish:
		lea	(RAM_Sprites).w,a6	; Check last sprite piece
		cmpi.w	#1,d6
		beq.s	.ran_out
		cmpi.w	#80,d6
		bgt.s	.ran_out
		move.w	d6,d7
		subi.w	#1,d7
		lsl.w	#3,d7
		adda	d7,a6
		clr.l	(a6)+
		clr.l	(a6)+
.ran_out:
		move.w	d6,(RAM_SprLinkNum).w
		rts

; ====================================================================
; --------------------------------------------------------
; Object subroutines
;
; These can ONLY be called on the current object's code.
; --------------------------------------------------------

; --------------------------------------------------------
; object_ResetVars
;
; Call this BEFORE using animation
;
; Input:
; a6 | This object
;
; Breaks:
; d7
; --------------------------------------------------------

object_ResetVars:
		movem.l	d6-d7/a5,-(sp)
		lea	obj_ram(a6),a5
		move.w	#(sizeof_mdobj-obj_ram)-1,d6
		moveq	#0,d7
.clr_ram:	move.b	d7,(a5)+
		dbf	d6,.clr_ram
		movem.l	(sp)+,d6-d7/a5
		rts

; --------------------------------------------------------
; object_Display
;
; Makes this object visible, requires sprite map data
; (obj_map) and VRAM location (obj_vram) set up
; before calling this.
;
; Input:
; a6 | This object
;
; Returns:
; d0 | -1 If ran out of display slots
;
; Breaks:
; a5,d4-d7
; --------------------------------------------------------

; *** GENESIS map ***
; mapdata:
;       dc.w .frame0-mapdata
;       dc.w .frame1-mapdata
;       ...
; .frame0:
;       dc.w numofpz
;       dc.b YY,SS
;       dc.w vram_normal
;       dc.w vram_half
;       dc.w XXXX
;       ; next frame
;       align 2
;
; *** 32X map ***
; TODO

object_Display:
		movem.l	d7/a5,-(sp)
		lea	(RAM_ObjDispList).w,a5
		move.w	#MAX_MDOBJ-1,d7
.srch:
		tst.w	(a5)
		beq.s	.this_one
		adda	#2,a5
		dbf	d7,.srch
		moveq	#-1,d0
		bra.s	.ran_out
.this_one:
		move.w	a6,(a5)
.ran_out:
		movem.l	(sp)+,d7/a5
		rts

; --------------------------------------------------------
; object_DMA, object_DMA_Auto
;
; Makes DMA graphics entry for this object,
; for Genesis VDP Sprites ONLY.
;
; Input:
; a6   | This object
; a0   | DMA map data
; a1   | Graphics data
;
; Returns:
; d1.w | New VRAM Position for _Auto
;
; Notes:
; - Calling the _Auto version will
;   OVERWRITE obj_vram with the available
;   position for output.
; --------------------------------------------------------

object_DMA_Auto:
		movem.l	d0-d2/d4-d7/a5,-(sp)
		move.w	(RAM_SprAutoDmaCurr).w,d1
		move.w	obj_vram(a6),d4
		andi.w	#$F800,d4
		or.w	d1,d4
		move.w	d4,obj_vram(a6)
		bsr.s	objMkDMA_Go
		move.w	d1,(RAM_SprAutoDmaCurr).w
		movem.l	(sp)+,d0-d2/d4-d7/a5
		rts

; ------------------------------------------------

object_DMA:
		movem.l	d0-d2/d4-d7/a5,-(sp)
		bsr.s	objMkDMA_Go
		movem.l	(sp)+,d0-d2/d4-d7/a5
		rts

; ------------------------------------------------

objMkDMA_Go:
		btst	#bitobj_Mars,obj_set(a6)
		bne.s	.no_dma
		move.l	a1,d3			; d3 - BASE graphics data
		move.w	obj_frame(a6),d4	; d4 - Current frame
 		add.w	d4,d4
		move.w	(a0,d4.w),d4
 		adda	d4,a0
 		moveq	#0,d4
 		move.w	(a0)+,d4
 		beq.s	.no_dma			; If no valid entries, skip
 		bmi.s	.no_dma
 		subq.w	#1,d4
		move.w	obj_vram(a6),d1
		andi.w	#$7FF,d1
		lsl.w	#5,d1
		move.l	a6,-(sp)		; SAVE a6
.next_pz:
		swap	d4
		move.w	(a0)+,d4
		move.w	d4,d2
		lsr.w	#7,d2
		andi.w	#$1E0,d2
		add.w	#$20,d2
		moveq	#0,d0
		move.w	d4,d0
		andi.w	#$FFF,d0
		lsl.w	#5,d0
		add.l	d3,d0
		bsr	Video_DmaMkEntry
		add.w	d2,d1
		swap	d4
		dbf	d4,.next_pz
		move.l	(sp)+,a6		; Restore a6
		lsr.w	#5,d1			; Return d1
.no_dma:
		rts

; --------------------------------------------------------
; object_Animate
;
; Animates the sprite
;
; Input:
; a6 | This object
; a0 | Animation data
;
; Notes:
; - Calling this will OVERWRITE obj_frame with the
;   new frame number set on the animation sequence.
; --------------------------------------------------------

; anim_data:
; 	dc.w .frame_1-anim_data
; 	dc.w .frame_2-anim_data
; 	;...
;
; .frame_num:
; 	dc.w $speed			; Animation speed
; 	dc.w $frame_0,$frame_1,...	; Frames list
; 	dc.w $command			; End-of-data action command
;
; $command:
; | -1 Finish animation, ends at last frame
; | -2 Loop animation, goes back to index 0
; | -3 Go to index:
; |    dc.w -3,to_slot

object_Animate:
		movem.l	a0/d5-d7,-(sp)
		moveq	#0,d7
 		move.b	obj_anim_icur(a6),d7
 		cmp.b	obj_anim_id(a6),d7
 		beq.s	.sameThing
 		move.b	obj_anim_id(a6),obj_anim_icur(a6)
 		clr.w	obj_anim_indx(a6)
 		clr.b	obj_anim_spd(a6)
.sameThing:
 		move.b	obj_anim_id(a6),d7
 		cmpi.b	#-1,d7
 		beq.s	.return
 		add.w	d7,d7
 		move.w	(a0,d7.w),d7
 		lea	(a0,d7.w),a0
 		move.w	(a0)+,d7
 		cmpi.w	#-1,d7
 		beq.s	.keepspd
 		subi.b	#1,obj_anim_spd(a6)
 		bpl.s	.return
		move.b	d7,obj_anim_spd(a6)
.keepspd:
 		moveq	#0,d6
 		move.w	obj_anim_indx(a6),d7
 		add.w	d7,d7
 		move.w	(a0),d6
 		adda	d7,a0
 		move.w	(a0),d5
 		cmpi.w	#-1,d5
 		beq.s	.lastFrame	; finish
 		cmpi.w	#-2,d5
 		beq.s	.noAnim		; loop animation
 		cmpi.w	#-3,d5
 		beq.s	.goToFrame
 		move.w	d5,obj_frame(a6)
 		add.w	#1,obj_anim_indx(a6)
.return:
 		bra.s	.exit_anim
.noAnim:
 		move.w	#1,obj_anim_indx(a6)
 		move.w	d6,d5
 		move.w	d5,obj_frame(a6)
		bra.s	.exit_anim
.goToFrame:
		clr.w	obj_anim_indx(a6)
		move.w	2(a0),obj_anim_indx(a6)
.lastFrame:
 		clr.b	obj_anim_spd(a6)
.exit_anim:
		movem.l	(sp)+,a0/d5-d7
		rts

; --------------------------------------------------------
; object_ResetAnim
;
; Call this to reset animation
;
; Input:
; a6 | This object
; --------------------------------------------------------

object_ResetAnim:
 		clr.w	obj_anim_indx(a6)
 		clr.b	obj_anim_spd(a6)
		move.b	#0,obj_anim_icur(a6)
		rts

; --------------------------------------------------------
; object_Speed
;
; Moves the object using speed variables
;
; Input:
; a6 | This object
;
; Breaks:
; d7
; --------------------------------------------------------

object_Speed:
		move.l	d7,-(sp)
		moveq	#0,d7
		move.w	obj_x_spd(a6),d7
		ext.l	d7
		asl.l	#8,d7
		add.l	d7,obj_x(a6)
		moveq	#0,d7
		move.w	obj_y_spd(a6),d7
		ext.l	d7
		asl.l	#8,d7
		add.l	d7,obj_y(a6)
		move.l	(sp)+,d7
		rts

; --------------------------------------------------------
; object_Collision
;
; Detects collision with another Object from
; the list TOP to BOTTOM
; Reads ALL objects except the one that called this.
;
; Input:
; a6 | Object
;
; Returns:
; d0 | If Nothing: Zero
;      If Found: The object's RAM location it got.
;
; Breaks:
; d1-d7,a5
; --------------------------------------------------------

object_Collision:
		movem.l	d1-d7/a5,-(sp)
		lea	(RAM_Objects).w,a5
		moveq	#MAX_MDOBJ-1,d7
.next:
		cmp.l	a6,a5		; If reading THIS object, skip
		beq.s	.skip
		tst.l	obj_code(a5)	; This object has code?
		beq.s	.skip
		bsr.s	.check_this
		tst.w	d0
		bne.s	.exit_this	; Exit if Found already.
.skip:		adda	#sizeof_mdobj,a5
		dbf	d7,.next
		moveq	#0,d0
.exit_this:
		movem.l	(sp)+,d1-d7/a5
		rts
.check_this:
		moveq	#0,d0			; Reset Return
	; d6 - Y current top
	; d5 - Y current bottom
	; d4 - Y target top
	; d3 - Y target bottom
		move.w	obj_y(a6),d6		; d6 - Up point
		move.w	d6,d5			; d5 - Down point
		move.w	obj_size(a6),d1		; $UDxx
		move.w	d1,d2
		lsr.w	#8,d1			; d1 - Up size
		andi.w	#$FF,d2			; d2 - Down size
		lsl.w	#3,d1
		lsl.w	#3,d2
		sub.w	d1,d6
		add.w	d2,d5
		move.w	obj_y(a5),d4		; d4 - Up point
		move.w	d4,d3			; d3 - Down point
		move.w	obj_size(a5),d1		; $UDxx
		move.w	d1,d2
		lsr.w	#8,d1			; d1 - Up size
		andi.w	#$FF,d2			; d2 - Down size
		lsl.w	#3,d1
		lsl.w	#3,d2
		sub.w	d1,d4
		add.w	d2,d3
		cmp.w	d6,d3			; Target's YB > Our YT?
		blt.s	.not_ytop
		cmp.w	d5,d4			; Target's YT > Our YB?
		bge.s	.not_ytop
	; Now check X
		move.w	obj_x(a6),d6		; d6 - Left point
		move.w	d6,d5			; d5 - Right point
		move.w	obj_size+2(a6),d1	; $xxLR
		move.w	d1,d2
		lsr.w	#8,d1			; d1 - Left size
		andi.w	#$FF,d2			; d2 - Right size
		lsl.w	#3,d1
		lsl.w	#3,d2
		sub.w	d1,d6
		add.w	d2,d5
		move.w	obj_x(a5),d4		; d4 - Left point
		move.w	d4,d3			; d3 - Right point
		move.w	obj_size+2(a5),d1	; $UDxx
		move.w	d1,d2
		lsr.w	#8,d1			; d1 - Left size
		andi.w	#$FF,d2			; d2 - Right size
		lsl.w	#3,d1
		lsl.w	#3,d2
		sub.w	d1,d4
		add.w	d2,d3
		cmp.w	d6,d3
		blt.s	.not_ytop
		cmp.w	d5,d4
		bge.s	.not_ytop
		move.l	a5,d0		; FOUND OBJECT
.not_ytop:
		rts

; ====================================================================
; ----------------------------------------------------------------
; 32X ONLY
; ----------------------------------------------------------------

	if MARS|MARSCD

; --------------------------------------------------------
; Video_MdMarsMap_Set
; --------------------------------------------------------

Video_MdMarsMap_Set:
		lea	(RAM_MdDreq+Dreq_ScrlBuff).w,a6
		move.l	d0,mscrl_Art(a6)
		clr.l	mscrl_Xpos(a6)
		clr.l	mscrl_Ypos(a6)
		move.w	d1,mscrl_Xpos(a6)
		move.w	d2,mscrl_Ypos(a6)
		rts

; --------------------------------------------------------
; Video_MdMarsMap_Load
;
; Input:
; a0   | Map data
; d0.w | X block pos
; d1.w | Y block pos
; d2.w | X block size
; d3.w | Y block size
; d4.w | Starting color index
;
; Breaks:
; d5-d7/a2-a5
; --------------------------------------------------------

Video_MdMarsMap_Load:
		lea	(RAM_MdDreq+Dreq_ScrlData).w,a5
		moveq	#0,d6
		move.w	d1,d6
		lsl.w	#7,d6	; Manual Y size
		add.l	d6,a5
		move.w	d0,d6
		add.w	d6,d6
		adda	d6,a5

		move.l	a0,a2
		move.w	d4,d5
		andi.w	#$F8,d5
		lsl.w	#8,d5
		move.w	d3,d7
		subq.w	#1,d7
.copy_y:
		swap	d7
		swap	d6
		move.l	a2,a3
		move.l	a5,a4
		move.w	d2,d7
		subq.w	#1,d7
.copy_x:
		move.w	(a3)+,d6
		andi.w	#$7FF,d6
		add.w	d5,d6
		move.w	d6,(a4)+
		dbf	d7,.copy_x

		move.w	#512/16,d6
; 		move.l	a3,a0
		move.w	d2,d7
		add.w	d7,d7
		adda	d7,a2
		move.w	d6,d7
		add.w	d7,d7
		adda	d7,a5

		swap	d6
		swap	d7
		dbf	d7,.copy_y
		rts

; --------------------------------------------------------

	endif
