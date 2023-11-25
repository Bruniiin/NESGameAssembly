 INCLUDE "const.inc"
; INCLUDE "HEADER.inc"
 INCLUDE "chr.asm"

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

    LDX #$40
    STX $4017

    LDX #$FF
    TXS

    INX
    STX $2000
    STX $2001
    STX $4010

Awake.ClrMem:
    
    LDA #$00
    STA $00,  x
    STA $100, x
    STA $300, x
    STA $400, x
    STA $500, x
    STA $700, x
    LDA #$FE
    STA $200, x
    INX
    BNE Awake.ClrMem

; Main

    LDA #State.Title

GameState.Start: ; Nota: deve-se botar o background primeiro antes de habilitar NMI, ao botar outro, desabilita NMI e etc.

    STA State
    LDA State
    CMP #$00
    BEQ GameState.Main

GameState.Title:

    JSR Scene.StartScene
    JSR Awake.BlankWait

GameState.Main:

    JSR Entity.LoadPlayer
    JSR Scene.StartScene
    JSR Awake.BlankWait

Main.NmiEnable:

    LDA #$90 ; #%10010000
    STA $2000 ; #%00011110
    LDA #$1E
    STA $2001

Main: ; Loop principal

    LDA FrameCounter ; Frame counter é framerate (60 vezes por segundo);

    Main.Wait:
        CMP FrameCounter
        BEQ Main.Wait

    JMP Main

NMI:

Nmi.Awake:
    LDA #$00
    STA $2003
    LDA #$02
    STA $4014

    LDA #%10010000
    STA $2000
    LDA #%00011110
    STA $2001
    LDA #$00
    STA $2005
    STA $2005

    Nmi.Main:
        
        JSR Input.HandleInput

    Nmi.FrameUpdate:
        INC FrameCounter
            
    RTI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Entity.LoadPlayer:
    LDA ENTITY0, x
    STA SpriteAddress, x
    INX
    CPX #$10
    BNE Entity.LoadPlayer
    RTS

Scene.StartScene:

    LDA State
    CMP #State.Main
    BEQ Scene.MainScene

TitlePal:
    LDA $2002
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
    LDX #$00

TitlePal.loop:
    LDA PAL0, x
    STA $2007
    INX
    CPX #$20
    BNE TitlePal.loop

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
;   BEQ Scene.SceneSet

Scene.MainScene:

MainPal:
    LDA $2002
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
    LDX #$00

MainPal.loop:
    LDA PAL1, x
    STA $2007
    INX
    CPX #$20
    BNE TitlePal.loop

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
    INC BG0HI
    INX
    CPX #$04
    BNE MainScene.loop

Scene.SceneSet:
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Input.HandleInput:

    JSR Input.GetInput

Input.NotPressed:
    LDA #%00001111
    AND Controller_1
    BEQ Input.NotPressed_right ; se nenhum dos botões foram pressionados volta para Nmi
    LDA Controller_1
    AND #%00001000
    BEQ Input.NotPressed_up
    JSR Input.Pressed_up

Input.NotPressed_up:
    LDA Controller_1
    AND #%00000100
    BEQ Input.NotPressed_down
    JSR Input.Pressed_down

Input.NotPressed_down
    LDA Controller_1
    AND #%00000010
    BEQ Input.NotPressed_left
    JSR Input.Pressed_left

Input.NotPressed_left:
    LDA Controller_1
    AND #%00000001
    BEQ Input.NotPressed_right
    JSR Input.Pressed_right

Input.NotPressed_right:
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Input.Pressed_up:
    LDX #$00
    LDY #$00
    LDA PL_Y ; analisa as coordenadas e impede o jogador de atravessar a borda da tela, LDA CMP RTS
    CMP #$0E 
    BNE Input.Pressed_up.loop ; inicializa  movimentação para cima caso jogador não esteja na borda da tela
    RTS

Input.Pressed_up.loop
    CLC
    DEC PLAYER_POS, x ; PLAYER_POS = SPRITETAB
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
    LDA PL_Y
    CMP #$D7
    BNE Input.Pressed_down.loop
    RTS

Input.Pressed_down.loop
    CLC
    INC PLAYER_POS, x
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
    LDA PL_X
    CMP #$08
    BNE Input.Pressed_left.loop
    RTS

Input.Pressed_left.loop
    CLC
    DEC PLAYER_POS, x
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
    LDA PL_X
    CMP #$F8
    BNE Input.Pressed_right.loop
    RTS

Input.Pressed_right.loop
    CLC
    INC PLAYER_POS, x
    TXA
    ADC #$04
    TAX
    INY
    CPY #$04
    BNE Input.Pressed_right.loop
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;








 .bank 1
 .org $E000

PAL0: ; paleta de title, paleta de cima e de baixo são 16 bytes(2) = 32 
  .db $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F
  .db $22,$16,$27,$18, $0F,$1A,$30,$27, $22,$29,$29,$29, $22,$29,$29,$29

PAL1: 
  .db $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F
  .db $22,$16,$27,$18, $0F,$1A,$30,$27, $22,$29,$29,$29, $22,$29,$29,$29

ENTITY0:
  .db $80, $32, $00, $80
  .db $80, $33, $00, $88
  .db $88, $42, $00, $80
  .db $88, $43, $00, $88

 .org $FFFA
 .dw NMI
 .dw Awake.Reset
 .dw 0

 .bank 2
 .org $0000
 
 .incbin "mario.chr"