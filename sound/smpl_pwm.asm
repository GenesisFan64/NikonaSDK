; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona PWM instruments
;
; Located at SDRAM, SAMPLES MUST BE SMALL
;
; *** PUT align 4 AT THE TOP OF EVERY LABEL ***
; --------------------------------------------------------

	align 4
PwmIns_Nadie:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/nadie_st.wav",$2C
.end:
	align 4
PwmIns_PKick:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/wegot_kick.wav",$2C
.end:
	align 4
PwmIns_Piano:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/piano.wav",$2C
.end:
	align 4
PwmIns_PTom:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/sauron_tom.wav",$2C
.end:
