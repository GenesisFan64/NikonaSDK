@ECHO OFF
CLS
set AS_MSGPATH=tools/AS/win32
set USEANSI=n

echo *** Building EMULATOR-ONLY ROMs ***
echo ** GENESIS **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/emu/rom_emu_md.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=0,PICO=0,EMU=1
"tools/AS/win32/p2bin" -p=00 main.p "out/emu/rom_emu_md.bin"
echo ** SEGA 32X **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/emu/rom_emu_mars.lst" -q -xx -A -L -D MCD=0,MARS=1,MARSCD=0,PICO=0,EMU=1
"tools/AS/win32/p2bin" -p=00 main.p "out/emu/rom_emu_mars.32x"
echo ** SEGA PICO **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/emu/rom_emu_pico.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=0,PICO=1,EMU=1
"tools/AS/win32/p2bin" -p=00 main.p "out/emu/rom_emu_pico.bin"
echo ** SEGA CD **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/emu/rom_emu_mcd_j.lst" -q -xx -A -L -D MCD=1,MARS=0,MARSCD=0,PICO=0,EMU=1,CDREGION=0
"tools/AS/win32/p2bin" -p=00 main.p "out/emu/rom_emu_mcd_j.iso"
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/emu/rom_emu_mcd_u.lst" -q -xx -A -L -D MCD=1,MARS=0,MARSCD=0,PICO=0,EMU=1,CDREGION=1
"tools/AS/win32/p2bin" -p=00 main.p "out/emu/rom_emu_mcd_u.iso"
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/emu/rom_emu_mcd_e.lst" -q -xx -A -L -D MCD=1,MARS=0,MARSCD=0,PICO=0,EMU=1,CDREGION=2
"tools/AS/win32/p2bin" -p=00 main.p "out/emu/rom_emu_mcd_e.iso"
echo ** CD32X **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/emu/rom_emu_marscd_j.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=1,PICO=0,EMU=1,CDREGION=0
"tools/AS/win32/p2bin" -p=00 main.p "out/emu/rom_emu_marscd_j.iso"
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/emu/rom_emu_marscd_u.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=1,PICO=0,EMU=1,CDREGION=1
"tools/AS/win32/p2bin" -p=00 main.p "out/emu/rom_emu_marscd_u.iso"
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/emu/rom_emu_marscd_e.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=1,PICO=0,EMU=1,CDREGION=2
"tools/AS/win32/p2bin" -p=00 main.p "out/emu/rom_emu_marscd_e.iso"

echo *** Building REAL HARDWARE ROMs ***
echo ** GENESIS **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/realhw/rom_md.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=0,PICO=0,EMU=0
"tools/AS/win32/p2bin" -p=00 main.p "out/realhw/rom_md.bin"
echo ** SEGA 32X **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/realhw/rom_mars.lst" -q -xx -A -L -D MCD=0,MARS=1,MARSCD=0,PICO=0,EMU=0
"tools/AS/win32/p2bin" -p=00 main.p "out/realhw/rom_mars.32x"
echo ** SEGA PICO **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/realhw/rom_pico.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=0,PICO=1,EMU=0
"tools/AS/win32/p2bin" -p=00 main.p "out/realhw/rom_pico.bin"
echo ** SEGA CD **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/realhw/rom_mcd_j.lst" -q -xx -A -L -D MCD=1,MARS=0,MARSCD=0,PICO=0,EMU=0,CDREGION=0
"tools/AS/win32/p2bin" -p=00 main.p "out/realhw/rom_mcd_j.iso"
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/realhw/rom_mcd_u.lst" -q -xx -A -L -D MCD=1,MARS=0,MARSCD=0,PICO=0,EMU=0,CDREGION=1
"tools/AS/win32/p2bin" -p=00 main.p "out/realhw/rom_mcd_u.iso"
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/realhw/rom_mcd_e.lst" -q -xx -A -L -D MCD=1,MARS=0,MARSCD=0,PICO=0,EMU=0,CDREGION=2
"tools/AS/win32/p2bin" -p=00 main.p "out/realhw/rom_mcd_e.iso"
echo ** CD32X **
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/realhw/rom_marscd_j.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=1,PICO=0,EMU=0,CDREGION=0
"tools/AS/win32/p2bin" -p=00 main.p "out/realhw/rom_marscd_j.iso"
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/realhw/rom_marscd_u.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=1,PICO=0,EMU=0,CDREGION=1
"tools/AS/win32/p2bin" -p=00 main.p "out/realhw/rom_marscd_u.iso"
"tools/AS/win32/asw" main.asm -i "%cd%" -olist "out/realhw/rom_marscd_e.lst" -q -xx -A -L -D MCD=0,MARS=0,MARSCD=1,PICO=0,EMU=0,CDREGION=2
"tools/AS/win32/p2bin" -p=00 main.p "out/realhw/rom_marscd_e.iso"

IF EXIST main.p del main.p
REM IF EXIST main.h del main.h
