INCLUDE "constants.asm"

SECTION "AddItemToInventory_", ROMX[$4AA1], BANK[$03]

_ReceiveItem: ; 03:4AA1
	call DoesHLEqualwNumBagItems
	jp nz, PutItemInPocket
	push hl
	ld hl, CheckItemPocket
	ld a, BANK( CheckItemPocket )
	call FarCall_hl
	ld a, [wItemAttributeParamBuffer]
	dec a
	ld hl, .Pockets
	jp CallJumptable
	
.Pockets: ; 03:4ABA
	dw .Item
	dw .KeyItem
	dw .Ball
	dw .TMHM

.Item: ; 03:4AC2
	pop hl
	jp PutItemInPocket

.KeyItem: ; 03:4AC6
	pop hl
	jp ReceiveKeyItem

.Ball: ; 03:4ACA
	pop hl
	ld a, [wCurItem]
	ld c, a
	call GetBallIndex
	jp ReceiveBall

.TMHM: ; 03:4AD5
	pop hl
	ld a, [wCurItem]
	ld c, a
	call GetTMHMNumber
	jp ReceiveTMHM
	

_TossItem: ; 03:4AE0
	call DoesHLEqualwNumBagItems
	jr nz, .removeItem
	push hl
	ld hl, CheckItemPocket
	ld a, BANK( CheckItemPocket )
	call FarCall_hl
	ld a, [wItemAttributeParamBuffer]
	dec a
	ld hl, .Pockets
	jp CallJumptable
	
.Pockets ; 03:4AF8
	dw .Item
	dw .KeyItem
	dw .Ball
	dw .TMHM
	
.Ball ; 03:4B00
	pop hl
	ld a, [wCurItem]
	ld c, a
	call GetBallIndex
	jp TossBall
	
.TMHM ; 03:4B0B
	pop hl
	ld a, [wCurItem]
	ld c, a
	call GetTMHMNumber
	jp TossTMHM
	
.KeyItem ; 03:4B16
	pop hl
	jp TossKeyItem
	
.Item ; 03:4B1A
	pop hl

.removeItem ; 03:4B1B
	jp RemoveItemFromPocket


_CheckItem: ; 03:4B1E
	call DoesHLEqualwNumBagItems
	jr nz, .checkItem
	push hl
	ld hl, CheckItemPocket
	ld a, BANK( CheckItemPocket )
	call FarCall_hl
	ld a, [wItemAttributeParamBuffer]
	dec a
	ld hl, .Pockets
	jp CallJumptable
	
.Pockets ; 03:4B36
	dw .Item
	dw .KeyItem
	dw .Ball
	dw .TMHM
	
.Ball ; 03:4B3E
	pop hl
	ld a, [wCurItem]
	ld c, a
	call GetBallIndex
	jp CheckBall

.TMHM ; 03:4B49
	pop hl
	ld a, [wCurItem]
	ld c, a
	call GetTMHMNumber
	jp CheckTMHM
	
.KeyItem ; 03:4B54
	pop hl
	jp CheckKeyItems
	
.Item ; 03:4B58
	pop hl
	
.checkItem
	jp CheckTheItem


DoesHLEqualwNumBagItems: ; 03:4B5C
	ld a, l
	cp LOW(wNumBagItems)
	ret nz
	ld a, h
	cp HIGH(wNumBagItems)
	ret


PutItemInPocket: ; 03:4B64
	ld d, h
	ld e, l
	inc hl
	ld a, [wCurItem]
	ld c, a
	ld b, 0
	
; will add the item once the total
; available space (b) exceeds the
; amount being added
.findItemLoop
	ld a, [hli]
	cp $FF
	jr z, .checkIfInventoryFull
	cp c
	jr nz, .checkNextItem
	ld a, 99
	sub [hl]
	add b
	ld b, a
	ld a, [wItemQuantity]
	cp b
	jr z, .itemCanBeAdded
	jr c, .itemCanBeAdded

.checkNextItem
	inc hl
	jr .findItemLoop
	
.checkIfInventoryFull
	call GetPocketCapacity
	ld a, [de]
	cp c
	jr c, .itemCanBeAdded
	
	and a
	ret
	
.itemCanBeAdded
	ld h, d
	ld l, e
	ld a, [wCurItem]
	ld c, a
	
.findItemToAddLoop
	inc hl
	ld a, [hli]
	cp a, $FF
	jr z, .addNewItem
	cp c
	jr nz, .findItemToAddLoop
	
	ld a, [wItemQuantity]
	add [hl]
	cp a, 100
	jr nc, .setMax
	ld [hl], a
	jr .success

; set this slot's quantity to 99,
; and keep iterating through list
; to add remaining amount
.setMax
	ld [hl], 99
	sub 99
	ld [wItemQuantity], a
	jr .findItemToAddLoop
	
.addNewItem
	dec hl
	ld a, [wCurItem]
	ld [hli], a
	ld a, [wItemQuantity]
	ld [hli], a
	ld [hl], $FF
	ld h, d
	ld l, e
	inc [hl]
.success
	scf
	ret

	
GetPocketCapacity: ; 03:4BC1
	ld c, MAX_ITEMS
	ld a, e
	cp a, LOW(wNumBagItems)
	jr nz, .notBag
	ld a, d
	cp HIGH(wNumBagItems)
	ret z
	
.notBag
	ld c, MAX_PC_ITEMS
	ret

	
RemoveItemFromPocket: ;03:4BCF
	ld d, h
	ld e, l
	inc hl
	ld a, [wItemIndex]
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	inc hl
	ld a, [wItemQuantity]
	ld b, a
	ld a, [hl]
	sub b
	jr c, .fail
	
	ld [hl], a
	ld [wItemQuantityBuffer], a
	and a
	jr nz, .dontEraseSlot
	
; if the remaining quantity is zero
; then erase the slot by shifting
; the subsequent data upwards
	dec hl
	ld b, h
	ld c, l
	inc hl
	inc hl
	
.shift
	ld a, [hli]
	ld [bc], a
	inc bc
	cp $FF
	jr nz, .shift
	
	ld h, d
	ld l, e
	
	dec [hl]
	
.dontEraseSlot
	scf
	ret
	
.fail
	and a
	ret
	
	
CheckTheItem: ; 03:4BFD
	ld a, [wCurItem]
	ld c, a
	
.loop
	inc hl
	ld a, [hli]
	cp $FF
	jr z, .fail
	cp c
	jr nz, .loop
	
	scf
	ret
	
.fail
	and a
	ret

	
ReceiveKeyItem: ; 03:4C0E
	ld hl, wNumKeyItems
	ld a, [hli]
	cp a, MAX_KEY_ITEMS
	jr nc, .fail
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [wCurItem]
	ld [hli], a
	ld [hl], $FF
	ld hl, wNumKeyItems
	inc [hl]
	scf
	ret
	
.fail
	and a
	ret
	
	
TossKeyItem: ; 03:4C28
	ld hl, wNumKeyItems
	dec [hl]
	inc hl
	ld a, [wItemIndex]
	ld e, a
	ld d, 0
	add hl, de
	ld d, h
	ld e, l
	inc hl
	
.shift
	ld a, [hli]
	ld [de], a
	inc de
	cp $FF
	jr nz, .shift
	
	scf
	ret
	
	
CheckKeyItems: ; 03:4C40
	ld a, [wCurItem]
	ld c, a
	ld hl, wKeyItems
	
.loop
	ld a, [hli]
	cp c
	jr z, .matchFound
	cp $FF
	jr nz, .loop

	and a
	ret
	
.matchFound
	scf
	ret
	
	
; get index of ball item id c from BallItems
GetBallIndex: ; 03:4C53
	ld a, c
	push hl
	push de
	push bc
	ld hl, BallItems
	ld de, 1
	call FindItemInTable
	ld a, b
	pop bc
	pop de
	pop hl
	ld c, a
	ret
	
	
; get ball item id at index c in BallItems
GetBallByIndex: ; 03:4c66
	push bc
	push hl
	ld b, 0
	ld hl, BallItems
	add hl, bc
	ld a, [hl]
	pop hl
	pop bc
	ld c, a
	ret
	
	
BallItems: ; 03:4C73
	db ITEM_MASTER_BALL
	db ITEM_ULTRA_BALL
	db ITEM_GREAT_BALL
	db ITEM_POKE_BALL
	db $FF
	

; empties the ball pocket by setting the
; terminator immediately after wNumBallItems

	; Note, the ball pocket appears to be
	; a fixed length, not $FF terminated
EmptyBallPocket: ; 03:4C78
	ld hl, wNumBallItems
	xor a
	ld [hli], a
	ld [hl], $FF
	ret
	

ReceiveBall: ; 03:4C80
	ld hl, wBallQuantities
	ld b, 0
	add hl, bc
	ld a, [wItemQuantity]
	add [hl]
	cp 100
	jr nc, .fail
	ld b, a
	ld a, [hl]
	and a
	jr nz, .skipIncreasingNumItems
	
	ld a, [wNumBallItems]
	inc a
	ld [wNumBallItems], a
	
.skipIncreasingNumItems
	ld [hl], b
	scf
	ret
	
.fail
	and a
	ret
	

TossBall: ; 03:4C9F
	ld hl, wBallQuantities
	ld b, 0
	add hl, bc
	ld a, [wItemQuantity]
	ld b, a
	ld a, [hl]
	sub b
	jr c, .fail
	jr nz, .skipDecreasingNumItems
	
	ld b, a
	ld a, [wNumBallItems]
	dec a
	ld [wNumBallItems], a
	ld a, b
	
.skipDecreasingNumItems
	ld [hl], a
	ld [wItemQuantityBuffer], a
	scf
	ret
	
.fail
	and a
	ret
	
	
CheckBall: ; 03:4CC0
	ld hl, wBallQuantities
	ld b, 0
	add hl, bc
	ld a, [hl]
	and a
	ret z
	scf
	ret

	
ReceiveTMHM: ; 03:4CCB
	ld b, 0
	ld hl, wTMsHMs
	add hl, bc
	ld a, [wItemQuantity]
	add [hl]
	cp 100
	jr nc, .fail
	ld [hl], a
	scf
	ret
	
.fail
	and a
	ret
	
	
TossTMHM: ; 03:4CDE
	ld b, 0
	ld hl, wTMsHMs
	add hl, bc
	ld a, [wItemQuantity]
	ld b, a
	ld a, [hl]
	sub b
	jr c, .fail
	
	ld [hl], a
	ld [wItemQuantityBuffer], a
	scf
	ret

.fail
	and a
	ret

	
CheckTMHM: ; 03:4CF4
	ld b, 0
	ld hl, wTMsHMs
	add hl, bc
	ld a, [hl]
	and a
	ret z
	scf
	ret

GetTMHMNumber: ; 03:4CFF
	ld a, c
	ld c, 0
	
	sub ITEM_TM01
	jr c, .notMachine
	
	cp ITEM_C8 - ITEM_TM01
	jr z, .notMachine
	jr c, .finish
	
	inc c
	cp ITEM_E1 - ITEM_TM01
	jr z, .notMachine
	
	jr c, .finish
	inc c

; c represents the amount of non-TMs which
; appear ahead of this item in the list
; so subtract that value before exiting
.finish
	sub c
	ld c, a
	scf
	ret
	
.notMachine
	and a
	ret
	
SECTION "_CheckTossableItem", ROMX[$53AD], BANK[$03]

_CheckTossableItem: ; 03:53AD
; Return 1 in wItemAttributeParamBuffer and carry if wCurItem can't be removed from the bag.
	ld a, ITEMATTR_PERMISSIONS
	call GetItemAttr
	bit CANT_TOSS_F, a
	jr nz, ItemAttr_ReturnCarry
	and a
	ret

CheckSelectableItem: ; 03:53B8
; Return 1 in wItemAttributeParamBuffer and carry if wCurItem can't be selected.
	ld a, ITEMATTR_PERMISSIONS
	call GetItemAttr
	bit CANT_SELECT_F, a
	jr nz, ItemAttr_ReturnCarry
	and a
	ret

CheckItemPocket: ; 03:53C3
; Return the pocket for wCurItem in wItemAttributeParamBuffer.
	ld a, ITEMATTR_POCKET
	call GetItemAttr
	and $0F
	ld [wItemAttributeParamBuffer], a
	ret

CheckItemContext: ; 03:53CE
; Return the context for wCurItem in wItemAttributeParamBuffer.
	ld a, ITEMATTR_HELP
	call GetItemAttr
	and $0F
	ld [wItemAttributeParamBuffer], a
	ret

CheckItemMenu: ; 03:53D9
; Return the menu for wCurItem in wItemAttributeParamBuffer.
	ld a, ITEMATTR_HELP
	call GetItemAttr
	swap a
	and $f
	ld [wItemAttributeParamBuffer], a
	ret
	
GetItemAttr: ; 03:53E6
; Get attribute a of wCurItem.
	push hl
	push bc
	ld hl, ItemAttributes
	ld c, a
	ld b, 0
	add hl, bc
	xor a
	ld [wItemAttributeParamBuffer], a
	ld a, [wCurItem]
	dec a
	ld c, a
	ld a, ITEMATTR_STRUCT_LENGTH
	call AddNTimes
	ld a, BANK( ItemAttributes )
	call GetFarByte
	pop bc
	pop hl
	ret

ItemAttr_ReturnCarry: ; 03:5405
	ld a, 1
	ld [wItemAttributeParamBuffer], a
	scf
	ret
	
GetItemPrice: ; 03:540C
; Return the price of wCurItem in de.
	push hl
	push bc
	ld a, ITEMATTR_PRICE
	call GetItemAttr
	ld e, a
	ld a, ITEMATTR_PRICE_HI
	call GetItemAttr
	ld d, a
	pop bc
	pop hl
	ret