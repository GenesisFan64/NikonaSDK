; ===========================================================================
; ------------------------------------------------------------
; SOUNDTRACK SECTION
; ------------------------------------------------------------

; ------------------------------------------------------------
; Instrument macros
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
;
; pitch:
; -17-7 = 8000 hz
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

; Track data format:
; 	gemaHead .blk,.pat,.ins,3
; .blk:
; 	binclude "sound/tracks/track_blk.bin"
; .pat:
; 	binclude "sound/tracks/track_patt.bin"
; .ins:
; 	gIns??? pitch,ins_data,flags
; 	; ...
; 	; Entry for each instrument
; 	; starts from 1, not 0.
;
; Default Samplerate for samples: 16000hz
; APPLIES TO ALL.

; ====================================================================
; ------------------------------------------------------------
; Nikona DEFAULT track-list
;
; Entry:
; gemaTrk ticks,track_data	; Without global beats
; gemaTrk ticks|$80,track_data	; With global beats
;
; To use sub-beats call gemaSetBeats extenally
; BEFORE playing your track:
; 	move.w	#new_beats,d0
; 	bsr	gemaSetBeats
; 	move.w	#track_id,d0
;	bsr	gemaPlayTrack
; ------------------------------------------------------------

	align 2
Gema_MasterList:
	gemaTrk $3F,GemaTrk_Test
	gemaTrk 4|$80,GemaTrk_Astral
	gemaTrk 3|$80,GemaTrk_Arena1

; ------------------------------------------------------------

GemaTrk_Test:
	gemaHead .blk,.pat,.ins,3
.blk:
	binclude "sound/tracks/test_blk.bin"
.pat:
	binclude "sound/tracks/test_patt.bin"
.ins:
	gInsNull
; 	gInsPwm -12,PwmIns_test8,0

; ------------------------------------------------------------

GemaTrk_Arena1:
	gemaHead .blk,.patt,.ins,4
.blk:
	binclude "sound/tracks/techno_blk.bin"
.patt:
	binclude "sound/tracks/techno_patt.bin"
.ins:
	gInsPcm -12,PcmIns_techno_01,0
	gInsPcm -12,PcmIns_techno_02,0
	gInsPcm -12,PcmIns_techno_03,0
	gInsPcm -12,PcmIns_techno_04,0
	gInsPcm -12,PcmIns_techno_05,0
	gInsPcm -12,PcmIns_techno_06,1
	gInsPcm -12,PcmIns_techno_07,1
	gInsPcm -12,PcmIns_techno_08,1
	gInsPcm -12,PcmIns_techno_09,1
	gInsPcm -12,PcmIns_techno_10,1
	gInsPcm -12,PcmIns_techno_11,0

; ------------------------------------------------------------

GemaTrk_Astral:
	gemaHead .blk,.patt,.ins,4
.blk:
	binclude "sound/tracks/astral_blk.bin"
.patt:
	binclude "sound/tracks/astral_patt.bin"
.ins:
	gInsPcm -12,PcmIns_astral_01,1
	gInsPcm -12,PcmIns_astral_02,1
	gInsPcm -12,PcmIns_astral_03,0
	gInsPcm -12,PcmIns_astral_04,0
	gInsPcm -12,PcmIns_astral_05,0
	gInsPcm -12,PcmIns_astral_06,0
	gInsPcm -12,PcmIns_astral_07,0
	gInsPcm -12,PcmIns_astral_08,0
	gInsPcm -12,PcmIns_astral_09,0
	gInsPcm -12,PcmIns_astral_10,0
	gInsPcm -12,PcmIns_astral_11,0
	gInsPcm -12,PcmIns_astral_12,0
	gInsPcm -12,PcmIns_astral_13,0
	gInsPcm -12,PcmIns_astral_14,0
	gInsPcm -12,PcmIns_astral_15,0
	gInsPcm -12,PcmIns_astral_16,0
	gInsPcm -12,PcmIns_astral_17,0
	gInsPcm -12,PcmIns_astral_18,0
	gInsPcm -12,PcmIns_astral_19,1
	gInsPcm -12,PcmIns_astral_20,1
	gInsPcm -12,PcmIns_astral_21,1
	gInsPcm -12,PcmIns_astral_22,0
	gInsPcm -12,PcmIns_astral_23,0
	gInsPcm -12,PcmIns_astral_24,0
	gInsPcm -12,PcmIns_astral_25,0
	gInsPcm -12,PcmIns_astral_26,0
