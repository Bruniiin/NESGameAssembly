 .rsset $0000
Ptr001 .rs 1
Ptr002 .rs 1
Ptr003 .rs 1
Ptr004 .rs 1
Ptr005 .rs 1
Ptr006 .rs 1
Ptr007 .rs 1
Ptr008 .rs 1
Ptr009 .rs 1
Ptr0010 .rs 1
FrameCounter .rs 1
BufferCtrlReg .rs 1
TurnOffScreenTest .rs 1
SceCtrlReg .rs 1
RoomCtrlReg .rs 1
ChunkCtrlReg .rs 1
TileCtrlReg .rs 1
RoomLength .rs 1
PPUCTRL_REG1Mirror .rs 1
; PPUMASK_REG2Mirror .rs 1
ChunkAmountPerFrame .rs 1
TileIndexTempStore .rs 1
ChunkIndexTempStore .rs 1
CurrentRoomTempStore .rs 1
CurrentChunkTempStore .rs 1
CurrentSceneTempStore .rs 1
; ObjectIDTempStore .rs 1
TextMode .rs 1
TextLength .rs 1
ScrollUpdate .rs 1
SceneCondVar .rs 1
SceneCondTempStore .rs 1
PlayerPointer .rs 1
SceneLength .rs 1
; NmiTest .rs 1
ScrollHor .rs 1
ScrollHorTempStore .rs 1
ArithmeticTempStore .rs 1
RunSceCtrl .rs 1
ScrollVer .rs 1
ScrollOper .rs 1
; PlayerScore .rs 2
JmpAddressTempStore_LOW .rs 1
JmpAddressTempStore_HIGH .rs 1
MaxPlayerScore_HIGH .rs 2
PlayerPosHor .rs 1
PlayerHorTempStore .rs 1
PlayerPosVer .rs 1
PlayerVerTempStore .rs 1
ScrollHorVel .rs 1
PosOffsetHor .rs 1
PosOffsetVer .rs 1
ObjectStatus .rs 1
ObjectPositionTempStore .rs 1
PosOffsetEntriesToCopy .rs 1
; MainUpdateGuard .rs 1
RunMainUpdate .rs 1
SpriteLength .rs 1
SpriteCount .rs 1
ObjectAttribute .rs 1
; GameStatus .rs 1
PlayerStatus .rs 1 ; bit 1: is alive?, bit 2 and 3: is idle, walking, running or jumping? bit 4: are controllers enabled? bit 5: facing direction
PauseStatus .rs 1
InputStatus .rs 1
; LoadPlayerEntity .rs 1
ProgramMode .rs 1
; OperMode .rs 1
; CurrentLevel .rs 1
; State .rs 1
; CurrentBackground .rs 1
BaseOAMAddress_Player .rs 1
PseudoRandomTempStore .rs 1
PseudoRandomBitReg .rs 1
LowAddrTempStore .rs 1
HighAddrTempStore .rs 1
Controller_1 .rs 1
; ControllerP2 .rs 1
SceneReady .rs 1
CurrentScene .rs 1
; SpriteRamLocationLow .rs 1
CurrentBufferTempStore .rs 1
ScenePtr .rs 1
BufferAmount .rs 1
IndexRegTempStore .rs 1
IndexCtrlTempStore .rs 1
ObjectIndexRegTempStore .rs 1
ObjectIndexRegTempStore002 .rs 1
; VarTest1 .rs 1
ObjectRegTest .rs 1
OffsetTempStore .rs 1
BuffersDone .rs 1
BuffersToCopy .rs 1
CopyCounterTempStore .rs 1
; ObjectQueueOffsetStore .rs 1
ActiveObjectsList .rs 1
SpriteOffsetTempStore .rs 1
ReservedObjectOffsetStore .rs 1
ObjectTimer .rs 1
BufferStatus .rs 1
FrameDelay .rs 1
FrameDelayTest .rs 1
DisplayTimer .rs 1
SceneTimer .rs 1
GfxBufferOffset .rs 1
BufferCopyLimitPerFrame .rs 1
ResumeLoadBuffer .rs 1
ReadyForNextBuffer .rs 1
; GfxBuffer .ds 1
GfxBufferSize .rs 1
BufferToDraw .rs 1
BufferLength .rs 1
; BufferArea_LOW .rs 1
; BufferArea_HIGH .rs 1
RLEMode .rs 1
ReservedOAMTempStore .rs 1
OAMOffsetStore .rs 1
SpriteDataTempStore .rs 1
ActiveObjectHorTempStore .rs 1
ActiveObjectVerTempStore .rs 1
PlayerVelocityHor .rs 1
PlayerVelocityVer .rs 1
Lerp001 .rs 1

OAMAddressDefault = $0200
OAMAddress = $0204
ResetBootValid = $03
NametableAddr_001 = $01
GfxBuffer = $00C0
ChunkToTileIndexStore = $0400
SpriteDataIndexStore = $0500
SpriteDataTempQueue = $0510
ObjectSpriteOffset = $0450
ObjectSpriteLength = $0400
SpriteOffsetIndexStore = $0520
SpriteOffsetTempQueue = $0530
ActiveObjectQueue = $0550
ObjectRenderingQueue = $0580
ActiveObjectsHor = $0600
ActiveObjectsVer = $0610
SpriteOAMOffset = $04
OAMTest = $0200
OnScreenSpriteLimit = $08
; PLAYER_OAM_FALLBACK = $0204
; PLAYER_POS = $0200

; Object IDs

POINTER = $00
PROJECTILE = $01
PLAYER = $03 

; Hardware registers

SNDDELTA_REG = $4010
PPUCTRL_REG1 = $2000
PPUMASK_REG2 = $2001
PPUSTATUS_REG3 = $2002
OAMADDR_REG4 = $2003
OAMDATA_REG5 = $2004
PPUSCROLL_REG6 = $2005
PPUADDR_REG7 = $2006
PPUDATA_REG8 = $2007
OAMDMA_REG9 = $4014

; State.Main = $00 
; State.Title = $01
; StateExitGame = $02
; PL_Y       = $020C
; PL_X       = $020F
; TITLE_Y    = $020C
; TITLE_X    = $020F
; BG0LO .rs 1
; BG0HI .rs 1
; BG1LO .rs 1
; BG1HI .rs 1