# Z80Mon
A generic Z80 monitor developed as a replacement for the Amstrad NC100 ROM with the goal being, among others, to be able run CP/M.

## Introduction
Growing up my first computing experiences was on a Sinclair Spectrum 48K. I have fond memories of sitting in front of the machine typing in strange alphanumerics (hex machine code) from a magazine (YS) to produce a program that could be saved off, and hopefully run (it had a parity byte for each line, but that didn't always save you from a mistake ;) ). Fast forward several decades, a Comp. Sci. degree, and many years spent as a programmer, I have'd a hankering to revisit my technological roots. While I've no wish to restart the schoolyard wars of which computer (and by association which CPU) is best, I've found over the years that the Z80 is pretty sensible, at least compartively, to it's contemporaries. Comparing Z80 assembler with 8080 assembler, which are machine code compatible (8080->Z80, not the other way round necessarily), the Z80 I find is more readable. While I still have my old machine, I wanted to experiment with something a little more portable and not reliant on external equipment (monitor and PSU). There are several projects available to those that wish to relive the 8 bit age, ranging from quite basic single board computers to rack systems having potentially every possible interface available. For this first foray into the past I wanted to keep the expenditure as low as possible, at least in monetary terms if not time. So looking around on Ebay it was apparent that the cheapest available option was the Amstrad NC100 (approx. £15 with postage), note that while their are excellent SBC PCBs available which will cost you less than a NC100 you also have to factor in sourcing additional parts. One reason the NC100 was so cheap was that it was listed as 'spares/repair' as it wouldn't power on. A little research revealed that the device is a little weird in that it's barrel power connector is centre negative, while most PSUs are center positive. If you were to connect one of these PSUs, there's no diode protection/rectification and it'd almost certainly do a lot of damage (possibly terminal)  to the machine. There is however a fuse in the power circuitry which blows before there's a chance to do critical damage, but it is also inline with the battery feed so the device will appear dead to the world. Thankfully having received my machine, a quick inspection reveal that said fuse had indeed blown, so one wire link later and it's back up and running :). Let the fun begin. :grin:

## Amstrad NC100
One of the reasons why I selected the NC100 is that it's hardware is quiet well known [1]. While it was developed as a tool for people on the move who were expected to be complete computer novices, it has been taken up (and apart) by people with a passion for machines. So what do you get?

* CPU: 4 MHz CMOS Z80 compatible
* RAM: 64K byte SRAM
* RAM Expansion: PCMCIA/JEIDA Memory Cards (PC-Cards) Type I
* ROM: socketed 256K Custom ROM
* Extras: RTC
* Display: 480x64 pixel (80x8 characters) LCD
* Keyboard: 64 key keyboard (with decent travel)
* Ports: Parallel Centronics, Serial RS232
* Power: PSU, or 4 x AA (doesn't recharge from PSU)

Overall impressions? Nice machine for the age (released in 1992), my only particular irk is that the LCD is in a fixed position, would have been nicer if you could pitch the screen towards you. As it is, you end up hunching over it or proping the entire thing at an angle. The Dreamwriter 100 is basically the same machine, there they have slanted the LCD but at the expense of it being fixed as a wedge of plastic at the back. Not sure which solution I prefer to be honest...

## Monitor
So the point of all this (or at least part of it) was to reacquaint myself with Z80 assembler. I could jump right in and use one of the many Z80 monitors available, or write my own. Now I always think the best way to learn is to do, so writing my own was the way forward. However, even with a project that is as simple (in theory) as a monitor there are countless decisions to make which can bog you down when all you want to do is write code. So I decided to port, in as much as was applicable, an excellent monitor that I'd used before [2] in a previous project [3]. 

A suitable assembler was needed with preferably macro and conditional support, so z80asm was chosen as it includes both and is in the Debian/Ubuntu repositories. Next, some method of loading test binaries was required because constantly removing/burning/inserting a ROM is both tiresome and can soon mangle both the socket, and the ROM. Thankfully binary images can be transfered [4] easily over a serial link (I used minicom on linux), then saved and run from a SRAM PCMCIA card. [Note, the serial port on NC100 is full spec. RS232, not TTL level, using a TTL level serial adapter would probably destroy the serial adapter.] Unfortunately trying to find a suitable PCMCIA card can be hit and miss as they aren't readily available on Ebay, and they're generally not cheap. Thankfully I had a spare which I had acquired many years previous and had been lanquashing at the bottom of a drawer (for once hoarding old dross pays off!). To run code from the memory card it has to be prepended with a header [4], so having fashioned a suitable code stub (nc100_memcard_sideload.asm), and a test payload, attempts were made to run the code from the SRAM card. It didn't work! After spending sometime trying to debug the problem, made more interesting by the machine having obviously no debugging tools apart from BASIC, I found that removing the "NC100PRG" from the header made it work, obviously firmware differences there. So with the ability to sideload code, I could start coding in earnest. Not much to comment about the development itself, start with the I/O routines and then add features as required. One interesting feature of the monitor design is that it supports modules, this allows the monitor to be ported to different platforms and additional commands to be added (at compile time and run time), without altering the monitor source itself. Two in particular are important, the system init and startup modules. System init, as the name implies is there to initialise the system. In this case the Z80 is executing from ROM with no RAM available, so the first job is to page in some RAM and configure the stack. Up to this point any associated subroutines have to be able to execute without a stack (this required using IX as a store for the return pointer, see 'module_find' subroutine). After that the rest of the system is initialised and then it executes a 'rst 8' which is used to classify a warm boot. It's at that point that the startup module (if it's there) is called, which in this case restores the configuration from the RTC RAM. 

## Flash ROM mod
During the development of the monitor, it matured to stage where it could be self hosting, so the next stage was to source a programmble ROM. An EPROM would be the obvious choice, but having used flash ROM DIP parts previously this was the preferable route having the potential to allow for in system programming. So back to Ebay and an AMD AM29F040 [5] was sourced (this is a 5V 512K x 8 flash ROM). The pin configuration of the ROM socket needs to altered to accommodate the flash device, namely A18 needs to be moved from pin 31 to pin 1 and !WE (write enable) is needed on pin 31. Thankfully the machine was built to accomdate a number of different ROM devices, so these particular pins are assignable, just not in the way the designers envisaged (original configurations of J301,J302,J303,J304 [1]). So by removing the existing configuration:

And crosslinking a set of pads, A18 can be routed to pin 1. 

Now write enable is needed for pin 31 and, obviously, this is not available in the original configuration. It can be sourced from the RTC which is close by, so running a wire from RTC pin 11, to socket pin 31 the mod is complete.

After that it was time to write some code to the ROM, and here is where things get a little weird. While trying to burn the ROM, the programming software exited with an error. On further examination it turned out the manufacture/device ids didn't match the expected values. To start with I was expecting this to be a problem with the device programmer or it's software (it's a fairly expensive device, but errors can happen), hoping the device wasn't a dud. Having checked the values listed in the AMD datasheet and the ROM in a second device, both sides were right and both sides were wrong. So a little more investigation revealed that the manufacturer/device code was for a Spansion part of the same size but with a different product code. Spansion and AMD are related, so is this a case of a manufacturing error? Or is it that somebody has faked the markings (for the more popular/recognisable AMD component) on the I.C. which does happen?  Who know's? Programming it as a Spansion part proceeded without error, so after plugging it in and powering on the device I was reward with the monitor interface. Excellent!

So what features are available in the monitor?

* Download/Upload to memory (Intel Hex format)
* Display/Edit/Clear/Run memory
* Read/Write Ports
* Print registers, set stack pointer

The implementation on the NC100 provides support for:

* Keyboard & LCD
* ROM/RAM/SRAM PCMCIA
* Serial
* RTC
* Setup command which includes
 * RTC date/time/alarm
 * LCD invert & console redirection (to serial port)
 * Memory page selection 
 * Serial port configuration (baud, etc)
 * Status information (including battery)
* Flash programmer

## CP/M

Note: Work in progress!!!

With the monitor in a stable state, attention was turned to trying to get CP/M [6] to run. CP/M is a disk operating system that was designed to try and solve the problem of early home computer systems which was incredibly disparate hardware. While software written for one particular machine could in theory run on another machine if they have the same CPU, differences in hardware running the gamut of the controllers including keyboard, display, disk and even memory made software quite bespoke for a system. CP/M tries to unify all of this by hiding terminal (keyboard & display) and disk operations behind a BIOS (Basic Input/Output System) which CP/M then intergrates with to provide a basic DOS. It's something that influenced the development of the IBM PC and MSDOS several years later. Whilst I have used both AmigaDOS and MSDOS, I was interested to try this earlier system and see how it compared.

There are a few sites on the web that have information on CP/M, the best one is probably 'The Unofficial CP/M Web Site' [7]. Here you'll find a collection of resources, including original binaries, source and manuals. CP/M v2.2 appears to be the most sensible starting place for authenticity (there are several extension of CP/M), features and simplicity of BIOS. The first thing you should probably do is RTFM [8], especially the section 'CP/M 2 Alteration' which details the alterations needed for a new system. So the main task is to write a BIOS for the particular harware, this comprises the functions:

* boot - cold start initialisation
* wboot - warm start initialisation
* const - console in status
* conin - console in read
* conout - console output character
* list - list device output character (printer)
* punch	- punch device character out (tape)
* reader - reader device character in (tape)
* home	- move head to home position, track 00, on selected disk
* seldsk	- select a disk drive
* settrk	- set track number for selected disk
* setsec	- set sector number for selected disk
* setdma - set memory address to read/write data
* read - read disk sector to memory
* write - write memory to disk sector
* listst - return list device status
* sectran - disk sector translation

Knowing this it is time to consider hardware. While the monitor supports the keyboard & LCD, the serial interface was chosen as the console device for CP/M as it is much simpler to interface with especially in regard to the graphical LCD (as opposed to character LCD displays). Disks are the next issue, or the lack of them more precisely. While it is in theory possible to connect a disk drive to the serial port (see RangerDisk drives), this is more than a litle ugly and reliant on media that can be several decades old. A more sensible approach would be to use the PCMCIA SRAM card I already had and emulate floppy/hard drives which is precisely what I did. The SRAM card I have is 512KB, while the hardware supports upto 1 MB. Looking at the various disk sizes of the time, they tend to be in the range of 100s of kilobytes. By choosing a base block size of 64k for a virtual disk, a number of virtual disks can be made on an SRAM card that vary in size depending on need. Obviously some additional information needs to be stored if a card is to be split into multiple virtual devices. Handily though CP/M expects the first sector of the first track to contain the boot loader which isn't needed (as it'll be ROM), so this can be reused to store device information (see 'nc100/virtual_disk.asm'). The first job then is to create an admin tool for the monitor that can initialise the SRAM card, create/delete/format virtual disks and get/put system track ('nc100/virtual_disk_admin.asm'). With this done attention could be turned to the BIOS. The serial device is initialised by the monitor, so only the I/O routines are needed and these reuse the existing monitor library. The disk access routines are a little trickier, they need to copy data to/from the SRAM card which is mapped in the memory space on top of CP/M's memory (the system RAM) to a DMA buffer set by CP/M which can be anywhere barring the upper space allocated to the command processor, DOS routines and BIOS. One way to solve this problem is to buffer it first in an additional buffer in the BIOS area, before remapping the memory back to it's normal configuration and doing a second copy to the actual DMA space according to CP/M. The problem with this is that it involves two copies, however this is done at the speed of the system RAM which is (usually) operating much faster than any storage device so the impact is not noticable. When CP/M shipped as a product it was distributed in binary form which had to be patched for your machine, this was to update both BIOS section and also to pointly ammend where the CCP/BDOS/BIOS segment loaded (according to how much RAM you had). These days, with the source available, it is much easier. You just need to set the memory address of where the CCP/BDOS should load [8], and append your BIOS when assembling. Having created the aforementioned binary, this can then be transfered to the monitor where it can be saved to a virtual disk (PUTSYS). Loading this binary from the virtual disk (GETSYS) to the correct memory address [8], and jumping to the code will, if everythings right give you a prompt on the serial port (you need to be running the monitor with console redirection on a terminal).

At this point I should probably point out the major bug with running CP/M on the NC100, the power switch triggers a NMI, the vector for which is in the middle of CP/M's FCB storage so interpreting that as code is a bad idea! I have written a small bit of code to power off the system when you're in CP/M, don't use the power switch. Others have coded around the problem in different ports to the system, this however requires quite a few changes to the disk code where as I want to keep the code base as original as possible.

At this point there's a working CP/M installation, but it can't do much as you have no tools and there isn't even a way to transfer programs manually (kind of). The built-in 'SAVE' command has potential, it can save a specified number of 256 byte blocks to disk. So transfering a binary to RAM with the monitor, and then running CP/M and using 'SAVE' solves this right? Wrong! 'SAVE' has a fixed starting point of 0x0100, which is in the middle of the monitor so no help. But if you change the value of TBASE to 0x8000 (which is in RAM from the monitor's perspective) on an initial build of the CCP/BDOS/BIOS blob. You can then transfer the commands 'PIP' and 'LOAD' using this method, and then do a final build of the CP/M blob reverting TBASE to it's original value. With these two programs you can then proceed to transfer others by converting them to Intel Hex format, using 'PIP' you can save that to file (in your terminal emulator do a text file transfer of the a hex file) and then use 'LOAD' to turn the hex file back into a binary. Cumbersome. So having done that for a few files you'll want to find an actual terminal transfer program, I used 'MBOOT'. Now it was fun time! Having rustled up a copy of ZORK 1, I proceed to do a playthough which was interesting if frustrating at times :).

Here the project has stalled for a bit. One feature I would like get done is intergrate the onboard keyboard and LCD, as using a serial console is unwieldy. RAM is also something I would potentially look at. The NC100 is kitted out with 2x32k static RAM devices, but there is an upgraded version (with the same PCB) the NC150 with a single 128k RAM device. Not sure how easy it would be to source a suitable RAM chip, but the added RAM would be good especially for playing with CP/M 3 (Plus). Another problem was lack of disk space, even with the small size of CP/M programs the SRAM card was starting to run out of space. One partial solution is to use some of the unused space in the flash ROM, several disk image could be stored there (the disk system was designed to support this). However, a larger card of some sort would be the way forward. One solution might be to use the parallel port to drive the unused address lines on the PCMCIA interface which are currently grounded to support a larger SRAM card. Another option could potentially be a flash PCMCIA card, which in theory might be compatible, but they tend to require a PCMCIA type II slot while the NC100 is a type I. Of note is the fact that the card slot plastic surround is detachable and so that might be replaced with one that supports type II cards (which would help as electrically the slots are the same, I think).  I have to admit I'm kind of tempted by an NC200 which is similar hardware in a laptop style case, so has a bigger backlit display and floppy drive (which is a power hog, but could be replaced by a GOTEK drive). Unfortunately, unlike the NC100, they go for silly money on Ebay, I'm not pay >£100 for Z80 system which hasn't even a bus interface.

So an interesting journey, which is not over, merely on hiatus... I hope ;)

## Build
To build the monitor with a list file (useful for after the fact compilation against new targets):

z80asm -o z80mon.hex z80mon.asm nc100/nc100_lib.asm nc100/vdisk_utils.asm nc100/flash_tool.asm -L 2>z80mon.lst

To build the CP/M system binary(CCP/BDOS/BIOS):
z80asm -o cpm2.2/cpm22.hex cpm2.2/cpm22.def cpm2.2/cpm22.z80 cpm2.2/cbios.asm

To convert binary objects so that they can be transfered:

objcopy -v -I binary -O ihex <filename>.hex <filename>.ihex

## Resources
1. Emulator - https://www.ncus.org.uk/files/NC100EM-1.3.TAR.GZ

## References
1. https://www.cpcwiki.eu/index.php?title=A_surgical_guide_to_the_Amstrad_NC
2. https://www.pjrc.com/tech/8051/paulmon2.html
3. https://github.com/Celliwig/Oyster-Terminal
4. The Amstrad Notepad Advanced User Guide [Robin Nixon]: Writing External Programs
5. https://robotics.ee.uwa.edu.au/eyebot5/doc/DataSheets/29F040.pdf
6. https://en.wikipedia.org/wiki/CP/M
7. http://www.cpm.z80.de/
8. http://www.cpm.z80.de/manuals/cpm22-m.pdf
