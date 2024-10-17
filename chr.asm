; CHR
 
 .bank 1 ; PRG-ROM 2
 .org $E000

BG_Floor:

  .db $10,$23,$40,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85,$85

Terrain_Metatile:

  .db $B2,$B2
  .db $B4,$B4

Terrain_LeftMetatile:

  .db $B0,$B1
  .db $B3,$B4

Terrain_RightMetatile:

  .db $B2,$B3
  .db $B4,$B5 

Terrain_Chunk_HIGH:

  .db >Terrain_Metatile,>Terrain_RightMetatile

Terrain_LeftChunk_LOW:

  .db <Terrain_LeftMetatile,<Terrain_Metatile

Terrain_LeftChunk_HIGH:

  .db >Terrain_LeftMetatile,>Terrain_Metatile

Terrain_RightChunk_LOW:

  .db <Terrain_Metatile,<Terrain_RightMetatile

Terrain_RightChunk_HIGH:

  .db >Terrain_Metatile,>Terrain_RightMetatile

Terrain_Chunk_LOW:

  .db <Terrain_Metatile,<Terrain_Metatile