Original CP/M 2.2 binaries.

To transfer programs, the SAVE command in the CCP was modified, briefly, so that
instead of saving from 0x100, it instead saves from 0x4000 to be compatible with
the monitor. From there it was necessary to convert LOAD and PIP to Intel hex
format, then transfer them individually using the monitor, to CP/M and using the
built-in SAVE command to save them to disk.

Then programs can be transfered by converting them to Intel hex format (starting
at 0x100), and piped over the serial connection (9600 baud is needed to avoid
dropped bytes) using the PIP program to save it to disk, ie:

pip <filename>.hex=con:

Then LOAD can be used to convert the Intel hex file to a program.
