; ===========================================================================
; ----------------------------------------------------------------
; SCREEN CODE
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

setVram_Mikami		equ $0440
setVram_Sisi		equ $0480

; ====================================================================
; ------------------------------------------------------
; Structs
; ------------------------------------------------------

; 			strct 0
; strc_xpos		ds.w 1
; strc_ypos		ds.w 1
; 			endstrct

; ====================================================================
; ------------------------------------------------------
; This mode's RAM
; ------------------------------------------------------

			strct RAM_ScrnBuff
RAM_CurrPick		ds.w 1
RAM_GemaArg0		ds.w 1
RAM_GemaArg1		ds.w 1
RAM_GemaArg2		ds.w 1
RAM_GemaArg3		ds.w 1
RAM_GemaArg4		ds.w 1
RAM_GemaArg5		ds.w 1
RAM_GemaArg6		ds.w 1
RAM_ChnlLinks		ds.w 26
sizeof_thisbuff		ds.l 0
			endstrct

	erreport "SCREEN",sizeof_thisbuff-RAM_ScrnBuff,MAX_ScrnBuff

; ====================================================================
; ------------------------------------------------------
; Init
; ------------------------------------------------------

		bsr	Mode_Init
		load_banks file_mddata_def,pointr_marsdata_def

	; ----------------------------------------------
	; Load assets
	if MARS|MARSCD
		lea	(PalMars_TEST),a0
		move.w	#0,d0
		move.w	#256,d1
		moveq	#0,d2
		bsr	Video_MdMars_FadePal
		move.l	#ArtMars_TEST,d0
		moveq	#0,d1
		moveq	#0,d2
		bsr	Video_MdMarsMap_Set
		lea	(MapMars_TEST),a0
		moveq	#0,d0
		moveq	#0,d1
		move.w	#320/16,d2
		move.w	#224/16,d3
		move.w	#0,d4
		bsr	Video_MdMarsMap_Load
		moveq	#1,d0
		bsr	Video_MdMars_VideoMode
	endif
	if MARS|MARSCD=0
		move.l	#ART_TEST,d0
		move.w	#cell_vram($0001),d1
		move.w	#ART_TEST_E-ART_TEST,d2
		bsr	Video_LoadArt
		lea	(MAP_TEST),a0			; long lea
		move.l	#locate(0,0,1),d0
		move.l	#map_size(320,224),d1
		move.w	#$0001,d2
		bsr	Video_LoadMap
	endif
		lea	(ASCII_FONT_S1).l,a0
		lea	(ASCII_PAL).l,a1
		bsr	Video_PrintInit
		move.l	#Art_Sisi,d0
		move.w	#cell_vram(setVram_Sisi),d1
		move.w	#Art_Sisi_e-Art_Sisi,d2
		bsr	Video_LoadArt

		lea	PAL_TEST(pc),a0
		moveq	#0,d0
		move.w	#16,d1
		bsr	Video_FadePal
		lea	(objPal_Sisi),a0
		moveq	#16,d0
		move.w	#16,d1
		bsr	Video_FadePal
		lea	str_TesterInit(pc),a0
		move.l	#locate(1,1,0),d0
		bsr	Video_Print
; 		move.l	#Object_Mikami,d0
; 		moveq	#0,d1
; 		bsr	Objects_Set
		move.l	#Object_Sisi,d0
		bsr	Objects_Add
	; ----------------------------------------------
		clr.w	(RAM_GemaArg0).w
		clr.w	(RAM_GemaArg1).w
		clr.w	(RAM_GemaArg2).w
		clr.w	(RAM_GemaArg3).w
		clr.w	(RAM_GemaArg4).w
		clr.w	(RAM_GemaArg5).w
		move.w	#212,(RAM_GemaArg6).w
		move.w	#212,d0
		bsr	gemaSetBeats
; 		moveq	#1,d0
; 		bsr	gemaPlayTrack

	; ----------------------------------------------
		bsr	.show_me
; 		bsr	.steal_vars
		bsr	Objects_Run
	; ----------------------------------------------
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l		; Enable display
		move.b	#%10000001,(RAM_VdpRegs+$C).w		; H40 + shadow mode
		bsr	Video_Update
		bsr	Video_FadeIn

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	System_Render

; 		bsr	.steal_vars
		bsr	Objects_Run
		lea	str_Info(pc),a0
		move.l	#locate(31,26,0),d0
		bsr	Video_Print

; 	; Controls
; 	if MCD|MARSCD
; 		lea	(Controller_1).w,a6
; 		move.w	on_press(a6),d7
; 		btst	#bitJoyMode,d7
; 		beq.s	.n_aplay
; ; 		moveq	#1,d0
; ; 		bsr	Video_MdMarsGfxMode
; 		move.w	#$0002,(sysmcd_reg+mcd_dcomm_m).l
; 		move.w	#$0010,d0
; 		bsr	System_McdSubTask
; .n_aplay:
; 	endif

		lea	(Controller_1).w,a6
		lea	(RAM_CurrPick).w,a5
	; UP/DOWN
		move.w	on_hold(a6),d7
		andi.w	#JoyA+JoyB+JoyC,d7
		bne.s	.n_up
		move.w	on_press(a6),d7
		btst	#bitJoyDown,d7
		beq.s	.n_down
		cmp.w	#7,(a5)		; MAX OPTIONS
		beq.s	.n_down
		addq.w	#1,(a5)
		bsr.s	.show_me
.n_down:
		move.w	on_press(a6),d7
		btst	#bitJoyUp,d7
		beq.s	.n_up
		tst.w	(a5)
		beq.s	.n_up
		subq.w	#1,(a5)
		bsr.s	.show_me
.n_up:
		move.w	(RAM_CurrPick).w,d7
		lsl.w	#2,d7
		jsr	.jump_list(pc,d7.w)
		tst.w	(RAM_ScreenMode).w	; Check -1
		bpl.s	.n_cbtn
		bsr	gemaStopAll
		bsr	System_Render
		bsr	Video_FadeOut
		move.w	#0,(RAM_ScreenMode).w	; Return to mode 0
		rts				; EXIT
.n_cbtn:
		bra	.loop
; ------------------------------------------------------

.show_me:
		lea	str_ShowMe(pc),a0
		move.l	#locate(23,5,0),d0
		bra	Video_Print

; ------------------------------------------------------

.jump_list:
		bra.w	.nothing
		bra.w	.option_1
		bra.w	.option_2
		bra.w	.option_3
		bra.w	.option_4
		bra.w	.option_5
		bra.w	.option_6
		bra.w	.option_7

; ------------------------------------------------------
; OPTION 0
; ------------------------------------------------------

.nothing:
		move.w	on_press(a6),d7
		btst	#bitJoyStart,d7
		beq.s	.no_press
		bsr.s	.show_me
		bra	gemaTest
.no_press:
		rts

; ------------------------------------------------------
; OPTION 1
; ------------------------------------------------------

.option_1:
		lea	(RAM_GemaArg0).w,a5
		move.w	on_press(a6),d7
		btst	#bitJoyStart,d7
		beq.s	.option1_args
		move.w	(a5)+,d0
		move.w	(a5)+,d1
		move.w	(a5)+,d2
		bsr	gemaPlayTrack
		move.w	(RAM_GemaArg1).w,d0
		move.w	d0,d1
		add.w	d1,d1
		lea	.extnal_beats(pc),a0
		move.w	(a0,d1.w),d0
		bra	gemaSetBeats
; 		bra.s	.show_me
.option1_args:
		move.w	on_hold(a6),d7
		move.w	d7,d6
		andi.w	#JoyA+JoyB+JoyC,d6
		beq.s	.no_press
		btst	#bitJoyB,d7
		beq.s	.d2_opt
		adda	#2,a5
.d2_opt:
		btst	#bitJoyC,d7
		beq.s	.d3_opt
		adda	#4,a5
.d3_opt:
		move.w	on_press(a6),d7
		btst	#bitJoyRight,d7
		beq.s	.op1_right
		addq.w	#1,(a5)
		bra	.show_me
.op1_right:
		btst	#bitJoyLeft,d7
		beq.s	.op1_left
		subq.w	#1,(a5)
		bra	.show_me
.op1_left:
		move.w	on_hold(a6),d7
		btst	#bitJoyUp,d7
		beq.s	.op1_down
		addq.w	#1,(a5)
		bra	.show_me
.op1_down:
		btst	#bitJoyDown,d7
		beq.s	.op1_up
		subq.w	#1,(a5)
		bra	.show_me
.op1_up:

		rts

; ------------------------------------------------------
; OPTION 2
; ------------------------------------------------------

.option_2:
		lea	(RAM_GemaArg0).w,a5
		move.w	on_press(a6),d7
		btst	#bitJoyStart,d7
		beq.s	.option1_args
		move.w	(a5)+,d0
		move.w	(a5)+,d1
		bra	gemaStopTrack

; ------------------------------------------------------
; OPTION 3
; ------------------------------------------------------

.option_3:
		lea	(RAM_GemaArg3).w,a5
		move.w	on_press(a6),d7
		btst	#bitJoyStart,d7
		beq	.option1_args
		move.w	(a5)+,d0
		move.w	(a5)+,d1
		bra	gemaFadeTrack

; ------------------------------------------------------
; OPTION 4
; ------------------------------------------------------

.option_4:
		lea	(RAM_GemaArg3).w,a5
		move.w	on_press(a6),d7
		btst	#bitJoyStart,d7
		beq	.option1_args
		move.w	(a5)+,d0
		move.w	(a5)+,d1
		bra	gemaSetTrackVol

; ------------------------------------------------------
; OPTION 5
; ------------------------------------------------------

.option_5:
		move.w	on_press(a6),d7
		btst	#bitJoyStart,d7
		beq.s	.no_press2
		bsr	.show_me
		bra	gemaStopAll
.no_press2:
		rts

; ------------------------------------------------------
; OPTION 6
; ------------------------------------------------------

.option_6:
		lea	(RAM_GemaArg6).w,a5
		move.w	on_hold(a6),d7
		andi.w	#JoyB,d7
		beq.s	.no_press2
		move.w	on_press(a6),d7
		btst	#bitJoyRight,d7
		beq.s	.op2_right
		addq.w	#1,(a5)
		bra	.show_me_2
.op2_right:
		btst	#bitJoyLeft,d7
		beq.s	.op2_left
		subq.w	#1,(a5)
		bsr	.show_me_2
.op2_left:
		move.w	on_hold(a6),d7
		btst	#bitJoyDown,d7
		beq.s	.op2_down
		addq.w	#1,(a5)
		bsr	.show_me_2
.op2_down:
		btst	#bitJoyUp,d7
		beq.s	.op2_up
		subq.w	#1,(a5)
		bsr	.show_me_2
.op2_up:
		move.w	on_press(a6),d7
		btst	#bitJoyStart,d7
		beq.s	.no_press2
.show_me_2:
		bsr	.show_me
		move.w	(a5),d0
		bra	gemaSetBeats

; ------------------------------------------------------
; OPTION 7
; ------------------------------------------------------

.option_7:
		move.w	on_press(a6),d7
		btst	#bitJoyStart,d7
		beq.s	.no_press2
		move.w	#-1,(RAM_ScreenMode).w	; risky but whatever.
		rts

; ------------------------------------------------------
; EXTERNAL BEATS FOR EACH TRACK
; ------------------------------------------------------

.extnal_beats:
	dc.w 214
	dc.w 214
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+4
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32
	dc.w 200+32

; ====================================================================
; ------------------------------------------------------
; DATA assets locations for 68K and SH2
; ------------------------------------------------------

file_mddata_def:
		dc.b "DATABNKD.BIN",0		; CD Filename
		align 2
pointr_marsdata_def:
		dc.l MARSDATA_SCREEN01		; 32X Cartridge point
		dc.b "MARSD_01.BIN",0		; CD Filename
		align 2

; ====================================================================
; ------------------------------------------------------
; Objects
; ------------------------------------------------------

; ; --------------------------------------------------
; ; Mikami
; ; --------------------------------------------------
;
; Object_Mikami:
; 		moveq	#0,d0
; 		move.b	obj_index(a6),d0
; 		add.w	d0,d0
; 		move.w	.list(pc,d0.w),d1
; 		jmp	.list(pc,d1.w)
; ; ----------------------------------------------
; .list:		dc.w .init-.list
; 		dc.w .main-.list
; ; ----------------------------------------------
; .init:
; 		move.b	#1,obj_index(a6)
; 		move.l	#objMap_Mikami,obj_map(a6)
; 		move.l	#objDma_Mikami,obj_dma(a6)
; 		move.w	#setVram_Mikami|$2000,obj_vram(a6)
; 		bclr	#bitobj_Mars,obj_set(a6)	; Genesis object
; 		move.w	#(320/2)+48,obj_x(a6)
; 		move.w	#(224/2)+64,obj_y(a6)
; 		clr.w	obj_frame(a6)
; 		bsr	object_ResetAnim
; 		bset	#0,obj_status(a6)
; 		bset	#bitobj_flipH,obj_set(a6)
;
; ; ----------------------------------------------
; .main:
; 		lea	(Controller_2),a3
; 		btst	#0,obj_status(a6)
; 		beq.s	.no_fallspd
; 		add.w	#$40,obj_y_spd(a6)
; .no_fallspd:
;
; ; .fake_col_c:
; 		move.w	on_press(a3),d7
; 		btst	#bitJoyC,d7
; 		beq.s	.fake_jump
; 		btst	#0,obj_status(a6)
; 		bne.s	.fake_jump
; 		move.w	#-$500,obj_y_spd(a6)
; 		move.b	#2,obj_anim_id(a6)
; 		bset	#0,obj_status(a6)
;
; 		moveq	#$0F,d0
; 		moveq	#1,d1
; 		bsr	gemaPlayFromBlk
;
; .fake_jump:
; 		move.w	on_press(a3),d7
; 		btst	#bitJoyB,d7
; 		beq.s	.no_slash
; 		tst.w	obj_y_spd(a6)
; 		bne.s	.no_slash
; 		clr.w	obj_anim_indx(a6)
; 		move.b	#4,obj_anim_id(a6)
; 		move.w	#$10,obj_ram+2(a6)
;
; 		moveq	#$0F,d0
; 		moveq	#0,d1
; 		bsr	gemaPlayFromBlk
;
; .no_slash:
; 		clr.w	obj_x_spd(a6)
;
; 		moveq	#0,d0
; 		moveq	#0,d1
; 		move.w	on_hold(a3),d7
; 		move.w	d7,d6
; 		andi.w	#JoyLeft+JoyRight,d6
; 		beq.s	.move_mika
; 		clr.w	obj_ram+2(a6)
; 		move.w	#$180,d6
; 		btst	#bitJoyRight,d7
; 		beq.s	.no_l
; 		move.w	d6,obj_x_spd(a6)
; .no_l
; 		neg.w	d6
; 		btst	#bitJoyLeft,d7
; 		beq.s	.move_mika
; 		move.w	d6,obj_x_spd(a6)
; .move_mika:
;
;
; 		moveq	#0,d6
; 		tst.w	obj_x_spd(a6)
; 		beq.s	.r_spd
; 		moveq	#1,d6
; 		move.b	obj_set(a6),d7
; 		bclr	#bitobj_flipH,d7
; 		tst.w	obj_x_spd(a6)
; 		bpl.s	.r_flip
; 		bset	#bitobj_flipH,d7
; .r_flip:
; 		move.b	d7,obj_set(a6)
; .r_spd:
;
; 		tst.w	obj_ram+2(a6)
; 		beq.s	.free_anim
; 		subi.w	#1,obj_ram+2(a6)
; 		bne.s	.no_anim
; .free_anim:
; 		btst	#0,obj_status(a6)
; 		bne.s	.no_anim
; 		tst.w	obj_y_spd(a6)
; 		bmi.s	.is_jumpin
; 		move.b	d6,obj_anim_id(a6)
; .is_jumpin:
; 		tst.w	obj_y_spd(a6)
; 		beq.s	.no_anim
; 		move.b	#3,obj_anim_id(a6)
; .no_anim:
; 		bsr	object_Speed
;
; 		move.w	#(224-16)-32,d7
; 		move.w	obj_y(a6),d0
; 		cmp.w	d7,d0
; 		blt.s	.fake_col
; 		clr.w	obj_y_spd(a6)
; 		andi.w	#-$10,obj_y(a6)
; 		bclr	#0,obj_status(a6)
; .fake_col:
;
; ; 		move.w	(Controller_2+on_press),d7
; ; 		btst	#bitClickM,d7
; ; 		beq.s	.no_reset
; ; 		move.w	#320/2,obj_x(a6)
; ; 		move.w	#224/2,obj_y(a6)
; ; .no_reset:
; 		lea	.anim_data(pc),a0
; 		bsr	object_Animate
; 		bra	object_Display
;
; ; ----------------------------------------------
;
; .anim_data:
; 		dc.w .anim_stand-.anim_data
; 		dc.w .anim_move-.anim_data
; 		dc.w .anim_jump-.anim_data
; 		dc.w .anim_fall-.anim_data
; 		dc.w .anim_slash-.anim_data
; .anim_stand:
; 		dc.w 6
; 		dc.w 0,-1
; 		align 2
; .anim_move:
; 		dc.w 5
; 		dc.w 2,3,4,5,6,7,8,-3,1
; 		align 2
; .anim_jump:
; 		dc.w 5
; 		dc.w 10,11,12,-3,2
; 		align 2
; .anim_fall:
; 		dc.w 5
; 		dc.w 11,12,-3,1
; 		align 2
; .anim_slash:
; 		dc.w 1
; 		dc.w 14,15,16,17,-2
; 		align 2
;
; --------------------------------------------------
; Sisi
; --------------------------------------------------

Object_Sisi:
		moveq	#0,d0
		move.b	obj_index(a6),d0
		add.w	d0,d0
		move.w	.list(pc,d0.w),d1
		jmp	.list(pc,d1.w)
; ----------------------------------------------
.list:		dc.w .init-.list
		dc.w .main-.list
; ----------------------------------------------
.init:
		move.b	#1,obj_index(a6)
		move.l	#objMap_Sisi,obj_map(a6)
		move.w	#setVram_Sisi|$2000,obj_vram(a6)
; 		move.w	#320/2,obj_x(a6)
; 		move.w	#224/2,obj_y(a6)
		clr.w	obj_frame(a6)
		bsr	object_ResetAnim

; ----------------------------------------------
.main:
; 		move.w	obj_ram(a6),d0
; 		move.w	obj_ram+2(a6),d1


		moveq	#0,d0

		move.w	(RAM_CurrPick).w,d1
		lsl.w	#3,d1

		addi.w	#$18,d0
		addi.w	#$20,d1
		move.w	d0,obj_x(a6)
		move.w	d1,obj_y(a6)

; 		lea	(RAM_Objects),a0
; 		cmp.l	#Object_Mikami,obj_code(a0)
; 		bne.s	.dont_link
; 		move.w	obj_ram+2(a6),d7
; 		cmp.w	#24<<1,d7
; 		bge.s	.dont_incr
; 		add.w	#2,d7
; .dont_incr:
; 		move.w	d7,obj_ram+2(a6)
;
; 		move.w	obj_x(a0),d7
; 		move.w	obj_y(a0),d6
; 		move.w	#24,d5
; 		sub.w	d5,d6
; 		move.w	obj_ram(a6),d0
; 		moveq	#4,d1
; 		bsr	System_SineWave
; 		asr.w	#8,d2
; 		add.w	d2,d6
; 		moveq	#5,d1
; 		bsr	System_SineWave_Cos
; 		asr.w	#8,d2
; 		add.w	d2,d7
;
; 		move.b	obj_set(a6),d0
; 		move.b	obj_set(a0),d1
; 		eor.w	d1,d0
; 		andi.w	#1,d0
; 		beq.s	.same_h
; 		clr.w	obj_ram+2(a6)
; .same_h:
; 		move.w	obj_ram+2(a6),d4
; 		bclr	#bitobj_flipH,obj_set(a6)
; 		btst	#bitobj_flipH,obj_set(a0)
; 		beq.s	.dont_flipx
; 		neg.w	d4
; 		bset	#bitobj_flipH,obj_set(a6)
; .dont_flipx:
; 		lsr.w	#1,d4
; 		add.w	d4,d7
; 		move.w	d6,obj_y(a6)
; 		move.w	d7,obj_x(a6)
; 		add.w	#4,obj_ram(a6)

.dont_link:
		lea	.anim_data(pc),a0
		bsr	object_Animate
		bra	object_Display

; ----------------------------------------------

.anim_data:
		dc.w .anim_00-.anim_data
		dc.w .anim_00-.anim_data
		dc.w .anim_00-.anim_data
		dc.w .anim_00-.anim_data
.anim_00:
		dc.w 8
		dc.w 0,1,2,1
		dc.w -2
		align 2
;
; ; --------------------------------------------------
; ; Ball
; ; --------------------------------------------------
;
; Object_ball:
; 		moveq	#0,d0
; 		move.b	obj_index(a6),d0
; 		add.w	d0,d0
; 		move.w	.list(pc,d0.w),d1
; 		jmp	.list(pc,d1.w)
; ; ----------------------------------------------
; .list:		dc.w .init-.list
; 		dc.w .main-.list
; ; ----------------------------------------------
; .init:
; 		move.b	#1,obj_index(a6)
; 		move.l	#objMap_Sisi,obj_map(a6)
; 		move.l	#0,obj_dma(a6)
; 		move.w	#setVram_Sisi|$0000,obj_vram(a6)
; 		bclr	#bitobj_Mars,obj_set(a6)	; Genesis object
; 		move.w	#320/2,obj_x(a6)
; 		move.w	#224/2,obj_y(a6)
; 		clr.w	obj_frame(a6)
; 		bsr	object_ResetAnim
;
; 		move.w	#$180,obj_x_spd(a6)
; 		move.w	#$180,obj_y_spd(a6)
;
; ; ----------------------------------------------
; .main:
; 		move.w	obj_x(a6),d0
; 		move.w	obj_y(a6),d1
; 		sub.w	#16,d0
; 		sub.w	#16,d1
; 		move.w	#320-32,d2
; 		move.w	#(224-16)-32,d3
;
; 		tst.w	d1
; 		bpl.s	.on_scrn_yu
; 		neg.w	obj_y_spd(a6)
; 		bsr	.playit
; .on_scrn_yu:
; 		cmp.w	d3,d1
; 		blt.s	.on_scrn_yd
; 		neg.w	obj_y_spd(a6)
; 		bsr	.playit
; .on_scrn_yd:
;
; 		tst.w	d0
; 		bpl.s	.on_scrn_xu
; 		neg.w	obj_x_spd(a6)
; 		bsr.s	.playit
; .on_scrn_xu:
; 		cmp.w	d2,d0
; 		blt.s	.on_scrn_xd
; 		neg.w	obj_x_spd(a6)
; 		bsr.s	.playit
; .on_scrn_xd:
;
; 		bsr	object_Speed
;
; 		lea	.anim_data(pc),a0
; 		bsr	object_Animate
; 		bra	object_Display
; .playit:
; 		moveq	#$0F,d0
; 		moveq	#2,d1
; 		bra	gemaPlayFromBlk
;
; ; ----------------------------------------------
;
; .anim_data:
; 		dc.w .anim_00-.anim_data
; 		dc.w .anim_00-.anim_data
; 		dc.w .anim_00-.anim_data
; 		dc.w .anim_00-.anim_data
; .anim_00:
; 		dc.w 8
; 		dc.w 0,1,2,1,-1
; 		align 2

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Custom VBlank
; ------------------------------------------------------

; ------------------------------------------------------
; Custom HBlank
; ------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Small DATA section
; ------------------------------------------------------

PAL_TEST:
		binclude "game/screen_1/data/md/maps/test/md_pal.bin"
		align 2

; str_ShowPsg:	dc.b "\\w \\w \\w \\w",0
; 		dc.l RAM_ChnlLinks,RAM_ChnlLinks+2,RAM_ChnlLinks+4,RAM_ChnlLinks+6
; 		align 2
; str_ShowFm:	dc.b "\\w \\w \\w \\w \\w \\w",0
; 		dc.l RAM_ChnlLinks+8,RAM_ChnlLinks+10,RAM_ChnlLinks+12
; 		dc.l RAM_ChnlLinks+14,RAM_ChnlLinks+16,RAM_ChnlLinks+18
; 		align 2
; str_ShowPcm:	dc.b "\\w \\w \\w \\w",$0A
; 		dc.b "\\w \\w \\w \\w",0
; 		dc.l RAM_ChnlLinks+20,RAM_ChnlLinks+22,RAM_ChnlLinks+24,RAM_ChnlLinks+26
; 		dc.l RAM_ChnlLinks+28,RAM_ChnlLinks+30,RAM_ChnlLinks+32,RAM_ChnlLinks+34
; 		align 2
; str_ShowPwm:	dc.b "\\w \\w \\w \\w",$0A
; 		dc.b "\\w \\w \\w",0
; 		dc.l RAM_ChnlLinks+36,RAM_ChnlLinks+38,RAM_ChnlLinks+40,RAM_ChnlLinks+42
; 		dc.l RAM_ChnlLinks+44,RAM_ChnlLinks+46,RAM_ChnlLinks+48,RAM_ChnlLinks+50
; 		align 2

str_TesterInit:
		dc.b "GEMA/Nikona sound driver tester",$0A
		dc.b "                \{DATE} \{TIME}",$0A
		dc.b $0A
		dc.b "    gemaTest          (A)  (B)  (C)",$0A
		dc.b "    gemaPlayTrack",$0A
		dc.b "    gemaStopTrack",$0A
		dc.b "    gemaFadeTrack",$0A
		dc.b "    gemaSetTrackVol",$0A
		dc.b "    gemaStopAll",$0A
		dc.b "    gemaSetBeats",$0A
		dc.b "    --> EXIT"
		dc.b 0
		align 2
str_ShowMe:	dc.b "\\w \\w \\w",$A,$A
		dc.b "\\w \\w \\w",$A,$A,$A
		dc.b "\\w",0
		dc.l RAM_GemaArg0,RAM_GemaArg1,RAM_GemaArg2
		dc.l RAM_GemaArg3,RAM_GemaArg4,RAM_GemaArg5
		dc.l RAM_GemaArg6
		align 2
str_Info:
		dc.b "\\l",0
		dc.l RAM_Framecount
		align 2
; str_Notes:
;  dc.b "---",0,"C#0",0,"D-0",0,"D#0",0,"E-0",0,"F-0",0,"F#0",0,"G-0",0,"G#0",0,"A-0",0,"A#0",0,"B-0",0
;  dc.b "C-1",0,"C#1",0,"D-1",0,"D#1",0,"E-1",0,"F-1",0,"F#1",0,"G-1",0,"G#1",0,"A-1",0,"A#1",0,"B-1",0
;  dc.b "C-2",0,"C#2",0,"D-2",0,"D#2",0,"E-2",0,"F-2",0,"F#2",0,"G-2",0,"G#2",0,"A-2",0,"A#2",0,"B-2",0
;  dc.b "C-3",0,"C#3",0,"D-3",0,"D#3",0,"E-3",0,"F-3",0,"F#3",0,"G-3",0,"G#3",0,"A-3",0,"A#3",0,"B-3",0
;  dc.b "C-4",0,"C#4",0,"D-4",0,"D#4",0,"E-4",0,"F-4",0,"F#4",0,"G-4",0,"G#4",0,"A-4",0,"A#4",0,"B-4",0
;  dc.b "C-5",0,"C#5",0,"D-5",0,"D#5",0,"E-5",0,"F-5",0,"F#5",0,"G-5",0,"G#5",0,"A-5",0,"A#5",0,"B-5",0
;  dc.b "C-6",0,"C#6",0,"D-6",0,"D#6",0,"E-6",0,"F-6",0,"F#6",0,"G-6",0,"G#6",0,"A-6",0,"A#6",0,"B-6",0
;  dc.b "C-7",0,"C#7",0,"D-7",0,"D#7",0,"E-7",0,"F-7",0,"F#7",0,"G-7",0,"G#7",0,"A-7",0,"A#7",0,"B-7",0
;  dc.b "C-8",0,"C#8",0,"D-8",0,"D#8",0,"E-8",0,"F-8",0,"F#8",0,"G-8",0,"G#8",0,"A-8",0,"A#8",0,"B-8",0
;  dc.b "C-9",0,"C#9",0,"D-9",0,"D#9",0,"E-9",0,"F-9",0,"F#9",0,"G-9",0,"G#9",0,"A-9",0,"A#9",0,"B-9",0
;  align 2
; str_Notes_FM:
;  dc.b "---",0
;  dc.b "C-",0,0,"C#",0,0,"D-",0,0,"D#",0,0,"E-",0,0,"F-",0,0
;  dc.b "F#",0,0,"G-",0,0,"G#",0,0,"A-",0,0,"A#",0,0,"B-",0,0
;  align 2
; str_Octv_FM:
;  dc.b "0",0,"1",0,"2",0,"3",0,"4",0,"5",0,"6",0,"7",0
;  align 2
