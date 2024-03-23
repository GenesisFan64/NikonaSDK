; ===========================================================================
; ----------------------------------------------------------------
; Put your 32X graphics here
;
; This is stored on the Genesis side and then
; sent to SDRAM using DREQ.
;
; Labels MUST be aligned by 4
; ----------------------------------------------------------------

		align 4
ArtSSpr_Doremi:
		binclude "game/screen_0/data/mars/objects/doremi/doremi_art.bin"
		align 4
ArtSSpr_Sophie:
		binclude "game/screen_0/data/mars/objects/sophie/sophie_art.bin"
		align 4
ArtMars_Scrn0:
		binclude "game/screen_0/data/mars/maps/test/data_art.bin"
		align 4


