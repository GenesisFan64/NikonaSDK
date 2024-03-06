; ===========================================================================
; ----------------------------------------------------------------
; Genesis system routines, and some SegaCD and 32X routines.
;
; * CAN BE RECYCLED FOR SEGA PICO, ONLY IGNORE Z80 ACCESS OR
; THE CONTROL ROUTINE **
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; Settings
; ----------------------------------------------------------------

MAX_SRAMSIZE	equ $400
TAG_SRAMDATA	equ "SAVE"	; 4-letter save file signature

; ====================================================================
; ----------------------------------------------------------------
; Variables
; ----------------------------------------------------------------

; Controller buffer data, MUST call System_Input on VBlank.
;
; Type/Revision byte:
;
; ID    |
; $0D   | $00 - Original 3 button
;       | $01 - 6 button version: XYZM

; Read WORD in +on_hold or +on_press
JoyUp		equ $0001
JoyDown		equ $0002
JoyLeft		equ $0004
JoyRight	equ $0008
JoyB		equ $0010
JoyC		equ $0020
JoyA		equ $0040
JoyStart	equ $0080
JoyZ		equ $0100
JoyY		equ $0200
JoyX		equ $0400
JoyMode		equ $0800
bitJoyUp	equ 0		; READ THESE AS A WORD
bitJoyDown	equ 1
bitJoyLeft	equ 2
bitJoyRight	equ 3
bitJoyB		equ 4
bitJoyC		equ 5
bitJoyA		equ 6
bitJoyStart	equ 7
bitJoyZ		equ 8
bitJoyY		equ 9
bitJoyX		equ 10
bitJoyMode	equ 11

; Mega Mouse
; Read WORD as +on_hold or +on_press
ClickR		equ $0001
ClickL		equ $0002
ClickM		equ $0004	; US MOUSE ONLY
ClickS		equ $0008	; (Untested)
bitClickL	equ 0
bitClickR	equ 1
bitClickM	equ 2
bitClickS	equ 3

; Controller_1 / Controller_2
		strct 0
pad_id		ds.b 1			; Controller ID
pad_ver		ds.b 1			; Controller type/revision
on_hold		ds.w 1			; User HOLD bits
on_press	ds.w 1			; User PRESSED bits
on_release	ds.w 1			; (RESERVED)
mouse_x		ds.w 1			; Mouse/Pen X position or speed
mouse_y		ds.w 1			; Mouse/pen Y position or speed
ext_3		ds.w 1
ext_4		ds.w 1
sizeof_input	ds.l 0
		endstrct

; ====================================================================
; ----------------------------------------------------------------
; RAM section
; ----------------------------------------------------------------

		strct RAM_MdSystem
RAM_InputData	ds.b sizeof_input*4		; Input data section
RAM_SaveData	ds.b MAX_SRAMSIZE		; Read/Write of the SAVE data
RAM_SysRandVal	ds.l 1				; Random value
RAM_SysRandSeed	ds.l 1				; Randomness seed
RAM_MdMarsVInt	ds.w 3				; VBlank jump (JMP xxxx xxxx)
RAM_MdMarsHint	ds.w 3				; HBlank jump (JMP xxxx xxxx)
RAM_ScreenMode	ds.w 1
sizeof_mdsys	ds.l 0
		endstrct
		erreport "MD SYSTEM RAM",sizeof_mdsys-RAM_MdSystem,MAX_MdSystem

; ====================================================================
; ----------------------------------------------------------------
; Alias tags
; ----------------------------------------------------------------

Controller_1	equ RAM_InputData
Controller_2	equ RAM_InputData+sizeof_input

; ====================================================================
; --------------------------------------------------------
; Init System
; 
; Uses:
; a0-a2,d0-d1
; --------------------------------------------------------

System_Init:
		or.w	#$0700,sr
	if PICO=0
		move.w	#$0100,(z80_bus).l	; Stop Z80
.wait:
		btst	#0,(z80_bus).l		; Wait for it
		bne.s	.wait
		moveq	#%01000000,d0		; Init ports, TH=1
		move.b	d0,(sys_ctrl_1).l	; Controller 1
		move.b	d0,(sys_ctrl_2).l	; Controller 2
		move.b	d0,(sys_ctrl_3).l	; Modem
		move.w	#0,(z80_bus).l		; Enable Z80
	endif
		move.w	#$4EF9,d0		; Set JMP opcode for the Hblank/VBlank jumps
 		move.w	d0,(RAM_MdMarsVInt).w
		move.w	d0,(RAM_MdMarsHInt).w
		move.l	#VInt_Default,d0	; Set default ints
		move.l	#Hint_Default,d1
		bsr	System_SetInts
		lea	(RAM_InputData),a0	; Clear input data buffer
		move.w	#(sizeof_input/2)-1,d1
		moveq	#0,d0
.clrinput:
		move.w	d0,(a0)+
		dbf	d1,.clrinput
		move.l	#$56255769,d0		; Set these random values
		move.l	#$95116102,d1
		move.l	d0,(RAM_SysRandVal).l
		move.l	d1,(RAM_SysRandSeed).l
	if MCD|MARSCD
		bsr	System_McdSubWait
	endif
		andi.w	#$F8FF,sr
		bra	System_SramInit

; --------------------------------------------------------
; System_Render
;
; Call this on the loop your current screen.
; ** VDP DISPLAY MUST BE ON TO USE THIS **
;
; This will:
; - Update the sound driver for any changes that
;   need communication with 68K
; - Build the object sprites
; - 32X/CD32X:
;   Update the DREQ data
;
; On VBLANK:
; - Update the input data
; - Transfer the Genesis palette, sprites and scroll
;   data from from RAM to VDP
;   (32X: RV bit is not required.)
; - Process the DMA BLAST list (32X: Uses RV bit)
; --------------------------------------------------------

System_Render:
		move.b	(RAM_VdpRegs+1).w,d7	; ** If the user forgets to enable
		btst	#bitDispEnbl,d7		; ** DISPLAY skip all this
		beq.s	.forgot_disp		; **
.wait_lag:
		bsr	Sound_Update		; Syncronize/Update sound on lag
		move.w	(vdp_ctrl).l,d7		; Got here during VBlank?
		btst	#bitVBlk,d7		; If yes, drop frame and wait
		bne.s	.wait_lag
		bsr	Sound_Update		; Update sound
		bsr	Objects_Show		; Build sprite data from Objects
.wait_in:
		bsr	Sound_Update		; Syncronize/Update sound during Display
		move.w	(vdp_ctrl).l,d7
		btst	#bitVBlk,d7		; VBlank started?
		beq.s	.wait_in
		bsr	System_Input		; Read input data FIRST
		bsr	Video_Render		; Render visuals
		bsr	Sound_Update		; Update sound
		addq.l	#1,(RAM_Framecount).w	; Count the frame.
	if MARS|MARSCD
		bsr	System_MarsUpdate	; 32X/CD32X: Send DREQ changes
	endif
		bsr	Sound_Update		; Update sound again
.forgot_disp:
		rts

; ====================================================================
; --------------------------------------------------------
; System_DmaEnter_(from) and System_DmaEnter_(from)
; from: ROM or RAM
;
; Call to these labels BEFORE and AFTER
; DMA-to-VDP transers, these calls are NOT
; required for FILL or COPY
;
; This is where you put your Sound driver's Z80 stop
; or pause calls here.
; --------------------------------------------------------

System_DmaEnter_RAM:
		bra	gemaDmaPause
System_DmaExit_RAM:
		bra	gemaDmaResume

; --------------------------------------------------------

System_DmaEnter_ROM:
		bra	gemaDmaPauseRom
System_DmaExit_ROM:
		bra	gemaDmaResumeRom

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; System_Input
;
; Reads data from the Controller ports
; *** CALL THIS ON VBLANK ONLY ***
;
; Uses:
; d5-d7,a5-a6
; --------------------------------------------------------

; ----------------------------------------
; PICO input is hard-coded to
; Controller_1
;
; on_hold/on_press:
; %P00BRLDU
; UDLR - Arrows
;    B - BIG button red
;    P - Pen press/click
;
; mouse_x/mouse_y:
; Pen X/Y position
; depen
; ----------------------------------------

System_Input:

	if PICO
		lea	(RAM_InputData),a6
		lea	($800003).l,a5
		moveq	#0,d7
		move.b	(a5),d7		; $800003: %P00RLDU
		eori.w	#$FF,d7
		move.w	d7,d6
; 		move.b	on_release(a6),d2
; 		eor.b	d2,d7
; 		and.b	d2,d7
; 		move.b	d7,on_release(a6)
		move.w	on_hold(a6),d5
		eori.w	#$FF,d5
		and.w	d6,d5
		move.w	d5,on_press(a6)
		move.w	d6,on_hold(a6)
		move.b	2(a5),d7
		lsl.w	#8,d7
		move.b	4(a5),d7
		sub.w	#$3C,d7
		bpl.s	.x_valid	 ; <-- Failsafe negative X
		clr.w	d7
.x_valid:
		move.w	d7,mouse_x(a6)
	; $0000-$00EF - Tablet
	; $0100-$01EF - Storyware
		moveq	#0,d7
		move.b	6(a5),d6
		lsl.w	#8,d6
		move.b	8(a5),d6
		subi.w	#$1FC,d6
		bmi.s	.bad_y
		move.w	d6,d7
.bad_y:
		move.w	d7,mouse_y(a6)
		move.b	10(a5),d6
		moveq	#0,d7
		moveq	#6-1,d5		; 6 pages
.page_it:
		lsr.w	#1,d6
		bcc.s	.no_bit
		addq.w	#1,d7
.no_bit:
		dbf	d5,.page_it
		move.b	d7,ext_3(a6)
	else
	; ----------------------------------------
	; Normal Genesis controls

		lea	(RAM_InputData).w,a6	; a6 - Output
		lea	(sys_data_1),a5		; a5 - BASE Genesis Input regs area
		bsr.s	.this_one
		adda	#2,a5
		adda	#sizeof_input,a6

; ----------------------------------------
; Read port
;
; a5 - Current port
; a6 - Output data
; ----------------------------------------

.this_one:
		bsr	.pick_id
		move.b	d7,pad_id(a6)
		cmpi.w	#$0F,d7
		beq.s	.exit
		andi.w	#$0F,d7
		add.w	d7,d7
		move.w	.list(pc,d7.w),d6
		jmp	.list(pc,d6.w)
.exit:
		clr.b	pad_ver(a6)
		rts

; ----------------------------------------
; Grab ID
; ----------------------------------------

.list:
		dc.w .exit-.list	; $00
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .id_03-.list	; $03 - Mega mouse
		dc.w .exit-.list	; $04
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $08
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $0C
		dc.w .id_0D-.list	; $0D - Genesis controller (3 or 6 button)
		dc.w .exit-.list
		dc.w .exit-.list	; $0F - No controller OR Master System controller (2 Buttons: 1(B),2(C))

; ----------------------------------------
; ID $03
;
; Mega Mouse
; ----------------------------------------

; *** NOT TESTED ON HARDWARE ***
.id_03:
		move.b	#$20,(a5)
		move.b	#$60,6(a5)
		btst	#4,(a5)
		beq.w	.invalid
		move.b	#$00,(a5)	; $0F
		nop
		nop
		move.b	#$20,(a5)	; $0F
		nop
		nop
		move.b	#$00,(a5)	; Yo | Xo | Ys | Xs
		nop
		nop
		move.b	(a5),d5		; d5 - X/Y direction bits (Ys Xs)
		move.b	#$20,(a5)	; C | M | R | L
		nop
		nop
		move.b	(a5),d7
 		andi.w	#%1111,d7
		move.w	on_hold(a6),d6
		eor.w	d7,d6
		move.w	d7,on_hold(a6)
		and.w	d7,d6
		move.w	d6,on_press(a6)
		move.b	#$00,(a5)	; X7 | X6 | X5 | X4
		nop
		nop
		move.b	(a5),d7
		move.b	#$20,(a5)	; X3 | X2 | X1 | X0
		andi.w	#%1111,d7
		lsl.w	#4,d7
		nop
		move.b	(a5),d6
		andi.w	#%1111,d6
		or.w	d6,d7
		btst    #0,d5
		beq.s	.x_neg
		neg.b	d7
		neg.w	d7
.x_neg:
		move.w	d7,mouse_x(a6)
		move.b	#$00,(a5)	; Y7 | Y6 | Y5 | Y4
		nop
		nop
		move.b	(a5),d7
		move.b	#$20,(a5)	; Y3 | Y2 | Y1 | Y0
		andi.w	#%1111,d7
		lsl.w	#4,d7
		nop
		move.b	(a5),d6
		andi.w	#%1111,d6
		or.w	d6,d7
		btst    #1,d5
		beq.s	.y_neg
		neg.b	d7
		neg.w	d7
.y_neg:
		neg.w	d7		; Reverse Y
		move.w	d7,mouse_y(a6)

.invalid:
		move.b	#$60,(a5)
		rts

; ----------------------------------------
; ID $0D
;
; Normal controller: 3 button or 6 button.
; ----------------------------------------

.id_0D:
		move.b	#$40,(a5)	; Show CB|RLDU
		nop
		nop
		move.b	(a5),d5
		andi.w	#%00111111,d5
		move.b	#$00,(a5)	; Show SA|RLDU
		nop
		nop
		move.b	(a5),d7		; The following flips are for
		lsl.w	#2,d7		; the 6pad's internal counter:
		andi.w	#%11000000,d7
		or.w	d5,d7
		move.b	#$40,(a5)	; Show CB|RLDU (2)
		not.w	d7
		move.b	on_hold+1(a6),d5
		eor.b	d7,d5
		move.b	#$00,(a5)	; Show SA|RLDU (3)
		move.b	d7,on_hold+1(a6)
		and.b	d7,d5
		move.b	d5,on_press+1(a6)
		move.b	#$40,(a5)	; 6 button responds (4)
		nop
		nop
		move.b	(a5),d7		; Grab ??|MXYZ
 		move.b	#$00,(a5)	; (5)
  		nop
  		nop
 		move.b	(a5),d6		; Type: $03 old, $0F new
 		move.b	#$40,(a5)	; (6)
 		nop
 		nop
		andi.w	#$F,d6
		lsr.w	#2,d6
		andi.w	#1,d6
		beq.s	.oldpad
		not.b	d7
 		andi.w	#%1111,d7
		move.b	on_hold(a6),d5
		eor.b	d7,d5
		move.b	d7,on_hold(a6)
		and.b	d7,d5
		move.b	d5,on_press(a6)
.oldpad:
		move.b	d6,pad_ver(a6)
		rts

; ----------------------------------------
; Grab ID
; ----------------------------------------

.pick_id:
		moveq	#0,d7
		move.b	#%01110000,(a5)		; TH=1,TR=1,TL=1
		nop
		nop
		bsr	.read
		move.b	#%00110000,(a5)		; TH=0,TR=1,TL=1
		nop
		nop
		add.w	d7,d7
.read:
		move.b	(a5),d5
		move.b	d5,d6
		andi.b	#%1100,d6
		beq.s	.step_1
		addq.w	#1,d7
.step_1:
		add.w	d7,d7
		move.b	d5,d6
		andi.w	#%0011,d6
		beq.s	.step_2
		addq.w	#1,d7
.step_2:
		rts
	endif

; --------------------------------------------------------
; System_Random
;
; Makes a random number.
;
; Input:
; d0 | Seed
;
; Output:
; d0 | LONG
;
; Uses:
; d4-d5
; --------------------------------------------------------

System_Random:
		move.l	d4,-(sp)
		move.l	(RAM_SysRandSeed).w,d4
		bne.s	.good_s
		move.l	#$23B51947,d4
.good_s:
		move.l	d4,d0
		rol.l	#5,d4
		add.l	d0,d4
		asr.w	#3,d4
		add.l	d0,d4
		move.w	d4,d0
		swap	d4
		add.w	d4,d0
		move.w	d0,d4
		swap	d4
		move.l	d4,(RAM_SysRandSeed).w
		move.l	(sp)+,d4
		rts

; --------------------------------------------------------
; System_SineWave_Cos / System_SineWave
;
; Get sinewave value
;
; Input:
; d0 | WORD - Tan
; d1 | WORD - Multiply
;
; Output:
; d2 | LONG - Result (as 0000.0000)
; --------------------------------------------------------

System_SineWave_Cos:
		movem.w	d0,-(sp)
		moveq	#0,d2
		addi.b	#$40,d0
		move.b	d0,d2
		asl.b	#1,d2
		move.w	MdSys_SineData(pc,d2.w),d2
		mulu.w	d1,d2
		or.b	d0,d0
		bpl.s	.dont_neg
		neg.l	d2
.dont_neg:
		movem.w	(sp)+,d0
		rts

System_SineWave:
		movem.w	d0,-(sp)
		andi.w	#$7F,d0
		asl.w	#1,d0
		move.w	MdSys_SineData(pc,d0.w),d2
		mulu.w	d1,d2
		movem.w	(sp)+,d0
		subq.l	#8,d2
		or.b	d0,d0
		bpl.s	.dont_neg
		neg.l	d2
.dont_neg:
		rts

MdSys_SineData:	dc.w 0,	6, $D, $13, $19, $1F, $26, $2C,	$32, $38, $3E
		dc.w $44, $4A, $50, $56, $5C, $62, $68,	$6D, $73, $79
		dc.w $7E, $84, $89, $8E, $93, $98, $9D,	$A2, $A7, $AC
		dc.w $B1, $B5, $B9, $BE, $C2, $C6, $CA,	$CE, $D1, $D5
		dc.w $D8, $DC, $DF, $E2, $E5, $E7, $EA,	$ED, $EF, $F1
		dc.w $F3, $F5, $F7, $F8, $FA, $FB, $FC,	$FD, $FE, $FF
		dc.w $FF, $100,	$100, $100, $100, $100,	$FF, $FF, $FE
		dc.w $FD, $FC, $FB, $FA, $F8, $F7, $F5,	$F3, $F1, $EF
		dc.w $ED, $EA, $E7, $E5, $E2, $DF, $DC,	$D8, $D5, $D1
		dc.w $CE, $CA, $C6, $C2, $BE, $B9, $B5,	$B1, $AC, $A7
		dc.w $A2, $9D, $98, $93, $8E, $89, $84,	$7E, $79, $73
		dc.w $6D, $68, $62, $5C, $56, $50, $4A,	$44, $3E, $38
		dc.w $32, $2C, $26, $1F, $19, $13, $D, 6

; --------------------------------------------------------
; System_SetInts
;
; Set new interrputs
;
; d0.l - VBlank (if 0: Skip write)
; d1.l - HBlank (if 0: Skip write)
;
; Uses:
; d4
; --------------------------------------------------------

System_SetInts:
		move.l	d0,d4
		beq.s	.novint
	if MCD|MARSCD
		move.l	d4,($FFFFFD06+2).w
	else
 		move.l	d4,(RAM_MdMarsVInt+2).w
	endif
.novint:
		move.l	d1,d4
		beq.s	.nohint
	if MCD|MARSCD
		move.l	d4,($FFFFFD0C+2).w
	else
 		move.l	d4,(RAM_MdMarsHInt+2).w
	endif
.nohint:
		rts

; --------------------------------------------------------
; System_SramInit
;
; Init save data
;
; Uses:
; a4,d4-d5
; --------------------------------------------------------

System_SramInit:
	if PICO
		nop			; Pico has no SRAM
	elseif MCD|MARSCD
		nop			; TODO
	else
		bsr	System_SramLoad
		cmpi.l	#TAG_SRAMDATA,(RAM_SaveData).w
		beq.s	.dont_clear
		lea	(RAM_SaveData).w,a6
		moveq	#0,d6
		move.w	#MAX_SRAMSIZE-1,d7
.clr_sram:
		move.b	d6,(a6)+
		dbf	d7,.clr_sram
		move.l	#TAG_SRAMDATA,(RAM_SaveData).w
		bsr	System_SramSave
.dont_clear:
	endif
		rts

; --------------------------------------------------------
; System_SramSave
; --------------------------------------------------------

System_SramSave:
	if PICO
		nop
	elseif MCD|MARSCD
		nop
	else

	; Cartridge
		move.w	sr,d7
		swap	d7
		ori.w	#$0700,sr
	if MARS
		bset	#0,(sysmars_reg+dreqctl+1).l
	endif
		move.b	#1,(md_bank_sram).l
		lea	(RAM_SaveData).w,a6
		lea	($200003).l,a5
		move.w	#((MAX_SRAMSIZE-2)/2)-1,d7
.save:
		move.b	(a6)+,d6
		move.b	d6,(a5)
		adda	#2,a5
		dbf	d7,.save
.dont_reset:
		move.b	#0,(md_bank_sram).l
	if MARS
		bclr	#0,(sysmars_reg+dreqctl+1).l
	endif
		swap	d7
		move.w	d7,sr
	endif
		rts

; --------------------------------------------------------
; System_SramLoad
; --------------------------------------------------------

System_SramLoad:
	if PICO
		nop
	elseif MCD|MARSCD
		nop
	else

	; Cartridge
		move.w	sr,d7
		swap	d7
		ori.w	#$0700,sr
	if MARS
		bset	#0,(sysmars_reg+dreqctl+1).l
	endif
		move.b	#1,(md_bank_sram).l
		lea	(RAM_SaveData).w,a6
		lea	($200003).l,a5
		move.w	#((MAX_SRAMSIZE-2)/2)-1,d7
.load:
		move.b	(a5),d6
		move.b	d6,(a5)+
		adda	#2,a5
		dbf	d7,.load
.dont_reset:
		move.b	#0,(md_bank_sram).l
	if MARS
		bclr	#0,(sysmars_reg+dreqctl+1).l
	endif
		swap	d7
		move.w	d7,sr
	endif
		rts

; ====================================================================
; ----------------------------------------------------------------
; Screen mode subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Initialize current screen mode
;
; MUST call this at the very start of your screen code.
; --------------------------------------------------------

Mode_Init:
		ori.w	#$0700,sr			; Disable interrupts.
		move.b	#$04,(RAM_VdpRegs).l
		move.b	#$04,(RAM_VdpRegs+1).l
		bsr	Video_Update
		bsr	Video_Clear
		bsr	Objects_Clear
		lea	(MAX_ScrnBuff),a4
		move.w	#(MAX_ScrnBuff/2)-1,d5
		moveq	#0,d4
.clr:
		move.w	d4,(a4)+
		dbf	d5,.clr
		rts

; --------------------------------------------------------
; Syncronized Fade-in/Fade-out for both VDP and SuperVDP
; --------------------------------------------------------

Mode_FadeIn:
		bsr	Objects_Run
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#2,(RAM_FadeMarsIncr).w
		move.w	#1,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
.loopw:
		bsr	System_Render
		bsr	Video_RunFade
		bne.s	.loopw
		rts

Mode_FadeOut:
		bsr	Objects_Run
		move.w	#2,(RAM_FadeMdReq).w
		move.w	#2,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#2,(RAM_FadeMarsIncr).w
		move.w	#1,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
.loopw:
		bsr	System_Render
		bsr	Video_RunFade
		bne.s	.loopw
		rts

; ====================================================================
; ----------------------------------------------------------------
; Default interrupts
; ----------------------------------------------------------------

; --------------------------------------------------------
; VBlank
; --------------------------------------------------------

VInt_Default:
		movem.l	d0-a6,-(sp)
		bsr	System_Input
		addi.l	#1,(RAM_FrameCount).w
		movem.l	(sp)+,d0-a6
		rte

; --------------------------------------------------------
; HBlank
; --------------------------------------------------------

HInt_Default:
		rte

; ====================================================================
; ----------------------------------------------------------------
; SEGA CD / CD32X ONLY
; ----------------------------------------------------------------

	if MCD|MARSCD

; --------------------------------------------------------
; System_McdSubWait
;
; Waits until Sub-CPU finishes.
;
; Uses:
; a6,d7
; --------------------------------------------------------

System_McdSubWait:
		lea	(sysmcd_reg+mcd_comm_m),a6
.wait_sub_o:	move.b	1(a6),d7
		bmi.s	.wait_sub_o
		rts

; --------------------------------------------------------
; System_McdSubTask
;
; Request task to Sub-CPU
; ** Exits without waiting SUB to finish, call
; System_McdSubWait after this IF required **
;
; Input:
; d0.b - Task number
;
; Uses:
; d7/a6
; --------------------------------------------------------

System_McdSubTask:
		bsr	System_McdSubWait
; 		lea	(sysmcd_reg+mcd_comm_m),a6
.wait_else:	move.b	(a6),d7
		andi.w	#$F0,d7
		cmpi.w	#$F0,d7			; Z80 got first?
		beq.s	.wait_else
		move.b	d0,(a6)			; Set this command
.wait_sub_i:	move.b	1(a6),d7		; Wait until SUB gets busy
		bpl.s	.wait_sub_i
		move.b	#$00,(a6)		; Clear value, SUB already got the ID
		rts

; --------------------------------------------------------
; System_McdTrnsfr_WRAM
;
; Read file from disc and sends it to WORD-RAM,
; waits on finish.
;
; Input:
; a0 - Filename string: "FILENAME.BIN",0
; a1 - Output location
;
; Uses:
; d7/a5-a6
;
; This calls Sub-Task $02
; NEEDS WORD-RAM permission in 2M
; --------------------------------------------------------

System_McdTrnsfr_WRAM:
		lea	(sysmcd_reg+mcd_dcomm_m),a5
		move.w	(a0)+,(a5)+				; 0 copy filename
		move.w	(a0)+,(a5)+				; 2
		move.w	(a0)+,(a5)+				; 4
		move.w	(a0)+,(a5)+				; 6
		move.w	(a0)+,(a5)+				; 8
		move.w	(a0)+,(a5)+				; 8
		move.w	#0,(a5)+				; A <-- zero end
; 		move.w	d0,d1
		move.b	(sysmcd_reg+mcd_memory).l,d0		; Set WORDRAM permission to SUB
		bset	#1,d0
		move.b	d0,(sysmcd_reg+mcd_memory).l
		move.w	#$02,d0					; COMMAND $02
		bsr	System_McdSubTask
		bra	System_McdSubWait

; --------------------------------------------------------
; System_McdTrnsfr_RAM
;
; Read file from disc and transfer it's contents to a1,
; uses communication ports.
;
; Input:
; a0 - Filename string: "FILENAME.BIN",0
; a1 - Output location
; d0 - Size ($10* sizes only)
;
; Uses:
; d7,a0-a1,a5-a6
;
; This calls Sub-Task $01
; --------------------------------------------------------

System_McdTrnsfr_RAM:
		lea	(sysmcd_reg+mcd_dcomm_m),a5
		move.w	(a0)+,(a5)+			; 0 copy filename
		move.w	(a0)+,(a5)+			; 2
		move.w	(a0)+,(a5)+			; 4
		move.w	(a0)+,(a5)+			; 6
		move.w	(a0)+,(a5)+			; 8
		move.w	(a0)+,(a5)+			; 8
		move.w	#0,(a5)+			; A <-- zero end
		move.w	d0,d1
		moveq	#$01,d0				; COMMAND: READ CD AND PASS DATA
		bsr	System_McdSubTask
		move.w	d1,d0
	; a0 - Output location
	; d0 - Number of $10-byte packets
		lsr.w	#4,d0				; size >> 4
		subq.w	#1,d0				; -1
		lea	(sysmcd_reg+mcd_dcomm_s),a6
		move.b	(sysmcd_reg+mcd_comm_m).l,d7	; LOCK HERE
		bset	#7,d7
		move.b	d7,(sysmcd_reg+mcd_comm_m).l
.copy_ram:	move.b	(sysmcd_reg+mcd_comm_s).l,d7	; Wait if sub PASSed the packet
		btst	#6,d7
		beq.s	.copy_ram
		move.l	a6,a5
		move.w	(a5)+,(a1)+
		move.w	(a5)+,(a1)+
		move.w	(a5)+,(a1)+
		move.w	(a5)+,(a1)+
		move.w	(a5)+,(a1)+
		move.w	(a5)+,(a1)+
		move.w	(a5)+,(a1)+
		move.w	(a5)+,(a1)+
		move.b	(sysmcd_reg+mcd_comm_m).l,d7	; Tell SUB we got the pack
		bset	#6,d7
		move.b	d7,(sysmcd_reg+mcd_comm_m).l
.wait_sub:	move.b	(sysmcd_reg+mcd_comm_s).l,d7	; Wait clear
		btst	#6,d7
		bne.s	.wait_sub
		move.b	(sysmcd_reg+mcd_comm_m).l,d7	; and clear our bit too.
		bclr	#6,d7
		move.b	d7,(sysmcd_reg+mcd_comm_m).l
		dbf	d0,.copy_ram
		move.b	(sysmcd_reg+mcd_comm_m).l,d7	; UNLOCK
		bclr	#7,d7
		move.b	d7,(sysmcd_reg+mcd_comm_m).l
		rts

; --------------------------------------------------------
; System_McdSendBuff
;
; Send data memory-to-memory from
; MAIN-CPU to SUB-CPU
;
; Input:
; a0 - Input data
; a1 - Output location in SUB-CPU area
; d0 - Size ($10* sizes only)
;
; Uses:
; d7,a0-a1/a5-a6
;
; This calls Sub-Task $08
; --------------------------------------------------------

System_McdSendBuff:
		move.l	a1,d7				; Write a1 to dcomm_m $00-$03
		move.w	d7,(sysmcd_reg+mcd_dcomm_m+2).l
		swap	d7
		move.w	d7,(sysmcd_reg+mcd_dcomm_m).l
		move.w	d0,d6
		moveq	#$08,d0				; COMMAND $08
		bsr	System_McdSubTask
		lsr.w	#4,d6				; size >> 4
		subq.w	#1,d6				; -1
		lea	(sysmcd_reg+mcd_dcomm_m),a6
.wait_pre:	move.b	(sysmcd_reg+mcd_comm_s).l,d0	; SUB got the a0?
		btst	#6,d0
		beq.s	.wait_pre
		bset	#7,(sysmcd_reg+mcd_comm_m).l	; MAIN lock
.copy_ram:	move.b	(sysmcd_reg+mcd_comm_s).l,d0	; Sub is busy?
		btst	#6,d0
		bne.s	.copy_ram
		move.l	a6,a5
		move.w	(a0)+,(a5)+
		move.w	(a0)+,(a5)+
		move.w	(a0)+,(a5)+
		move.w	(a0)+,(a5)+
		move.w	(a0)+,(a5)+
		move.w	(a0)+,(a5)+
		move.w	(a0)+,(a5)+
		move.w	(a0)+,(a5)+
		move.b	(sysmcd_reg+mcd_comm_m).l,d0
		bset	#6,d0
		move.b	d0,(sysmcd_reg+mcd_comm_m).l	; Set PASS bit
.wait_sub:	move.b	(sysmcd_reg+mcd_comm_s).l,d0	; Sub got the data?
		btst	#6,d0
		beq.s	.wait_sub
		move.b	(sysmcd_reg+mcd_comm_m).l,d0
		bclr	#6,d0
		move.b	d0,(sysmcd_reg+mcd_comm_m).l	; Clear PASS bit
		dbf	d6,.copy_ram
		bclr	#7,(sysmcd_reg+mcd_comm_m).l	; UNLOCK
		rts

; ----------------------------------------------------------------

	endif	; finish MCD section

; ====================================================================
; ----------------------------------------------------------------
; 32X and CD32X ONLY
; ----------------------------------------------------------------

	if MARS|MARSCD

; --------------------------------------------------------
; System_MarsDataPack
;
; BOTH 32X AND CD32X
;
; Sends graphics data to the SDRAM area
; call this BEFORE doing any visuals.
;
; Input:
; a0.l | Cartridge pointer and Filename:
;        dc.l cart_pointer ; Cartridge only
;        dc.b "FILENAME.BIN" ; CD32X only
;
;        The SDRAM data to be send MUST have
;        the size at the begining:
;        dc.l end_point-start_label
;        dc.b (data)
;
; Uses:
; a4-a5,d3-d7
;
; Notes:
; On CD32X this uses WORD-RAM for the Source.
; --------------------------------------------------------

System_MarsDataPack:
	if MARSCD
		adda	#4,a0			; Skip cartridge label
		bsr	System_McdTrnsfr_WRAM
		lea	(sysmcd_wram).l,a4
	else
		move.l	(a0),a4
	endif
		move.l	(a4)+,d0		; Read size
; 		andi.w	#$F800,d0
; 		addi.w	#$800,d0
		move.l	a4,a0
		lea	(SH2_USER_DATA).l,a1
		move.l	#$00FFF8,d3		; MAX transfer size
		moveq	#-8,d4			; Filter bits
		and.l	d4,d0
		move.l	d0,d4
		cmp.l	d3,d4
		bgt.s	.large_pack
		bra	System_MarsSendDreq	; Small package
.large_pack:
		move.w	d3,d0
		bsr	System_MarsSendDreq
		sub.l	d3,d4
		cmp.l	d3,d4
		bge.s	.large_pack
		tst.l	d4
		beq.s	.exit_now
		move.w	d4,d0
		bra	System_MarsSendDreq
.exit_now:
		bra	System_Render

; --------------------------------------------------------
; System_MarsSendDreq
;
; Transfers data to the 32X using DREQ
;
; Input:
; a0.l | Source data to transfer
; a1.l | Destination in SDRAM
; d0.w | Size (MUST end with 0 or 8)
;
; Uses:
; a4-a5,d5-d7
;
; Notes:
; Call this during DISPLAY ONLY, NOT during VBlank.
;
; * SOME 32X EMULATORS WILL GET STUCK WAITING
; FOR DMA EXIT *
; --------------------------------------------------------

System_MarsSendDreq:
		moveq	#1,d6
		bra.s	sys_MSendDreq

; --------------------------------------------------------
; System_MarsUpdate
;
; Send a small section of RAM to SH2 for updating
; the visuals.
;
; Uses:
; d0-d1,a4-a5,d5-d7
;
; Notes:
; Call this during DISPLAY ONLY, NOT during VBlank.
; --------------------------------------------------------

System_MarsUpdate:
		lea	(RAM_MdDreq),a0
		move.w	#sizeof_dreq,d0
		moveq	#0,d6

; --------------------------------------------------------

sys_MSendDreq:
		move.w	sr,d7
		ori.w	#$0700,sr		; Disable interrupts
		lea	(sysmars_reg).l,a5
		lea	dreqfifo(a5),a4
		tst.l	d6			; CMD zero?
		beq.s	.no_src
		move.l	a1,d5
		move.l	d5,dreqdest(a5)
		moveq	#0,d5			; Increment a1 for later.
		move.w	d0,d5
		add.l	d5,a1
.no_src:
		move.b	d6,comm12(a5)		; d6 - Set CMD mode
		move.w	#%000,dreqctl(a5)	; Reset 68S
		move.w	d0,d6			; d6 - Size in bytes
		lsr.w	#1,d6			; (length/2)
		move.w	d6,dreqlen(a5)		; Set transfer length (size/2)
		move.w	d6,d5			; d5 - (length/2)/4
		lsr.w	#2,d5
		subi.w	#1,d5
		bset	#0,standby(a5)		; Call CMD interrupt to MASTER
.wait_bit:	btst	#6,comm12(a5)		; Wait START signal
		beq.s	.wait_bit
		bclr	#6,comm12(a5)		; Clear.
		move.w	#%100,dreqctl(a5)	; Set 68S
.l0:		move.w  (a0)+,(a4)		; *** CRITICAL PART ***
		move.w  (a0)+,(a4)
		move.w  (a0)+,(a4)
		move.w  (a0)+,(a4)
		dbf	d5,.l0
	if EMU=0				; *** EMULATOR patch
.wait_bit_e:	btst	#6,comm12(a5)		; Wait DMA END signal
		beq.s	.wait_bit_e
		bclr	#6,comm12(a5)		; Clear.
	endif
		move.w	#%000,dreqctl(a5)	; Reset 68S
		move.w	d7,sr			; Reenable interrupts
		rts
	endif

; ====================================================================
; ----------------------------------------------------------------
; Shared subs for the add-ons
; ----------------------------------------------------------------

; --------------------------------------------------------
; System_GrabRamCode
;
; Shared routine for MCD, 32X and CD32X.
;
; Send new code to the USER side of RAM and
; jumps into it.
;
; ** FOR SEGA CD/CD+32X
; Input:
; a0 - Filename string 8-bytes
;
; ** FOR SEGA 32X
; Input:
; a0 - Location of the RAM-code to copy from
;      in the $880000/$900000 areas
; --------------------------------------------------------

System_GrabRamCode:
	if MCD|MARSCD
		; a0 - filename string,0
		lea	(RAM_UserCode),a1
		move.w	#(MAX_UserCode),d0
		bsr	System_McdTrnsfr_RAM
		jmp	(RAM_UserCode).l
	elseif MARS
		lea	(RAM_UserCode),a1
		move.w	#(MAX_UserCode)-1,d7
.copyme2:
		move.b	(a0)+,(a1)+
		dbf	d7,.copyme2
		jmp	(RAM_UserCode).l
	else
		rts
	endif

; ====================================================================
