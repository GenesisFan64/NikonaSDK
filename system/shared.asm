; ===========================================================================
; ----------------------------------------------------------------
; Shared variables
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; 32X SECTION
; ----------------------------------------------------------------

	if MARS|MARSCD

; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_MARSSPR	equ 16

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

		strct 0
mscrl_Art	ds.l 1		; Block data on SH2 map
mscrl_Xpos	ds.l 1		; 0000.0000
mscrl_Ypos	ds.l 1		; 0000.0000
mscrl_Ybot	ds.w 1		; TODO
mscrl_Ytop	ds.w 1
sizeof_marsscrl	ds.l 1
		endstrct

		strct 0
sspr_Flags	ds.w 1
sspr_Frame	ds.w 1
sspr_Size	ds.w 1		; XXYY
sspr_Indx	ds.w 1
sspr_Xpos	ds.w 1
sspr_Ypos	ds.w 1
sspr_Art	ds.l 1
sizeof_marsspr	ds.l 1
		endstrct

; ----------------------------------------------------------------
; 32X DREQ-RAM
;
; To read these labels:
;
; On the Genesis:
; 	lea	(RAM_MdDreq+DREQ_LABEL),aX ; This or use an alias
; On the 32X:
; 	mov	#DREQ_LABEL,rX
; 	mov	@(marsGbl_DmaRead,gbr),r0
;	add	r0,rX
; ----------------------------------------------------------------

; *** List MUST be aligned by 8bytes, end with 0 or 8 ***

		strct 0
Dreq_Palette	ds.w 256			; 256-color palette *DON'T MOVE THIS*
Dreq_ScrlData	ds.w (512/16)*(256/16)
Dreq_ScrlBuff	ds.b sizeof_marsscrl
Dreq_SuperSpr	ds.b sizeof_marsspr*MAX_MARSSPR
sizeof_dreq	ds.l 0
		endstrct

	if MOMPASS=5
	if (sizeof_dreq&7) <> 0
		error "DREQ IS MISALIGNED: \{sizeof_dreq}"
; 	else
; 		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
	endif

; --------------------------------------------------------
; Alias labels
; --------------------------------------------------------

RAM_MdMars_Palette	equ RAM_MdDreq+Dreq_Palette
RAM_MdMars_SuperSpr	equ RAM_MdDreq+Dreq_SuperSpr
RAM_MdMars_ScrlData	equ RAM_MdDreq+Dreq_ScrlData
RAM_MdMars_ScrlBuff	equ RAM_MdDreq+Dreq_ScrlBuff

; --------------------------------------------------------

	endif	; end MARS|MARSCD
