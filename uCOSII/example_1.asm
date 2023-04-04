; C:\IDE68K\UCOSII\EXAMPLE_1.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; /*
; * EXAMPLE_1.C
; *
; * This is a minimal program to verify multitasking.
; *
; */
; #include "stdio.h"
; #include "Bios.h"
; #include "ucos_ii.h"
; #define STACKSIZE 256
; /*
; ** Stacks for each task are allocated here in the application in this case = 256 bytes
; ** but you can change size if required
; */
; OS_STK Task1Stk[STACKSIZE];
; OS_STK Task2Stk[STACKSIZE];
; OS_STK Task3Stk[STACKSIZE];
; OS_STK Task4Stk[STACKSIZE];
; /* Prototypes for our tasks/threads*/
; void Task1(unsigned int pdata); /* (void *) means the child task expects no data from parent*/
; void Task2(void *);
; void Task3(void *);
; void Task4(void *);
; /*
; ** Our main application which has to
; ** 1) Initialise any peripherals on the board, e.g. RS232 for hyperterminal + LCD
; ** 2) Call OSInit() to initialise the OS
; ** 3) Create our application task/threads
; ** 4) Call OSStart()
; */
; void main(void)
; {
       section   code
       xdef      _main
_main:
       move.l    A2,-(A7)
       lea       _OSTaskCreate.L,A2
; static int count = 0;
; // initialise board hardware by calling our routines from the BIOS.C source file
; Init_RS232();
       jsr       _Init_RS232
; Init_LCD();
       jsr       _Init_LCD
; /* display welcome message on LCD display */
; Oline0("Altera DE1/68K");
       pea       @exampl~1_1.L
       jsr       _Oline0
       addq.w    #4,A7
; Oline1("Micrium uC/OS-II RTOS");
       pea       @exampl~1_2.L
       jsr       _Oline1
       addq.w    #4,A7
; OSInit(); // call to initialise the OS
       jsr       _OSInit
; /*
; ** Now create the 4 child tasks and pass them no data.
; ** the smaller the numerical priority value, the higher the task priority
; */
; OSTaskCreate(Task1, count, &Task1Stk[STACKSIZE], 12);
       pea       12
       lea       _Task1Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       move.l    main_count.L,-(A7)
       pea       _Task1.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 11); // highest priority task
       pea       11
       lea       _Task2Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task2.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task3, OS_NULL, &Task3Stk[STACKSIZE], 13);
       pea       13
       lea       _Task3Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task3.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task4, OS_NULL, &Task4Stk[STACKSIZE], 14); // lowest priority task
       pea       14
       lea       _Task4Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task4.L
       jsr       (A2)
       add.w     #16,A7
; OSStart();                                              // call to start the OS scheduler, (never returns from this function)
       jsr       _OSStart
       move.l    (A7)+,A2
       rts
; }
; /*
; ** IMPORTANT : Timer 1 interrupts must be started by the highest priority task
; ** that runs first which is Task2
; */
; void Task1(unsigned int pdata)
; {
       xdef      _Task1
_Task1:
       link      A6,#-4
       move.l    D2,-(A7)
       move.l    8(A6),D2
; char msb, mid, lsb;
; for (;;)
Task1_1:
; {
; printf("This is Task #1\n");
       pea       @exampl~1_3.L
       jsr       _printf
       addq.w    #4,A7
; OSTimeDly(15);
       pea       15
       jsr       _OSTimeDly
       addq.w    #4,A7
; msb = (pdata >> 16) & 0xff;
       move.l    D2,D0
       lsr.l     #8,D0
       lsr.l     #8,D0
       and.l     #255,D0
       move.b    D0,-3(A6)
; mid = (pdata >> 8) & 0xff;
       move.l    D2,D0
       lsr.l     #8,D0
       and.l     #255,D0
       move.b    D0,-2(A6)
; lsb = pdata & 0xff;
       move.l    D2,D0
       and.l     #255,D0
       move.b    D0,-1(A6)
; HEX_A = lsb;
       move.b    -1(A6),4194320
; HEX_B = mid;
       move.b    -2(A6),4194322
; HEX_C = msb;
       move.b    -3(A6),4194324
; pdata++;
       addq.l    #1,D2
       bra       Task1_1
; }
; }
; /*
; ** Task 2 below was created with the highest priority so it must start timer1
; ** so that it produces interrupts for the 100hz context switches
; */
; void Task2(void *pdata)
; {
       xdef      _Task2
_Task2:
       link      A6,#0
; // must start timer ticker here
; Timer1_Init(); // this function is in BIOS.C and written by us to start timer
       jsr       _Timer1_Init
; for (;;)
Task2_1:
; {
; printf("....This is Task #2\n");
       pea       @exampl~1_4.L
       jsr       _printf
       addq.w    #4,A7
; OSTimeDly(10);
       pea       10
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task2_1
; }
; }
; void Task3(void *pdata)
; {
       xdef      _Task3
_Task3:
       link      A6,#0
; for (;;)
Task3_1:
; {
; printf("........This is Task #3\n");
       pea       @exampl~1_5.L
       jsr       _printf
       addq.w    #4,A7
; OSTimeDly(40);
       pea       40
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task3_1
; }
; }
; void Task4(void *pdata)
; {
       xdef      _Task4
_Task4:
       link      A6,#0
       move.l    A2,-(A7)
       lea       Task4_countA.L,A2
; static int countA = 0;
; static int countB = 0;
; for (;;)
Task4_3:
; {
; printf("............This is Task #4\n");
       pea       @exampl~1_6.L
       jsr       _printf
       addq.w    #4,A7
; if (countA > 256) {
       move.l    (A2),D0
       cmp.l     #256,D0
       ble.s     Task4_6
; countA = 0;
       clr.l     (A2)
; PortB = countB++;
       move.l    Task4_countB.L,D0
       addq.l    #1,Task4_countB.L
       move.b    D0,4194306
Task4_6:
; }
; PortA = countA++;
       move.l    (A2),D0
       addq.l    #1,(A2)
       move.b    D0,4194304
; OSTimeDly(50);
       pea       50
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task4_3
; }
; }
       section   const
@exampl~1_1:
       dc.b      65,108,116,101,114,97,32,68,69,49,47,54,56,75
       dc.b      0
@exampl~1_2:
       dc.b      77,105,99,114,105,117,109,32,117,67,47,79,83
       dc.b      45,73,73,32,82,84,79,83,0
@exampl~1_3:
       dc.b      84,104,105,115,32,105,115,32,84,97,115,107,32
       dc.b      35,49,10,0
@exampl~1_4:
       dc.b      46,46,46,46,84,104,105,115,32,105,115,32,84
       dc.b      97,115,107,32,35,50,10,0
@exampl~1_5:
       dc.b      46,46,46,46,46,46,46,46,84,104,105,115,32,105
       dc.b      115,32,84,97,115,107,32,35,51,10,0
@exampl~1_6:
       dc.b      46,46,46,46,46,46,46,46,46,46,46,46,84,104,105
       dc.b      115,32,105,115,32,84,97,115,107,32,35,52,10
       dc.b      0
       section   data
main_count:
       dc.l      0
Task4_countA:
       dc.l      0
Task4_countB:
       dc.l      0
       section   bss
       xdef      _Task1Stk
_Task1Stk:
       ds.b      512
       xdef      _Task2Stk
_Task2Stk:
       ds.b      512
       xdef      _Task3Stk
_Task3Stk:
       ds.b      512
       xdef      _Task4Stk
_Task4Stk:
       ds.b      512
       xref      _Init_LCD
       xref      _Timer1_Init
       xref      _Init_RS232
       xref      _OSInit
       xref      _OSStart
       xref      _OSTaskCreate
       xref      _Oline0
       xref      _Oline1
       xref      _OSTimeDly
       xref      _printf
