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

MapMars_TEST:
		binclude "game/screen_1/data/mars/maps/test/data_map.bin"
		align 2

; ----------------------------------------------------------------
; 32X Palettes
; ----------------------------------------------------------------

PalMars_TEST:
		binclude "game/screen_1/data/mars/maps/test/data_pal.bin"
		align 2

; ----------------------------------------------------------------
; Screen maps
; ----------------------------------------------------------------

MAP_TEST:
		binclude "game/screen_1/data/md/maps/test/md_map.bin"
		align 2

; ----------------------------------------------------------------
; Object maps
; ----------------------------------------------------------------

objPal_Sisi:
		binclude "game/screen_1/data/md/objects/sisi/sisi_pal.bin"
		align 2
objMap_Sisi:
		binclude "game/screen_1/data/md/objects/sisi/sisi_map.bin"
		align 2
