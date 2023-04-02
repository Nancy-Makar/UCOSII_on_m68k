/*
*********************************************************************************************************
*                                               uC/OS-II
*                                        The Real-Time Kernel
*
*                            (c) Copyright 2000, Jean J. Labrosse, Weston, FL
*                                          All Rights Reserved
*
*                                          M68000 Specific code
*                                              IDE68K v 2.2
*
* File         : OS_CPU.H
* By           : Jean J. Labrosse, Peter J. Fondse
*********************************************************************************************************
*/

/*
*********************************************************************************************************
*                                           REVISION HISTORY
*
* $Log$
*
*********************************************************************************************************
*/

/*$PAGE*/
/*
*********************************************************************************************************
*                                              DATA TYPES
*********************************************************************************************************
*/

typedef unsigned char  BOOLEAN;
typedef unsigned char  INT8U;                    /* Unsigned  8 bit quantity                           */
typedef signed   char  INT8S;                    /* Signed    8 bit quantity                           */
typedef unsigned short INT16U;                   /* Unsigned 16 bit quantity                           */
typedef signed   short INT16S;                   /* Signed   16 bit quantity                           */
typedef unsigned int   INT32U;                   /* Unsigned 32 bit quantity                           */
typedef signed   int   INT32S;                   /* Signed   32 bit quantity                           */
typedef float          FP32;                     /* Single precision floating point                    */
typedef double         FP64;                     /* Double precision floating point                    */

#define BYTE           INT8S                     /* Define data types for backward compatibility ...   */
#define UBYTE          INT8U                     /* ... to uC/OS V1.xx                                 */
#define WORD           INT16S
#define UWORD          INT16U
#define LONG           INT32S
#define ULONG          INT32U

typedef unsigned short OS_STK;                   /* Each stack entry is 16-bit wide                    */

/*
*********************************************************************************************************
*                                           Motorola 68000
*
* Method #1:  Disable/Enable interrupts using simple instructions.  After critical section, interrupts
*             will be enabled even if they were disabled before entering the critical section.
*
* Method #2:  Disable/Enable interrupts by preserving the state of interrupts.  In other words, if
*             interrupts were disabled before entering the critical section, they will be disabled when
*             leaving the critical section.
*********************************************************************************************************
*/
#define  OS_CRITICAL_METHOD    2

#if      OS_CRITICAL_METHOD == 1
#define  OS_ENTER_CRITICAL()  _word(0x007C); _word(0x0700)                /* asm("  ORI   #$0700,SR\n")                 */
#define  OS_EXIT_CRITICAL()   _word(0x027C); _word(0xF800)                /* asm("  AND   #$0F800,SR\n")                */
#endif

#if      OS_CRITICAL_METHOD == 2
#define  OS_ENTER_CRITICAL()  _word(0x40E7); _word(0x007C); _word(0x0700) /* asm("  MOVE  SR,-(A7)\n  ORI #$0700,SR\n")  */
#define  OS_EXIT_CRITICAL()   _word(0x46DF)                               /* asm("  MOVE  (A7)+,SR\n")                   */
#endif

#define  CPU_INT_DIS()        _word(0x007C); _word(0x0700)                /* asm("  ORI   #$0700,SR\n"                   */
#define  CPU_INT_EN()         _word(0x027C); _word(0xF800)                /* asm("  AND   #$0F800,SR\n")                 */

#define  OS_TASK_SW()         _trap(0)                                    /* asm("  TRAP  #0\n")                         */

#define  OS_STK_GROWTH        1                                           /* Define CPUs stack growth: 1 = Down, 0 = Up   */

#define  OS_INITIAL_SR        0x2000                                      /* Supervisor mode, all interrupts enabled     */

#define  OS_TRAP_NBR          0                                           /* OSCtxSw() invoked through TRAP #0            */

void OSVectSet(INT8U vect, void (*addr)(void));
void *OSVectGet(INT8U vect);
void OSIntExit68K(void);
void OSStartHighRdy(void);
void OSIntCtxSw(void);
void OSCtxSw(void);
void OSFPRestore(void *);
void OSFPSave(void *);
void OSTickISR(void);