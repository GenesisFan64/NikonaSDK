; ====================================================================
; ----------------------------------------------------------------
; GLOBAL RAM for ALL screen modes
;
; Score, Lives, Level number, etc.
; ----------------------------------------------------------------

			strct RAM_MdGlobal

; ------------------------------------------------------------
; Examples:
;
; RAM_Glbl_ExmpL ds.l 8 ; reserve 4 LONGS ($20 bytes)
; RAM_Glbl_ExmpW ds.w 6 ; reserve 3 WORDS ($0C bytes)
; RAM_Glbl_ExmpB ds.b 5 ; reserve 5 bytes
;
; Careful with bytes, everything needs to be word-algined
; or your will get an ADDRESS ERROR.
; ------------------------------------------------------------

RAM_Glbl_Filler		ds.l 1		; 1 long (4 bytes)


; ------------------------------------------------------------
sizeof_MdGlbl		ds.l 0		; size label
			endstrct
