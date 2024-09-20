 .rsset $0000
FrameCounter .rs 1
State .rs 1
CurrentBackground .rs 1
BG0LO .rs 1
BG0HI .rs 1
BG1LO .rs 1
BG1HI .rs 1
Controller_1 .rs 1
Controller_2 .rs 1
SceneReady .rs 1
ScenePtr .ds 1
BufferPtr .ds 1
BufferAmount .rs 1
BuffersDone .rs 1
GfxBuffer .ds 1
BufferToDraw .ds 1
BufferLength .ds 1
BufferLocation .ds 1
RLEMode .rs 1

State.Main = $00 
State.Title = $01
StateExitGame = $02

PL_Y       = $020C
PL_X       = $020F
TITLE_Y    = $020C
TITLE_X    = $020F
PLAYER_POS = $0200
SpriteAddress = $0200