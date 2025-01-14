Here are the UniFLEX kernel versions.

Your kernel may support the following devices:

c 0 x   ttyxx  tty ports 00...08

c 1 0   smem  kernel memory

c 1 1   pmem  virtual memory

c 2 0   null  EOF on read, 'Blackhole' on write

c 2 1   zero  read '0' bytes, no write

c 2 2   random read pseudo random numbers, no write

c 3 x   wcx   character drivers for IDE disks 0...7

c 4 0   hwgetset  helper device for portbaud,  get/set baudrate on serial ports

c 5 x   ttyxx  tty ports 09 and up, via IOP

c 6 x   fdc floppy character drivers

c 7 x   uio user I/O drivers

c 8     gpp debug ports
 
c 9     Econet(r) devices

c 10    loop-control

b 0 x   wx    block device  for IDE disks 0...7

b 1 X   loop  loop device

b 2 x   fd    block device for floppy disks


All files are in UniFLEX text format, use 'ufless' to access them from linux.
The .tar image contains the whole source for the CPU09 UniFLEX kernel, in UniFLEX text format

Mix/UF_IOP_200509.dsk.zip. It has the most recent driver source tree in it as the latest version of portbaud.
bootable kernels" uniflex (IDE basic version), uniflex2 (with IOP drivers in it)


2022-11-02:  usrc_63_20221102 is the most recent kernel tree. By settings options in .../mach_m1/sysconfig.h the 
user can select the desired kernel version. i.e. with or without IOP. 

It is advised to only boot a kernel which your hardware configuration (at boot time) supports,  other the boot may
'hang' because the kernel can't handle the interrupts that it sees on it's IO locations.

Mix/uf20200708.dsk.zip contains a few bootable kernels:
- uniflex               IDE kernel, supports CPU09SR4 boards
- uniflex1              same, backup of former
- uniflex2              IDE kernel with IOP support, IOP supports CPU09SR4 boards
- uniflex9              IDE kernel which drops straight in /bin/sh

Note: edit /ect/ttylist after booting, disable tty09...tty12 if you don't have IOP and reboot after

#######################################################################################
2020-12-30:

Uploaded Older/usrc_63A, this clean tree contains the most recent improvements as: 
* partition table is now located in system tables space. Each partition table is
(re) loaded when a drive/partition is opened the first time
* creating a file always strips the s+ bit from the perms.
* the idedrvr.t now supports 2 CPU09IDE boards (need the latest patches)
* the build system got some improvements, all files touched when the sysconfig.h 
has been changed will be rebuild now.
* the kernel interrupt-handler handles unused hardware somewhat better now

2021-01-26:

The image "basic_uf_sys2A.dsk.zip" holds the lastest kernel sources in /src and has already prepared new
boot images in the root directory. 

'uniflex' and 'uniflex1' are identical and support IDE and extra serial ports via CPU09SR4.
'uniflex2' supports IDE and IOP. So you can connect with serial ports via the CPU09IOP.
'uniflex4' supports IDE/IOP and FLP. Here you can connect a floppy drive via CPU09GPP/09FLP.

I have changed the naming of the hard disks:
W00,W01,W02,W03 are the first master, W10,W11,W12,W13 are the first slave
W20,W21,W22,W23 are the second master, W30,W31,W32,W33 are the second slave

The same goes for the character devices: WC00,WC01,WC02......WC31,WC32,WC33


*******************************************************************************************
2021-08-14:

Created Older/usrc_63B and uploaded uf_b_kern.tar in that directory. It provides a clean source
tree to build your own UniFLEX kernel. in .../mach_m1/sysconfig.h you can set what 
hardware is to be supported with your build. 
This kernel tree supports the 63X09<->68X09 transient of the CPU mode. The kernel runs
_always_ in 63X09 mode, but a user process may alter that setting. Leave the FIRQ setting
on 'long stackframe' when meddling with the LDMD register. Failing to do so may result
in your process crashing and  being terminated.
**** For this kernel you NEED the UniBUG_B version of the UniBUG ROM ****


*******************************************************************************************
2022-03-07:

Created Older/usrc_63C, this contains the recent status of all files. The Older directrory holds
'tar' versions of the previous versions.

ufsrc_20220307.tar is the tar archive, identical to the files in usrc_63C.
 
*******************************************************************************************
2022-06-11:

Added wd0_kees.dsk.zip. This is mostly the wd0 disk from Mike Evenson's memulator.
I replaced the uniflex versions, re-created the /dev directory, added a few programs.
===>>> in /ksrc on this image is the latest kermel source present. <<<===
I build the uniflex versions from this source tree, while running UniFLEX from an SD-card.


*******************************************************************************************
2022-11-02:

Published the present kernel state, source tree  
In this source I added the loop device driver as block major 1. That implies that the floppy
driver (and devices) now sit on block major 2. Check your /dev directory.
Also I corrected a few bugs in the iop_han.t code. Lastly, while testing the loop device driver,
I found a few bugs in the kernel code. Calling dobfio happened sometimes with the wrong device
major, also setting the read-ahead disk addresses ommited the DEVICE the read-ahead was to be
on, added also the device for the 'unxtb' settings.





