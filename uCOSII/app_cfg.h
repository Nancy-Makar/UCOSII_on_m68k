/*
*********************************************************************************************************
*                                                uC/OS-II
*                                          The Real-Time Kernel
*                            uC/OS-II Configuration File for applicaion programs
*
*                               (c) Copyright 2005-2007, Micrium, Weston, FL
*                                          All Rights Reserved
*
*
* File    : OS_APP.H
* By      : Jean J. Labrosse
* Version : V2.92
*
* LICENSING TERMS:
* ---------------
*   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
* If you plan on using  uC/OS-II  in a commercial product you need to contact Micriµm to properly license
* its use in your product. We provide ALL the source code for your convenience and to help you experience
* uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
* licensing fee.
*********************************************************************************************************
*/

/* This definition could be better moved to ucos_ii.h                                                  */

#define  OS_NULL                 (void *)0


/* No clear what priority is best for the timer, high (e.g. 0, 1 or 5) or low (e.g. 60)                */

#define  OS_TASK_TMR_PRIO        5                       /* Timer task priority                        */