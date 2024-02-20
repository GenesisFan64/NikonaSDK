; ===========================================================================
; ----------------------------------------------------------------
; MACROS section
;
; THIS MUST BE INCLUDED AT THE VERY START.
; ----------------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Functions
; --------------------------------------------------------

locate		function a,b,c,(b&$FF)|(a<<8&$FF00)|(c<<16&$FF0000)	; VDP locate: X pos|Y pos|Layer for some video
cell_vram	function a,(a<<5)					; Vram position in 8x8 CELLS
map_size	function l,r,(((l-1)/8)<<16&$FFFF0000|((r-1)/8)&$FFFF)	; Full w/h sizes, for cell sizes use doubleword
; md_ramloc	function x,-(-x)&$FFFFFFFF

; ====================================================================
; --------------------------------------------------------
; Macros
; --------------------------------------------------------

currPadding	set 0
notZ80		function cpu,(cpu<>128)&&(cpu<>32988)

; -------------------------------------
; Reserve memory
;
; (Doesn't work on Z80)
; -------------------------------------

strct		macro thisinput			; Reserve memory address
GLBL_LASTPC	set *
		dephase
		phase thisinput
GLBL_LASTORG	set *
		endm

; -------------------------------------
; Finish struct
; -------------------------------------

endstrct	macro				; Then finish the custom struct.
		org GLBL_LASTORG
		phase GLBL_LASTPC
		endm

; -------------------------------------
; Report memory usage
; -------------------------------------

report		macro text,dis,dat
	if MOMPASS == 2
		if dat == -1
			message text+": \{(dis)&$FFFFFF}"
		else
			if dis > dat
				warning "RAN OUT OF "+text+" SPACE (\{(dis)&$FFFFFF} of \{(dat)&$FFFFFF})"
			else
				message text+" uses \{(dis)&$FFFFFF} of \{(dat)&$FFFFFF}"
			endif
		endif
	endif
		endm

; -------------------------------------
; Same thing but only show on error
; -------------------------------------

erreport	macro text,dis,dat
	if MOMPASS == 2
		if dat == -1
			message text+": \{(dis)&$FFFFFF}"
		else
			if dis > dat
				error "RAN OUT OF "+text+" (\{(dis)&$FFFFFF} of \{(dat)&$FFFFFF})"
; 			else
; 				message text+" uses \{(dis)&$FFFFFF} of \{(dat)&$FFFFFF}"
			endif
		endif
	endif
		endm

; -------------------------------------
; ZERO Fill padding
; -------------------------------------

rompad		macro address			; Zero fill
diff := address - *
		if diff < 0
			error "too much stuff before org $\{address} ($\{(-diff)} bytes)"
		else
			while diff > 1024
				; AS can only generate 1 kb of code on a single line
				dc.b [1024]0
diff := diff - 1024
			endm
			dc.b [diff]0
		endif
	endm

; ====================================================================
; --------------------------------------------------------
; ISO filesystem macros
; --------------------------------------------------------

; Set a ISO file
; NOTE: a valid ISO head is required from $8000 to $B7FF
; DATES are random here

iso_setfs	macro type,start,end
.fstrt:
		dc.b .fend-.fstrt				; Block size
		dc.b 0						; zero
		dc.b (start>>11&$FF),(start>>19&$FF)		; Start sector, little
		dc.b (start>>27&$FF),(start>>35&$FF)
		dc.l start>>11					; Start sector, big
		dc.b ((end-start)&$FF),((end-start)>>8&$FF)	; Filesize, little
		dc.b ((end-start)>>16&$FF),((end-start)>>24&$FF)
		dc.l end-start					; Filesize, big
		dc.b (2023-1900)+1				; Year
		dc.b 0,0,0,0,0,0				; TODO
		dc.b 2						; File flags
		dc.b 0,0
		dc.b 1,0					; Volume sequence number, little
		dc.b 0,1					; Volume sequence number, big
		dc.b 1,type
.fend:
		endm

iso_file	macro filename,start,end
.fstrt:		dc.b .fend-.fstrt				; Block size
		dc.b 0						; zero
		dc.b (start>>11&$FF),(start>>19&$FF)		; Start sector, little
		dc.b (start>>27&$FF),(start>>35&$FF)
		dc.l start>>11					; Start sector, big
		dc.b ((end-start)&$FF),((end-start)>>8&$FF)	; Filesize, little
		dc.b ((end-start)>>16&$FF),((end-start)>>24&$FF)
		dc.l end-start					; Filesize, big
		dc.b (2023-1900)+1				; Year
		dc.b 0,0,0,0,0,0				; TODO
		dc.b 0						; File flags
		dc.b 0,0
		dc.b 1,0					; Volume sequence number, little
		dc.b 0,1					; Volume sequence number, big
		dc.b .flend-.flen
.flen:		dc.b filename,";1"
.flend:		dc.b 0
.fend:
		endm

; ====================================================================
; --------------------------------------------------------
; Nikona macros
; --------------------------------------------------------

; ---------------------------------------------
; Screen mode code
; ---------------------------------------------

screen_code macro lblstart,lblend,path
	if MCD|MARSCD
		align $800		; SCD/CD32X sector align
	elseif MARS
		align 4
		phase $880000+*		; 32X ROM-area
	endif
lblstart label *
	if MARS
		dephase
	endif

mctopscrn:
	if MARS|MCD|MARSCD
		phase RAM_UserCode	; SCD/32X/CD32X relocate to RAM area
	endif
mcscrn_s:
	include path;"game/screen_0/code.asm"
mcscrn_e:
	if MARS
		dephase	; dephase RAM section
		dephase ; dephase $880000+ section
	elseif MCD|MARSCD
		dephase
		phase mctopscrn+(mcscrn_e-RAM_UserCode)
		align $800
; Md_Screen00_e:
lblend label *
	endif
	if MCD|MARS|MARSCD
		report "THIS SCREEN's code",mcscrn_e-RAM_UserCode,MAX_UserCode
	endif
	endm

; ---------------------------------------------
; 68K data bank
; ---------------------------------------------

data_bkset macro startlbl,except
	if MCD|MARSCD
		align $800
	elseif MARS
		align 4
	endif
; MCD_DBANK0:
startlbl label *
	if MCD|MARSCD
		phase sysmcd_wram
	elseif MARS
; 		dephase
	if except==-1
		phase $900000+*	; First 32X data bank
	else
		phase $900000
	endif
	endif
	endm

data_bkend macro startlbl,endlbl,thissize

	if MARS
		dephase
		if thissize > $40000
			warning "THIS BANK SIZE IS TOO LARGE FOR WORD-RAM (CD/CD32X)"
		endif
		report "THIS 68K DATA BANK at $900000",thissize,$100000
	elseif MCD|MARSCD
		dephase
		align $800
endlbl label *	; <-- CD/CD32X ONLY
		report "THIS 68K DATA BANK at WORD-RAM",thissize,$40000
	endif
	endm

; --------------------------------------------------------
; 32X ONLY
; --------------------------------------------------------

sdram_bkset macro thislbl,endlbl
	if MCD|MARSCD
		align $800
	elseif MARS
		align 4
		phase $880000+*
	endif
; MARSDATA_DEFAULT:
thislbl label *
	if MARS
		dephase
	endif
	if MARS|MARSCD
		dc.l endlbl-thislbl
		phase SH2_USER_DATA
	endif
	endm

; ---------------------------------------------

sdram_bkend macro thislbl,endlbl
	if MARS|MARSCD
		dephase
		align 8	; <-- DREQ alignment
	endif
	if MCD|MARSCD
endlbl label *
		align $800	; <-- AS failing
; 		dc.l 0
	elseif MARS
		phase $880000+*
endlbl label *
		dephase
	endif

	if MARS|MARSCD
		report "SH2 SDRAM DATA: thislbl",endlbl-thislbl,(CS3|$40000)-SH2_USER_DATA
	endif
	endm

; --------------------------------------------------------
; Set data bank(s) for the current screen
;
; mcdpos:
; 	dc.b "FILENAME.BIN",0
; 	align 2
;
; marspos:
; 	dc.l MARSDATA_DEFAULT		; 32X Cartridge point (UNUSED on CD32X)
; 	dc.b "MARSD_00.BIN",0		; CD32X Filename (UNUSED on 32X Cartridge)
; 	align 2
; --------------------------------------------------------

set_dbanks macro mcdpos,marspos
	if MARS|MARSCD
		lea	marspos(pc),a0		; 32X/CD32X: SH2 side data
		bsr	System_MarsDataPack
	endif
	if MCD|MARSCD
		bsr	System_McdSubWait
		lea	mcdpos(pc),a0		; CD/CD32X: Genesis data
		bsr	System_McdTrnsfr_WRAM
	endif
	endm

; ---------------------------------------------
; VDP color debug
; ---------------------------------------------

vdp_showme	macro color
		move.l	#$C0000000,(vdp_ctrl).l
		move.w	#color,(vdp_data).l
		endm
