; ====================================================================
; ----------------------------------------------------------------
; CACHE code
;
; LIMIT: $600 bytes
; ----------------------------------------------------------------

		align 4
CACHE_MASTER:
		phase 0		; AS can't phase $C0000000

; ====================================================================

		dc.b "MASTER CACHE GOES HERE"
		align 4

; ====================================================================

		dephase
		align 4
CACHE_MASTER_E:
	if MOMPASS=6
		message "SH2 MASTER CACHE uses: \{(CACHE_MASTER_E-CACHE_MASTER)}"
	endif
