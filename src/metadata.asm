; CHR
 
 .bank 1 ; PRG-ROM 2
 .org $F000

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

  .db HIGH(Terrain_Metatile),HIGH(Terrain_RightMetatile)

Terrain_LeftChunk_LOW:

  .db LOW(Terrain_LeftMetatile), LOW(Terrain_Metatile)

Terrain_LeftChunk_HIGH:

  .db HIGH(Terrain_LeftMetatile),HIGH(Terrain_Metatile)

Terrain_RightChunk_LOW:

  .db LOW(Terrain_Metatile),LOW(Terrain_RightMetatile)

Terrain_RightChunk_HIGH:

  .db HIGH(Terrain_Metatile),HIGH(Terrain_RightMetatile)

Terrain_Chunk_LOW:

  .db LOW(Terrain_Metatile),HIGH(Terrain_Metatile)