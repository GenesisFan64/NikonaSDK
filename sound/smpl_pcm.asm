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

PcmIns_Arena1_01:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/01.wav",$2C
.end:
	align 2
PcmIns_Arena1_02:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/02.wav",$2C
.end:
	align 2
PcmIns_Arena1_03:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/03.wav",$2C
.end:
	align 2
PcmIns_Arena1_04:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/04.wav",$2C
.end:
	align 2
PcmIns_Arena1_05:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/05.wav",$2C
.end:
	align 2
PcmIns_Arena1_06:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/06.wav",$2C
.end:
	align 2
PcmIns_Arena1_07:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/07.wav",$2C
.end:
	align 2
PcmIns_Arena1_08:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/08.wav",$2C
.end:
	align 2
PcmIns_Arena1_09:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/09.wav",$2C
.end:
	align 2
PcmIns_Arena1_10:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/10.wav",$2C
.end:
	align 2
PcmIns_Arena1_11:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/11.wav",$2C
.end:
	align 2
PcmIns_Arena1_12:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/12.wav",$2C
.end:
	align 2
PcmIns_Arena1_13:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/13.wav",$2C
.end:
	align 2
PcmIns_Arena1_14:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/arena1/14.wav",$2C
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
