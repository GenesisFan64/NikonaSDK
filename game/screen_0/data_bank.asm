; ====================================================================
; ----------------------------------------------------------------
; 68K SCREEN MODE DATA
; for big stuff like maps, level, etc.
;
; For Genesis graphics use data_dma.asm
; and for 32X graphics use data_mgfx.asm
;
; 32X 256-COLOR PALETTES GO HERE.
;
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

; ----------------------------------------------------------------
; 32X Screen maps
; ----------------------------------------------------------------

MAP_TEST:
		binclude "game/screen_0/data/maps/md/test/md_map.bin"
		align 2
MapMars_TEST:
		binclude "game/screen_0/data/maps/mars/test/data_map.bin"
		align 2

; ----------------------------------------------------------------
; 32X Palettes
; ----------------------------------------------------------------

PalMars_TEST:
		binclude "game/screen_0/data/maps/mars/test/data_pal.bin"
		align 2
PalMars_Sabrina:
		binclude "game/screen_0/data/objects/mars/sabrina/sabrina_pal.bin"
		align 2

; ----------------------------------------------------------------
; Object palettes
; ----------------------------------------------------------------

objPal_Sisi:
		binclude "game/screen_0/data/objects/md/sisi/sisi_pal.bin"
		align 2

; ----------------------------------------------------------------
; Object maps
; ----------------------------------------------------------------

objMap_Sisi:
		binclude "game/screen_0/data/objects/md/sisi/sisi_map.bin"
		align 2
