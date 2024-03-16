; ===========================================================================
; ------------------------------------------------------------
; SOUND TRACKS SECTION
; ------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------------
; Instrument macros
; ------------------------------------------------------------

gInsNull macro
	dc.b $00,$00,$00,$00
	dc.b $00,$00,$00,$00
	endm

; alv: attack level
; atk: attack rate
; slv: sustain
; dky: decay rate (up)
; rrt: release rate (down)
; vib: (TODO)
gInsPsg	macro pitch,alv,atk,slv,dky,rrt,vib
	dc.b $80,pitch,alv,atk
	dc.b slv,dky,rrt,vib
	endm

; same args as gInsPsg
; but this has one more argument for the noise type:
; mode: noise mode
;       %tmm
;        t  - Bass(0)|Noise(1)
;         mm- Clock(0)|Clock/2(1)|Clock/4(2)|Tone3(3)
;
gInsPsgN macro pitch,alv,atk,slv,dky,rrt,vib,mode
	dc.b $90|mode,pitch,alv,atk
	dc.b slv,dky,rrt,vib
	endm

; 24-bit 68k pointer to FM patch data
gInsFm macro pitch,fmins
	dc.b $A0,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; Same args as gInsFm but for FM3 special.
;
; ** Pitch is useless here, set to 0 **
gInsFm3	macro pitch,fmins
	dc.b $B0,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; DAC Sample
;
; flags: %000L
;        L - Loop sample No/Yes
gInsDac	macro pitch,start,flags
	dc.b $C0|flags,pitch,((start>>16)&$FF),((start>>8)&$FF)
	dc.b start&$FF,0,0,0
	endm

; Sega CD PCM Sample
;
; flags: %000L
;        L - Loop sample No/Yes
gInsPcm	macro pitch,start,flags
 if MCD|MARSCD
	dc.b $D0|flags,pitch,((start>>16)&$FF),((start>>8)&$FF)
	dc.b start&$FF,0,0,0
 else
	dc.b $00,$00,$00,$00
	dc.b $00,$00,$00,$00
 endif
	endm

; Sega 32X PWM Sample
;
; flags: %00SL
;        L - Loop sample No/Yes
;        S - Sample data is in STEREO
gInsPwm	macro pitch,start,flags
 if MARS|MARSCD
	dc.b $E0|flags,pitch,((start>>24)&$FF),((start>>16)&$FF)
	dc.b ((start>>8)&$FF),start&$FF,0,0
 else
	dc.b $00,$00,$00,$00
	dc.b $00,$00,$00,$00
 endif
	endm

; ticks - %gttttttt
;   loc - 68k pointer
;
; t-Ticks
; g-Use global tempo
gemaTrk macro ticks,loc
	dc.l ((ticks&$FF)<<24)|loc&$FFFFFF
	endm

; gemaHead
;
; blk_data,patt_data,ins_list,num_chnlsused
gemaHead macro blk,pat,ins,num
	dc.w num
	dc.l blk
	dc.l pat
	dc.l ins
	endm

; ====================================================================
; ------------------------------------------------------------
; Nikona DEFAULT track-list
;
; gemaTrk ticks+beatsbit*,track_data
; Add $80 ($80|ticks) to make the track use global sub-beats
;
; To use sub-beats call gemaSetBeats command
; BEFORE playing your track:
; 	move.w	#new_beats,d0
; 	bsr	gemaSetBeats
; 	move.w	#track_id,d0
;	bsr	gemaPlayTrack
; ------------------------------------------------------------

	align 2
Gema_MasterList:
	gemaTrk 4|$80,GemaTrk_Astral
	gemaTrk 3|$80,GemaTrk_Arena1
; 	gemaTrk 6|$80,GemaTrk_MOVEME
; 	gemaTrk 6|$80,GemaTrk_NadieMD
; 	gemaTrk 6|$80,GemaTrk_NadieMCD
; 	gemaTrk 6|$80,GemaTrk_NadieMARS
	gemaTrk 3|$80,GemaTrk_Crystal
	gemaTrk 3,GemaTrk_Dream

; ------------------------------------------------------------
; BGM tracks
; ------------------------------------------------------------

GemaSfx_All:
	gemaHead .blk,.pat,.ins,1
.blk:
	binclude "sound/tracks/sfxall_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/sfxall_patt.bin"
	align 2
.ins:
	gInsPsgN 0,$00,$00,$00,$00,$00,0,%100
	gInsPsgN 0,$00,$00,$00,$00,$00,0,%101
	gInsPsgN 0,$00,$00,$00,$00,$00,0,%110
	gInsFm 0,FmIns_Ding_1
	gInsFm3 0,FmIns_Fm3_Explosion

; ------------------------------------------------------------

GemaTrk_TEST_0:
	gemaHead .blk,.pat,.ins,3
.ins:
; 	gInsPsgN 0,$00,$00,$00,$00,$00,0,%101
; 	gInsFm -36-6,FmIns_Ambient_dark
	gInsPcm -12,PcmIns_MoveMe_BrassL,%11
; 	gInsPwm 0,PwmIns_Piano,%00
.blk:
	binclude "sound/tracks/test_blk.bin"
.pat:
	binclude "sound/tracks/test_patt.bin"

; ------------------------------------------------------------

GemaTrk_MOVEME:
	gemaHead .blk,.pat,.ins,13
.blk:
	binclude "sound/tracks/moveme_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/moveme_patt.bin"
	align 2
.ins:
	gInsPcm -12,PcmIns_MoveMe_Hit,%10
	gInsFm 0,FmIns_Bass_Duck
	gInsPcm -12,PcmIns_MoveMe_BrassL,%11
	gInsFm 0,FmIns_ClosedHat
	gInsPsgN 0,$00,$00,$00,$00,$04,0,%110
	gInsFm -12,FmIns_HBeat_tom
	gInsPcm -12,PcmIns_Snare,%10
	gInsPcm -12,PcmIns_Kick,%10		;gInsFm -38,FmIns_DrumKick_gem
	gInsFm -12,FmIns_Trumpet_carnival	;FmIns_Trumpet_2
	gInsPsg 0,$20,$20,$10,$01,$08,0		;gInsFm -12,FmIns_Ding_Baseball;
	gInsFm3 0,FmIns_Sp_OpenHat
	gInsNull;gInsPwm -17,PwmIns_MyTime,%10
	gInsPsg +12,$20,$10,$10,$0C,$0C,0
	gInsPsg 0,$00,$00,$00,$00,$06,0
	gInsPcm -12,PcmIns_MoveMe_BrassR,%11
	gInsNull
	gInsNull
	gInsNull
	gInsNull

; ------------------------------------------------------------

GemaTrk_Dream:
	gemaHead .blk,.pat,.ins,8
.blk:
	binclude "sound/tracks/dream_blk.bin"
.pat:
	binclude "sound/tracks/dream_patt.bin"
.ins:
	gInsFm 0,FmIns_Hats_closed
	gInsDac +12,DacIns_Kick_wegot,0
	gInsFm -12,FmIns_brass_eur
	gInsFm -24,FmIns_Trumpet_carnival
	gInsPsg  0,$00,$20,$00,$02,$10,0
	gInsPsgN 0,$00,$10,$00,$01,$04,0,%100
	gInsFm 0,FmIns_Bass_low_1
	gInsFm 0,FmIns_Hats_1
	gInsPsgN 0,$00,$10,$00,$01,$08,0,%101
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsPsg  0,$40,$00,$00,$00,$00,0
	gInsFm -12,FmIns_Trumpet_1

; Ticks: 3-1
; TEMPO: 170
GemaTrk_Crystal:
	gemaHead .blk,.pat,.ins,7
.blk:
	binclude "sound/tracks/crystal_blk.bin"
.pat:
	binclude "sound/tracks/crystal_patt.bin"
.ins:
	gInsFm 0,FmIns_Organ2a
	gInsPsgN 0,$00,$10,$00,$01,$10,0,%100
	gInsDac 0,DacIns_Kick_wegot,0
	gInsFm3 0,FmIns_Sp_OpenHat
	gInsNull
	gInsFm 0,FmIns_Bass_low_1

; ------------------------------------------------------------

GemaTrk_Arena1:
	gemaHead shrd_blk,shrd_pat,.ins,4
.ins:
	gInsPcm -17-7,PcmIns_techno_01,0
	gInsPcm -17-7,PcmIns_techno_02,0
	gInsPcm -17-7,PcmIns_techno_03,0
	gInsPcm -17-7,PcmIns_techno_04,0
	gInsPcm -17-7,PcmIns_techno_05,0
	gInsPcm -17-7,PcmIns_techno_06,1
	gInsPcm -17-7,PcmIns_techno_07,1
	gInsPcm -17-7,PcmIns_techno_08,1
	gInsPcm -17-7,PcmIns_techno_09,1
	gInsPcm -17-7,PcmIns_techno_10,1
	gInsPcm -17-7,PcmIns_techno_11,0
shrd_blk:
	binclude "sound/tracks/techno_blk.bin"
shrd_pat:
	binclude "sound/tracks/techno_patt.bin"

GemaTrk_Astral:
	gemaHead .blk,.patt,.ins,4
.ins:
	gInsPcm -17-7,PcmIns_astral_01,1
	gInsPcm -17-7,PcmIns_astral_02,1
	gInsPcm -17-7,PcmIns_astral_03,0
	gInsPcm -17-7,PcmIns_astral_04,0
	gInsPcm -17-7,PcmIns_astral_05,0
	gInsPcm -17-7,PcmIns_astral_06,0
	gInsPcm -17-7,PcmIns_astral_07,0
	gInsPcm -17-7,PcmIns_astral_08,0
	gInsPcm -17-7,PcmIns_astral_09,0
	gInsPcm -17-7,PcmIns_astral_10,0
	gInsPcm -17-7,PcmIns_astral_11,0
	gInsPcm -17-7,PcmIns_astral_12,0
	gInsPcm -17-7,PcmIns_astral_13,0
	gInsPcm -17-7,PcmIns_astral_14,0
	gInsPcm -17-7,PcmIns_astral_15,0
	gInsPcm -17-7,PcmIns_astral_16,0
	gInsPcm -17-7,PcmIns_astral_17,0
	gInsPcm -17-7,PcmIns_astral_18,0
	gInsPcm -17-7,PcmIns_astral_19,1
	gInsPcm -17-7,PcmIns_astral_20,1
	gInsPcm -17-7,PcmIns_astral_21,1
	gInsPcm -17-7,PcmIns_astral_22,0
	gInsPcm -17-7,PcmIns_astral_23,0
	gInsPcm -17-7,PcmIns_astral_24,0
	gInsPcm -17-7,PcmIns_astral_25,0
	gInsPcm -17-7,PcmIns_astral_26,0
.blk:
	binclude "sound/tracks/astral_blk.bin"
.patt:
	binclude "sound/tracks/astral_patt.bin"

; ------------------------------------------------------------

; GemaTrk_NadieMD:
; 	gemaHead .blk,.patt,.inst,7
; .blk:
; 	binclude "sound/tracks/nadie_md_blk.bin"
; 	align 2
; .patt:
; 	binclude "sound/tracks/nadie_md_patt.bin"
; 	align 2
; .inst:
; 	gInsDac 0,DacIns_Nadie,0
; 	gInsFm -36,FmIns_Piano_Aqua
; 	gInsFm -12,FmIns_HBeat_tom
; 	gInsFm -37,FmIns_DrumKick_gem
; 	gInsPsg 0,$50,$70,$00,$06,$08,0
; 	gInsFm 0,FmIns_Trumpet_1
; 	gInsNull
; 	gInsFm3 0,FmIns_Sp_ClosedHat
; 	gInsFm3 0,FmIns_Sp_OpenHat
;
; GemaTrk_NadieMCD:
; 	gemaHead .blk,.patt,.inst,11
; .blk:
; 	binclude "sound/tracks/nadie_mcd_blk.bin"
; 	align 2
; .patt
; 	binclude "sound/tracks/nadie_mcd_patt.bin"
; 	align 2
; .inst:
; 	gInsPcm -12,PcmIns_NadieL,%10
; 	gInsFm -36,FmIns_Piano_Aqua
; 	gInsFm -12,FmIns_HBeat_tom
; 	gInsPcm -12-12,PcmIns_PKick,%00
; 	gInsPsg 0,$50,$70,$00,$06,$08,0
; 	gInsFm 0,FmIns_Trumpet_1
; 	gInsPcm 0-12,PcmIns_Piano,%00
; 	gInsPcm -12-12,PcmIns_PTom,%00
; 	gInsPcm -12,PcmIns_NadieR,%10
;
; GemaTrk_NadieMARS:
; 	gemaHead .blk,.patt,.inst,11
; .blk:
; 	binclude "sound/tracks/nadie_blk.bin"
; 	align 2
; .patt
; 	binclude "sound/tracks/nadie_patt.bin"
; 	align 2
; .inst:
; 	gInsPwm 0,PwmIns_Nadie,%10
; 	gInsFm -36,FmIns_Piano_Aqua
; 	gInsFm -12,FmIns_HBeat_tom
; 	gInsPwm -12,PwmIns_PKick,%00
; 	gInsPsg 0,$50,$70,$00,$06,$08,0
; 	gInsFm 0,FmIns_Trumpet_1
; 	gInsPwm 0,PwmIns_Piano,%00
; 	gInsPwm -12,PwmIns_PTom,%00
; 	gInsNull
