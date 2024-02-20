; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona sound driver v1.0
; (C)2023-2024 GenesisFan64
;
; Features:
; - Support for SEGA CD's PCM channels:
;   | All 8 channels with streaming support
;   | for larger samples.
;
; - Support for 32X's PWM:
;   | 7 pseudo-channels in either MONO
;   | or STEREO.
;
; - DMA ROM protection
;   | This keeps DAC in a decent quality while
;   | doing any DMA jobs in the 68k side.
; - DAC Playback at 16000hz
; - FM special mode with custom frequencies
; - Autodetection for the PSG's Tone3 mode
;
; ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣶⡿⠿⠿⠿⣶⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⠀⢀⣠⣶⢟⣿⠟⠁⢰⢋⣽⡆⠈⠙⣿⡿⣶⣄⡀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⣠⣴⠟⠋⢠⣾⠋⠀⣀⠘⠿⠿⠃⣀⠀⠈⣿⡄⠙⠻⣦⣄⠀⠀⠀⠀
; ⠀⢀⣴⡿⠋⠁⠀⢀⣼⠏⠺⠛⠛⠻⠂⠐⠟⠛⠛⠗⠘⣷⡀⠀⠈⠙⢿⣦⡀⠀
; ⣴⡟⢁⣀⣠⣤⡾⢿⡟⠀⠀⠀⠘⢷⠾⠷⡾⠃⠀⠀⠀⢻⡿⢷⣤⣄⣀⡈⢻⣦
; ⠙⠛⠛⠋⠉⠁⠀⢸⡇⠀⠀⢠⣄⠀⠀⠀⠀⣠⡄⠀⠀⢸⡇⠀⠈⠉⠙⠛⠛⠋
; ⠀⠀⠀⠀⠀⠀⠀⢸⡇⢾⣦⣀⣹⡧⠀⠀⢼⣏⣀⣴⡷⢸⡇⠀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⠀⠀⠸⣧⡀⠈⠛⠛⠁⠀⠀⠈⠛⠛⠁⢀⣼⠇⠀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⠀⠀⢀⣘⣿⣶⣤⣀⣀⣀⣀⣀⣀⣤⣶⣿⣃⠀⠀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⣠⡶⠟⠋⢉⣀⣽⠿⠉⠉⠉⠹⢿⣍⣈⠉⠛⠷⣦⡀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⢾⣯⣤⣴⡾⠟⠋⠁⠀⠀⠀⠀⠀⠀⠉⠛⠷⣶⣤⣬⣿⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠁⠀⠀⠀⠀⠀
; --------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Macros
; --------------------------------------------------------

; Shared for all DAC, PCM, PWM
gSmpHead macro len,loop
	dc.b ((len)&$FF),(((len)>>8)&$FF),(((len)>>16)&$FF)	; length
	dc.b ((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
	endm

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; z80_cpu	equ $A00000		; Z80 CPU area, size: $2000
; z80_bus 	equ $A11100		; only read bit 0 (bit 8 as WORD)
; z80_reset	equ $A11200		; WRITE only: $0000 reset/$0100 cancel

; Z80-area points:
zDrvFifo	equ commZfifo		; FIFO command storage
zDrvFWrt	equ commZWrite		; FIFO command index
zDrvRomBlk	equ commZRomBlk		; ROM block flag
zDrvMarsBlk	equ marsBlock		; Flag to disable 32X's PWM
zDrvMcdBlk	equ mcdBlock		; Flag to disable SegaCD's PCM
zDrvRamSrc	equ cdRamSrcB		; RAM-read source+dest pointers
zDrvRamLen	equ cdRamLen		; RAM-read length and flag

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

RAM_ZCdFlag_D	equ RAM_ZSndBuff	; transferRom flag

; ====================================================================
; --------------------------------------------------------
; Initialize Sound
;
; Uses:
; a0-a1,d0-d1
; --------------------------------------------------------

; 		align $80
Sound_Init:
		ori.w	#$0700,sr
	if PICO
		; PICO driver init...
	else
		move.w	#$0100,(z80_bus).l		; Get Z80 bus
		move.w	#$0100,(z80_reset).l		; Z80 reset
.wait:
		btst	#0,(z80_bus).l
		bne.s	.wait
		lea	(z80_cpu).l,a0			; Clean entire Z80 FIRST.
		move.w	#$1FFF,d0
		moveq	#0,d1
.cleanup:
		move.b	d1,(a0)+
		dbf	d0,.cleanup
		lea	(Z80_CODE).l,a0			; a0 - Z80 code (on $880000)
		lea	(z80_cpu).l,a1			; a1 - Z80 CPU area
		move.w	#(Z80_CODE_END-Z80_CODE)-1,d0	; d0 - Size

.copy:
		move.b	(a0)+,(a1)+
		dbf	d0,.copy
		move.w	#0,(z80_reset).l		; Reset cancel
		clr.b	(RAM_ZCdFlag_D).w		; Reset Z80 transferRom flag
		nop					; Reset Z80 buffer flag
		nop
		nop
		move.w	#$100,(z80_reset).l
		move.w	#0,(z80_bus).l			; Start Z80
	endif
		move.l	#Gema_MasterList,d0
		bra	gemaSetMasterList

; ----------------------------------------------------------------
; Sound_Update
;
; Call and LOOP this during DISPLAY to communicate
; with the Z80
;
; SegaCD/CD32X:
; This checks if the Z80 wants to read from RAM (as it can't
; see it) then this CPU manually writes the RAM bytes from
; here to the Z80's RAM
; THIS IS REQUIRED for the tracks and instruments stored
; on RAM in case you are doing ASIC-Stamps.
;
; DAC samples are safe to read from WORD-RAM (if NOT using Stamps)
; but careful when loading new data, and make sure MAIN
; has the permission to read the data.
;
; Sega Pico:
; * For later *
;
; Uses:
; d5-d7,a4-a6
; ----------------------------------------------------------------

Sound_Update:
	if PICO
		rts		; entire Sound driver for Pico goes here
	else
	; ------------------------------------------------
	; If transferRom wants to read from 68k RAM
		tst.b	(RAM_ZCdFlag_D).w	; *Z80 WRITES TO RAM*
		beq.s	.no_task
		clr.b	(RAM_ZCdFlag_D).w
		moveq	#0,d7
		bsr	sndLockZ80
		move.b	(z80_cpu+zDrvRamLen).l,d7
		beq.s	.no_size
		subq.w	#1,d7
		lea	(z80_cpu+(zDrvRamSrc+1)),a6
		lea	(z80_cpu),a5
		move.b	-(a6),d6		; d6 - Source
		swap	d6
		move.b	-(a6),d6
		lsl.w	#8,d6
		move.b	-(a6),d6
		moveq	#0,d5
		move.b	-(a6),d5		; d5 - Dest
		lsl.w	#8,d5
		move.b	-(a6),d5
		add.l	d5,a5
		move.l	d6,a4
.copy_bytes:
		move.b	(a4)+,(a5)+
		dbf	d7,.copy_bytes
		move.b	#0,(z80_cpu+zDrvRamLen).l
.no_size:
		bsr	sndUnlockZ80
.no_task:
	endif
		rts

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; ------------------------------------------------
; Lock Z80, get bus
; ------------------------------------------------

sndLockZ80:
	if PICO=0
		move.w	#$0100,(z80_bus).l
.wait:
		btst	#0,(z80_bus).l
		bne.s	.wait
	endif
		rts

; ------------------------------------------------
; Unlock Z80, return bus
; ------------------------------------------------

sndUnlockZ80:
	if PICO=0
		move.w	#0,(z80_bus).l
	endif
		rts

; ------------------------------------------------
; 68K-to-Z80 sound request enter/exit routines
;
; d6 - commFifo index
; ------------------------------------------------

sndReq_Enter:
	if PICO=0
		move.w	#$0100,(z80_bus).l		; Request Z80 Stop
	endif
; 		or.w	#$0700,sr			; Disable interrupts
		suba	#4,sp				; Extra jump return
		movem.l	d6-d7/a5-a6,-(sp)		; Save these regs to the stack
		adda	#(4*4)+4,sp			; Go back to the RTS jump
		lea	(z80_cpu+zDrvFWrt),a5		; a5 - commZWrite
		lea	(z80_cpu+zDrvFifo),a6		; a6 - fifo command list
.wait:
	if PICO=0
		btst	#0,(z80_bus).l			; Wait for Z80
		bne.s	.wait
	endif
		move.b	(a5),d6				; d6 - index fifo position
		ext.w	d6				; extend to 16 bits
		rts
; JUMP ONLY
sndReq_Exit:
	if PICO=0
		move.w	#0,(z80_bus).l
	endif
		suba	#8+(4*4),sp
		movem.l	(sp)+,d6-d7/a5-a6		; And pop those back
		adda	#8,sp
; 		andi.w	#$F8FF,sr			; Enable interrupts
		rts

; ------------------------------------------------
; Send request id and arguments
;
; Input:
; d7 - byte to write
; d6 - index pointer
; a5 - commZWrite, update index
; a6 - commZfifo command list
;
; *** CALL sndReq_Enter FIRST ***
; ------------------------------------------------

sndReq_scmd:
		move.b	#-1,(a6,d6.w)			; write command-start flag
		addq.b	#1,d6				; next fifo pos
		andi.b	#MAX_ZCMND-1,d6
		bra.s	sndReq_sbyte
sndReq_slong:
		bsr	sndReq_sbyte
		ror.l	#8,d7
sndReq_saddr:	; 24-bit address
		bsr	sndReq_sbyte
		ror.l	#8,d7
sndReq_sword:
		bsr	sndReq_sbyte
		ror.l	#8,d7
sndReq_sbyte:
		move.b	d7,(a6,d6.w)			; write byte
		addq.b	#1,d6				; next fifo pos
		andi.b	#MAX_ZCMND-1,d6
		move.b	d6,(a5)				; update commZWrite
		rts

; --------------------------------------------------------
; gemaDmaPause
;
; Call this BEFORE doing any DMA transfer
; --------------------------------------------------------

gemaDmaPause:
	if PICO
		rts
	else
		swap	d7
		swap	d6
; .retry_flag:
		bsr	sndLockZ80
		move.b	#1,(z80_cpu+zDrvRomBlk)		; Block flag for Z80
		bsr	sndUnlockZ80
		move.w	#96,d7				; ...Small delay...
		dbf	d7,*
		swap	d6
		swap	d7
		rts
	endif

; --------------------------------------------------------
; gemaDmaResume
;
; Call this AFTER finishing DMA transfer
; --------------------------------------------------------

gemaDmaResume:
	if PICO
		rts
	else
		swap	d7
		swap	d6
		bsr	sndLockZ80
		move.b	#0,(z80_cpu+zDrvRomBlk)		; Block flag for Z80
		bsr	sndUnlockZ80
		swap	d6
		swap	d7
		rts
	endif

; --------------------------------------------------------
; gemaDmaPauseRom
;
; Call this BEFORE doing any DMA transfer
;
; *** BANKS $880000/$900000 WILL BE GONE ***
; --------------------------------------------------------

gemaDmaPauseRom:
	if PICO
		rts
	else
		swap	d7
		swap	d6
		bsr	sndLockZ80
		move.b	#1,(z80_cpu+zDrvRomBlk)		; Block flag for Z80
		bsr	sndUnlockZ80
		move.w	#96,d7				; ...Small delay...
		dbf	d7,*
; 	if MARS|MARSCD
; 		move.w	#2,d6
; 		bsr	sndReqCmd
; 	endif
	if MARS
		bset	#0,(sysmars_reg+dreqctl+1).l	; Set RV=1
	endif
		swap	d6
		swap	d7
		rts
	endif

; --------------------------------------------------------
; gemaDmaResumeRom
;
; Call this AFTER finishing DMA transfer
;
; *** BANKS $880000/$900000 GET RESTORED ***
; --------------------------------------------------------

gemaDmaResumeRom:
	if PICO
		rts
	else
		swap	d7
		swap	d6
		bsr	sndLockZ80
		move.b	#0,(z80_cpu+zDrvRomBlk)		; Block flag for Z80
		bsr	sndUnlockZ80
; 	if MARS|MARSCD
; 		move.w	#3,d6
; 		bsr	sndReqCmd
; 	endif
	if MARS
		bclr	#0,(sysmars_reg+dreqctl+1).l	; Set RV=0
	endif
		swap	d6
		swap	d7
		rts
	endif

; ====================================================================
; --------------------------------------------------------
; USER CALLS
; --------------------------------------------------------

; --------------------------------------------------------
; gemaTest
;
; For TESTING only.
; --------------------------------------------------------

gemaTest:
		bsr	sndReq_Enter
		move.w	#$00,d7		; Command $00
		bsr	sndReq_scmd
		bra 	sndReq_Exit

; --------------------------------------------------------
; gemaSetMasterList
;
; Set Tracklist location
;
; Input:
; d0.l - 68k pointer
; --------------------------------------------------------

gemaSetMasterList:
		bsr	sndReq_Enter
		move.w	#$01,d7		; Command $01
		bsr	sndReq_scmd
		move.l	d0,d7
		bsr	sndReq_slong
		bra 	sndReq_Exit

; --------------------------------------------------------
; gemaPlayTrack
;
; Play a sequence with arguments
;
; Input:
; d0.b - Sequence number
; d1.b - Playback slot number
;        If -1: use auto-search
; d2.b - Starting block
; --------------------------------------------------------

gemaPlayTrack:
		bsr	sndReq_Enter
		move.w	#$02,d7		; Command $02
		bsr	sndReq_scmd
		move.b	d0,d7		; d0.b Seq number
		bsr	sndReq_sbyte
		move.b	d2,d7		; d2.b Block <--
		bsr	sndReq_sbyte
		move.b	d1,d7		; d1.b Slot
		bsr	sndReq_sbyte
		bra 	sndReq_Exit

; --------------------------------------------------------
; gemaStopTrack
;
; Play a sequence with arguments
;
; Input:
; d0.b - Sequence number
; d1.b - Playback slot number
;        If -1: stop all slots with the same number
; --------------------------------------------------------

gemaStopTrack:
		bsr	sndReq_Enter
		move.w	#$03,d7		; Command $03
		bsr	sndReq_scmd
		move.b	d0,d7		; d0.b Seq number
		bsr	sndReq_sbyte
		move.b	d1,d7		; d1.b Slot
		bsr	sndReq_sbyte
		bra 	sndReq_Exit

; --------------------------------------------------------
; gemaSetBeats
;
; Sets global subbeats
;
; d0.w - sub-beats
; --------------------------------------------------------

gemaSetBeats:
		bsr	sndReq_Enter
		move.w	#$06,d7		; Command $06
		bsr	sndReq_scmd
		move.w	d0,d7
		bsr	sndReq_sword
		bra 	sndReq_Exit
