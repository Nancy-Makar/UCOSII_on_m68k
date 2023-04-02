;********************************************************************************************************
;                                               uC/OS-II
;                                         The Real-Time Kernel
;
;                            (c) Copyright 1999, Jean J. Labrosse, Weston, FL
;                                          All Rights Reserved
;
;
;                                      68000 specific assembly code
;                                        with 68881 FPU support
;
; File         : OS_FCPU_A.ASM
; By           : Jean J. Labrosse, Peter J. Fondse
;********************************************************************************************************


;********************************************************************************************************
;                                            REVISION HISTORY
;
; $Log$
;
;********************************************************************************************************


;********************************************************************************************************
;                                          PUBLIC DECLARATIONS
;********************************************************************************************************

        xdef   _OSIntCtxSw                     ; Satisfy OSIntExit() in OS_CORE.C
        xdef   _OSStartHighRdy
        xdef   _OSCtxSw
        xdef   _OSTickISR
        xdef   OSIntExit68K

;********************************************************************************************************
;                                         EXTERNAL DECLARATIONS
;********************************************************************************************************

        xref   _OSCtxSwCtr
        xref   _OSIntExit
        xref   _OSIntNesting
        xref   _OSLockNesting
        xref   _OSPrioCur
        xref   _OSPrioHighRdy
        xref   _OSRdyGrp
        xref   _OSRdyTbl
        xref   _OSRunning
        xref   _OSTaskSwHook
        xref   _OSTCBCur
        xref   _OSTCBHighRdy
        xref   _OSTCBPrioTbl
        xref   _OSTimeTick
        xref   _OSUnMapTbl

;********************************************************************************************************
;                               START HIGHEST PRIORITY TASK READY-TO-RUN
;
; Description : This function is called by OSStart() to start the highest priority task that was created
;               by your application before calling OSStart().
;
; Arguments   : none
;
; Note(s)     : 1) The stack frame is assumed to look as follows:
;
;                  OSTCBHighRdy->OSTCBStkPtr +  0  ---->  D0    (H)        Low Memory
;                                            +  2         D0    (L)
;                                            +  4         D1    (H)
;                                            +  6         D1    (L)
;                                            +  8         D2    (H)
;                                            + 10         D2    (L)
;                                            + 12         D3    (H)
;                                            + 14         D3    (L)
;                                            + 16         D4    (H)
;                                            + 18         D4    (L)
;                                            + 20         D5    (H)
;                                            + 22         D5    (L)
;                                            + 24         D6    (H)
;                                            + 26         D6    (L)
;                                            + 28         D7    (H)
;                                            + 30         D7    (L)
;                                            + 32         A0    (H)
;                                            + 34         A0    (L)
;                                            + 36         A1    (H)
;                                            + 38         A1    (L)
;                                            + 40         A2    (H)
;                                            + 42         A2    (L)
;                                            + 44         A3    (H)
;                                            + 46         A3    (L)
;                                            + 48         A4    (H)
;                                            + 50         A4    (L)
;                                            + 52         A5    (H)
;                                            + 54         A5    (L)
;                                            + 56         A6    (H)
;                                            + 58         A6    (L)
;                                            + 60         OS_INITIAL_SR
;                                            + 62         task  (H)
;                                            + 64         task  (L)
;                                            + 66         task  (H)
;                                            + 68         task  (L)
;                                            + 70         pdata (H)
;                                            + 72         pdata (L)        High Memory
;
;               2) OSStartHighRdy() MUST:
;                      a) Call OSTaskSwHook() then,
;                      b) Set OSRunning to TRUE,
;                      c) Switch to the highest priority task.
;********************************************************************************************************

        section   code

_OSStartHighRdy:
        jsr       _OSTaskSwHook            ; Invoke user defined context switch hook
        addq.b    #1,_OSRunning            ; Indicate that we are multitasking
        move.l    _OSTCBHighRdy,A0         ; Point to TCB of highest priority task ready to run
        move.l    (A0),A7                  ; Get the stack pointer of the task to resume
        movem.l   (A7)+,A0-A6/D0-D7        ; Restore the CPU registers
        rte                                ; Run task

;********************************************************************************************************
;                                       TASK LEVEL CONTEXT SWITCH
;
; Description : This function is called when a task makes a higher priority task ready-to-run.
;               Called with TRAP #0 instruction (see vector table entry at address 0x0080 in boot.asm)
;
; Arguments   : none
;
; Note(s)     : 1) Upon entry,
;                  OSTCBCur     points to the OS_TCB of the task to suspend
;                  OSTCBHighRdy points to the OS_TCB of the task to resume
;
;               2) The stack frame of the task to suspend looks as follows (the registers for
;                  task to suspend need to be saved):
;
;                                         SP +  0  ---->  SR                   Low Memory
;                                            +  2         PC of task  (H)
;                                            +  4         PC of task  (L)      High Memory
;
;               3) The stack frame of the task to resume looks as follows:
;
;                  OSTCBHighRdy->OSTCBStkPtr +  0  ---->  D0    (H)           Low Memory
;                                            +  2         D0    (L)
;                                            +  4         D1    (H)
;                                            +  6         D1    (L)
;                                            +  8         D2    (H)
;                                            + 10         D2    (L)
;                                            + 12         D3    (H)
;                                            + 14         D3    (L)
;                                            + 16         D4    (H)
;                                            + 18         D4    (L)
;                                            + 20         D5    (H)
;                                            + 22         D5    (L)
;                                            + 24         D6    (H)
;                                            + 26         D6    (L)
;                                            + 28         D7    (H)
;                                            + 30         D7    (L)
;                                            + 32         A0    (H)
;                                            + 34         A0    (L)
;                                            + 36         A1    (H)
;                                            + 38         A1    (L)
;                                            + 40         A2    (H)
;                                            + 42         A2    (L)
;                                            + 44         A3    (H)
;                                            + 46         A3    (L)
;                                            + 48         A4    (H)
;                                            + 50         A4    (L)
;                                            + 52         A5    (H)
;                                            + 54         A5    (L)
;                                            + 56         A6    (H)
;                                            + 58         A6    (L)
;                                            + 60         OS_INITIAL_SR       (See OS_CPU.H)
;                                            + 62         PC of task  (H)
;                                            + 64         PC of task  (L)     High Memory
;********************************************************************************************************

_OSCtxSw:
        movem.l   A0-A6/D0-D7,-(A7)              ; Save the registers of the current task
        move.l    _OSTCBCur,A0                   ; Save the stack pointer in the suspended task TCB
        move.l    A7,(A0)
        jsr       _OSTaskSwHook                  ; Invoke user defined context switch hook
        move.b    _OSPrioHighRdy,_OSPrioCur      ; OSPrioCur = OSPrioHighRdy
        move.l    _OSTCBHighRdy,A0               ; OSTCBCur  = OSTCBHighRdy
        move.l    A0,_OSTCBCur
        move.l    (A0),A7                        ; Get the stack pointer of the task to resume
        movem.l   (A7)+,A0-A6/D0-D7              ; Restore the CPU registers
        rte                                      ; Run task

;********************************************************************************************************
;                                      INTERRUPT LEVEL CONTEXT SWITCH
;
; Description : This function is called from OSIntExit() in OS_CORE.C
;               Provided for backward compatibility.
;               The ISR MUST NOT call OSIntExit(), but should jump to OSIntExit68K().
;********************************************************************************************************

_OSIntCtxSw:
        adda.l    #10,A7                         ; Adjust the stack
        move.l    _OSTCBCur,A1                   ; Save the stack pointer in the suspended task TCB
        move.l    A7,(A1)
        jsr       _OSTaskSwHook                  ; Invoke user defined context switch hook
        move.l    _OSTCBHighRdy,A1               ; OSTCBCur  = OSTCBHighRdy
        move.l    A1,_OSTCBCur
        move.l    (A1),A7                        ; Get the stack pointer of the task to resume
        move.b    _OSPrioHighRdy,_OSPrioCur      ; OSPrioCur = OSPrioHighRdy
        movem.l   (A7)+,A0-A6/D0-D7              ; Restore the CPU registers
        rte                                      ; Run task

;********************************************************************************************************
;                           INTERRUPT EXIT FUNCTION (IDE68K specific)
;
; Description : ISR's (written in Assembly) must directly JUMP to OSIntExit68K
;
; Notes       : You must NOT call OSIntExit() to exit an ISR with IDE68K, but JUMP to OSIntExit68K().
;
; Stack frame upon entry:
;
;                  SP +  0  ---->  D0    (H)
;                     +  2         D0    (L)
;                     +  4         D1    (H)
;                     +  6         D1    (L)
;                     +  8         D2    (H)
;                     + 10         D2    (L)
;                     + 12         D3    (H)
;                     + 14         D3    (L)
;                     + 16         D4    (H)
;                     + 18         D4    (L)
;                     + 20         D5    (H)
;                     + 22         D5    (L)
;                     + 24         D6    (H)
;                     + 26         D6    (L)
;                     + 28         D7    (H)
;                     + 30         D7    (L)
;                     + 32         A0    (H)
;                     + 34         A0    (L)
;                     + 36         A1    (H)
;                     + 38         A1    (L)
;                     + 40         A2    (H)
;                     + 42         A2    (L)
;                     + 44         A3    (H)
;                     + 46         A3    (L)
;                     + 48         A4    (H)
;                     + 50         A4    (L)
;                     + 52         A5    (H)
;                     + 54         A5    (L)
;                     + 56         A6    (H)
;                     + 58         A6    (L)
;                     + 60         Task or ISR's SR
;                     + 62         PC of task  (H)
;                     + 64         PC of task  (L)                   High Memory
;********************************************************************************************************

OSIntExit68K:
        subq.b    #1,_OSIntNesting              ; if (--OSIntNesting == 0)
        bne       OSIntExit68K_1
        tst.b     _OSLockNesting                ; if (OSLockNesting == 0)
        bne       OSIntExit68K_1
        move.w    (60,A7),D0                    ;  if (LAST nested ISR)
        and.w     #$0700,D0
        bne       OSIntExit68K_1
        lea       _OSUnMapTbl,A0                ;  y = OSUnMapTbl[OSRdyGrp];
        clr.l     D0
        move.b    _OSRdyGrp,D0
        move.b    0(A0,D0.L),D1                 ;  y in D1
        lea       _OSRdyTbl,A0                  ;  OSPrioHighRdy = (INT8U)((y << 3) + OSUnMapTbl[OSRdyTbl[y]]);
        clr.l     D0
        move.b    D1,D0
        lea       0(A0,D0.L),A0
        clr.l     D0
        move.b    (A0),D0                       ;  OSRdyTbl[y] in D0
        lea       _OSUnMapTbl,A0
        lea       0(A0,D0.L),A0                 ;  &OSUnMapTbl[OSRdyTbl[y]] in A0
        move.b    D1,D0
        lsl.b     #3,D0                         ;  (y << 3) in D0
        add.b     (A0),D0
        move.b    D0,_OSPrioHighRdy
        cmp.b     _OSPrioCur,D0                 ;  if (OSPrioCur != OSPrioHighRdy) {
        beq.s     OSIntExit68K_1
        lea       _OSTCBPrioTbl,A0              ;    OSTCBHighRdy  = OSTCBPrioTbl[OSPrioHighRdy];
        clr.l     D1
        move.b    D0,D1
        lsl.l     #2,D1
        lea       0(A0,D1.L),A0
        move.l    (A0),_OSTCBHighRdy
        addq.l    #1,_OSCtxSwCtr                ;    OSCtxSwCtr++;
        move.l    _OSTCBCur,A0                  ;    Save the stack pointer in the suspended task TCB
        move.l    A7,(A0)
        jsr       _OSTaskSwHook                 ;    Invoke user defined context switch hook
        move.l    _OSTCBHighRdy,A0              ;    OSTCBCur  = OSTCBHighRdy
        move.l    A0,_OSTCBCur
        move.b    _OSPrioHighRdy,_OSPrioCur     ;    OSPrioCur = OSPrioHighRdy
        move.l    (A0),A7                       ;    Get the stack pointer of the task to resume
OSIntExit68K_1:
        movem.l   (A7)+,A0-A6/D0-D7             ;  Restore the CPU registers
        rte                                     ;  Return to task or nested ISR

;********************************************************************************************************
;                                           SYSTEM TICK ISR
;
; Description : This function is the ISR used to notify uC/OS-II that a system tick has occurred.
;
; Arguments   : none
;
; Notes       : 1) You MUST increment 'OSIntNesting' and NOT call OSIntEnter()
;               2) You MUST save ALL the CPU registers as shown below
;               3) You MUST JUMP to OSIntExit68K() instead of call the function.
;********************************************************************************************************

_OSTickISR:
        or.w      #$0700,SR                     ; Disable ALL interrupts
        addq.b    #1,_OSIntNesting              ; OSIntNesting++;
        movem.l   A0-A6/D0-D7,-(A7)             ; Save the registers of the current task
        jsr       _OSTimeTick                   ; Call uC/OS-II's tick updating function
        bra       OSIntExit68K                  ; Exit ISR

;*********************************************************************************************************
;                                           SAVE FPU REGISTERS
;                                        void OSFPSave(void *pblk)
;
; Description : This function is called to save the contents of the FPU registers during a context
;               switch.  It is assumed that a pointer to a storage area for the FPU registers is placed
;               in the task's TCB (i.e. .OSTCBExtPtr).
; Arguments   : pblk is passed to this function when called.
; Note(s)     : 1) The stack frame upon entry looks as follows:
;
;                      SP + 0 -> Return address(H) of function (Low memory)
;                         + 2    Return address(L) of function
;                         + 4    pblk(H)
;                         + 6    pblk(L)                       (High memory)
;*********************************************************************************************************

_OSFPSave:
        move.l    4(A7),A0
        fmovem.x  FP0-FP7,(A0)
        rts

;*********************************************************************************************************
;                                           RESTORE FPU REGISTERS
;                                       void OSFPRestore(void *pblk)
;
; Description : This function is called to restore the contents of the FPU registers during a context
;               switch.  It is assumed that a pointer to a storage area for the FPU registers is placed
;               in the task's TCB (i.e. .OSTCBExtPtr).
; Arguments   : pblk is passed to this function when called.
; Note(s)     : 1) The stack frame upon entry looks as follows:
;
;                      SP + 0 -> Return address(H) of function (Low memory)
;                         + 2    Return address(L) of function
;                         + 4    pblk(H)
;                         + 6    pblk(L)                       (High memory)
;*********************************************************************************************************

_OSFPRestore:
        move.l    4(A7),A0
        fmovem.x  (A0),FP0-FP7
        rts