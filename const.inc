 .rsset $0000
FrameCounter .rs 1
ScrollHor .rs 1
ScrollOper .rs 1
PlayerScore .rs 2
MaxPlayerScore .rs 2
PlayerStatus .rs 1
PlayerPosHor .rs 1
PlayerPosVer .rs 1
PosOffsetHor .rs 1
PosOffsetVer .rs 1
PlayerAttr .rs 1
PosOffsetColumnsToCopy .rs 1
SpriteLength .rs 1
SpritePallette .rs 1
GameStatus .rs 
PlayerStatus
PauseStatus .rs 1
InputStatus .rs 1
LoadPlayerEntity .rs 1
ProgramMode .rs 1
CurrentLevel .rs 1
State .rs 1
CurrentBackground .rs 1
BaseOAMAddress_LOW .rs 1
PseudoRandomBitReg .rs 1
BG0LO .rs 1
BG0HI .rs 1
BG1LO .rs 1
BG1HI .rs 1
Controller_1 .rs 1
Controller_2 .rs 1
SceneReady .rs 1
CurrentScene .ds 1
SpriteRamLocationLow .rs 1
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
ResetBootValid = $03

PL_Y       = $020C
PL_X       = $020F
TITLE_Y    = $020C
TITLE_X    = $020F
PLAYER_POS = $0200
SPRITE_RAM = $0200
SPRITE_RAM_OFFSET = $04
SNDDELTA_REG = $4010
SNDMASTER_CTRL_RE
PPUCTRL_REG1 = $2000
PPUMASK_REG2 = $2001
PPUSTATUS_REG3 = $2002
OAMADDR_REG4 = $2003
OAMDATA_REG5 = $2004
PPUSCROLL_REG6 = $2005
PPUADDR_REG7 = $2006
PPUDATA_REG8 = $2007
OAMDMA_REG9 = $4014

PLAYERPTR = $01
ENEMYPTR = $02