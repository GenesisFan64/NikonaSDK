; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona DAC instruments
;
; This must be located at the 68k's 900000 area.
; ** 68K BANK 0 only **
;
; BASE Samplerate is at 16000hz
; --------------------------------------------------------

	align $8000

; --------------------------------------------------------

DacIns_Nadie:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/nadie.wav",$2C
.end:
DacIns_Kick_techno:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/ST-72_kick.wav",$2C
.end:
DacIns_Snare_techno:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/ST-79_snare.wav",$2C
.end:
DacIns_Kick_wegot:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/wegot_kick.wav",$2C
.end:
