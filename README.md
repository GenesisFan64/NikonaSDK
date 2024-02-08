# NikonaSDK
A SDK in pure assembly for the SEGA 16-bit console famly of systems: Genesis, Sega CD, Sega 32X, Sega CD32X and Sega Pico.

- Sega Genesis and Sega 32X roms are tested on real hardware.
- Sega CD, Sega CD32X and Sega Pico are UNTESTED as I don't have either Sega CD or the Sega Pico (There's no flashcarts for Pico anyway)

Prebuilt binaries are located in the /out folder for testing, ROMs are built separately for use on Emulator and Real Hardware. (ares-emu can run Real Hardware roms, still not 100% perfect for 32X)

NTSC speed only, no PAL optimization done at all.

Code targets a modified version of AS Macro Assembler by Flamewing and a custom version of P2BIN by Clownacy, The AS assembler and P2BIN executables go to these directories depending of the system:

- Windows: tools/AS/win32
- Linux: tools/AS/linux
