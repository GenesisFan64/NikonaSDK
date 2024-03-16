; ===========================================================================
; ----------------------------------------------------------------
; SCREEN CODE
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

setVram_Emily		equ $440
setVram_Doremi		equ $440+(4*6)
setVram_Sophie		equ $440+((4*6)*2)
setVram_Nicole		equ $440+((4*6)*3)
setVram_Bibi		equ $4A0

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
RAM_SC0_Null		ds.l 1
RAM_WhoIAm		ds.l 1
sizeof_thisbuff		ds.l 0
			endstrct

	erreport "SCREEN",sizeof_thisbuff-RAM_ScrnBuff,MAX_ScrnBuff

; ====================================================================
; ------------------------------------------------------
; Init
; ------------------------------------------------------

		bsr	Mode_Init
		set_dbanks file_mddata_def,pointr_marsdata_def

	; ----------------------------------------------
	; Load assets
	if MARS|MARSCD
		lea	(PalMars_Scrn0),a0
		move.w	#0,d0
		move.w	#256,d1
		moveq	#0,d2
		bsr	Video_MdMars_FadePal
		lea	(MapMars_Scrn0),a0
		moveq	#0,d0
		moveq	#0,d1
		move.w	#320/16,d2
		move.w	#224/16,d3
		move.w	#0,d4
		bsr	Video_MdMarsMap_Load
		move.l	#ArtMars_Scrn0,d0
		moveq	#0,d1
		moveq	#0,d2
		bsr	Video_MdMarsMap_Set
		moveq	#1,d0
		bsr	Video_MdMars_VideoMode
	endif
; 	if MARS|MARSCD=0
; 		move.l	#Art_Scn0_BG,d0
; 		move.w	#cell_vram($0001),d1
; 		move.w	#Art_Scn0_BG_e-Art_Scn0_BG,d2
; 		bsr	Video_LoadArt
; 		lea	(MAP_Scr0_BG),a0
; 		move.l	#locate(0,0,1),d0
; 		move.l	#map_size(320,224),d1
; 		move.w	#$0001,d2
; 		bsr	Video_LoadMap
; 	endif
		lea	(ASCII_FONT).l,a0
		lea	(ASCII_PAL).l,a1
		bsr	Video_PrintInit


; 		lea	PAL_SCR0_TEST(pc),a0
; 		moveq	#0,d0
; 		move.w	#16,d1
; 		bsr	Video_FadePal

		lea	(objPal_Emily),a0
		moveq	#0,d0
		move.w	#16,d1
		bsr	Video_FadePal
		lea	(objPal_Doremi),a0
		moveq	#16,d0
		move.w	#16,d1
		bsr	Video_FadePal
		lea	(objPal_Sophie),a0
		moveq	#32,d0
		move.w	#16,d1
		bsr	Video_FadePal

		lea	str_Scrn0Intro(pc),a0
		move.l	#locate(1,1,0),d0
		bsr	Video_Print

		move.l	#Obj_Emily,d0		; IN THIS ORDER
		moveq	#0,d1
		bsr	Objects_Add
		move.l	#Obj_Bibi,d0
		moveq	#0,d1
		bsr	Objects_Add
		move.l	#Obj_Doremi,d0
		moveq	#0,d1
		bsr	Objects_Add
		move.l	#Obj_Doremi,d0
		moveq	#1,d1
		bsr	Objects_Add
		move.l	#Obj_Doremi,d0
		moveq	#2,d1
		bsr	Objects_Add

	; ----------------------------------------------
		move.w	#214,d0
		bsr	gemaSetBeats
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		bsr	gemaPlayTrack
; 	if MCD|MARSCD
; 		move.w	#$0002,(sysmcd_reg+mcd_dcomm_m).l
; 		move.w	#$0010,d0
; 		bsr	System_McdSubTask
; 	endif
	; ----------------------------------------------
; 		bsr	.show_me
; 		bsr	.steal_vars
		bsr	Objects_Run
		bsr	ShowMe_Who
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
; 		vdp_showme $0E0
		bsr	Objects_Run
		bsr	ShowMe_Who
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		bne.s	.snd_test
; 		vdp_showme $000
		bra.s	.loop
.snd_test:
		bsr	gemaStopAll
		bsr	System_Render
		bsr	Video_FadeOut
		move.w	#1,(RAM_ScreenMode).w
		rts		; EXIT

; ====================================================================
; ------------------------------------------------------
; DATA assets locations for 68K and SH2
; ------------------------------------------------------

file_mddata_def:
		dc.b "DATABNKD.BIN",0		; CD Filename
		align 2
pointr_marsdata_def:
		dc.l MARSDATA_SCREEN00		; 32X Cartridge point
		dc.b "MARSD_00.BIN",0		; CD Filename
		align 2

; ====================================================================
; ------------------------------------------------------
; Objects
; ------------------------------------------------------

; --------------------------------------------------
; Emily
; --------------------------------------------------

Obj_Emily:
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
		move.l	#objMap_Emily,obj_map(a6)
		move.w	#setVram_Emily|$8000,obj_vram(a6)
		bclr	#bitobj_Mars,obj_set(a6)	; Set as Genesis object
		move.l	#$03030202,obj_size(a6)		; UDLR sizes
		move.w	#(320/2)-32,obj_x(a6)
		move.w	#(224/2)-32,obj_y(a6)
		clr.w	obj_frame(a6)
		clr.w	obj_ram(a6)
		clr.w	obj_ram+2(a6)
		bsr	object_ResetAnim

; ----------------------------------------------
.main:
		lea	obj_ram(a6),a5
		lea	(Controller_1),a4

		clr.w	obj_x_spd(a6)
		clr.w	obj_y_spd(a6)
		move.w	on_hold(a4),d4
		btst	#bitJoyDown,d4
		beq.s	.go_down
		move.w	#0,(a5)		; <--
		move.w	#$140,obj_y_spd(a6)
.go_down:
		btst	#bitJoyUp,d4
		beq.s	.go_up
		move.w	#4,(a5)
		move.w	#-$140,obj_y_spd(a6)
.go_up:
		btst	#bitJoyRight,d4
		beq.s	.go_r
		move.w	#8,(a5)
		move.w	#$140,obj_x_spd(a6)
.go_r:
		btst	#bitJoyLeft,d4
		beq.s	.go_l
		move.w	#$C,(a5)
		move.w	#-$140,obj_x_spd(a6)
.go_l:
		move.w	(a5),d0
		move.w	on_hold(a4),d4
		andi.w	#JoyUp+JoyDown+JoyLeft+JoyRight,d4
		beq.s	.stay
		move.b	2(a5),d1
		andi.w	#%11,d1
		add.w	d1,d0
.stay:
		move.w	d0,obj_frame(a6)
		addi.w	#$0020,2(a5)		; Speed
		andi.w	#$03FF,2(a5)		; limit
		bsr	object_Speed

		tst.l	obj_x(a6)
		bpl.s	.x_neg
		clr.l	obj_x(a6)
.x_neg:
		cmp.w	#320,obj_x(a6)
		blt.s	.x_posi
		move.w	#320,obj_x(a6)
.x_posi:
		tst.l	obj_y(a6)
		bpl.s	.y_neg
		clr.l	obj_y(a6)
.y_neg:
		cmp.w	#224,obj_y(a6)
		blt.s	.y_posi
		move.w	#224,obj_y(a6)
.y_posi:
		clr.l	(RAM_WhoIAm).w
		bsr	object_Collision
		tst.l	d0
		beq.s	.no_one
		move.l	d0,(RAM_WhoIAm).w
.no_one:
		lea	(objDma_Emily),a0
		lea	(Art_Emily),a1
		bsr	object_DMA
		bra	object_Display

; ----------------------------------------------

.anim_data:
		dc.w .anim_d-.anim_data
		dc.w .anim_u-.anim_data
		dc.w .anim_r-.anim_data
		dc.w .anim_l-.anim_data
.anim_d:
		dc.w 8
		dc.w 0,1,2,3,-1
		align 2
.anim_u:
		dc.w 8
		dc.w 4,5,6,7,-1
		align 2
.anim_r:
		dc.w 8
		dc.w 8,9,10,11,-1
		align 2
.anim_l:
		dc.w 8
		dc.w 12,13,14,15,-1
		align 2

; --------------------------------------------------
; Doremi, Sophie o Nicole
; --------------------------------------------------

Obj_Doremi:
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
		bclr	#bitobj_Mars,obj_set(a6)	; Set as Genesis object
		move.l	#$03030202,obj_size(a6)		; UDLR sizes
		move.b	obj_subid(a6),d0
		lsl.w	#4,d0
		lea	.sub_list(pc),a0
		adda	d0,a0
		move.l	(a0)+,obj_map(a6)
		move.w	(a0)+,obj_vram(a6)
		move.w	(a0)+,obj_x(a6)
		move.w	(a0)+,obj_y(a6)
		move.w	(a0)+,obj_ram+2(a6)

		clr.w	obj_frame(a6)
		clr.w	obj_ram(a6)
		bsr	object_ResetAnim

; ----------------------------------------------
.main:
		moveq	#0,d0
		move.b	obj_ram(a6),d0
		add.w	obj_ram+2(a6),d0
		move.w	d0,obj_frame(a6)
		addi.w	#$0010,obj_ram(a6)		; Speed
		andi.w	#$01FF,obj_ram(a6)		; limit

		moveq	#0,d0
		move.b	obj_subid(a6),d0
		lsl.w	#3,d0
		lea	.sub_dma(pc),a2
		adda	d0,a2
		move.l	(a2)+,a0
		move.l	(a2)+,a1
		bsr	object_DMA
		bra	object_Display

; ----------------------------------------------

.sub_dma:
		dc.l objDma_Doremi,Art_Doremi
		dc.l objDma_Sophie,Art_Sophie
		dc.l objDma_Sophie,Art_Sophie
.sub_list:
		dc.l objMap_Doremi
		dc.w setVram_Doremi|$2000
		dc.w 60,90
		dc.w 0
		dc.l 0
		dc.l objMap_Sophie
		dc.w setVram_Sophie|$4000
		dc.w 256,60
		dc.w 0
		dc.l 0
		dc.l objMap_Sophie
		dc.w setVram_Nicole|$4000
		dc.w 278,190
		dc.w 2
		dc.l 0

; --------------------------------------------------
; Bibi
; --------------------------------------------------

Obj_Bibi:
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
		bclr	#bitobj_Mars,obj_set(a6)	; Set as Genesis object
		move.l	#$02030202,obj_size(a6)		; UDLR sizes
		move.w	#(320/2),obj_x(a6)
		move.w	#(224/2),obj_y(a6)
		move.l	#objMap_Bibi,obj_map(a6)
		move.w	#setVram_Bibi|$2000,obj_vram(a6)
		clr.w	obj_frame(a6)
		bsr	object_ResetAnim
		bsr	object_ResetVars

; ----------------------------------------------
.main:
		moveq	#0,d0
		lea	(Controller_2).w,a5
		cmp.b	#JoyID_Mouse,pad_id(a5)
		bne.s	.no_mouse
		move.w	on_hold(a5),d7
		btst	#bitClickL,d7
		beq.s	.no_click
		moveq	#1,d0
		bra.s	.no_mouse
.no_click:
		clr.w	obj_x_spd(a6)
		clr.w	obj_y_spd(a6)
		move.w	mouse_x(a5),d7
		move.w	mouse_y(a5),d6
		move.w	d7,d5
		or.w	d6,d5
		beq.s	.no_mouse

		tst.w	d6
		beq.s	.no_y_spd
		moveq	#3,d0
		bset	#bitobj_flipH,obj_set(a6)
		move.w	d6,d5
		asl.w	#6,d5
		tst.w	d6
		bpl.s	.plus_y_spd
		bclr	#bitobj_flipH,obj_set(a6)
		addq.w	#1,d0
.plus_y_spd:
		move.w	d5,obj_y_spd(a6)
.no_y_spd:

		tst.w	d7
		beq.s	.no_x_spd
		moveq	#2,d0
		bset	#bitobj_flipH,obj_set(a6)
		move.w	d7,d5
		asl.w	#6,d5
		tst.w	d7
		bpl.s	.plus_x_spd
		bclr	#bitobj_flipH,obj_set(a6)
.plus_x_spd:
		move.w	d5,obj_x_spd(a6)
.no_x_spd:

;
; 		moveq	#2,d0
; 		bset	#bitobj_flipH,obj_set(a6)
; 		move.w	d7,d5
; 		lsl.w	#3,d5
; 		tst.w	d7
; 		bpl.s	.no_x_spd
; 		neg.w	d5
; 		bclr	#bitobj_flipH,obj_set(a6)
; .no_x_spd:
; 		move.w	d5,obj_x_spd(a6)

.no_mouse:
		move.b	d0,obj_anim_id(a6)
; 		lea	obj_ram(a6),a5
; 		sub.w	#1,(a5)
; 		bpl.s	.keep_moving
; 		move.w	2(a5),d1
; 		addq.w	#4,d1			; Start at 4
; 		move.b	d1,obj_anim_id(a6)
; 		lsl.w	#2,d1
; 		lea	.set_spds(pc,d1.w),a0
; 		move.w	(a0),obj_x_spd(a6)
; 		move.w	2(a0),obj_y_spd(a6)
; 		bclr	#bitobj_flipH,obj_set(a6)
; 		tst.w	obj_x_spd(a6)
; 		bmi.s	.flip_x
; 		bset	#bitobj_flipH,obj_set(a6)
; .flip_x:
; 		addq.w	#1,2(a5)
; 		andi.w	#%11,2(a5)
; 		move.w	#$100,(a5)		; Reset timer
; .keep_moving:
		bsr	object_Speed
		lea	.anim_data(pc),a0
		bsr	object_Animate

		lea	(objDma_Bibi),a0
		lea	(Art_Bibi),a1
		bsr	object_DMA
		bra	object_Display

; ----------------------------------------------

; .set_spds:
; 		dc.w  $0080, $0000	; Right
; 		dc.w  $0000, $0080	; Down
; 		dc.w -$0080, $0000	; Left
; 		dc.w  $0000,-$0080	; Up
.anim_data:
		dc.w .stand-.anim_data
		dc.w .yatta-.anim_data
		dc.w .walk_lr-.anim_data
		dc.w .walk_d-.anim_data
		dc.w .walk_u-.anim_data
.stand:
		dc.w 7
		dc.w 0
		dc.w -1
.walk_d:
		dc.w 7
		dc.w 0,1,0,2
		dc.w -1
.walk_u:
		dc.w 7
		dc.w 3,4,3,5
		dc.w -1
.walk_lr:
		dc.w 7
		dc.w 6,7,6,8
		dc.w -1
.yatta:
		dc.w 7
		dc.w 9
		dc.w -1

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

ShowMe_Who:
		lea	list_WhoIAm(pc),a1

		move.l	(RAM_WhoIAm).w,d3
		tst.l	d3
		beq.s	.nadie
		move.l	d3,a2
		lea	str_ListWho(pc),a0
.next_one:
		move.l	(a1),d0
		move.w	4(a1),d1
		cmp.l	#-1,d0
		beq.s	.nadie
		cmp.l	obj_code(a2),d0
		bne.s	.not_this
		cmp.b	obj_subid(a2),d1
		beq.s	.found
.not_this:
		adda	#6,a1
		adda	#8,a0
		bra.s	.next_one
.nadie:
		lea	str_Nadie(pc),a0
.found:
		move.l	#locate(21,2,0),d0
		bra	Video_Print

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

PAL_SCR0_TEST:
		binclude "game/screen_0/data/md/maps/test/md_pal.bin"
		align 2
str_Scrn0Intro:
		dc.b "Probando colision con objectos",$A
		dc.b "Emiliy toca toca a:",0
		align 2
str_Nadie:	dc.b "NADIE  ",0
str_ListWho:	dc.b "Bibi   ",0
		dc.b "Doremi ",0
		dc.b "Sophie ",0
		dc.b "Nicole ",0
		dc.b "Nikona ",0
list_WhoIAm:	dc.l Obj_Bibi
		dc.w 0
		dc.l Obj_Doremi
		dc.w 0
		dc.l Obj_Doremi
		dc.w 1
		dc.l Obj_Doremi
		dc.w 2
		dc.l -1
		dc.w 0

str_ShowMe:	dc.b "\\w | \\w \\w",0
		dc.l $FF0000,$FF0004,$FF0006
		align 2

; List_ObjPos:	dc.w 1
; 		dc.w 215,164
; 		dc.w $4000|setVram_Generic+(4*6)
; 		dc.l objMap_Doremi
; 		dc.l objDma_Doremi
; 		dc.w $70,$40
; 		dc.w $4000|setVram_Generic+(4*6)
; 		dc.l objMap_Doremi
; 		dc.l objDma_Doremi
; 		dc.w $50,$80
; 		dc.w $4000|setVram_Generic+(4*6)
; 		dc.l objMap_Doremi
; 		dc.l objDma_Doremi
; 		dc.w $30,$C0
; 		dc.w $4000|setVram_Generic+(4*6)
; 		dc.l objMap_Doremi
; 		dc.l objDma_Doremi
