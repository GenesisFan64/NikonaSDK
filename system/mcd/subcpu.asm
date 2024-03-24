; ====================================================================
; ----------------------------------------------------------------
; SegaCD SUB-CPU
;
; TOP CODE loaded on BOOT
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; Variables
; ----------------------------------------------------------------

scpu_wram	equ $00080000
scpu_bram	equ $FFFE8000
scpu_pcm	equ $FFFF0000
; scpu_pcmwave	equ $FFFF2001	; <-- ODD WRITES ONLY
scpu_reg	equ $FFFF8000

PCM		equ $00
ENV		equ $01		; Envelope "Volume"
PAN		equ $03		; Panning (%bbbbaaaa, aaaa = left, bbbb = right)
FDL		equ $05		; Sample rate $00xx
FDH		equ $07		; Sample rate $xx00
LSL		equ $09		; Loop address $xx00
LSH		equ $0B		; Loop address $00xx
ST		equ $0D		; Start address (only $x0, $x000)
CTREG		equ $0F		; Control register ($80 - Bank select, $C0 - Channel select)
ONREG		equ $11		; Channel On/Off (BITS: 1 - off, 0 - on)

; ====================================================================
; ----------------------------------------------------------------
; Structs
; ----------------------------------------------------------------

; cdpcm_flags:
; %EFSU ---l
; E-Enabled
; F-First fill / Restart
; S-Force stop (keyoff)
; U-Update channel freq/vol/pan only
; l-loop channel

; SIZE MUST BE $20
		strct 0
cdpcm_flags	ds.b 1		; %
cdpcm_strmf	ds.b 1
cdpcm_strmhalf	ds.b 1		; Halfway MSB $00/$04/$08/$0C
cdpcm_freeb	ds.b 1
cdpcm_clen	ds.l 1
cdpcm_cread	ds.l 1
cdpcm_pan	ds.b 1
cdpcm_env	ds.b 1
cdpcm_pitch	ds.w 1
cdpcm_start	ds.l 1
cdpcm_len	ds.l 1
cdpcm_loop	ds.l 1
cdpcm_nstart	ds.l 1
cdpcm_nlen	ds.l 1
cdpcm_nloop	ds.l 1
sizeof_cdpcm	ds.l 0
		endstrct

; ====================================================================
; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

		include "system/mcd/cdbios.asm"

; ====================================================================
; ----------------------------------------------------------------
; MAIN CODE
; ----------------------------------------------------------------

		phase $6000
		dc.b "MAIN-NIKONA",0
		dc.w 0,0
		dc.l 0
		dc.l 0
		dc.l $20
		dc.l 0
.table:
		dc.w SP_Init-.table
		dc.w SP_Main-.table
		dc.w SP_IRQ-.table
		dc.w SP_User-.table
		dc.w 0

; ====================================================================
; ----------------------------------------------------------------
; Init
; ----------------------------------------------------------------

SP_Init:
; 		bclr	#3,(scpu_reg+$33).w
; 		move.b	#$2F,(scpu_reg+$31).w
; 		move.l	#SP_Timer,(_LEVEL3+2).l
		bsr	subCDDA_ResetVolume
		move.b	#0,(scpu_reg+mcd_memory).l
		bsr	spInitFS
		lea	file_subdata(pc),a0
		bsr	spSearchFile
		lea	(SUBCPU_DATA),a0		; Get PCM samples
		bsr	spReadSectorsN
		bsr	CDPCM_Init
		move.b	#0,(scpu_reg+mcd_comm_s).w	; Reset SUB-status

; 		bset	#3,(scpu_reg+$33).w
		rts

; --------------------------------------------------------

file_subdata:
		dc.b "SUB_DATA.BIN",0
		align 2

; =====================================================================
; ----------------------------------------------------------------
; Level 3 IRQ
; ----------------------------------------------------------------

SP_Timer:
; 		movem.l	d0-a6,-(sp)
; 		bsr	CDPCM_Stream_IRQ
; 		movem.l	(sp)+,d0-a6
		rte	; rte

; =====================================================================
; ----------------------------------------------------------------
; User interrupt
; ----------------------------------------------------------------

SP_User:
		rts

; =====================================================================
; ----------------------------------------------------------------
; Level 2 IRQ
;
; WARNING: The SEGA intro before starting
; the game calls this every frame.
; ----------------------------------------------------------------

SP_IRQ:
		move.b	(scpu_reg+mcd_comm_m).w,d0
		andi.w	#$F0,d0
		cmpi.w	#$F0,d0				; Z80 wants to enter ($F0)?
		bne	.not_now
; 		bclr	#3,(scpu_reg+$33).w		; Disable Timer interrupt
		move.b	#-1,(scpu_reg+mcd_comm_s).w	; Respond to Z80
.wait_start:
		move.b	(scpu_reg+mcd_comm_m).w,d0	; MAIN is ready?
		btst	#1,d0
		beq.s	.wait_start
		bsr	CDPCM_Stream_IRQ
		lea	(RAM_CdSub_PcmTable),a1
		lea	(scpu_reg+mcd_dcomm_m+8).w,a2
		move.b	#$00,(scpu_reg+mcd_comm_s).w

; ----------------------------------------------------------------
; a1 - table
; a2 - MAIN data

.next_packet:
		move.b	(scpu_reg+mcd_comm_m).l,d0	; Wait PASS
		btst	#1,d0				; LOCK enabled?
		beq.s	.exit_now
		btst	#0,d0				; MAIN passed the packet?
		beq.s	.next_packet
		move.l	a2,a0
		move.w	(a0)+,(a1)+			; WORD passes
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		movem.l	d0/a1-a2,-(sp)
		bsr	CDPCM_Stream_IRQ
		movem.l	(sp)+,d0/a1-a2
		move.b	#$01,(scpu_reg+mcd_comm_s).w	; Sub-CPU got the data
.wait_main:	move.b	(scpu_reg+mcd_comm_m).w,d0	; Wait Z80 bit
		btst	#0,d0
		bne.s	.wait_main
		move.b	#$00,(scpu_reg+mcd_comm_s).w	; Sub-CPU is free
		bra	.next_packet
.exit_now:	bsr	CDPCM_Stream_IRQ
		bsr	CDPCM_ReadTable
.not_now:
; 		bset	#3,(scpu_reg+$33).w		; Enable Timer interrupt
		rts

; ====================================================================
; ----------------------------------------------------------------
; Main
;
; mcd_comm_m COMMAND READ ONLY:
; %lp0iiiii
;
; mcd_comm_s STATUS READ/WRITE:
; %bp000000
;
; a6 - comm data MAIN (READ ONLY)
; a5 - comm data SUB (READ/WRITE)
; ----------------------------------------------------------------

SP_Main:
	rept 5
		bsr	CDPCM_Stream
	endm
		move.b	(scpu_reg+mcd_comm_m).w,d0
		move.b	d0,d1
		andi.w	#$F0,d1
		cmpi.b	#$F0,d1					; Z80 got first?
		beq.s	SP_Main
		move.l	d0,-(sp)
		bsr	CDPCM_Stream
		move.l	(sp)+,d0
		andi.w	#%00111111,d0				; <-- current limit
		beq.s	SP_Main
; 		bclr	#3,(scpu_reg+$33).w
		move.l	d0,-(sp)
		bsr	CDPCM_Stream
		move.l	(sp)+,d0
		move.b	(scpu_reg+mcd_comm_s).w,d7
		bset	#7,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w		; Tell MAIN we are working.
		add.w	d0,d0					; index*2
		move.w	SP_cmdlist(pc,d0.w),d1
		jsr	SP_cmdlist(pc,d1.w)
		move.b	(scpu_reg+mcd_comm_s).w,d7
		bclr	#7,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w		; Tell MAIN we finished.
; 		bset	#3,(scpu_reg+$33).w
		bra	SP_Main

	; ** DO NOT RETURN WITH RTS **
	; On return it goes on a loop expecting a flag set
	; by VBlank, the IRQ is now used by the Z80
	; to Transfer the PCM table (Z80->here)

; =====================================================================
; ----------------------------------------------------------------
; Commands list
; ----------------------------------------------------------------

; Struct
; $01-$0F: Common memory handling
; $10-$1F: CDDA Playback control
; $20-$2F: ???
; $30-$3F: ???

SP_cmdlist:
		dc.w SP_cmnd00-SP_cmdlist	; $00 | **INVALID**
		dc.w SP_cmnd01-SP_cmdlist	; $01 | Read file from disc, copy data through mcd_dcomm_s
		dc.w SP_cmnd02-SP_cmdlist	; $02 | Read file from disc, sends output to WORD-RAM
		dc.w SP_cmnd00-SP_cmdlist	; $03
		dc.w SP_cmnd00-SP_cmdlist	; $04
		dc.w SP_cmnd00-SP_cmdlist	; $05
		dc.w SP_cmnd00-SP_cmdlist	; $06
		dc.w SP_cmnd00-SP_cmdlist	; $07 | Set 2M WORD-RAM permission to MAIN
		dc.w SP_cmnd08-SP_cmdlist	; $08 | Get data from MAIN through mcd_dcomm_m
		dc.w SP_cmnd00-SP_cmdlist	; $09
		dc.w SP_cmnd00-SP_cmdlist	; $0A
		dc.w SP_cmnd00-SP_cmdlist	; $0B
		dc.w SP_cmnd00-SP_cmdlist	; $0C
		dc.w SP_cmnd00-SP_cmdlist	; $0D
		dc.w SP_cmnd00-SP_cmdlist	; $0E
		dc.w SP_cmnd00-SP_cmdlist	; $0F

		dc.w SP_cmnd10-SP_cmdlist	; $10 | Play CDDA once
		dc.w SP_cmnd11-SP_cmdlist	; $11 | Play CDDA and loop
		dc.w SP_cmnd00-SP_cmdlist	; $12 |
		dc.w SP_cmnd00-SP_cmdlist	; $13 |
		dc.w SP_cmnd14-SP_cmdlist	; $14 | Stop CDDA
		dc.w SP_cmnd00-SP_cmdlist	; $15 |
		dc.w SP_cmnd16-SP_cmdlist	; $16 | CDDA fade-out
		dc.w SP_cmnd17-SP_cmdlist	; $17 | CDDA Reset volumes
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist

		dc.w SP_cmnd20-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist

; =====================================================================
; ----------------------------------------------------------------
; Commands $01-$0F
;
; General purpose data transfering
; ----------------------------------------------------------------

; --------------------------------------------------------
; NULL COMMAND
; --------------------------------------------------------

SP_cmnd00:
		rts

; --------------------------------------------------------
; Command $01
;
; Read data from disc and transfer through
; dcomm_s as packets of $10 bytes
;
; Input:
; mcd_comm_m  | %lp------
;               l - LOCK bit set by MAIN-CPU
;               p - Data-PASS bit
;
; mcd_dcomm_m | "FILENAME.BIN",0
;               Filename string 8.3 zero terminated
;
; Returns:
; mcd_comm_s  | %-p------
;               p - SUB-CPU reports that data passed
;
; Uses:
; mcd_dcomm_s $00 to $10
; --------------------------------------------------------

SP_cmnd01:
		move.w	#MSCSTOP,d0			; Stop CDDA music
		jsr	(_CDBIOS).w
		lea	(scpu_reg+mcd_dcomm_m).w,a0	; a0 - Filename
		bsr	spSearchFile
		lea	(ISO_Output),a0
		bsr	spReadSectorsN
		lea	(ISO_Output),a0
		lea	(scpu_reg+mcd_dcomm_s).w,a2
.next_packet:
		move.l	a2,a1
		move.w	(a0)+,(a1)+			; WORD writes
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.b	(scpu_reg+mcd_comm_s).w,d7	; Sub PASS bit
		bset	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
.wait_main:	move.b	(scpu_reg+mcd_comm_m).w,d7	; MAIN got data?
		btst	#7,d7				; Unlocked?
		beq.s	.exit_now
		btst	#6,d7				; MAIN got the data?
		beq.s	.wait_main
		move.b	(scpu_reg+mcd_comm_s).w,d7	; Clear Sub PASS
		bclr	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
.wait_main_o:	move.b	(scpu_reg+mcd_comm_m).w,d7	; Wait MAIN response.
		btst	#6,d7
		bne.s	.wait_main_o
		bra.s	.next_packet
.exit_now:	move.b	(scpu_reg+mcd_comm_s).w,d7	; Clear Sub PASS
		bclr	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
.wait_ret:	bset	#0,(scpu_reg+mcd_memory).l	; Return 2M WORDRAM to MAIN, RET=1
		beq.s	.wait_ret
		rts

; --------------------------------------------------------
; Command $02
;
; Read data from disc directly to WORD-RAM
;
; Input:
; mcd_dcomm_m | "FILENAME.BIN",0
;               Filename string 8.3 zero terminated
; --------------------------------------------------------

SP_cmnd02:
		move.b	(scpu_reg+mcd_memory).l,d0
		btst	#1,d0
		beq.s	SP_cmnd02
		move.w	#MSCSTOP,d0			; Stop CDDA music
		jsr	(_CDBIOS).w
		lea	(scpu_reg+mcd_dcomm_m).w,a0	; a0 - filename
		bsr	spSearchFile
		lea	(scpu_wram),a0
		bsr	spReadSectorsN
.wait_ret:	bset	#0,(scpu_reg+mcd_memory).l	; Return WORDRAM to MAIN, RET=1
		beq.s	.wait_ret
		rts

; --------------------------------------------------------
; Command $08
;
; Transfer memory from MAIN-CPU to SUB-CPU
;
; Input:
; mcd_comm_m  | %lp------
;               l - LOCK bit set by MAIN-CPU
;               p - Data-PASS bit
;
; mcd_dcomm_m | From $00 to $07
;               Data packets
;
; Returns:
; mcd_comm_s  | %-p------
;               p - SUB-CPU reports that data passed
; --------------------------------------------------------

SP_cmnd08:
		lea	(scpu_reg+mcd_dcomm_m).w,a2
		move.w	(a2),d0				; a1 - Destination
		swap	d0
		move.w	2(a2),d0
		move.l	d0,a1
		move.b	(scpu_reg+mcd_comm_s).w,d7	; Tell MAIN we got the a1
		bset	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
.wait_start:	move.b	(scpu_reg+mcd_comm_m).w,d0	; Wait for MAIN
		btst	#7,d0
		beq.s	.wait_start
		move.b	(scpu_reg+mcd_comm_s).w,d7
		bclr	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
.next_packet:
		move.b	(scpu_reg+mcd_comm_m).w,d7
		btst	#7,d7
		beq.s	.exit_now
		btst	#6,d7
		beq.s	.next_packet
		move.l	a2,a0
		move.w	(a0)+,(a1)+			; WORD writes to be safe...
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
; 		move.w	(a0)+,(a1)+
; 		move.w	(a0)+,(a1)+
; 		move.w	(a0)+,(a1)+
; 		move.w	(a0)+,(a1)+
		move.b	(scpu_reg+mcd_comm_s).w,d7
		bset	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
.wait_main:	move.b	(scpu_reg+mcd_comm_m).w,d7	; Wait MAIN
		btst	#6,d7
		bne.s	.wait_main
		move.b	(scpu_reg+mcd_comm_s).w,d7
		bclr	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
		bra	.next_packet
.exit_now:
		rts

; =====================================================================
; ----------------------------------------------------------------
; Commands $10-$1F
;
; CDDA
; ----------------------------------------------------------------

; --------------------------------------------------------
; Command $10
;
; Play CDDA Track, once
;
; Input:
; mcd_dcomm_m | dc.w CD track number
;                    - DO NOT USE TRACK 1
;                    - TRACK 0 IS INVALID
; --------------------------------------------------------

SP_cmnd10:
		move.w	#MSCSTOP,d0
		jsr	(_CDBIOS).w
		bsr	subCDDA_ResetVolume
		lea	(scpu_reg+mcd_dcomm_m).w,a0
		move.w	#MSCPLAY1,d0
		jsr	(_CDBIOS).w
		rts

; --------------------------------------------------------
; Command $11
;
; Play CDDA Track, loops
;
; Input:
; mcd_dcomm_m | dc.w track_num ; Track number
;                    - DO NOT USE TRACK 1
;                    - TRACK 0 IS INVALID
; --------------------------------------------------------

SP_cmnd11:
		move.w	#MSCSTOP,d0
		jsr	(_CDBIOS).w
		bsr	subCDDA_ResetVolume
		lea	(scpu_reg+mcd_dcomm_m).w,a0
		move.w	#MSCPLAYR,d0
		jsr	(_CDBIOS).w
		rts

; --------------------------------------------------------
; Command $14
;
; Stop CDDA Track
; --------------------------------------------------------

SP_cmnd14:
		move.w	#MSCSTOP,d0
		jsr	(_CDBIOS).w
		bra	subCDDA_ResetVolume

; --------------------------------------------------------
; Command $16
;
; Fade-out/Fade-in CD Volume
;
; Input:
; mcd_dcomm_m | dc.w target_vol,fade_speed
;
;               Target volume: $000-$400 Max-Min
;               Fade Speed:    $001-$200 Slow-Fast
;                                   $400 Set once
; --------------------------------------------------------

SP_cmnd16:
		move.l	(scpu_reg+mcd_dcomm_m).w,d1
		move.w	#FDRCHG,d0
		jsr	_CDBIOS.w
		rts

; --------------------------------------------------------
; Command $17
;
; CDDA Fade-out
; --------------------------------------------------------

SP_cmnd17:
; 		move.l	#$0380,d1
; 		move.w	#FDRSET,d0			; Set CDDA music volume
; 		jsr	(_CDBIOS).w
; 		move.l	#$0380|$8000,d1
; 		move.w	#FDRSET,d0			; Set CDDA music master volume
; 		jsr	(_CDBIOS).w
; 		rts

; --------------------------------------------------------
; CDDA subroutines:

subCDDA_ResetVolume:
		movem.l	d0-d1/a0-a1,-(sp)
		move.w	#$0400,d1
		move.w	#FDRSET,d0			; Set CDDA music volume
		jsr	(_CDBIOS).w
		move.w	#$0400|$8000,d1
		move.w	#FDRSET,d0			; Set CDDA music master volume
		jsr	(_CDBIOS).w
		movem.l	(sp)+,d0-d1/a0-a1
		rts

; =====================================================================
; ----------------------------------------------------------------
; Commands $20-$2F
;
; Stamps
; ----------------------------------------------------------------

; --------------------------------------------------------
; Command $20
; --------------------------------------------------------

SP_cmnd20:
		rts

; =====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; CD-ROM data
; --------------------------------------------------------

; ------------------------------------------------
; spReadSectorsN
;
; Input:
; a0 - Destination
; d0 - Sector start
; d1 - Number of sectors
; d2 - Destination increment (Only 0 or $800)
; ------------------------------------------------

spReadSectorsN:
		lea	(RAM_CdSub_FsBuff),a5
		andi.l	#$FFFF,d0
		andi.l	#$FFFF,d1
		move.l	d0,(a5)
		move.l	d1,4(a5)
		move.l	a0,8(a5)
		move.b	#%011,(scpu_reg+4).w		; Set CDC device to "Sub CPU"
		move.w	#CDCSTOP,d0			; Stop CDC
		jsr	(_CDBIOS).w
		move.l	a5,a0
		move.w	#ROMREADN,d0			; Read sector by count
		jsr	(_CDBIOS).w
.wait_STAT:
		move.w	#CDCSTAT,d0			; Get CDC Status
		jsr	(_CDBIOS).w
 		bcs.s	.wait_STAT
.wait_READ:
		move.w	#CDCREAD,d0			; CDC Read mode
		jsr	(_CDBIOS).w
		bcs.s	.wait_READ
		move.l	d0,$10(a5)
.WaitTransfer:
		movea.l	8(a5),a0		; a0 - DATA Destination
		lea	$10(a5),a1			; a1 - HEADER out
		move.w	#CDCTRN,d0			; CDC Transfer data
		jsr	(_CDBIOS).w
		bcs.s	.waitTransfer			; If not done, branch

		move.w	#CDCACK,d0			; Finish read
		jsr	(_CDBIOS).w

		addi.l	#$800,8(a5)
		addq.l	#1,(a5)
		subq.l	#1,4(a5)
		bne.s	.wait_STAT
		rts

; ------------------------------------------------
; ISO9660 Driver
; ------------------------------------------------

spInitFS:
		movem.l	d0-d7/a0-a6,-(a7)
	; Load Volume VolumeDescriptor
		moveq	#$10,d0			; Start Sector (at $8000)
		moveq	#$10,d1			; Sector size
		lea	(ISO_Filelist),a0	; Destination
		bsr	spReadSectorsN
	; Load Root Directory
		lea	(ISO_Filelist),a0	; Get pointer to sector buffer
		lea.l	$9C(a0),a1		; Get root directory record
		move.b	6(a1),d0		; Get first part of Sector address
		lsl.l	#8,d0			; bitshift
		move.b	7(a1),d0		; Get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	8(a1),d0		; get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	9(a1),d0		; get final part of sector address
	; d0 now contains start sector address
		moveq	#$10,d1			; Size ($20 Sectors)
		bsr	spReadSectorsN
		movem.l	(a7)+,d0-d7/a0-a6	; Restore all registers
		rts

; --------------------------------------------------------
; spSearchFile
;
; Search a file on the disc
;
; FILETABLE MUST BE LOADED FIRST WITH spInitFS
;
; Input
; a0 - Filename string zero terminated
;
; Output:
; d0.l - Start sector
; d1.l - Number of sectors
; d2.l - Filesize
;
; Breaks:
; d4-d7,a6
; --------------------------------------------------------

; TODO: A ZERO-SIZE CHECK

spSearchFile:
; 		movem.l	a1/a2/a6,-(a7)
		lea	(ISO_Filelist),a4		; a4 - TOP
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
.next_file:
		move.b	(a4),d7			; d7 - Block size
		beq.s	.failed_srch
		andi.w	#$FF,d7
		move.l	a4,a3			; a3 - To search for
		adda	#$19,a3			; Go to flags
		move.b	(a3),d6
		bne.s	.non_file		; $00: iso_file, non-Zero: iso_setfs
		adda	#$07,a3			; Go to filename
		moveq	#0,d6
		move.b	(a3)+,d6
		subq.w	#3+1,d6
		move.l	a0,a2			; a2 - string to seach
.chk_str:
		move.b	(a3)+,d5
		cmp.b	(a2)+,d5
		bne.s	.non_file
		dbf	d6,.chk_str
		bra.s	.found_file
.non_file:
		adda	d7,a4
		bra.s	.next_file
.found_file:
		move.l	6(a4),d0		; d0 - Sector position
		move.l	$E(a4),d1		; d1 - Number of sectors
		move.l	d1,d2			; d2 - ORIGINAL filesize
		lsr.l	#8,d1			; Bitshift numof_sectors
		lsr.l	#3,d1
		rts
.failed_srch:
		moveq	#0,d0
		tst.w	d0
		rts

; =====================================================================
; ----------------------------------------------------------------
; PCM sound
; ----------------------------------------------------------------

; --------------------------------------------------------
; CDPCM_Wait
;
; MUST Call this after writing any PCM register.
; --------------------------------------------------------

CDPCM_Wait:
		nop
		nop
		nop
; 		move.l	d7,-(sp)
; 		move.w	#4,d7
; .WaitLoop:
; 		dbf	d7,.WaitLoop
; 		move.l	(sp)+,d7
		rts

; --------------------------------------------------------
; CDPCM_Init
; --------------------------------------------------------

CDPCM_Init:
	; $0000-$7FFF is blank
	; $8000 is the Silence block until the
	;       streaming routine detects it and
	;       manually stops the channel
	; $8002-$FFFF is unused
		lea	(scpu_pcm),a6
		moveq	#0,d0
		moveq	#-1,d1
		move.b	#$80,d4		; d4 - CTRL in memory mode
		moveq	#$0F,d7		; $0000-$7FFF
		lea	$2001(a6),a5
.clr_pwm:
		move.b	d4,CTREG(a6)
; 		bsr	CDPCM_Wait
		move.l	a5,a4
		move.w	#$0FFC,d6
.wr_end:	move.b	d0,(a4)
		addq.l	#2,a4
		dbf	d6,.wr_end
	rept 4
		move.b	d1,(a4)
		addq.l	#2,a4
	endm
		addq.b	#$01,d4
		dbf	d7,.clr_pwm
		move.b	#$88,d4		; Make silence block
		lea	.data_blk(pc),a0
		move.b	d4,CTREG(a6)	; Slot $8000 for pre-silence
; 		bsr	CDPCM_Wait
		moveq	#32-1,d7
.copy_data:
		move.b	(a0)+,d0
		move.b	d0,(a5)
		addq.l	#2,a5
		dbf	d7,.copy_data
		move.b	#-1,ONREG(a6)
		bra	CDPCM_Wait
.data_blk:
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
		dc.b $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
		align 2

; --------------------------------------------------------
; CDPCM_ReadTable
; --------------------------------------------------------

CDPCM_ReadTable:
		lea	(RAM_CdSub_PcmBuff),a6
		lea	(RAM_CdSub_PcmTable),a5
		moveq	#8-1,d7			; 8 channels
		moveq	#0,d6			; Starting channel number
.get_tbl:
		move.b	(a5),d5
		bclr	#2,d5			; Key-cut?
		beq.s	.no_keyoff
		bsr	.cdcom_keyoff
.no_keyoff:
		bclr	#1,d5			; Key-off?
		beq.s	.no_keycut
		bsr	.cdcom_keyoff
.no_keycut:
		bclr	#0,d5			; Key-on?
		beq.s	.no_comm
		bsr	.cdcom_keyon
.no_comm:
		move.b	d5,(a5)
		adda	#sizeof_cdpcm,a6	; Next PCM buffer
		adda	#1,a5			; Next PCM table column
		addq.w	#1,d6
		dbf	d7,.get_tbl
.dont_upd:
		rts

; --------------------------------------------------------
; pcmcom:
; 0 - Playback bits: %0000PCOK /Pitchbend/keyCut/keyOff/KeyOn
; 8 - Pitch MSB
; 16 - Pitch LSB
; 24 - Volume
; 32 - Panning %RRRRLLLL
; 40 - LoopEnable bit | 24-bit sample location in Sub-CPU area
; 48
; 56
.cdcom_keyoff:
		bclr	d6,(RAM_CdSub_PcmEnbl).l
		move.b	#$80|$20,cdpcm_flags(a6)
		rts

; a0 - table data
; a1 - buffer
.cdcom_keyon:
		bclr	#3,d5			; Effect update ONLY?
		bne	.effect_only
		bsr.s	.cdcom_keyoff
		bsr.s	.effect_mod
		moveq	#0,d0
		move.b	(a0),d0		; 40
		move.b	d0,d3
		adda	#8,a0
		andi.w	#$7F,d0
		swap	d0
		move.b	(a0),d0		; 48
		adda	#8,a0
		lsl.w	#8,d0
		move.b	(a0),d0		; 56
		move.l	d0,a2
		moveq	#0,d0
		moveq	#0,d1			; Read LEN
		move.b	(a2)+,d0
		rol.w	#8,d0
		move.b	(a2)+,d0
		ror.w	#8,d0
		move.b	(a2)+,d1
		swap	d1
		or.l	d1,d0
		move.l	d0,cdpcm_nlen(a6)
		moveq	#0,d1			; Read LEN
		moveq	#0,d0
		move.b	(a2)+,d0
		rol.w	#8,d0
		move.b	(a2)+,d0
		ror.w	#8,d0
		move.b	(a2)+,d1
		swap	d1
		or.l	d1,d0
		move.l	d0,cdpcm_nloop(a6)
		move.l	a2,cdpcm_nstart(a6)
		rol.b	#1,d3
		andi.b	#1,d3
		or.b	#$C0,d3
		move.b	d3,cdpcm_flags(a6)
		rts
.effect_only:
		or.b	#$10,cdpcm_flags(a6)
.effect_mod:
		move.l	a5,a0
		adda	#8,a0
		move.b	(a0),d0		; 8 - Pitch MSB
		adda	#8,a0
		lsl.w	#8,d0
		move.b	(a0),d0		; 16 - Pitch LSB
		adda	#8,a0
		move.b	(a0),d1		; 24 - Volume
		adda	#8,a0
		move.b	(a0),d2		; 32 - Panning
		adda	#8,a0
		move.w	d0,cdpcm_pitch(a6)
		move.b	d1,cdpcm_env(a6)
		move.b	d2,cdpcm_pan(a6)
		rts

; --------------------------------------------------------
; PCM streaming
; --------------------------------------------------------

CDPCM_Stream:
; 		movem.l	d0-a6,-(sp)
		st.b	(RAM_CdSub_PcmMidStrm).w
		bsr.s	CDPCM_Stream_Run
		clr.b	(RAM_CdSub_PcmMidStrm).w
; 		movem.l	(sp)+,d0-a6
		rts
CDPCM_Stream_IRQ:
		tst.b	(RAM_CdSub_PcmMidStrm).w
		beq.s	CDPCM_Stream_Run
		rts
CDPCM_Stream_Run:
		lea	(RAM_CdSub_PcmBuff),a6
		lea	(scpu_pcm),a5
		lea	$23(a5),a4			; <-- RAM-addr MSBs (ODDs)
		moveq	#8-1,d7				; 8 channels, 8 pseudo-buffers
		moveq	#0,d6				; Current channel (also for BTST/BSET/BCLR)
		move.b	(RAM_CdSub_PcmEnbl).l,d5	; Global OFF/ON bits
		not.w	d5				; reverse the bits
.get_addr:
		btst	#7,cdpcm_flags(a6)
		beq.s	.non_strm
		bclr	#6,cdpcm_flags(a6)		; Restart bit?
		beq.s	.no_refill
		bsr	.first_fill
		bra	.non_strm
.no_refill:
		bclr	#5,cdpcm_flags(a6)
		bne.s	.force_off
		move.b	(a4),d3				; Get playback MSB
		bpl.s	.keep_strm
		btst	#0,cdpcm_flags(a6)
		bne.s	.keep_strm
.force_off:
		bset	d6,d5
		move.b	d5,ONREG(a5)
		clr.b	cdpcm_flags(a6)
		bra.s	.non_strm
.keep_strm:
		bclr	#4,cdpcm_flags(a6)
		beq.s	.non_upd
		bsr	.update_set
.non_upd:
		move.b	cdpcm_strmhalf(a6),d4		; Check halfway $x0/$x4/$x8/$xC
		andi.b	#$0E,d3
		cmp.b	d4,d3
		bne.s	.non_strm
		move.w	d3,d4
		addq.w	#$02,d4
		andi.w	#$0E,d4
		move.b	d4,cdpcm_strmhalf(a6)
		move.l	cdpcm_cread(a6),a0
		move.l	cdpcm_clen(a6),d1
		lsl.w	#8,d4				; << 8
		move.l	#$0200,d3			; d3 - Block size
		cmp.w	#$0E00,d4			; Looping block?
		bne.s	.lowhalf
		sub.l	#4,d3				; loop block is -4
.lowhalf:
		bsr	.make_blk_strm
		move.l	d1,cdpcm_clen(a6)
		move.l	a0,cdpcm_cread(a6)
.non_strm:
		adda	#sizeof_cdpcm,a6		; Next PCM buffer
		adda	#4,a4				; Next MSB
		addq.w	#1,d6				; Next channel
		dbf	d7,.get_addr
		not.w	d5				; reverse return bits
		move.b	d5,(RAM_CdSub_PcmEnbl).l
		rts

; --------------------------------------------------------
; a0 - wave data to write
; d1 - channel current length
; d3 - block size
; d4 - current block slot to write
; d6 - current channel

.make_blk_strm:
		move.b	d6,d0
		or.b	#$80,d0
		move.b	d0,CTREG(a5)
; 		bsr	CDPCM_Wait
		lea	$2001(a5),a1
		add.w	d4,d4
		adda	d4,a1
		move.w	d3,d4
; 		lsr.w	#2,d3		; /4
		subq.w	#1,d4
		btst	#0,cdpcm_flags(a6)
		beq	.end_point

; ----------------------------------------
; Wave has loop
; ----------------------------------------

.loop_point:
		movea.l	cdpcm_start(a6),a2
		move.l	cdpcm_loop(a6),d0
		add.l	d0,a2
		move.l	cdpcm_len(a6),d2
		sub.l	d0,d2
.loop_strm:
		subq.l	#1,d1
		bne.s	.strlen_it
		move.l	a2,a0
		move.l	d2,d1
		move.l	d1,cdpcm_clen(a6)
.strlen_it:
		move.b	(a0)+,d0
		bsr	CDPCM_WavToPcm
		move.b	d0,(a1)
; 		bsr	CDPCM_Wait
		addq.l	#2,a1
		dbf	d4,.loop_strm
		rts

; ----------------------------------------
; Wave doesn't loop
; ----------------------------------------

.end_point:
		moveq	#-1,d0
		subq.l	#1,d1
		beq.s	.stlen_it
		bmi.s	.stlen_it
		move.b	(a0)+,d0
		bsr	CDPCM_WavToPcm
.stlen_it:
		move.b	d0,(a1)
; 		bsr	CDPCM_Wait
		addq.l	#2,a1
		dbf	d4,.end_point
		tst.l	d1
		bpl.s	.not_end
		move.b	d6,d0
		or.b	#$C0,d0
		move.b	d0,CTREG(a5)
		bsr	CDPCM_Wait
		move.w	#$8000,d0	; Relocate PCM to SILENCE block on LOOP -1
		move.b	d0,LSL(a5)
		bsr	CDPCM_Wait
		lsr.w	#8,d0
		move.b	d0,LSH(a5)
		bsr	CDPCM_Wait
		bclr	d6,d5
.not_end:
		rts

; --------------------------------------------------------
; Channel changes
; --------------------------------------------------------

.update_set:
		move.b	d6,d0
		or.b	#$C0,d0
		move.b	d0,CTREG(a5)
		move.w	cdpcm_pitch(a6),d2
		move.b	d2,FDL(a5)
		bsr	CDPCM_Wait
		lsr.w	#8,d2
		move.b	d2,FDH(a5)
		bsr	CDPCM_Wait
		move.b	cdpcm_pan(a6),d2	; Panning
		move.b	d2,PAN(a5)
		bsr	CDPCM_Wait
		move.b	cdpcm_env(a6),d2	; Envelope
		move.b	d2,ENV(a5)
		bra	CDPCM_Wait

; --------------------------------------------------------
; First fill
; --------------------------------------------------------

.first_fill:
		bset	d6,d5
		move.b	d5,ONREG(a5)		; Stop channel first
		bsr	CDPCM_Wait
		move.l	cdpcm_nstart(a6),cdpcm_start(a6)
		move.l	cdpcm_nlen(a6),cdpcm_len(a6)
		move.l	cdpcm_nloop(a6),cdpcm_loop(a6)

		move.l	cdpcm_start(a6),a0	; Make first block
		move.l	cdpcm_len(a6),d1
		bsr	.make_lblk
		move.l	a0,cdpcm_cread(a6)
		move.l	d1,cdpcm_clen(a6)
		move.b	d6,d0
		or.b	#$C0,d0
		move.b	d0,CTREG(a5)
		bsr	CDPCM_Wait
		bsr	.update_set
		move.b	d6,d0
		lsl.w	#4,d0
		move.b	d0,d2
		move.b	d0,ST(a5)		; Start MSB
		bsr	CDPCM_Wait
		lsl.w	#8,d0
		tst.l	d1
		bmi.s	.small_sampl
		beq.s	.small_sampl
		move.b	#0,cdpcm_strmhalf(a6)
		bra.s	.set_nonstop

; --------------------------------------------------------

.small_sampl:
		btst	#0,cdpcm_flags(a6)
		beq.s	.set_endloop
		move.l	cdpcm_loop(a6),d3
		move.l	d3,d0
		bra	.set_nonstop
.set_endloop:
		move.w	#$8000,d0		; BLANK WAVE pointer
.set_nonstop:
		move.b	d0,LSL(a5)
		bsr	CDPCM_Wait
		lsr.w	#8,d0
		move.b	d0,LSH(a5)
		bsr	CDPCM_Wait
		bclr	d6,d5
		move.b	d5,ONREG(a5)
		bra	CDPCM_Wait

; --------------------------------------------------------
; a0 - Wave data
; a1 - Output to memory (set with CTREG first)
; d1 - Wave length counter
; d6 - current channel

.make_lblk:
		move.b	d6,d0		; Set channel as memory slot
		or.b	#$80,d0
		move.b	d0,CTREG(a5)
		bsr	CDPCM_Wait
		lea	$2001(a5),a1
		move.w	#$200,d3	; BLOCK SIZE
		lsr.w	#2,d3		; /4
		subq.w	#1,d3
.wave_blkl:
		tst.l	d1
		bmi.s	.fill_mode
	rept 4
		moveq	#-1,d0		; Set loop flag
		subq.l	#1,d1		; Len counter
		beq.s	.len_it		; If ran out of wave data, write -1 now.
		move.b	(a0)+,d0	; Read wave and convert
		bsr	CDPCM_WavToPcm
.len_it:
		move.b	d0,(a1)
; 		bsr	CDPCM_Wait
		addq.l	#2,a1
	endm
		dbf	d3,.wave_blkl
		rts
; Fill unused block
.fill_mode:
		moveq	#-1,d0
.loop_blkl:
	rept 4
		move.b	d0,(a1)
; 		bsr	CDPCM_Wait
		addq.l	#2,a1
	endm
		dbf	d3,.loop_blkl
		rts

; --------------------------------------------------------

CDPCM_WavToPcm:
		andi.w	#$FF,d0
		move.b	.wave_list(pc,d0.w),d0
		rts
.wave_list:
	dc.b $FE,$FE,$FD,$FC,$FB,$FA,$F9,$F8,$F7,$F6,$F5,$F4,$F3,$F2,$F1,$F0
	dc.b $EF,$EE,$ED,$EC,$EB,$EA,$E9,$E8,$E7,$E6,$E5,$E4,$E3,$E2,$E1,$E0
	dc.b $DF,$DE,$DD,$DC,$DB,$DA,$D9,$D8,$D7,$D6,$D5,$D4,$D3,$D2,$D1,$D0
	dc.b $CF,$CE,$CD,$CC,$CB,$CA,$C9,$C8,$C7,$C6,$C5,$C4,$C3,$C2,$C1,$C0
	dc.b $BF,$BE,$BD,$BC,$BB,$BA,$B9,$B8,$B7,$B6,$B5,$B4,$B3,$B2,$B1,$B0
	dc.b $AF,$AE,$AD,$AC,$AB,$AA,$A9,$A8,$A7,$A6,$A5,$A4,$A3,$A2,$A1,$A0
	dc.b $9F,$9E,$9D,$9C,$9B,$9A,$99,$98,$97,$96,$95,$94,$93,$92,$91,$90
	dc.b $8F,$8E,$8D,$8C,$8B,$8A,$89,$88,$87,$86,$85,$84,$83,$82,$81,$80
	dc.b $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
	dc.b $10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F
	dc.b $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$2E,$2F
	dc.b $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
	dc.b $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F
	dc.b $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F
	dc.b $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F
	dc.b $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F
	align 2

; --------------------------------------------------------
; CDPCM_Update
;
; Only checks for playback changes
; --------------------------------------------------------

; CDPCM_Update:
; 		lea	(RAM_CdSub_PcmBuff),a6
; 		lea	(scpu_pcm),a5
; 		lea	$23(a5),a4			; <-- RAM-addr MSBs (ODDs)
; 		moveq	#8-1,d7				; 8 channels, 8 pseudo-buffers
; 		moveq	#0,d6				; Current channel (also for BTST/BSET/BCLR)
; 		move.b	(RAM_CdSub_PcmEnbl).l,d5	; Global OFF/ON bits
; 		not.w	d5				; reverse the bits
; .get_addr:
; 		btst	#7,cdpcm_flags(a6)	; Channel active?
; 		beq	.non_upd
; 		bclr	#6,cdpcm_flags(a6)	; Restart bit?
; 		beq.s	.no_refill
; 		bsr	.first_fill
; .no_refill:
;
; ; .stop_bit:	bclr	#5,cdpcm_flags(a6)	; Stop bit?
; ; 		beq.s	.not_stop
; ; 		bset	d6,d5
; ; 		move.b	d5,ONREG(a5)		; Stop channel first
; ; ; 		bsr	CDPCM_Wait
; ; 		clr.b	cdpcm_flags(a6)
; ; .not_stop:
; ; 		bclr	#4,cdpcm_flags(a6)
; ; 		beq.s	.non_upd
; ; 		bsr	.update_set
; ; .non_upd:
; 		adda	#sizeof_cdpcm,a6	; Next PCM buffer
; 		adda	#4,a4			; Next MSB
; 		addq.w	#1,d6			; Next channel
; 		dbf	d7,.get_addr
; .non_chng:
; 		not.w	d5			; reverse return bits
; 		move.b	d5,(RAM_CdSub_PcmEnbl).l
; 		rts

; ====================================================================
; ----------------------------------------------------------------
; Internal buffers
; ----------------------------------------------------------------

; 			align $80

; ====================================================================
; ----------------------------------------------------------------
; RAM
; ----------------------------------------------------------------

			align $80
SP_RAM:
			strct SP_RAM
RAM_CdSub_PcmBuff	ds.b 8*sizeof_cdpcm
RAM_CdSub_PcmTable	ds.b 8*8		; Z80 table
RAM_CdSub_PcmEnbl	ds.b 1			; PCM enable bits
RAM_CdSub_PcmPlay	ds.b 1
RAM_CdSub_PcmMidStrm	ds.b 1
RAM_CdSub_PcmTblUpd	ds.b 1
; BRAM_Buff		ds.b $640
ISO_Filelist		ds.b $800*$10
ISO_Output		ds.b $800*$10
RAM_CdSub_FsBuff	ds.l $20
sizeof_subcpu		ds.l 0
			endstrct

			erreport "SUB-CPU IP",sizeof_subcpu,$20000

; ====================================================================
; ----------------------------------------------------------------
; SUB-CPU data
; ----------------------------------------------------------------

			dephase
			phase $20000
SUBCPU_DATA:
			dephase
			dephase
