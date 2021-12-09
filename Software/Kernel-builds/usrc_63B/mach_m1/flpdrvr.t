        opt     nol        lib     ../include/flpdrvr.h        lib     ../include/blktab.h        lib     ./gendrvr.h        opt     lis,exp        if      (FLP=1)        sttl     Floppy Drivers        pag        name    flpdrvr        global  flpopen,flpclos,flpio,flpirq        global  flopen,flclos,flread,flwrit,flspcl        global  flpdt* Device Tables** dtdfl rmb     2       device buffer fwd link* dtdbl rmb     2       device buffer bwd link* dtqfl rmb     2       device io queue fwd link* dtqbl rmb     2       device io queue bwd link* dtbusy        rmb     1       device busy flag* dtrtry        rmb     1       device error retry count* dtspr rmb     2       device spare byteflpdt   rzb     DVTSIZ          device table*FDtable fdb     0               Block Device Table addressflpwrk  fdb     0,0,0,0,0,0flpcur  fcb     0flpopt  fcb     0,0,0,0        flp open tableflpsts  fcb     0,0,0,0        side flagsflpstd  fcb     0,0,0,0        dens flags** open the flp disk drive - insure the device is online, etc.* B contains device minor*flpopen pshs    d        ldx     #flpopt        lda     b,x        beq     flpop2        inc     b,x        bra     flpop3*flpop2  jsr     flopen          do character open stuff        lda     #1        sta     flpdpr+flnwop  new open** try to read disk as 8" SD, 8" DD, 5" SD and 5" DD* As we want to read the SIR, which is block 1 there is no* worry about side select. If SIR is read, the real SIDE/SIZE/DENS* info is taken from the SIR*flpop7  ldd     0,s             get device#        bsr     frdsir          read SIR SD/8"        beq     flpop4        clr     uerror        jsr     freebf          free the buffer*        ldx     #flpstd         density info        ldd     0,s             get device#        lda     b,x        eora    #%00000001        sta     b,x             toggle dens*        ldd     0,s             get device# again        bsr     frdsir          read SIR DD/8"        beq     flpop4          no error        clr     uerror        jsr     freebf*        ldx     #flpstd         density info        ldd     0,s             get device#        lda     b,x        eora    #%00000001        sta     b,x             toggle dens*        ldx     #flpsts         5/8" info        ldd     0,s        lda     b,x        eora    #%01000000      5/8" select        sta     b,x        anda    #%01000000      done already        bne     flpop7*        lda     #EIO            set IO error        sta     uerror        ldx     #flpopt         reset open        ldd     0,s        clr     b,xflpop3  puls    d,pc            retunr*flpop4  pshs    y               save buffer        ldx     0,s             buf ptr        ldy     #flpwrk         data location        ldu     #sdenf          offset in SIR        ldd     #2              2 bytes(ttyget/set)        jsr     cpybts        ldd     2,s             device#        ldx     #flpsts        abx        lda     flpwrk+1        sta     0,x             side info        lda     flpwrk        sta     4,x             dens info        puls    y        jsr     freebf        puls    d,pc* flp closeflpclos        ldx     #flpopt*       dec     b,x             dec open counter*       bpl     flpcl1        clr     b,x             clear open statusflpcl1  rts                     return** frdsir, read floppy SIR into a buffer*frdsir  ldx     #1        ldy     #0        jsr     rdbuf        lda     bfflag,y        bita    #BFERR        rts** fire up FLP operation to initiate transfer* Y = buf header*flpio   stx     FDtable         save Block Device Table address        inc     flpdt+dtbusy    mark busy        ldb     bfdvn+1,y       get device #        stb     flpdpr+fldriv        ldu     #flpdpr*        lda     #1              set func        sta     flpdt+dtrtry        ldx     #flpsts         side table        abx        lda     0,x        sta     fltsid,u        lda     4,x             get dens flpstd        sta     fltden,u*        lda     bfflag,y        R/W* 'standard' sizes 128/256/512        ldx     bfxfc,y         get transfer count        stx     fltsiz,u        TOTAL size09      sta     flrflg,u        bita    #BFSPC        bne     flnsrw          non standard size** single block read/write*        bita    #BFRWF        bne     02f             read=1, go wait** write, transfer data to FIFO*        pshs    b,x,u        ldd     bfxfc,y        cmpd    #BUFSIZ         max data xfer in DPR        bls     01f        ldd     #BUFSIZ01      std     fltxfr,u        actual xfer        trfr    D,W        tfr     y,x             map buffer and        jsr     mapbpt          X points now to SBUFFER @ OFFSET        leau    flpfifo,u        tfm1    X,U            transfer data from buffer to system space        puls    b,x,u** read, send command, in interrupt data is there (or not)*02      lda     bfblch,y        BLOCK# H/M/L        sta     flblkh,u        ldd     bfblck,y        std     flblkm,u*        lda     #$ff        sta     flptel,u        rts*01      lda    #EBDEV        sta    uerror        lda    bfflag,y        ora    #BFERR        sta    bfflag,y*flpfin  clr     flpdt+dtrtry    erase function        rts** look here for large write chunks*flnsrw  ldx     #0        stx     fltxfr,u        init transferred data counter        bita    #BFRWF          bulk READ data in IRQ        bne     02b             direction flag** flrwflg holds the command and direction* for BULK write, put first block here* next data blocks via IRQ*        pshs    b,x,u           +5, save registers        tfr     y,x             map buffer and        jsr     mapbpt          X points now to SBUFFER @ OFFSET        pshs    d               +2, make space        ldd     bfxfc,y         check for SIZE        cmpd    #BUFSIZ        bls     14f        ldd     #BUFSIZ14      std     0,s        addd    fltxfr,u        adjust transferred        std     fltxfr,u        ldd     bfxfc,y         deduct what we did now        subd    0,s        std     bfxfc,y        ldd     bfadr,y         adjust memory pointer        addd    0,s        std     bfadr,y        bcc     12f        inc     bfxadr,y12      pulsw                   -2, count        leau    flpfifo,u       floppy buffer18      tfm1    X,U            transfer data from/to buffer to system space        puls    b,x,u          -5        bra     02b** IRQ, here something has been done (success or fail)*flpirq  equ     *        ldu     #flpdpr        clr     flpint,u          set we saw it*        ldy     flpdt+dtqfl     get last transaction        beq     flpfin        ldb     flstat,u             result        bne     flprr1*        lda     bfflag,y        bita    #BFSPC          special action        bne     flirrw** single block transfers, Write= done, Read is get data*        bita    #BFRWF          read=1        beq     03f             for write we're finished** interrupt context, be careful, buffer may be in use*        ldb     DATBOX+SBUF     save DAT setting        pshs    b,x,u        ldd     bfxfc,y        cmpd    #BUFSIZ         max data xfer        bls     10f        ldd     #BUFSIZ10      trfr    D,W        std     fltxfr,u        tfr     y,x             map buffer and        jsr     mapbpt          X points now to SBUFFER @ OFFSET        leau    flpfifo,u        tfm1    U,X            transfer data from system to buffer        puls    b,x,u        stb     DATBOX+SBUF    restore DAT setting** for write, we're done*03      bra     flpdon* handle errorsflprr1  stb     bfstat,y        lda     bfflag,y        ora     #BFERR        sta     bfflag,y        bitb    #%01000000     write protect        beq     01f        lda     #EPRM        bra     02f01      bitb    #%00010000     not found        beq     03f        lda     #EBADF        bra     02f03      lda     #EIO02      sta     uerror*flpdon  clr     flpdt+dtbusy    set unbusy        clr     flpdt+dtrtry    clear funtion        ldx     FDtable        jmp     BDioend** BULK data transfer* for Write, tranfer next data block(s)**flirrw  equ     *        anda    #BFRWF        pshs    a               direction flag        beq     09f* BULK Read        ldd     fltxfr,u        what we got already        cmpd    fltsiz,u        set by read command        bhs     11f* BULK  Read/Write09      ldd     bfxfc,y         any data ?        bne     10f*11      leas    1,s             clean stack        bra     flpdon** common code for Read/Write*10      cmpd    #BUFSIZ        bls     02f        ldd     #BUFSIZ* transfer next block02      trfr    D,W            count        pshs    d              +2        addd    fltxfr,u        tell how much we did        std     fltxfr,u*        ldb     DATBOX+SBUF     save old value        pshs    b,x,u          +5        tfr     y,x             map buffer and        jsr     mapbpt          X points now to SBUFFER @ OFFSET        leau    flpfifo,u        tst     7,s        beq     14f            read: DPR -> mem        excg    U,X            write: mem -> DPR14      tfm1    X,U            data between buffer and system space        puls    b,x,u          -5, leave old W in stack        stb     DATBOX+SBUF*        ldd     bfxfc,y        process data done        subd    0,s            always less then 65K        std     bfxfc,y        ldd     bfadr,y        update buffer pointer        addd    0,s++          -2, correct stack        std     bfadr,y        bcc     06f        inc     bfxadr,y*06      puls    a               cleanup stack        lda     #$ff        sta     flptel,u        rts**  character open*flopen  equ     *        ldx     #flpopt        cmpb    #1        bhi     flchop4        tst     b,x        bne     flchop5 don't touch settings        inc     b,x        ldx     #flpsts        abx        clr     0,x     clear side/size info        clr     4,x     clear dens info        bra     flchop5*flchop4 lda     #EBARG        sta     uerrorflchop5 rts** character close*flclos  jmp     flpclos** flchrd*flread  equ     *        pshs    d       save device number        ldy     #fchbuf        jsr     blkgtb  get device buffer        puls    d        jsr     fchcn   configure buffer        tst     uerror  OK?        beq     fchrd4        pshs    y        ldy     #fchbuf        jsr     blkfrb  free the buffer        puls    y,pc    error returnfchrd4  pshs    a       save task mode byte        orb     #BFRWF  set read        stb     bfflag,y save        bra     fchio** flchwr*flwrit  equ     *        pshs    d       save device info        ldy     #fchbuf        jsr     blkgtb  get device buffer        puls    d        jsr     fchcn   configure        tst     uerror  OK        beq     fchwr4        pshs    y        ldy     #fchbuf        jsr     blkfrb  free the buffer        puls    y,pc    error returnfchwr4  pshs    a       save task mode bytefchio   ldb     #FLmajor        jmp     blkcio** fchcn** Configure the buffer header pointed at by Y.* This routine sets up the character device info* from the user block and puts it in the buffer* header such that the device drivers can use* the informationfor the transfer* this routine is specific for the floppy driver*fchcn   std     bfdvn,y save device info        ldd     uicnt   xfr count        std     bfxfc,y        cmpd    #128    check valid numbers        beq     fcnch4        cmpd    #256        beq     fcnch4        cmpd    #512        beq     fcnch4** above are valid sector sizes*        pshs    x        ldx     #tsztabfcnctb  cmpd    0,x++        beq     fcnch2        tst     0,x        bne     fcnctb        puls    x*fcnch8  lda     #EBARG  set error        sta     uerror        rts*fcnch2  puls    x        ldd     uistrt   (big) buffer aligned at 512        bitdi   $01ff    byte boundary?        bne     fcnch8*        lda     bfflag,y        ora     #BFSPC  special bit for drivers        sta     bfflag,y*fcnch4  jmp     blkcnf** valid track sizes* 5" SD, 8" SD, 5" DD, 8" DD, HD, (legay) 5" SD, 8" SD, 5" DD, 8" DD, HD RTRK*tsztab  fdb     3125,5187,6250,10375,12500,3050,5100,6100,10200,12200,12500,0** flspcl*flspcl        tfr     x,y        ldx     #flpsts         side info table        abx                     correct entry        cmpy    #0        bne     01f*        ldd     usarg0        sta     0,x             set side        stb     4,x             set dens        ldd     usarg2          hardware        std     flpdpr+flpstp        rts01      lda     0,x             get side        ldb     4,x             get dens        std     0,y        lda     flpdpr+flstat        sta     2,y        clr     3,y        ldd     flpdpr+flpstp        std     4,y        endif        end