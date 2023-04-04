; C:\IDE68K\UCOSII\OS_CPU_C.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; /*
; *********************************************************************************************************
; *                                               uC/OS-II
; *                                         The Real-Time Kernel
; *
; *                            (c) Copyright 2000, Jean J. Labrosse, Weston, FL
; *                                          All Rights Reserved
; *
; *
; *                                         68000 Specific C code
; *                                                IDE68K
; *
; * File         : OS_CPU_C.C
; * By           : Jean J. Labrosse
; *********************************************************************************************************
; */
; #ifndef  OS_MASTER_FILE
; #include "ucos_ii.h"
; #endif
; #include "Bios.h"
; /*
; *********************************************************************************************************
; *                                           REVISION HISTORY
; *
; * $Log$
; *
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0
; INT8U OSTmrTickCtr;
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                        INITIALIZE A TASK'S STACK
; *
; * Description: This function is called by either OSTaskCreate() or OSTaskCreateExt() to initialize the
; *              stack frame of the task being created.  This function is highly processor specific.
; *
; * Arguments  : task          is a pointer to the task code
; *
; *              pdata         is a pointer to a user supplied data area that will be passed to the task
; *                            when the task first executes.
; *
; *              ptos          is a pointer to the top of stack.  It is assumed that 'ptos' points to
; *                            a 'free' entry on the task stack.  If OS_STK_GROWTH is set to 1 then
; *                            'ptos' will contain the HIGHEST valid address of the stack.  Similarly, if
; *                            OS_STK_GROWTH is set to 0, the 'ptos' will contains the LOWEST valid address
; *                            of the stack.
; *
; *              opt           specifies options that can be used to alter the behavior of OSTaskStkInit().
; *                            (see uCOS_II.H for OS_TASK_OPT_???).
; *
; * Returns    : Always returns the location of the new top-of-stack' once the processor registers have
; *              been placed on the stack in the proper order.
; *
; * Note(s)    : 1) The initial value of the Status Register (SR) is OS_INITIAL_SR sets the 68xxx processor
; *                 to run in SUPERVISOR mode.  It is assumed that all uC/OS-II tasks run in supervisor
; *                 mode.
; *              2) You can pass the above options in the 'opt' argument.  You MUST only use the upper
; *                 8 bits of 'opt' because the lower bits are reserved by uC/OS-II.  If you make changes
; *                 to the code below, you will need to ensure that it doesn't affect the behaviour of
; *                 OSTaskIdle() and OSTaskStat().
; *              3) Registers are initialized to make them easy to differentiate with a debugger.
; *********************************************************************************************************
; */
; OS_STK *OSTaskStkInit(void (*task)(void *pd), void *pdata, OS_STK *ptos, INT16U opt)
; {
       section   code
       xdef      _OSTaskStkInit
_OSTaskStkInit:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; INT32U  *pstk32;
; INT16U  *pstk16;
; opt       = opt;                                  /* 'opt' is not used, prevent warning            */
; /* Load stack pointer and align on 32-bit bound  */
; pstk32    = (INT32U *)((INT32U)ptos & 0xFFFFFFFCL);
       move.l    16(A6),D0
       and.l     #2147483647,D0
       move.l    D0,D2
; /* -- SIMULATE CALL TO FUNCTION WITH ARGUMENT -- */
; *--pstk32 = (INT32U)pdata;                        /*    pdata                                      */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    12(A6),(A0)
; *--pstk32 = (INT32U)task;                         /*    Task return address                        */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    8(A6),(A0)
; /* ------ SIMULATE INTERRUPT STACK FRAME ------- */
; *--pstk32 = (INT32U)task;                         /*    Task return address                        */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    8(A6),(A0)
; pstk16    = (INT16U *)pstk32;                     /* Switch to 16-bit wide stack                   */
       move.l    D2,D3
; *--pstk16 = (INT16U)OS_INITIAL_SR;                /*    Initial Status Register value for the task */
       subq.l    #2,D3
       move.l    D3,A0
       move.w    #8192,(A0)
; pstk32    = (INT32U *)pstk16;                     /* Switch to 32-bit wide stack                   */
       move.l    D3,D2
; /* ------- SAVE ALL PROCESSOR REGISTERS -------- */
; *--pstk32 = (INT32U)0x00A600A6L;                  /* Register A6                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #10879142,(A0)
; *--pstk32 = (INT32U)0x00A500A5L;                  /* Register A5                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #10813605,(A0)
; *--pstk32 = (INT32U)0x00A400A4L;                  /* Register A4                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #10748068,(A0)
; *--pstk32 = (INT32U)0x00A300A3L;                  /* Register A3                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #10682531,(A0)
; *--pstk32 = (INT32U)0x00A200A2L;                  /* Register A2                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #10616994,(A0)
; *--pstk32 = (INT32U)0x00A100A1L;                  /* Register A1                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #10551457,(A0)
; *--pstk32 = (INT32U)0x00A000A0L;                  /* Register A0                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #10485920,(A0)
; *--pstk32 = (INT32U)0x00D700D7L;                  /* Register D7                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #14090455,(A0)
; *--pstk32 = (INT32U)0x00D600D6L;                  /* Register D6                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #14024918,(A0)
; *--pstk32 = (INT32U)0x00D500D5L;                  /* Register D5                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #13959381,(A0)
; *--pstk32 = (INT32U)0x00D400D4L;                  /* Register D4                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #13893844,(A0)
; *--pstk32 = (INT32U)0x00D300D3L;                  /* Register D3                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #13828307,(A0)
; *--pstk32 = (INT32U)0x00D200D2L;                  /* Register D2                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #13762770,(A0)
; *--pstk32 = (INT32U)0x00D100D1L;                  /* Register D1                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #13697233,(A0)
; *--pstk32 = (INT32U)0x00D000D0L;                  /* Register D0                                   */
       subq.l    #4,D2
       move.l    D2,A0
       move.l    #13631696,(A0)
; return ((OS_STK *)pstk32);                        /* Return pointer to new top-of-stack            */
       move.l    D2,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                             GET ISR VECTOR
; *
; * Description: This function is called to get the address of the exception handler specified by 'vect'.
; *              It is assumed that the VBR (Vector Base Register) is set to 0x00000000 (Not an issue with 68000 as VBR is always fixed at 0, but other 68k derivaties allowed VBR to be relocated - e.g. 68020).
; *
; * Arguments  : vect     is the vector number
; *
; * Note(s)    : 1) Interrupts are disabled during this call
; *              2) It is assumed that the VBR (Vector Base Register) is set to 0x00000000.
; *********************************************************************************************************
; */
; /*$PAGE*/
; #if OS_CPU_HOOKS_EN
; /*
; *********************************************************************************************************
; *                                       OS INITIALIZATION HOOK
; *                                            (BEGINNING)
; *
; * Description: This function is called by OSInit() at the beginning of OSInit(). Uou can use it to initialise
; *              Your board hardware (it could be done somewhere else too, but this is a convenient place)
; *
; * Arguments  : none
; *
; * Note(s)    : 1) Interrupts should be disabled during this call.
; *********************************************************************************************************
; */
; void OSInitHookBegin(void)
; {
       xdef      _OSInitHookBegin
_OSInitHookBegin:
       rts
; }
; /*
; *********************************************************************************************************
; *                                       OS INITIALIZATION HOOK
; *                                               (END)
; *
; * Description: This function is called by OSInit() at the end of OSInit().
; *
; * Arguments  : none
; *
; * Note(s)    : 1) Interrupts should be disabled during this call.
; *********************************************************************************************************
; */
; void OSInitHookEnd(void)
; {
       xdef      _OSInitHookEnd
_OSInitHookEnd:
; #if OS_TMR_EN > 0
; OSTmrTickCtr = 0;
       clr.b     _OSTmrTickCtr.L
       rts
; #endif
; }
; /*
; *********************************************************************************************************
; *                                          TASK CREATION HOOK
; *
; * Description: This function is called when a task is created.
; *
; * Arguments  : ptcb   is a pointer to the task control block of the task being created.
; *
; * Note(s)    : 1) Interrupts are disabled during this call.
; *********************************************************************************************************
; */
; void OSTaskCreateHook(OS_TCB *ptcb)
; {
       xdef      _OSTaskCreateHook
_OSTaskCreateHook:
       link      A6,#0
       unlk      A6
       rts
; }
; /*
; *********************************************************************************************************
; *                                           TASK DELETION HOOK
; *
; * Description: This function is called when a task is deleted.
; *
; * Arguments  : ptcb   is a pointer to the task control block of the task being deleted.
; *
; * Note(s)    : 1) Interrupts are disabled during this call.
; *********************************************************************************************************
; */
; void OSTaskDelHook(OS_TCB *ptcb)
; {
       xdef      _OSTaskDelHook
_OSTaskDelHook:
       link      A6,#0
       unlk      A6
       rts
; }
; /*
; *********************************************************************************************************
; *                                           TASK SWITCH HOOK
; *
; * Description: This function is called when a task switch is performed.  This allows you to perform other
; *              operations during a context switch.
; *
; * Arguments  : none
; *
; * Note(s)    : 1) Interrupts are disabled during this call.
; *              2) It is assumed that the global pointer 'OSTCBHighRdy' points to the TCB of the task that
; *                 will be 'switched in' (i.e. the highest priority task) and, 'OSTCBCur' points to the
; *                 task being switched out (i.e. the preempted task).
; *********************************************************************************************************
; */
; void OSTaskSwHook(void)
; {
       xdef      _OSTaskSwHook
_OSTaskSwHook:
       rts
; }
; /*
; *********************************************************************************************************
; *                                           TASK IDLE HOOK
; *
; * Description: This function is called when a idle task is performed.  This allows you to perform other
; *              operations during the idle task.
; *
; * Arguments  : none
; *
; * Note(s)    : none
; *********************************************************************************************************
; */
; void OSTaskIdleHook(void)
; {
       xdef      _OSTaskIdleHook
_OSTaskIdleHook:
       rts
; }
; /*
; *********************************************************************************************************
; *                                           TASK RETURN HOOK
; *
; * Description: This function is called if a task accidentally returns without deleting itself.  In other
; *              words, a task should either be an infinite loop or delete itself if it's done.
; *
; * Arguments  : Pointer to currently running TCB
; *
; * Note(s)    : none
; *********************************************************************************************************
; */
; void OSTaskReturnHook(OS_TCB *ptcb)
; {
       xdef      _OSTaskReturnHook
_OSTaskReturnHook:
       link      A6,#0
       unlk      A6
       rts
; }
; /*
; *********************************************************************************************************
; *                                           STATISTIC TASK HOOK
; *
; * Description: This function is called every second by uC/OS-II's statistics task.  This allows your
; *              application to add functionality to the statistics task.
; *
; * Arguments  : none
; *********************************************************************************************************
; */
; void OSTaskStatHook(void)
; {
       xdef      _OSTaskStatHook
_OSTaskStatHook:
       rts
; }
; /*
; *********************************************************************************************************
; *                                               TICK HOOK
; *
; * Description: This function is called every tick.
; *
; * Arguments  : none
; *
; * Note(s)    : 1) Interrupts may or may not be ENABLED during this call.
; *********************************************************************************************************
; */
; void OSTimeTickHook(void)
; {
       xdef      _OSTimeTickHook
_OSTimeTickHook:
; #if OS_TMR_EN > 0
; if (OSTmrUsed > 0 && ++OSTmrTickCtr >= (OS_TICKS_PER_SEC / OS_TMR_CFG_TICKS_PER_SEC)) {
       move.w    _OSTmrUsed.L,D0
       cmp.w     #0,D0
       bls.s     OSTimeTickHook_1
       addq.b    #1,_OSTmrTickCtr.L
       move.b    _OSTmrTickCtr.L,D0
       cmp.b     #10,D0
       blo.s     OSTimeTickHook_1
; OSTmrTickCtr = 0;
       clr.b     _OSTmrTickCtr.L
; OSTmrSignal();
       jsr       _OSTmrSignal
OSTimeTickHook_1:
       rts
; }
; #endif
; }
; /*
; *********************************************************************************************************
; *                                           OSTCBInit() HOOK
; *
; * Description: This function is called by OSTCBInit() after setting up most of the TCB.
; *
; * Arguments  : ptcb    is a pointer to the TCB of the task being created.
; *
; * Note(s)    : 1) Interrupts may or may not be ENABLED during this call.
; *********************************************************************************************************
; */
; #if OS_VERSION > 203
; void OSTCBInitHook (OS_TCB *ptcb)
; {
       xdef      _OSTCBInitHook
_OSTCBInitHook:
       link      A6,#0
       unlk      A6
       rts
; }
; #endif
; #endif // OS_CPU_HOOKS_EN
       section   bss
       xdef      _OSTmrTickCtr
_OSTmrTickCtr:
       ds.b      1
       xref      _OSTmrSignal
       xref      _OSTmrUsed
