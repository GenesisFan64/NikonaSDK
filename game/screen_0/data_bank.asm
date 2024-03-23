; ===========================================================================
; ----------------------------------------------------------------
; 68K SCREEN MODE DATA
; for big stuff like maps, level, etc.
;
; For Genesis graphics use data_dma.asm
; and for 32X graphics use data_mgfx.asm
;
; For 32X, CD32X:
; THE 256-COLOR PALETTES GO HERE.
; ----------------------------------------------------------------

; ----------------------------------------------------------------
; 32X Screen maps
; ----------------------------------------------------------------

MapMars_Scrn0:
		binclude "game/screen_0/data/mars/maps/test/data_map.bin"
		align 2

; ----------------------------------------------------------------
; 32X Palettes
; ----------------------------------------------------------------

PalMars_Doremi:
		binclude "game/screen_0/data/mars/objects/doremi/doremi_pal.bin"
		align 2
PalMars_Sophie:
		binclude "game/screen_0/data/mars/objects/sophie/sophie_pal.bin"
		align 2
PalMars_Scrn0:
		binclude "game/screen_0/data/mars/maps/test/data_pal.bin"
		align 2

; ----------------------------------------------------------------
; Screen maps
; ----------------------------------------------------------------

MAP_Scr0_BG:
		binclude "game/screen_0/data/md/maps/test/md_map.bin"
		align 2

; ----------------------------------------------------------------
; Object data
; ----------------------------------------------------------------

; Emily
objPal_Emily:
		binclude "game/screen_0/data/md/objects/emily/emi_pal.bin"
		align 2
objMap_Emily:
		binclude "game/screen_0/data/md/objects/emily/emi_map.bin"
		align 2
objDma_Emily:
		binclude "game/screen_0/data/md/objects/emily/emi_plc.bin"
		align 2

; Doremi
objPal_Doremi:
		binclude "game/screen_0/data/md/objects/doremi/doremi_pal.bin"
		align 2
objMap_Doremi:
		binclude "game/screen_0/data/md/objects/doremi/doremi_map.bin"
		align 2
objDma_Doremi:
		binclude "game/screen_0/data/md/objects/doremi/doremi_plc.bin"
		align 2

; Bibi
; objPal_Doremi:
; 		binclude "game/screen_0/data/md/objects/doremi/doremi_pal.bin"
; 		align 2
objMap_Bibi:
		binclude "game/screen_0/data/md/objects/bibi/bibi_map.bin"
		align 2
objDma_Bibi:
		binclude "game/screen_0/data/md/objects/bibi/bibi_plc.bin"
		align 2

; Sophie
objPal_Sophie:
		binclude "game/screen_0/data/md/objects/sophie/sophie_pal.bin"
		align 2
objMap_Sophie:
		binclude "game/screen_0/data/md/objects/sophie/sophie_map.bin"
		align 2
objDma_Sophie:
		binclude "game/screen_0/data/md/objects/sophie/sophie_plc.bin"
		align 2
