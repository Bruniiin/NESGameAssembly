 INCLUDE "const.inc"
 INCLUDE "chr.asm"
; INCLUDE "HEADER.inc"

 .inesprg 1
 .ineschr 1
 .inesmap 0
 .inesmir 1

 .bank 0
 .org $C000

; Awake

Awake.BlankWait:
    BIT $2002
    BPL Awake.BlankWait
    RTS
Awake.Reset:
    SEI
    CLD
    LDA #$40
    STA $4017
    LDX #$FF
    STA PPUMASK_REG2
    AND #$00000110
    TXS ; set up stack
Awake.BootCheck:
    ; LDA MaxPlayerScore, x
    ; BEQ Awake.ClrMem
    ; LDY #ResetBootValid
Awake.ClrMem:
    LDA #$00
    STA $00,  x
    STA $0100, x
    STA $0200, x
    STA $0300, x
    STA $0400, x
    STA $0500, x
    STA $0700, x
    ; LDA #$FE
    ; STA $200, x
    INX
    BNE Awake.ClrMem

; GameState.SetState: 

    ; LDA State
    ; BEQ GameState.Main

; GameState.Title:

    ; JSR Entity.LoadStart
    ; JSR Scene.StartScene
    ; JSR Scene.DrawToBuffer
    ; JMP Main

; GameState.Main:

Main:

    STA ProgramMode
    JSR Awake.BlankWait ; wait two empty frames.
    JSR Awake.BlankWait
    STA DELTA_REG+1
    AND #$00010000
    STA PPUMASK_REG2
    AND #$10000000
    STA PPUCTRL_REG1
    Main.Loop:
        LDA FrameCounter 
    Main.Wait:
        CMP FrameCounter 
        BEQ Main.Wait
        JMP Main.Loop


; The demo's program is split into two parts: the main program and NMI, which fires every v-blank.

NMI:

        LDA #$00
        STA $2003
        LDA #$02
        STA $4014
        LDA #%00010000
        STA PPUCTRL_REG1
        AND #%11100110 ; disable screen for rendering OAM
        STA PPUCTRL_REG2
        LDA ScrollHor
        STA $2005
        LDA #$00
        STA $2005
    Nmi.Logic:
        JSR HandlePause
        LDA PauseStatus
        LSR A
        BCS Nmi.HandleUi
        JSR Input.HandleInput
        JSR Entity.Update
        LDA PlayerStatus
        AND #$11111110
        BNE Nmi.Render
        JSR Entity.SpawnPlayer
        JMP Nmi.Render
    Nmi.HandleUi:
        JSR HandlePauseUi
    Nmi.Render:
        LDA #$00
        LDX #$00
        LDY #$00
        JSR Entity.RenderEntity
        JSR PushGfxBuffer
    Nmi.GfxBuffer:
        JSR Scene.LoadBuffer
        LDA BuffersDone
        CMP BufferAmount
        BNE Nmi.GfxBufferLoop
    Nmi.FrameUpdate: ; increments a variable once per frame, useful for RNG calculations later
        INC FrameCounter
    Nmi.GfxEnable:
        LDA #%10000000
        STA PPUCTRL_REG1
        AND #%11111110
        STA PPUMASK_REG2

        ; ready for the next frame.
            
RTI

HandlePause:
    LDA PauseStatus
    BNE HandleUnpause
    LDA ScrollOper
    LSR A
    BCS HandleUiScroll
    LDA Controller_1
    AND #%00010000
    BEQ HandlePauseDone
    INC ScrollOper ; currently scrolling.
HandleUiScroll:
    LDA ScrollHor
    SBC #$01
    STA ScrollHor
    CMP #$E0
    BEQ UiScrollSet
    RTS 
UiScrollSet:
    DEC ScrollOper
    INC PauseStatus
HandleUnpause:
    LDA ScrollOper
    LSR A
    BCS HandleUiUnscroll
    LDA Controller_1
    AND #%00010000
    BEQ HandlePauseDone
HandleUiUnscroll:
    LDA ScrollHor
    ADC #$01
    STA ScrollHor
    CMP #$20
    BEQ UiScrollset
    RTS
HandlePauseDone:
    RTS

Entity.Update:

Entity.SpawnPlayer:
    ; LDA GameStatus
    ; AND #$00000001
    ; BNE Entity.SpawnPlayerDone
    ; AND #$10000001
    ; BEQ Entity.SpawnPlayerDone
    LDA #$00
    STA PlayerStatus
    LDA ScrollXReg ; + 32
    CLC
    ADC #$32
    STA PlayerPos_X
    LDA #$DC
    STA PlayerPos_Y
    INC InputStatus
    LDA #$00
    ORA #%00000001
    STA GameStatus
Entity.CalcPosOffset:
    LDA #$00
    LDX #$00
    LDY #$00
    LDA PlayerAttr, x
    STA PosOffsetEntriesToCopy
Entity.CalcPosOffsetLoop:
    INX
    LDA PlayerAttr, x
    AND #%11110000
    LSR A ; PHA
    STA PosOffsetHor
    LDA PlayerAttr, x
    AND #%00001111
    STA PosOffsetVer
    INX
    LDY #$00

; horizontal pos

Entity.CalcPosOffsetHorLoop:
    LDA PlayerPos_X
    CPY PosOffsetHor
    BEQ Entity.CalcPosOffsetTransfer
Entity.CalcPosOffsetHorAdd:
    ADC #$04
    INY
    CPY PosOffsetHor
    BNE CalcPosOffsetAdd
Entity.CalcPosOffsetHorTransfer:

    STA PlayerAttr, x
    INX
    LDY #$00

; vertical pos

Entity.CalcPosOffsetVerLoop:
    LDA PlayerPos_Y
    CPY PosOffsetVer
    BEQ Entity.CalcPosOffsetTransfer
Entity.CalcPosOffsetVerAdd:
    ADC #$04
    INY
    CPY PosOffsetHor
    BNE CalcPosOffsetAdd
Entity.CalcPosOffsetVerTransfer:
    STA PlayerAttr, x
    CPX PosOffsetEntriesToCopy
    BNE Entity.CalcPosOffsetLoop
Entity.SpawnPlayerDone:
    RTS

   ;vert tile attr horiz

Entity.LoadEntity:

    LDA GameStatus
    AND #$10000000
    BNE Entity.SetPlayerPosition
    LDA #$04 ; $0204 = base offset. can change effortlessly if needed
    STA BaseOAMAddress_LOW
    TAY 
    Entity.RenderPlayerSprite:
        LDX #$00
        LDA PlayerGraphicsTable, x
        CLC
        ADC #$02
        STA SpriteLength
        INX
        LDA PlayerGraphicsTable, x
        STA SpritePallette
        INX
        INY
    Entity.RenderPlayerSpriteLoop:
        LDA PlayerGraphicsTable, x
        STA SPRITE_RAM, y
        INY
        LDA SpritePallette
        STA SPRITE_RAM, y
        INX
        INY
        INY
        INY
        CPX SpriteLength
        BNE Entity.RenderPlayerSpriteLoop
    Entity.SetPlayerPosition:
        LDA BaseOAMAddress_LOW
        TAY
        INY
        LDX #$00
    Entity.SetPlayerPositionLoop:
        LDA PlayerAttr, x ; copy vertical
        STA SPRITE_RAM, y
        INX
        INY
        INY
        INY
        LDA PlayerAttr, x ; copy horizontal
        STA SPRITE_RAM, y
        INX
        INY
        CPX SpriteLength
        BNE Entity.SetPlayerPositionLoop
    Entity.RenderPlayerDone:
        RTS

        ;LDY PlayerAttributes, x
        ;STY SPRITE_RAM + SpriteRamLocationLow
        ;LDA SpriteRamLocationLow
        ;CLC
        ;ADC #$02
        ;INX
        ;LDY PlayerAttributes, x
        ;STY SPRITE_RAM + SpriteRamLocationLow
        ;CPX SpriteLength
        ;BNE Entity.SetPlayerPosition

        ;LDA PlayerGraphicsTable, x
        ;STA SPRITE_RAM, y
        ;LDA SpriteRamLocationLow
        ;CLC
        ;ADC #$01
        ;LDA SpritePallette
        ;STA SPRITE_RAM + SpriteRamLocationLow
        ;ADC #$04
        ;INY
        ;CPY SpriteLength
        ;BNE Entity.RenderPlayerSpriteLoop

    Entity.LoadEntityLoop: ; old code.

        LDA ENTITY0, x
        STA SPRITE_RAM, x
        INX
        CPX #$10
        BNE Entity.LoadPlayer

    Entity.LoadEntityDone:
        RTS

Scene.DrawToBuffer:

    LDA #$00
    LDX #$00
    LDY #$00

Scene.DrawToBufferLoop

    LDA CurrentScene, y
    STA BufferAmount ; first value of currentscene is how many buffers in a scene

    INY
    LDA CurrentScene, y
    STA <ScenePtr
    INY
    LDA CurrentScene, y
    STA >ScenePtr

    LDA ScenePtr, x
    STA BufferToDraw ; first value of a metatile is their length

Scene.DrawToBufferLoop

    LDA ScenePtr, x
    STA GfxBuffer, x
    INX 
    CPX BufferToDraw
    BNE Scene.DrawToBufferLoop

    LDX #$00
    LDY #$00

    RTS

Scene.LoadBuffer:

    LDA #$00
    LDX #$00

    LDA GfxBuffer, x
    STA <BufferLength

    INX 
    LDA GfxBuffer, x
    STA >BufferLocation

    INX
    LDA GfxBuffer, x
    STA <BufferLocation

    LDA $2002
    LDA >BufferLocation
    STA $2006
    LDA <BufferLocation
    STA $2006
    INX
    TXA
    PHA  ; push A to stack for next buffer
    TAY

    LDA RLEMode
    BNE Scene.RunRLE

Scene.LoadBufferLoop:

    LDA GfxBuffer, y
    STA $2007
    INY
    CPY <BufferLength
    BNE Scene.LoadBufferLoop
    INX BuffersDone
    RTS

Scene.RunRLE:
    RTS

Scene.StartScene:

    LDA State
;   CMP #State.Main
;    BEQ Scene.MainScene

Title_Attr: ; Attr = Attribute table
    LDA $2002
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
    LDX #$00

Title_Attr.loop:
    LDA PAL0, x
    STA $2007
    INX
    CPX #$20
    BNE Title_Attr.loop

TitleScene:
    LDA $2002
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006
    LDA #$00
    STA BG0LO
    LDA #HIGH(BG0)
    STA BG0HI

    LDX #$00
    LDY #$00

TitleScene.loop:
    LDA [BG0LO], y
    STA $2007
    INY
    CPY #$00
    BNE TitleScene.loop
    INC BG0HI
    INX
    CPX #$04
    BNE TitleScene.loop

Scene.SceneSet.Title:
    RTS

Scene.MainScene:

Main_Attr:
    LDA $2002
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
    LDX #$00

Main_Attr.loop:
    LDA PAL1, x
    STA $2007
    INX
    CPX #$20
    BNE Main_Attr.loop

MainScene:
    LDA $2002
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006
    LDA #$00
    STA BG1LO
    LDA #HIGH(BG1)
    STA BG1HI

    LDX #$00
    LDY #$00

MainScene.loop:
    LDA [BG1LO], y
    STA $2007
    INY
    CPY #$00
    BNE MainScene.loop
    INC BG1HI
    INX
    CPX #$04
    BNE MainScene.loop

 Scene.SceneSet:
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Input.HandleInput:

    JSR Input.GetInput

;    LDA State
;    CMP #$00
;    BEQ Input.Title

Input.NotPressed:
    LDA #%00001111
    AND Controller_1
    BEQ Input.NotPressed_right
    LDA Controller_1
    AND #%00001000
    BEQ Input.NotPressed_up 

    LDA State
    CMP #$01
    BNE Input.Struct_up
    JSR Input.Pressed_up

Input.NotPressed_up:
    LDA Controller_1
    AND #%00000100
    BEQ Input.NotPressed_down

    LDA State
    CMP #$01
    BNE Input.Struct_down
    JSR Input.Pressed_down

Input.NotPressed_down
    LDA Controller_1    
    AND #%00000010
    BEQ Input.NotPressed_left
    LDA State
    CMP #$01
    BNE Input.Struct_left
    JSR Input.Pressed_left

Input.NotPressed_left:
    LDA Controller_1
    AND #%00000001
    BEQ Input.NotPressed_right
    LDA State
    CMP #$01
    BNE Input.Struct_right
    JSR Input.Pressed_right

Input.NotPressed_right:
    RTS

Input.Struct_up
        JSR Input.Pressed_up_Title
        JMP Input.NotPressed_up

Input.Struct_down
        JSR Input.Pressed_down_Title
        JMP Input.NotPressed_down

Input.Struct_left
        RTS

Input.Struct_right
        RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Input.Pressed_up:
    LDX #$00
    LDY #$00
    ; LDA PL_Y
    ; CMP #$0E 
    BNE Input.Pressed_up.loop
    RTS

Input.Pressed_up.loop
    CLC
    DEC OAMPlayerBaseAddr, x ; PLAYER_POS = SPRITETAB
    TXA
    ADC #$04
    TAX 
    INY
    CPY #$04
    BNE Input.Pressed_up.loop
    RTS 

Input.Pressed_down:
    LDX #$00
    LDY #$00
    ; LDA PL_Y
    ; CMP #$D7
    BNE Input.Pressed_down.loop
    RTS

Input.Pressed_down.loop
    CLC
    INC OAMPlayerBaseAddr, x
    TXA
    ADC #$04
    TAX
    INY
    CPY #$04
    BNE Input.Pressed_down.loop
    RTS

Input.Pressed_left:
    LDX #$03
    LDY #$00
    ; LDA PL_X
    ; CMP #$08
    BNE Input.Pressed_left.loop
    RTS

Input.Pressed_left.loop
    CLC
    DEC OAMPlayerBaseAddr, x
    TXA
    ADC #$04
    TAX
    INY
    CPY #$04
    BNE Input.Pressed_left.loop
    RTS

Input.Pressed_right:
    LDX #$03
    LDY #$00
    ; LDA PL_X
    ; CMP #$F8
    BNE Input.Pressed_right.loop
    RTS

Input.Pressed_right.loop
    CLC
    INC OAMPlayerBaseAddr, x
    TXA
    ADC #$04
    TAX
    INY
    CPY #$04
    BNE Input.Pressed_right.loop
    RTS

; tela de título

Input.Pressed_up_Title:
    LDX #$00
    LDY #$00
;    LDA PL_Y
;    CMP #$0E 
;    BNE Input.Pressed_up_Title.loop 
;    RTS

Input.Pressed_up_Title.loop
    CLC
    DEC PLAYER_POS, x ; PLAYER_POS = SPRITETAB
    TXA
    ADC #$04
    TAX 
    INY
    CPY #$04
    BNE Input.Pressed_up_Title.loop
    RTS 

Input.Pressed_down_Title:
    LDX #$00
    LDY #$00
;    LDA PL_Y
;    CMP #$D7
;    BNE Input.Pressed_down_Title.loop
;    RTS

Input.Pressed_down_Title.loop

    CLC
    INC PLAYER_POS, x
    TXA
    ADC #$04
    TAX
    INY
    CPY #$04
    BNE Input.Pressed_down_Title.loop
    RTS

Input.GetInput:

    LDA #$01
    STA $4016
    LDA #$00
    STA $4016
    LDX #$08
Input.GetInput.loop

    LDA $4016
    LSR A
    ROL Controller_1
    DEX
    BNE Input.GetInput.loop
    RTS

 .bank 1
 .org $E000

; CurrentScene:
;     .db $01, <BG_Floor, >BG_Floor, $01, <BG_Title, >BG_Title

PAL0: 
  .db $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F
  .db $22,$16,$27,$18, $0F,$1A,$30,$27, $22,$29,$29,$29, $22,$29,$29,$29

PlayerGraphicsTableOld:
   ;vert tile attr horiz
  .db $80, $32, $00, $80
  .db $80, $33, $00, $88
  .db $88, $42, $00, $80
  .db $88, $43, $00, $88

EntityTableAddr_LOW:
    .db <PlayerAttr, <GenEnemyAttr

EntityTableAddr_HIGH:
    .db >PlayerAttr, >GenEnemyAttr

PlayerAttr:
  .db $0D, ; how many entries to copy
  .db $01, PlayerPos_X_TopLeft, PlayerPos_Y_TopLeft ; first value is how many 4-pixel offsets horizontally and vertically from position
  .db $11, PlayerPos_X_TopRight, PlayerPos_Y_TopRight
  .db $00, PlayerPos_X_BottomLeft, PlayerPos_Y_BottomLeft
  .db $10, PlayerPos_X_BottomRight, PlayerPos_Y_BottomRight

PlayerGraphicsTable:
  .db $04,$20,$32,$33,$42,$43 ; idle anim

EnemyGraphicsTable:
  .db $70,$71,$72,$73

 .org $FFFA
 .dw NMI
 .dw Awake.Reset
 .dw 0

 .bank 2
 .org $0000
 
 .incbin "backgrounddata.chr"