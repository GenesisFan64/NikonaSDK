; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 SDRAM section, shared for both SH2 CPUs
;
; comm port usage:
; comm0-comm7  | FREE to USE, comm2 and comm4 will get
;              | overwritten on error
; comm8-comm11 | Used by Z80 for the PWM table transfer
; comm12       | Master CPU control
; comm14       | Slave CPU control
; ----------------------------------------------------------------

		phase CS3	; Now we are at SDRAM
		cpu SH7600	; Should be SH7095 but this CPU mode works.

; ====================================================================
; ----------------------------------------------------------------
; Macros
; ----------------------------------------------------------------

cpu_me macro color
	if MARSCD=0	; <-- Doesn't work on FUSION
		mov	#color,r1
		mov	#_vdpreg,r2
		mov	#_vdpreg+bitmapmd,r3
.hblk:		mov.b	@(vdpsts,r2),r0
		tst	#HBLK,r0
		bt	.hblk
		mov.b	r1,@r3
		nop
	endif
	endm

; ====================================================================
; ----------------------------------------------------------------
; Settings
; ----------------------------------------------------------------

SH2_DEBUG	equ 0				; Set to 1 too see if CPUs are active using comm's 0 and 1
STACK_MSTR	equ $C0000800			; Master's STACK point (OLD: CS3|$40000)
STACK_SLV	equ $C0000800			; Slave's STACK point (OLD: CS3|$3F800)

; ====================================================================
; ----------------------------------------------------------------
; MASTER CPU VECTOR LIST (vbr)
; ----------------------------------------------------------------

		align 4
SH2_Master:
		dc.l SH2_M_Entry,STACK_MSTR	; Power PC, Stack
		dc.l SH2_M_Entry,STACK_MSTR	; Reset PC, Stack
		dc.l SH2_M_ErrIllg		; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_M_ErrInvl		; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_M_ErrAddr		; CPU address error
		dc.l SH2_M_ErrDma		; DMA address error
		dc.l SH2_M_ErrNmi		; NMI vector
		dc.l SH2_M_ErrUser		; User break vector
		dc.l 0,0,0,0,0,0,0,0,0		; reserved
		dc.l 0,0,0,0,0,0,0,0,0
		dc.l 0
		dc.l SH2_M_Error		; Trap user vectors
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
 		dc.l master_irq		; Level 1 IRQ
		dc.l master_irq		; Level 2 & 3 IRQ
		dc.l master_irq		; Level 4 & 5 IRQ
		dc.l master_irq		; Level 6 & 7 IRQ: PWM interupt
		dc.l master_irq		; Level 8 & 9 IRQ: Command interupt
		dc.l master_irq		; Level 10 & 11 IRQ: H Blank interupt
		dc.l master_irq		; Level 12 & 13 IRQ: V Blank interupt
		dc.l master_irq		; Level 14 & 15 IRQ: Reset Button
	; Extra ON-chip interrupts (vbr+$120)
		dc.l master_irq		; Watchdog (custom)
		dc.l master_irq		; DMA

; ====================================================================
; ----------------------------------------------------------------
; SLAVE CPU VECTOR LIST (vbr)
; ----------------------------------------------------------------

		align 4
SH2_Slave:
		dc.l SH2_S_Entry,STACK_SLV	; Cold PC,SP
		dc.l SH2_S_Entry,STACK_SLV	; Manual PC,SP
		dc.l SH2_S_ErrIllg		; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_S_ErrInvl		; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_S_ErrAddr		; CPU address error
		dc.l SH2_S_ErrDma		; DMA address error
		dc.l SH2_S_ErrNmi		; NMI vector
		dc.l SH2_S_ErrUser		; User break vector
		dc.l 0,0,0,0,0,0,0,0,0		; reserved
		dc.l 0,0,0,0,0,0,0,0,0
		dc.l 0
		dc.l SH2_S_Error		; Trap user vectors
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
 		dc.l slave_irq		; Level 1 IRQ
		dc.l slave_irq		; Level 2 & 3 IRQ
		dc.l slave_irq		; Level 4 & 5 IRQ
		dc.l slave_irq		; Level 6 & 7 IRQ: PWM interupt
		dc.l slave_irq		; Level 8 & 9 IRQ: Command interupt
		dc.l slave_irq		; Level 10 & 11 IRQ: H Blank interupt
		dc.l slave_irq		; Level 12 & 13 IRQ: V Blank interupt
		dc.l slave_irq		; Level 14 & 15 IRQ: Reset Button
	; Extra ON-chip interrupts (vbr+$120)
		dc.l slave_irq		; Watchdog
		dc.l slave_irq		; DMA

; ====================================================================
; ----------------------------------------------------------------
; IRQ on both SH2's
;
; r0-r1 are saved
; ----------------------------------------------------------------

; sr: %xxxxMQIIIIxxST

		align 4
master_irq:
		mov	r0,@-r15
		mov	r1,@-r15
		sts	pr,@-r15
		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov	r0,r1
		mov.b	#$F0,r0		; ** $F0
		extu.b	r0,r0
		ldc	r0,sr
		mova	int_m_list,r0
		add	r1,r0
		mov	@r0,r1
		jsr	@r1
		nop
		lds	@r15+,pr
		mov	@r15+,r1
		mov	@r15+,r0
		rte
		nop
		align 4

; ====================================================================

slave_irq:
		mov	r0,@-r15
		mov	r1,@-r15
		sts	pr,@-r15
		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov	r0,r1
		mov.b	#$F0,r0		; ** $F0
		extu.b	r0,r0
		ldc	r0,sr
		mova	int_s_list,r0
		add	r1,r0
		mov	@r0,r1
		jsr	@r1
		nop
		lds	@r15+,pr
		mov	@r15+,r1
		mov	@r15+,r0
		rte
		nop
		align 4

; ====================================================================
; ------------------------------------------------
; irq list
; ------------------------------------------------

		align 4

;				  		  IRQ Level:
int_m_list:
		dc.l m_irq_bad			; 0
		dc.l m_irq_bad			; 1
		dc.l m_irq_bad			; 2
		dc.l m_irq_wdg			; 3 Watchdog
		dc.l m_irq_bad			; 4
		dc.l m_irq_dma			; 5 DMA exit
		dc.l m_irq_pwm			; 6
		dc.l m_irq_pwm			; 7
		dc.l m_irq_cmd			; 8
		dc.l m_irq_cmd			; 9
		dc.l m_irq_h			; A
		dc.l m_irq_h			; B
		dc.l m_irq_v			; C
		dc.l m_irq_v			; D
		dc.l m_irq_vres			; E
		dc.l m_irq_vres			; F
int_s_list:
		dc.l s_irq_bad			; 0
		dc.l s_irq_bad			; 1
		dc.l s_irq_bad			; 2
		dc.l s_irq_wdg			; 3 Watchdog
		dc.l s_irq_bad			; 4
		dc.l s_irq_dma			; 5 DMA exit
		dc.l s_irq_pwm|$C0000000	; 6
		dc.l s_irq_pwm|$C0000000	; 7
		dc.l s_irq_cmd			; 8
		dc.l s_irq_cmd			; 9
		dc.l s_irq_h			; A
		dc.l s_irq_h			; B
		dc.l s_irq_v			; C
		dc.l s_irq_v			; D
		dc.l s_irq_vres			; E
		dc.l s_irq_vres			; F

; ====================================================================
; ----------------------------------------------------------------
; Error handler
; ----------------------------------------------------------------

; *** Only works on HARDWARE ***
;
; comm2: (CPU)(CODE)
; comm4: PC counter
;
;  CPU | The CPU who got the error:
;        $00 - Master
;        $01 - Slave
;
; CODE | Error type:
;	 $00: Unknown error
;	 $01: Illegal instruction
;	 $02: Invalid slot instruction
;	 $03: Address error
;	 $04: DMA error
;	 $05: NMI vector
;	 $06: User break

SH2_M_Error:
		bra	SH2_M_ErrCode
		mov	#0,r0
SH2_M_ErrIllg:
		bra	SH2_M_ErrCode
		mov	#1,r0
SH2_M_ErrInvl:
		bra	SH2_M_ErrCode
		mov	#2,r0
SH2_M_ErrAddr:
		bra	SH2_M_ErrCode
		mov	#3,r0
SH2_M_ErrDma:
		bra	SH2_M_ErrCode
		mov	#4,r0
SH2_M_ErrNmi:
		bra	SH2_M_ErrCode
		mov	#5,r0
SH2_M_ErrUser:
		bra	SH2_M_ErrCode
		mov	#6,r0
; r0 - value
SH2_M_ErrCode:
		mov	#_sysreg+comm2,r1
		mov.w	r0,@r1
		mov	#_sysreg+comm4,r1
		mov	@r15,r0
		mov	r0,@r1
		bra	*
		nop
		align 4

; ----------------------------------------------------

SH2_S_Error:
		bra	SH2_S_ErrCode
		mov	#0,r0
SH2_S_ErrIllg:
		bra	SH2_S_ErrCode
		mov	#-1,r0
SH2_S_ErrInvl:
		bra	SH2_S_ErrCode
		mov	#-2,r0
SH2_S_ErrAddr:
		bra	SH2_S_ErrCode
		mov	#-3,r0
SH2_S_ErrDma:
		bra	SH2_S_ErrCode
		mov	#-4,r0
SH2_S_ErrNmi:
		bra	SH2_S_ErrCode
		mov	#-5,r0
SH2_S_ErrUser:
		bra	SH2_S_ErrCode
		mov	#-6,r0
; r0 - value
SH2_S_ErrCode:
		mov	#_sysreg+comm2,r1
		mov.w	r0,@r1
		mov	#_sysreg+comm4,r1
		mov	@r15,r0
		mov	r0,@r1
		bra	*
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Interrupts
; ----------------------------------------------------------------

; =================================================================
; ------------------------------------------------
; Master | Unused interrupt
; ------------------------------------------------

		align 4
m_irq_bad:
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | Watchdog
; ------------------------------------------------

m_irq_wdg:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | DMA Exit
; ------------------------------------------------

m_irq_dma:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_DMASOURCE0,r1		; Check Channel 0
		mov	@($C,r1),r0		; Dummy READ
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)		; Transfer mode + DMA enable OFF
		mov	#_sysreg+comm12,r1	; Send signal
		mov.b	@r1,r0
		or	#%01000000,r0
		mov.b	r0,@r1
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | PWM Interrupt
; ------------------------------------------------

m_irq_pwm:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | CMD Interrupt
; ------------------------------------------------

m_irq_cmd:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1		; Clear CMD interrupt
		mov.w	r0,@r1
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	#_sysreg,r4			; r4 - sysreg base
		mov	#_DMASOURCE0,r3			; r3 - DMA base register
		mov	#_sysreg+comm12,r2		; r2 - comm to write the signal
		mov	#%0100010011100000,r0		; Transfer mode + DMA enable OFF
		mov	r0,@($C,r3)
		mov.b	@r2,r0
		and	#%1111,r0
		tst	r0,r0
		bt	.dreq_ram			; CMD mode $00
		mov	@(dreqdest,r4),r0
		mov	#CS3,r1
		bra	.dreq_setdest
		or	r1,r0
.dreq_ram:
		mov	@(marsGbl_DreqWrite,gbr),r0	; Pick current WRITE buffer
.dreq_setdest:
		mov	#TH,r1				; as Cache-thru
		or	r1,r0
		mov	r0,@(4,r3)			; Set Destination
		mov.w	@(dreqlen,r4),r0		; NOTE: NO size check
		extu.w	r0,r0
		mov	r0,@(8,r3)			; Length set by 68k
		mov	#_sysreg+dreqfifo,r1
		mov	r1,@r3				; Source point: DREQ FIFO
		mov	#%0100010011100101,r0		; Transfer mode + DMA enable + Use DMA interrupt
		mov	r0,@($C,r3)			; Dest:Incr(01) Src:Keep(00) Size:Word(01)
		mov.b	@r2,r0				; Set PASS bit to Genesis side.
		or	#%01000000,r0
		mov.b	r0,@r2
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | HBlank
; ------------------------------------------------

m_irq_h:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+hintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | VBlank
; ------------------------------------------------

m_irq_v:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+vintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt (RESET button)
; ------------------------------------------------

m_irq_vres:
		mov	#_sysreg,r1
		mov	r15,r0
		mov.w	r0,@(vresintclr,r1)
		mov	#_DMAOPERATION,r1	; Quickly cancel DMA's
		mov	#0,r0
		mov	r0,@r1
		mov	#_sysreg,r1		; If RV was active, freeze.
		mov.w	@(dreqctl,r1),r0
		tst	#1,r0
		bf	.rv_busy
		mov 	#_vdpreg,r1
		mov	#0,r0
		mov.b	r0,@(bitmapmd,r1)
		mov	#(STACK_MSTR)-8,r15	; Reset Master's STACK
		mov	#SH2_M_HotStart,r0	; Write return point and status
		mov	r0,@r15
		mov.w   #$F0,r0
		mov	r0,@(4,r15)
		mov	#_sysreg,r1		; Report Master as OK
		mov	#"M_OK",r0
		mov	r0,@(comm0,r1)
		nop
		nop
		nop
		nop
		nop
		rte
		nop
		align 4
.rv_busy:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		bra	*
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | Unused Interrupt
; ------------------------------------------------

		align 4
s_irq_bad:
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | Watchdog
; ------------------------------------------------

s_irq_wdg:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | DMA Exit
; ------------------------------------------------

		align 4
s_irq_dma:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | PWM Interrupt
; ------------------------------------------------

; located on cache/cache_slv.asm
;
; s_irq_pwm:
		ltorg	; Save literals

; =================================================================
; ------------------------------------------------
; Slave | CMD Interrupt
; ------------------------------------------------

		align 4
s_irq_cmd:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1	; Clear CMD flag
		mov.w	r0,@r1
	; --------------------------------
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		sts	pr,@-r15
		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0
		and	#%00001111,r0
		shll2	r0
		mov	r0,r1
		mova	.scmd_tasks,r0
		add	r1,r0
		mov	@r0,r1
		jmp	@r1
		nop
		align 4

; --------------------------------

.scmd_tasks:
		dc.l .scmd_task00	; <-- unused
		dc.l .scmd_task01
		dc.l .scmd_task01
		dc.l .scmd_task01

; --------------------------------
; Task $00
; --------------------------------

.scmd_task00:
		bra	.exit_scmd
		nop

; --------------------------------
; Task $01
; --------------------------------

.scmd_task01:
		mov	#_sysreg+comm8,r1		; Input
		mov	#$C0000000|RAM_Mars_PwmTable,r2	; Output
		mov	#_sysreg+comm14,r3		; comm
		nop
.wait_1:
		mov.b	@r3,r0
		and	#%11110000,r0
		tst	#%10000000,r0			; LOCK exit?
		bt	.exit_c
		tst	#%01000000,r0			; Wait PASS
		bt	.wait_1
.copy_1:
		mov	@r1,r0				; Copy entire LONG
		mov	r0,@r2
		add	#4,r2				; Increment table pos
		mov.b	@r3,r0
		and	#%10111111,r0
		bra	.wait_1
		mov.b	r0,@r3				; Clear PASS bit, Z80 loops
.exit_c:

; --------------------------------
; Process changes

.proc_pwm:
		mov	#$C0000000|RAM_Mars_PwmTable,r8	; Input
		mov	#$C0000000|RAM_Mars_PwmList,r7	; Output
		mov	#MAX_PWMCHNL,r6
.next_chnl:
		mov	r8,r3				; r3 - current table column
		mov.b	@r3,r0				; r0: %kfo o-on f-off k-cut
		and	#%00011111,r0
		tst	r0,r0
		bt	.no_chng
.no_keycut:
		tst	#%00000010,r0
		bf	.is_keycut
		tst	#%00000100,r0
		bf	.is_keycut
		tst	#%00000001,r0
		bt	.no_chng
		tst	#%00001000,r0
		bt	.no_pitchbnd

	; copypasted
		mov	@(mchnsnd_enbl,r7),r0
		tst	#$80,r0
		bt	.no_chng
; 		mov	#0,r0
; 		mov	r0,@(mchnsnd_enbl,r7)
		add	#8,r3			; Next: Volume and Pitch MSB
		mov.b	@r3,r0			; r0: %vvvvvvpp
		mov	r0,r2			; Save pp-pitch
		and	#%11111100,r0
		mov	r0,@(mchnsnd_vol,r7)
		add	#8,r3			; Next: Pitch LSB
		mov.b	@r3,r1			; r0: %pppppppp
		extu.b	r1,r1
		mov	r2,r0
		and	#%11,r0
		shll8	r0
		or	r1,r0
		bra	.no_chng
		mov	r0,@(mchnsnd_pitch,r7)

.no_pitchbnd:
		mov	#0,r0
		mov	r0,@(mchnsnd_enbl,r7)
		add	#8,r3			; Next: Volume and Pitch MSB
		mov.b	@r3,r0			; r0: %vvvvvvpp
		mov	r0,r2			; Save pp-pitch
		and	#%11111100,r0
		mov	r0,@(mchnsnd_vol,r7)
		add	#8,r3			; Next: Pitch LSB
		mov.b	@r3,r1			; r0: %pppppppp
		extu.b	r1,r1
		mov	r2,r0
		and	#%11,r0
		shll8	r0
		or	r1,r0
		mov	r0,@(mchnsnd_pitch,r7)
		add	#8,r3			; Next: Stereo/Loop/Left/Right | 32-bit**
		mov.b	@r3,r0			; r0: %SLlraaaa
		mov	r0,r1			; Save aaaa-address
		and	#%11110000,r0
		shlr2	r0
		shlr2	r0
		or	#$80,r0			; Set as Enabled
		mov	r0,r4
		mov	r1,r0
		and	#%00001111,r0
		shll16	r0
		shll8	r0
		mov	r0,@(mchnsnd_bank,r7)
		mov	r0,r1			; r1 - BANK
		add	#8,r3			; Next: Pointer $xx0000
		mov.b	@r3,r0
		extu.b	r0,r0
		shll16	r0
		mov	r0,r2			; r2: $xx0000
		add	#8,r3			; Next: Pointer $00xx00
		mov.b	@r3,r0
		extu.b	r0,r0
		shll8	r0
		or	r0,r2			; r2: $xxxx00
		add	#8,r3			; Next: Pointer $0000xx
		mov.b	@r3,r0
		extu.b	r0,r0
		or	r2,r0			; r0: $00xxxxxx
		add	r0,r1
	; Read LEN and LOOP
		mov.b	@r1+,r0
		extu.b	r0,r3
		mov.b	@r1+,r2
		extu.b	r2,r2
		shll8	r2
		or	r2,r3
		mov.b	@r1+,r2
		extu.b	r2,r2
		shll16	r2
		or	r2,r3
		mov.b	@r1+,r0
		extu.b	r0,r0
		mov.b	@r1+,r2
		extu.b	r2,r2
		shll8	r2
		or	r2,r0
		mov.b	@r1+,r2
		extu.b	r2,r2
		shll16	r2
		or	r2,r0
		shll8	r0
		mov	r0,@(mchnsnd_loop,r7)
		mov	r1,r0
		shll8	r0
		mov	r0,@(mchnsnd_start,r7)
		mov	r0,@(mchnsnd_read,r7)
		mov	r1,r0
		add	r3,r0
		shll8	r0
		mov	r0,@(mchnsnd_len,r7)
		bra	.no_chng
		mov	r4,@(mchnsnd_enbl,r7)
.is_keycut:
		mov	#0,r0
		mov	r0,@(mchnsnd_enbl,r7)
.no_chng:
; 		add	#$40,r6
		mov	#sizeof_marssnd,r0
		add	r0,r7
		dt	r6
		bf/s	.next_chnl
		add	#1,r8
.exit_scmd:
	; --------------------------------
		mov	#_sysreg+comm14,r1	; Clear cmd number
		mov	#0,r0
		mov.b	r0,@r1
		lds	@r15+,pr
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | HBlank
; ------------------------------------------------

s_irq_h:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+hintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | VBlank
; ------------------------------------------------

s_irq_v:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+vintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | VRES Interrupt (RESET button on Genesis)
; ------------------------------------------------

s_irq_vres:
		mov	#_sysreg,r1
		mov	r15,r0
		mov.w	r0,@(vresintclr,r1)
		mov	#_DMAOPERATION,r1	; Quickly cancel DMA's
		mov	#0,r0
		mov	r0,@r1
		mov	#_sysreg,r1		; If RV was active, freeze.
		mov.w	@(dreqctl,r1),r0
		tst	#1,r0
		bf	.rv_busy
		mov	#(STACK_SLV)-8,r15	; Reset Slave's STACK
		mov	#SH2_S_HotStart,r0	; Write return point and status
		mov	r0,@r15
		mov.w   #$F0,r0
		mov	r0,@(4,r15)
		mov	#_sysreg,r1
		mov	#"S_OK",r0		; Report Slave as OK
		mov	r0,@(comm4,r1)
		nop
		nop
		nop
		nop
		nop
		rte
		nop
		align 4
.rv_busy:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		bra	*
		nop
		align 4

		ltorg		; Save literals

; ====================================================================
; ----------------------------------------------------------------
; Master entry point
; ----------------------------------------------------------------

		align 4
SH2_M_Entry:
		mov	#STACK_MSTR,r15			; Reset stack
		mov	#SH2_Master,r0			; Reset vbr
		ldc	r0,vbr
		mov.l	#_FRT,r1
		mov	#0,r0
		mov.b	r0,@(0,r1)
		mov.b	#$E2,r0
		mov.b	r0,@(7,r1)
		mov	#0,r0
		mov.b	r0,@(4,r1)
		mov	#1,r0
		mov.b	r0,@(5,r1)
		mov	#0,r0
		mov.b	r0,@(6,r1)
		mov	#1,r0
		mov.b	r0,@(1,r1)
		mov	#0,r0
		mov.b	r0,@(3,r1)
		mov.b	r0,@(2,r1)
; 		mov.b	#$F2,r0				; <-- not needed here
; 		mov.b	r0,@(7,r1)
; 		mov	#0,r0
; 		mov.b	r0,@(4,r1)
; 		mov	#1,r0
; 		mov.b	r0,@(5,r1)
; 		mov.b	#$E2,r0
; 		mov.b	r0,@(7,r1)

	; --------------------------------------------------------
	; Extra interrupt settings
		mov.w   #$FEE2,r0			; Extra interrupt priority levels ($FFFFFEE2)
		mov     #(3<<4)|(5<<8),r1		; (DMA_LVL<<8)|(WDG_LVL<<4) Current: WDG 3 DMA 5
		mov.w   r1,@r0
		mov.w   #$FEE4,r0			; Vector jump number for Watchdog ($FFFFFEE4)
		mov     #($120/4)<<8,r1			; (vbr+POINTER)<<8
		mov.w   r1,@r0
		mov.b	#$A0,r0				; Vector jump number for DMACHANNEL0 ($FFFFFFA0)
		mov     #($124/4),r1			; (vbr+POINTER)
		mov	r1,@r0
		mov	#RAM_Mars_Global,r0		; Reset gbr
		ldc	r0,gbr

	; --------------------------------------------------------
	; CD32X initialization
	;
	; *** FUSION: Framebuffer flipping fails if
	; bitmapmd is 0
	; --------------------------------------------------------

	if MARSCD
	if EMU
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
		mov.b	r0,@(framectl,r1)
.waitl:		mov.b	@(vdpsts,r1),r0
		tst	#VBLK,r0
		bt	.waitl
.wait_frm:	mov.b	@(framectl,r1),r0
		cmp/eq	#1,r0
		bf	.wait_frm
	else
		mov 	#_vdpreg,r1
.waite:		mov.b	@(vdpsts,r1),r0		; Wait VBlank
		tst	#VBLK,r0
		bf	.waite
.waitl:		mov.b	@(vdpsts,r1),r0
		tst	#VBLK,r0
		bt	.waitl
		mov	#1,r2			; Set Framebuffer 1
		mov	r2,r0
		mov.b	r0,@(framectl,r1)
.wait_frm:	mov.b	@(framectl,r1),r0
		cmp/eq	r2,r0
		bf	.wait_frm
	endif
		mov	#0,r0
		mov	#CS3+($20000-$38),r2	; Cleanup FIRST
		mov	#CS3+($40000),r3
.clean_up:
		cmp/ge	r3,r2
		bt	.exit_clean
		mov	r0,@r2
		bra	.clean_up
		add	#4,r2
.exit_clean:
		mov	#_framebuffer,r1	; Copy the other half of SDRAM
		mov	#CS3+($20000-$38),r2
		mov	#CS3+(SH2_END&$3FFFFF),r3
.copy_new:
		cmp/ge	r3,r2
		bt	.exit_send
		mov	@r1+,r0
		mov	r0,@r2
		bra	.copy_new
		add	#4,r2
.exit_send:
		mov	#_sysreg+comm0,r1
		mov	#0,r0
		mov	r0,@r1
	endif
		mov	#RAM_Mars_DreqBuff_0,r0
		mov	r0,@(marsGbl_DreqRead,gbr)
		mov	#RAM_Mars_DreqBuff_1,r0
		mov	r0,@(marsGbl_DreqWrite,gbr)

; ====================================================================
; ----------------------------------------------------------------
; Master MAIN code
; ----------------------------------------------------------------

SH2_M_HotStart:
		mov.b	#$F0,r0			; ** $F0
		extu.b	r0,r0
		ldc	r0,sr
		mov.w	#$FE80,r1		; $FFFFFE80
		mov.w	#$A518,r0		; Disable Watchdog
		mov.w	r0,@r1
		bsr	Mars_CachePurge
		nop
		bsr	MarsVideo_Init
		nop
		mov	#_sysreg,r1
		mov.w	@r1,r0
		or	#CMDIRQ_ON,r0
		mov.w	r0,@r1
		mov	#_sysreg+comm14,r1
.wait_slv:	mov.w	@r1,r0
		tst	r0,r0
		bf	.wait_slv
		mov	#_DMAOPERATION,r1		; Enable DMA operation
		mov	#1,r0
		mov	r0,@r1
		mov.b	#$20,r0				; Interrupts ON
		ldc	r0,sr
		bra	master_loop
		nop
		align 4
litr_MarsVideo_Init:
		dc.l MarsVideo_Init
		ltorg
		align 4

; ----------------------------------------------------------------
; MASTER CPU loop
;
; comm12: %BS00ccccRF00mmmm

; B | BUSY signal for CMD (TODO)
; S | SIGNAL-status bits for CMD, clears only
; F | Frame-ready flag, clears when frame is ready.
; c | CMD task number
; R | Graphics mode INIT flag
; m | Pseudo-Graphics mode
; ----------------------------------------------------------------

		align 4
master_loop:
	if SH2_DEBUG
		mov	#_sysreg+comm0,r1		; DEBUG counter
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1
	endif

	; ---------------------------------------
	; Flip the DREQ Read/Write points
	; ---------------------------------------
		mov	#_vdpreg,r1			; Check if we got late
.waitl:		mov.b	@(vdpsts,r1),r0			; on VBlank
		tst	#VBLK,r0
		bf	.waitl
		stc	sr,@-r15
		mov.b	#$F0,r0				; ** $F0
		extu.b	r0,r0
		ldc	r0,sr
		bsr	Mars_CachePurge			; Purge cache
		nop
		mov	@(marsGbl_DreqWrite,gbr),r0	; Flip DMA Read/Write buffers
		mov	r0,r1
		mov	@(marsGbl_DreqRead,gbr),r0
		mov	r0,@(marsGbl_DreqWrite,gbr)
		mov	r1,r0
		mov	r0,@(marsGbl_DreqRead,gbr)
		mov	#_sysreg+comm12+1,r1		; Reset FrameWait bit from 68K
		mov.b	@r1,r0
		and	#%10111111,r0
		mov.b	r0,@r1
		ldc	@r15+,sr

	; ---------------------------------------
	; Write palette using DREQ data
	; ---------------------------------------
		mov	#_vdpreg,r1			; Wait until VBlank
.waitv:		mov.b	@(vdpsts,r1),r0
		tst	#VBLK,r0
		bt	.waitv
		mov	#_vdpreg,r1
		mov.w	@(marsGbl_ThisFrame,gbr),r0	; Set current framebuffer
		and	#1,r0
		mov.b	r0,@(framectl,r1)
 		mov.w	@(marsGbl_XShift,gbr),r0	; Set SHIFT bit (Xpos & 1)
		and	#1,r0
		mov.w	r0,@(shift,r1)
		mov	@(marsGbl_DreqRead,gbr),r0
; 		mov	#Dreq_Palette,r1		; PALETTE MUST BE AT THE TOP OF DREQ DATA
; 		add	r0,r1				; so I don't need to add Dreq_Palette...
		mov	r0,r1
		mov	#_palette,r2
 		mov	#(256/8),r3
.copy_pal:
	rept 8/2
		mov	@r1+,r0				; Copy 2 colors as LONGs
		mov	r0,@r2
		add	#4,r2
	endm
		dt	r3
		bf	.copy_pal
.not_ready:
		mov	#_sysreg+comm12,r1
		mov.w	@r1,r0
		mov	#mstr_list,r1
		tst	#$80,r0
		bt	.non_init
		add	#4,r1
.non_init:
		and	#%00001111,r0		; <-- Current limit
		shll2	r0
		shll	r0
		add	r0,r1
		mov	@r1,r0
		jmp	@r0
		nop
		align 4
mstr_list:
		dc.l MstrMode_0,MstrMode_0_i
		dc.l MstrMode_2D,MstrMode_2D_i

; ====================================================================
; ----------------------------------------------------------------
; NOTHING
; ----------------------------------------------------------------

		align 4
MstrMode_0_i:
		mov 	#_vdpreg,r1
		mov	#0,r0
		mov.b	r0,@(bitmapmd,r1)
		nop
		mov	#_sysreg+comm12+1,r1
		mov.b	@r1,r0
		and	#$7F,r0
		mov.b	r0,@r1
MstrMode_0:
		mov	#_vdpreg,r1
.waitl:		mov.b	@(vdpsts,r1),r0
		tst	#VBLK,r0
		bf	.waitl

		bra	master_loop
		nop

; ====================================================================
; ----------------------------------------------------------------
; 256-color tiled scrolling layer with "Super" Sprites
;
; NOTES:
; - STOP SCROLLING FIRST
; - MAXIMUM scrolling speed is 8 pixels for both axis
; ----------------------------------------------------------------

		align 4

; ---------------------------------------
; Init
; ---------------------------------------

MstrMode_2D_i:
		mov	#CACHE_MASTER,r1
		mov	#CACHE_MASTER_E-CACHE_MASTER,r2
		mov	#Mars_CacheRamCode,r0
		jsr	@r0
		nop
		mov	#Dreq_ScrlBuff,r14
		mov	@(marsGbl_DreqRead,gbr),r0
		add	r0,r14
		mov	@(mscrl_xpos,r14),r1
		shlr16	r1
		mov	@(mscrl_ypos,r14),r2
		shlr16	r2
		mov	@(mscrl_Art,r14),r0
		mov 	#_vdpreg,r3
		mov	r0,@(marsGbl_Scrl_Art,gbr)
		exts.w	r2,r0
		mov	r0,@(marsGbl_Scrl_Ypos,gbr)
		exts.w	r1,r0
		mov	r0,@(marsGbl_Scrl_Xpos,gbr)
		mov	#2,r0
		mov	r0,@(marsGbl_Scrl_DrwAll,gbr)
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r3)
		mov	#_sysreg+comm12+1,r1
		mov.b	@r1,r0
		and	#$7F,r0
		bra	MstrMode_2D
		mov.b	r0,@r1
		align 4
		ltorg

; ---------------------------------------
; Loop
; ---------------------------------------

		align 4
MstrMode_2D:
	; ---------------------------------------
	; Set scrolling varaibles
		mov	@(marsGbl_DreqRead,gbr),r0
		mov	#Dreq_ScrlBuff,r14
		add	r0,r14
		mov	#0,r1				; X increment
		mov	#0,r2				; Y increment
		mov	#2,r3				; Drawflags counter
		mov	@(mscrl_xpos,r14),r6
		mov	#SET_MSCRLSIZE/2,r4		; Scroll speed limit
		mov	@(marsGbl_Scrl_Xpos,gbr),r0
		mov	#-SET_MSCRLSIZE,r5		; -block_size
		mov	@(mscrl_ypos,r14),r8
		mov	r0,r7
		mov	@(marsGbl_Scrl_Ypos,gbr),r0
		mov	r0,r9
		shlr16	r6			; X >> 16
		exts.w	r6,r6			; extend
		cmp/eq	r7,r6			; Xpos == Xold?
		bt	.x_old
		mov	r6,r1			; Make X increment
		sub	r7,r1

		mov	r6,r0			; Check X&blocksize
		and	r5,r0
		and	r5,r7
		cmp/eq	r7,r0
		bt	.x_old
		cmp/pz	r1
		bf	.x_dirl
		nop
		mov	@(marsGbl_Scrl_DrwR,gbr),r0
		tst	r0,r0
		bf	.x_new
		mov	#0,r0
		mov	r0,@(marsGbl_Scrl_DrwL,gbr)
		mov	r3,r0
		mov	r0,@(marsGbl_Scrl_DrwR,gbr)
		bra	.x_new
		nop
		nop ; align
.x_dirl:
		mov	@(marsGbl_Scrl_DrwL,gbr),r0
		tst	r0,r0
		bf	.x_new
		mov	#0,r0
		mov	r0,@(marsGbl_Scrl_DrwR,gbr)
		mov	r3,r0
		mov	r0,@(marsGbl_Scrl_DrwL,gbr)
.x_new:
.x_old:
		shlr16	r8				; Y >> 16
		exts.w	r8,r8				; extend
		cmp/eq	r9,r8				; Ypos == Yold?
		bt	.y_old
		mov	r8,r2				; Make Y increment
		sub	r9,r2

		mov	r8,r0				; Check Y&blocksize
		and	r5,r0
		and	r5,r9
		cmp/eq	r9,r0
		bt	.y_old
		cmp/pl	r2
		bf	.y_dirl
		mov	@(marsGbl_Scrl_DrwD,gbr),r0
		tst	r0,r0
		bf	.y_new
		mov	#0,r0
		mov	r0,@(marsGbl_Scrl_DrwU,gbr)
		mov	r3,r0
		mov	r0,@(marsGbl_Scrl_DrwD,gbr)
		bra	.y_new
		nop
		nop ; align
.y_dirl:
		mov	@(marsGbl_Scrl_DrwU,gbr),r0
		tst	r0,r0
		bf	.y_new
		mov	#0,r0
		mov	r0,@(marsGbl_Scrl_DrwD,gbr)
		mov	r3,r0
		mov	r0,@(marsGbl_Scrl_DrwU,gbr)
.y_new:

.y_old:
		mov	r8,r0
		mov	r0,@(marsGbl_Scrl_Ypos,gbr)
; 		mov	r8,r0
; 		mov	r0,@(marsGbl_Scrl_Yold,gbr)	; Update Yold
; 		mov	r6,r0
; 		mov	r0,@(marsGbl_Scrl_Xold,gbr)	; Update Xold
		mov	r6,r0
		mov	r0,@(marsGbl_Scrl_Xpos,gbr)
		exts.w	r1,r1
		mov.w	r0,@(marsGbl_XShift,gbr)	; Write Xshift here
		exts.w	r2,r2

	; ---------------------------------------
	; Increment FB draw TL and Y pos
	; r1 - X increment
	; r2 - Y increment
		mov	@(marsGbl_Scrl_Hght,gbr),r0
		mov	r0,r6
		mov	@(marsGbl_Scrl_FbY,gbr),r0
		mov	r0,r5
		mov	@(marsGbl_Scrl_Size,gbr),r0
		mov	r0,r4
		mov	@(marsGbl_Scrl_FbTL,gbr),r0
		add	r1,r0		; Add X
		cmp/pl	r1
		bf	.yx_negtv
		cmp/ge	r4,r0
		bf	.yx_negtv
		sub	r4,r0
.yx_negtv:
		cmp/pz	r1
		bt	.yx_postv
		cmp/pz	r0
		bt	.yx_postv
		add	r4,r0
.yx_postv:
		add	r2,r5		; Add Y
		cmp/pl	r2
		bf	.ypu_negtv
		cmp/ge	r6,r5
		bf	.ypu_negtv
		sub	r6,r5
.ypu_negtv:
		cmp/pz	r2
		bt	.ypu_postv
		cmp/pz	r5
		bt	.ypu_postv
		add	r6,r5
.ypu_postv:
		nop
		mov	r0,@(marsGbl_Scrl_FbTL,gbr)
		mov	r5,r0
		mov	r0,@(marsGbl_Scrl_FbY,gbr)
	; ---------------------------------------
	; DRAW the blocks now
	; ---------------------------------------
; 	cpu_me 2
; 		mov	#_sysreg+comm14+1,r1		; Pre-draw the Super Sprites
; .wait_slv_i:	mov.b	@r1,r0				; using Slave SH2
; 		tst	r0,r0
; 		bf	.wait_slv_i
; 		mov	#1,r0				; Slave task $01
; 		mov.b	r0,@r1
		mov	#_framebuffer,r14
		mov	@(marsGbl_Scrl_Size,gbr),r0
		mov	r0,r13
		mov	@(marsGbl_Scrl_Hght,gbr),r0
		mov	r0,r12
		mov	@(marsGbl_Scrl_Wdth,gbr),r0
		mov	r0,r11
		mov	@(marsGbl_Scrl_FbTL,gbr),r0
		mov	r0,r10
		mov	@(marsGbl_Scrl_FbY,gbr),r0
		mov	r0,r9
		mov	@(marsGbl_Scrl_Art,gbr),r0
		mov	r0,r8
		mov	@(marsGbl_Scrl_Ypos,gbr),r0
		mov	r0,r6
		mov	@(marsGbl_Scrl_Xpos,gbr),r0
		mov	r0,r5
		mov	@(marsGbl_Scrl_FbOut,gbr),r0
		add	r0,r14
		mov	@(marsGbl_DreqRead,gbr),r0
		mov	#Dreq_ScrlData,r7
		add	r0,r7
		mov	#-SET_MSCRLSIZE,r0	; -MSCRL_BLKSIZE
		and	r0,r10			; Set FB top-left
		and	r0,r9
		mov	@(marsGbl_Scrl_DrwAll,gbr),r0
		tst	r0,r0
		bt	.clr_init
		dt	r0
		mov	r0,@(marsGbl_Scrl_DrwAll,gbr)
		bsr	MarsVideo_MapDrawAll
		nop
		bra	.from_full
		nop
.clr_init:
 		bsr	Mars_CachePurge
		nop
		bsr	MarsVideo_DrawFillBlk		; Redraw from refill boxes
		nop
 		bsr	MarsVideo_MapScrlUD
		nop
		bsr	MarsVideo_MapScrlLR
		nop
.from_full:
		bsr	Mars_CachePurge
		nop
		bsr	MarsVideo_SuperSpr_Draw
		nop
; 	cpu_me 1
		mov	#0,r1
		mov	#240,r2				; Show scroll area 0 to 240
		bsr	MarsVideo_ShowScrlBg
		nop
		bsr	MarsVideo_MkFillBlk		; Build refill boxes
		nop
; 		mov	#_sysreg+comm14+1,r1
; .wait_slv_e:	mov.b	@r1,r0
; 		tst	r0,r0
; 		bf	.wait_slv_e
		bsr	marsScrl_CopyTopBot
		nop
		mov	#240,r2				; $xxFF patcher
		mov	#FBVRAM_PATCH,r3
		bsr	MarsVideo_FixTblShift
		mov	#0,r1

	; ---------------------------------------
	; Make the scroll area visible and
	; fix the broken lines.
 		nop
		mov.w	@(marsGbl_ThisFrame,gbr),r0
		xor	#1,r0
		mov.w	r0,@(marsGbl_ThisFrame,gbr)
		bra	master_loop
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Slave entry point
; ----------------------------------------------------------------

		align 4
SH2_S_Entry:
		mov	#STACK_SLV,r15		; Reset stack
		mov	#SH2_Slave,r0		; Reset vbr
		ldc	r0,vbr
		mov.l	#_FRT,r1		; Free-run timer settings
		mov	#0,r0			; ** REQUIRED FOR REAL HARDWARE **
		mov.b	r0,@(0,r1)
		mov.b	#$E2,r0
		mov.b	r0,@(7,r1)
		mov	#0,r0
		mov.b	r0,@(4,r1)
		mov	#1,r0
		mov.b	r0,@(5,r1)
		mov	#0,r0
		mov.b	r0,@(6,r1)
		mov	#1,r0
		mov.b	r0,@(1,r1)
		mov	#0,r0
		mov.b	r0,@(3,r1)
		mov.b	r0,@(2,r1)
		mov.b	#$F2,r0			; <-- PWM interrupt needs this
		mov.b	r0,@(7,r1)
		mov	#0,r0
		mov.b	r0,@(4,r1)
		mov	#1,r0
		mov.b	r0,@(5,r1)
		mov.b	#$E2,r0
		mov.b	r0,@(7,r1)		; <-- ***

	; --------------------------------------------------------
	; Extra interrupt settings
		mov.w   #$FEE2,r0		; Extra interrupt priority levels ($FFFFFEE2)
		mov     #(3<<4)|(5<<8),r1	; (DMA_LVL<<8)|(WDG_LVL<<4) Current: WDG 3 DMA 5
		mov.w   r1,@r0
		mov.w   #$FEE4,r0		; Vector jump number for Watchdog ($FFFFFEE4)
		mov     #($120/4)<<8,r1		; (vbr+POINTER)<<8
		mov.w   r1,@r0
		mov.b	#$A8,r0			; Vector jump number for DMACHANNEL1 ($FFFFFFA8)
		mov     #($124/4),r1		; (vbr+POINTER)
		mov	r1,@r0
		mov	#RAM_Mars_Global,r0	; Reset gbr
		ldc	r0,gbr

	; --------------------------------------------------------
	; CD32X
	; --------------------------------------------------------
	if MARSCD
		mov	#_sysreg+comm0,r1
.wait_mstr:	mov	@r1,r0
		tst	r0,r0
		bf	.wait_mstr
		add	#4,r1
		mov	#0,r0			; clear comm4
		mov	r0,@r1
	endif
		bsr	MarsSound_Init		; Init sound
		nop

; ====================================================================
; ----------------------------------------------------------------
; Slave MAIN code
; ----------------------------------------------------------------

SH2_S_HotStart:
		mov.b	#$F0,r0			; ** $F0
		extu.b	r0,r0
		ldc	r0,sr
		mov.w	#$FE80,r1		; $FFFFFE80
		mov.w	#$A518,r0		; Disable Watchdog
		mov.w	r0,@r1
		bsr	Mars_CachePurge
		nop
		mov	#CACHE_SLAVE,r1
		mov	#CACHE_SLAVE_E-CACHE_SLAVE,r2
		mov	#Mars_CacheRamCode,r0
		jsr	@r0
		nop
		mov	#_sysreg,r1
		mov.w	@r1,r0
		or	#CMDIRQ_ON|PWMIRQ_ON,r0		; Enable these interrupts
		mov.w	r0,@r1
		mov	#_sysreg+comm12,r1
.wait_mst:	mov.w	@r1,r0
		tst	r0,r0
		bf	.wait_mst
		mov	#_DMAOPERATION,r1		; Enable DMA operation
		mov	#1,r0
		mov	r0,@r1
		mov.b	#$20,r0				; Interrupts ON
		ldc	r0,sr
		mov	#slave_loop,r0
		jmp	@r0
		nop
		align 4
		ltorg

; ----------------------------------------------------------------
; SLAVE CPU loop
; ----------------------------------------------------------------

		align 4
slave_loop:
	if SH2_DEBUG
		mov	#_sysreg+comm1,r1		; DEBUG counter
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1
	endif
		mov	#_sysreg+comm14,r1		; Frame-ready bitclear
		mov.w	@r1,r0
		mov	slv_list,r1
		and	#$7F,r0
		shll2	r0
		add	r0,r1
		mov	@r1,r0
		jmp	@r0
		nop
		align 4

; ====================================================================

slv_list:
		dc.l SlvMode_00
		dc.l SlvMode_01

; ====================================================================
; ----------------------------------------------------------------
; NOTHING
; ----------------------------------------------------------------

SlvMode_00:
		bra	slave_loop
		nop

; ====================================================================
; ----------------------------------------------------------------
; Slave mode 01
; ----------------------------------------------------------------

		align 4
SlvMode_01:
		bsr	Mars_CachePurge
		nop
		mov	#_sysreg+comm14+1,r1
		mov	#0,r0
		mov.b	r0,@r1
		bra	slave_loop
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Shared routines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Mars_CachePurge
;
; Purges the internal cache, call this often.
;
; Breaks:
; r0-r1
; --------------------------------------------------------

		align 4
Mars_CachePurge:
		mov.w	#_CCR&$FFFF,r1		; Purge ON, Cache OFF
		mov	#%10000,r0
		mov.b	r0,@r1
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		mov	#%01001,r0		; Purge OFF, Two-Way mode, Cache ON
		rts
		mov.b	r0,@r1

; --------------------------------------------------------
; Mars_ClearCacheCode
;
; Clear the entire "fast code" section for the
; current CPU
;
; Breaks:
; r0-r2
; --------------------------------------------------------

		align 4
Mars_ClearCacheCode:
		mov.l	#$C0000000+$800,r1
		mov	#0,r0
		mov.w	#$80,r2
.loop:
		mov	r0,@-r1
		mov	r0,@-r1
		mov	r0,@-r1
		mov	r0,@-r1
		dt	r2
		bf	.loop
		rts
		nop
		align 4

; ----------------------------------------------------------------
; Mars_CacheRamCode
;
; Loads "fast code" into the SH2's cache, maximum size is
; $700 bytes aprox.
;
; Input:
; r1 | Code to send
; r2 | Size
;
; Breaks:
; r0/r3
; ----------------------------------------------------------------

		align 4
Mars_CacheRamCode:
		stc	sr,@-r15	; Interrupts OFF
		mov.b	#$F0,r0		; ** $F0
		extu.b	r0,r0
		ldc	r0,sr
		mov	#_CCR,r3
		mov	#%00010000,r0	; Cache purge + Disable
		mov.w	r0,@r3
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		mov	#%00001001,r0	; Cache two-way mode + Enable
		mov.w	r0,@r3
		mov 	#$C0000000,r3
		shlr2	r2
.copy:
		mov 	@r1+,r0
		mov 	r0,@r3
		dt	r2
		bf/s	.copy
		add 	#4,r3
		rts
		ldc	@r15+,sr
		align 4
		ltorg

; --------------------------------------------------------
; Mars_SetWatchdog
;
; Prepares watchdog interrupt
;
; Input:
; r1 | Watchdog CPU clock divider
; r2 | Watchdog Pre-timer
; --------------------------------------------------------

		align 4
Mars_SetWatchdog:
		stc	sr,r4
		mov.b	#$F0,r0			; ** $F0
		extu.b	r0,r0
		ldc 	r0,sr
		mov.l	#_CCR,r3		; Refresh Cache
		mov	#%00001000,r0		; Two-way mode
		mov.w	r0,@r3
		mov	#%00011001,r0		; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r3
		mov.w	#$FE80,r3		; $FFFFFE80
		mov.w	#$5A00,r0		; Watchdog pre-timer
		or	r2,r0
		mov.w	r0,@r3
		mov.w	#$A538,r0		; Enable Watchdog
		or	r1,r0
		mov.w	r0,@r3
		ldc	r4,sr
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

		align 4
		include "system/mars/sound.asm"
		include "system/mars/video.asm"
		include "system/mars/cache/cache_mstr.asm"
		include "system/mars/cache/cache_slv.asm"

; ====================================================================
; ----------------------------------------------------------------
; GLOBAL GBR Variables
;
; SHARED FOR BOTH CPUS, watch out for the Read/Write conflicts.
; ----------------------------------------------------------------

			align $10
RAM_Mars_Global:
			strct 0
marsGbl_XShift		dc.w 0					; **** Xscroll bit for indexed scrolling
marsGbl_ThisFrame	dc.w 0
marsGbl_SSprFlip	dc.w 0
marsGbl_FreeW1		dc.w 0
marsGbl_DreqRead	dc.l 0					; **** RAM_Mars_DreqBuff_0|TH
marsGbl_DreqWrite	dc.l 0					; RAM_Mars_DreqBuff_1|TH
marsGbl_Scrl_Xpos	dc.l 0					; ****
marsGbl_Scrl_Ypos	dc.l 0
marsGbl_Scrl_FREE0	dc.l 0
marsGbl_Scrl_FREE1	dc.l 0
marsGbl_Scrl_FbTL	dc.l 0					; ****
marsGbl_Scrl_FbY	dc.l 0
marsGbl_Scrl_Art	dc.l 0
marsGbl_Scrl_DrwAll	dc.l 0
marsGbl_Scrl_DrwR	dc.l 0					; ****
marsGbl_Scrl_DrwL	dc.l 0
marsGbl_Scrl_DrwD	dc.l 0
marsGbl_Scrl_DrwU	dc.l 0
marsGbl_Scrl_Size	dc.l 0					; ****
marsGbl_Scrl_Wdth	dc.l 0
marsGbl_Scrl_Hght	dc.l 0
marsGbl_Scrl_FbOut	dc.l 0
sizeof_MarsGbl		dc.l 0
			endstrct
			ds.b sizeof_MarsGbl

; ====================================================================
; ----------------------------------------------------------------
; CACHED RAM
; ----------------------------------------------------------------

			align $10
SH2_RAM:
			phase SH2_RAM
RAM_Mars_ScrlRefill_0	ds.w (512/SET_MSCRLSIZE)*(256/SET_MSCRLSIZE)	; Redraw blk timers (WORDS)
			dephase

; ====================================================================
; ----------------------------------------------------------------
; NON-CACHED RAM
; ----------------------------------------------------------------

			align $10
SH2_RAM_TH:
			phase SH2_RAM_TH|TH
RAM_Mars_DreqBuff_0	ds.b sizeof_dreq			; DREQ data from Genesis
RAM_Mars_DreqBuff_1	ds.b sizeof_dreq			; ****
			dephase

		report "SH2 code uses",*-SH2_Master,-1

; ====================================================================
; ----------------------------------------------------------------
; Data
; ----------------------------------------------------------------

		align 4
sin_table	binclude "system/mars/data/sinedata.bin"
		align 4
		include "sound/smpl_pwm.asm"		; GEMA: PWM samples

; ====================================================================
; ----------------------------------------------------------------
; Data
; ----------------------------------------------------------------

		align $10
SH2_END:
		report "All SH2 SDRAM uses",SH2_END&$FFFFFF,-1

; ====================================================================
; ----------------------------------------------------------------
; USER data pointer
; ----------------------------------------------------------------


SH2_USER_DATA:
		cpu 68000
		padding off
		dephase
		phase (SH2_END-SH2_Master)+MARS_RAMCODE
		align 4
