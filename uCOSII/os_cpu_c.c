/*
*********************************************************************************************************
*                                               uC/OS-II
*                                         The Real-Time Kernel
*
*                            (c) Copyright 2000, Jean J. Labrosse, Weston, FL
*                                          All Rights Reserved
*
*
*                                         68000 Specific C code
*                                                IDE68K
*
* File         : OS_CPU_C.C
* By           : Jean J. Labrosse
*********************************************************************************************************
*/

#ifndef  OS_MASTER_FILE
#include <ucos_ii.h>
#endif

#include <Bios.h>

/*
*********************************************************************************************************
*                                           REVISION HISTORY
*
* $Log$
*
*********************************************************************************************************
*/

#if OS_TMR_EN > 0
    INT8U OSTmrTickCtr;
#endif

/*$PAGE*/
/*
*********************************************************************************************************
*                                        INITIALIZE A TASK'S STACK
*
* Description: This function is called by either OSTaskCreate() or OSTaskCreateExt() to initialize the
*              stack frame of the task being created.  This function is highly processor specific.
*
* Arguments  : task          is a pointer to the task code
*
*              pdata         is a pointer to a user supplied data area that will be passed to the task
*                            when the task first executes.
*
*              ptos          is a pointer to the top of stack.  It is assumed that 'ptos' points to
*                            a 'free' entry on the task stack.  If OS_STK_GROWTH is set to 1 then
*                            'ptos' will contain the HIGHEST valid address of the stack.  Similarly, if
*                            OS_STK_GROWTH is set to 0, the 'ptos' will contains the LOWEST valid address
*                            of the stack.
*
*              opt           specifies options that can be used to alter the behavior of OSTaskStkInit().
*                            (see uCOS_II.H for OS_TASK_OPT_???).
*
* Returns    : Always returns the location of the new top-of-stack' once the processor registers have
*              been placed on the stack in the proper order.
*
* Note(s)    : 1) The initial value of the Status Register (SR) is OS_INITIAL_SR sets the 68xxx processor
*                 to run in SUPERVISOR mode.  It is assumed that all uC/OS-II tasks run in supervisor
*                 mode.
*              2) You can pass the above options in the 'opt' argument.  You MUST only use the upper
*                 8 bits of 'opt' because the lower bits are reserved by uC/OS-II.  If you make changes
*                 to the code below, you will need to ensure that it doesn't affect the behaviour of
*                 OSTaskIdle() and OSTaskStat().
*              3) Registers are initialized to make them easy to differentiate with a debugger.
*********************************************************************************************************
*/

OS_STK *OSTaskStkInit(void (*task)(void *pd), void *pdata, OS_STK *ptos, INT16U opt)
{
    INT32U  *pstk32;
    INT16U  *pstk16;


    opt       = opt;                                  /* 'opt' is not used, prevent warning            */
                                                      /* Load stack pointer and align on 32-bit bound  */
    pstk32    = (INT32U *)((INT32U)ptos & 0xFFFFFFFCL);
                                                      /* -- SIMULATE CALL TO FUNCTION WITH ARGUMENT -- */
    *--pstk32 = (INT32U)pdata;                        /*    pdata                                      */
    *--pstk32 = (INT32U)task;                         /*    Task return address                        */
                                                      /* ------ SIMULATE INTERRUPT STACK FRAME ------- */
    *--pstk32 = (INT32U)task;                         /*    Task return address                        */
    pstk16    = (INT16U *)pstk32;                     /* Switch to 16-bit wide stack                   */
    *--pstk16 = (INT16U)OS_INITIAL_SR;                /*    Initial Status Register value for the task */
    pstk32    = (INT32U *)pstk16;                     /* Switch to 32-bit wide stack                   */
                                                      /* ------- SAVE ALL PROCESSOR REGISTERS -------- */
    *--pstk32 = (INT32U)0x00A600A6L;                  /* Register A6                                   */
    *--pstk32 = (INT32U)0x00A500A5L;                  /* Register A5                                   */
    *--pstk32 = (INT32U)0x00A400A4L;                  /* Register A4                                   */
    *--pstk32 = (INT32U)0x00A300A3L;                  /* Register A3                                   */
    *--pstk32 = (INT32U)0x00A200A2L;                  /* Register A2                                   */
    *--pstk32 = (INT32U)0x00A100A1L;                  /* Register A1                                   */
    *--pstk32 = (INT32U)0x00A000A0L;                  /* Register A0                                   */
    *--pstk32 = (INT32U)0x00D700D7L;                  /* Register D7                                   */
    *--pstk32 = (INT32U)0x00D600D6L;                  /* Register D6                                   */
    *--pstk32 = (INT32U)0x00D500D5L;                  /* Register D5                                   */
    *--pstk32 = (INT32U)0x00D400D4L;                  /* Register D4                                   */
    *--pstk32 = (INT32U)0x00D300D3L;                  /* Register D3                                   */
    *--pstk32 = (INT32U)0x00D200D2L;                  /* Register D2                                   */
    *--pstk32 = (INT32U)0x00D100D1L;                  /* Register D1                                   */
    *--pstk32 = (INT32U)0x00D000D0L;                  /* Register D0                                   */
    return ((OS_STK *)pstk32);                        /* Return pointer to new top-of-stack            */
}

/*$PAGE*/
/*
*********************************************************************************************************
*                                             GET ISR VECTOR
*
* Description: This function is called to get the address of the exception handler specified by 'vect'.
*              It is assumed that the VBR (Vector Base Register) is set to 0x00000000 (Not an issue with 68000 as VBR is always fixed at 0, but other 68k derivaties allowed VBR to be relocated - e.g. 68020).
*
* Arguments  : vect     is the vector number
*
* Note(s)    : 1) Interrupts are disabled during this call
*              2) It is assumed that the VBR (Vector Base Register) is set to 0x00000000.
*********************************************************************************************************
*/


/*$PAGE*/
#if OS_CPU_HOOKS_EN
/*
*********************************************************************************************************
*                                       OS INITIALIZATION HOOK
*                                            (BEGINNING)
*
* Description: This function is called by OSInit() at the beginning of OSInit(). Uou can use it to initialise
*              Your board hardware (it could be done somewhere else too, but this is a convenient place)
*
* Arguments  : none
*
* Note(s)    : 1) Interrupts should be disabled during this call.
*********************************************************************************************************
*/
void OSInitHookBegin(void)
{
}

/*
*********************************************************************************************************
*                                       OS INITIALIZATION HOOK
*                                               (END)
*
* Description: This function is called by OSInit() at the end of OSInit().
*
* Arguments  : none
*
* Note(s)    : 1) Interrupts should be disabled during this call.
*********************************************************************************************************
*/
void OSInitHookEnd(void)
{

#if OS_TMR_EN > 0
    OSTmrTickCtr = 0;
#endif

}


/*
*********************************************************************************************************
*                                          TASK CREATION HOOK
*
* Description: This function is called when a task is created.
*
* Arguments  : ptcb   is a pointer to the task control block of the task being created.
*
* Note(s)    : 1) Interrupts are disabled during this call.
*********************************************************************************************************
*/
void OSTaskCreateHook(OS_TCB *ptcb)
{
}


/*
*********************************************************************************************************
*                                           TASK DELETION HOOK
*
* Description: This function is called when a task is deleted.
*
* Arguments  : ptcb   is a pointer to the task control block of the task being deleted.
*
* Note(s)    : 1) Interrupts are disabled during this call.
*********************************************************************************************************
*/
void OSTaskDelHook(OS_TCB *ptcb)
{
}

/*
*********************************************************************************************************
*                                           TASK SWITCH HOOK
*
* Description: This function is called when a task switch is performed.  This allows you to perform other
*              operations during a context switch.
*
* Arguments  : none
*
* Note(s)    : 1) Interrupts are disabled during this call.
*              2) It is assumed that the global pointer 'OSTCBHighRdy' points to the TCB of the task that
*                 will be 'switched in' (i.e. the highest priority task) and, 'OSTCBCur' points to the
*                 task being switched out (i.e. the preempted task).
*********************************************************************************************************
*/
void OSTaskSwHook(void)
{
}

/*
*********************************************************************************************************
*                                           TASK IDLE HOOK
*
* Description: This function is called when a idle task is performed.  This allows you to perform other
*              operations during the idle task.
*
* Arguments  : none
*
* Note(s)    : none
*********************************************************************************************************
*/
void OSTaskIdleHook(void)
{
}

/*
*********************************************************************************************************
*                                           TASK RETURN HOOK
*
* Description: This function is called if a task accidentally returns without deleting itself.  In other
*              words, a task should either be an infinite loop or delete itself if it's done.
*
* Arguments  : Pointer to currently running TCB
*
* Note(s)    : none
*********************************************************************************************************
*/
void OSTaskReturnHook(OS_TCB *ptcb)
{
}

/*
*********************************************************************************************************
*                                           STATISTIC TASK HOOK
*
* Description: This function is called every second by uC/OS-II's statistics task.  This allows your
*              application to add functionality to the statistics task.
*
* Arguments  : none
*********************************************************************************************************
*/
void OSTaskStatHook(void)
{
}

/*
*********************************************************************************************************
*                                               TICK HOOK
*
* Description: This function is called every tick.
*
* Arguments  : none
*
* Note(s)    : 1) Interrupts may or may not be ENABLED during this call.
*********************************************************************************************************
*/
void OSTimeTickHook(void)
{

#if OS_TMR_EN > 0
    if (OSTmrUsed > 0 && ++OSTmrTickCtr >= (OS_TICKS_PER_SEC / OS_TMR_CFG_TICKS_PER_SEC)) {
        OSTmrTickCtr = 0;
        OSTmrSignal();
    }
#endif

}

/*
*********************************************************************************************************
*                                           OSTCBInit() HOOK
*
* Description: This function is called by OSTCBInit() after setting up most of the TCB.
*
* Arguments  : ptcb    is a pointer to the TCB of the task being created.
*
* Note(s)    : 1) Interrupts may or may not be ENABLED during this call.
*********************************************************************************************************
*/
#if OS_VERSION > 203
void OSTCBInitHook (OS_TCB *ptcb)
{
}
#endif
#endif // OS_CPU_HOOKS_EN