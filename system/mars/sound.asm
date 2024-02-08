; ====================================================================
; ----------------------------------------------------------------
; 32X Sound (For SLAVE CPU ONLY)
;
; Playback code (the PWM interrupt) is located at cache_slv.asm
; ----------------------------------------------------------------

; --------------------------------------------------------
; Settings
; --------------------------------------------------------

SAMPLE_RATE	equ 16000;22050;22050	; 22050 best, 32000 doesn't work
MAX_PWMCHNL	equ 7

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

; 32X sound channel
		strct 0
mchnsnd_enbl	ds.l 1		; %E000 SLlr | Enable-Stereo,Loop,left,right
mchnsnd_read	ds.l 1		; READ point
mchnsnd_bank	ds.l 1		; CS1 or CS3
mchnsnd_start	ds.l 1		; Start point $00xxxxxx << 8
mchnsnd_len	ds.l 1		; Lenght << 8
mchnsnd_loop	ds.l 1		; Loop point << 8
mchnsnd_pitch	ds.l 1		; Pitch $xx.xx
mchnsnd_vol	ds.l 1		; Volume ($0000-Max)
sizeof_marssnd	ds.l 0
		endstrct

; ====================================================================
; --------------------------------------------------------
; Init Sound PWM
;
; Cycle register formulas:
; NTSC ((((23011361<<1)/SAMPLE_RATE+1)>>1)+1)
; PAL  ((((22801467<<1)/SAMPLE_RATE+1)>>1)+1)
;
; NOTE: The CLICK sound after calling this is normal.
; --------------------------------------------------------

		align 4
MarsSound_Init:
		stc	gbr,@-r15
		mov	#_sysreg,r0
		ldc	r0,gbr
		mov	#$0105,r0					; Timing interval $01, output L/R
		mov.w	r0,@(timerctl,gbr)
		mov	#((((23011361<<1)/SAMPLE_RATE+1)>>1)+1),r0	; Samplerate
		mov.w	r0,@(cycle,gbr)
		mov	#1,r0
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		ldc	@r15+,gbr
		rts
		nop
		align 4

; ====================================================================

		ltorg			; Save literals
