; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona PCM instruments for Sega CD
;
; Stored on DISC and loaded to Sub-CPU
;
; ** DO NOT LEAVE THIS SECTION EMPTY **
; --------------------------------------------------------

	align $800

; --------------------------------------------------------

PcmIns_menu_01:
	gSmpHead .end-.start,784
.start:	binclude "sound/instr/smpl/menu/01.wav",$2C
.end:
	align 2
PcmIns_menu_02:
	gSmpHead .end-.start,700
.start:	binclude "sound/instr/smpl/menu/02.wav",$2C
.end:
	align 2
PcmIns_menu_03:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/03.wav",$2C
.end:
	align 2
; PcmIns_menu_04:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/menu/04.wav",$2C
; .end:
	align 2
PcmIns_menu_05:
	gSmpHead .end-.start,5348
.start:	binclude "sound/instr/smpl/menu/05.wav",$2C
.end:
	align 2
PcmIns_menu_06:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/06.wav",$2C
.end:
	align 2
PcmIns_menu_07:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/07.wav",$2C
.end:
	align 2
PcmIns_menu_08:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/08.wav",$2C
.end:
	align 2
PcmIns_menu_09:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/09.wav",$2C
.end:
	align 2
; PcmIns_menu_10:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/menu/10.wav",$2C
; .end:
	align 2
PcmIns_menu_11:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/11.wav",$2C
.end:
	align 2
PcmIns_menu_12:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/12.wav",$2C
.end:
	align 2
PcmIns_menu_13:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/13.wav",$2C
.end:
	align 2
PcmIns_menu_14:
	gSmpHead .end-.start,4080
.start:	binclude "sound/instr/smpl/menu/14.wav",$2C
.end:
	align 2
PcmIns_menu_15:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/15.wav",$2C
.end:
	align 2
PcmIns_menu_16:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/menu/16.wav",$2C
.end:
	align 2

PcmIns_PKick:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/wegot_kick.wav",$2C
	align 4
.end:
PcmIns_Piano:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/piano.wav",$2C
	align 4
.end:
PcmIns_PTom:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/sauron_tom.wav",$2C
	align 4
.end:
PcmIns_NadieL:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/nadie_l.wav",$2C
	align 4
.end:
PcmIns_NadieR:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/nadie_r.wav",$2C
	align 4
.end:
PcmIns_MoveMe_Hit:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/moveme_hit.wav",$2C
	align 4
.end:
PcmIns_Kick:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/kick_moveme.wav",$2C
	align 4
.end:
PcmIns_Snare:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snare_moveme.wav",$2C
	align 4
.end:
PcmIns_MoveMe_BrassL:
	gSmpHead .end-.start,6478
.start:	binclude "sound/instr/smpl/brass_move_l.wav",$2C
	align 4
.end:
PcmIns_MoveMe_BrassR:
	gSmpHead .end-.start,6478
.start:	binclude "sound/instr/smpl/brass_move_r.wav",$2C
	align 4
.end:
