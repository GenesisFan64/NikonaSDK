; ===========================================================================
; NIKONA MD 16-BIT/32-BIT SDK
; (C)2023-2024 GenesisFan64
;
; For developing games on the Genesis-family of systems
; including Sega CD, Sega 32X, Sega CD32X and Sega Pico
;
; Assemble with a modified AS Macro Assembler by flamewing
; and a custom version of p2bin:
;
; asl main.asm -i "." -olist ROM.lst -q -xx -A -L -D (flags)
; p2bin -p=00 main.p ROM.bin
;
; ASSEMBLER FLAGS:
; MCD,MARS,MARSCD,PICO,CDREGION,EMU

; * System targets, MUST include ALL and set 1 to
; the target console and the others to 0
;    MCD - Sega CD
;   MARS - Sega 32X
; MARSCD - Sega CD32X
;   PICO - Sega Pico
; The code builds to stock Genesis by default,
; ONLY CHOOSE ONE TARGET AT THE TIME.
;
; CDREGION - SEGACD/CD32X ONLY, Set ROM region:
;            0=Japan 1=USA 2=Europe
;      EMU - 0=Real hardware, 1=Emulator only
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
; ===========================================================================

; ====================================================================
; ----------------------------------------------------------------
; USER SETTINGS
; ----------------------------------------------------------------

; --------------------------------------------------------
; 68000 RAM SIZES (MAIN-CPU)
;
; MAX_SysCode, MAX_UserCode are only used in Sega CD
; Sega 32X and CD32X.
; These sections are free to use on stock Genesis
; and Pico in case you are not interested on the add-ons.
;
; RESERVED RAM ADDRESSES:
; $FFFB00-$FFFD00 | Stack a7
; $FFFD00-$FFFDFF | RESERVED for the Sega CD Vector jumps
;                   FREE if running on cartridge
;                   (Genesis,32X,Pico)
; $FFFE00-$FFFEFF | RESERVED for Sega CD, BIOS uses this area
;                   temporals
;                   ** Not sure if this can be used after
;                   during the application **
; $FFFF00-$FFFFFF | RESERVED for the Sound Driver,
;                   The Z80 driver writes to this area
; --------------------------------------------------------

MAX_SysCode	equ $2000	; Task routines ** CD/32X/CD32X ONLY **
MAX_UserCode	equ $8000	; USER code ** CD/32X/CD32X ONLY **
MAX_ScrnBuff	equ $1800	; Current screen buffer
MAX_MdVideo	equ $2000	; Video cache'd visuals, registers, etc.
MAX_MdSystem	equ $0600	; Internal lib stuff and a copy of save data for reading/writing
MAX_MdOther	equ $0C00	; Add-on stuff

; ====================================================================

		org 0
		cpu 		68000		; Starting CPU is 68000
		padding		off		; Dont pad dc.b
		listing 	purecode	; Want listing file
		supmode 	on 		; Supervisor mode (68K)
		dottedstructs	off
		page 		0

; ====================================================================
; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

		include	"macros.asm"		; Assembler macros
		include "game/globals.asm"	; USER variables
		include	"system/mcd/map.asm"	; Sega CD hardware map (shared with Sub-CPU)
		include	"system/mars/map.asm"	; 32X hardware map (shared with SH2)
		include	"system/md/map.asm"	; Genesis hardware map and other areas
		include	"system/md/ram.asm"	; Genesis RAM sections
		include	"system/shared.asm"	; Shared variables and specials

; ====================================================================
; ----------------------------------------------------------------
; Init procedures for all systems
; ----------------------------------------------------------------

; ---------------------------------------------
; SEGA 32X
; ---------------------------------------------

	if MARS
		include	"system/head_mars.asm"			; 32X header
		lea	($880000+Md_SysCode),a0			; Transfer SYSTEM subs
		lea	(RAM_SystemCode),a1
		move.w	#((Md_SysCode_e-Md_SysCode))-1,d0
.copy_1:
		move.b	(a0)+,(a1)+
		dbf	d0,.copy_1
		jsr	(Sound_init).l			; Init Sound driver FIRST
		jsr	(Video_init).l			;  ''  Video
		jsr	(System_Init).l			;  ''  System
		move.w	#0,(RAM_ScreenMode).w		; Start at screen 0
		jmp	(Md_ReadModes).l		; Jump to RAM

; ---------------------------------------------
; SEGA CD and CD32X
;
; This one is tricky...
; ---------------------------------------------

	elseif MCD|MARSCD
		include	"system/head_mcd.asm"			; Sega CD header
mcdin_top:
		lea	Md_SysCode(pc),a0			; Transfer SYSTEM subs
		lea	(RAM_SystemCode),a1			; At TOP of RAM
		move.w	#((Md_SysCode_e-Md_SysCode))-1,d0
.copy_1:
		move.b	(a0)+,(a1)+
		dbf	d0,.copy_1
	if MARSCD					; CD32X boot
		include "system/mcd/marscd.asm"
	endif
		lea	(RAM_MdVideo),a0		; Clean our "work" RAM starting from here
		move.l	#sizeof_mdram,d1
		moveq	#0,d0
.loop_ram:	move.w	d0,(a0)+
		cmp.l	d1,a0
		bcs.s	.loop_ram
		jsr	(Sound_init).l			; Init Sound driver FIRST
		jsr	(Video_init).l			;  ''  Video
		jsr	(System_Init).l			;  ''  System
		move.w	#0,(RAM_ScreenMode).l		; Start at screen 0
		jmp	(Md_ReadModes).l		; Go to SCREENJUMP section
		phase $FFFF0600+*
Z80_CODE:	include "sound/driver/gema_zdrv.asm"	; <-- Z80 code loaded from here
Z80_CODE_END:
		dephase

; ---------------------------------------------
; SEGA PICO
;
; This recycles the MD's routines.
; ---------------------------------------------
	elseif PICO
		include	"system/head_pico.asm"		; Pico header
		bsr	Sound_init			; Init Sound driver FIRST
		bsr	Video_init			;  ''  Video
		bsr	System_Init			;  ''  Values
		move.w	#0,(RAM_ScreenMode).w		; Start at screen 0
		bra.w	Md_ReadModes			; Go to SCREENJUMP section

; ---------------------------------------------
; MD
; ---------------------------------------------
	else
		include	"system/head_md.asm"		; Genesis header
		bsr	Sound_init			; Init Sound driver FIRST
		bsr	Video_init			;  ''  Video
		bsr	System_Init			;  ''  Values
		move.w	#0,(RAM_ScreenMode).w		; Start at screen 0
		bra.w	Md_ReadModes			; Go to SCREENJUMP section

; ---------------------------------------------
	endif

; ====================================================================
; --------------------------------------------------------
; SYSTEM routines and MODE switching code
;
; MD and PICO: Normal ROM locations
; CD/32X/CD32X: Loaded into RAM
; --------------------------------------------------------

	if MCD|MARS|MARSCD
Md_SysCode:
		phase RAM_SystemCode
	endif
; ---------------------------------------------

		include	"sound/driver/gema.asm"
		include	"system/md/video.asm"
		include	"system/md/system.asm"

; ---------------------------------------------
; Read screen modes
;
;   MD/Pico: Direct ROM jump
; SCD/CD32X: Reads file from disc and
;            transfers code to RAM
;       32X: Read from ROM and copies code to
;            RAM so it's problematic with DMA
;            and the SH2
;
; - Returning in your current screen code will
; loop here.
; - DO NOT JUMP TO SCREEN MODES DIRECTLY
; ---------------------------------------------

Md_ReadModes:
		ori.w	#$0700,sr		; Disable interrupts
		moveq	#0,d0
		move.w	(RAM_ScreenMode).w,d0
		and.w	#$7F,d0			; <-- CURRENT LIMIT
		lsl.w	#4,d0			; * $10
		lea	.pick_mode(pc,d0.w),a0	; LEA the filename
	if MCD|MARSCD
		adda	#4,a0
		jsr	(System_GrabRamCode).l
	elseif MARS
		movea.l	.pick_mode(pc,d0.w),a0	; d0 - ROM location $880000+
		jsr	(System_GrabRamCode).l
	else
		movea.l	.pick_mode(pc,d0.w),a0	; Location to JUMP to.
		jsr	(a0)
	endif
		bra.s	Md_ReadModes		; Loop on rts

; ---------------------------------------------
; ** ADD SCREEN MODES HERE **
; ---------------------------------------------

.pick_mode:
		dc.l Md_Screen00	; Cartridge label (unused on CD)
		dc.b "SCREEN00.BIN"	; ISO Filename (unused on Cartridge)
		dc.l Md_Screen00
		dc.b "SCREEN00.BIN"
		dc.l Md_Screen00
		dc.b "SCREEN00.BIN"
		dc.l Md_Screen00
		dc.b "SCREEN00.BIN"
		dc.l Md_Screen00

; ---------------------------------------------

	if MCD|MARS|MARSCD
.end:
		erreport "SYSTEM TOP RAM-CODE",(.end-RAM_SystemCode),MAX_SysCode
		dephase
		phase (.end-RAM_SystemCode)+Md_SysCode
	endif
Md_SysCode_e:
		align 2

; ===========================================================================
; --------------------------------------------------------
; Z80 include on Cartridge ONLY (NOT on Disc)
; --------------------------------------------------------

	if MCD|MARSCD=0
Z80_STPOS:
	if MARS
		phase $880000+*		; 32X cartridge: $880000+ area
	endif
Z80_CODE:	include "sound/driver/gema_zdrv.asm"
Z80_CODE_END:
	if MARS
		dephase
		phase (Z80_CODE_END-Z80_CODE)+Z80_STPOS
	endif
	endif

; ===========================================================================
; ----------------------------------------------------------------
; DATA section shared on both Cartridge or Disc
; ----------------------------------------------------------------

; --------------------------------------------------------
; CD/CD32X ISO header and files
; --------------------------------------------------------

	if MCD|MARSCD
		align $8000
		binclude "system/mcd/fshead.bin"	; Include ISO header
		iso_setfs 0,IsoFileList,IsoFileList_e	; TWO pointers to the filelist:
		iso_setfs 1,IsoFileList,IsoFileList_e
IsoFileList:
		iso_file "SUB_DATA.BIN",MCD_SUBDATA,MCD_SUBDATA_e
		iso_file "MARSCODE.BIN",MARS_RAMCODE,MARS_RAMCODE_E
		iso_file "DATABNKD.BIN",MCD_DBANK0,MCD_DBANK0_e
		iso_file "MARSD_00.BIN",MARSDATA_DEFAULT,MARSDATA_DEFAULT_E
		iso_file "SCREEN00.BIN",Md_Screen00,Md_Screen00_e
		align $800
IsoFileList_e:
	endif

; ====================================================================
; --------------------------------------------------------
; SEGA CD SUB-CPU data
; --------------------------------------------------------

	if MCD|MARSCD
		align $800
MCD_SUBDATA:
		phase $20000				; <-- MANUAL location on Sub-CPU
		include "sound/smpl_pcm.asm"		; PCM samples
.here:
		erreport "SUB-CPU DATA",.here,$80000
		dephase
		phase MCD_SUBDATA+(.here-$20000)
		align $800
MCD_SUBDATA_E:
	endif

; ----------------------------------------------------------------
; SH2 code and shared data stored in SDRAM
; ----------------------------------------------------------------

	if MCD|MARSCD
		align $800
	elseif MARS
		align 4
	endif
MARS_RAMCODE:
	if MARS|MARSCD
		include "system/mars/code.asm"
	endif
	if MCD|MARSCD
		align $800
	endif
MARS_RAMCODE_E:

; ====================================================================
; --------------------------------------------------------
; Screen modes
;
; These are stored as separate files on DISC
;
; Usage:
; screen_code START_LABEL,END_LABEL,CODE_PATH
; --------------------------------------------------------

	screen_code Md_Screen00,Md_Screen00_e,"game/screen_0/code.asm"
; 	screen_code Md_Screen01,Md_Screen01_e,"game/screen_1/code.asm"

; ====================================================================
; ----------------------------------------------------------------
; 68K DATA BANKs
;
; SEGA CD / CD32X:
; Stored in WORD-RAM pieces
; limited to 256KB 2M or 128KB 1M/1M
; ** WORD-RAM CANNOT BE USED IF USING ASIC STAMPS **
;
; SEGA 32X Cartridge:
; Limited to 1MB bankswitchable.
; ONLY 4 banks can be used, Bank 0 already uses the
; first 512KB for the code.
;
; For multi-porting keep the data size limited to 256KB.
; ----------------------------------------------------------------

; --------------------------------------------------------
; DEFAULT BANK
;
; CD/CD32X:
; $200000 256KB (WORD-RAM)
;
; 32X:
; $900000 1MB (Bankswichable area)
;
; Usage:
; data_bkset LABEL_START,OPTION
; (your includes and bincludes)
; data_bkend LABEL_START,LABEL_END,used_size
;
; OPTION (32X Cartridge ONLY):
;  0, Normal 32X $900000 bank
; -1, First 32X $900000 bank
; * Ignored on other systems.
; --------------------------------------------------------

	data_bkset MCD_DBANK0,-1
mdbank0:
		include "sound/tracks.asm"		; GEMA: Track data
		include "sound/instr.asm"		; GEMA: FM instruments
		include "sound/smpl_dac.asm"		; (MCD/CD32X ONLY) GEMA: DAC samples
		include "game/screen_0/data_bank.asm"
	if MCD|MARSCD
		include "game/screen_0/data_dma.asm"	; SEGA CD / CD32X ONLY.
	endif
mdbank0_e:
	data_bkend MCD_DBANK0,MCD_DBANK0_e,mdbank0_e-mdbank0

; --------------------------------------------------------
; BANK 1
; --------------------------------------------------------

; 	data_bank MCD_DBANK1,-1
; 		org $200000-4
; 		dc.b "BNK1"
; 	data_bank_e MCD_DBANK1_e

; --------------------------------------------------------
; BANK 2
; --------------------------------------------------------

; 	data_bank MCD_DBANK2,-1
; 		org $300000-4
; 		dc.b "BNK2"
; 	data_bank_e MCD_DBANK2_e

; --------------------------------------------------------
; BANK 3
; --------------------------------------------------------

; 	data_bank MCD_DBANK3,-1
; 		org $400000-4
; 		dc.b "BNK3"
; 	data_bank_e MCD_DBANK3_e

; ====================================================================
; ----------------------------------------------------------------
; 32X/CD32X ONLY
;
; SDRAM DATA packages for each screen mode
;
; Usage:
; sdram_bank START_LABEL,END_LABEL
; (includes and bincludes)
; sdram_bank_e START_LABEL,END_LABEL
; ----------------------------------------------------------------

; ---------------------------------------------
; DEFAULT
; ---------------------------------------------

	sdram_bkset MARSDATA_DEFAULT,MARSDATA_DEFAULT_e
	include "game/screen_0/data_mgfx.asm"
	sdram_bkend MARSDATA_DEFAULT,MARSDATA_DEFAULT_e

; ====================================================================
; ----------------------------------------------------------------
; Cartridge DMA graphics data
;
; BANK-free on 32X Cartridge
; ----------------------------------------------------------------

	if MCD|MARSCD=0		; <-- NOT for CD
		include "game/screen_0/data_dma.asm"
	endif

; ====================================================================
; ---------------------------------------------
; End
; ---------------------------------------------

ROM_END:
	if MCD|MARSCD
; 		align $800
; 		rompad (ROM_END&$FFFF00)+$10
.here:		rompad .here&$FF0000+$10000
	else
		align $8000			; Cartridge padding
	endif
