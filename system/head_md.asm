; ===========================================================================
; ----------------------------------------------------------------
; Genesis header
; ----------------------------------------------------------------

		dc.l RAM_Stack		; Stack point
		dc.l MD_Entry		; Entry point MUST point to $3F0
		dc.l MD_ErrBus		; Bus error
		dc.l MD_ErrAddr		; Address error
		dc.l MD_ErrIll		; ILLEGAL Instruction
		dc.l MD_ErrZDiv		; Divide by 0
		dc.l MD_ErrChk		; CHK Instruction
		dc.l MD_ErrTrapV	; TRAPV Instruction
		dc.l MD_ErrPrivl	; Privilege violation
		dc.l MD_Trace		; Trace
		dc.l MD_Line1010	; Line 1010 Emulator
		dc.l MD_Line1111	; Line 1111 Emulator
		dc.l MD_ErrorEx		; Error exception
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l RAM_MdMarsHInt	; RAM jump for HBlank (JMP xxxx xxxx)
		dc.l MD_ErrorTrap
		dc.l RAM_MdMarsVInt	; RAM jump for VBlank (JMP xxxx xxxx)
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.b "SEGA GENESIS    "
		dc.b "(C)GF64 2024.???"
		dc.b "Nikona MD                                       "
		dc.b "Nikona GENESIS                                  "
		dc.b "GM HOMEBREW-02"
		dc.w 0
		dc.b "J6M             "
		dc.l 0
		dc.l ROM_END
		dc.l $FF0000
		dc.l $FFFFFF
		dc.b "RA",$F8,$20
		dc.l $200001
		dc.l $203FFF
		align $1F0
		dc.b "JUE             "

; ====================================================================
; ----------------------------------------------------------------
; Error handlers
;
; all these do nothing currently
; ----------------------------------------------------------------

MD_ErrBus:				; Bus error
MD_ErrAddr:				; Address error
MD_ErrIll:				; ILLEGAL Instruction
MD_ErrZDiv:				; Divide by 0
MD_ErrChk:				; CHK Instruction
MD_ErrTrapV:				; TRAPV Instruction
MD_ErrPrivl:				; Privilege violation
MD_Trace:				; Trace
MD_Line1010:				; Line 1010 Emulator
MD_Line1111:				; Line 1111 Emulator
MD_ErrorEx:				; Error exception
MD_ErrorTrap:
		rte			; Return from Exception

; ====================================================================
; ----------------------------------------------------------------
; Entry point
; ----------------------------------------------------------------

MD_Entry:
	; --------------------------------
	; Check if the system has TMSS
		move	#$2700,sr			; Disable interrputs
		move.b	(sys_io).l,d0			; Read IO port
		andi.b	#%00001111,d0			; Get version, right 4 bits
		beq.s	.oldmd				; If 0, Skip this part
		move.l	($100).l,(sys_tmss).l		; Write "SEGA" to port sys_tmss
.oldmd:
		tst.w	(vdp_ctrl).l			; Test VDP to unlock Video
	; --------------------------------
		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp
		lea	($FFFF0000),a0			; Clean our "work" RAM
		move.l	#sizeof_mdram,d1
		moveq	#0,d0
.loop_ram:	move.w	d0,(a0)+
		cmp.l	d1,a0
		bcs.s	.loop_ram
		lea	(vdp_data),a6
.wait_dma:	move.w	4(a6),d7			; Check if DMA is active.
		btst	#1,d7
		bne.s	.wait_dma
		move.l	#$C0000000,4(a6)		; Clear palette
		moveq	#64-1,d7
		moveq	#0,d6
.palclear:
		move.w	d6,(a6)
		dbf	d7,.palclear
		movem.l	($FF0000),d0-a6			; Clean registers using zeros from RAM
