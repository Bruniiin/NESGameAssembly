 INCLUDE "defines/defines.inc"
 INCLUDE "src/metadata.asm"

 .inesprg 1
 .ineschr 1
 .inesmap 0
 .inesmir 1

 .bank 0
 .org $C000

Awake:
    SEI
    CLD
    LDA #$40
    STA $4017
    LDX #$FF
    TXS ; set up stack.
    INX
    STX PPUCTRL_REG1
    STX PPUMASK_REG2
    STX $4010
    AND #%00000110
    STA ProgramMode
    JSR Awake.BlankWait ; wait two empty frames.
    JSR Awake.BlankWait
    LDA #$00
    STA SNDDELTA_REG+1 
    JSR Awake.OAMReset
Awake.MemoryInit:
    LDA #$00
    STA $000, x
    STA $100, x
    STA $400, x
    STA $500, x
    STA $600, x
    STA $700, x
    INX
    BNE Awake.MemoryInit
    JMP Main
Awake.BootCheck:
    LDA MaxPlayerScore_HIGH
    BEQ Awake.ColdBoot
Awake.ColdBoot: ; page 3 holds data that will be saved upon reset
    LDA #$00
    STA $300, x 
    INX
    BNE Awake.ColdBoot
Awake.OAMReset:
    LDA #$FE
    STA $200, x
    INX
    BNE Awake.OAMReset
    RTS
Awake.BlankWait:
    BIT $2002
    BPL Awake.BlankWait
    RTS

Main:
    LDA #$40 ; set up vram buffer start offset, set as 40 (64 bytes long)
    STA GfxBufferSize
    LDA #$00
    STA DisplayTimer
    STA PlayerPointer
    LDA #$FF
    STA CurrentBufferTempStore
    STA CurrentSceneTempStore
    STA BufferCtrlReg
    LDA #$AF
    STA PlayerPosHor
    LDA #$47
    STA PlayerPosVer
    LDA #$04
    STA BaseOAMAddress_Player
    JSR LoadPalettesTest
    JSR Awake.BlankWait
    LDA #%00011110
    STA PPUMASK_REG2
    LDA #%10011000
    STA PPUCTRL_REG1
    STA PPUCTRL_REG1Mirror
    JSR Scene.ClearBuffer
    JSR Object.ClearAllObjects
    LDA POINTER
    STA ActiveObjectQueue
    INC ActiveObjectsList
Main.Wait:
    LDA RunMainUpdate
    BNE Main.Update
    JMP Main.Wait
Main.Update: 
    JSR BufferControl
    JSR PushUpdateToBuffer
    LDY FrameCounter
    JSR ProdRandomValue
    JSR Object.RenderObject
    DEC RunMainUpdate
    JMP Main.Wait

NMI:
    Nmi.Init:
        LDA #$00
        STA OAMADDR_REG4
        LDA #$02
        STA $4014
    Nmi.GfxBuffer:
    Nmi.GfxBufferHandling:
        LDA GfxBuffer
        BMI Nmi.ObjectHandling
        JSR Scene.LoadBuffer
        LDA FrameDelay
        BNE Nmi.Logic
        ; JSR StoreJmpToTempAddr ; allows the programmer to RTS to a different address than the original JSR
    Nmi.ObjectHandling:
        LDA BufferCtrlReg
        CMP #$01
        BCC Nmi.Logic
        LDA ReadyForNextBuffer
        CMP #$02
        BCC Nmi.Logic
        JSR Object.HandleObjects
        LDA PlayerPosHor
        STA ActiveObjectsHor
        LDA PlayerPosVer
        STA ActiveObjectsVer
    Nmi.Logic:
        JSR Player.HandlePhysics
        JSR HandlePause
        LDA PauseStatus
        LSR A
        BCS Nmi.HandleUi
        ; LDA ObjectStatus
        ; BEQ .
        JSR Input.HandleInput
        JSR HandleScrollReg
    Nmi.HandleUi:
        ; JSR HandlePauseUi
    Nmi.FrameUpdate: ; increments a variable once per frame, useful for RNG calculations and timers
        LDA ObjectTimer
        BEQ .
        DEC ObjectTimer
      .:INC FrameCounter
        INC DisplayTimer
    Nmi.GfxEnable:
        LDA #$00
        STA FrameDelay
        STA ScrollHorTempStore
        LDA PPUCTRL_REG1Mirror
        STA PPUCTRL_REG1
        INC RunMainUpdate
        ; LDA #%00011110
        ; STA PPUMASK_REG2        ; ready for the next frame.
    RTI

ProdRandomValue:
    TXA
    LSR A
    TAX
    LDA [$00], y
    STA PseudoRandomTempStore
    TXA
    ADC #PseudoRandomTempStore
    TAX
    STX PseudoRandomBitReg
    RTS

Object.MoveObjectQueue:
    INX 
    CPX #$04
    BNE Object.RenderObjectSetup
Object.RenderExit:
    RTS 
Object.RenderObject: ; i'm not 100% satisfied with this rendering method and will replace it with a separate sprite initialization and queueing system.
    LDX #$00
    LDY #$00
    STX SpriteDataTempStore
    STX SpriteOffsetTempStore
    STX OAMOffsetStore
    JSR Object.ClearOAM
Object.RenderObjectSetup:
    LDA ActiveObjectQueue, x
    BMI Object.MoveObjectQueue
    STX ObjectPositionTempStore
    TAX
    LDY #$00
    LDA ObjectAddress_LOW, x
    STA Ptr009
    LDA ObjectAddress_HIGH, x
    STA Ptr0010
    LDA [Ptr009], y
    STA SpriteLength
    ASL A
    STA ArithmeticTempStore 
    INY 
    LDA [Ptr009], y
    STA ObjectAttribute
    INY
    LDX ObjectPositionTempStore
    LDA ObjectSpriteOffset, x
    BEQ .
    LDA #$00
    CLC
    ADC #$02
    ADC ArithmeticTempStore
    TAY
    .:
    LDX #$00
Object.CopySpriteData:
    LDA [Ptr009], y
    STA SpriteDataTempQueue, x
    INX
    INY
    CPX SpriteLength
    BNE Object.CopySpriteData
    LDX #$00
Object.CopyOffsetData:
    LDA [Ptr009], y
    STA SpriteOffsetTempQueue, x
    INX
    INY
    CPX SpriteLength
    BNE Object.CopyOffsetData
Object.RenderObjectResume:
    LDX ObjectPositionTempStore
    LDA ActiveObjectsVer, x
    STA ActiveObjectVerTempStore
    LDA ActiveObjectsHor, x
    STA ActiveObjectHorTempStore
    JSR Object.CalcPosOffset
    LDX OAMOffsetStore
    LDY SpriteDataTempStore
Object.Render:
    LDA ActiveObjectVerTempStore
    STA OAMAddress, x
    INX
    LDA SpriteDataTempQueue, y
    STA OAMAddress, x
    INX
    LDA ObjectAttribute
    STA OAMAddress, x
    INX
    LDA ActiveObjectHorTempStore
    STA OAMAddress, x
    INC ObjectIndexRegTempStore
    INX 
    INY
    STX OAMOffsetStore
    STY SpriteDataTempStore
    CPY SpriteLength
    BNE Object.RenderObjectResume
    LDA #$00
    STA ObjectIndexRegTempStore
    STA SpriteDataTempStore
    LDX ObjectPositionTempStore 
    JMP Object.MoveObjectQueue

Object.HandleObjects:
    LDX #$00
    LDA ActiveObjectQueue
    BMI Object.HandleObjectsExit
Object.HandleObjectsLoop:
    LDA ActiveObjectQueue, x
    CMP #$FF
    BEQ .
    STX ObjectPositionTempStore
    TAY
    LDA ObjectRoutine_LOW, y
    STA Ptr007
    LDA ObjectRoutine_HIGH, y
    STA Ptr008
    JSR Object.JumpToPointerRoutine
    LDX ObjectPositionTempStore
    .:
    INX
    CPX #$08
    BNE Object.HandleObjectsLoop
Object.HandleObjectsExit:
    RTS
Object.JumpToPointerRoutine
    JMP [Ptr007]

Pointer:
    LDA ObjectTimer
    BNE NotPressed
    LDA Controller_1
    AND #%10000000 ; A button pressed
    BEQ NotPressed
    JSR Object.ReserveObject
    LDX ReservedObjectOffsetStore ; spawn new projectile instance
    LDA #$01
    STA ActiveObjectQueue, x
    LDA PlayerPosHor
    ADC #$04
    STA ActiveObjectsHor, x
    LDA PlayerPosVer
    STA ActiveObjectsVer, x
    LDA #$40
    STA ObjectTimer
    ChangeAnimationState:
    LDX ObjectPositionTempStore
    LDA #$01
    STA ObjectSpriteOffset, x
    NotPressed:
    RTS 
Projectile:
    LDX ObjectPositionTempStore 
    INC ActiveObjectsHor, x
    LDA PlayerVelocityHor
    BPL .
    INC ActiveObjectsHor, x
    .:
    LDA ActiveObjectsHor, x
    CMP #$FF
    BEQ DestroyProjectile
    LDA ActiveObjectsHor, x
    BEQ DestroyProjectile
    RTS
    DestroyProjectile:
    LDA #$FF
    STA ActiveObjectQueue, x
    STA ActiveObjectsHor, x
    STA ActiveObjectsVer, x
    LDA #$00
    STA ObjectSpriteOffset, x 
    RTS

Object.ReserveObject:
    LDX #$00
Object.ReserveLoop:
    LDA ActiveObjectQueue, x
    CMP #$FF
    BEQ .
    INX
    CPX #$10
    BNE Object.ReserveLoop
    RTS
    .:
    STX ReservedObjectOffsetStore
    RTS

Object.ClearObject:
    LDA #$FF
    STA ActiveObjectQueue, x
    STA ActiveObjectsHor, x
    STA ActiveObjectsVer, x
    LDA #$00
    STA ObjectSpriteOffset, x 
    RTS
Object.ClearAllObjects:
    LDA #$FF
    STA ActiveObjectQueue, x
    STA ActiveObjectsHor, x
    STA ActiveObjectsVer, x
    LDA #$00
    STA ObjectSpriteOffset, x 
    INX
    CPX #$10
    BNE Object.ClearAllObjects
    RTS

Object.ClearOAM:
    LDA #$FE
    STA OAMAddress, x
    INX
    CPX #$10
    BNE Object.ClearOAM
    LDX #$00
    RTS

    LDA #$FE
    STA OAMAddress, x
    INX
    LDA OAMAddress, x
    CMP #$FE
    BNE Object.ClearOAM
    LDX #$00
    RTS

Object.CalcPosOffset:
    LDY ObjectIndexRegTempStore
    LDA SpriteOffsetTempQueue, y
    AND #%11110000
    LSR A 
    LSR A
    LSR A
    LSR A 
    STA PosOffsetHor
    LDA SpriteOffsetTempQueue, y
    AND #%00001111
    STA PosOffsetVer
    
; horizontal pos

Object.CalcPosOffsetHorLoop:
    LDA PosOffsetHor
    BEQ Object.CalcPosOffsetVerLoop
    LDX #$00
Object.CalcPosOffsetHorAdd:
    LDA ActiveObjectHorTempStore
    CLC
    ADC #$04
Object.CalcPosOffsetHorTransfer:
    STA ActiveObjectHorTempStore
    INX
    CPX PosOffsetHor
    BNE Object.CalcPosOffsetHorAdd

; vertical pos

Object.CalcPosOffsetVerLoop:
    LDA PosOffsetVer
    BEQ Object.CalcPosOffsetDone
    LDX #$00
Object.CalcPosOffsetVerAdd:
    LDA ActiveObjectVerTempStore
    CLC
    ADC #$04
Object.CalcPosOffsetVerTransfer:
    STA ActiveObjectVerTempStore
    INX
    CPX PosOffsetVer
    BNE Object.CalcPosOffsetVerAdd
Object.CalcPosOffsetDone:
    RTS

Player.HandlePhysics: ; not yet using subpixels
    LDA PlayerVelocityHor
    CMP #$FF
    BNE CheckPositiveVelocityHor
    DEC PlayerPosHor
CheckPositiveVelocityHor:
    CMP #$01
    BNE CheckVelocityVer
    INC PlayerPosHor
CheckVelocityVer:
    LDA PlayerVelocityVer
    CMP #$FF
    BNE CheckPositiveVelocityVer
    DEC PlayerPosVer
CheckPositiveVelocityVer:
    CMP #$01
    BNE .
    INC PlayerPosVer
    .:
    LDA #$00
    STA PlayerVelocityHor
    STA PlayerVelocityVer 
    RTS

Object.TransferObject: ; WIP, not implemented. New objects are sent to a temporary queue one at a time and then transfered to the sprite queue in another routine to be rendered, instead of iterating from the object queue. This saves CPU time, but it's a bit advanced right now.
    LDX #$00
    LDY #$00
    STX SpriteDataTempStore
    STX SpriteOffsetTempStore
Object.TransferObjectSetup:
    LDA ActiveObjectQueue, x
    BMI Object.TransferObjectsExit
    STX ObjectPositionTempStore
    TAX
    LDY #$00
    LDA ObjectAddress_LOW, x
    STA Ptr009
    LDA ObjectAddress_HIGH, x
    STA Ptr0010
    LDA [Ptr009], y
    ; STA SpriteLength
    ; ASL A
    ; ASL A
    ; STA ArithmeticTempStore 
    INY 
    LDA [Ptr009], y
    STA ObjectAttribute
    INY
    LDX #$00
; Object.CopySpriteData:
    LDA [Ptr009], y
    STA SpriteDataTempQueue, x
    INX
    INY
    CPX SpriteLength
;     BNE Object.CopySpriteData
    LDX #$00
; Object.CopySpriteOffsetData:
    LDA [Ptr009], y
    STA SpriteOffsetTempQueue, x
    INX
    INY
    CPX SpriteLength
    ; BNE Object.CopySpriteOffsetData
Object.TransferObjectsExit:
    RTS

; Object.RenderObject: 
    LDA ObjectStatus
    BNE Object.RenderObjectPointToLocation 
    LDY #$00
    LDX PlayerPointer
    LDA ObjectAddress_LOW, x
    STA Ptr007
    LDA ObjectAddress_HIGH, x
    STA Ptr008
    LDA [Ptr007], y
    STA SpriteLength
    ASL A
    ASL A
    STA ArithmeticTempStore
    INY
    LDA [Ptr007], y
    STA ObjectAttribute
    INY
    LDX #$00
; Object.CopySpriteData:
    LDA [Ptr007], y
    STA SpriteDataIndexStore, x
    INX
    INY
    CPX SpriteLength
    ; BNE Object.CopySpriteData
    LDX #$00
; Object.CopySpriteOffsetData:
    LDA [Ptr007], y
    STA SpriteOffsetIndexStore, x
    INX
    INY
    CPX SpriteLength
    ; BNE Object.CopySpriteOffsetData
    INC ObjectStatus
    RTS
  Object.RenderObjectPointToLocation:
    ; LDX #$00
    LDY #$00
    STY ObjectIndexRegTempStore
    STY ObjectIndexRegTempStore002
    LDA SpriteOAMOffset
    STA Ptr007
    LDA #$02
    STA Ptr008 
    LDA PlayerPosHor
    STA PlayerHorTempStore
    LDA PlayerPosVer
    STA PlayerVerTempStore
; Object.RenderObjectSetup:
    JSR Object.CalcPosOffset
    LDX ObjectIndexRegTempStore
    LDY ObjectIndexRegTempStore002
Object.RenderObjectLoop:
    LDA PlayerVerTempStore
    STA [Ptr007], y
    INY 
    LDA SpriteDataIndexStore, x
    STA [Ptr007], y
    CPX SpriteLength
    ; BEQ Object.RenderObjectResume
    INX
    STX ObjectIndexRegTempStore
    ; TXA
    ; PHA
    ; TAX
; Object.RenderObjectResume:
    INY
    LDA ObjectAttribute
    STA [Ptr007], y
    INY
    LDA PlayerHorTempStore
    STA [Ptr007], y
    INY 
    STY ObjectIndexRegTempStore002
    CPY ArithmeticTempStore
    ; BNE Object.RenderObjectSetup
    LDA #$01
    STA ObjectStatus
    RTS

BufferControl:
    LDA RunSceCtrl
    BNE BufferControlResume
    LDA SceCtrlReg
    CMP CurrentSceneTempStore
    BEQ BufferControlExit
    LDX SceCtrlReg
    LDY #$00
    STX CurrentSceneTempStore
    LDA #$00
    STA DisplayTimer
    LDX SceCtrlReg
    LDA SceneController_LOW, x
    STA Ptr003
    LDA SceneController_HIGH, x
    STA Ptr004          
    LDA [Ptr003], y
    CLC 
    ADC #$03
    STA SceneLength 
    INY
    LDA [Ptr003], y
    STA SceneTimer
    INC RunSceCtrl
    INY 
    INY
    JMP BufferControlLoop
BufferControlResume:
    LDY IndexCtrlTempStore
BufferControlTimer:
    LDA SceneTimer
    BEQ BufferConditionControl ; allows change of scene from a condition being met in code (such as player presses button, player does something, etc.)
    LDA DisplayTimer
    CMP SceneTimer 
    BNE BufferControlExit
    LDA #$00
    STA DisplayTimer
    JMP BufferControlLoop
BufferConditionControl:
    LDA SceneCondVar
    CMP SceneCondTempStore
    BEQ BufferControlExit
    TAY
BufferControlLoop:
    LDA [Ptr003], y
    STA BufferCtrlReg
    INY
    CPY SceneLength
    BEQ BufferControlDone
BufferControlWait:
    STY IndexCtrlTempStore
BufferControlExit:
    RTS
BufferControlDone:
    DEC RunSceCtrl
    RTS

CheckForChunkUpdate:
    LDA RoomCtrlReg
    CMP CurrentRoomTempStore
    BNE PushMetadataToBufferInit
    LDA ChunkCtrlReg
    CMP CurrentChunkTempStore
    BNE PushMetadataToBuffer
    RTS

PushUpdateToBuffer:
    LDA BufferCtrlReg
    CMP CurrentBufferTempStore
    BEQ PushUpdateToBufferExit
    LDX BufferCtrlReg
    STX CurrentBufferTempStore
    TAX
    LDY #$00
    LDA NametableAddress_LOW, x
    STA Ptr001
    LDA NametableAddress_HIGH, x
    STA Ptr002
    LDA [Ptr001], y
    CLC
    ADC #$04
    STA BufferLength
PushUpdateToBufferLoop:
    LDA [Ptr001], y
    STA GfxBuffer, y
    INY
    CPY BufferLength
    BNE PushUpdateToBufferLoop
    LDA GfxBufferOffset
    ADC #BufferLength
    STA GfxBufferOffset
    ; INC BufferAmount
PushUpdateToBufferExit:
    RTS

PushMetadataToBufferInit:
    LDA RoomCtrlReg
    STA CurrentRoomTempStore
    LDA #$01
    STA ChunkCtrlReg
PushMetadataToBuffer:
    LDA ChunkCtrlReg
    CMP RoomLength
    BEQ PushMetadataToBufferExit
    LDX RoomCtrlReg
    LDA RoomPointer_LOW, x
    STA Ptr001
    LDA RoomPointer_HIGH, x 
    STA Ptr002
    LDA [Ptr001], y ; Room001Test
    INC A
    STA RoomLength
PushMetadataToBufferResume:
    LDA ChunkCtrlReg
    TAY
    LDA [Ptr001], y
    TAY
    LDA MetatileChunkPointer_LOW, y
    STA Ptr003
    LDA MetatileChunkPointer_HIGH, y
    STA Ptr004
    LDX #$00
    LDY #$00
CopyChunkData:
    LDA [Ptr003], y
    STA ChunkToTileIndexStore, y
    INY
    CPY #$04
    BNE CopyChunkData
    LDY #$00
ConvertChunkIndexToPointer:
    LDX ChunkToTileIndexStore, y
    LDA MetatilePointer_LOW, x
    STA Ptr003
    LDA MetatileChunkPointer_HIGH, x
    STA Ptr004
CopyMetatileData:
    LDA [Ptr003], y
    STA GfxBuffer, y
    INY
    CPY #$04
    BNE CopyMetatileData
    LDY ChunkIndexTempStore
    INY 
    STY ChunkIndexTempStore
    CPY #$04
    BNE ConvertChunkIndexToPointer
    INC ChunkAmountPerFrame
    INC ChunkCtrlReg
    CMP RoomLength
    BEQ PushMetadataToBufferDone
    LDA ChunkAmountPerFrame
    CMP #$08
    BEQ PushMetadataToBufferDone
    BNE PushMetadataToBufferResume
PushMetadataToBufferExit:
    RTS
PushMetadataToBufferDone:
    LDA #$00
    STA ChunkAmountPerFrame
    INC FrameDelay
    RTS

    ; LDA ChunkCtrlReg
    ; CMP #$02
    ; BCS PushMetadataToBufferResume
    ; STA TileCtrlReg
    ; STY TileIndexTempStore
    ; STA ChunkCtrlReg
    ; LDA ChunkCtrlReg

PushStringToBuffer:
    LDY #$00
    LDX #$00
    LDA StringAddress_LOW, x
    STA Ptr001
    LDA StringAddress_HIGH, x
    STA Ptr002
    LDA [Ptr001], y
    ADC #$04
    STA BufferLength
PushStringToBufferLoop:
    LDA [Ptr001], y
    STA GfxBuffer, y
    INY
    ; INX
    CPY BufferLength
    BNE PushStringToBufferLoop
    LDA GfxBufferOffset
    ADC BufferLength
    STA GfxBufferOffset
    INC BufferAmount
    INC BufferStatus
    RTS

LoadPalettesTest:
    LDA $2002
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
    LDX #$00
LoadPalettesTestLoop:
    LDA Palette001, x
    STA $2007
    INX
    CPX #$20
    BNE LoadPalettesTestLoop
    RTS

    ; AND #%10000000
    ; ROL A
    ; ROL A
    ; ORA #%10011000

HandleScrollReg:
    LDA ScrollHor
    STA PPUSCROLL_REG6
    LDA ScrollVer
    STA PPUSCROLL_REG6
HandleScrollRegExit:
    RTS
HandleScreenChange:
    INC ScrollHor
    LDA ScrollHor
    BNE ControlScroll
    LDA ScrollUpdate
    EOR #$01
    STA ScrollUpdate
    LDA #%10011000
    ORA ScrollUpdate
    STA PPUCTRL_REG1Mirror
ControlScroll:
    INC Lerp001
    LDA Lerp001
    AND #%10000000
    ; BEQ  
    LDA #$00
    STA Lerp001
    LDA ScrollHorVel
    CMP #$02
    ; BEQ 
    INC ScrollHorVel 
    LDA ScrollHor
    STA PPUSCROLL_REG6
    LDA ScrollVer
    STA PPUSCROLL_REG6
    RTS

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
    BEQ UiScrollSet
    RTS
HandlePauseUi:  
HandlePauseDone:
    RTS

Object.Update:

Object.SpawnEntity:
    LDA ScrollHor ; + 32
    CLC
    ADC #$32
    STA PlayerPosHor
    LDA #$DC
    STA PlayerPosVer
    INC InputStatus
Object.CalcPosOffsetSetup:
    LDA #$00
    LDX #$00
    LDY #$00
    LDA PlayerData, x
    STA PosOffsetEntriesToCopy

    ; CPY PosOffsetEntriesToCopy
    ; BNE Object.CalcPosOffset
   ;vert tile attr horiz

Object.LoadEntity:
    ; LDA GameStatus
    ; AND #$10000000
    BNE Object.SetPlayerPosition
    LDA #$04 ; $0204 = base offset. can change effortlessly if needed
    LDY #$FF
Object.FindEmptyOAMLoop:
    INX
    LDA OAMAddress, x
    CMP #$FE
    BNE Object.FindEmptyOAMLoop
    STA BaseOAMAddress_Player
    TXA
    TAY
Object.RenderPlayerSprite:
        LDX #$00
        LDA PlayerData, x
        CLC
        ADC #$02
        STA SpriteLength
        INX
        LDA PlayerData, x
        STA ObjectAttribute
        INX
        INY
Object.RenderPlayerSpriteLoop:
        LDA PlayerData, x
        STA OAMAddress, y
        INY
        LDA ObjectAttribute
        STA OAMAddress, y
        INX
        INY
        INY
        INY
        CPX SpriteLength
        BNE Object.RenderPlayerSpriteLoop
Object.SetPlayerPosition:
        LDA BaseOAMAddress_Player
        TAY
        INY
        LDX #$00
Object.SetPlayerPositionLoop:
        LDA PlayerData, x ; copy vertical
        STA OAMAddress, y
        INX
        INY
        INY
        INY
        LDA PlayerData, x ; copy horizontal
        STA OAMAddress, y
        INX
        INY
        CPX SpriteLength
        BNE Object.SetPlayerPositionLoop
Object.RenderPlayerDone:
        RTS
Object.OAMReserveSpaceLoop:
        LDA #$FE
        STA OAMAddress, x
        INX
        INY
        CPY #$04
        BNE Object.OAMReserveSpaceLoop
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

    Entity.LoadEntityLoop: ; old code, kept for debugging.
        LDA PlayerData, x
        STA OAMAddress, x
        INX
        CPX #$10
        BNE Entity.LoadEntityLoop
    Entity.LoadEntityDone:
        RTS

Scene.DrawToBuffer: ; old code
    LDA #$00
    LDX #$00
    LDY #$00
    LDA CurrentScene, y
    STA BufferAmount ; first value of currentscene is how many buffers in a scene.
    INY
    LDA CurrentScene, y
    STA ScenePtr
    INY
    LDA CurrentScene, y
    STA ScenePtr
    LDA ScenePtr, x
    STA BufferToDraw ; first value of a metatile is their length.
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
    LDA ResumeLoadBuffer
    BEQ Scene.LoadBufferInit
    LDX IndexRegTempStore
    LDY CopyCounterTempStore
    LDA HighAddrTempStore
    CMP #$23
    BEQ Scene.CheckLowAddr
Scene.LoadBufferResume: 
    LDA HighAddrTempStore
    STA $2006
    LDA LowAddrTempStore
    STA $2006
    JMP Scene.LoadBufferLoop
Scene.CheckLowAddr:
    LDA LowAddrTempStore 
    CMP #$C0
    BCC Scene.LoadBufferResume
Scene.JumpTable:
    LDA HighAddrTempStore
    CLC
    ADC #$01
    STA HighAddrTempStore
    LDA #$00
    STA LowAddrTempStore
    JMP Scene.LoadBufferResume
Scene.LoadBufferInit:
    LDX #$00
    LDY #$00
    LDA GfxBuffer, x
    CLC
    ADC #$04
    STA BufferLength
    INX 
    LDA GfxBuffer, x
    STA BuffersToCopy
    INX
    LDA $2002
    LDA GfxBuffer, x
    STA PPUADDR_REG7 ; VRAM High Address
    STA HighAddrTempStore
    INX
    LDA GfxBuffer, x
    STA PPUADDR_REG7 ; VRAM Low Address
    STA LowAddrTempStore
    INX
    STX IndexRegTempStore
    ; TXA
    ; PHA  ; push A to stack
    LDA GfxBuffer, x
    CMP #$FD
    BNE .
    INC TextMode
    ; PLA
    ; TAX
  .:LDA TextMode
    BNE Scene.TextModeSetup
    LDA RLEMode
    BNE Scene.RunLengthEncoding
    JMP Scene.WaitOneFrameBuffer
Scene.RunLengthEncoding:
Scene.TextModeSetup:
    INX
    INC IndexRegTempStore
Scene.CopyBuffer:
    ; PLA
    ; TAX
    ; PHA
Scene.LoadBufferLoop:
    LDA GfxBuffer, x
    STA $2007
    INX
    INC LowAddrTempStore
    BNE Scene.AddrTempOverflowCheck
    INC HighAddrTempStore
Scene.AddrTempOverflowCheck:
    LDA TextMode
    BNE Scene.WaitOneFrameBuffer
    CPX BufferLength
    BNE Scene.LoadBufferLoop
    INY
    CPY BuffersToCopy
    BNE Scene.WaitOneFrameBuffer
Scene.ExitBuffer:
    ; STA GfxBufferOffset
    LDA #$00
    STA ResumeLoadBuffer
    STA DisplayTimer
    STA TextMode
    STA TextLength
    INX
    LDA GfxBuffer, x
    BMI Scene.BufferTaskDone
    LDA GfxBufferOffset
    CLC
    ADC BufferLength
    INC ReadyForNextBuffer
    INC FrameDelay
    RTS
Scene.WaitOneFrameBuffer: ; if there is more than one buffer to copy OR bufferlength surpasses 32 bytes, wait one frame and resume.
    LDA #$01
    STA ResumeLoadBuffer
    LDA TextMode
    BNE .
    STY CopyCounterTempStore
    RTS
  .:CPX BufferLength
    BEQ Scene.ExitBuffer
    INC IndexRegTempStore
    RTS
Scene.BufferTaskDone:
    LDA #$00
    STA BuffersToCopy
    JSR Scene.ClearBuffer
    INC ReadyForNextBuffer
    RTS

StoreJmpToTempAddr:
    PLA
    STA JmpAddressTempStore_LOW
    PLA
    STA JmpAddressTempStore_HIGH
    PHA
    LDA JmpAddressTempStore_LOW
    PHA
    RTS
JmpToTempAddr:
    PLA
    PLA
    LDA JmpAddressTempStore_HIGH
    PHA
    LDA JmpAddressTempStore_LOW
    PHA
    RTS

Input.GetInput:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016
    LDX #$08
Input.GetInputLoop
    LDA $4016
    LSR A
    ROL Controller_1
    DEX
    BNE Input.GetInputLoop
    RTS

Scene.ClearBuffer:
    LDA #$FF
    LDX #$00
Scene.ClearBufferLoop:
    STA GfxBuffer, x
    INX
    CPX #$40
    BNE Scene.ClearBufferLoop
    ; INC A
    ; STA GfxBufferOffset
    ; DEC BufferStatus
    RTS

BufferCalcTest:
    LSR A
    INY  
    CPY BufferLength
    BNE BufferCalcTest
    STA BufferCopyLimitPerFrame
    RTS 

Scene.ClearScreen
    LDX #$00
    LDY #$00
    LDA $2002
    LDA #$00
    STA $2006
    LDA #$20
    STA $2006
    LDA #$24
Scene.ClearScreenLoop
    STA $2007
    INX
    CPX #$00
    BNE Scene.ClearScreenLoop
    INY
    CPY #$04
    BNE Scene.ClearScreenLoop
    RTS

; Scene.RunRLE:
;     RTS
; 
; Scene.StartScene:
;
;    LDA State
;   CMP #State.Main
;    BEQ Scene.MainScene

; Title_Attr: ; Attr = Attribute table
;    LDA $2002
;    LDA #$3F
;    STA $2006
;    LDA #$00
;    STA $2006
;    LDX #$00

; Title_Attr.loop:
;    LDA PAL0, x
;    STA $2007
;    INX
;    CPX #$20
;    BNE Title_Attr.loop

; TitleScene:
;    LDA $2002
;    LDA #$20
;    STA $2006
;    LDA #$00
;    STA $2006
;    LDA #$00
;    STA BG0LO
;    LDA #HIGH(BG0)
;    STA BG0HI
;
;    LDX #$00
;    LDY #$00

; TitleScene.loop:
;    LDA [BG0LO], y
;    STA $2007
;    INY
;    CPY #$00
;    BNE TitleScene.loop
;    INC BG0HI
;    INX
;    CPX #$04
;    BNE TitleScene.loop

; Scene.SceneSet.Title:
;    RTS

; Scene.MainScene:

; Main_Attr:
;    LDA $2002
;    LDA #$3F
;    STA $2006
;    LDA #$00
;    STA $2006
;    LDX #$00

; Main_Attr.loop:
;    LDA PAL1, x
;    STA $2007
;    INX
;    CPX #$20
;    BNE Main_Attr.loop

; MainScene:
;    LDA $2002
;    LDA #$20
;    STA $2006
;    LDA #$00
;    STA $2006
;    LDA #$00
;    STA BG1LO
;    LDA #HIGH(BG1)
;    STA BG1HI

;    LDX #$00
;    LDY #$00

; MainScene.loop:
;    LDA [BG1LO], y
;    STA $2007
;    INY
;    CPY #$00
;    BNE MainScene.loop
;    INC BG1HI
;    INX
;    CPX #$04
;    BNE MainScene.loop

; Scene.SceneSet:
;    RTS

Input.HandleInput:
    JSR Input.GetInput
Input.NotPressed:
    LDA #%00001111
    AND Controller_1
    BEQ Input.NotPressedRight
    LDA Controller_1
    AND #%00001000
    BEQ Input.NotPressedUp 
    JSR Input.PressedUp
Input.NotPressedUp:
    LDA Controller_1
    AND #%00000100
    BEQ Input.NotPressedDown
    JSR Input.PressedDown
Input.NotPressedDown
    LDA Controller_1    
    AND #%00000010
    BEQ Input.NotPressedLeft
    JSR Input.PressedLeft
Input.NotPressedLeft:
    LDA Controller_1
    AND #%00000001
    BEQ Input.NotPressedRight
    JSR Input.PressedRight
Input.NotPressedRight:
    RTS

Input.PressedUp:
Input.PressedUp.loop
    CLC
    DEC PlayerVelocityVer 
    RTS 
Input.PressedDown:
Input.PressedDown.loop
    CLC
    INC PlayerVelocityVer
    RTS
Input.PressedLeft:
Input.PressedLeft.loop
    CLC
    DEC PlayerVelocityHor
    DEC ScrollHor
    LDA ScrollHor
    CMP #$FF
    BNE .
    LDA ScrollUpdate
    EOR #$01
    STA ScrollUpdate
    LDA ScrollUpdate
    ORA #%10011000
    STA PPUCTRL_REG1Mirror
    .:
    RTS
Input.PressedRight:
Input.PressedRight.loop
    CLC
    INC PlayerVelocityHor
    INC ScrollHor
    LDA ScrollHor
    BNE .
    LDA ScrollUpdate
    EOR #$01
    STA ScrollUpdate
    LDA ScrollUpdate
    ORA #%10011000
    STA PPUCTRL_REG1Mirror
    .:
    RTS

    ; TXA
    ; ADC #$04
    ; TAX
    ; INY
    ; CPY #$01
    ; LDX #$03
    ; LDY #$00
    ; TXA
    ; ADC #$04
    ; TAX
    ; INY
    ; CPY #$01
; Input.Struct_up
;         JSR Input.Pressed_up_Title
;         JMP Input.NotPressed_up
; Input.Struct_down
;         JSR Input.Pressed_down_Title
;         JMP Input.NotPressed_down
; Input.Struct_left
;         RTS
; Input.Struct_right
;         RTS
    ; LDA PlayerStatus
    ; CMP #$01
    ; BNE Input.Struct_up
    ;    LDA State
    ;    CMP #$00
    ;    BEQ Input.Title
    ; LDA PL_Y
    ; CMP #$0E 
    ; BNE Input.Pressed_up.loop
    ; RTS
; tela de título
; Input.Pressed_up_Title:
;     LDX #$00
;     LDY #$00
;    LDA PL_Y
; Input.Pressed_up_Title.loop
;     CLC
;     DEC PLAYER_POS, x ; PLAYER_POS = SPRITETAB
;     TXA
;     ADC #$04
;     TAX 
;     INY
;     CPY #$04
;     BNE Input.Pressed_up_Title.loop
;     RTS 
; Input.Pressed_down_Title:
;     LDX #$00
;     LDY #$00
;    LDA PL_Y
;    CMP #$D7
;    BNE Input.Pressed_down_Title.loop
;    RTS
; Input.Pressed_down_Title.loop
;     CLC
;     INC PLAYER_POS, x
;     TXA
;     ADC #$04
;     TAX
;     INY
;     CPY #$04
;     BNE Input.Pressed_down_Title.loop
;     RTS

 .bank 1
 .org $E000

Palette001:
  .db $30,$30,$1A,$0F
  .db $22,$36,$17,$0F
  .db $22,$30,$21,$0F
  .db $22,$27,$17,$0F
  .db $0F,$16,$27,$18
  .db $0F,$30,$2A,$0F
  .db $22,$29,$29,$29
  .db $22,$29,$29,$29

NametableAddress_HIGH:
    .db HIGH(ScreenErase), HIGH(DevMessage001), HIGH(DevMessage002), HIGH(DevMessage003),HIGH(DevMessage004)
NametableAddress_LOW:
    .db LOW(ScreenErase), LOW(DevMessage001), LOW(DevMessage002), LOW(DevMessage003), LOW(DevMessage004)

SceneController_HIGH:
    .db HIGH(DevMessage)
SceneController_LOW:
    .db LOW(DevMessage)

ObjectAddress_HIGH:
    .db HIGH(InterfacePointerData), HIGH(ProjectileData), HIGH(PlayerData), HIGH(ExampleEnemy001Data), HIGH(ExampleEnemy002Data)
ObjectAddress_LOW:
    .db LOW(InterfacePointerData), LOW(ProjectileData), LOW(PlayerData), LOW(ExampleEnemy001Data), LOW(ExampleEnemy002Data)

ObjectRoutine_HIGH:
    .db HIGH(Pointer), HIGH(Projectile)
ObjectRoutine_LOW:
    .db LOW(Pointer), LOW(Projectile)

ObjectData_HIGH:
    .db HIGH(ObjectOrder)
ObjectData_LOW:
    .db LOW(ObjectOrder)

StringAddress_HIGH:
    .db HIGH(DevMessage001), HIGH(DevMessage002), HIGH(DevMessage003), HIGH(DevMessage004)
StringAddress_LOW:
    .db LOW(DevMessage001), LOW(DevMessage002), LOW(DevMessage003), LOW(DevMessage004)

MetatilePointer_HIGH:
  .db HIGH(Terrain_Metatile), HIGH(Terrain_LeftMetatile), HIGH(Terrain_RightMetatile)
MetatilePointer_LOW:
  .db LOW(Terrain_Metatile), LOW(Terrain_LeftMetatile), LOW(Terrain_RightMetatile)

MetatileChunkPointer_HIGH:
  .db $FF, HIGH(MetatileChunk001)
MetatileChunkPointer_LOW:
  .db $FF, LOW(MetatileChunk001)

RoomPointer_HIGH:
  .db $FF, HIGH(Room001Test)
RoomPointer_LOW:
  .db $FF, LOW(Room001Test)

MetatileChunk001:
  .db $01,$00,$00,$02

ObjectOrder: ; the first byte defines the object's type, the second defines its parameters, and the third and fourth defines the starting x and y position on the screen. ; first byte defines the x/y position of the object. the upper second byte defines the object's type, the lower second byte is for parameters.
    .db $00,$00,$AF,$37

Room001Test:
  .db $02
  .db $01,$01
    ; will add a paramater with true/false values, including if to draw buffer to edge of scroll and
    ; updated vertically instead (for scrolling games, similar to SMB. (https://www.youtube.com/watch?v=UepNwgFJ83k&t=208s).

DevMessage:
    .db $05,$60,$00 ; length of bytes, time between updates, true/false parameters
    .db $00,$01,$02,$03,$04

ScreenErase:
    .db $20,$3C,$20,$00 ; length, copies, high nametable address, low nametable address
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
DevMessage001:
    .db $0E,$01,$21,$28 
    .db $12,$17,$24,$0D,$0E,$1F,$0E,$15,$18,$19,$16,$0E,$17,$1D,$2B
DevMessage002:
    .db $0D,$01,$21,$A9
    .db $FD,$19,$15,$0E,$0A,$1C,$0E,$24,$20,$0A,$12,$1D,$AF
DevMessage003:
    .db $27,$01,$22,$26
    .db $FD,$16,$0E,$0A,$17,$20,$11,$12,$15,$0E,$F5,$24,$1D,$1B,$22,$24,$16
    .db $18,$1F,$12,$17,$10,$24,$22,$18,$1E,$1B,$24,$0C,$18,$17,$1D,$1B
    .db $18,$15,$15,$0E,$1B,$AF
DevMessage004:
    .db $05,$01,$25,$CE
    .db $CF,$02,$00,$02,$04

PlayerData:
    .db $04,%00000010
    .db $32,$33,$42,$43 ; idle anim. first is how many bytes to copy, second is the palette.
    .db $00,$10,$01,$11 ; sprite offsets from original position
InterfacePointerData:
    .db $01,%00000001
    .db $2B,$00
    .db $F4,$00
ProjectileData:
    .db $01,%00100001
    .db $28
    .db $00
ExampleEnemy001Data:
    .db $04,$20
    .db $70,$71,$72,$73
ExampleEnemy002Data:
    .db $04,$20
    .db $70,$71,$72,$73

 .org $FFFA
 .dw NMI 
 .dw Awake
 .dw 0
 .bank 2
 .org $0000
 .incbin "chr/patterndata.chr"

; obsolete code
    ; AND #%00010000
    ; STA PPUMASK_REG2
    ; AND #%10000000
    ; STA PPUCTRL_REG1
; GameState.SetState: 
    ; LDA State
    ; BEQ GameState.Main
; GameState.Title:
    ; JSR Entity.LoadStart
    ; JSR Scene.StartScene
    ; JSR Scene.DrawToBuffer
    ; JMP Main
; GameState.Main:
    ; JSR PushStringToBuffer
    ; JSR Entity.LoadEntityLoop
    ; LDA BuffersDone
    ; CMP #$01
    ; BNE Main.Wait
    ; CMP FrameCounter 
    ; BEQ Main.Wait
    ; LDA BufferStatus ; check if buffer is empty, if so, skip
    ; BNE Nmi.IgnoreRender
; obsolete entity code
    ; LDA #$00
    ; ORA #%00000001
    ; STA GameStatus
    ; LDA GameStatus
    ; AND #%00000001
    ; BNE Entity.SpawnPlayerDone
    ; AND #%10000001
    ; BEQ Entity.SpawnPlayerDone
    ; LDA #$00
    ; STA PlayerStatus
    ; CurrentScene:
    ;     .db $01, <BG_Floor, >BG_Floor, $01, <BG_Title, >BG_Title
    ;PlayerGraphicsTableOld:
    ;   ;vert tile attr horiz
    ; .db $80, $32, $00, $80
    ; .db $80, $33, $00, $88
    ; .db $88, $42, $00, $80
    ; .db $88, $43, $00, $88
    ;PlayerData:
    ; .db $0D ; how many entries to copy
    ; .db $01, PlayerPos_X_TopLeft, PlayerPos_Y_TopLeft ; first value is how many 4-pixel offsets horizontally and vertically from position
    ; .db $11, PlayerPos_X_TopRight, PlayerPos_Y_TopRight
    ; .db $00, PlayerPos_X_BottomLeft, PlayerPos_Y_BottomLeft
    ; .db $10, PlayerPos_X_BottomRight, PlayerPos_Y_BottomRight
    ; STY OffsetTempStore
    ; PHA
    ; LDA $2002
    ; STA BufferArea_LOW
    ; STA BufferArea_HIGH
    ; LDA BufferArea_LOW
    ; LDA BufferArea_HIGH
    ; CPY BuffersToCopy
    ; BNE Scene.CopyBuffer
    ; PLA
    ; PLA
    ; STA IndexRegTempStore
    ; LDA PlayerStatus
    ; AND #%11111110
    ; BNE Nmi.Render
    ; JSR Object.SpawnEntity
    ; JMP Nmi.Render