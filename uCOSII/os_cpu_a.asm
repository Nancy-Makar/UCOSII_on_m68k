;********************************************************************************************************
;                                               uC/OS-II
;                                         The Real-Time Kernel
;
;                            (c) Copyright 1999, Jean J. Labrosse, Weston, FL
;                                          All Rights Reserved
;
;
;                                     68000 Specific assembly code
;                                               IDE68K
;
; File         : OS_CPU_A.ASM
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

        xdef   _OSStartHighRdy
        xdef   _OSCtxSw
        xdef   _OSIntCtxSw
        xdef   _OSTickISR
        xdef   OSIntExit68K:

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

; Pseudocode for OSStartHighRdy:
;          Call OSTaskSwHook();
;          Set OSRunning to 1;
;          Load the processor stack pointer with OSTCBHighRdy->OSTCBStkPtr;
;          POP all the processor registers from the stack;
;          Execute a Return from Interrupt instruction;

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

; Pseudocode for OSCtxSw:
; OSCtxSw:
; PUSH processor registers onto the current task’s stack;
; Save the stack pointer at OSTCBCur->OSTCBStkPtr;
; Call OSTaskSwHook(); (1)
; OSTCBCur = OSTCBHighRdy;
; OSPrioCur = OSPrioHighRdy; (2)
; Load the processor stack pointer with OSTCBHighRdy->OSTCBStkPtr;
; POP all the processor registers from the stack;
; Execute a Return from Interrupt instruction;

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

; Pseudocode for OSIntCtxSw
; OSIntCtxSw
;          Save the stack pointer at OSTCBCur->OSTCBStkPtr;
;          Call OSTaskSwHook(); (1)
;          OSTCBCur = OSTCBHighRdy;
;          OSPrioCur = OSPrioHighRdy; (2)
;          Load the processor stack pointer with OSTCBHighRdy->OSTCBStkPtr;
;          POP all the processor registers from the stack;
;          Execute a Return from Interrupt instruction;

_OSIntCtxSw:
        adda.l    #10,A7                         ; Adjust the stack (note this code is called as a subroutine by OS so extra copy of PC stored on stack - along with PC and SR - so adjust by 10 bytes to point to A6)
        move.l    _OSTCBCur,A1                   ; Save the stack pointer in the suspended task TCB
        move.l    A7,(A1)
;
        jsr       _OSTaskSwHook                  ; Invoke user defined context switch hook
;
        move.l    _OSTCBHighRdy,A1               ; OSTCBCur  = OSTCBHighRdy
        move.l    A1,_OSTCBCur
        move.l    (A1),A7                        ; Get the stack pointer of the task to resume
;
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

; C Code for OSInterrupt exit taken from test book on OS example program 3.16 page 96/305

; void OSIntExit (void)
; {
;           OS_ENTER_CRITICAL();
;           if ((--OSIntNesting | OSLockNesting) == 0) {
;                       OSIntExitY = OSUnMapTbl[OSRdyGrp];
;                       OSPrioHighRdy = (INT8U)((OSIntExitY << 3) + OSUnMapTbl[OSRdyTbl[OSIntExitY]]);
;                       if (OSPrioHighRdy != OSPrioCur) {
;                                       OSTCBHighRdy = OSTCBPrioTbl[OSPrioHighRdy];
;                                       OSCtxSwCtr++;
;                                       OSIntCtxSw();
;                       }
;           }
;           OS_EXIT_CRITICAL();
; }

OSIntExit68K:
        subq.b    #1,_OSIntNesting              ; if (--OSIntNesting == 0)
        bne       OSIntExit68K_1
        tst.b     _OSLockNesting                ; if (OSLockNesting == 0)
        bne       OSIntExit68K_1

;       re-enabling interrupts
        move.w    (60,A7),D0                    ; must be LAST nested ISR
        and.w     #$0700,D0                     ; do we want to change S bit in SR
;
        bne       OSIntExit68K_1
        lea       _OSUnMapTbl,A0                ;  y = OSUnMapTbl[OSRdyGrp];
        clr.l     D0
        move.b    _OSRdyGrp,D0
        move.b    0(A0,D0.L),D1                 ;  y in D1
;
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
;
        cmp.b     _OSPrioCur,D0                 ;  if (OSPrioCur != OSPrioHighRdy) {
        beq.s     OSIntExit68K_1
;
        lea       _OSTCBPrioTbl,A0              ;    OSTCBHighRdy  = OSTCBPrioTbl[OSPrioHighRdy];
        clr.l     D1
        move.b    D0,D1
        lsl.l     #2,D1
        lea       0(A0,D1.L),A0
        move.l    (A0),_OSTCBHighRdy
;
        addq.l    #1,_OSCtxSwCtr                ;    OSCtxSwCtr++;
;
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

; C Code for OSInterrupt exit taken from text book on OS example program

; void OSTickISR(void)
; {
;          Save processor registers;
;          Call OSIntEnter() or increment OSIntNesting;
;          Call OSTimeTick();
;          Call OSIntExit();
;          Restore processor registers;
;          Execute a return from interrupt instruction;
; }


_OSTickISR:
        or.w      #$0700,SR                     ; Disable ALL interrupts
        addq.b    #1,_OSIntNesting              ; OSIntNesting++;
        movem.l   A0-A6/D0-D7,-(A7)             ; Save the registers of the current task
        ; call your ISR here to clear the tick interrupt
        jsr       _Timer_ISR
        ;
        jsr       _OSTimeTick                   ; Call uC/OS-II's tick updating function
        bra       OSIntExit68K                  ; Exit ISR