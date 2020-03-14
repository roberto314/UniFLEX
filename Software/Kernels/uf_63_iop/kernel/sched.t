          lib     environment.h          sttl    Scheduler  routines          pag          name    sched          global  change,rsched,swpguy          global  putrun,makrdy,fixpri,swpguy** All routines in this file pertain to scheduling* operations.*** change & rsched** Change will change tasks.  The current task is put* back on the linked list of running tasks.* Rsched will reschedule the cpu giving control to* another ready task.  If no tasks are ready, idle* looping is done until one becomes ready.  Rsched* does not put the current task back on the ready list!* This routine returns one to the caller.  All registers* are destroyed.*change    ldx     utask      point to task table entry          jsr     putrun     put on ready list*rsched    seti    mask       interrupts          sts     umark0     save stack pointers          ldx     tsktab     point to task table          ldb     tsutop,x   get usrtop of sched task          jsr     swtchu     switch users          jsr     chkmap     validate map assignmentrsche2    clr     chproc     reset change flag          bsr     getjob     get a new task          bne     rsche3     find one?          lda     #127       set higheset priority          sta     jobpri     set as current          lda     LIGHTS     turn on "idle" bit          ora     #LB_IDLE          sta     LIGHTS          clri               clear      interrupts* idle work could go on here          jsr     idle_tsk   run the "idle" task          seti          lda     LIGHTS     turn off "idle" bit          anda    #!LB_IDLE       !$80          sta     LIGHTS          bra     rsche2     loop til find a ready onersche3    stb     jobpri     set new priority          clr     restim     clr time value          ldb     tsutop,x   get usrtop of new task          jsr     swtchu     switch users top page*         inc     teluch     tell rom changed users *** 4-4-81 ***          ldx     utask      point to task          lda     tsmode,x   get modes          bita    #TSWAPO    was he swapped out?          beq     rsche4          anda    #!TSWAPO   clear swapped bit          sta     tsmode,x   save new modes          lds     umark2     get stack from prior swaprsche4    jsr     chkmap     validate map assignment          ldd     #1         return 1 to new task          rts     return          pag** getjob** Search ready list for ready task.  If none found,* return 'EQ' status.  Otherwise return task table* entry address in x.*getjob    clrb    clear      flag          ldx     runlst     point to head of list          beq     getjo6     empty list?getjo1    lda     tsmode,x   get mode          bita    #TCORE     task in ram?          beq     getjo8          lda     tsstat,x   get status byte          cmpa    #TRUN      is it in run state?          bne     getjo8          tstb    first      in list?          beq     getjo2          ldd     tslink,x   remove from list          std     tslink,y          bra     getjo4getjo2    ldy     tslink,x   remove from list head          sty     runlst     set new headgetjo4    ldb     tsprir,x   get priority          clr     tslink,x   zero out link          clr     tslink+1,x so not run list          lda     #$ff       set ne status          rts     returngetjo6    clra    set        eq status          rtsgetjo8    tfr     x,y        save old pos          ldx     tslink,x   follow link          beq     getjo6          ldb     #1         set flag          bra     getjo1     repeat loop          pag** putrun** Put current task on ready list.  The list is* arranged with higher priority tasks at the top.* If equal priorities are found, the new one is* put at the end of the block.  On entry, x points* to the task table entry.  All registers are* destroyed except x.*putrun    pshs    cc         save status          seti    mask       interrupts          ldy     runlst     point to head          bne     putru2          stx     runlst     set new headputru1    clra    --         ldd #0 set last link          clrb          std     tslink,x          puls    cc,pc      returnputru2    ldb     tsprir,x   get priority          cmpb    tsprir,y   look for correct prior slot          ble     putru4          ldd     runlst          stx     runlst     set new head          bra     putru5     link in restputru4    tfr     y,u        save last look          ldy     tslink,y   follow link          beq     putru6          cmpb    tsprir,y   check priority          ble     putru4          ldd     tslink,u   link into list here          stx     tslink,uputru5    std     tslink,x          puls    cc,pc      returnputru6    stx     tslink,u          bra     putru1     go zero last link          pag** makrdy** Make a task ready to run.  Enter with x* pointing to task table entry.  If new tasks* priority is higher than current, set the* 'chproc' flag so the system can change tasks.*makrdy    lda     #TRUN      set status          sta     tsstat,x          clra    --         ldd #0 clear events flag          clrb          std     tsevnt,x          bsr     putrun     put on ready list          ldb     tsprir,x   get priority          cmpb    jobpri     higher than current?          ble     makrd6          inc     chproc     set change flagmakrd6    rts     return** fixpri** Adjust the tasks priority whose task entry is* pointed at by X.*fixpri    ldb     #USERPR    set base priority          subb    tsprb,x    add in bias          bpl     fixpr2     overflow?          lda     tsact,x    get activity count          beq     fixpr1     is it zero?          adda    tssize,x   add in mem usage          bcc     fixpr0     overflow?          lda     #255       set max herefixpr0    lsra    divide     by 8          lsra          lsra          inca               always  make at least one!          pshs    a          subb    0,s+       subtract from priority          bpl     fixpr2     overflow?fixpr1    lda     tsage,x    get age          beq     fixpr3          decb          bmi     fixpr3     overflow?fixpr2    ldb     #-127      set lowest priorityfixpr3    stb     tsprir,x   set new priority          ldy     runlst     check run list head          beq     fixpr4     if empty          cmpb    tsprir,y   check against top of run list          bhs     fixpr4     if this task is highest          lda     #1         set change task flag          sta     chprocfixpr4    rts     return          pag** swpguy** This is the routine which is responsible for swapping* tasks to and from secondary storage.  If a task is* found which is ready to be swapped in, two things may* happen.  First, if there is memory available, the* task is simply swapped in and set ready to run.  If* there is not enough memory, the routine 'lkout' is* called to find someont to swap out.*swpguy    tst     tmtupf     time to update?          beq     swpgu1          clr     tmtupf     clear out flag          jsr     update     do updateswpgu1    clra    --         ldd #0 make some room on stack          clrb          pshs    d          task pointer          pshs    b          and time out value          seti    mask       ints          ldx     runlst          beq     swpg35     no running?swpgu2    ldb     tsmode,x   get modes          bitb    #TCORE     is it already loaded?          bne     swpgu3     if so - ignore          lda     tsage,x    get age value          bne     swpg25          tst     1,s        have we found someone yet?          bne     swpgu3     if so - ignore          bra     swpg27swpg25    cmpa    0,s        compare age values          bls     swpgu3     looking for oldestswpg27    sta     0,s        save new age value          stx     1,s        save task entryswpgu3    ldx     tslink,x   follow run list link          bne     swpgu2     end of list?swpg35    clri          tst     1,s        did we find one?          bne     swpgu4          inc     rdytci     set 'ready to come in'          leas    3,s        clean stack          ldb     #SWAPPR    set priority          ldy     #rdytci    point to event          jsr     sleep      goto sleep          bra     swpguy     repeat searchswpgu4    puls    b,x        get task entry          lda     tssize,x   get swapped size          ldu     tstext,x   get text entry          beq     swpgu5     is there one?          tst     txlref,u   any loaded refs?          bne     swpgu5          adda    txsiz,u    add in text sizeswpgu5    cmpa    corcnt     have enoygh memory?          lbhi    lkout      if not, go look for a task to thro out          bne     brngin     just enough?          tst     inargx     any in arg expansion?          lbne    lkout          ldb     tsmode,x   get modes          bitb    #TARGX     need extra segment?          lbne    lkout      if so - swap out more          pag** brngin** We have found a task to swap in and we have enough memory* to support the task as swapped.  Swap in the text, data,* and stack segments.*brngin    sta     swpisz     save swap in size          ldu     #swpint    point to swap in map          stu     swpptr     save pointer          pshs    abrngi1    jsr     getpag     get a page of mem          stb     0,u+       save in map          dec     0,s        dec the count          bne     brngi1          puls    a          clean stack          stb     tsutop,x   set new user top          ldu     tstext,x   get text entry          beq     brngi5     is there one?          tst     txlref,u   any loaded references?          bne     brngi4          ldb     swpisz     get swap size          subb    txsiz,u    subtract off text size          stb     swpisz     save new value          ldb     txsiz,u    get text size          leau    txmap,u    point to text mem map          ldy     swpptr     get swap map pointer          pshs    x          save task          lda     tsutop,x   get user block          jsr     mapxbf     map into XBUFFER          ldx     #XBUFFR+(umem-USRLOC<<12) point to mem mapbrngi2    lda     0,y+       transfer segments to text          sta     0,u+          sta     0,x+       set in mem map          decb    dec        the count          bne     brngi2          sty     swpptr     save memory map position          ldx     0,s        reset task pointer          ldx     tstext,x   point to text entry          clrb    set        for read          lda     txsiz,x    get text size          ldy     txadr,x    get swap address          ldu     0,s        get task ptr          leax    txmap,x    point to text map          jsr     doswap     swap in text segment          puls    x          get task pointer          ldu     tstext,x   point to text entrybrngi4    inc     txlref,u   bump loaded ref countbrngi5    lda     swpisz     get remaining swap size          clrb    set        for read          pshs    x          save task          ldy     tsswap,x   get swap address          ldx     #0         set for reg swap          ldu     0,s        get task pointer          jsr     doswap     go swap in          ldx     0,s        get task          ldb     tssize,x   get swapped size          ldu     tsswap,x   get swap address          jsr     freswp     free swap space          ldx     0,s        get task pointer          lda     tsutop,x   get user top segment          tst     MAXMAP     multiple memory maps?          beq     00f          jsr     mapxbf     map in to XBUFFER          inc     XBUFFR+(urelod-USRLOC<<12)          ldb     XBUFFR+(umapno-USRLOC<<12)          jsr     fremap          clr     XBUFFR+(umapno-USRLOC<<12)00        ldu     tstext,x   get text pointer          beq     brngi8     ant text?          ldx     #XBUFFR+(umem-USRLOC<<12) point to user mem map          ldb     txsiz,u    get text size          leau    txmap,u    point to text mapbrngi6    lda     0,u+       copy map to user block          sta     0,x+          decb    dec        the count          bne     brngi6     repeat?brngi8    puls    x          reset task pointer          lda     tsmode,x   get modes          ora     #TCORE     show it is loaded in core          anda    #!TARGX    clear arg bit          sta     tsmode,x   save new modes          clr     tsage,x    set age to 0          ldd     staswp     get swap in stat counter          addd    #1         bump to show swap          std     staswp     save new value          jmp     swpguy     repeat swap loop          pag** lkout** Look for a task to swap out, since we need the memory* to swap another guy in.*lkout     clra    --         ldd #0 set up stack          clrb          pshs    d          task pointer          pshs    b          age value          ldx     tsktab     point to task table          seti    mask       intslkout2    ldd     tsstat,x   get stat and mode          bitb    #TCORE     in core (loaded)?          beq     lkout4     if not - ignore          bitb    #TLOCK|TSYSTM ok to swap out?          bne     lkout4          cmpa    #TSLEEP    is he sleeping?          beq     lkout3          cmpa    #TRUN      is he running?          bne     lkout4lkout3    lda     tsage,x    get age value          cmpa    0,s        compare to so far value          bls     lkout4          sta     0,s        save new value          stx     1,s        save task pointerlkout4    leax    TSKSIZ,x   get to next task entry          cmpx    tskend     end of list?          bne     lkout2          clri          ldb     0,s+       get age value          bne     lkout5     did we find one?          leas    2,s        clean stack          inc     rdytgo     set rdy to go out flag          ldy     #rdytgo          ldb     #SWAPPR    set priority          jsr     sleep      go sleep          jmp     swpguy     repeat swap looplkout5    puls    x          get task pointer          lda     tsmode,x   get modes          anda    #!TCORE    clear core bit          sta     tsmode,x   save new mode          ldb     #1         set to free memory          jsr     swpout     go swap out task          jmp     swpguy     repeat swap loop