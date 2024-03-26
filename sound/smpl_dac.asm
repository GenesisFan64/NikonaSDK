; ===========================================================================
; --------------------------------------------------------
; GEMA/Nikona DAC instruments
;
; This must be located at the 68k's 900000 area.
; ** 68K BANK 0 only **
;
; BASE Samplerate is at 16000hz
; --------------------------------------------------------

	align $8000	; Start from a safe ROM-bank

; --------------------------------------------------------

; 	gSmplData Label,"filepath",loop_point(0-start)
;  	gSmplData PcmIns_test8,"sound/instr/smpl/test_8.wav",0
; 	gSmplData DacIns_Kick_techno,"sound/instr/smpl/ST-72_kick.wav",0
; 	gSmplData DacIns_Snare_techno,"sound/instr/smpl/ST-79_snare.wav",0
; 	gSmplData DacIns_Kick_wegot,"sound/instr/smpl/wegot_kick.wav",0
