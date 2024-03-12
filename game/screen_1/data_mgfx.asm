; ===========================================================================
; ----------------------------------------------------------------
; Put your 32X graphics here, indexed or direct
;
; This is stored on the Genesis side and then
; sent to SDRAM using DREQ.
;
; Labels MUST be aligned by 4
; ----------------------------------------------------------------

		align 4
ArtMars_TEST:
		binclude "game/screen_1/data/mars/maps/test/data_art.bin"
		align 4


