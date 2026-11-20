$IsImm MACRO Operand:REQ
	IF (OPATTR (Operand)) AND 00000100y
		;; Is an immediate value
        EXITM <-1>
    ELSE
        EXITM <0>
    ENDIF
ENDM

$IsMem MACRO Operand:REQ
	IF (OPATTR (Operand)) AND 00000010y
		;; Is a memory variable or has a relocatable data label
		EXITM <-1>              ;; True
	ELSE
		EXITM <0>               ;; False
	ENDIF
ENDM

$IsReg MACRO Operand:REQ
	IF (OPATTR (Operand)) AND 00010000y
		;; Is a register value
        EXITM <-1>
    ELSE
        EXITM <0>
    ENDIF
ENDM

$IsStack MACRO Operand:REQ
	IF (OPATTR (Operand)) AND 01000000y
		;; relative to SS
        EXITM <-1>
    ELSE
        EXITM <0>
    ENDIF
ENDM

$IsAddr MACRO Operand:REQ
local a
	a = 0

	IF @SizeStr(<Operand>) GT 5		
		IFIDNI <addr >, @SubStr(<Operand>, 1 , 5)	;本函数将字符串 string 的第 start 位起的字符串取出 length 个字符。若 start 为负数，则从字符串尾端算起。若可省略的参数 length 存在，但为负数，则表示取到倒数第 length 个字符。
			a = 1
		ENDIF
	ENDIF

	IF a
        EXITM <-1>
    ELSE
        EXITM <0>
    ENDIF
ENDM

; The preceding $IsXxx macros is not a part of original ntdddk.h
; -

InitializeListHead MACRO ListHead:REQ
local a
	IF $IsAddr(ListHead)
		a SUBSTR <ListHead>, 6
		IF $IsStack(a)				;; Is relative to SS
			lea rax, a
		ELSE
			mov rax, offset a
		ENDIF
	ELSEIF $IsReg(ListHead)
		IFDIFI <ListHead>, <rax>	;; don't move rax onto itself
			mov rax, ListHead
		ENDIF
	ELSEIF $IsStack(ListHead)
		mov rax, ListHead
	ELSE
		.ERR
	ENDIF
	; (LIST_ENTRY PTR [rax]).Flink = (LIST_ENTRY PTR [rax]).Blink = rax
	mov (LIST_ENTRY PTR [rax]).Flink, rax
	mov (LIST_ENTRY PTR [rax]).Blink, rax
ENDM



;  BOOLEAN IsListEmpty( PLIST_ENTRY ListHead );

IsListEmpty MACRO ListHead:REQ
local a
	IF $IsAddr(ListHead)
		a SUBSTR <ListHead>, 6
		IF $IsStack(a)				;; Is relative to SS
			lea rax, a
		ELSE
			mov rax, offset a
		ENDIF
	ELSEIF $IsReg(ListHead)
		IFDIFI <ListHead>, <rax>	;; don't move rax onto itself
			mov rax, ListHead
		ENDIF
	ELSEIF $IsStack(ListHead)
		mov rax, ListHead
	ELSE
		.ERR
	ENDIF
	.if <<cmp [rax+LIST_ENTRY.Flink],rax>>,zero?
	
	;.if [LIST_ENTRY PTR [rax]].Flink == rax
		xor rax, rax
		inc rax						;; return TRUE
	.else
		xor rax, rax				;; return FALSE
	.endif
ENDM

$IsListEmpty MACRO ListHead:REQ
local a
	IF $IsAddr(ListHead)
		a SUBSTR <ListHead>, 6
		IF $IsStack(a)				;; Is relative to SS
			lea rax, a
		ELSE
			mov rax, offset a
		ENDIF
	ELSEIF $IsReg(ListHead)
		IFDIFI <ListHead>, <rax>	;; don't move rax onto itself
			mov rax, ListHead
		ENDIF
	ELSEIF $IsStack(ListHead)
		mov rax, ListHead
	ELSE
		.ERR
	ENDIF
	.if <<cmp [rax+LIST_ENTRY.Flink],rax>>,zero?
	;.if [LIST_ENTRY PTR [rax]].Flink == rax
		xor rax, rax
		inc rax						;; return TRUE
	.else
		xor rax, rax				;; return FALSE
	.endif
	EXITM <rax>
ENDM

;  VOID RemoveEntryList( PLIST_ENTRY Entry );

RemoveEntryList MACRO Entry:REQ
local a
	IF $IsAddr(Entry)
		a SUBSTR <Entry>, 6
		IF $IsStack(a)				;; Is relative to SS
			lea rax, a
		ELSE
			mov rax, offset a
		ENDIF
	ELSEIF $IsReg(Entry)
		IFDIFI <Entry>, <rax>		;; don't move rax onto itself
			mov rax, Entry
		ENDIF
	ELSEIF $IsStack(Entry)
		mov rax, Entry
	ELSE
		.ERR
	ENDIF

	mov rcx, (LIST_ENTRY PTR [rax]).Flink
	mov rax, (LIST_ENTRY PTR [rax]).Blink

	mov (LIST_ENTRY PTR [rax]).Flink, rcx
	mov (LIST_ENTRY PTR [rcx]).Blink, rax
ENDM

;  PLIST_ENTRY RemoveHeadList( PLIST_ENTRY ListHead );

RemoveHeadList MACRO ListHead:REQ
local a
	IF $IsAddr(ListHead)
		a SUBSTR <ListHead>, 6
		IF $IsStack(a)				;; Is relative to SS
			lea rax, a
		ELSE
			mov rax, offset a
		ENDIF
	ELSEIF $IsReg(ListHead)
		IFDIFI <ListHead>, <rax>	;; don't move rax onto itself
			mov rax, ListHead
		ENDIF
	ELSEIF $IsStack(ListHead)
		mov rax, ListHead
	ELSE
		.ERR
	ENDIF
	mov rcx, (LIST_ENTRY PTR [rax]).Flink
	push rcx

	mov rcx, (LIST_ENTRY PTR [rcx]).Flink
	mov (LIST_ENTRY PTR [rax]).Flink, rcx

	mov (LIST_ENTRY PTR [rcx]).Blink, rax

	pop rax
ENDM

$RemoveHeadList MACRO ListHead:REQ
local a
	IF $IsAddr(ListHead)
		a SUBSTR <ListHead>, 6
		IF $IsStack(a)				;; Is relative to SS
			lea rax, a
		ELSE
			mov rax, offset a
		ENDIF
	ELSEIF $IsReg(ListHead)
		IFDIFI <ListHead>, <rax>	;; don't move rax onto itself
			mov rax, ListHead
		ENDIF
	ELSEIF $IsStack(ListHead)
		mov rax, ListHead
	ELSE
		.ERR
	ENDIF
	mov rcx, (LIST_ENTRY PTR [rax]).Flink
	push rcx

	mov rcx, (LIST_ENTRY PTR [rcx]).Flink
	mov (LIST_ENTRY PTR [rax]).Flink, rcx

	mov (LIST_ENTRY PTR [rcx]).Blink, rax

	pop rax
	EXITM <rax>
ENDM

;  PLIST_ENTRY RemoveTailList( PLIST_ENTRY ListHead );

RemoveTailList MACRO ListHead:REQ
local a
	IF $IsAddr(ListHead)
		a SUBSTR <ListHead>, 6
		IF $IsStack(a)				;; Is relative to SS
			lea rax, a
		ELSE
			mov rax, offset a
		ENDIF
	ELSEIF $IsReg(ListHead)
		IFDIFI <ListHead>, <rax>	;; don't move rax onto itself
			mov rax, ListHead
		ENDIF
	ELSEIF $IsStack(ListHead)
		mov rax, ListHead
	ELSE
		.ERR
	ENDIF
	mov rcx, (LIST_ENTRY PTR [rax]).Blink
	push rcx

	mov rcx, (LIST_ENTRY PTR [rcx]).Blink
	mov (LIST_ENTRY PTR [rax]).Blink, rcx

	mov (LIST_ENTRY PTR [rcx]).Flink, rax

	pop rax
ENDM

$RemoveTailList MACRO ListHead:REQ
local a
	IF $IsAddr(ListHead)
		a SUBSTR <ListHead>, 6
		IF $IsStack(a)				;; Is relative to SS
			lea rax, a
		ELSE
			mov rax, offset a
		ENDIF
	ELSEIF $IsReg(ListHead)
		IFDIFI <ListHead>, <rax>	;; don't move eax onto itself
			mov rax, ListHead
		ENDIF
	ELSEIF $IsStack(ListHead)
		mov rax, ListHead
	ELSE
		.ERR
	ENDIF
	mov rcx, (LIST_ENTRY PTR [rax]).Blink
	push rcx

	mov rcx, (LIST_ENTRY PTR [rcx]).Blink
	mov (LIST_ENTRY PTR [rax]).Blink, rcx

	mov (LIST_ENTRY PTR [rcx]).Flink, rax

	pop rax
	EXITM <rax>
ENDM


;  VOID InsertTailList( PLIST_ENTRY ListHead, PLIST_ENTRY Entry );

InsertHeadList	 MACRO ListHead:REQ, Entry:REQ  ;插入到rax链表的前面
local h, e, rrax
	rrax = 0
	IF $IsAddr(ListHead)
		h SUBSTR <ListHead>, 6
		IF $IsStack(h)				;; Is relative to SS
			lea rax, h
			rrax = 1				;; no more rax
		ELSE
			mov rax, offset h
			rrax = 1				;; no more rax
		ENDIF
	ELSEIF $IsReg(ListHead)
		IFDIFI <ListHead>, <rax>	;; don't move rax onto itself
			mov rax, ListHead
			rrax = 1				;; no more rax
		ENDIF
	ELSEIF $IsStack(ListHead)
		mov rax, ListHead
		rrax = 1					;; no more rax
	ELSE
		.ERR
	ENDIF

	IF $IsAddr(Entry)
		e SUBSTR <Entry>, 6
		IF $IsStack(e)				;; Is relative to SS
			lea rcx, e
		ELSE
			mov rcx, offset e
		ENDIF
	ELSEIF $IsReg(Entry)

		IF rrax							;; if rax was used report error
			IFIDNI <Entry>, <rax>
				line TEXTEQU %@Line
				% ECHO @FileCur(line) : ERROR! Register value overwritten by InsertTailList macro.
				.ERR
			ENDIF		
		ENDIF

		IFDIFI <Entry>, <rcx>	;; don't move rax onto itself
			mov rcx, Entry
		ENDIF
	ELSEIF $IsStack(Entry)
		mov rcx, Entry
	ELSE
		.ERR
	ENDIF

	mov (LIST_ENTRY PTR [rcx]).Flink, rax
	push (LIST_ENTRY PTR [rax]).Blink
	pop (LIST_ENTRY PTR [rcx]).Blink

	push (LIST_ENTRY PTR [rax]).Blink
	mov (LIST_ENTRY PTR [rax]).Blink, rcx
	pop rax
	mov (LIST_ENTRY PTR [rax]).Flink, rcx
	
	
	
	
	
	
	
	
ENDM

;  VOID InsertHeadList( PLIST_ENTRY ListHead, PLIST_ENTRY Entry );

InsertTailList MACRO ListHead:REQ, Entry:REQ	;;插入到rax链表的后面
local h, e, rrax
	rrax = 0
	IF $IsAddr(ListHead)
		h SUBSTR <ListHead>, 6
		IF $IsStack(h)				;; Is relative to SS
			lea rax, h
			rrax = 1				;; no more rax
		ELSE
			mov rax, offset h
			rrax = 1				;; no more rax
		ENDIF
	ELSEIF $IsReg(ListHead)
		IFDIFI <ListHead>, <rax>	;; don't move rax onto itself
			mov rax, ListHead
			rrax = 1				;; no more rax
		ENDIF
	ELSEIF $IsStack(ListHead)
		mov rax, ListHead
		rrax = 1					;; no more rax
	ELSE
		.ERR
	ENDIF

	IF $IsAddr(Entry)
		e SUBSTR <Entry>, 6
		IF $IsStack(e)				;; Is relative to SS
			lea rcx, e
		ELSE
			mov rcx, offset e
		ENDIF
	ELSEIF $IsReg(Entry)

		IF rrax							;; if rax was used report error
			IFIDNI <Entry>, <rax>
				line TEXTEQU %@Line
				% ECHO @FileCur(line) : ERROR! Register value overwritten by InsertTailList macro.
				.ERR
			ENDIF		
		ENDIF

		IFDIFI <Entry>, <rcx>	;; don't move rax onto itself
			mov rcx, Entry
		ENDIF
	ELSEIF $IsStack(Entry)
		mov rcx, Entry
	ELSE
		.ERR
	ENDIF

	mov (LIST_ENTRY PTR [rcx]).Blink, rax
	push (LIST_ENTRY PTR [rax]).Flink
	pop (LIST_ENTRY PTR [rcx]).Flink

	push (LIST_ENTRY PTR [rax]).Flink
	mov (LIST_ENTRY PTR [rax]).Flink, rcx
	pop rax
	mov (LIST_ENTRY PTR [rax]).Blink, rcx



ENDM

