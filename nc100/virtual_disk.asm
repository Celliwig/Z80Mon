; # Virtual disk routines
; ###########################################################################
;  A memory card can act as a virtual disk(s) for CP/M. A variety of disk sizes
;  can be supported 128k, 256k, 512k, and 1M depending on the size of the card.
;
;  Original spec:
;  --------------
;  The original disk specification was for a disk with a 128 bytes per sector,
;  26 sectors per track, and 73 tracks per disk. This gave a storage capacity
;  of 242944 bytes. The 1st 2 tracks in the original specification is reserved
;  for the system (CCP/BDOS/CBIOS) however. This is 0x1a00 (6656) bytes of data,
;  so in fact leaves a capacity of 236288 bytes.
;
;  Virtual disk:
;  -------------
;  To simplify the code, the original 128 byte sector size is retained.
;  The sectors per track is more than doubled to 0x2000 (8192) bytes, which
;  will waste storage in the system track, but make any address calculations
;  much easier. This can be double again for larger disk sizes where the wasted
;  storage will not be missed (much).
;
;   Disk Size   |  Sector Size  | Track Sectors |  Num. Tracks
;  -------------------------------------------------------------
;     128k      |   128 Bytes   |      32       |      32
;     256k      |   128 Bytes   |      32       |      64
;     512k      |   128 Bytes   |      32       |      128
;      1M       |   128 Bytes   |      64       |      128
;
;  Memory addressing:
;  Theoretical situation of accessing a 128k disk image starting at 0x0.
;
;   A16 | A15 | A14 | A13 | A12 | A11 | A10 |  A9 |  A8 |  A7 |  A6 |  A5 |  A4 |  A3 |  A2 |  A1 |  A0
;  ------------------------------------------------------------------------------------------------------
;           Tracks (32)         |    Sectors per Track (32)   |            Sector Bytes (128)
;
;  So to access (Track: 0x05 / Sector: 0x17):
;   A16 | A15 | A14 | A13 | A12 | A11 | A10 |  A9 |  A8 |  A7 |  A6 |  A5 |  A4 |  A3 |  A2 |  A1 |  A0
;  ------------------------------------------------------------------------------------------------------
;    0  |  0  |  1  |  0  |  1  |  1  |  0  |  1  |  1  |  1  |  X  |  X  |  X  |  X  |  X  |  X  |  X
;
;  Disk id:
;  --------
;  In the original spec. the first sector of the first track is reserved for the
;  cold start loader. This is not needed as the monitor will handle loading the
;  system track. This space is reused to store information about the virtual disk
;  image.
;
;               | Bytes |        Description
;  -------------------------------------------------
;  Magic Number |  16   | 0x2323232343504D564449534B23232323 (####CPMVDISK####)
;  Mem Size     |   1   | Total memory size in 32k blocks
;  Disk Number  |   1   | Disk number within memory
;  Disk Size    |   1   | Virtual disk size in 32k blocks
;  End Address  |   1   | Pointer to end of the disk (MSB: A23-A16)
;  Name		|  64   | ASCII description of the virtual disk, null terminated.
