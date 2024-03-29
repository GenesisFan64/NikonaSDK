; ===========================================================================
; --------------------------------------------------------
; GEMA/Nikona FM instruments "patches"
;
; Using .gsx save state for easy editing, use
; FM_EDITOR.bin in Fusion or any gsx compatible emulator
; to make or modify instrument data
; --------------------------------------------------------

; FM_EDITOR savestate data is located at:
; $2478
;
; Sizes:
; Normal FM ins: $20
; Special FM ins: $28
;
; INTRUMENT FORMAT:
; dc.b $30,$34,$38,$3C	; Register data following this order
; dc.b $40,$44,$48,$4C	; **
; dc.b $50,$54,$58,$5C	; **
; dc.b $60,$64,$68,$6C	; **
; dc.b $70,$74,$78,$7C	; **
; dc.b $80,$84,$88,$8C	; **
; dc.b $90,$94,$98,$9C	; **
; dc.b $B0,$B4,$22,$28	; **
; ** Extra words for FM3 special:
; dc.w OP1,OP2,OP3,OP4	; FM3 special ONLY: Manual frequencies
;
; $90,$94,$98,$9C: SSG-EG
; These CAN be used, but can be problematic
; on non-genuine systems.
;
; $B4: %00aa0ppp
; a - AMS
; p - PMS
; Keep panning bits 0, set the panning in your track.
;
; $22 LFO: %0000evvv
; e - Enable
; v - Value
; $28 KEYS: %oooo0000
; o - Operators 4-1
; --------------------------------------------------------

; TODO: a macro for this.

FmIns_Organ2:
		binclude "sound/instr/fm/organ2.gsx",$2478,$20
FmIns_Organ2a:
		binclude "sound/instr/fm/organ2a.gsx",$2478,$20

; FM3 Special
FmIns_Fm3_Explosion:
		binclude "sound/instr/fm/OLD/fm3_sfx_boomworm.gsx",$2478,$28
FmIns_Sp_OpenHat:
		binclude "sound/instr/fm/OLD/fm3_openhat.gsx",$2478,$28
FmIns_Sp_ClosedHat:
		binclude "sound/instr/fm/OLD/fm3_closedhat.gsx",$2478,$28
FmIns_Sp_Cowbell:
		binclude "sound/instr/fm/OLD/fm3_cowbell.gsx",$2478,$28
; BASS
FmIns_Bass_1:
		binclude "sound/instr/fm/OLD/bass_low.gsx",$2478,$20
FmIns_Bass_2:
		binclude "sound/instr/fm/OLD/bass_strong.gsx",$2478,$20
FmIns_Bass_donna:
		binclude "sound/instr/fm/OLD/bass_feellove.gsx",$2478,$20
FmIns_Bass_groove:
		binclude "sound/instr/fm/OLD/bass_groove.gsx",$2478,$20
FmIns_Bass_groove_2:
		binclude "sound/instr/fm/OLD/bass_groove_2.gsx",$2478,$20
FmIns_Bass_groove_gem:
		binclude "sound/instr/fm/OLD/bass_groove_gem.gsx",$2478,$20
FmIns_Bass_italo:
		binclude "sound/instr/fm/OLD/bass_italo.gsx",$2478,$20
FmIns_Bass_duck:
		binclude "sound/instr/fm/OLD/bass_duck.gsx",$2478,$20
FmIns_Bass_4:
		binclude "sound/instr/fm/OLD/bass_4.gsx",$2478,$20
FmIns_Bass_8:
		binclude "sound/instr/fm/OLD/bass_8.gsx",$2478,$20
FmIns_Bass_club:
		binclude "sound/instr/fm/OLD/OLD_bass_club.gsx",$2478,$20
FmIns_Bass_calm:
		binclude "sound/instr/fm/OLD/bass_calm.gsx",$2478,$20
FmIns_Bass_low_1:
		binclude "sound/instr/fm/OLD/bass_low_1.bin"
FmIns_Bass_Oil:
		binclude "sound/instr/fm/OLD/bass_oil.gsx",$2478,$20

; PIANO
FmIns_PianoM1:
		binclude "sound/instr/fm/OLD/piano_m1.gsx",$2478,$20
FmIns_Piano_Aqua:
		binclude "sound/instr/fm/OLD/piano_aqua.gsx",$2478,$20
FmIns_Piano_Hard:
		binclude "sound/instr/fm/OLD/piano_hard.bin"
; FmIns_Piano_m1:
; 		binclude "sound/instr/fm/OLD/piano_m1.gsx",$2478,$20


FmIns_Synth_Plus:
		binclude "sound/instr/fm/OLD/OLD_synthplus.gsx",$2478,$20

FmIns_Trumpet_1:
		binclude "sound/instr/fm/OLD/OLD_trumpet_1.gsx",$2478,$20
FmIns_Trumpet_carnival:
		binclude "sound/instr/fm/OLD/OLD_trumpet_carnivl.gsx",$2478,$20


FmIns_brass_eur:
		binclude "sound/instr/fm/OLD/OLD_brass_eur.gsx",$2478,$20
FmIns_Brass_Puy:
		binclude "sound/instr/fm/OLD/brass_puy.gsx",$2478,$20


FmIns_Organ_Ito:
		binclude "sound/instr/fm/OLD/organ_ito.gsx",$2478,$20
FmIns_Ding_Baseball:
		binclude "sound/instr/fm/OLD/ding_baseball.gsx",$2478,$20
FmIns_DrumKick_gem:
		binclude "sound/instr/fm/OLD/drum_kick_gem.gsx",$2478,$20


FmIns_Trumpet_2:
		binclude "sound/instr/fm/OLD/trumpet_2.gsx",$2478,$20
FmIns_Trumpet_puy:
		binclude "sound/instr/fm/OLD/trumpet_puy.gsx",$2478,$20
FmIns_Marimba:
		binclude "sound/instr/fm/OLD/marimba.gsx",$2478,$20

FmIns_Ding_toy:
		binclude "sound/instr/fm/OLD/ding_toy.gsx",$2478,$20

FmIns_Flaute_cave:
		binclude "sound/instr/fm/OLD/flaute_sea.gsx",$2478,$20
FmIns_Banjo_puy:
		binclude "sound/instr/fm/OLD/banjo_puy.gsx",$2478,$20
FmIns_PSynth_plus:
		binclude "sound/instr/fm/OLD/psynth_plus.gsx",$2478,$20
FmIns_Ding_1:
		binclude "sound/instr/fm/OLD/ding_gem.gsx",$2478,$20
FmIns_Trombone_gem:
		binclude "sound/instr/fm/OLD/trombone_gem.gsx",$2478,$20
FmIns_HBeat_tom:
		binclude "sound/instr/fm/OLD/nadia_tom.gsx",$2478,$20
FmIns_Guitar_bball:
		binclude "sound/instr/fm/OLD/guitar_bball.gsx",$2478,$20

FmIns_Hats_1:
		binclude "sound/instr/fm/OLD/fm_hats_spot.bin"
FmIns_Hats_closed:
		binclude "sound/instr/fm/OLD/hats_closed.gsx",$2478,$20
FmIns_ClosedHat:
		binclude "sound/instr/fm/OLD/hats_closed.gsx",$2478,$20

FmIns_Sewer_1:
		binclude "sound/instr/fm/OLD/sewer_1.bin"


FmIns_Ambient_dark:
		binclude "sound/instr/fm/OLD/ambient_dark.gsx",$2478,$20
FmIns_Ambient_spook:
		binclude "sound/instr/fm/OLD/ambient_spook.gsx",$2478,$20
FmIns_Ambient_3:
		binclude "sound/instr/fm/OLD/ambient_3.gsx",$2478,$20


; FmIns_Guitar_bball:
; 		binclude "sound/instr/fm/guitar_bball.gsx",$2478,$20
