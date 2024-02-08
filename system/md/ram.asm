; ====================================================================
; ----------------------------------------------------------------
; MD RAM
;
; Reserved RAM sections:
; $FFFD00-$FFFDFF: Sega CD's vectors
; $FFFE80-$FFFFFF: Z80 write-only scratchpad
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
RAM_MdDreq		ds.b $C00		; 32X DREQ area (MANUAL SIZE)
sizeof_RamOther		ds.l 0
			endstrct
			erreport "ADD-ON RAM USES",(sizeof_RamOther-RAM_MdOther),MAX_MdOther

; ------------------------------------------------
; Other
; ------------------------------------------------

RAM_Stack		equ RAM_MegaCd			; <-- goes backwards
RAM_MegaCd		equ $FFFFFD00
RAM_ZSndBuff		equ $FFFFFF00
