; ===========================================================================
; ----------------------------------------------------------------
; Genesis 68000 "MAIN-CPU" RAM section
;
; RESERVED RAM areas:
; $FFFB00-$FFFD00 | Stack area a7
; $FFFD00-$FFFDFF | RESERVED for the Sega CD Vector jumps,
;                   * FREE to use if running on Cartridge.
;                   (Genesis,32X,Pico.)
; $FFFE00-$FFFEFF | USED in Sega CD for the BIOS, BUT this might
;                   be free to use after booting **NEEDS testing**
;                   * FREE to use on Cartridge.
; $FFFF00-$FFFFFF | RESERVED for the Sound Driver
;                   This area will probably be used for the 68k
;                   version of GEMA for the Pico, but currently
;                   the Z80 sets a flag around here for a
;                   workaround to read data located at the
;                   RAM area, it will be required if the
;                   SegaCD does stamp processing and the game
;                   still needs sound.
; ----------------------------------------------------------------

; --------------------------------------------------------
; Settings
; --------------------------------------------------------

			strct $FFFF0000
RAM_SystemCode		ds.b MAX_SysCode	; CD/32X/CD32X
RAM_UserCode		ds.b MAX_UserCode	; CD/32X/CD32X

; ------------------------------------------------
; > $FF8000 section
; ------------------------------------------------

check_thisram		ds.l 0			; <-- get current pos
	if check_thisram&$FFFF < $8000
		error "This RAM section doesn't start from $FF80000 \{check_thisram&$FFFF}"
	endif
RAM_MdVideo		ds.b MAX_MdVideo	; $FF8000
RAM_MdSystem		ds.b MAX_MdSystem	;
RAM_MdOther		ds.b MAX_MdOther	; 32X's DREQ goes here
RAM_ScrnBuff		ds.b MAX_ScrnBuff
RAM_MdGlobal		ds.b sizeof_MdGlbl
sizeof_MdRam		ds.l 0
			endstrct
		if (sizeof_MdRam&$FF0000 == 0) | (sizeof_MdRam&$FFFFFF>$FFFB00)	; <-- maximum is $FFFB00
			error "RAN OUT OF MD RAM"
		endif

; ------------------------------------------------
; Add-on area
; ------------------------------------------------

			strct RAM_MdOther
RAM_MdDreq		ds.b $E00		; 32X DREQ RAM size (MANUALLY SET)
sizeof_RamOther		ds.l 0
			endstrct
			erreport "32X DREQ RAM USES",(sizeof_RamOther-RAM_MdOther),MAX_MdOther

; ------------------------------------------------
; Reserved areas
; ------------------------------------------------

RAM_Stack		equ RAM_MegaCd		; <-- goes backwards
RAM_MegaCd		equ $FFFFFD00
RAM_ZSndBuff		equ $FFFFFF00
