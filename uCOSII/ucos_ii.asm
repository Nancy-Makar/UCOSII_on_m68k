; C:\IDE68K\UCOSII\UCOS_II.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                             CORE FUNCTIONS
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : OS_CORE.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #define  OS_GLOBALS
; #include <ucos_ii.h>
; #endif
; /*
; *********************************************************************************************************
; *                                      PRIORITY RESOLUTION TABLE
; *
; * Note: Index into table is bit pattern to resolve highest priority
; *       Indexed value corresponds to highest priority bit position (i.e. 0..7)
; *********************************************************************************************************
; */
; INT8U  const  OSUnMapTbl[256] = {
; 0u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x00 to 0x0F                   */
; 4u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x10 to 0x1F                   */
; 5u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x20 to 0x2F                   */
; 4u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x30 to 0x3F                   */
; 6u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x40 to 0x4F                   */
; 4u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x50 to 0x5F                   */
; 5u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x60 to 0x6F                   */
; 4u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x70 to 0x7F                   */
; 7u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x80 to 0x8F                   */
; 4u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0x90 to 0x9F                   */
; 5u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0xA0 to 0xAF                   */
; 4u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0xB0 to 0xBF                   */
; 6u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0xC0 to 0xCF                   */
; 4u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0xD0 to 0xDF                   */
; 5u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, /* 0xE0 to 0xEF                   */
; 4u, 0u, 1u, 0u, 2u, 0u, 1u, 0u, 3u, 0u, 1u, 0u, 2u, 0u, 1u, 0u  /* 0xF0 to 0xFF                   */
; };
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                         FUNCTION PROTOTYPES
; *********************************************************************************************************
; */
; static  void  OS_InitEventList(void);
; static  void  OS_InitMisc(void);
; static  void  OS_InitRdyList(void);
; static  void  OS_InitTaskIdle(void);
; #if OS_TASK_STAT_EN > 0u
; static  void  OS_InitTaskStat(void);
; #endif
; static  void  OS_InitTCBList(void);
; static  void  OS_SchedNew(void);
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                        GET THE NAME OF A SEMAPHORE, MUTEX, MAILBOX or QUEUE
; *
; * Description: This function is used to obtain the name assigned to a semaphore, mutex, mailbox or queue.
; *
; * Arguments  : pevent    is a pointer to the event group.  'pevent' can point either to a semaphore,
; *                        a mutex, a mailbox or a queue.  Where this function is concerned, the actual
; *                        type is irrelevant.
; *
; *              pname     is a pointer to a pointer to an ASCII string that will receive the name of the semaphore,
; *                        mutex, mailbox or queue.
; *
; *              perr      is a pointer to an error code that can contain one of the following values:
; *
; *                        OS_ERR_NONE                if the name was copied to 'pname'
; *                        OS_ERR_EVENT_TYPE          if 'pevent' is not pointing to the proper event
; *                                                   control block type.
; *                        OS_ERR_PNAME_NULL          You passed a NULL pointer for 'pname'
; *                        OS_ERR_PEVENT_NULL         if you passed a NULL pointer for 'pevent'
; *                        OS_ERR_NAME_GET_ISR        if you are trying to call this function from an ISR
; *
; * Returns    : The length of the string or 0 if the 'pevent' is a NULL pointer.
; *********************************************************************************************************
; */
; #if (OS_EVENT_EN) && (OS_EVENT_NAME_EN > 0u)
; INT8U  OSEventNameGet (OS_EVENT   *pevent,
; INT8U     **pname,
; INT8U      *perr)
; {
       section   code
       xdef      _OSEventNameGet
_OSEventNameGet:
       link      A6,#-4
       move.l    D2,-(A7)
       move.l    16(A6),D2
; INT8U      len;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {               /* Is 'pevent' a NULL pointer?                        */
; *perr = OS_ERR_PEVENT_NULL;
; return (0u);
; }
; if (pname == (INT8U **)0) {                   /* Is 'pname' a NULL pointer?                         */
; *perr = OS_ERR_PNAME_NULL;
; return (0u);
; }
; #endif
; if (OSIntNesting > 0u) {                     /* See if trying to call from an ISR                  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSEventNameGet_1
; *perr  = OS_ERR_NAME_GET_ISR;
       move.l    D2,A0
       move.b    #17,(A0)
; return (0u);
       clr.b     D0
       bra       OSEventNameGet_3
OSEventNameGet_1:
; }
; switch (pevent->OSEventType) {
       move.l    8(A6),A0
       move.b    (A0),D0
       and.l     #255,D0
       subq.l    #1,D0
       blo.s     OSEventNameGet_4
       cmp.l     #4,D0
       bhs.s     OSEventNameGet_4
       asl.l     #1,D0
       move.w    OSEventNameGet_6(PC,D0.L),D0
       jmp       OSEventNameGet_6(PC,D0.W)
OSEventNameGet_6:
       dc.w      OSEventNameGet_7-OSEventNameGet_6
       dc.w      OSEventNameGet_7-OSEventNameGet_6
       dc.w      OSEventNameGet_7-OSEventNameGet_6
       dc.w      OSEventNameGet_7-OSEventNameGet_6
OSEventNameGet_7:
; case OS_EVENT_TYPE_SEM:
; case OS_EVENT_TYPE_MUTEX:
; case OS_EVENT_TYPE_MBOX:
; case OS_EVENT_TYPE_Q:
; break;
       bra.s     OSEventNameGet_5
OSEventNameGet_4:
; default:
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D2,A0
       move.b    #1,(A0)
; return (0u);
       clr.b     D0
       bra.s     OSEventNameGet_3
OSEventNameGet_5:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; *pname = pevent->OSEventName;
       move.l    8(A6),A0
       move.l    12(A6),A1
       move.l    18(A0),(A1)
; len    = OS_StrLen(*pname);
       move.l    12(A6),A0
       move.l    (A0),-(A7)
       jsr       _OS_StrLen
       addq.w    #4,A7
       move.b    D0,-1(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr  = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return (len);
       move.b    -1(A6),D0
OSEventNameGet_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                        ASSIGN A NAME TO A SEMAPHORE, MUTEX, MAILBOX or QUEUE
; *
; * Description: This function assigns a name to a semaphore, mutex, mailbox or queue.
; *
; * Arguments  : pevent    is a pointer to the event group.  'pevent' can point either to a semaphore,
; *                        a mutex, a mailbox or a queue.  Where this function is concerned, it doesn't
; *                        matter the actual type.
; *
; *              pname     is a pointer to an ASCII string that will be used as the name of the semaphore,
; *                        mutex, mailbox or queue.
; *
; *              perr      is a pointer to an error code that can contain one of the following values:
; *
; *                        OS_ERR_NONE                if the requested task is resumed
; *                        OS_ERR_EVENT_TYPE          if 'pevent' is not pointing to the proper event
; *                                                   control block type.
; *                        OS_ERR_PNAME_NULL          You passed a NULL pointer for 'pname'
; *                        OS_ERR_PEVENT_NULL         if you passed a NULL pointer for 'pevent'
; *                        OS_ERR_NAME_SET_ISR        if you called this function from an ISR
; *
; * Returns    : None
; *********************************************************************************************************
; */
; #if (OS_EVENT_EN) && (OS_EVENT_NAME_EN > 0u)
; void  OSEventNameSet (OS_EVENT  *pevent,
; INT8U     *pname,
; INT8U     *perr)
; {
       xdef      _OSEventNameSet
_OSEventNameSet:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    16(A6),D2
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return;
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {               /* Is 'pevent' a NULL pointer?                        */
; *perr = OS_ERR_PEVENT_NULL;
; return;
; }
; if (pname == (INT8U *)0) {                   /* Is 'pname' a NULL pointer?                         */
; *perr = OS_ERR_PNAME_NULL;
; return;
; }
; #endif
; if (OSIntNesting > 0u) {                     /* See if trying to call from an ISR                  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSEventNameSet_1
; *perr = OS_ERR_NAME_SET_ISR;
       move.l    D2,A0
       move.b    #18,(A0)
; return;
       bra       OSEventNameSet_3
OSEventNameSet_1:
; }
; switch (pevent->OSEventType) {
       move.l    8(A6),A0
       move.b    (A0),D0
       and.l     #255,D0
       subq.l    #1,D0
       blo.s     OSEventNameSet_4
       cmp.l     #4,D0
       bhs.s     OSEventNameSet_4
       asl.l     #1,D0
       move.w    OSEventNameSet_6(PC,D0.L),D0
       jmp       OSEventNameSet_6(PC,D0.W)
OSEventNameSet_6:
       dc.w      OSEventNameSet_7-OSEventNameSet_6
       dc.w      OSEventNameSet_7-OSEventNameSet_6
       dc.w      OSEventNameSet_7-OSEventNameSet_6
       dc.w      OSEventNameSet_7-OSEventNameSet_6
OSEventNameSet_7:
; case OS_EVENT_TYPE_SEM:
; case OS_EVENT_TYPE_MUTEX:
; case OS_EVENT_TYPE_MBOX:
; case OS_EVENT_TYPE_Q:
; break;
       bra.s     OSEventNameSet_5
OSEventNameSet_4:
; default:
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D2,A0
       move.b    #1,(A0)
; return;
       bra.s     OSEventNameSet_3
OSEventNameSet_5:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pevent->OSEventName = pname;
       move.l    8(A6),A0
       move.l    12(A6),18(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
OSEventNameSet_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       PEND ON MULTIPLE EVENTS
; *
; * Description: This function waits for multiple events.  If multiple events are ready at the start of the
; *              pend call, then all available events are returned as ready.  If the task must pend on the
; *              multiple events, then only the first posted or aborted event is returned as ready.
; *
; * Arguments  : pevents_pend  is a pointer to a NULL-terminated array of event control blocks to wait for.
; *
; *              pevents_rdy   is a pointer to an array to return which event control blocks are available
; *                            or ready.  The size of the array MUST be greater than or equal to the size
; *                            of the 'pevents_pend' array, including terminating NULL.
; *
; *              pmsgs_rdy     is a pointer to an array to return messages from any available message-type
; *                            events.  The size of the array MUST be greater than or equal to the size of
; *                            the 'pevents_pend' array, excluding the terminating NULL.  Since NULL
; *                            messages are valid messages, this array cannot be NULL-terminated.  Instead,
; *                            every available message-type event returns its messages in the 'pmsgs_rdy'
; *                            array at the same index as the event is returned in the 'pevents_rdy' array.
; *                            All other 'pmsgs_rdy' array indices are filled with NULL messages.
; *
; *              timeout       is an optional timeout period (in clock ticks).  If non-zero, your task will
; *                            wait for the resources up to the amount of time specified by this argument.
; *                            If you specify 0, however, your task will wait forever for the specified
; *                            events or, until the resources becomes available (or the events occur).
; *
; *              perr          is a pointer to where an error message will be deposited.  Possible error
; *                            messages are:
; *
; *                            OS_ERR_NONE         The call was successful and your task owns the resources
; *                                                or, the events you are waiting for occurred; check the
; *                                                'pevents_rdy' array for which events are available.
; *                            OS_ERR_PEND_ABORT   The wait on the events was aborted; check the
; *                                                'pevents_rdy' array for which events were aborted.
; *                            OS_ERR_TIMEOUT      The events were not received within the specified
; *                                                'timeout'.
; *                            OS_ERR_PEVENT_NULL  If 'pevents_pend', 'pevents_rdy', or 'pmsgs_rdy' is a
; *                                                NULL pointer.
; *                            OS_ERR_EVENT_TYPE   If you didn't pass a pointer to an array of semaphores,
; *                                                mailboxes, and/or queues.
; *                            OS_ERR_PEND_ISR     If you called this function from an ISR and the result
; *                                                would lead to a suspension.
; *                            OS_ERR_PEND_LOCKED  If you called this function when the scheduler is locked.
; *
; * Returns    : >  0          the number of events returned as ready or aborted.
; *              == 0          if no events are returned as ready because of timeout or upon error.
; *
; * Notes      : 1) a. Validate 'pevents_pend' array as valid OS_EVENTs :
; *
; *                        semaphores, mailboxes, queues
; *
; *                 b. Return ALL available events and messages, if any
; *
; *                 c. Add    current task priority as pending to   each events's wait list
; *                      Performed in OS_EventTaskWaitMulti()
; *
; *                 d. Wait on any of multiple events
; *
; *                 e. Remove current task priority as pending from each events's wait list
; *                      Performed in OS_EventTaskRdy(), if events posted or aborted
; *
; *                 f. Return any event posted or aborted, if any
; *                      else
; *                    Return timeout
; *
; *              2) 'pevents_rdy' initialized to NULL PRIOR to all other validation or function handling in
; *                 case of any error(s).
; *********************************************************************************************************
; */
; /*$PAGE*/
; #if ((OS_EVENT_EN) && (OS_EVENT_MULTI_EN > 0u))
; INT16U  OSEventPendMulti (OS_EVENT  **pevents_pend,
; OS_EVENT  **pevents_rdy,
; void      **pmsgs_rdy,
; INT32U      timeout,
; INT8U      *perr)
; {
       xdef      _OSEventPendMulti
_OSEventPendMulti:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4,-(A7)
       lea       _OSTCBCur.L,A2
       move.l    24(A6),D4
       move.l    12(A6),D5
       move.l    16(A6),A3
       move.l    8(A6),A4
; OS_EVENT  **pevents;
; OS_EVENT   *pevent;
; #if ((OS_Q_EN > 0u) && (OS_MAX_QS > 0u))
; OS_Q       *pq;
; #endif
; BOOLEAN     events_rdy;
; INT16U      events_rdy_nbr;
; INT8U       events_stat;
; #if (OS_CRITICAL_METHOD == 3u)                          /* Allocate storage for CPU status register    */
; OS_CPU_SR   cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if (OS_ARG_CHK_EN > 0u)
; if (pevents_pend == (OS_EVENT **)0) {               /* Validate 'pevents_pend'                     */
; *perr =  OS_ERR_PEVENT_NULL;
; return (0u);
; }
; if (*pevents_pend  == (OS_EVENT *)0) {              /* Validate 'pevents_pend'                     */
; *perr =  OS_ERR_PEVENT_NULL;
; return (0u);
; }
; if (pevents_rdy  == (OS_EVENT **)0) {               /* Validate 'pevents_rdy'                      */
; *perr =  OS_ERR_PEVENT_NULL;
; return (0u);
; }
; if (pmsgs_rdy == (void **)0) {                      /* Validate 'pmsgs_rdy'                        */
; *perr =  OS_ERR_PEVENT_NULL;
; return (0u);
; }
; #endif
; *pevents_rdy = (OS_EVENT *)0;                        /* Init array to NULL in case of errors        */
       move.l    D5,A0
       clr.l     (A0)
; pevents     =  pevents_pend;
       move.l    A4,D7
; pevent      = *pevents;
       move.l    D7,A0
       move.l    (A0),D2
; while  (pevent != (OS_EVENT *)0) {
OSEventPendMulti_1:
       tst.l     D2
       beq       OSEventPendMulti_3
; switch (pevent->OSEventType) {                  /* Validate event block types                  */
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       subq.l    #1,D0
       blo.s     OSEventPendMulti_10
       cmp.l     #5,D0
       bhs.s     OSEventPendMulti_10
       asl.l     #1,D0
       move.w    OSEventPendMulti_6(PC,D0.L),D0
       jmp       OSEventPendMulti_6(PC,D0.W)
OSEventPendMulti_6:
       dc.w      OSEventPendMulti_8-OSEventPendMulti_6
       dc.w      OSEventPendMulti_9-OSEventPendMulti_6
       dc.w      OSEventPendMulti_7-OSEventPendMulti_6
       dc.w      OSEventPendMulti_10-OSEventPendMulti_6
       dc.w      OSEventPendMulti_10-OSEventPendMulti_6
OSEventPendMulti_7:
; #if (OS_SEM_EN  > 0u)
; case OS_EVENT_TYPE_SEM:
; break;
       bra.s     OSEventPendMulti_5
OSEventPendMulti_8:
; #endif
; #if (OS_MBOX_EN > 0u)
; case OS_EVENT_TYPE_MBOX:
; break;
       bra.s     OSEventPendMulti_5
OSEventPendMulti_9:
; #endif
; #if ((OS_Q_EN   > 0u) && (OS_MAX_QS > 0u))
; case OS_EVENT_TYPE_Q:
; break;
       bra.s     OSEventPendMulti_5
OSEventPendMulti_10:
; #endif
; case OS_EVENT_TYPE_MUTEX:
; case OS_EVENT_TYPE_FLAG:
; default:
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return (0u);
       clr.w     D0
       bra       OSEventPendMulti_13
OSEventPendMulti_5:
; }
; pevents++;
       addq.l    #4,D7
; pevent = *pevents;
       move.l    D7,A0
       move.l    (A0),D2
       bra       OSEventPendMulti_1
OSEventPendMulti_3:
; }
; if (OSIntNesting  > 0u) {                           /* See if called from ISR ...                  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSEventPendMulti_14
; *perr =  OS_ERR_PEND_ISR;                        /* ... can't PEND from an ISR                  */
       move.l    D4,A0
       move.b    #2,(A0)
; return (0u);
       clr.w     D0
       bra       OSEventPendMulti_13
OSEventPendMulti_14:
; }
; if (OSLockNesting > 0u) {                           /* See if called with scheduler locked ...     */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSEventPendMulti_16
; *perr =  OS_ERR_PEND_LOCKED;                     /* ... can't PEND when locked                  */
       move.l    D4,A0
       move.b    #13,(A0)
; return (0u);
       clr.w     D0
       bra       OSEventPendMulti_13
OSEventPendMulti_16:
; }
; /*$PAGE*/
; events_rdy     =  OS_FALSE;
       clr.b     -2(A6)
; events_rdy_nbr =  0u;
       clr.w     D3
; events_stat    =  OS_STAT_RDY;
       clr.b     -1(A6)
; pevents        =  pevents_pend;
       move.l    A4,D7
; pevent         = *pevents;
       move.l    D7,A0
       move.l    (A0),D2
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; while (pevent != (OS_EVENT *)0) {                   /* See if any events already available         */
OSEventPendMulti_18:
       tst.l     D2
       beq       OSEventPendMulti_20
; switch (pevent->OSEventType) {
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       subq.l    #1,D0
       blo       OSEventPendMulti_27
       cmp.l     #5,D0
       bhs       OSEventPendMulti_27
       asl.l     #1,D0
       move.w    OSEventPendMulti_23(PC,D0.L),D0
       jmp       OSEventPendMulti_23(PC,D0.W)
OSEventPendMulti_23:
       dc.w      OSEventPendMulti_25-OSEventPendMulti_23
       dc.w      OSEventPendMulti_26-OSEventPendMulti_23
       dc.w      OSEventPendMulti_24-OSEventPendMulti_23
       dc.w      OSEventPendMulti_27-OSEventPendMulti_23
       dc.w      OSEventPendMulti_27-OSEventPendMulti_23
OSEventPendMulti_24:
; #if (OS_SEM_EN > 0u)
; case OS_EVENT_TYPE_SEM:
; if (pevent->OSEventCnt > 0u) {         /* If semaphore count > 0, resource available; */
       move.l    D2,A0
       move.w    6(A0),D0
       cmp.w     #0,D0
       bls.s     OSEventPendMulti_30
; pevent->OSEventCnt--;              /* ... decrement semaphore,                ... */
       move.l    D2,D0
       addq.l    #6,D0
       move.l    D0,A0
       subq.w    #1,(A0)
; *pevents_rdy++ =  pevent;           /* ... and return available semaphore event    */
       move.l    D5,A0
       addq.l    #4,D5
       move.l    D2,(A0)
; events_rdy   =  OS_TRUE;
       move.b    #1,-2(A6)
; *pmsgs_rdy++   = (void *)0;         /* NO message returned  for semaphores         */
       clr.l     (A3)+
; events_rdy_nbr++;
       addq.w    #1,D3
       bra.s     OSEventPendMulti_31
OSEventPendMulti_30:
; } else {
; events_stat |=  OS_STAT_SEM;      /* Configure multi-pend for semaphore events   */
       or.b      #1,-1(A6)
OSEventPendMulti_31:
; }
; break;
       bra       OSEventPendMulti_22
OSEventPendMulti_25:
; #endif
; #if (OS_MBOX_EN > 0u)
; case OS_EVENT_TYPE_MBOX:
; if (pevent->OSEventPtr != (void *)0) { /* If mailbox NOT empty;                   ... */
       move.l    D2,A0
       move.l    2(A0),D0
       beq.s     OSEventPendMulti_32
; /* ... return available message,           ... */
; *pmsgs_rdy++         = (void *)pevent->OSEventPtr;
       move.l    D2,A0
       move.l    2(A0),(A3)+
; pevent->OSEventPtr  = (void *)0;
       move.l    D2,A0
       clr.l     2(A0)
; *pevents_rdy++       =  pevent;     /* ... and return available mailbox event      */
       move.l    D5,A0
       addq.l    #4,D5
       move.l    D2,(A0)
; events_rdy         =  OS_TRUE;
       move.b    #1,-2(A6)
; events_rdy_nbr++;
       addq.w    #1,D3
       bra.s     OSEventPendMulti_33
OSEventPendMulti_32:
; } else {
; events_stat |= OS_STAT_MBOX;      /* Configure multi-pend for mailbox events     */
       or.b      #2,-1(A6)
OSEventPendMulti_33:
; }
; break;
       bra       OSEventPendMulti_22
OSEventPendMulti_26:
; #endif
; #if ((OS_Q_EN > 0u) && (OS_MAX_QS > 0u))
; case OS_EVENT_TYPE_Q:
; pq = (OS_Q *)pevent->OSEventPtr;
       move.l    D2,A0
       move.l    2(A0),D6
; if (pq->OSQEntries > 0u) {             /* If queue NOT empty;                     ... */
       move.l    D6,A0
       move.w    22(A0),D0
       cmp.w     #0,D0
       bls       OSEventPendMulti_34
; /* ... return available message,           ... */
; *pmsgs_rdy++ = (void *)*pq->OSQOut++;
       move.l    D6,D0
       add.l     #16,D0
       move.l    D0,A0
       move.l    (A0),A1
       addq.l    #4,(A0)
       move.l    (A1),(A3)+
; if (pq->OSQOut == pq->OSQEnd) {    /* If OUT ptr at queue end, ...                */
       move.l    D6,A0
       move.l    D6,A1
       move.l    16(A0),D0
       cmp.l     8(A1),D0
       bne.s     OSEventPendMulti_36
; pq->OSQOut  = pq->OSQStart;    /* ... wrap   to queue start                   */
       move.l    D6,A0
       move.l    D6,A1
       move.l    4(A0),16(A1)
OSEventPendMulti_36:
; }
; pq->OSQEntries--;                  /* Update number of queue entries              */
       move.l    D6,D0
       add.l     #22,D0
       move.l    D0,A0
       subq.w    #1,(A0)
; *pevents_rdy++ = pevent;            /* ... and return available queue event        */
       move.l    D5,A0
       addq.l    #4,D5
       move.l    D2,(A0)
; events_rdy   = OS_TRUE;
       move.b    #1,-2(A6)
; events_rdy_nbr++;
       addq.w    #1,D3
       bra.s     OSEventPendMulti_35
OSEventPendMulti_34:
; } else {
; events_stat |= OS_STAT_Q;         /* Configure multi-pend for queue events       */
       or.b      #4,-1(A6)
OSEventPendMulti_35:
; }
; break;
       bra.s     OSEventPendMulti_22
OSEventPendMulti_27:
; #endif
; case OS_EVENT_TYPE_MUTEX:
; case OS_EVENT_TYPE_FLAG:
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; *pevents_rdy = (OS_EVENT *)0;           /* NULL terminate return event array           */
       move.l    D5,A0
       clr.l     (A0)
; *perr        =  OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return (events_rdy_nbr);
       move.w    D3,D0
       bra       OSEventPendMulti_13
OSEventPendMulti_22:
; }
; pevents++;
       addq.l    #4,D7
; pevent = *pevents;
       move.l    D7,A0
       move.l    (A0),D2
       bra       OSEventPendMulti_18
OSEventPendMulti_20:
; }
; if ( events_rdy == OS_TRUE) {                       /* Return any events already available         */
       move.b    -2(A6),D0
       cmp.b     #1,D0
       bne.s     OSEventPendMulti_38
; *pevents_rdy = (OS_EVENT *)0;                    /* NULL terminate return event array           */
       move.l    D5,A0
       clr.l     (A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr        =  OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; return (events_rdy_nbr);
       move.w    D3,D0
       bra       OSEventPendMulti_13
OSEventPendMulti_38:
; }
; /*$PAGE*/
; /* Otherwise, must wait until any event occurs */
; OSTCBCur->OSTCBStat     |= events_stat  |           /* Resource not available, ...                 */
       move.l    (A2),A0
       move.b    -1(A6),D0
       or.b      #128,D0
       or.b      D0,50(A0)
; OS_STAT_MULTI;           /* ... pend on multiple events                 */
; OSTCBCur->OSTCBStatPend  = OS_STAT_PEND_OK;
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBDly       = timeout;                 /* Store pend timeout in TCB                   */
       move.l    (A2),A0
       move.l    20(A6),46(A0)
; OS_EventTaskWaitMulti(pevents_pend);                /* Suspend task until events or timeout occurs */
       move.l    A4,-(A7)
       jsr       _OS_EventTaskWaitMulti
       addq.w    #4,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                         /* Find next highest priority task ready       */
       jsr       _OS_Sched
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; switch (OSTCBCur->OSTCBStatPend) {                  /* Handle event posted, aborted, or timed-out  */
       move.l    (A2),A0
       move.b    51(A0),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq       OSEventPendMulti_44
       bhi.s     OSEventPendMulti_46
       tst.l     D0
       beq.s     OSEventPendMulti_42
       bra       OSEventPendMulti_44
OSEventPendMulti_46:
       cmp.l     #2,D0
       beq.s     OSEventPendMulti_42
       bra       OSEventPendMulti_44
OSEventPendMulti_42:
; case OS_STAT_PEND_OK:
; case OS_STAT_PEND_ABORT:
; pevent = OSTCBCur->OSTCBEventPtr;
       move.l    (A2),A0
       move.l    28(A0),D2
; if (pevent != (OS_EVENT *)0) {             /* If task event ptr != NULL, ...              */
       tst.l     D2
       beq.s     OSEventPendMulti_47
; *pevents_rdy++   =  pevent;             /* ... return available event ...              */
       move.l    D5,A0
       addq.l    #4,D5
       move.l    D2,(A0)
; *pevents_rdy     = (OS_EVENT *)0;       /* ... & NULL terminate return event array     */
       move.l    D5,A0
       clr.l     (A0)
; events_rdy_nbr =  1;
       moveq     #1,D3
       bra.s     OSEventPendMulti_48
OSEventPendMulti_47:
; } else {                                   /* Else NO event available, handle as timeout  */
; OSTCBCur->OSTCBStatPend = OS_STAT_PEND_TO;
       move.l    (A2),A0
       move.b    #1,51(A0)
; OS_EventTaskRemoveMulti(OSTCBCur, pevents_pend);
       move.l    A4,-(A7)
       move.l    (A2),-(A7)
       jsr       _OS_EventTaskRemoveMulti
       addq.w    #8,A7
OSEventPendMulti_48:
; }
; break;
       bra.s     OSEventPendMulti_41
OSEventPendMulti_44:
; case OS_STAT_PEND_TO:                           /* If events timed out, ...                    */
; default:                                        /* ... remove task from events' wait lists     */
; OS_EventTaskRemoveMulti(OSTCBCur, pevents_pend);
       move.l    A4,-(A7)
       move.l    (A2),-(A7)
       jsr       _OS_EventTaskRemoveMulti
       addq.w    #8,A7
; break;
OSEventPendMulti_41:
; }
; switch (OSTCBCur->OSTCBStatPend) {
       move.l    (A2),A0
       move.b    51(A0),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq       OSEventPendMulti_53
       bhi.s     OSEventPendMulti_55
       tst.l     D0
       beq.s     OSEventPendMulti_51
       bra       OSEventPendMulti_53
OSEventPendMulti_55:
       cmp.l     #2,D0
       beq       OSEventPendMulti_52
       bra       OSEventPendMulti_53
OSEventPendMulti_51:
; case OS_STAT_PEND_OK:
; switch (pevent->OSEventType) {             /* Return event's message                      */
       move.l    D2,A0
       move.b    (A0),D0
       and.l     #255,D0
       subq.l    #1,D0
       blo.s     OSEventPendMulti_62
       cmp.l     #5,D0
       bhs.s     OSEventPendMulti_62
       asl.l     #1,D0
       move.w    OSEventPendMulti_58(PC,D0.L),D0
       jmp       OSEventPendMulti_58(PC,D0.W)
OSEventPendMulti_58:
       dc.w      OSEventPendMulti_60-OSEventPendMulti_58
       dc.w      OSEventPendMulti_60-OSEventPendMulti_58
       dc.w      OSEventPendMulti_59-OSEventPendMulti_58
       dc.w      OSEventPendMulti_62-OSEventPendMulti_58
       dc.w      OSEventPendMulti_62-OSEventPendMulti_58
OSEventPendMulti_59:
; #if (OS_SEM_EN > 0u)
; case OS_EVENT_TYPE_SEM:
; *pmsgs_rdy++ = (void *)0;          /* NO message returned for semaphores          */
       clr.l     (A3)+
; break;
       bra.s     OSEventPendMulti_57
OSEventPendMulti_60:
; #endif
; #if ((OS_MBOX_EN > 0u) ||                 \
; ((OS_Q_EN    > 0u) && (OS_MAX_QS > 0u)))
; case OS_EVENT_TYPE_MBOX:
; case OS_EVENT_TYPE_Q:
; *pmsgs_rdy++ = (void *)OSTCBCur->OSTCBMsg;     /* Return received message         */
       move.l    (A2),A0
       move.l    36(A0),(A3)+
; break;
       bra.s     OSEventPendMulti_57
OSEventPendMulti_62:
; #endif
; case OS_EVENT_TYPE_MUTEX:
; case OS_EVENT_TYPE_FLAG:
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; *pevents_rdy = (OS_EVENT *)0;      /* NULL terminate return event array           */
       move.l    D5,A0
       clr.l     (A0)
; *perr        =  OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return (events_rdy_nbr);
       move.w    D3,D0
       bra       OSEventPendMulti_13
OSEventPendMulti_57:
; }
; *perr = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; break;
       bra.s     OSEventPendMulti_50
OSEventPendMulti_52:
; case OS_STAT_PEND_ABORT:
; *pmsgs_rdy++ = (void *)0;                   /* NO message returned for abort               */
       clr.l     (A3)+
; *perr        =  OS_ERR_PEND_ABORT;          /* Indicate that event  aborted                */
       move.l    D4,A0
       move.b    #14,(A0)
; break;
       bra.s     OSEventPendMulti_50
OSEventPendMulti_53:
; case OS_STAT_PEND_TO:
; default:
; *pmsgs_rdy++ = (void *)0;                   /* NO message returned for timeout             */
       clr.l     (A3)+
; *perr        =  OS_ERR_TIMEOUT;             /* Indicate that events timed out              */
       move.l    D4,A0
       move.b    #10,(A0)
; break;
OSEventPendMulti_50:
; }
; OSTCBCur->OSTCBStat          =  OS_STAT_RDY;        /* Set   task  status to ready                 */
       move.l    (A2),A0
       clr.b     50(A0)
; OSTCBCur->OSTCBStatPend      =  OS_STAT_PEND_OK;    /* Clear pend  status                          */
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBEventPtr      = (OS_EVENT  *)0;      /* Clear event pointers                        */
       move.l    (A2),A0
       clr.l     28(A0)
; OSTCBCur->OSTCBEventMultiPtr = (OS_EVENT **)0;
       move.l    (A2),A0
       clr.l     32(A0)
; #if ((OS_MBOX_EN > 0u) ||                 \
; ((OS_Q_EN    > 0u) && (OS_MAX_QS > 0u)))
; OSTCBCur->OSTCBMsg           = (void      *)0;      /* Clear task  message                         */
       move.l    (A2),A0
       clr.l     36(A0)
; #endif
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (events_rdy_nbr);
       move.w    D3,D0
OSEventPendMulti_13:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           INITIALIZATION
; *
; * Description: This function is used to initialize the internals of uC/OS-II and MUST be called prior to
; *              creating any uC/OS-II object and, prior to calling OSStart().
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; void  OSInit (void)
; {
       xdef      _OSInit
_OSInit:
; OSInitHookBegin();                                           /* Call port specific initialization code   */
       jsr       _OSInitHookBegin
; OS_InitMisc();                                               /* Initialize miscellaneous variables       */
       jsr       @ucos_ii_OS_InitMisc
; OS_InitRdyList();                                            /* Initialize the Ready List                */
       jsr       @ucos_ii_OS_InitRdyList
; OS_InitTCBList();                                            /* Initialize the free list of OS_TCBs      */
       jsr       @ucos_ii_OS_InitTCBList
; OS_InitEventList();                                          /* Initialize the free list of OS_EVENTs    */
       jsr       @ucos_ii_OS_InitEventList
; #if (OS_FLAG_EN > 0u) && (OS_MAX_FLAGS > 0u)
; OS_FlagInit();                                               /* Initialize the event flag structures     */
       jsr       _OS_FlagInit
; #endif
; #if (OS_MEM_EN > 0u) && (OS_MAX_MEM_PART > 0u)
; OS_MemInit();                                                /* Initialize the memory manager            */
       jsr       _OS_MemInit
; #endif
; #if (OS_Q_EN > 0u) && (OS_MAX_QS > 0u)
; OS_QInit();                                                  /* Initialize the message queue structures  */
       jsr       _OS_QInit
; #endif
; OS_InitTaskIdle();                                           /* Create the Idle Task                     */
       jsr       @ucos_ii_OS_InitTaskIdle
; #if OS_TASK_STAT_EN > 0u
; OS_InitTaskStat();                                           /* Create the Statistic Task                */
       jsr       @ucos_ii_OS_InitTaskStat
; #endif
; #if OS_TMR_EN > 0u
; OSTmr_Init();                                                /* Initialize the Timer Manager             */
       jsr       _OSTmr_Init
; #endif
; OSInitHookEnd();                                             /* Call port specific init. code            */
       jsr       _OSInitHookEnd
       rts
; #if OS_DEBUG_EN > 0u
; OSDebugInit();
; #endif
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                              ENTER ISR
; *
; * Description: This function is used to notify uC/OS-II that you are about to service an interrupt
; *              service routine (ISR).  This allows uC/OS-II to keep track of interrupt nesting and thus
; *              only perform rescheduling at the last nested ISR.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Notes      : 1) This function should be called with interrupts already disabled
; *              2) Your ISR can directly increment OSIntNesting without calling this function because
; *                 OSIntNesting has been declared 'global'.
; *              3) You MUST still call OSIntExit() even though you increment OSIntNesting directly.
; *              4) You MUST invoke OSIntEnter() and OSIntExit() in pair.  In other words, for every call
; *                 to OSIntEnter() at the beginning of the ISR you MUST have a call to OSIntExit() at the
; *                 end of the ISR.
; *              5) You are allowed to nest interrupts up to 255 levels deep.
; *              6) I removed the OS_ENTER_CRITICAL() and OS_EXIT_CRITICAL() around the increment because
; *                 OSIntEnter() is always called with interrupts disabled.
; *********************************************************************************************************
; */
; void  OSIntEnter (void)
; {
       xdef      _OSIntEnter
_OSIntEnter:
; if (OSRunning == OS_TRUE) {
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne.s     OSIntEnter_3
; if (OSIntNesting < 255u) {
       move.b    _OSIntNesting.L,D0
       cmp.b     #255,D0
       bhs.s     OSIntEnter_3
; OSIntNesting++;                      /* Increment ISR nesting level                        */
       addq.b    #1,_OSIntNesting.L
OSIntEnter_3:
       rts
; }
; }
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                              EXIT ISR
; *
; * Description: This function is used to notify uC/OS-II that you have completed servicing an ISR.  When
; *              the last nested ISR has completed, uC/OS-II will call the scheduler to determine whether
; *              a new, high-priority task, is ready to run.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Notes      : 1) You MUST invoke OSIntEnter() and OSIntExit() in pair.  In other words, for every call
; *                 to OSIntEnter() at the beginning of the ISR you MUST have a call to OSIntExit() at the
; *                 end of the ISR.
; *              2) Rescheduling is prevented when the scheduler is locked (see OS_SchedLock())
; *********************************************************************************************************
; */
; void  OSIntExit (void)
; {
       xdef      _OSIntExit
_OSIntExit:
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; if (OSRunning == OS_TRUE) {
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne       OSIntExit_1
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSIntNesting > 0u) {                           /* Prevent OSIntNesting from wrapping       */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSIntExit_3
; OSIntNesting--;
       subq.b    #1,_OSIntNesting.L
OSIntExit_3:
; }
; if (OSIntNesting == 0u) {                          /* Reschedule only if all ISRs complete ... */
       move.b    _OSIntNesting.L,D0
       bne       OSIntExit_9
; if (OSLockNesting == 0u) {                     /* ... and not locked.                      */
       move.b    _OSLockNesting.L,D0
       bne.s     OSIntExit_9
; OS_SchedNew();
       jsr       @ucos_ii_OS_SchedNew
; OSTCBHighRdy = OSTCBPrioTbl[OSPrioHighRdy];
       move.b    _OSPrioHighRdy.L,D0
       and.l     #255,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),_OSTCBHighRdy.L
; if (OSPrioHighRdy != OSPrioCur) {          /* No Ctx Sw if current task is highest rdy */
       move.b    _OSPrioHighRdy.L,D0
       cmp.b     _OSPrioCur.L,D0
       beq.s     OSIntExit_9
; #if OS_TASK_PROFILE_EN > 0u
; OSTCBHighRdy->OSTCBCtxSwCtr++;         /* Inc. # of context switches to this task  */
       move.l    _OSTCBHighRdy.L,D0
       add.l     #58,D0
       move.l    D0,A0
       addq.l    #1,(A0)
; #endif
; OSCtxSwCtr++;                          /* Keep track of the number of ctx switches */
       addq.l    #1,_OSCtxSwCtr.L
; OSIntCtxSw();                          /* Perform interrupt level ctx switch       */
       jsr       _OSIntCtxSw
OSIntExit_9:
; }
; }
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
OSIntExit_1:
       rts
; }
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                         INDICATE THAT IT'S NO LONGER SAFE TO CREATE OBJECTS
; *
; * Description: This function is called by the application code to indicate that all initialization has
; *              been completed and that kernel objects are no longer allowed to be created.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Note(s)    : 1) You should call this function when you no longer want to allow application code to
; *                 create kernel objects.
; *              2) You need to define the macro 'OS_SAFETY_CRITICAL_IEC61508'
; *********************************************************************************************************
; */
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; void  OSSafetyCriticalStart (void)
; {
; OSSafetyCriticalStartFlag = OS_TRUE;
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                         PREVENT SCHEDULING
; *
; * Description: This function is used to prevent rescheduling to take place.  This allows your application
; *              to prevent context switches until you are ready to permit context switching.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Notes      : 1) You MUST invoke OSSchedLock() and OSSchedUnlock() in pair.  In other words, for every
; *                 call to OSSchedLock() you MUST have a call to OSSchedUnlock().
; *********************************************************************************************************
; */
; #if OS_SCHED_LOCK_EN > 0u
; void  OSSchedLock (void)
; {
       xdef      _OSSchedLock
_OSSchedLock:
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; if (OSRunning == OS_TRUE) {                  /* Make sure multitasking is running                  */
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne.s     OSSchedLock_1
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSIntNesting == 0u) {                /* Can't call from an ISR                             */
       move.b    _OSIntNesting.L,D0
       bne.s     OSSchedLock_5
; if (OSLockNesting < 255u) {          /* Prevent OSLockNesting from wrapping back to 0      */
       move.b    _OSLockNesting.L,D0
       cmp.b     #255,D0
       bhs.s     OSSchedLock_5
; OSLockNesting++;                 /* Increment lock nesting level                       */
       addq.b    #1,_OSLockNesting.L
OSSchedLock_5:
; }
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
OSSchedLock_1:
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                          ENABLE SCHEDULING
; *
; * Description: This function is used to re-allow rescheduling.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Notes      : 1) You MUST invoke OSSchedLock() and OSSchedUnlock() in pair.  In other words, for every
; *                 call to OSSchedLock() you MUST have a call to OSSchedUnlock().
; *********************************************************************************************************
; */
; #if OS_SCHED_LOCK_EN > 0u
; void  OSSchedUnlock (void)
; {
       xdef      _OSSchedUnlock
_OSSchedUnlock:
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; if (OSRunning == OS_TRUE) {                            /* Make sure multitasking is running        */
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne       OSSchedUnlock_4
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSIntNesting == 0u) {                          /* Can't call from an ISR                   */
       move.b    _OSIntNesting.L,D0
       bne.s     OSSchedUnlock_3
; if (OSLockNesting > 0u) {                      /* Do not decrement if already 0            */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSSchedUnlock_5
; OSLockNesting--;                           /* Decrement lock nesting level             */
       subq.b    #1,_OSLockNesting.L
; if (OSLockNesting == 0u) {                 /* See if scheduler is enabled              */
       move.b    _OSLockNesting.L,D0
       bne.s     OSSchedUnlock_7
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                            /* See if a HPT is ready                    */
       jsr       _OS_Sched
       bra.s     OSSchedUnlock_8
OSSchedUnlock_7:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
OSSchedUnlock_8:
       bra.s     OSSchedUnlock_6
OSSchedUnlock_5:
; }
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
OSSchedUnlock_6:
       bra.s     OSSchedUnlock_4
OSSchedUnlock_3:
; }
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
OSSchedUnlock_4:
       rts
; }
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                         START MULTITASKING
; *
; * Description: This function is used to start the multitasking process which lets uC/OS-II manages the
; *              task that you have created.  Before you can call OSStart(), you MUST have called OSInit()
; *              and you MUST have created at least one task.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Note       : OSStartHighRdy() MUST:
; *                 a) Call OSTaskSwHook() then,
; *                 b) Set OSRunning to OS_TRUE.
; *                 c) Load the context of the task pointed to by OSTCBHighRdy.
; *                 d_ Execute the task.
; *********************************************************************************************************
; */
; void  OSStart (void)
; {
       xdef      _OSStart
_OSStart:
; if (OSRunning == OS_FALSE) {
       move.b    _OSRunning.L,D0
       bne.s     OSStart_1
; OS_SchedNew();                               /* Find highest priority's task priority number   */
       jsr       @ucos_ii_OS_SchedNew
; OSPrioCur     = OSPrioHighRdy;
       move.b    _OSPrioHighRdy.L,_OSPrioCur.L
; OSTCBHighRdy  = OSTCBPrioTbl[OSPrioHighRdy]; /* Point to highest priority task ready to run    */
       move.b    _OSPrioHighRdy.L,D0
       and.l     #255,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),_OSTCBHighRdy.L
; OSTCBCur      = OSTCBHighRdy;
       move.l    _OSTCBHighRdy.L,_OSTCBCur.L
; OSStartHighRdy();                            /* Execute target specific code to start task     */
       jsr       _OSStartHighRdy
OSStart_1:
       rts
; }
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                      STATISTICS INITIALIZATION
; *
; * Description: This function is called by your application to establish CPU usage by first determining
; *              how high a 32-bit counter would count to in 1 second if no other tasks were to execute
; *              during that time.  CPU usage is then determined by a low priority task which keeps track
; *              of this 32-bit counter every second but this time, with other tasks running.  CPU usage is
; *              determined by:
; *
; *                                             OSIdleCtr
; *                 CPU Usage (%) = 100 * (1 - ------------)
; *                                            OSIdleCtrMax
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TASK_STAT_EN > 0u
; void  OSStatInit (void)
; {
       xdef      _OSStatInit
_OSStatInit:
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; OSTimeDly(2u);                               /* Synchronize with clock tick                        */
       pea       2
       jsr       _OSTimeDly
       addq.w    #4,A7
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSIdleCtr    = 0uL;                          /* Clear idle counter                                 */
       clr.l     _OSIdleCtr.L
; OS_EXIT_CRITICAL();
       dc.w      18143
; OSTimeDly(OS_TICKS_PER_SEC / 10u);           /* Determine MAX. idle counter value for 1/10 second  */
       pea       10
       jsr       _OSTimeDly
       addq.w    #4,A7
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSIdleCtrMax = OSIdleCtr;                    /* Store maximum idle counter count in 1/10 second    */
       move.l    _OSIdleCtr.L,_OSIdleCtrMax.L
; OSStatRdy    = OS_TRUE;
       move.b    #1,_OSStatRdy.L
; OS_EXIT_CRITICAL();
       dc.w      18143
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                         PROCESS SYSTEM TICK
; *
; * Description: This function is used to signal to uC/OS-II the occurrence of a 'system tick' (also known
; *              as a 'clock tick').  This function should be called by the ticker ISR but, can also be
; *              called by a high priority task.
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; void  OSTimeTick (void)
; {
       xdef      _OSTimeTick
_OSTimeTick:
       move.l    D2,-(A7)
; OS_TCB    *ptcb;
; #if OS_TICK_STEP_EN > 0u
; BOOLEAN    step;
; #endif
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register     */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_TIME_TICK_HOOK_EN > 0u
; OSTimeTickHook();                                      /* Call user definable hook                     */
       jsr       _OSTimeTickHook
; #endif
; #if OS_TIME_GET_SET_EN > 0u
; OS_ENTER_CRITICAL();                                   /* Update the 32-bit tick counter               */
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSTime++;
       addq.l    #1,_OSTime.L
; OS_EXIT_CRITICAL();
       dc.w      18143
; #endif
; if (OSRunning == OS_TRUE) {
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne       OSTimeTick_5
; #if OS_TICK_STEP_EN > 0u
; switch (OSTickStepState) {                         /* Determine whether we need to process a tick  */
; case OS_TICK_STEP_DIS:                         /* Yes, stepping is disabled                    */
; step = OS_TRUE;
; break;
; case OS_TICK_STEP_WAIT:                        /* No,  waiting for uC/OS-View to set ...       */
; step = OS_FALSE;                          /*      .. OSTickStepState to OS_TICK_STEP_ONCE */
; break;
; case OS_TICK_STEP_ONCE:                        /* Yes, process tick once and wait for next ... */
; step            = OS_TRUE;                /*      ... step command from uC/OS-View        */
; OSTickStepState = OS_TICK_STEP_WAIT;
; break;
; default:                                       /* Invalid case, correct situation              */
; step            = OS_TRUE;
; OSTickStepState = OS_TICK_STEP_DIS;
; break;
; }
; if (step == OS_FALSE) {                            /* Return if waiting for step command           */
; return;
; }
; #endif
; ptcb = OSTCBList;                                  /* Point at first TCB in TCB list               */
       move.l    _OSTCBList.L,D2
; while (ptcb->OSTCBPrio != OS_TASK_IDLE_PRIO) {     /* Go through all TCBs in TCB list              */
OSTimeTick_3:
       move.l    D2,A0
       move.b    52(A0),D0
       cmp.b     #63,D0
       beq       OSTimeTick_5
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (ptcb->OSTCBDly != 0u) {                    /* No, Delayed or waiting for event with TO     */
       move.l    D2,A0
       move.l    46(A0),D0
       beq       OSTimeTick_12
; ptcb->OSTCBDly--;                          /* Decrement nbr of ticks to end of delay       */
       move.l    D2,D0
       add.l     #46,D0
       move.l    D0,A0
       subq.l    #1,(A0)
; if (ptcb->OSTCBDly == 0u) {                /* Check for timeout                            */
       move.l    D2,A0
       move.l    46(A0),D0
       bne       OSTimeTick_12
; if ((ptcb->OSTCBStat & OS_STAT_PEND_ANY) != OS_STAT_RDY) {
       move.l    D2,A0
       move.b    50(A0),D0
       and.b     #55,D0
       beq.s     OSTimeTick_10
; ptcb->OSTCBStat  &= (INT8U)~(INT8U)OS_STAT_PEND_ANY;          /* Yes, Clear status flag   */
       move.l    D2,A0
       moveq     #55,D0
       not.b     D0
       and.b     D0,50(A0)
; ptcb->OSTCBStatPend = OS_STAT_PEND_TO;                 /* Indicate PEND timeout    */
       move.l    D2,A0
       move.b    #1,51(A0)
       bra.s     OSTimeTick_11
OSTimeTick_10:
; } else {
; ptcb->OSTCBStatPend = OS_STAT_PEND_OK;
       move.l    D2,A0
       clr.b     51(A0)
OSTimeTick_11:
; }
; if ((ptcb->OSTCBStat & OS_STAT_SUSPEND) == OS_STAT_RDY) {  /* Is task suspended?       */
       move.l    D2,A0
       move.b    50(A0),D0
       and.b     #8,D0
       bne.s     OSTimeTick_12
; OSRdyGrp               |= ptcb->OSTCBBitY;             /* No,  Make ready          */
       move.l    D2,A0
       move.b    56(A0),D0
       or.b      D0,_OSRdyGrp.L
; OSRdyTbl[ptcb->OSTCBY] |= ptcb->OSTCBBitX;
       move.l    D2,A0
       move.b    54(A0),D0
       and.l     #255,D0
       lea       _OSRdyTbl.L,A0
       move.l    D2,A1
       move.b    55(A1),D1
       or.b      D1,0(A0,D0.L)
OSTimeTick_12:
; }
; }
; }
; ptcb = ptcb->OSTCBNext;                        /* Point at next TCB in TCB list                */
       move.l    D2,A0
       move.l    20(A0),D2
; OS_EXIT_CRITICAL();
       dc.w      18143
       bra       OSTimeTick_3
OSTimeTick_5:
       move.l    (A7)+,D2
       rts
; }
; }
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                             GET VERSION
; *
; * Description: This function is used to return the version number of uC/OS-II.  The returned value 
; *              corresponds to uC/OS-II's version number multiplied by 10000.  In other words, version 
; *              2.01.00 would be returned as 20100.
; *
; * Arguments  : none
; *
; * Returns    : The version number of uC/OS-II multiplied by 10000.
; *********************************************************************************************************
; */
; INT16U  OSVersion (void)
; {
       xdef      _OSVersion
_OSVersion:
; return (OS_VERSION);
       move.w    #29207,D0
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           DUMMY FUNCTION
; *
; * Description: This function doesn't do anything.  It is called by OSTaskDel().
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TASK_DEL_EN > 0u
; void  OS_Dummy (void)
; {
       xdef      _OS_Dummy
_OS_Dummy:
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                           MAKE TASK READY TO RUN BASED ON EVENT OCCURING
; *
; * Description: This function is called by other uC/OS-II services and is used to ready a task that was
; *              waiting for an event to occur.
; *
; * Arguments  : pevent      is a pointer to the event control block corresponding to the event.
; *
; *              pmsg        is a pointer to a message.  This pointer is used by message oriented services
; *                          such as MAILBOXEs and QUEUEs.  The pointer is not used when called by other
; *                          service functions.
; *
; *              msk         is a mask that is used to clear the status byte of the TCB.  For example,
; *                          OSSemPost() will pass OS_STAT_SEM, OSMboxPost() will pass OS_STAT_MBOX etc.
; *
; *              pend_stat   is used to indicate the readied task's pending status:
; *
; *                          OS_STAT_PEND_OK      Task ready due to a post (or delete), not a timeout or
; *                                               an abort.
; *                          OS_STAT_PEND_ABORT   Task ready due to an abort.
; *
; * Returns    : none
; *
; * Note       : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; #if (OS_EVENT_EN)
; INT8U  OS_EventTaskRdy (OS_EVENT  *pevent,
; void      *pmsg,
; INT8U      msk,
; INT8U      pend_stat)
; {
       xdef      _OS_EventTaskRdy
_OS_EventTaskRdy:
       link      A6,#-4
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    8(A6),D3
; OS_TCB   *ptcb;
; INT8U     y;
; INT8U     x;
; INT8U     prio;
; #if OS_LOWEST_PRIO > 63u
; OS_PRIO  *ptbl;
; #endif
; #if OS_LOWEST_PRIO <= 63u
; y    = OSUnMapTbl[pevent->OSEventGrp];              /* Find HPT waiting for message                */
       move.l    D3,A0
       move.b    8(A0),D0
       and.l     #255,D0
       lea       _OSUnMapTbl.L,A0
       move.b    0(A0,D0.L),D4
; x    = OSUnMapTbl[pevent->OSEventTbl[y]];
       move.l    D3,A0
       and.l     #255,D4
       add.l     D4,A0
       move.b    10(A0),D0
       and.l     #255,D0
       lea       _OSUnMapTbl.L,A0
       move.b    0(A0,D0.L),-1(A6)
; prio = (INT8U)((y << 3u) + x);                      /* Find priority of task getting the msg       */
       move.b    D4,D0
       lsl.b     #3,D0
       add.b     -1(A6),D0
       move.b    D0,D5
; #else
; if ((pevent->OSEventGrp & 0xFFu) != 0u) {           /* Find HPT waiting for message                */
; y = OSUnMapTbl[ pevent->OSEventGrp & 0xFFu];
; } else {
; y = OSUnMapTbl[(OS_PRIO)(pevent->OSEventGrp >> 8u) & 0xFFu] + 8u;
; }
; ptbl = &pevent->OSEventTbl[y];
; if ((*ptbl & 0xFFu) != 0u) {
; x = OSUnMapTbl[*ptbl & 0xFFu];
; } else {
; x = OSUnMapTbl[(OS_PRIO)(*ptbl >> 8u) & 0xFFu] + 8u;
; }
; prio = (INT8U)((y << 4u) + x);                      /* Find priority of task getting the msg       */
; #endif
; ptcb                  =  OSTCBPrioTbl[prio];        /* Point to this task's OS_TCB                 */
       and.l     #255,D5
       move.l    D5,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; ptcb->OSTCBDly        =  0u;                        /* Prevent OSTimeTick() from readying task     */
       move.l    D2,A0
       clr.l     46(A0)
; #if ((OS_Q_EN > 0u) && (OS_MAX_QS > 0u)) || (OS_MBOX_EN > 0u)
; ptcb->OSTCBMsg        =  pmsg;                      /* Send message directly to waiting task       */
       move.l    D2,A0
       move.l    12(A6),36(A0)
; #else
; pmsg                  =  pmsg;                      /* Prevent compiler warning if not used        */
; #endif
; ptcb->OSTCBStat      &= (INT8U)~msk;                /* Clear bit associated with event type        */
       move.l    D2,A0
       move.b    19(A6),D0
       not.b     D0
       and.b     D0,50(A0)
; ptcb->OSTCBStatPend   =  pend_stat;                 /* Set pend status of post or abort            */
       move.l    D2,A0
       move.b    23(A6),51(A0)
; /* See if task is ready (could be susp'd)      */
; if ((ptcb->OSTCBStat &   OS_STAT_SUSPEND) == OS_STAT_RDY) {
       move.l    D2,A0
       move.b    50(A0),D0
       and.b     #8,D0
       bne.s     OS_EventTaskRdy_1
; OSRdyGrp         |=  ptcb->OSTCBBitY;           /* Put task in the ready to run list           */
       move.l    D2,A0
       move.b    56(A0),D0
       or.b      D0,_OSRdyGrp.L
; OSRdyTbl[y]      |=  ptcb->OSTCBBitX;
       and.l     #255,D4
       lea       _OSRdyTbl.L,A0
       move.l    D2,A1
       move.b    55(A1),D0
       or.b      D0,0(A0,D4.L)
OS_EventTaskRdy_1:
; }
; OS_EventTaskRemove(ptcb, pevent);                   /* Remove this task from event   wait list     */
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRemove
       addq.w    #8,A7
; #if (OS_EVENT_MULTI_EN > 0u)
; if (ptcb->OSTCBEventMultiPtr != (OS_EVENT **)0) {   /* Remove this task from events' wait lists    */
       move.l    D2,A0
       move.l    32(A0),D0
       beq.s     OS_EventTaskRdy_3
; OS_EventTaskRemoveMulti(ptcb, ptcb->OSTCBEventMultiPtr);
       move.l    D2,A0
       move.l    32(A0),-(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRemoveMulti
       addq.w    #8,A7
; ptcb->OSTCBEventPtr       = (OS_EVENT  *)pevent;/* Return event as first multi-pend event ready*/
       move.l    D2,A0
       move.l    D3,28(A0)
OS_EventTaskRdy_3:
; }
; #endif
; return (prio);
       move.b    D5,D0
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                  MAKE TASK WAIT FOR EVENT TO OCCUR
; *
; * Description: This function is called by other uC/OS-II services to suspend a task because an event has
; *              not occurred.
; *
; * Arguments  : pevent   is a pointer to the event control block for which the task will be waiting for.
; *
; * Returns    : none
; *
; * Note       : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; #if (OS_EVENT_EN)
; void  OS_EventTaskWait (OS_EVENT *pevent)
; {
       xdef      _OS_EventTaskWait
_OS_EventTaskWait:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       lea       _OSTCBCur.L,A2
       move.l    8(A6),D3
; INT8U  y;
; OSTCBCur->OSTCBEventPtr               = pevent;                 /* Store ptr to ECB in TCB         */
       move.l    (A2),A0
       move.l    D3,28(A0)
; pevent->OSEventTbl[OSTCBCur->OSTCBY] |= OSTCBCur->OSTCBBitX;    /* Put task in waiting list        */
       move.l    D3,A0
       move.l    (A2),A1
       move.b    54(A1),D0
       and.l     #255,D0
       add.l     D0,A0
       move.l    (A2),A1
       move.b    55(A1),D0
       or.b      D0,10(A0)
; pevent->OSEventGrp                   |= OSTCBCur->OSTCBBitY;
       move.l    D3,A0
       move.l    (A2),A1
       move.b    56(A1),D0
       or.b      D0,8(A0)
; y             =  OSTCBCur->OSTCBY;            /* Task no longer ready                              */
       move.l    (A2),A0
       move.b    54(A0),D2
; OSRdyTbl[y]  &= (OS_PRIO)~OSTCBCur->OSTCBBitX;
       and.l     #255,D2
       lea       _OSRdyTbl.L,A0
       move.l    (A2),A1
       move.b    55(A1),D0
       not.b     D0
       and.b     D0,0(A0,D2.L)
; if (OSRdyTbl[y] == 0u) {                      /* Clear event grp bit if this was only task pending */
       and.l     #255,D2
       lea       _OSRdyTbl.L,A0
       move.b    0(A0,D2.L),D0
       bne.s     OS_EventTaskWait_1
; OSRdyGrp &= (OS_PRIO)~OSTCBCur->OSTCBBitY;
       move.l    (A2),A0
       move.b    56(A0),D0
       not.b     D0
       and.b     D0,_OSRdyGrp.L
OS_EventTaskWait_1:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                         MAKE TASK WAIT FOR ANY OF MULTIPLE EVENTS TO OCCUR
; *
; * Description: This function is called by other uC/OS-II services to suspend a task because any one of
; *              multiple events has not occurred.
; *
; * Arguments  : pevents_wait     is a pointer to an array of event control blocks, NULL-terminated, for
; *                               which the task will be waiting for.
; *
; * Returns    : none.
; *
; * Note       : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; #if ((OS_EVENT_EN) && (OS_EVENT_MULTI_EN > 0u))
; void  OS_EventTaskWaitMulti (OS_EVENT **pevents_wait)
; {
       xdef      _OS_EventTaskWaitMulti
_OS_EventTaskWaitMulti:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _OSTCBCur.L,A2
; OS_EVENT **pevents;
; OS_EVENT  *pevent;
; INT8U      y;
; OSTCBCur->OSTCBEventPtr      = (OS_EVENT  *)0;
       move.l    (A2),A0
       clr.l     28(A0)
; OSTCBCur->OSTCBEventMultiPtr = (OS_EVENT **)pevents_wait;       /* Store ptr to ECBs in TCB        */
       move.l    (A2),A0
       move.l    8(A6),32(A0)
; pevents =  pevents_wait;
       move.l    8(A6),D3
; pevent  = *pevents;
       move.l    D3,A0
       move.l    (A0),D2
; while (pevent != (OS_EVENT *)0) {                               /* Put task in waiting lists       */
OS_EventTaskWaitMulti_1:
       tst.l     D2
       beq       OS_EventTaskWaitMulti_3
; pevent->OSEventTbl[OSTCBCur->OSTCBY] |= OSTCBCur->OSTCBBitX;
       move.l    D2,A0
       move.l    (A2),A1
       move.b    54(A1),D0
       and.l     #255,D0
       add.l     D0,A0
       move.l    (A2),A1
       move.b    55(A1),D0
       or.b      D0,10(A0)
; pevent->OSEventGrp                   |= OSTCBCur->OSTCBBitY;
       move.l    D2,A0
       move.l    (A2),A1
       move.b    56(A1),D0
       or.b      D0,8(A0)
; pevents++;
       addq.l    #4,D3
; pevent = *pevents;
       move.l    D3,A0
       move.l    (A0),D2
       bra       OS_EventTaskWaitMulti_1
OS_EventTaskWaitMulti_3:
; }
; y             =  OSTCBCur->OSTCBY;            /* Task no longer ready                              */
       move.l    (A2),A0
       move.b    54(A0),D4
; OSRdyTbl[y]  &= (OS_PRIO)~OSTCBCur->OSTCBBitX;
       and.l     #255,D4
       lea       _OSRdyTbl.L,A0
       move.l    (A2),A1
       move.b    55(A1),D0
       not.b     D0
       and.b     D0,0(A0,D4.L)
; if (OSRdyTbl[y] == 0u) {                      /* Clear event grp bit if this was only task pending */
       and.l     #255,D4
       lea       _OSRdyTbl.L,A0
       move.b    0(A0,D4.L),D0
       bne.s     OS_EventTaskWaitMulti_4
; OSRdyGrp &= (OS_PRIO)~OSTCBCur->OSTCBBitY;
       move.l    (A2),A0
       move.b    56(A0),D0
       not.b     D0
       and.b     D0,_OSRdyGrp.L
OS_EventTaskWaitMulti_4:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                  REMOVE TASK FROM EVENT WAIT LIST
; *
; * Description: Remove a task from an event's wait list.
; *
; * Arguments  : ptcb     is a pointer to the task to remove.
; *
; *              pevent   is a pointer to the event control block.
; *
; * Returns    : none
; *
; * Note       : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; #if (OS_EVENT_EN)
; void  OS_EventTaskRemove (OS_TCB   *ptcb,
; OS_EVENT *pevent)
; {
       xdef      _OS_EventTaskRemove
_OS_EventTaskRemove:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
       move.l    12(A6),D2
       move.l    8(A6),D3
; INT8U  y;
; y                       =  ptcb->OSTCBY;
       move.l    D3,A0
       move.b    54(A0),D4
; pevent->OSEventTbl[y]  &= (OS_PRIO)~ptcb->OSTCBBitX;    /* Remove task from wait list              */
       move.l    D2,A0
       and.l     #255,D4
       add.l     D4,A0
       move.l    D3,A1
       move.b    55(A1),D0
       not.b     D0
       and.b     D0,10(A0)
; if (pevent->OSEventTbl[y] == 0u) {
       move.l    D2,A0
       and.l     #255,D4
       add.l     D4,A0
       move.b    10(A0),D0
       bne.s     OS_EventTaskRemove_1
; pevent->OSEventGrp &= (OS_PRIO)~ptcb->OSTCBBitY;
       move.l    D2,A0
       move.l    D3,A1
       move.b    56(A1),D0
       not.b     D0
       and.b     D0,8(A0)
OS_EventTaskRemove_1:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                             REMOVE TASK FROM MULTIPLE EVENTS WAIT LISTS
; *
; * Description: Remove a task from multiple events' wait lists.
; *
; * Arguments  : ptcb             is a pointer to the task to remove.
; *
; *              pevents_multi    is a pointer to the array of event control blocks, NULL-terminated.
; *
; * Returns    : none
; *
; * Note       : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; #if ((OS_EVENT_EN) && (OS_EVENT_MULTI_EN > 0u))
; void  OS_EventTaskRemoveMulti (OS_TCB    *ptcb,
; OS_EVENT **pevents_multi)
; {
       xdef      _OS_EventTaskRemoveMulti
_OS_EventTaskRemoveMulti:
       link      A6,#-4
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    8(A6),D4
; OS_EVENT **pevents;
; OS_EVENT  *pevent;
; INT8U      y;
; OS_PRIO    bity;
; OS_PRIO    bitx;
; y       =  ptcb->OSTCBY;
       move.l    D4,A0
       move.b    54(A0),D5
; bity    =  ptcb->OSTCBBitY;
       move.l    D4,A0
       move.b    56(A0),-2(A6)
; bitx    =  ptcb->OSTCBBitX;
       move.l    D4,A0
       move.b    55(A0),-1(A6)
; pevents =  pevents_multi;
       move.l    12(A6),D3
; pevent  = *pevents;
       move.l    D3,A0
       move.l    (A0),D2
; while (pevent != (OS_EVENT *)0) {                   /* Remove task from all events' wait lists     */
OS_EventTaskRemoveMulti_1:
       tst.l     D2
       beq       OS_EventTaskRemoveMulti_3
; pevent->OSEventTbl[y]  &= (OS_PRIO)~bitx;
       move.l    D2,A0
       and.l     #255,D5
       add.l     D5,A0
       move.b    -1(A6),D0
       not.b     D0
       and.b     D0,10(A0)
; if (pevent->OSEventTbl[y] == 0u) {
       move.l    D2,A0
       and.l     #255,D5
       add.l     D5,A0
       move.b    10(A0),D0
       bne.s     OS_EventTaskRemoveMulti_4
; pevent->OSEventGrp &= (OS_PRIO)~bity;
       move.l    D2,A0
       move.b    -2(A6),D0
       not.b     D0
       and.b     D0,8(A0)
OS_EventTaskRemoveMulti_4:
; }
; pevents++;
       addq.l    #4,D3
; pevent = *pevents;
       move.l    D3,A0
       move.l    (A0),D2
       bra       OS_EventTaskRemoveMulti_1
OS_EventTaskRemoveMulti_3:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                             INITIALIZE EVENT CONTROL BLOCK'S WAIT LIST
; *
; * Description: This function is called by other uC/OS-II services to initialize the event wait list.
; *
; * Arguments  : pevent    is a pointer to the event control block allocated to the event.
; *
; * Returns    : none
; *
; * Note       : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; #if (OS_EVENT_EN)
; void  OS_EventWaitListInit (OS_EVENT *pevent)
; {
       xdef      _OS_EventWaitListInit
_OS_EventWaitListInit:
       link      A6,#0
       move.l    D2,-(A7)
; INT8U  i;
; pevent->OSEventGrp = 0u;                     /* No task waiting on event                           */
       move.l    8(A6),A0
       clr.b     8(A0)
; for (i = 0u; i < OS_EVENT_TBL_SIZE; i++) {
       clr.b     D2
OS_EventWaitListInit_1:
       cmp.b     #8,D2
       bhs.s     OS_EventWaitListInit_3
; pevent->OSEventTbl[i] = 0u;
       move.l    8(A6),A0
       and.l     #255,D2
       add.l     D2,A0
       clr.b     10(A0)
       addq.b    #1,D2
       bra       OS_EventWaitListInit_1
OS_EventWaitListInit_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                             INITIALIZATION
; *                           INITIALIZE THE FREE LIST OF EVENT CONTROL BLOCKS
; *
; * Description: This function is called by OSInit() to initialize the free list of event control blocks.
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; static  void  OS_InitEventList (void)
; {
@ucos_ii_OS_InitEventList:
       link      A6,#-8
       movem.l   D2/D3/A2,-(A7)
       lea       _OSEventTbl.L,A2
; #if (OS_EVENT_EN) && (OS_MAX_EVENTS > 0u)
; #if (OS_MAX_EVENTS > 1u)
; INT16U     ix;
; INT16U     ix_next;
; OS_EVENT  *pevent1;
; OS_EVENT  *pevent2;
; OS_MemClr((INT8U *)&OSEventTbl[0], sizeof(OSEventTbl)); /* Clear the event table                   */
       pea       220
       move.l    A2,-(A7)
       jsr       _OS_MemClr
       addq.w    #8,A7
; for (ix = 0u; ix < (OS_MAX_EVENTS - 1u); ix++) {        /* Init. list of free EVENT control blocks */
       clr.w     D3
@ucos_ii_OS_InitEventList_1:
       cmp.w     #9,D3
       bhs       @ucos_ii_OS_InitEventList_3
; ix_next = ix + 1u;
       move.w    D3,D0
       addq.w    #1,D0
       move.w    D0,-6(A6)
; pevent1 = &OSEventTbl[ix];
       move.l    A2,D0
       and.l     #65535,D3
       move.l    D3,D1
       muls      #22,D1
       add.l     D1,D0
       move.l    D0,D2
; pevent2 = &OSEventTbl[ix_next];
       move.l    A2,D0
       move.w    -6(A6),D1
       and.l     #65535,D1
       muls      #22,D1
       add.l     D1,D0
       move.l    D0,-4(A6)
; pevent1->OSEventType    = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent1->OSEventPtr     = pevent2;
       move.l    D2,A0
       move.l    -4(A6),2(A0)
; #if OS_EVENT_NAME_EN > 0u
; pevent1->OSEventName    = (INT8U *)(void *)"?";     /* Unknown name                            */
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
       addq.w    #1,D3
       bra       @ucos_ii_OS_InitEventList_1
@ucos_ii_OS_InitEventList_3:
; #endif
; }
; pevent1                         = &OSEventTbl[ix];
       move.l    A2,D0
       and.l     #65535,D3
       move.l    D3,D1
       muls      #22,D1
       add.l     D1,D0
       move.l    D0,D2
; pevent1->OSEventType            = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent1->OSEventPtr             = (OS_EVENT *)0;
       move.l    D2,A0
       clr.l     2(A0)
; #if OS_EVENT_NAME_EN > 0u
; pevent1->OSEventName            = (INT8U *)(void *)"?"; /* Unknown name                            */
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; OSEventFreeList                 = &OSEventTbl[0];
       move.l    A2,_OSEventFreeList.L
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; #else
; OSEventFreeList                 = &OSEventTbl[0];       /* Only have ONE event control block       */
; OSEventFreeList->OSEventType    = OS_EVENT_TYPE_UNUSED;
; OSEventFreeList->OSEventPtr     = (OS_EVENT *)0;
; #if OS_EVENT_NAME_EN > 0u
; OSEventFreeList->OSEventName    = (INT8U *)"?";         /* Unknown name                            */
; #endif
; #endif
; #endif
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                             INITIALIZATION
; *                                    INITIALIZE MISCELLANEOUS VARIABLES
; *
; * Description: This function is called by OSInit() to initialize miscellaneous variables.
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; static  void  OS_InitMisc (void)
; {
@ucos_ii_OS_InitMisc:
; #if OS_TIME_GET_SET_EN > 0u
; OSTime                    = 0uL;                       /* Clear the 32-bit system clock            */
       clr.l     _OSTime.L
; #endif
; OSIntNesting              = 0u;                        /* Clear the interrupt nesting counter      */
       clr.b     _OSIntNesting.L
; OSLockNesting             = 0u;                        /* Clear the scheduling lock counter        */
       clr.b     _OSLockNesting.L
; OSTaskCtr                 = 0u;                        /* Clear the number of tasks                */
       clr.b     _OSTaskCtr.L
; OSRunning                 = OS_FALSE;                  /* Indicate that multitasking not started   */
       clr.b     _OSRunning.L
; OSCtxSwCtr                = 0u;                        /* Clear the context switch counter         */
       clr.l     _OSCtxSwCtr.L
; OSIdleCtr                 = 0uL;                       /* Clear the 32-bit idle counter            */
       clr.l     _OSIdleCtr.L
; #if OS_TASK_STAT_EN > 0u
; OSIdleCtrRun              = 0uL;
       clr.l     _OSIdleCtrRun.L
; OSIdleCtrMax              = 0uL;
       clr.l     _OSIdleCtrMax.L
; OSStatRdy                 = OS_FALSE;                  /* Statistic task is not ready              */
       clr.b     _OSStatRdy.L
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; OSSafetyCriticalStartFlag = OS_FALSE;                  /* Still allow creation of objects          */
; #endif
; #if OS_TASK_REG_TBL_SIZE > 0u
; OSTaskRegNextAvailID      = 0u;                        /* Initialize the task register ID          */
       clr.b     _OSTaskRegNextAvailID.L
       rts
; #endif
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                             INITIALIZATION
; *                                       INITIALIZE THE READY LIST
; *
; * Description: This function is called by OSInit() to initialize the Ready List.
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; static  void  OS_InitRdyList (void)
; {
@ucos_ii_OS_InitRdyList:
       move.l    D2,-(A7)
; INT8U  i;
; OSRdyGrp      = 0u;                                    /* Clear the ready list                     */
       clr.b     _OSRdyGrp.L
; for (i = 0u; i < OS_RDY_TBL_SIZE; i++) {
       clr.b     D2
@ucos_ii_OS_InitRdyList_1:
       cmp.b     #8,D2
       bhs.s     @ucos_ii_OS_InitRdyList_3
; OSRdyTbl[i] = 0u;
       and.l     #255,D2
       lea       _OSRdyTbl.L,A0
       clr.b     0(A0,D2.L)
       addq.b    #1,D2
       bra       @ucos_ii_OS_InitRdyList_1
@ucos_ii_OS_InitRdyList_3:
; }
; OSPrioCur     = 0u;
       clr.b     _OSPrioCur.L
; OSPrioHighRdy = 0u;
       clr.b     _OSPrioHighRdy.L
; OSTCBHighRdy  = (OS_TCB *)0;
       clr.l     _OSTCBHighRdy.L
; OSTCBCur      = (OS_TCB *)0;
       clr.l     _OSTCBCur.L
       move.l    (A7)+,D2
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                             INITIALIZATION
; *                                         CREATING THE IDLE TASK
; *
; * Description: This function creates the Idle Task.
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; static  void  OS_InitTaskIdle (void)
; {
@ucos_ii_OS_InitTaskIdle:
       link      A6,#-4
; #if OS_TASK_NAME_EN > 0u
; INT8U  err;
; #endif
; #if OS_TASK_CREATE_EXT_EN > 0u
; #if OS_STK_GROWTH == 1u
; (void)OSTaskCreateExt(OS_TaskIdle,
       pea       3
       clr.l     -(A7)
       pea       128
       pea       _OSTaskIdleStk.L
       pea       65535
       pea       63
       lea       _OSTaskIdleStk.L,A0
       add.w     #254,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _OS_TaskIdle.L
       jsr       _OSTaskCreateExt
       add.w     #36,A7
       and.l     #255,D0
; (void *)0,                                 /* No arguments passed to OS_TaskIdle() */
; &OSTaskIdleStk[OS_TASK_IDLE_STK_SIZE - 1u],/* Set Top-Of-Stack                     */
; OS_TASK_IDLE_PRIO,                         /* Lowest priority level                */
; OS_TASK_IDLE_ID,
; &OSTaskIdleStk[0],                         /* Set Bottom-Of-Stack                  */
; OS_TASK_IDLE_STK_SIZE,
; (void *)0,                                 /* No TCB extension                     */
; OS_TASK_OPT_STK_CHK | OS_TASK_OPT_STK_CLR);/* Enable stack checking + clear stack  */
; #else
; (void)OSTaskCreateExt(OS_TaskIdle,
; (void *)0,                                 /* No arguments passed to OS_TaskIdle() */
; &OSTaskIdleStk[0],                         /* Set Top-Of-Stack                     */
; OS_TASK_IDLE_PRIO,                         /* Lowest priority level                */
; OS_TASK_IDLE_ID,
; &OSTaskIdleStk[OS_TASK_IDLE_STK_SIZE - 1u],/* Set Bottom-Of-Stack                  */
; OS_TASK_IDLE_STK_SIZE,
; (void *)0,                                 /* No TCB extension                     */
; OS_TASK_OPT_STK_CHK | OS_TASK_OPT_STK_CLR);/* Enable stack checking + clear stack  */
; #endif
; #else
; #if OS_STK_GROWTH == 1u
; (void)OSTaskCreate(OS_TaskIdle,
; (void *)0,
; &OSTaskIdleStk[OS_TASK_IDLE_STK_SIZE - 1u],
; OS_TASK_IDLE_PRIO);
; #else
; (void)OSTaskCreate(OS_TaskIdle,
; (void *)0,
; &OSTaskIdleStk[0],
; OS_TASK_IDLE_PRIO);
; #endif
; #endif
; #if OS_TASK_NAME_EN > 0u
; OSTaskNameSet(OS_TASK_IDLE_PRIO, (INT8U *)(void *)"uC/OS-II Idle", &err);
       pea       -1(A6)
       pea       @ucos_ii_2.L
       pea       63
       jsr       _OSTaskNameSet
       add.w     #12,A7
       unlk      A6
       rts
; #endif
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                             INITIALIZATION
; *                                      CREATING THE STATISTIC TASK
; *
; * Description: This function creates the Statistic Task.
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TASK_STAT_EN > 0u
; static  void  OS_InitTaskStat (void)
; {
@ucos_ii_OS_InitTaskStat:
       link      A6,#-4
; #if OS_TASK_NAME_EN > 0u
; INT8U  err;
; #endif
; #if OS_TASK_CREATE_EXT_EN > 0u
; #if OS_STK_GROWTH == 1u
; (void)OSTaskCreateExt(OS_TaskStat,
       pea       3
       clr.l     -(A7)
       pea       128
       pea       _OSTaskStatStk.L
       pea       65534
       pea       62
       lea       _OSTaskStatStk.L,A0
       add.w     #254,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _OS_TaskStat.L
       jsr       _OSTaskCreateExt
       add.w     #36,A7
       and.l     #255,D0
; (void *)0,                                   /* No args passed to OS_TaskStat()*/
; &OSTaskStatStk[OS_TASK_STAT_STK_SIZE - 1u],  /* Set Top-Of-Stack               */
; OS_TASK_STAT_PRIO,                           /* One higher than the idle task  */
; OS_TASK_STAT_ID,
; &OSTaskStatStk[0],                           /* Set Bottom-Of-Stack            */
; OS_TASK_STAT_STK_SIZE,
; (void *)0,                                   /* No TCB extension               */
; OS_TASK_OPT_STK_CHK | OS_TASK_OPT_STK_CLR);  /* Enable stack checking + clear  */
; #else
; (void)OSTaskCreateExt(OS_TaskStat,
; (void *)0,                                   /* No args passed to OS_TaskStat()*/
; &OSTaskStatStk[0],                           /* Set Top-Of-Stack               */
; OS_TASK_STAT_PRIO,                           /* One higher than the idle task  */
; OS_TASK_STAT_ID,
; &OSTaskStatStk[OS_TASK_STAT_STK_SIZE - 1u],  /* Set Bottom-Of-Stack            */
; OS_TASK_STAT_STK_SIZE,
; (void *)0,                                   /* No TCB extension               */
; OS_TASK_OPT_STK_CHK | OS_TASK_OPT_STK_CLR);  /* Enable stack checking + clear  */
; #endif
; #else
; #if OS_STK_GROWTH == 1u
; (void)OSTaskCreate(OS_TaskStat,
; (void *)0,                                      /* No args passed to OS_TaskStat()*/
; &OSTaskStatStk[OS_TASK_STAT_STK_SIZE - 1u],     /* Set Top-Of-Stack               */
; OS_TASK_STAT_PRIO);                             /* One higher than the idle task  */
; #else
; (void)OSTaskCreate(OS_TaskStat,
; (void *)0,                                      /* No args passed to OS_TaskStat()*/
; &OSTaskStatStk[0],                              /* Set Top-Of-Stack               */
; OS_TASK_STAT_PRIO);                             /* One higher than the idle task  */
; #endif
; #endif
; #if OS_TASK_NAME_EN > 0u
; OSTaskNameSet(OS_TASK_STAT_PRIO, (INT8U *)(void *)"uC/OS-II Stat", &err);
       pea       -1(A6)
       pea       @ucos_ii_3.L
       pea       62
       jsr       _OSTaskNameSet
       add.w     #12,A7
       unlk      A6
       rts
; #endif
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                             INITIALIZATION
; *                            INITIALIZE THE FREE LIST OF TASK CONTROL BLOCKS
; *
; * Description: This function is called by OSInit() to initialize the free list of OS_TCBs.
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; static  void  OS_InitTCBList (void)
; {
@ucos_ii_OS_InitTCBList:
       link      A6,#-8
       movem.l   D2/D3/A2,-(A7)
       lea       _OSTCBTbl.L,A2
; INT8U    ix;
; INT8U    ix_next;
; OS_TCB  *ptcb1;
; OS_TCB  *ptcb2;
; OS_MemClr((INT8U *)&OSTCBTbl[0],     sizeof(OSTCBTbl));      /* Clear all the TCBs                 */
       pea       1892
       move.l    A2,-(A7)
       jsr       _OS_MemClr
       addq.w    #8,A7
; OS_MemClr((INT8U *)&OSTCBPrioTbl[0], sizeof(OSTCBPrioTbl));  /* Clear the priority table           */
       pea       256
       pea       _OSTCBPrioTbl.L
       jsr       _OS_MemClr
       addq.w    #8,A7
; for (ix = 0u; ix < (OS_MAX_TASKS + OS_N_SYS_TASKS - 1u); ix++) {    /* Init. list of free TCBs     */
       clr.b     D3
@ucos_ii_OS_InitTCBList_1:
       cmp.b     #21,D3
       bhs       @ucos_ii_OS_InitTCBList_3
; ix_next =  ix + 1u;
       moveq     #1,D0
       add.b     D3,D0
       move.b    D0,-5(A6)
; ptcb1   = &OSTCBTbl[ix];
       move.l    A2,D0
       and.l     #255,D3
       move.l    D3,D1
       muls      #86,D1
       add.l     D1,D0
       move.l    D0,D2
; ptcb2   = &OSTCBTbl[ix_next];
       move.l    A2,D0
       move.b    -5(A6),D1
       and.l     #255,D1
       muls      #86,D1
       add.l     D1,D0
       move.l    D0,-4(A6)
; ptcb1->OSTCBNext = ptcb2;
       move.l    D2,A0
       move.l    -4(A6),20(A0)
; #if OS_TASK_NAME_EN > 0u
; ptcb1->OSTCBTaskName = (INT8U *)(void *)"?";             /* Unknown name                       */
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,78(A1)
       addq.b    #1,D3
       bra       @ucos_ii_OS_InitTCBList_1
@ucos_ii_OS_InitTCBList_3:
; #endif
; }
; ptcb1                   = &OSTCBTbl[ix];
       move.l    A2,D0
       and.l     #255,D3
       move.l    D3,D1
       muls      #86,D1
       add.l     D1,D0
       move.l    D0,D2
; ptcb1->OSTCBNext        = (OS_TCB *)0;                       /* Last OS_TCB                        */
       move.l    D2,A0
       clr.l     20(A0)
; #if OS_TASK_NAME_EN > 0u
; ptcb1->OSTCBTaskName    = (INT8U *)(void *)"?";              /* Unknown name                       */
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,78(A1)
; #endif
; OSTCBList               = (OS_TCB *)0;                       /* TCB lists initializations          */
       clr.l     _OSTCBList.L
; OSTCBFreeList           = &OSTCBTbl[0];
       move.l    A2,_OSTCBFreeList.L
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                      CLEAR A SECTION OF MEMORY
; *
; * Description: This function is called by other uC/OS-II services to clear a contiguous block of RAM.
; *
; * Arguments  : pdest    is the start of the RAM to clear (i.e. write 0x00 to)
; *
; *              size     is the number of bytes to clear.
; *
; * Returns    : none
; *
; * Notes      : 1) This function is INTERNAL to uC/OS-II and your application should not call it.
; *              2) Note that we can only clear up to 64K bytes of RAM.  This is not an issue because none
; *                 of the uses of this function gets close to this limit.
; *              3) The clear is done one byte at a time since this will work on any processor irrespective
; *                 of the alignment of the destination.
; *********************************************************************************************************
; */
; void  OS_MemClr (INT8U  *pdest,
; INT16U  size)
; {
       xdef      _OS_MemClr
_OS_MemClr:
       link      A6,#0
; while (size > 0u) {
OS_MemClr_1:
       move.w    14(A6),D0
       cmp.w     #0,D0
       bls.s     OS_MemClr_3
; *pdest++ = (INT8U)0;
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       clr.b     (A0)
; size--;
       subq.w    #1,14(A6)
       bra       OS_MemClr_1
OS_MemClr_3:
       unlk      A6
       rts
; }
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       COPY A BLOCK OF MEMORY
; *
; * Description: This function is called by other uC/OS-II services to copy a block of memory from one
; *              location to another.
; *
; * Arguments  : pdest    is a pointer to the 'destination' memory block
; *
; *              psrc     is a pointer to the 'source'      memory block
; *
; *              size     is the number of bytes to copy.
; *
; * Returns    : none
; *
; * Notes      : 1) This function is INTERNAL to uC/OS-II and your application should not call it.  There is
; *                 no provision to handle overlapping memory copy.  However, that's not a problem since this
; *                 is not a situation that will happen.
; *              2) Note that we can only copy up to 64K bytes of RAM
; *              3) The copy is done one byte at a time since this will work on any processor irrespective
; *                 of the alignment of the source and destination.
; *********************************************************************************************************
; */
; void  OS_MemCopy (INT8U  *pdest,
; INT8U  *psrc,
; INT16U  size)
; {
       xdef      _OS_MemCopy
_OS_MemCopy:
       link      A6,#0
; while (size > 0u) {
OS_MemCopy_1:
       move.w    18(A6),D0
       cmp.w     #0,D0
       bls.s     OS_MemCopy_3
; *pdest++ = *psrc++;
       move.l    12(A6),A0
       addq.l    #1,12(A6)
       move.l    8(A6),A1
       addq.l    #1,8(A6)
       move.b    (A0),(A1)
; size--;
       subq.w    #1,18(A6)
       bra       OS_MemCopy_1
OS_MemCopy_3:
       unlk      A6
       rts
; }
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                              SCHEDULER
; *
; * Description: This function is called by other uC/OS-II services to determine whether a new, high
; *              priority task has been made ready to run.  This function is invoked by TASK level code
; *              and is not used to reschedule tasks from ISRs (see OSIntExit() for ISR rescheduling).
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Notes      : 1) This function is INTERNAL to uC/OS-II and your application should not call it.
; *              2) Rescheduling is prevented when the scheduler is locked (see OS_SchedLock())
; *********************************************************************************************************
; */
; void  OS_Sched (void)
; {
       xdef      _OS_Sched
_OS_Sched:
; #if OS_CRITICAL_METHOD == 3u                           /* Allocate storage for CPU status register     */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSIntNesting == 0u) {                          /* Schedule only if all ISRs done and ...       */
       move.b    _OSIntNesting.L,D0
       bne       OS_Sched_5
; if (OSLockNesting == 0u) {                     /* ... scheduler is not locked                  */
       move.b    _OSLockNesting.L,D0
       bne.s     OS_Sched_5
; OS_SchedNew();
       jsr       @ucos_ii_OS_SchedNew
; OSTCBHighRdy = OSTCBPrioTbl[OSPrioHighRdy];
       move.b    _OSPrioHighRdy.L,D0
       and.l     #255,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),_OSTCBHighRdy.L
; if (OSPrioHighRdy != OSPrioCur) {          /* No Ctx Sw if current task is highest rdy     */
       move.b    _OSPrioHighRdy.L,D0
       cmp.b     _OSPrioCur.L,D0
       beq.s     OS_Sched_5
; #if OS_TASK_PROFILE_EN > 0u
; OSTCBHighRdy->OSTCBCtxSwCtr++;         /* Inc. # of context switches to this task      */
       move.l    _OSTCBHighRdy.L,D0
       add.l     #58,D0
       move.l    D0,A0
       addq.l    #1,(A0)
; #endif
; OSCtxSwCtr++;                          /* Increment context switch counter             */
       addq.l    #1,_OSCtxSwCtr.L
; OS_TASK_SW();                          /* Perform a context switch                     */
       trap      #0
OS_Sched_5:
; }
; }
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
       rts
; }
; /*
; *********************************************************************************************************
; *                               FIND HIGHEST PRIORITY TASK READY TO RUN
; *
; * Description: This function is called by other uC/OS-II services to determine the highest priority task
; *              that is ready to run.  The global variable 'OSPrioHighRdy' is changed accordingly.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Notes      : 1) This function is INTERNAL to uC/OS-II and your application should not call it.
; *              2) Interrupts are assumed to be disabled when this function is called.
; *********************************************************************************************************
; */
; static  void  OS_SchedNew (void)
; {
@ucos_ii_OS_SchedNew:
       move.l    D2,-(A7)
; #if OS_LOWEST_PRIO <= 63u                        /* See if we support up to 64 tasks                   */
; INT8U   y;
; y             = OSUnMapTbl[OSRdyGrp];
       move.b    _OSRdyGrp.L,D0
       and.l     #255,D0
       lea       _OSUnMapTbl.L,A0
       move.b    0(A0,D0.L),D2
; OSPrioHighRdy = (INT8U)((y << 3u) + OSUnMapTbl[OSRdyTbl[y]]);
       move.b    D2,D0
       lsl.b     #3,D0
       and.l     #255,D2
       lea       _OSRdyTbl.L,A0
       move.b    0(A0,D2.L),D1
       and.l     #255,D1
       lea       _OSUnMapTbl.L,A0
       add.b     0(A0,D1.L),D0
       move.b    D0,_OSPrioHighRdy.L
       move.l    (A7)+,D2
       rts
; #else                                            /* We support up to 256 tasks                         */
; INT8U     y;
; OS_PRIO  *ptbl;
; if ((OSRdyGrp & 0xFFu) != 0u) {
; y = OSUnMapTbl[OSRdyGrp & 0xFFu];
; } else {
; y = OSUnMapTbl[(OS_PRIO)(OSRdyGrp >> 8u) & 0xFFu] + 8u;
; }
; ptbl = &OSRdyTbl[y];
; if ((*ptbl & 0xFFu) != 0u) {
; OSPrioHighRdy = (INT8U)((y << 4u) + OSUnMapTbl[(*ptbl & 0xFFu)]);
; } else {
; OSPrioHighRdy = (INT8U)((y << 4u) + OSUnMapTbl[(OS_PRIO)(*ptbl >> 8u) & 0xFFu] + 8u);
; }
; #endif
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                               DETERMINE THE LENGTH OF AN ASCII STRING
; *
; * Description: This function is called by other uC/OS-II services to determine the size of an ASCII string
; *              (excluding the NUL character).
; *
; * Arguments  : psrc     is a pointer to the string for which we need to know the size.
; *
; * Returns    : The size of the string (excluding the NUL terminating character)
; *
; * Notes      : 1) This function is INTERNAL to uC/OS-II and your application should not call it.
; *              2) The string to check must be less than 255 characters long.
; *********************************************************************************************************
; */
; #if (OS_EVENT_NAME_EN > 0u) || (OS_FLAG_NAME_EN > 0u) || (OS_MEM_NAME_EN > 0u) || (OS_TASK_NAME_EN > 0u) || (OS_TMR_CFG_NAME_EN > 0u)
; INT8U  OS_StrLen (INT8U *psrc)
; {
       xdef      _OS_StrLen
_OS_StrLen:
       link      A6,#0
       move.l    D2,-(A7)
; INT8U  len;
; #if OS_ARG_CHK_EN > 0u
; if (psrc == (INT8U *)0) {
; return (0u);
; }
; #endif
; len = 0u;
       clr.b     D2
; while (*psrc != OS_ASCII_NUL) {
OS_StrLen_1:
       move.l    8(A6),A0
       move.b    (A0),D0
       beq.s     OS_StrLen_3
; psrc++;
       addq.l    #1,8(A6)
; len++;
       addq.b    #1,D2
       bra       OS_StrLen_1
OS_StrLen_3:
; }
; return (len);
       move.b    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                              IDLE TASK
; *
; * Description: This task is internal to uC/OS-II and executes whenever no other higher priority tasks
; *              executes because they are ALL waiting for event(s) to occur.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Note(s)    : 1) OSTaskIdleHook() is called after the critical section to ensure that interrupts will be
; *                 enabled for at least a few instructions.  On some processors (ex. Philips XA), enabling
; *                 and then disabling interrupts didn't allow the processor enough time to have interrupts
; *                 enabled before they were disabled again.  uC/OS-II would thus never recognize
; *                 interrupts.
; *              2) This hook has been added to allow you to do such things as STOP the CPU to conserve
; *                 power.
; *********************************************************************************************************
; */
; void  OS_TaskIdle (void *p_arg)
; {
       xdef      _OS_TaskIdle
_OS_TaskIdle:
       link      A6,#0
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; p_arg = p_arg;                               /* Prevent compiler warning for not using 'p_arg'     */
; for (;;) {
OS_TaskIdle_1:
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSIdleCtr++;
       addq.l    #1,_OSIdleCtr.L
; OS_EXIT_CRITICAL();
       dc.w      18143
; OSTaskIdleHook();                        /* Call user definable HOOK                           */
       jsr       _OSTaskIdleHook
       bra       OS_TaskIdle_1
; }
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           STATISTICS TASK
; *
; * Description: This task is internal to uC/OS-II and is used to compute some statistics about the
; *              multitasking environment.  Specifically, OS_TaskStat() computes the CPU usage.
; *              CPU usage is determined by:
; *
; *                                          OSIdleCtr
; *                 OSCPUUsage = 100 * (1 - ------------)     (units are in %)
; *                                         OSIdleCtrMax
; *
; * Arguments  : parg     this pointer is not used at this time.
; *
; * Returns    : none
; *
; * Notes      : 1) This task runs at a priority level higher than the idle task.  In fact, it runs at the
; *                 next higher priority, OS_TASK_IDLE_PRIO-1.
; *              2) You can disable this task by setting the configuration #define OS_TASK_STAT_EN to 0.
; *              3) You MUST have at least a delay of 2/10 seconds to allow for the system to establish the
; *                 maximum value for the idle counter.
; *********************************************************************************************************
; */
; #if OS_TASK_STAT_EN > 0u
; void  OS_TaskStat (void *p_arg)
; {
       xdef      _OS_TaskStat
_OS_TaskStat:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _OSIdleCtrMax.L,A2
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; p_arg = p_arg;                               /* Prevent compiler warning for not using 'p_arg'     */
; while (OSStatRdy == OS_FALSE) {
OS_TaskStat_1:
       move.b    _OSStatRdy.L,D0
       bne.s     OS_TaskStat_3
; OSTimeDly(2u * OS_TICKS_PER_SEC / 10u);  /* Wait until statistic task is ready                 */
       pea       20
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       OS_TaskStat_1
OS_TaskStat_3:
; }
; OSIdleCtrMax /= 100uL;
       move.l    (A2),-(A7)
       pea       100
       jsr       ULDIV
       move.l    (A7),(A2)
       addq.w    #8,A7
; if (OSIdleCtrMax == 0uL) {
       move.l    (A2),D0
       bne.s     OS_TaskStat_4
; OSCPUUsage = 0u;
       clr.b     _OSCPUUsage.L
; #if OS_TASK_SUSPEND_EN > 0u
; (void)OSTaskSuspend(OS_PRIO_SELF);
       pea       255
       jsr       _OSTaskSuspend
       addq.w    #4,A7
       and.l     #255,D0
OS_TaskStat_4:
; #else
; for (;;) {
; OSTimeDly(OS_TICKS_PER_SEC);
; }
; #endif
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSIdleCtr = OSIdleCtrMax * 100uL;            /* Set initial CPU usage as 0%                        */
       move.l    (A2),-(A7)
       pea       100
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,_OSIdleCtr.L
; OS_EXIT_CRITICAL();
       dc.w      18143
; for (;;) {
OS_TaskStat_6:
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSIdleCtrRun = OSIdleCtr;                /* Obtain the of the idle counter for the past second */
       move.l    _OSIdleCtr.L,_OSIdleCtrRun.L
; OSIdleCtr    = 0uL;                      /* Reset the idle counter for the next second         */
       clr.l     _OSIdleCtr.L
; OS_EXIT_CRITICAL();
       dc.w      18143
; OSCPUUsage   = (INT8U)(100uL - OSIdleCtrRun / OSIdleCtrMax);
       moveq     #100,D0
       move.l    _OSIdleCtrRun.L,-(A7)
       move.l    (A2),-(A7)
       jsr       ULDIV
       move.l    (A7),D1
       addq.w    #8,A7
       sub.l     D1,D0
       move.b    D0,_OSCPUUsage.L
; OSTaskStatHook();                        /* Invoke user definable hook                         */
       jsr       _OSTaskStatHook
; #if (OS_TASK_STAT_STK_CHK_EN > 0u) && (OS_TASK_CREATE_EXT_EN > 0u)
; OS_TaskStatStkChk();                     /* Check the stacks for each task                     */
       jsr       _OS_TaskStatStkChk
; #endif
; OSTimeDly(OS_TICKS_PER_SEC / 10u);       /* Accumulate OSIdleCtr for the next 1/10 second      */
       pea       10
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       OS_TaskStat_6
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                        CHECK ALL TASK STACKS
; *
; * Description: This function is called by OS_TaskStat() to check the stacks of each active task.
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if (OS_TASK_STAT_STK_CHK_EN > 0u) && (OS_TASK_CREATE_EXT_EN > 0u)
; void  OS_TaskStatStkChk (void)
; {
       xdef      _OS_TaskStatStkChk
_OS_TaskStatStkChk:
       link      A6,#-12
       movem.l   D2/D3,-(A7)
; OS_TCB      *ptcb;
; OS_STK_DATA  stk_data;
; INT8U        err;
; INT8U        prio;
; for (prio = 0u; prio <= OS_TASK_IDLE_PRIO; prio++) {
       clr.b     D3
OS_TaskStatStkChk_1:
       cmp.b     #63,D3
       bhi       OS_TaskStatStkChk_3
; err = OSTaskStkChk(prio, &stk_data);
       pea       -10(A6)
       and.l     #255,D3
       move.l    D3,-(A7)
       jsr       _OSTaskStkChk
       addq.w    #8,A7
       move.b    D0,-1(A6)
; if (err == OS_ERR_NONE) {
       move.b    -1(A6),D0
       bne       OS_TaskStatStkChk_8
; ptcb = OSTCBPrioTbl[prio];
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb != (OS_TCB *)0) {                               /* Make sure task 'ptcb' is ...   */
       tst.l     D2
       beq.s     OS_TaskStatStkChk_8
; if (ptcb != OS_TCB_RESERVED) {                       /* ... still valid.               */
       cmp.l     #1,D2
       beq.s     OS_TaskStatStkChk_8
; #if OS_TASK_PROFILE_EN > 0u
; #if OS_STK_GROWTH == 1u
; ptcb->OSTCBStkBase = ptcb->OSTCBStkBottom + ptcb->OSTCBStkSize;
       move.l    D2,A0
       move.l    8(A0),D0
       move.l    D2,A0
       move.l    12(A0),D1
       lsl.l     #1,D1
       add.l     D1,D0
       move.l    D2,A0
       move.l    D0,70(A0)
; #else
; ptcb->OSTCBStkBase = ptcb->OSTCBStkBottom - ptcb->OSTCBStkSize;
; #endif
; ptcb->OSTCBStkUsed = stk_data.OSUsed;            /* Store number of entries used   */
       lea       -10(A6),A0
       move.l    D2,A1
       move.l    4(A0),74(A1)
OS_TaskStatStkChk_8:
       addq.b    #1,D3
       bra       OS_TaskStatStkChk_1
OS_TaskStatStkChk_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; #endif
; }
; }
; }
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           INITIALIZE TCB
; *
; * Description: This function is internal to uC/OS-II and is used to initialize a Task Control Block when
; *              a task is created (see OSTaskCreate() and OSTaskCreateExt()).
; *
; * Arguments  : prio          is the priority of the task being created
; *
; *              ptos          is a pointer to the task's top-of-stack assuming that the CPU registers
; *                            have been placed on the stack.  Note that the top-of-stack corresponds to a
; *                            'high' memory location is OS_STK_GROWTH is set to 1 and a 'low' memory
; *                            location if OS_STK_GROWTH is set to 0.  Note that stack growth is CPU
; *                            specific.
; *
; *              pbos          is a pointer to the bottom of stack.  A NULL pointer is passed if called by
; *                            'OSTaskCreate()'.
; *
; *              id            is the task's ID (0..65535)
; *
; *              stk_size      is the size of the stack (in 'stack units').  If the stack units are INT8Us
; *                            then, 'stk_size' contains the number of bytes for the stack.  If the stack
; *                            units are INT32Us then, the stack contains '4 * stk_size' bytes.  The stack
; *                            units are established by the #define constant OS_STK which is CPU
; *                            specific.  'stk_size' is 0 if called by 'OSTaskCreate()'.
; *
; *              pext          is a pointer to a user supplied memory area that is used to extend the task
; *                            control block.  This allows you to store the contents of floating-point
; *                            registers, MMU registers or anything else you could find useful during a
; *                            context switch.  You can even assign a name to each task and store this name
; *                            in this TCB extension.  A NULL pointer is passed if called by OSTaskCreate().
; *
; *              opt           options as passed to 'OSTaskCreateExt()' or,
; *                            0 if called from 'OSTaskCreate()'.
; *
; * Returns    : OS_ERR_NONE         if the call was successful
; *              OS_ERR_TASK_NO_MORE_TCB  if there are no more free TCBs to be allocated and thus, the task cannot
; *                                  be created.
; *
; * Note       : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; INT8U  OS_TCBInit (INT8U    prio,
; OS_STK  *ptos,
; OS_STK  *pbos,
; INT16U   id,
; INT32U   stk_size,
; void    *pext,
; INT16U   opt)
; {
       xdef      _OS_TCBInit
_OS_TCBInit:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _OSTCBList.L,A2
       move.b    11(A6),D4
       and.l     #255,D4
; OS_TCB    *ptcb;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_TASK_REG_TBL_SIZE > 0u
; INT8U      i;
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; ptcb = OSTCBFreeList;                                  /* Get a free TCB from the free TCB list    */
       move.l    _OSTCBFreeList.L,D2
; if (ptcb != (OS_TCB *)0) {
       tst.l     D2
       beq       OS_TCBInit_1
; OSTCBFreeList            = ptcb->OSTCBNext;        /* Update pointer to free TCB list          */
       move.l    D2,A0
       move.l    20(A0),_OSTCBFreeList.L
; OS_EXIT_CRITICAL();
       dc.w      18143
; ptcb->OSTCBStkPtr        = ptos;                   /* Load Stack pointer in TCB                */
       move.l    D2,A0
       move.l    12(A6),(A0)
; ptcb->OSTCBPrio          = prio;                   /* Load task priority into TCB              */
       move.l    D2,A0
       move.b    D4,52(A0)
; ptcb->OSTCBStat          = OS_STAT_RDY;            /* Task is ready to run                     */
       move.l    D2,A0
       clr.b     50(A0)
; ptcb->OSTCBStatPend      = OS_STAT_PEND_OK;        /* Clear pend status                        */
       move.l    D2,A0
       clr.b     51(A0)
; ptcb->OSTCBDly           = 0u;                     /* Task is not delayed                      */
       move.l    D2,A0
       clr.l     46(A0)
; #if OS_TASK_CREATE_EXT_EN > 0u
; ptcb->OSTCBExtPtr        = pext;                   /* Store pointer to TCB extension           */
       move.l    D2,A0
       move.l    28(A6),4(A0)
; ptcb->OSTCBStkSize       = stk_size;               /* Store stack size                         */
       move.l    D2,A0
       move.l    24(A6),12(A0)
; ptcb->OSTCBStkBottom     = pbos;                   /* Store pointer to bottom of stack         */
       move.l    D2,A0
       move.l    16(A6),8(A0)
; ptcb->OSTCBOpt           = opt;                    /* Store task options                       */
       move.l    D2,A0
       move.w    34(A6),16(A0)
; ptcb->OSTCBId            = id;                     /* Store task ID                            */
       move.l    D2,A0
       move.w    22(A6),18(A0)
; #else
; pext                     = pext;                   /* Prevent compiler warning if not used     */
; stk_size                 = stk_size;
; pbos                     = pbos;
; opt                      = opt;
; id                       = id;
; #endif
; #if OS_TASK_DEL_EN > 0u
; ptcb->OSTCBDelReq        = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     57(A0)
; #endif
; #if OS_LOWEST_PRIO <= 63u                                         /* Pre-compute X, Y                  */
; ptcb->OSTCBY             = (INT8U)(prio >> 3u);
       move.b    D4,D0
       lsr.b     #3,D0
       move.l    D2,A0
       move.b    D0,54(A0)
; ptcb->OSTCBX             = (INT8U)(prio & 0x07u);
       move.b    D4,D0
       and.b     #7,D0
       move.l    D2,A0
       move.b    D0,53(A0)
; #else                                                             /* Pre-compute X, Y                  */
; ptcb->OSTCBY             = (INT8U)((INT8U)(prio >> 4u) & 0xFFu);
; ptcb->OSTCBX             = (INT8U) (prio & 0x0Fu);
; #endif
; /* Pre-compute BitX and BitY         */
; ptcb->OSTCBBitY          = (OS_PRIO)(1uL << ptcb->OSTCBY);
       moveq     #1,D0
       move.l    D2,A0
       move.b    54(A0),D1
       and.l     #255,D1
       lsl.l     D1,D0
       move.l    D2,A0
       move.b    D0,56(A0)
; ptcb->OSTCBBitX          = (OS_PRIO)(1uL << ptcb->OSTCBX);
       moveq     #1,D0
       move.l    D2,A0
       move.b    53(A0),D1
       and.l     #255,D1
       lsl.l     D1,D0
       move.l    D2,A0
       move.b    D0,55(A0)
; #if (OS_EVENT_EN)
; ptcb->OSTCBEventPtr      = (OS_EVENT  *)0;         /* Task is not pending on an  event         */
       move.l    D2,A0
       clr.l     28(A0)
; #if (OS_EVENT_MULTI_EN > 0u)
; ptcb->OSTCBEventMultiPtr = (OS_EVENT **)0;         /* Task is not pending on any events        */
       move.l    D2,A0
       clr.l     32(A0)
; #endif
; #endif
; #if (OS_FLAG_EN > 0u) && (OS_MAX_FLAGS > 0u) && (OS_TASK_DEL_EN > 0u)
; ptcb->OSTCBFlagNode  = (OS_FLAG_NODE *)0;          /* Task is not pending on an event flag     */
       move.l    D2,A0
       clr.l     40(A0)
; #endif
; #if (OS_MBOX_EN > 0u) || ((OS_Q_EN > 0u) && (OS_MAX_QS > 0u))
; ptcb->OSTCBMsg       = (void *)0;                  /* No message received                      */
       move.l    D2,A0
       clr.l     36(A0)
; #endif
; #if OS_TASK_PROFILE_EN > 0u
; ptcb->OSTCBCtxSwCtr    = 0uL;                      /* Initialize profiling variables           */
       move.l    D2,A0
       clr.l     58(A0)
; ptcb->OSTCBCyclesStart = 0uL;
       move.l    D2,A0
       clr.l     66(A0)
; ptcb->OSTCBCyclesTot   = 0uL;
       move.l    D2,A0
       clr.l     62(A0)
; ptcb->OSTCBStkBase     = (OS_STK *)0;
       move.l    D2,A0
       clr.l     70(A0)
; ptcb->OSTCBStkUsed     = 0uL;
       move.l    D2,A0
       clr.l     74(A0)
; #endif
; #if OS_TASK_NAME_EN > 0u
; ptcb->OSTCBTaskName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,78(A1)
; #endif
; #if OS_TASK_REG_TBL_SIZE > 0u                              /* Initialize the task variables            */
; for (i = 0u; i < OS_TASK_REG_TBL_SIZE; i++) {
       clr.b     D3
OS_TCBInit_3:
       cmp.b     #1,D3
       bhs.s     OS_TCBInit_5
; ptcb->OSTCBRegTbl[i] = 0u;
       move.l    D2,A0
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       add.l     D0,A0
       clr.l     82(A0)
       addq.b    #1,D3
       bra       OS_TCBInit_3
OS_TCBInit_5:
; }
; #endif
; OSTCBInitHook(ptcb);
       move.l    D2,-(A7)
       jsr       _OSTCBInitHook
       addq.w    #4,A7
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSTCBPrioTbl[prio] = ptcb;
       and.l     #255,D4
       move.l    D4,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    D2,0(A0,D0.L)
; OS_EXIT_CRITICAL();
       dc.w      18143
; OSTaskCreateHook(ptcb);                            /* Call user defined hook                   */
       move.l    D2,-(A7)
       jsr       _OSTaskCreateHook
       addq.w    #4,A7
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; ptcb->OSTCBNext    = OSTCBList;                    /* Link into TCB chain                      */
       move.l    D2,A0
       move.l    (A2),20(A0)
; ptcb->OSTCBPrev    = (OS_TCB *)0;
       move.l    D2,A0
       clr.l     24(A0)
; if (OSTCBList != (OS_TCB *)0) {
       move.l    (A2),D0
       beq.s     OS_TCBInit_6
; OSTCBList->OSTCBPrev = ptcb;
       move.l    (A2),A0
       move.l    D2,24(A0)
OS_TCBInit_6:
; }
; OSTCBList               = ptcb;
       move.l    D2,(A2)
; OSRdyGrp               |= ptcb->OSTCBBitY;         /* Make task ready to run                   */
       move.l    D2,A0
       move.b    56(A0),D0
       or.b      D0,_OSRdyGrp.L
; OSRdyTbl[ptcb->OSTCBY] |= ptcb->OSTCBBitX;
       move.l    D2,A0
       move.b    54(A0),D0
       and.l     #255,D0
       lea       _OSRdyTbl.L,A0
       move.l    D2,A1
       move.b    55(A1),D1
       or.b      D1,0(A0,D0.L)
; OSTaskCtr++;                                       /* Increment the #tasks counter             */
       addq.b    #1,_OSTaskCtr.L
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
       bra.s     OS_TCBInit_8
OS_TCBInit_1:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NO_MORE_TCB);
       moveq     #66,D0
OS_TCBInit_8:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                         EVENT FLAG  MANAGEMENT
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : OS_FLAG.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #include <ucos_ii.h>
; #endif
; #if (OS_FLAG_EN > 0u) && (OS_MAX_FLAGS > 0u)
; /*
; *********************************************************************************************************
; *                                          LOCAL PROTOTYPES
; *********************************************************************************************************
; */
; static  void     OS_FlagBlock(OS_FLAG_GRP *pgrp, OS_FLAG_NODE *pnode, OS_FLAGS flags, INT8U wait_type, INT32U timeout);
; static  BOOLEAN  OS_FlagTaskRdy(OS_FLAG_NODE *pnode, OS_FLAGS flags_rdy, INT8U pend_stat);
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                          CHECK THE STATUS OF FLAGS IN AN EVENT FLAG GROUP
; *
; * Description: This function is called to check the status of a combination of bits to be set or cleared
; *              in an event flag group.  Your application can check for ANY bit to be set/cleared or ALL
; *              bits to be set/cleared.
; *
; *              This call does not block if the desired flags are not present.
; *
; * Arguments  : pgrp          is a pointer to the desired event flag group.
; *
; *              flags         Is a bit pattern indicating which bit(s) (i.e. flags) you wish to check.
; *                            The bits you want are specified by setting the corresponding bits in
; *                            'flags'.  e.g. if your application wants to wait for bits 0 and 1 then
; *                            'flags' would contain 0x03.
; *
; *              wait_type     specifies whether you want ALL bits to be set/cleared or ANY of the bits
; *                            to be set/cleared.
; *                            You can specify the following argument:
; *
; *                            OS_FLAG_WAIT_CLR_ALL   You will check ALL bits in 'flags' to be clear (0)
; *                            OS_FLAG_WAIT_CLR_ANY   You will check ANY bit  in 'flags' to be clear (0)
; *                            OS_FLAG_WAIT_SET_ALL   You will check ALL bits in 'flags' to be set   (1)
; *                            OS_FLAG_WAIT_SET_ANY   You will check ANY bit  in 'flags' to be set   (1)
; *
; *                            NOTE: Add OS_FLAG_CONSUME if you want the event flag to be 'consumed' by
; *                                  the call.  Example, to wait for any flag in a group AND then clear
; *                                  the flags that are present, set 'wait_type' to:
; *
; *                                  OS_FLAG_WAIT_SET_ANY + OS_FLAG_CONSUME
; *
; *              perr          is a pointer to an error code and can be:
; *                            OS_ERR_NONE               No error
; *                            OS_ERR_EVENT_TYPE         You are not pointing to an event flag group
; *                            OS_ERR_FLAG_WAIT_TYPE     You didn't specify a proper 'wait_type' argument.
; *                            OS_ERR_FLAG_INVALID_PGRP  You passed a NULL pointer instead of the event flag
; *                                                      group handle.
; *                            OS_ERR_FLAG_NOT_RDY       The desired flags you are waiting for are not
; *                                                      available.
; *
; * Returns    : The flags in the event flag group that made the task ready or, 0 if a timeout or an error
; *              occurred.
; *
; * Called from: Task or ISR
; *
; * Note(s)    : 1) IMPORTANT, the behavior of this function has changed from PREVIOUS versions.  The
; *                 function NOW returns the flags that were ready INSTEAD of the current state of the
; *                 event flags.
; *********************************************************************************************************
; */
; #if OS_FLAG_ACCEPT_EN > 0u
; OS_FLAGS  OSFlagAccept (OS_FLAG_GRP  *pgrp,
; OS_FLAGS      flags,
; INT8U         wait_type,
; INT8U        *perr)
; {
       xdef      _OSFlagAccept
_OSFlagAccept:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/D7,-(A7)
       move.l    8(A6),D3
       move.l    20(A6),D4
       move.w    14(A6),D5
       and.l     #65535,D5
       move.b    19(A6),D7
       and.l     #255,D7
; OS_FLAGS      flags_rdy;
; INT8U         result;
; BOOLEAN       consume;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR     cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_FLAGS)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pgrp == (OS_FLAG_GRP *)0) {                        /* Validate 'pgrp'                          */
; *perr = OS_ERR_FLAG_INVALID_PGRP;
; return ((OS_FLAGS)0);
; }
; #endif
; if (pgrp->OSFlagType != OS_EVENT_TYPE_FLAG) {          /* Validate event block type                */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #5,D0
       beq.s     OSFlagAccept_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return ((OS_FLAGS)0);
       clr.w     D0
       bra       OSFlagAccept_3
OSFlagAccept_1:
; }
; result = (INT8U)(wait_type & OS_FLAG_CONSUME);
       move.b    D7,D0
       and.b     #128,D0
       move.b    D0,-1(A6)
; if (result != (INT8U)0) {                              /* See if we need to consume the flags      */
       move.b    -1(A6),D0
       beq.s     OSFlagAccept_4
; wait_type &= (INT8U)~OS_FLAG_CONSUME;
       and.b     #127,D7
; consume    = OS_TRUE;
       moveq     #1,D6
       bra.s     OSFlagAccept_5
OSFlagAccept_4:
; } else {
; consume    = OS_FALSE;
       clr.b     D6
OSFlagAccept_5:
; }
; /*$PAGE*/
; *perr = OS_ERR_NONE;                                   /* Assume NO error until proven otherwise.  */
       move.l    D4,A0
       clr.b     (A0)
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; switch (wait_type) {
       and.l     #255,D7
       move.l    D7,D0
       cmp.l     #4,D0
       bhs       OSFlagAccept_6
       asl.l     #1,D0
       move.w    OSFlagAccept_8(PC,D0.L),D0
       jmp       OSFlagAccept_8(PC,D0.W)
OSFlagAccept_8:
       dc.w      OSFlagAccept_11-OSFlagAccept_8
       dc.w      OSFlagAccept_12-OSFlagAccept_8
       dc.w      OSFlagAccept_9-OSFlagAccept_8
       dc.w      OSFlagAccept_10-OSFlagAccept_8
OSFlagAccept_9:
; case OS_FLAG_WAIT_SET_ALL:                         /* See if all required flags are set        */
; flags_rdy = (OS_FLAGS)(pgrp->OSFlagFlags & flags);     /* Extract only the bits we want   */
       move.l    D3,A0
       move.w    6(A0),D0
       and.w     D5,D0
       move.w    D0,D2
; if (flags_rdy == flags) {                     /* Must match ALL the bits that we want     */
       cmp.w     D5,D2
       bne.s     OSFlagAccept_14
; if (consume == OS_TRUE) {                 /* See if we need to consume the flags      */
       cmp.b     #1,D6
       bne.s     OSFlagAccept_16
; pgrp->OSFlagFlags &= (OS_FLAGS)~flags_rdy;     /* Clear ONLY the flags we wanted  */
       move.l    D3,A0
       move.w    D2,D0
       not.w     D0
       and.w     D0,6(A0)
OSFlagAccept_16:
       bra.s     OSFlagAccept_15
OSFlagAccept_14:
; }
; } else {
; *perr = OS_ERR_FLAG_NOT_RDY;
       move.l    D4,A0
       move.b    #112,(A0)
OSFlagAccept_15:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; break;
       bra       OSFlagAccept_7
OSFlagAccept_10:
; case OS_FLAG_WAIT_SET_ANY:
; flags_rdy = (OS_FLAGS)(pgrp->OSFlagFlags & flags);     /* Extract only the bits we want   */
       move.l    D3,A0
       move.w    6(A0),D0
       and.w     D5,D0
       move.w    D0,D2
; if (flags_rdy != (OS_FLAGS)0) {               /* See if any flag set                      */
       tst.w     D2
       beq.s     OSFlagAccept_18
; if (consume == OS_TRUE) {                 /* See if we need to consume the flags      */
       cmp.b     #1,D6
       bne.s     OSFlagAccept_20
; pgrp->OSFlagFlags &= (OS_FLAGS)~flags_rdy;     /* Clear ONLY the flags we got     */
       move.l    D3,A0
       move.w    D2,D0
       not.w     D0
       and.w     D0,6(A0)
OSFlagAccept_20:
       bra.s     OSFlagAccept_19
OSFlagAccept_18:
; }
; } else {
; *perr = OS_ERR_FLAG_NOT_RDY;
       move.l    D4,A0
       move.b    #112,(A0)
OSFlagAccept_19:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; break;
       bra       OSFlagAccept_7
OSFlagAccept_11:
; #if OS_FLAG_WAIT_CLR_EN > 0u
; case OS_FLAG_WAIT_CLR_ALL:                         /* See if all required flags are cleared    */
; flags_rdy = (OS_FLAGS)~pgrp->OSFlagFlags & flags;    /* Extract only the bits we want     */
       move.l    D3,A0
       move.w    6(A0),D0
       not.w     D0
       and.w     D5,D0
       move.w    D0,D2
; if (flags_rdy == flags) {                     /* Must match ALL the bits that we want     */
       cmp.w     D5,D2
       bne.s     OSFlagAccept_22
; if (consume == OS_TRUE) {                 /* See if we need to consume the flags      */
       cmp.b     #1,D6
       bne.s     OSFlagAccept_24
; pgrp->OSFlagFlags |= flags_rdy;       /* Set ONLY the flags that we wanted        */
       move.l    D3,A0
       or.w      D2,6(A0)
OSFlagAccept_24:
       bra.s     OSFlagAccept_23
OSFlagAccept_22:
; }
; } else {
; *perr = OS_ERR_FLAG_NOT_RDY;
       move.l    D4,A0
       move.b    #112,(A0)
OSFlagAccept_23:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; break;
       bra       OSFlagAccept_7
OSFlagAccept_12:
; case OS_FLAG_WAIT_CLR_ANY:
; flags_rdy = (OS_FLAGS)~pgrp->OSFlagFlags & flags;   /* Extract only the bits we want      */
       move.l    D3,A0
       move.w    6(A0),D0
       not.w     D0
       and.w     D5,D0
       move.w    D0,D2
; if (flags_rdy != (OS_FLAGS)0) {               /* See if any flag cleared                  */
       tst.w     D2
       beq.s     OSFlagAccept_26
; if (consume == OS_TRUE) {                 /* See if we need to consume the flags      */
       cmp.b     #1,D6
       bne.s     OSFlagAccept_28
; pgrp->OSFlagFlags |= flags_rdy;       /* Set ONLY the flags that we got           */
       move.l    D3,A0
       or.w      D2,6(A0)
OSFlagAccept_28:
       bra.s     OSFlagAccept_27
OSFlagAccept_26:
; }
; } else {
; *perr = OS_ERR_FLAG_NOT_RDY;
       move.l    D4,A0
       move.b    #112,(A0)
OSFlagAccept_27:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; break;
       bra.s     OSFlagAccept_7
OSFlagAccept_6:
; #endif
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; flags_rdy = (OS_FLAGS)0;
       clr.w     D2
; *perr     = OS_ERR_FLAG_WAIT_TYPE;
       move.l    D4,A0
       move.b    #111,(A0)
; break;
OSFlagAccept_7:
; }
; return (flags_rdy);
       move.w    D2,D0
OSFlagAccept_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                        CREATE AN EVENT FLAG
; *
; * Description: This function is called to create an event flag group.
; *
; * Arguments  : flags         Contains the initial value to store in the event flag group.
; *
; *              perr          is a pointer to an error code which will be returned to your application:
; *                               OS_ERR_NONE               if the call was successful.
; *                               OS_ERR_CREATE_ISR         if you attempted to create an Event Flag from an
; *                                                         ISR.
; *                               OS_ERR_FLAG_GRP_DEPLETED  if there are no more event flag groups
; *
; * Returns    : A pointer to an event flag group or a NULL pointer if no more groups are available.
; *
; * Called from: Task ONLY
; *********************************************************************************************************
; */
; OS_FLAG_GRP  *OSFlagCreate (OS_FLAGS  flags,
; INT8U    *perr)
; {
       xdef      _OSFlagCreate
_OSFlagCreate:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       lea       _OSFlagFreeList.L,A2
       move.l    12(A6),D3
; OS_FLAG_GRP *pgrp;
; #if OS_CRITICAL_METHOD == 3u                        /* Allocate storage for CPU status register        */
; OS_CPU_SR    cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_FLAG_GRP *)0);
; }
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; if (OSSafetyCriticalStartFlag == OS_TRUE) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_FLAG_GRP *)0);
; }
; #endif
; if (OSIntNesting > 0u) {                        /* See if called from ISR ...                      */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSFlagCreate_1
; *perr = OS_ERR_CREATE_ISR;                  /* ... can't CREATE from an ISR                    */
       move.l    D3,A0
       move.b    #16,(A0)
; return ((OS_FLAG_GRP *)0);
       clr.l     D0
       bra       OSFlagCreate_3
OSFlagCreate_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pgrp = OSFlagFreeList;                          /* Get next free event flag                        */
       move.l    (A2),D2
; if (pgrp != (OS_FLAG_GRP *)0) {                 /* See if we have event flag groups available      */
       tst.l     D2
       beq.s     OSFlagCreate_4
; /* Adjust free list                                */
; OSFlagFreeList       = (OS_FLAG_GRP *)OSFlagFreeList->OSFlagWaitList;
       move.l    (A2),A0
       move.l    2(A0),(A2)
; pgrp->OSFlagType     = OS_EVENT_TYPE_FLAG;  /* Set to event flag group type                    */
       move.l    D2,A0
       move.b    #5,(A0)
; pgrp->OSFlagFlags    = flags;               /* Set to desired initial value                    */
       move.l    D2,A0
       move.w    10(A6),6(A0)
; pgrp->OSFlagWaitList = (void *)0;           /* Clear list of tasks waiting on flags            */
       move.l    D2,A0
       clr.l     2(A0)
; #if OS_FLAG_NAME_EN > 0u
; pgrp->OSFlagName     = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,8(A1)
; #endif
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
       bra.s     OSFlagCreate_5
OSFlagCreate_4:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                = OS_ERR_FLAG_GRP_DEPLETED;
       move.l    D3,A0
       move.b    #114,(A0)
OSFlagCreate_5:
; }
; return (pgrp);                                  /* Return pointer to event flag group              */
       move.l    D2,D0
OSFlagCreate_3:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                     DELETE AN EVENT FLAG GROUP
; *
; * Description: This function deletes an event flag group and readies all tasks pending on the event flag
; *              group.
; *
; * Arguments  : pgrp          is a pointer to the desired event flag group.
; *
; *              opt           determines delete options as follows:
; *                            opt == OS_DEL_NO_PEND   Deletes the event flag group ONLY if no task pending
; *                            opt == OS_DEL_ALWAYS    Deletes the event flag group even if tasks are
; *                                                    waiting.  In this case, all the tasks pending will be
; *                                                    readied.
; *
; *              perr          is a pointer to an error code that can contain one of the following values:
; *                            OS_ERR_NONE               The call was successful and the event flag group was
; *                                                      deleted
; *                            OS_ERR_DEL_ISR            If you attempted to delete the event flag group from
; *                                                      an ISR
; *                            OS_ERR_FLAG_INVALID_PGRP  If 'pgrp' is a NULL pointer.
; *                            OS_ERR_EVENT_TYPE         If you didn't pass a pointer to an event flag group
; *                            OS_ERR_INVALID_OPT        An invalid option was specified
; *                            OS_ERR_TASK_WAITING       One or more tasks were waiting on the event flag
; *                                                      group.
; *
; * Returns    : pgrp          upon error
; *              (OS_EVENT *)0 if the event flag group was successfully deleted.
; *
; * Note(s)    : 1) This function must be used with care.  Tasks that would normally expect the presence of
; *                 the event flag group MUST check the return code of OSFlagAccept() and OSFlagPend().
; *              2) This call can potentially disable interrupts for a long time.  The interrupt disable
; *                 time is directly proportional to the number of tasks waiting on the event flag group.
; *              3) All tasks that were waiting for the event flag will be readied and returned an
; *                 OS_ERR_PEND_ABORT if OSFlagDel() was called with OS_DEL_ALWAYS
; *********************************************************************************************************
; */
; #if OS_FLAG_DEL_EN > 0u
; OS_FLAG_GRP  *OSFlagDel (OS_FLAG_GRP  *pgrp,
; INT8U         opt,
; INT8U        *perr)
; {
       xdef      _OSFlagDel
_OSFlagDel:
       link      A6,#0
       movem.l   D2/D3/D4/D5/D6/A2,-(A7)
       move.l    8(A6),D2
       move.l    16(A6),D3
       lea       _OSFlagFreeList.L,A2
; BOOLEAN       tasks_waiting;
; OS_FLAG_NODE *pnode;
; OS_FLAG_GRP  *pgrp_return;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR     cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_FLAG_GRP *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pgrp == (OS_FLAG_GRP *)0) {                        /* Validate 'pgrp'                          */
; *perr = OS_ERR_FLAG_INVALID_PGRP;
; return (pgrp);
; }
; #endif
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSFlagDel_1
; *perr = OS_ERR_DEL_ISR;                            /* ... can't DELETE from an ISR             */
       move.l    D3,A0
       move.b    #15,(A0)
; return (pgrp);
       move.l    D2,D0
       bra       OSFlagDel_3
OSFlagDel_1:
; }
; if (pgrp->OSFlagType != OS_EVENT_TYPE_FLAG) {          /* Validate event group type                */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #5,D0
       beq.s     OSFlagDel_4
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D3,A0
       move.b    #1,(A0)
; return (pgrp);
       move.l    D2,D0
       bra       OSFlagDel_3
OSFlagDel_4:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pgrp->OSFlagWaitList != (void *)0) {               /* See if any tasks waiting on event flags  */
       move.l    D2,A0
       move.l    2(A0),D0
       beq.s     OSFlagDel_6
; tasks_waiting = OS_TRUE;                           /* Yes                                      */
       moveq     #1,D6
       bra.s     OSFlagDel_7
OSFlagDel_6:
; } else {
; tasks_waiting = OS_FALSE;                          /* No                                       */
       clr.b     D6
OSFlagDel_7:
; }
; switch (opt) {
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq       OSFlagDel_11
       bhi       OSFlagDel_8
       tst.l     D0
       beq.s     OSFlagDel_10
       bra       OSFlagDel_8
OSFlagDel_10:
; case OS_DEL_NO_PEND:                               /* Delete group if no task waiting          */
; if (tasks_waiting == OS_FALSE) {
       tst.b     D6
       bne.s     OSFlagDel_13
; #if OS_FLAG_NAME_EN > 0u
; pgrp->OSFlagName     = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,8(A1)
; #endif
; pgrp->OSFlagType     = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pgrp->OSFlagWaitList = (void *)OSFlagFreeList; /* Return group to free list           */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pgrp->OSFlagFlags    = (OS_FLAGS)0;
       move.l    D2,A0
       clr.w     6(A0)
; OSFlagFreeList       = pgrp;
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; pgrp_return          = (OS_FLAG_GRP *)0;  /* Event Flag Group has been deleted        */
       clr.l     D5
       bra.s     OSFlagDel_14
OSFlagDel_13:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                = OS_ERR_TASK_WAITING;
       move.l    D3,A0
       move.b    #73,(A0)
; pgrp_return          = pgrp;
       move.l    D2,D5
OSFlagDel_14:
; }
; break;
       bra       OSFlagDel_9
OSFlagDel_11:
; case OS_DEL_ALWAYS:                                /* Always delete the event flag group       */
; pnode = (OS_FLAG_NODE *)pgrp->OSFlagWaitList;
       move.l    D2,A0
       move.l    2(A0),D4
; while (pnode != (OS_FLAG_NODE *)0) {          /* Ready ALL tasks waiting for flags        */
OSFlagDel_15:
       tst.l     D4
       beq.s     OSFlagDel_17
; (void)OS_FlagTaskRdy(pnode, (OS_FLAGS)0, OS_STAT_PEND_ABORT);
       pea       2
       clr.l     -(A7)
       move.l    D4,-(A7)
       jsr       @ucos_ii_OS_FlagTaskRdy
       add.w     #12,A7
       and.l     #255,D0
; pnode = (OS_FLAG_NODE *)pnode->OSFlagNodeNext;
       move.l    D4,A0
       move.l    (A0),D4
       bra       OSFlagDel_15
OSFlagDel_17:
; }
; #if OS_FLAG_NAME_EN > 0u
; pgrp->OSFlagName     = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,8(A1)
; #endif
; pgrp->OSFlagType     = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pgrp->OSFlagWaitList = (void *)OSFlagFreeList;/* Return group to free list                */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pgrp->OSFlagFlags    = (OS_FLAGS)0;
       move.l    D2,A0
       clr.w     6(A0)
; OSFlagFreeList       = pgrp;
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (tasks_waiting == OS_TRUE) {               /* Reschedule only if task(s) were waiting  */
       cmp.b     #1,D6
       bne.s     OSFlagDel_18
; OS_Sched();                               /* Find highest priority task ready to run  */
       jsr       _OS_Sched
OSFlagDel_18:
; }
; *perr = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; pgrp_return          = (OS_FLAG_GRP *)0;      /* Event Flag Group has been deleted        */
       clr.l     D5
; break;
       bra.s     OSFlagDel_9
OSFlagDel_8:
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                = OS_ERR_INVALID_OPT;
       move.l    D3,A0
       move.b    #7,(A0)
; pgrp_return          = pgrp;
       move.l    D2,D5
; break;
OSFlagDel_9:
; }
; return (pgrp_return);
       move.l    D5,D0
OSFlagDel_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                 GET THE NAME OF AN EVENT FLAG GROUP
; *
; * Description: This function is used to obtain the name assigned to an event flag group
; *
; * Arguments  : pgrp      is a pointer to the event flag group.
; *
; *              pname     is pointer to a pointer to an ASCII string that will receive the name of the event flag
; *                        group.
; *
; *              perr      is a pointer to an error code that can contain one of the following values:
; *
; *                        OS_ERR_NONE                if the requested task is resumed
; *                        OS_ERR_EVENT_TYPE          if 'pevent' is not pointing to an event flag group
; *                        OS_ERR_PNAME_NULL          You passed a NULL pointer for 'pname'
; *                        OS_ERR_FLAG_INVALID_PGRP   if you passed a NULL pointer for 'pgrp'
; *                        OS_ERR_NAME_GET_ISR        if you called this function from an ISR
; *
; * Returns    : The length of the string or 0 if the 'pgrp' is a NULL pointer.
; *********************************************************************************************************
; */
; #if OS_FLAG_NAME_EN > 0u
; INT8U  OSFlagNameGet (OS_FLAG_GRP   *pgrp,
; INT8U        **pname,
; INT8U         *perr)
; {
       xdef      _OSFlagNameGet
_OSFlagNameGet:
       link      A6,#-4
       move.l    D2,-(A7)
       move.l    16(A6),D2
; INT8U      len;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pgrp == (OS_FLAG_GRP *)0) {              /* Is 'pgrp' a NULL pointer?                          */
; *perr = OS_ERR_FLAG_INVALID_PGRP;
; return (0u);
; }
; if (pname == (INT8U **)0) {                   /* Is 'pname' a NULL pointer?                         */
; *perr = OS_ERR_PNAME_NULL;
; return (0u);
; }
; #endif
; if (OSIntNesting > 0u) {                     /* See if trying to call from an ISR                  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSFlagNameGet_1
; *perr = OS_ERR_NAME_GET_ISR;
       move.l    D2,A0
       move.b    #17,(A0)
; return (0u);
       clr.b     D0
       bra       OSFlagNameGet_3
OSFlagNameGet_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pgrp->OSFlagType != OS_EVENT_TYPE_FLAG) {
       move.l    8(A6),A0
       move.b    (A0),D0
       cmp.b     #5,D0
       beq.s     OSFlagNameGet_4
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D2,A0
       move.b    #1,(A0)
; return (0u);
       clr.b     D0
       bra.s     OSFlagNameGet_3
OSFlagNameGet_4:
; }
; *pname = pgrp->OSFlagName;
       move.l    8(A6),A0
       move.l    12(A6),A1
       move.l    8(A0),(A1)
; len    = OS_StrLen(*pname);
       move.l    12(A6),A0
       move.l    (A0),-(A7)
       jsr       _OS_StrLen
       addq.w    #4,A7
       move.b    D0,-1(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr  = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return (len);
       move.b    -1(A6),D0
OSFlagNameGet_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                ASSIGN A NAME TO AN EVENT FLAG GROUP
; *
; * Description: This function assigns a name to an event flag group.
; *
; * Arguments  : pgrp      is a pointer to the event flag group.
; *
; *              pname     is a pointer to an ASCII string that will be used as the name of the event flag
; *                        group.
; *
; *              perr      is a pointer to an error code that can contain one of the following values:
; *
; *                        OS_ERR_NONE                if the requested task is resumed
; *                        OS_ERR_EVENT_TYPE          if 'pevent' is not pointing to an event flag group
; *                        OS_ERR_PNAME_NULL          You passed a NULL pointer for 'pname'
; *                        OS_ERR_FLAG_INVALID_PGRP   if you passed a NULL pointer for 'pgrp'
; *                        OS_ERR_NAME_SET_ISR        if you called this function from an ISR
; *
; * Returns    : None
; *********************************************************************************************************
; */
; #if OS_FLAG_NAME_EN > 0u
; void  OSFlagNameSet (OS_FLAG_GRP  *pgrp,
; INT8U        *pname,
; INT8U        *perr)
; {
       xdef      _OSFlagNameSet
_OSFlagNameSet:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    16(A6),D2
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return;
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pgrp == (OS_FLAG_GRP *)0) {              /* Is 'pgrp' a NULL pointer?                          */
; *perr = OS_ERR_FLAG_INVALID_PGRP;
; return;
; }
; if (pname == (INT8U *)0) {                   /* Is 'pname' a NULL pointer?                         */
; *perr = OS_ERR_PNAME_NULL;
; return;
; }
; #endif
; if (OSIntNesting > 0u) {                     /* See if trying to call from an ISR                  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSFlagNameSet_1
; *perr = OS_ERR_NAME_SET_ISR;
       move.l    D2,A0
       move.b    #18,(A0)
; return;
       bra       OSFlagNameSet_3
OSFlagNameSet_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pgrp->OSFlagType != OS_EVENT_TYPE_FLAG) {
       move.l    8(A6),A0
       move.b    (A0),D0
       cmp.b     #5,D0
       beq.s     OSFlagNameSet_4
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D2,A0
       move.b    #1,(A0)
; return;
       bra.s     OSFlagNameSet_3
OSFlagNameSet_4:
; }
; pgrp->OSFlagName = pname;
       move.l    8(A6),A0
       move.l    12(A6),8(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr            = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return;
OSFlagNameSet_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                     WAIT ON AN EVENT FLAG GROUP
; *
; * Description: This function is called to wait for a combination of bits to be set in an event flag
; *              group.  Your application can wait for ANY bit to be set or ALL bits to be set.
; *
; * Arguments  : pgrp          is a pointer to the desired event flag group.
; *
; *              flags         Is a bit pattern indicating which bit(s) (i.e. flags) you wish to wait for.
; *                            The bits you want are specified by setting the corresponding bits in
; *                            'flags'.  e.g. if your application wants to wait for bits 0 and 1 then
; *                            'flags' would contain 0x03.
; *
; *              wait_type     specifies whether you want ALL bits to be set or ANY of the bits to be set.
; *                            You can specify the following argument:
; *
; *                            OS_FLAG_WAIT_CLR_ALL   You will wait for ALL bits in 'mask' to be clear (0)
; *                            OS_FLAG_WAIT_SET_ALL   You will wait for ALL bits in 'mask' to be set   (1)
; *                            OS_FLAG_WAIT_CLR_ANY   You will wait for ANY bit  in 'mask' to be clear (0)
; *                            OS_FLAG_WAIT_SET_ANY   You will wait for ANY bit  in 'mask' to be set   (1)
; *
; *                            NOTE: Add OS_FLAG_CONSUME if you want the event flag to be 'consumed' by
; *                                  the call.  Example, to wait for any flag in a group AND then clear
; *                                  the flags that are present, set 'wait_type' to:
; *
; *                                  OS_FLAG_WAIT_SET_ANY + OS_FLAG_CONSUME
; *
; *              timeout       is an optional timeout (in clock ticks) that your task will wait for the
; *                            desired bit combination.  If you specify 0, however, your task will wait
; *                            forever at the specified event flag group or, until a message arrives.
; *
; *              perr          is a pointer to an error code and can be:
; *                            OS_ERR_NONE               The desired bits have been set within the specified
; *                                                      'timeout'.
; *                            OS_ERR_PEND_ISR           If you tried to PEND from an ISR
; *                            OS_ERR_FLAG_INVALID_PGRP  If 'pgrp' is a NULL pointer.
; *                            OS_ERR_EVENT_TYPE         You are not pointing to an event flag group
; *                            OS_ERR_TIMEOUT            The bit(s) have not been set in the specified
; *                                                      'timeout'.
; *                            OS_ERR_PEND_ABORT         The wait on the flag was aborted.
; *                            OS_ERR_FLAG_WAIT_TYPE     You didn't specify a proper 'wait_type' argument.
; *
; * Returns    : The flags in the event flag group that made the task ready or, 0 if a timeout or an error
; *              occurred.
; *
; * Called from: Task ONLY
; *
; * Note(s)    : 1) IMPORTANT, the behavior of this function has changed from PREVIOUS versions.  The
; *                 function NOW returns the flags that were ready INSTEAD of the current state of the
; *                 event flags.
; *********************************************************************************************************
; */
; OS_FLAGS  OSFlagPend (OS_FLAG_GRP  *pgrp,
; OS_FLAGS      flags,
; INT8U         wait_type,
; INT32U        timeout,
; INT8U        *perr)
; {
       xdef      _OSFlagPend
_OSFlagPend:
       link      A6,#-24
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       move.l    8(A6),D3
       move.l    24(A6),D4
       move.w    14(A6),D5
       and.l     #65535,D5
       lea       _OSTCBCur.L,A2
       move.b    19(A6),D6
       and.l     #255,D6
       lea       -22(A6),A3
       move.l    20(A6),A4
       lea       @ucos_ii_OS_FlagBlock.L,A5
; OS_FLAG_NODE  node;
; OS_FLAGS      flags_rdy;
; INT8U         result;
; INT8U         pend_stat;
; BOOLEAN       consume;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR     cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_FLAGS)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pgrp == (OS_FLAG_GRP *)0) {                        /* Validate 'pgrp'                          */
; *perr = OS_ERR_FLAG_INVALID_PGRP;
; return ((OS_FLAGS)0);
; }
; #endif
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSFlagPend_1
; *perr = OS_ERR_PEND_ISR;                           /* ... can't PEND from an ISR               */
       move.l    D4,A0
       move.b    #2,(A0)
; return ((OS_FLAGS)0);
       clr.w     D0
       bra       OSFlagPend_3
OSFlagPend_1:
; }
; if (OSLockNesting > 0u) {                              /* See if called with scheduler locked ...  */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSFlagPend_4
; *perr = OS_ERR_PEND_LOCKED;                        /* ... can't PEND when locked               */
       move.l    D4,A0
       move.b    #13,(A0)
; return ((OS_FLAGS)0);
       clr.w     D0
       bra       OSFlagPend_3
OSFlagPend_4:
; }
; if (pgrp->OSFlagType != OS_EVENT_TYPE_FLAG) {          /* Validate event block type                */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #5,D0
       beq.s     OSFlagPend_6
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return ((OS_FLAGS)0);
       clr.w     D0
       bra       OSFlagPend_3
OSFlagPend_6:
; }
; result = (INT8U)(wait_type & OS_FLAG_CONSUME);
       move.b    D6,D0
       and.b     #128,D0
       move.b    D0,-2(A6)
; if (result != (INT8U)0) {                              /* See if we need to consume the flags      */
       move.b    -2(A6),D0
       beq.s     OSFlagPend_8
; wait_type &= (INT8U)~(INT8U)OS_FLAG_CONSUME;
       move.b    #128,D0
       not.b     D0
       and.b     D0,D6
; consume    = OS_TRUE;
       moveq     #1,D7
       bra.s     OSFlagPend_9
OSFlagPend_8:
; } else {
; consume    = OS_FALSE;
       moveq     #0,D7
OSFlagPend_9:
; }
; /*$PAGE*/
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; switch (wait_type) {
       and.l     #255,D6
       move.l    D6,D0
       cmp.l     #4,D0
       bhs       OSFlagPend_10
       asl.l     #1,D0
       move.w    OSFlagPend_12(PC,D0.L),D0
       jmp       OSFlagPend_12(PC,D0.W)
OSFlagPend_12:
       dc.w      OSFlagPend_15-OSFlagPend_12
       dc.w      OSFlagPend_16-OSFlagPend_12
       dc.w      OSFlagPend_13-OSFlagPend_12
       dc.w      OSFlagPend_14-OSFlagPend_12
OSFlagPend_13:
; case OS_FLAG_WAIT_SET_ALL:                         /* See if all required flags are set        */
; flags_rdy = (OS_FLAGS)(pgrp->OSFlagFlags & flags);   /* Extract only the bits we want     */
       move.l    D3,A0
       move.w    6(A0),D0
       and.w     D5,D0
       move.w    D0,D2
; if (flags_rdy == flags) {                     /* Must match ALL the bits that we want     */
       cmp.w     D5,D2
       bne.s     OSFlagPend_18
; if (consume == OS_TRUE) {                 /* See if we need to consume the flags      */
       cmp.b     #1,D7
       bne.s     OSFlagPend_20
; pgrp->OSFlagFlags &= (OS_FLAGS)~flags_rdy;   /* Clear ONLY the flags we wanted    */
       move.l    D3,A0
       move.w    D2,D0
       not.w     D0
       and.w     D0,6(A0)
OSFlagPend_20:
; }
; OSTCBCur->OSTCBFlagsRdy = flags_rdy;      /* Save flags that were ready               */
       move.l    (A2),A0
       move.w    D2,44(A0)
; OS_EXIT_CRITICAL();                       /* Yes, condition met, return to caller     */
       dc.w      18143
; *perr                   = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; return (flags_rdy);
       move.w    D2,D0
       bra       OSFlagPend_3
OSFlagPend_18:
; } else {                                      /* Block task until events occur or timeout */
; OS_FlagBlock(pgrp, &node, flags, wait_type, timeout);
       move.l    A4,-(A7)
       and.l     #255,D6
       move.l    D6,-(A7)
       and.l     #65535,D5
       move.l    D5,-(A7)
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       jsr       (A5)
       add.w     #20,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; }
; break;
       bra       OSFlagPend_11
OSFlagPend_14:
; case OS_FLAG_WAIT_SET_ANY:
; flags_rdy = (OS_FLAGS)(pgrp->OSFlagFlags & flags);    /* Extract only the bits we want    */
       move.l    D3,A0
       move.w    6(A0),D0
       and.w     D5,D0
       move.w    D0,D2
; if (flags_rdy != (OS_FLAGS)0) {               /* See if any flag set                      */
       tst.w     D2
       beq.s     OSFlagPend_22
; if (consume == OS_TRUE) {                 /* See if we need to consume the flags      */
       cmp.b     #1,D7
       bne.s     OSFlagPend_24
; pgrp->OSFlagFlags &= (OS_FLAGS)~flags_rdy;    /* Clear ONLY the flags that we got */
       move.l    D3,A0
       move.w    D2,D0
       not.w     D0
       and.w     D0,6(A0)
OSFlagPend_24:
; }
; OSTCBCur->OSTCBFlagsRdy = flags_rdy;      /* Save flags that were ready               */
       move.l    (A2),A0
       move.w    D2,44(A0)
; OS_EXIT_CRITICAL();                       /* Yes, condition met, return to caller     */
       dc.w      18143
; *perr                   = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; return (flags_rdy);
       move.w    D2,D0
       bra       OSFlagPend_3
OSFlagPend_22:
; } else {                                      /* Block task until events occur or timeout */
; OS_FlagBlock(pgrp, &node, flags, wait_type, timeout);
       move.l    A4,-(A7)
       and.l     #255,D6
       move.l    D6,-(A7)
       and.l     #65535,D5
       move.l    D5,-(A7)
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       jsr       (A5)
       add.w     #20,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; }
; break;
       bra       OSFlagPend_11
OSFlagPend_15:
; #if OS_FLAG_WAIT_CLR_EN > 0u
; case OS_FLAG_WAIT_CLR_ALL:                         /* See if all required flags are cleared    */
; flags_rdy = (OS_FLAGS)~pgrp->OSFlagFlags & flags;    /* Extract only the bits we want     */
       move.l    D3,A0
       move.w    6(A0),D0
       not.w     D0
       and.w     D5,D0
       move.w    D0,D2
; if (flags_rdy == flags) {                     /* Must match ALL the bits that we want     */
       cmp.w     D5,D2
       bne.s     OSFlagPend_26
; if (consume == OS_TRUE) {                 /* See if we need to consume the flags      */
       cmp.b     #1,D7
       bne.s     OSFlagPend_28
; pgrp->OSFlagFlags |= flags_rdy;       /* Set ONLY the flags that we wanted        */
       move.l    D3,A0
       or.w      D2,6(A0)
OSFlagPend_28:
; }
; OSTCBCur->OSTCBFlagsRdy = flags_rdy;      /* Save flags that were ready               */
       move.l    (A2),A0
       move.w    D2,44(A0)
; OS_EXIT_CRITICAL();                       /* Yes, condition met, return to caller     */
       dc.w      18143
; *perr                   = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; return (flags_rdy);
       move.w    D2,D0
       bra       OSFlagPend_3
OSFlagPend_26:
; } else {                                      /* Block task until events occur or timeout */
; OS_FlagBlock(pgrp, &node, flags, wait_type, timeout);
       move.l    A4,-(A7)
       and.l     #255,D6
       move.l    D6,-(A7)
       and.l     #65535,D5
       move.l    D5,-(A7)
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       jsr       (A5)
       add.w     #20,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; }
; break;
       bra       OSFlagPend_11
OSFlagPend_16:
; case OS_FLAG_WAIT_CLR_ANY:
; flags_rdy = (OS_FLAGS)~pgrp->OSFlagFlags & flags;   /* Extract only the bits we want      */
       move.l    D3,A0
       move.w    6(A0),D0
       not.w     D0
       and.w     D5,D0
       move.w    D0,D2
; if (flags_rdy != (OS_FLAGS)0) {               /* See if any flag cleared                  */
       tst.w     D2
       beq.s     OSFlagPend_30
; if (consume == OS_TRUE) {                 /* See if we need to consume the flags      */
       cmp.b     #1,D7
       bne.s     OSFlagPend_32
; pgrp->OSFlagFlags |= flags_rdy;       /* Set ONLY the flags that we got           */
       move.l    D3,A0
       or.w      D2,6(A0)
OSFlagPend_32:
; }
; OSTCBCur->OSTCBFlagsRdy = flags_rdy;      /* Save flags that were ready               */
       move.l    (A2),A0
       move.w    D2,44(A0)
; OS_EXIT_CRITICAL();                       /* Yes, condition met, return to caller     */
       dc.w      18143
; *perr                   = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; return (flags_rdy);
       move.w    D2,D0
       bra       OSFlagPend_3
OSFlagPend_30:
; } else {                                      /* Block task until events occur or timeout */
; OS_FlagBlock(pgrp, &node, flags, wait_type, timeout);
       move.l    A4,-(A7)
       and.l     #255,D6
       move.l    D6,-(A7)
       and.l     #65535,D5
       move.l    D5,-(A7)
       move.l    A3,-(A7)
       move.l    D3,-(A7)
       jsr       (A5)
       add.w     #20,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; }
; break;
       bra.s     OSFlagPend_11
OSFlagPend_10:
; #endif
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; flags_rdy = (OS_FLAGS)0;
       clr.w     D2
; *perr      = OS_ERR_FLAG_WAIT_TYPE;
       move.l    D4,A0
       move.b    #111,(A0)
; return (flags_rdy);
       move.w    D2,D0
       bra       OSFlagPend_3
OSFlagPend_11:
; }
; /*$PAGE*/
; OS_Sched();                                            /* Find next HPT ready to run               */
       jsr       _OS_Sched
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSTCBCur->OSTCBStatPend != OS_STAT_PEND_OK) {      /* Have we timed-out or aborted?            */
       move.l    (A2),A0
       move.b    51(A0),D0
       beq       OSFlagPend_34
; pend_stat                = OSTCBCur->OSTCBStatPend;
       move.l    (A2),A0
       move.b    51(A0),-1(A6)
; OSTCBCur->OSTCBStatPend  = OS_STAT_PEND_OK;
       move.l    (A2),A0
       clr.b     51(A0)
; OS_FlagUnlink(&node);
       move.l    A3,-(A7)
       jsr       _OS_FlagUnlink
       addq.w    #4,A7
; OSTCBCur->OSTCBStat      = OS_STAT_RDY;            /* Yes, make task ready-to-run              */
       move.l    (A2),A0
       clr.b     50(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; flags_rdy                = (OS_FLAGS)0;
       clr.w     D2
; switch (pend_stat) {
       move.b    -1(A6),D0
       and.l     #255,D0
       cmp.l     #2,D0
       beq.s     OSFlagPend_38
       bhi.s     OSFlagPend_39
       cmp.l     #1,D0
       beq.s     OSFlagPend_39
       bra.s     OSFlagPend_39
OSFlagPend_38:
; case OS_STAT_PEND_ABORT:
; *perr = OS_ERR_PEND_ABORT;                /* Indicate that we aborted   waiting       */
       move.l    D4,A0
       move.b    #14,(A0)
; break;
       bra.s     OSFlagPend_37
OSFlagPend_39:
; case OS_STAT_PEND_TO:
; default:
; *perr = OS_ERR_TIMEOUT;                   /* Indicate that we timed-out waiting       */
       move.l    D4,A0
       move.b    #10,(A0)
; break;
OSFlagPend_37:
; }
; return (flags_rdy);
       move.w    D2,D0
       bra       OSFlagPend_3
OSFlagPend_34:
; }
; flags_rdy = OSTCBCur->OSTCBFlagsRdy;
       move.l    (A2),A0
       move.w    44(A0),D2
; if (consume == OS_TRUE) {                              /* See if we need to consume the flags      */
       cmp.b     #1,D7
       bne       OSFlagPend_44
; switch (wait_type) {
       and.l     #255,D6
       move.l    D6,D0
       cmp.l     #4,D0
       bhs.s     OSFlagPend_43
       asl.l     #1,D0
       move.w    OSFlagPend_45(PC,D0.L),D0
       jmp       OSFlagPend_45(PC,D0.W)
OSFlagPend_45:
       dc.w      OSFlagPend_48-OSFlagPend_45
       dc.w      OSFlagPend_48-OSFlagPend_45
       dc.w      OSFlagPend_46-OSFlagPend_45
       dc.w      OSFlagPend_46-OSFlagPend_45
OSFlagPend_46:
; case OS_FLAG_WAIT_SET_ALL:
; case OS_FLAG_WAIT_SET_ANY:                     /* Clear ONLY the flags we got              */
; pgrp->OSFlagFlags &= (OS_FLAGS)~flags_rdy;
       move.l    D3,A0
       move.w    D2,D0
       not.w     D0
       and.w     D0,6(A0)
; break;
       bra.s     OSFlagPend_44
OSFlagPend_48:
; #if OS_FLAG_WAIT_CLR_EN > 0u
; case OS_FLAG_WAIT_CLR_ALL:
; case OS_FLAG_WAIT_CLR_ANY:                     /* Set   ONLY the flags we got              */
; pgrp->OSFlagFlags |=  flags_rdy;
       move.l    D3,A0
       or.w      D2,6(A0)
; break;
       bra.s     OSFlagPend_44
OSFlagPend_43:
; #endif
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_FLAG_WAIT_TYPE;
       move.l    D4,A0
       move.b    #111,(A0)
; return ((OS_FLAGS)0);
       clr.w     D0
       bra.s     OSFlagPend_3
OSFlagPend_44:
; }
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;                                   /* Event(s) must have occurred              */
       move.l    D4,A0
       clr.b     (A0)
; return (flags_rdy);
       move.w    D2,D0
OSFlagPend_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                              GET FLAGS WHO CAUSED TASK TO BECOME READY
; *
; * Description: This function is called to obtain the flags that caused the task to become ready to run.
; *              In other words, this function allows you to tell "Who done it!".
; *
; * Arguments  : None
; *
; * Returns    : The flags that caused the task to be ready.
; *
; * Called from: Task ONLY
; *********************************************************************************************************
; */
; OS_FLAGS  OSFlagPendGetFlagsRdy (void)
; {
       xdef      _OSFlagPendGetFlagsRdy
_OSFlagPendGetFlagsRdy:
       link      A6,#-4
; OS_FLAGS      flags;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR     cpu_sr = 0u;
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; flags = OSTCBCur->OSTCBFlagsRdy;
       move.l    _OSTCBCur.L,A0
       move.w    44(A0),-2(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (flags);
       move.w    -2(A6),D0
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       POST EVENT FLAG BIT(S)
; *
; * Description: This function is called to set or clear some bits in an event flag group.  The bits to
; *              set or clear are specified by a 'bit mask'.
; *
; * Arguments  : pgrp          is a pointer to the desired event flag group.
; *
; *              flags         If 'opt' (see below) is OS_FLAG_SET, each bit that is set in 'flags' will
; *                            set the corresponding bit in the event flag group.  e.g. to set bits 0, 4
; *                            and 5 you would set 'flags' to:
; *
; *                                0x31     (note, bit 0 is least significant bit)
; *
; *                            If 'opt' (see below) is OS_FLAG_CLR, each bit that is set in 'flags' will
; *                            CLEAR the corresponding bit in the event flag group.  e.g. to clear bits 0,
; *                            4 and 5 you would specify 'flags' as:
; *
; *                                0x31     (note, bit 0 is least significant bit)
; *
; *              opt           indicates whether the flags will be:
; *                                set     (OS_FLAG_SET) or
; *                                cleared (OS_FLAG_CLR)
; *
; *              perr          is a pointer to an error code and can be:
; *                            OS_ERR_NONE                The call was successfull
; *                            OS_ERR_FLAG_INVALID_PGRP   You passed a NULL pointer
; *                            OS_ERR_EVENT_TYPE          You are not pointing to an event flag group
; *                            OS_ERR_FLAG_INVALID_OPT    You specified an invalid option
; *
; * Returns    : the new value of the event flags bits that are still set.
; *
; * Called From: Task or ISR
; *
; * WARNING(s) : 1) The execution time of this function depends on the number of tasks waiting on the event
; *                 flag group.
; *              2) The amount of time interrupts are DISABLED depends on the number of tasks waiting on
; *                 the event flag group.
; *********************************************************************************************************
; */
; OS_FLAGS  OSFlagPost (OS_FLAG_GRP  *pgrp,
; OS_FLAGS      flags,
; INT8U         opt,
; INT8U        *perr)
; {
       xdef      _OSFlagPost
_OSFlagPost:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/D7/A2,-(A7)
       move.l    8(A6),D4
       lea       @ucos_ii_OS_FlagTaskRdy.L,A2
       move.l    20(A6),D7
; OS_FLAG_NODE *pnode;
; BOOLEAN       sched;
; OS_FLAGS      flags_cur;
; OS_FLAGS      flags_rdy;
; BOOLEAN       rdy;
; #if OS_CRITICAL_METHOD == 3u                         /* Allocate storage for CPU status register       */
; OS_CPU_SR     cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_FLAGS)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pgrp == (OS_FLAG_GRP *)0) {                  /* Validate 'pgrp'                                */
; *perr = OS_ERR_FLAG_INVALID_PGRP;
; return ((OS_FLAGS)0);
; }
; #endif
; if (pgrp->OSFlagType != OS_EVENT_TYPE_FLAG) {    /* Make sure we are pointing to an event flag grp */
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #5,D0
       beq.s     OSFlagPost_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D7,A0
       move.b    #1,(A0)
; return ((OS_FLAGS)0);
       clr.w     D0
       bra       OSFlagPost_3
OSFlagPost_1:
; }
; /*$PAGE*/
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; switch (opt) {
       move.b    19(A6),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq.s     OSFlagPost_7
       bhi.s     OSFlagPost_4
       tst.l     D0
       beq.s     OSFlagPost_6
       bra.s     OSFlagPost_4
OSFlagPost_6:
; case OS_FLAG_CLR:
; pgrp->OSFlagFlags &= (OS_FLAGS)~flags;  /* Clear the flags specified in the group         */
       move.l    D4,A0
       move.w    14(A6),D0
       not.w     D0
       and.w     D0,6(A0)
; break;
       bra.s     OSFlagPost_5
OSFlagPost_7:
; case OS_FLAG_SET:
; pgrp->OSFlagFlags |=  flags;            /* Set   the flags specified in the group         */
       move.l    D4,A0
       move.w    14(A6),D0
       or.w      D0,6(A0)
; break;
       bra.s     OSFlagPost_5
OSFlagPost_4:
; default:
; OS_EXIT_CRITICAL();                     /* INVALID option                                 */
       dc.w      18143
; *perr = OS_ERR_FLAG_INVALID_OPT;
       move.l    D7,A0
       move.b    #113,(A0)
; return ((OS_FLAGS)0);
       clr.w     D0
       bra       OSFlagPost_3
OSFlagPost_5:
; }
; sched = OS_FALSE;                                /* Indicate that we don't need rescheduling       */
       clr.b     D6
; pnode = (OS_FLAG_NODE *)pgrp->OSFlagWaitList;
       move.l    D4,A0
       move.l    2(A0),D2
; while (pnode != (OS_FLAG_NODE *)0) {             /* Go through all tasks waiting on event flag(s)  */
OSFlagPost_9:
       tst.l     D2
       beq       OSFlagPost_11
; switch (pnode->OSFlagNodeWaitType) {
       move.l    D2,A0
       move.b    18(A0),D0
       and.l     #255,D0
       cmp.l     #4,D0
       bhs       OSFlagPost_12
       asl.l     #1,D0
       move.w    OSFlagPost_14(PC,D0.L),D0
       jmp       OSFlagPost_14(PC,D0.W)
OSFlagPost_14:
       dc.w      OSFlagPost_17-OSFlagPost_14
       dc.w      OSFlagPost_18-OSFlagPost_14
       dc.w      OSFlagPost_15-OSFlagPost_14
       dc.w      OSFlagPost_16-OSFlagPost_14
OSFlagPost_15:
; case OS_FLAG_WAIT_SET_ALL:               /* See if all req. flags are set for current node */
; flags_rdy = (OS_FLAGS)(pgrp->OSFlagFlags & pnode->OSFlagNodeFlags);
       move.l    D4,A0
       move.w    6(A0),D0
       move.l    D2,A0
       and.w     16(A0),D0
       move.w    D0,D3
; if (flags_rdy == pnode->OSFlagNodeFlags) {   /* Make task RTR, event(s) Rx'd          */
       move.l    D2,A0
       cmp.w     16(A0),D3
       bne.s     OSFlagPost_22
; rdy = OS_FlagTaskRdy(pnode, flags_rdy, OS_STAT_PEND_OK);
       clr.l     -(A7)
       and.l     #65535,D3
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       jsr       (A2)
       add.w     #12,A7
       move.b    D0,D5
; if (rdy == OS_TRUE) {
       cmp.b     #1,D5
       bne.s     OSFlagPost_22
; sched = OS_TRUE;                     /* When done we will reschedule          */
       moveq     #1,D6
OSFlagPost_22:
; }
; }
; break;
       bra       OSFlagPost_13
OSFlagPost_16:
; case OS_FLAG_WAIT_SET_ANY:               /* See if any flag set                            */
; flags_rdy = (OS_FLAGS)(pgrp->OSFlagFlags & pnode->OSFlagNodeFlags);
       move.l    D4,A0
       move.w    6(A0),D0
       move.l    D2,A0
       and.w     16(A0),D0
       move.w    D0,D3
; if (flags_rdy != (OS_FLAGS)0) {              /* Make task RTR, event(s) Rx'd          */
       tst.w     D3
       beq.s     OSFlagPost_26
; rdy = OS_FlagTaskRdy(pnode, flags_rdy, OS_STAT_PEND_OK);
       clr.l     -(A7)
       and.l     #65535,D3
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       jsr       (A2)
       add.w     #12,A7
       move.b    D0,D5
; if (rdy == OS_TRUE) {
       cmp.b     #1,D5
       bne.s     OSFlagPost_26
; sched = OS_TRUE;                     /* When done we will reschedule          */
       moveq     #1,D6
OSFlagPost_26:
; }
; }
; break;
       bra       OSFlagPost_13
OSFlagPost_17:
; #if OS_FLAG_WAIT_CLR_EN > 0u
; case OS_FLAG_WAIT_CLR_ALL:               /* See if all req. flags are set for current node */
; flags_rdy = (OS_FLAGS)~pgrp->OSFlagFlags & pnode->OSFlagNodeFlags;
       move.l    D4,A0
       move.w    6(A0),D0
       not.w     D0
       move.l    D2,A0
       and.w     16(A0),D0
       move.w    D0,D3
; if (flags_rdy == pnode->OSFlagNodeFlags) {   /* Make task RTR, event(s) Rx'd          */
       move.l    D2,A0
       cmp.w     16(A0),D3
       bne.s     OSFlagPost_30
; rdy = OS_FlagTaskRdy(pnode, flags_rdy, OS_STAT_PEND_OK);
       clr.l     -(A7)
       and.l     #65535,D3
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       jsr       (A2)
       add.w     #12,A7
       move.b    D0,D5
; if (rdy == OS_TRUE) {
       cmp.b     #1,D5
       bne.s     OSFlagPost_30
; sched = OS_TRUE;                     /* When done we will reschedule          */
       moveq     #1,D6
OSFlagPost_30:
; }
; }
; break;
       bra       OSFlagPost_13
OSFlagPost_18:
; case OS_FLAG_WAIT_CLR_ANY:               /* See if any flag set                            */
; flags_rdy = (OS_FLAGS)~pgrp->OSFlagFlags & pnode->OSFlagNodeFlags;
       move.l    D4,A0
       move.w    6(A0),D0
       not.w     D0
       move.l    D2,A0
       and.w     16(A0),D0
       move.w    D0,D3
; if (flags_rdy != (OS_FLAGS)0) {              /* Make task RTR, event(s) Rx'd          */
       tst.w     D3
       beq.s     OSFlagPost_34
; rdy = OS_FlagTaskRdy(pnode, flags_rdy, OS_STAT_PEND_OK);
       clr.l     -(A7)
       and.l     #65535,D3
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       jsr       (A2)
       add.w     #12,A7
       move.b    D0,D5
; if (rdy == OS_TRUE) {
       cmp.b     #1,D5
       bne.s     OSFlagPost_34
; sched = OS_TRUE;                     /* When done we will reschedule          */
       moveq     #1,D6
OSFlagPost_34:
; }
; }
; break;
       bra.s     OSFlagPost_13
OSFlagPost_12:
; #endif
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_FLAG_WAIT_TYPE;
       move.l    D7,A0
       move.b    #111,(A0)
; return ((OS_FLAGS)0);
       clr.w     D0
       bra       OSFlagPost_3
OSFlagPost_13:
; }
; pnode = (OS_FLAG_NODE *)pnode->OSFlagNodeNext; /* Point to next task waiting for event flag(s) */
       move.l    D2,A0
       move.l    (A0),D2
       bra       OSFlagPost_9
OSFlagPost_11:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (sched == OS_TRUE) {
       cmp.b     #1,D6
       bne.s     OSFlagPost_36
; OS_Sched();
       jsr       _OS_Sched
OSFlagPost_36:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; flags_cur = pgrp->OSFlagFlags;
       move.l    D4,A0
       move.w    6(A0),-2(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr     = OS_ERR_NONE;
       move.l    D7,A0
       clr.b     (A0)
; return (flags_cur);
       move.w    -2(A6),D0
OSFlagPost_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                          QUERY EVENT FLAG
; *
; * Description: This function is used to check the value of the event flag group.
; *
; * Arguments  : pgrp         is a pointer to the desired event flag group.
; *
; *              perr          is a pointer to an error code returned to the called:
; *                            OS_ERR_NONE                The call was successfull
; *                            OS_ERR_FLAG_INVALID_PGRP   You passed a NULL pointer
; *                            OS_ERR_EVENT_TYPE          You are not pointing to an event flag group
; *
; * Returns    : The current value of the event flag group.
; *
; * Called From: Task or ISR
; *********************************************************************************************************
; */
; #if OS_FLAG_QUERY_EN > 0u
; OS_FLAGS  OSFlagQuery (OS_FLAG_GRP  *pgrp,
; INT8U        *perr)
; {
       xdef      _OSFlagQuery
_OSFlagQuery:
       link      A6,#-4
; OS_FLAGS   flags;
; #if OS_CRITICAL_METHOD == 3u                      /* Allocate storage for CPU status register          */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_FLAGS)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pgrp == (OS_FLAG_GRP *)0) {               /* Validate 'pgrp'                                   */
; *perr = OS_ERR_FLAG_INVALID_PGRP;
; return ((OS_FLAGS)0);
; }
; #endif
; if (pgrp->OSFlagType != OS_EVENT_TYPE_FLAG) { /* Validate event block type                         */
       move.l    8(A6),A0
       move.b    (A0),D0
       cmp.b     #5,D0
       beq.s     OSFlagQuery_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    12(A6),A0
       move.b    #1,(A0)
; return ((OS_FLAGS)0);
       clr.w     D0
       bra.s     OSFlagQuery_3
OSFlagQuery_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; flags = pgrp->OSFlagFlags;
       move.l    8(A6),A0
       move.w    6(A0),-2(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    12(A6),A0
       clr.b     (A0)
; return (flags);                               /* Return the current value of the event flags       */
       move.w    -2(A6),D0
OSFlagQuery_3:
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                     SUSPEND TASK UNTIL EVENT FLAG(s) RECEIVED OR TIMEOUT OCCURS
; *
; * Description: This function is internal to uC/OS-II and is used to put a task to sleep until the desired
; *              event flag bit(s) are set.
; *
; * Arguments  : pgrp          is a pointer to the desired event flag group.
; *
; *              pnode         is a pointer to a structure which contains data about the task waiting for
; *                            event flag bit(s) to be set.
; *
; *              flags         Is a bit pattern indicating which bit(s) (i.e. flags) you wish to check.
; *                            The bits you want are specified by setting the corresponding bits in
; *                            'flags'.  e.g. if your application wants to wait for bits 0 and 1 then
; *                            'flags' would contain 0x03.
; *
; *              wait_type     specifies whether you want ALL bits to be set/cleared or ANY of the bits
; *                            to be set/cleared.
; *                            You can specify the following argument:
; *
; *                            OS_FLAG_WAIT_CLR_ALL   You will check ALL bits in 'mask' to be clear (0)
; *                            OS_FLAG_WAIT_CLR_ANY   You will check ANY bit  in 'mask' to be clear (0)
; *                            OS_FLAG_WAIT_SET_ALL   You will check ALL bits in 'mask' to be set   (1)
; *                            OS_FLAG_WAIT_SET_ANY   You will check ANY bit  in 'mask' to be set   (1)
; *
; *              timeout       is the desired amount of time that the task will wait for the event flag
; *                            bit(s) to be set.
; *
; * Returns    : none
; *
; * Called by  : OSFlagPend()  OS_FLAG.C
; *
; * Note(s)    : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; static  void  OS_FlagBlock (OS_FLAG_GRP  *pgrp,
; OS_FLAG_NODE *pnode,
; OS_FLAGS      flags,
; INT8U         wait_type,
; INT32U        timeout)
; {
@ucos_ii_OS_FlagBlock:
       link      A6,#0
       movem.l   D2/D3/D4/D5/A2,-(A7)
       move.l    12(A6),D2
       lea       _OSTCBCur.L,A2
       move.l    8(A6),D3
; OS_FLAG_NODE  *pnode_next;
; INT8U          y;
; OSTCBCur->OSTCBStat      |= OS_STAT_FLAG;
       move.l    (A2),A0
       or.b      #32,50(A0)
; OSTCBCur->OSTCBStatPend   = OS_STAT_PEND_OK;
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBDly        = timeout;              /* Store timeout in task's TCB                   */
       move.l    (A2),A0
       move.l    24(A6),46(A0)
; #if OS_TASK_DEL_EN > 0u
; OSTCBCur->OSTCBFlagNode   = pnode;                /* TCB to link to node                           */
       move.l    (A2),A0
       move.l    D2,40(A0)
; #endif
; pnode->OSFlagNodeFlags    = flags;                /* Save the flags that we need to wait for       */
       move.l    D2,A0
       move.w    18(A6),16(A0)
; pnode->OSFlagNodeWaitType = wait_type;            /* Save the type of wait we are doing            */
       move.l    D2,A0
       move.b    23(A6),18(A0)
; pnode->OSFlagNodeTCB      = (void *)OSTCBCur;     /* Link to task's TCB                            */
       move.l    D2,A0
       move.l    (A2),8(A0)
; pnode->OSFlagNodeNext     = pgrp->OSFlagWaitList; /* Add node at beginning of event flag wait list */
       move.l    D3,A0
       move.l    D2,A1
       move.l    2(A0),(A1)
; pnode->OSFlagNodePrev     = (void *)0;
       move.l    D2,A0
       clr.l     4(A0)
; pnode->OSFlagNodeFlagGrp  = (void *)pgrp;         /* Link to Event Flag Group                      */
       move.l    D2,A0
       move.l    D3,12(A0)
; pnode_next                = (OS_FLAG_NODE *)pgrp->OSFlagWaitList;
       move.l    D3,A0
       move.l    2(A0),D5
; if (pnode_next != (void *)0) {                    /* Is this the first NODE to insert?             */
       tst.l     D5
       beq.s     @ucos_ii_OS_FlagBlock_1
; pnode_next->OSFlagNodePrev = pnode;           /* No, link in doubly linked list                */
       move.l    D5,A0
       move.l    D2,4(A0)
@ucos_ii_OS_FlagBlock_1:
; }
; pgrp->OSFlagWaitList = (void *)pnode;
       move.l    D3,A0
       move.l    D2,2(A0)
; y            =  OSTCBCur->OSTCBY;                 /* Suspend current task until flag(s) received   */
       move.l    (A2),A0
       move.b    54(A0),D4
; OSRdyTbl[y] &= (OS_PRIO)~OSTCBCur->OSTCBBitX;
       and.l     #255,D4
       lea       _OSRdyTbl.L,A0
       move.l    (A2),A1
       move.b    55(A1),D0
       not.b     D0
       and.b     D0,0(A0,D4.L)
; if (OSRdyTbl[y] == 0x00u) {
       and.l     #255,D4
       lea       _OSRdyTbl.L,A0
       move.b    0(A0,D4.L),D0
       bne.s     @ucos_ii_OS_FlagBlock_3
; OSRdyGrp &= (OS_PRIO)~OSTCBCur->OSTCBBitY;
       move.l    (A2),A0
       move.b    56(A0),D0
       not.b     D0
       and.b     D0,_OSRdyGrp.L
@ucos_ii_OS_FlagBlock_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2
       unlk      A6
       rts
; }
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                  INITIALIZE THE EVENT FLAG MODULE
; *
; * Description: This function is called by uC/OS-II to initialize the event flag module.  Your application
; *              MUST NOT call this function.  In other words, this function is internal to uC/OS-II.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * WARNING    : You MUST NOT call this function from your code.  This is an INTERNAL function to uC/OS-II.
; *********************************************************************************************************
; */
; void  OS_FlagInit (void)
; {
       xdef      _OS_FlagInit
_OS_FlagInit:
       link      A6,#-8
       movem.l   D2/D3/A2,-(A7)
       lea       _OSFlagTbl.L,A2
; #if OS_MAX_FLAGS == 1u
; OSFlagFreeList                 = (OS_FLAG_GRP *)&OSFlagTbl[0];  /* Only ONE event flag group!      */
; OSFlagFreeList->OSFlagType     = OS_EVENT_TYPE_UNUSED;
; OSFlagFreeList->OSFlagWaitList = (void *)0;
; OSFlagFreeList->OSFlagFlags    = (OS_FLAGS)0;
; #if OS_FLAG_NAME_EN > 0u
; OSFlagFreeList->OSFlagName     = (INT8U *)"?";
; #endif
; #endif
; #if OS_MAX_FLAGS >= 2u
; INT16U        ix;
; INT16U        ix_next;
; OS_FLAG_GRP  *pgrp1;
; OS_FLAG_GRP  *pgrp2;
; OS_MemClr((INT8U *)&OSFlagTbl[0], sizeof(OSFlagTbl));           /* Clear the flag group table      */
       pea       60
       move.l    A2,-(A7)
       jsr       _OS_MemClr
       addq.w    #8,A7
; for (ix = 0u; ix < (OS_MAX_FLAGS - 1u); ix++) {                 /* Init. list of free EVENT FLAGS  */
       clr.w     D3
OS_FlagInit_1:
       cmp.w     #4,D3
       bhs       OS_FlagInit_3
; ix_next = ix + 1u;
       move.w    D3,D0
       addq.w    #1,D0
       move.w    D0,-6(A6)
; pgrp1 = &OSFlagTbl[ix];
       move.l    A2,D0
       and.l     #65535,D3
       move.l    D3,D1
       muls      #12,D1
       add.l     D1,D0
       move.l    D0,D2
; pgrp2 = &OSFlagTbl[ix_next];
       move.l    A2,D0
       move.w    -6(A6),D1
       and.l     #65535,D1
       muls      #12,D1
       add.l     D1,D0
       move.l    D0,-4(A6)
; pgrp1->OSFlagType     = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pgrp1->OSFlagWaitList = (void *)pgrp2;
       move.l    D2,A0
       move.l    -4(A6),2(A0)
; #if OS_FLAG_NAME_EN > 0u
; pgrp1->OSFlagName     = (INT8U *)(void *)"?";               /* Unknown name                    */
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,8(A1)
       addq.w    #1,D3
       bra       OS_FlagInit_1
OS_FlagInit_3:
; #endif
; }
; pgrp1                 = &OSFlagTbl[ix];
       move.l    A2,D0
       and.l     #65535,D3
       move.l    D3,D1
       muls      #12,D1
       add.l     D1,D0
       move.l    D0,D2
; pgrp1->OSFlagType     = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pgrp1->OSFlagWaitList = (void *)0;
       move.l    D2,A0
       clr.l     2(A0)
; #if OS_FLAG_NAME_EN > 0u
; pgrp1->OSFlagName     = (INT8U *)(void *)"?";                   /* Unknown name                    */
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,8(A1)
; #endif
; OSFlagFreeList        = &OSFlagTbl[0];
       move.l    A2,_OSFlagFreeList.L
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; #endif
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                              MAKE TASK READY-TO-RUN, EVENT(s) OCCURRED
; *
; * Description: This function is internal to uC/OS-II and is used to make a task ready-to-run because the
; *              desired event flag bits have been set.
; *
; * Arguments  : pnode         is a pointer to a structure which contains data about the task waiting for
; *                            event flag bit(s) to be set.
; *
; *              flags_rdy     contains the bit pattern of the event flags that cause the task to become
; *                            ready-to-run.
; *
; *              pend_stat   is used to indicate the readied task's pending status:
; *
; *
; * Returns    : OS_TRUE       If the task has been placed in the ready list and thus needs scheduling
; *              OS_FALSE      The task is still not ready to run and thus scheduling is not necessary
; *
; * Called by  : OSFlagsPost() OS_FLAG.C
; *
; * Note(s)    : 1) This function assumes that interrupts are disabled.
; *              2) This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; static  BOOLEAN  OS_FlagTaskRdy (OS_FLAG_NODE *pnode,
; OS_FLAGS      flags_rdy,
; INT8U         pend_stat)
; {
@ucos_ii_OS_FlagTaskRdy:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; OS_TCB   *ptcb;
; BOOLEAN   sched;
; ptcb                 = (OS_TCB *)pnode->OSFlagNodeTCB; /* Point to TCB of waiting task             */
       move.l    8(A6),A0
       move.l    8(A0),D2
; ptcb->OSTCBDly       = 0u;
       move.l    D2,A0
       clr.l     46(A0)
; ptcb->OSTCBFlagsRdy  = flags_rdy;
       move.l    D2,A0
       move.w    14(A6),44(A0)
; ptcb->OSTCBStat     &= (INT8U)~(INT8U)OS_STAT_FLAG;
       move.l    D2,A0
       moveq     #32,D0
       not.b     D0
       and.b     D0,50(A0)
; ptcb->OSTCBStatPend  = pend_stat;
       move.l    D2,A0
       move.b    19(A6),51(A0)
; if (ptcb->OSTCBStat == OS_STAT_RDY) {                  /* Task now ready?                          */
       move.l    D2,A0
       move.b    50(A0),D0
       bne.s     @ucos_ii_OS_FlagTaskRdy_1
; OSRdyGrp               |= ptcb->OSTCBBitY;         /* Put task into ready list                 */
       move.l    D2,A0
       move.b    56(A0),D0
       or.b      D0,_OSRdyGrp.L
; OSRdyTbl[ptcb->OSTCBY] |= ptcb->OSTCBBitX;
       move.l    D2,A0
       move.b    54(A0),D0
       and.l     #255,D0
       lea       _OSRdyTbl.L,A0
       move.l    D2,A1
       move.b    55(A1),D1
       or.b      D1,0(A0,D0.L)
; sched                   = OS_TRUE;
       moveq     #1,D3
       bra.s     @ucos_ii_OS_FlagTaskRdy_2
@ucos_ii_OS_FlagTaskRdy_1:
; } else {
; sched                   = OS_FALSE;
       clr.b     D3
@ucos_ii_OS_FlagTaskRdy_2:
; }
; OS_FlagUnlink(pnode);
       move.l    8(A6),-(A7)
       jsr       _OS_FlagUnlink
       addq.w    #4,A7
; return (sched);
       move.b    D3,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                              UNLINK EVENT FLAG NODE FROM WAITING LIST
; *
; * Description: This function is internal to uC/OS-II and is used to unlink an event flag node from a
; *              list of tasks waiting for the event flag.
; *
; * Arguments  : pnode         is a pointer to a structure which contains data about the task waiting for
; *                            event flag bit(s) to be set.
; *
; * Returns    : none
; *
; * Called by  : OS_FlagTaskRdy() OS_FLAG.C
; *              OSFlagPend()     OS_FLAG.C
; *              OSTaskDel()      OS_TASK.C
; *
; * Note(s)    : 1) This function assumes that interrupts are disabled.
; *              2) This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; void  OS_FlagUnlink (OS_FLAG_NODE *pnode)
; {
       xdef      _OS_FlagUnlink
_OS_FlagUnlink:
       link      A6,#-8
       movem.l   D2/D3/D4,-(A7)
       move.l    8(A6),D3
; #if OS_TASK_DEL_EN > 0u
; OS_TCB       *ptcb;
; #endif
; OS_FLAG_GRP  *pgrp;
; OS_FLAG_NODE *pnode_prev;
; OS_FLAG_NODE *pnode_next;
; pnode_prev = (OS_FLAG_NODE *)pnode->OSFlagNodePrev;
       move.l    D3,A0
       move.l    4(A0),D4
; pnode_next = (OS_FLAG_NODE *)pnode->OSFlagNodeNext;
       move.l    D3,A0
       move.l    (A0),D2
; if (pnode_prev == (OS_FLAG_NODE *)0) {                      /* Is it first node in wait list?      */
       tst.l     D4
       bne.s     OS_FlagUnlink_1
; pgrp                 = (OS_FLAG_GRP *)pnode->OSFlagNodeFlagGrp;
       move.l    D3,A0
       move.l    12(A0),-4(A6)
; pgrp->OSFlagWaitList = (void *)pnode_next;              /*      Update list for new 1st node   */
       move.l    -4(A6),A0
       move.l    D2,2(A0)
; if (pnode_next != (OS_FLAG_NODE *)0) {
       tst.l     D2
       beq.s     OS_FlagUnlink_3
; pnode_next->OSFlagNodePrev = (OS_FLAG_NODE *)0;     /*      Link new 1st node PREV to NULL */
       move.l    D2,A0
       clr.l     4(A0)
OS_FlagUnlink_3:
       bra.s     OS_FlagUnlink_5
OS_FlagUnlink_1:
; }
; } else {                                                    /* No,  A node somewhere in the list   */
; pnode_prev->OSFlagNodeNext = pnode_next;                /*      Link around the node to unlink */
       move.l    D4,A0
       move.l    D2,(A0)
; if (pnode_next != (OS_FLAG_NODE *)0) {                  /*      Was this the LAST node?        */
       tst.l     D2
       beq.s     OS_FlagUnlink_5
; pnode_next->OSFlagNodePrev = pnode_prev;            /*      No, Link around current node   */
       move.l    D2,A0
       move.l    D4,4(A0)
OS_FlagUnlink_5:
; }
; }
; #if OS_TASK_DEL_EN > 0u
; ptcb                = (OS_TCB *)pnode->OSFlagNodeTCB;
       move.l    D3,A0
       move.l    8(A0),-8(A6)
; ptcb->OSTCBFlagNode = (OS_FLAG_NODE *)0;
       move.l    -8(A6),A0
       clr.l     40(A0)
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                       MESSAGE MAILBOX MANAGEMENT
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : OS_MBOX.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #include <ucos_ii.h>
; #endif
; #if OS_MBOX_EN > 0u
; /*
; *********************************************************************************************************
; *                                        ACCEPT MESSAGE FROM MAILBOX
; *
; * Description: This function checks the mailbox to see if a message is available.  Unlike OSMboxPend(),
; *              OSMboxAccept() does not suspend the calling task if a message is not available.
; *
; * Arguments  : pevent        is a pointer to the event control block
; *
; * Returns    : != (void *)0  is the message in the mailbox if one is available.  The mailbox is cleared
; *                            so the next time OSMboxAccept() is called, the mailbox will be empty.
; *              == (void *)0  if the mailbox is empty or,
; *                            if 'pevent' is a NULL pointer or,
; *                            if you didn't pass the proper event pointer.
; *********************************************************************************************************
; */
; #if OS_MBOX_ACCEPT_EN > 0u
; void  *OSMboxAccept (OS_EVENT *pevent)
; {
       xdef      _OSMboxAccept
_OSMboxAccept:
       link      A6,#-4
       move.l    D2,-(A7)
       move.l    8(A6),D2
; void      *pmsg;
; #if OS_CRITICAL_METHOD == 3u                              /* Allocate storage for CPU status register  */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                        /* Validate 'pevent'                         */
; return ((void *)0);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MBOX) {      /* Validate event block type                 */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     OSMboxAccept_1
; return ((void *)0);
       clr.l     D0
       bra.s     OSMboxAccept_3
OSMboxAccept_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pmsg               = pevent->OSEventPtr;
       move.l    D2,A0
       move.l    2(A0),-4(A6)
; pevent->OSEventPtr = (void *)0;                       /* Clear the mailbox                         */
       move.l    D2,A0
       clr.l     2(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (pmsg);                                        /* Return the message received (or NULL)     */
       move.l    -4(A6),D0
OSMboxAccept_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                          CREATE A MESSAGE MAILBOX
; *
; * Description: This function creates a message mailbox if free event control blocks are available.
; *
; * Arguments  : pmsg          is a pointer to a message that you wish to deposit in the mailbox.  If
; *                            you set this value to the NULL pointer (i.e. (void *)0) then the mailbox
; *                            will be considered empty.
; *
; * Returns    : != (OS_EVENT *)0  is a pointer to the event control clock (OS_EVENT) associated with the
; *                                created mailbox
; *              == (OS_EVENT *)0  if no event control blocks were available
; *********************************************************************************************************
; */
; OS_EVENT  *OSMboxCreate (void *pmsg)
; {
       xdef      _OSMboxCreate
_OSMboxCreate:
       link      A6,#0
       movem.l   D2/A2,-(A7)
       lea       _OSEventFreeList.L,A2
; OS_EVENT  *pevent;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; if (OSSafetyCriticalStartFlag == OS_TRUE) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_EVENT *)0);
; }
; #endif
; if (OSIntNesting > 0u) {                     /* See if called from ISR ...                         */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMboxCreate_1
; return ((OS_EVENT *)0);                  /* ... can't CREATE from an ISR                       */
       clr.l     D0
       bra       OSMboxCreate_3
OSMboxCreate_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pevent = OSEventFreeList;                    /* Get next free event control block                  */
       move.l    (A2),D2
; if (OSEventFreeList != (OS_EVENT *)0) {      /* See if pool of free ECB pool was empty             */
       move.l    (A2),D0
       beq.s     OSMboxCreate_4
; OSEventFreeList = (OS_EVENT *)OSEventFreeList->OSEventPtr;
       move.l    (A2),A0
       move.l    2(A0),(A2)
OSMboxCreate_4:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (pevent != (OS_EVENT *)0) {
       tst.l     D2
       beq.s     OSMboxCreate_6
; pevent->OSEventType    = OS_EVENT_TYPE_MBOX;
       move.l    D2,A0
       move.b    #1,(A0)
; pevent->OSEventCnt     = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; pevent->OSEventPtr     = pmsg;           /* Deposit message in event control block             */
       move.l    D2,A0
       move.l    8(A6),2(A0)
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; OS_EventWaitListInit(pevent);
       move.l    D2,-(A7)
       jsr       _OS_EventWaitListInit
       addq.w    #4,A7
OSMboxCreate_6:
; }
; return (pevent);                             /* Return pointer to event control block              */
       move.l    D2,D0
OSMboxCreate_3:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           DELETE A MAIBOX
; *
; * Description: This function deletes a mailbox and readies all tasks pending on the mailbox.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired
; *                            mailbox.
; *
; *              opt           determines delete options as follows:
; *                            opt == OS_DEL_NO_PEND   Delete the mailbox ONLY if no task pending
; *                            opt == OS_DEL_ALWAYS    Deletes the mailbox even if tasks are waiting.
; *                                                    In this case, all the tasks pending will be readied.
; *
; *              perr          is a pointer to an error code that can contain one of the following values:
; *                            OS_ERR_NONE             The call was successful and the mailbox was deleted
; *                            OS_ERR_DEL_ISR          If you attempted to delete the mailbox from an ISR
; *                            OS_ERR_INVALID_OPT      An invalid option was specified
; *                            OS_ERR_TASK_WAITING     One or more tasks were waiting on the mailbox
; *                            OS_ERR_EVENT_TYPE       If you didn't pass a pointer to a mailbox
; *                            OS_ERR_PEVENT_NULL      If 'pevent' is a NULL pointer.
; *
; * Returns    : pevent        upon error
; *              (OS_EVENT *)0 if the mailbox was successfully deleted.
; *
; * Note(s)    : 1) This function must be used with care.  Tasks that would normally expect the presence of
; *                 the mailbox MUST check the return code of OSMboxPend().
; *              2) OSMboxAccept() callers will not know that the intended mailbox has been deleted!
; *              3) This call can potentially disable interrupts for a long time.  The interrupt disable
; *                 time is directly proportional to the number of tasks waiting on the mailbox.
; *              4) Because ALL tasks pending on the mailbox will be readied, you MUST be careful in
; *                 applications where the mailbox is used for mutual exclusion because the resource(s)
; *                 will no longer be guarded by the mailbox.
; *              5) All tasks that were waiting for the mailbox will be readied and returned an 
; *                 OS_ERR_PEND_ABORT if OSMboxDel() was called with OS_DEL_ALWAYS
; *********************************************************************************************************
; */
; #if OS_MBOX_DEL_EN > 0u
; OS_EVENT  *OSMboxDel (OS_EVENT  *pevent,
; INT8U      opt,
; INT8U     *perr)
; {
       xdef      _OSMboxDel
_OSMboxDel:
       link      A6,#0
       movem.l   D2/D3/D4/D5/A2,-(A7)
       move.l    8(A6),D2
       move.l    16(A6),D3
       lea       _OSEventFreeList.L,A2
; BOOLEAN    tasks_waiting;
; OS_EVENT  *pevent_return;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_EVENT *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; *perr = OS_ERR_PEVENT_NULL;
; return (pevent);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MBOX) {       /* Validate event block type                */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     OSMboxDel_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D3,A0
       move.b    #1,(A0)
; return (pevent);
       move.l    D2,D0
       bra       OSMboxDel_3
OSMboxDel_1:
; }
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMboxDel_4
; *perr = OS_ERR_DEL_ISR;                            /* ... can't DELETE from an ISR             */
       move.l    D3,A0
       move.b    #15,(A0)
; return (pevent);
       move.l    D2,D0
       bra       OSMboxDel_3
OSMboxDel_4:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                        /* See if any tasks waiting on mailbox      */
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSMboxDel_6
; tasks_waiting = OS_TRUE;                           /* Yes                                      */
       moveq     #1,D5
       bra.s     OSMboxDel_7
OSMboxDel_6:
; } else {
; tasks_waiting = OS_FALSE;                          /* No                                       */
       clr.b     D5
OSMboxDel_7:
; }
; switch (opt) {
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq       OSMboxDel_11
       bhi       OSMboxDel_8
       tst.l     D0
       beq.s     OSMboxDel_10
       bra       OSMboxDel_8
OSMboxDel_10:
; case OS_DEL_NO_PEND:                               /* Delete mailbox only if no task waiting   */
; if (tasks_waiting == OS_FALSE) {
       tst.b     D5
       bne.s     OSMboxDel_13
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; pevent->OSEventType = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent->OSEventPtr  = OSEventFreeList;    /* Return Event Control Block to free list  */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pevent->OSEventCnt  = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; OSEventFreeList     = pevent;             /* Get next free event control block        */
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr               = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; pevent_return       = (OS_EVENT *)0;      /* Mailbox has been deleted                 */
       clr.l     D4
       bra.s     OSMboxDel_14
OSMboxDel_13:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr               = OS_ERR_TASK_WAITING;
       move.l    D3,A0
       move.b    #73,(A0)
; pevent_return       = pevent;
       move.l    D2,D4
OSMboxDel_14:
; }
; break;
       bra       OSMboxDel_9
OSMboxDel_11:
; case OS_DEL_ALWAYS:                                /* Always delete the mailbox                */
; while (pevent->OSEventGrp != 0u) {            /* Ready ALL tasks waiting for mailbox      */
OSMboxDel_15:
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSMboxDel_17
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_MBOX, OS_STAT_PEND_ABORT);
       pea       2
       pea       2
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
       bra       OSMboxDel_15
OSMboxDel_17:
; }
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; pevent->OSEventType    = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent->OSEventPtr     = OSEventFreeList;     /* Return Event Control Block to free list  */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pevent->OSEventCnt     = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; OSEventFreeList        = pevent;              /* Get next free event control block        */
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (tasks_waiting == OS_TRUE) {               /* Reschedule only if task(s) were waiting  */
       cmp.b     #1,D5
       bne.s     OSMboxDel_18
; OS_Sched();                               /* Find highest priority task ready to run  */
       jsr       _OS_Sched
OSMboxDel_18:
; }
; *perr         = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; pevent_return = (OS_EVENT *)0;                /* Mailbox has been deleted                 */
       clr.l     D4
; break;
       bra.s     OSMboxDel_9
OSMboxDel_8:
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr         = OS_ERR_INVALID_OPT;
       move.l    D3,A0
       move.b    #7,(A0)
; pevent_return = pevent;
       move.l    D2,D4
; break;
OSMboxDel_9:
; }
; return (pevent_return);
       move.l    D4,D0
OSMboxDel_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                    PEND ON MAILBOX FOR A MESSAGE
; *
; * Description: This function waits for a message to be sent to a mailbox
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired mailbox
; *
; *              timeout       is an optional timeout period (in clock ticks).  If non-zero, your task will
; *                            wait for a message to arrive at the mailbox up to the amount of time
; *                            specified by this argument.  If you specify 0, however, your task will wait
; *                            forever at the specified mailbox or, until a message arrives.
; *
; *              perr          is a pointer to where an error message will be deposited.  Possible error
; *                            messages are:
; *
; *                            OS_ERR_NONE         The call was successful and your task received a
; *                                                message.
; *                            OS_ERR_TIMEOUT      A message was not received within the specified 'timeout'.
; *                            OS_ERR_PEND_ABORT   The wait on the mailbox was aborted.
; *                            OS_ERR_EVENT_TYPE   Invalid event type
; *                            OS_ERR_PEND_ISR     If you called this function from an ISR and the result
; *                                                would lead to a suspension.
; *                            OS_ERR_PEVENT_NULL  If 'pevent' is a NULL pointer
; *                            OS_ERR_PEND_LOCKED  If you called this function when the scheduler is locked
; *
; * Returns    : != (void *)0  is a pointer to the message received
; *              == (void *)0  if no message was received or,
; *                            if 'pevent' is a NULL pointer or,
; *                            if you didn't pass the proper pointer to the event control block.
; *********************************************************************************************************
; */
; /*$PAGE*/
; void  *OSMboxPend (OS_EVENT  *pevent,
; INT32U     timeout,
; INT8U     *perr)
; {
       xdef      _OSMboxPend
_OSMboxPend:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _OSTCBCur.L,A2
       move.l    16(A6),D3
       move.l    8(A6),D4
; void      *pmsg;
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((void *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; *perr = OS_ERR_PEVENT_NULL;
; return ((void *)0);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MBOX) {  /* Validate event block type                     */
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     OSMboxPend_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D3,A0
       move.b    #1,(A0)
; return ((void *)0);
       clr.l     D0
       bra       OSMboxPend_3
OSMboxPend_1:
; }
; if (OSIntNesting > 0u) {                          /* See if called from ISR ...                    */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMboxPend_4
; *perr = OS_ERR_PEND_ISR;                      /* ... can't PEND from an ISR                    */
       move.l    D3,A0
       move.b    #2,(A0)
; return ((void *)0);
       clr.l     D0
       bra       OSMboxPend_3
OSMboxPend_4:
; }
; if (OSLockNesting > 0u) {                         /* See if called with scheduler locked ...       */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMboxPend_6
; *perr = OS_ERR_PEND_LOCKED;                   /* ... can't PEND when locked                    */
       move.l    D3,A0
       move.b    #13,(A0)
; return ((void *)0);
       clr.l     D0
       bra       OSMboxPend_3
OSMboxPend_6:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pmsg = pevent->OSEventPtr;
       move.l    D4,A0
       move.l    2(A0),D2
; if (pmsg != (void *)0) {                          /* See if there is already a message             */
       tst.l     D2
       beq.s     OSMboxPend_8
; pevent->OSEventPtr = (void *)0;               /* Clear the mailbox                             */
       move.l    D4,A0
       clr.l     2(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; return (pmsg);                                /* Return the message received (or NULL)         */
       move.l    D2,D0
       bra       OSMboxPend_3
OSMboxPend_8:
; }
; OSTCBCur->OSTCBStat     |= OS_STAT_MBOX;          /* Message not available, task will pend         */
       move.l    (A2),A0
       or.b      #2,50(A0)
; OSTCBCur->OSTCBStatPend  = OS_STAT_PEND_OK;
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBDly       = timeout;               /* Load timeout in TCB                           */
       move.l    (A2),A0
       move.l    12(A6),46(A0)
; OS_EventTaskWait(pevent);                         /* Suspend task until event or timeout occurs    */
       move.l    D4,-(A7)
       jsr       _OS_EventTaskWait
       addq.w    #4,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                       /* Find next highest priority task ready to run  */
       jsr       _OS_Sched
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; switch (OSTCBCur->OSTCBStatPend) {                /* See if we timed-out or aborted                */
       move.l    (A2),A0
       move.b    51(A0),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq       OSMboxPend_14
       bhi.s     OSMboxPend_16
       tst.l     D0
       beq.s     OSMboxPend_12
       bra.s     OSMboxPend_14
OSMboxPend_16:
       cmp.l     #2,D0
       beq.s     OSMboxPend_13
       bra.s     OSMboxPend_14
OSMboxPend_12:
; case OS_STAT_PEND_OK:
; pmsg =  OSTCBCur->OSTCBMsg;
       move.l    (A2),A0
       move.l    36(A0),D2
; *perr =  OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; break;
       bra.s     OSMboxPend_11
OSMboxPend_13:
; case OS_STAT_PEND_ABORT:
; pmsg = (void *)0;
       clr.l     D2
; *perr =  OS_ERR_PEND_ABORT;               /* Indicate that we aborted                      */
       move.l    D3,A0
       move.b    #14,(A0)
; break;
       bra.s     OSMboxPend_11
OSMboxPend_14:
; case OS_STAT_PEND_TO:
; default:
; OS_EventTaskRemove(OSTCBCur, pevent);
       move.l    D4,-(A7)
       move.l    (A2),-(A7)
       jsr       _OS_EventTaskRemove
       addq.w    #8,A7
; pmsg = (void *)0;
       clr.l     D2
; *perr =  OS_ERR_TIMEOUT;                  /* Indicate that we didn't get event within TO   */
       move.l    D3,A0
       move.b    #10,(A0)
; break;
OSMboxPend_11:
; }
; OSTCBCur->OSTCBStat          =  OS_STAT_RDY;      /* Set   task  status to ready                   */
       move.l    (A2),A0
       clr.b     50(A0)
; OSTCBCur->OSTCBStatPend      =  OS_STAT_PEND_OK;  /* Clear pend  status                            */
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBEventPtr      = (OS_EVENT  *)0;    /* Clear event pointers                          */
       move.l    (A2),A0
       clr.l     28(A0)
; #if (OS_EVENT_MULTI_EN > 0u)
; OSTCBCur->OSTCBEventMultiPtr = (OS_EVENT **)0;
       move.l    (A2),A0
       clr.l     32(A0)
; #endif
; OSTCBCur->OSTCBMsg           = (void      *)0;    /* Clear  received message                       */
       move.l    (A2),A0
       clr.l     36(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (pmsg);                                    /* Return received message                       */
       move.l    D2,D0
OSMboxPend_3:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                     ABORT WAITING ON A MESSAGE MAILBOX
; *
; * Description: This function aborts & readies any tasks currently waiting on a mailbox.  This function
; *              should be used to fault-abort the wait on the mailbox, rather than to normally signal
; *              the mailbox via OSMboxPost() or OSMboxPostOpt().
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired mailbox.
; *
; *              opt           determines the type of ABORT performed:
; *                            OS_PEND_OPT_NONE         ABORT wait for a single task (HPT) waiting on the
; *                                                     mailbox
; *                            OS_PEND_OPT_BROADCAST    ABORT wait for ALL tasks that are  waiting on the
; *                                                     mailbox
; *
; *              perr          is a pointer to where an error message will be deposited.  Possible error
; *                            messages are:
; *
; *                            OS_ERR_NONE         No tasks were     waiting on the mailbox.
; *                            OS_ERR_PEND_ABORT   At least one task waiting on the mailbox was readied
; *                                                and informed of the aborted wait; check return value
; *                                                for the number of tasks whose wait on the mailbox
; *                                                was aborted.
; *                            OS_ERR_EVENT_TYPE   If you didn't pass a pointer to a mailbox.
; *                            OS_ERR_PEVENT_NULL  If 'pevent' is a NULL pointer.
; *
; * Returns    : == 0          if no tasks were waiting on the mailbox, or upon error.
; *              >  0          if one or more tasks waiting on the mailbox are now readied and informed.
; *********************************************************************************************************
; */
; #if OS_MBOX_PEND_ABORT_EN > 0u
; INT8U  OSMboxPendAbort (OS_EVENT  *pevent,
; INT8U      opt,
; INT8U     *perr)
; {
       xdef      _OSMboxPendAbort
_OSMboxPendAbort:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
       move.l    8(A6),D2
       move.l    16(A6),D4
; INT8U      nbr_tasks;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; *perr = OS_ERR_PEVENT_NULL;
; return (0u);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MBOX) {       /* Validate event block type                */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     OSMboxPendAbort_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return (0u);
       clr.b     D0
       bra       OSMboxPendAbort_3
OSMboxPendAbort_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                        /* See if any task waiting on mailbox?      */
       move.l    D2,A0
       move.b    8(A0),D0
       beq       OSMboxPendAbort_4
; nbr_tasks = 0u;
       clr.b     D3
; switch (opt) {
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq.s     OSMboxPendAbort_8
       bhi       OSMboxPendAbort_9
       tst.l     D0
       beq.s     OSMboxPendAbort_9
       bra.s     OSMboxPendAbort_9
OSMboxPendAbort_8:
; case OS_PEND_OPT_BROADCAST:                    /* Do we need to abort ALL waiting tasks?   */
; while (pevent->OSEventGrp != 0u) {        /* Yes, ready ALL tasks waiting on mailbox  */
OSMboxPendAbort_11:
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSMboxPendAbort_13
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_MBOX, OS_STAT_PEND_ABORT);
       pea       2
       pea       2
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; nbr_tasks++;
       addq.b    #1,D3
       bra       OSMboxPendAbort_11
OSMboxPendAbort_13:
; }
; break;
       bra.s     OSMboxPendAbort_7
OSMboxPendAbort_9:
; case OS_PEND_OPT_NONE:
; default:                                       /* No,  ready HPT       waiting on mailbox  */
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_MBOX, OS_STAT_PEND_ABORT);
       pea       2
       pea       2
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; nbr_tasks++;
       addq.b    #1,D3
; break;
OSMboxPendAbort_7:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                        /* Find HPT ready to run                    */
       jsr       _OS_Sched
; *perr = OS_ERR_PEND_ABORT;
       move.l    D4,A0
       move.b    #14,(A0)
; return (nbr_tasks);
       move.b    D3,D0
       bra.s     OSMboxPendAbort_3
OSMboxPendAbort_4:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; return (0u);                                           /* No tasks waiting on mailbox              */
       clr.b     D0
OSMboxPendAbort_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                      POST MESSAGE TO A MAILBOX
; *
; * Description: This function sends a message to a mailbox
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired mailbox
; *
; *              pmsg          is a pointer to the message to send.  You MUST NOT send a NULL pointer.
; *
; * Returns    : OS_ERR_NONE          The call was successful and the message was sent
; *              OS_ERR_MBOX_FULL     If the mailbox already contains a message.  You can can only send one
; *                                   message at a time and thus, the message MUST be consumed before you
; *                                   are allowed to send another one.
; *              OS_ERR_EVENT_TYPE    If you are attempting to post to a non mailbox.
; *              OS_ERR_PEVENT_NULL   If 'pevent' is a NULL pointer
; *              OS_ERR_POST_NULL_PTR If you are attempting to post a NULL pointer
; *
; * Note(s)    : 1) HPT means Highest Priority Task
; *********************************************************************************************************
; */
; #if OS_MBOX_POST_EN > 0u
; INT8U  OSMboxPost (OS_EVENT  *pevent,
; void      *pmsg)
; {
       xdef      _OSMboxPost
_OSMboxPost:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; return (OS_ERR_PEVENT_NULL);
; }
; if (pmsg == (void *)0) {                          /* Make sure we are not posting a NULL pointer   */
; return (OS_ERR_POST_NULL_PTR);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MBOX) {  /* Validate event block type                     */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     OSMboxPost_1
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSMboxPost_3
OSMboxPost_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                   /* See if any task pending on mailbox            */
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSMboxPost_4
; /* Ready HPT waiting on event                    */
; (void)OS_EventTaskRdy(pevent, pmsg, OS_STAT_MBOX, OS_STAT_PEND_OK);
       clr.l     -(A7)
       pea       2
       move.l    12(A6),-(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                   /* Find highest priority task ready to run       */
       jsr       _OS_Sched
; return (OS_ERR_NONE);
       clr.b     D0
       bra.s     OSMboxPost_3
OSMboxPost_4:
; }
; if (pevent->OSEventPtr != (void *)0) {            /* Make sure mailbox doesn't already have a msg  */
       move.l    D2,A0
       move.l    2(A0),D0
       beq.s     OSMboxPost_6
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_MBOX_FULL);
       moveq     #20,D0
       bra.s     OSMboxPost_3
OSMboxPost_6:
; }
; pevent->OSEventPtr = pmsg;                        /* Place message in mailbox                      */
       move.l    D2,A0
       move.l    12(A6),2(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSMboxPost_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                      POST MESSAGE TO A MAILBOX
; *
; * Description: This function sends a message to a mailbox
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired mailbox
; *
; *              pmsg          is a pointer to the message to send.  You MUST NOT send a NULL pointer.
; *
; *              opt           determines the type of POST performed:
; *                            OS_POST_OPT_NONE         POST to a single waiting task
; *                                                     (Identical to OSMboxPost())
; *                            OS_POST_OPT_BROADCAST    POST to ALL tasks that are waiting on the mailbox
; *
; *                            OS_POST_OPT_NO_SCHED     Indicates that the scheduler will NOT be invoked
; *
; * Returns    : OS_ERR_NONE          The call was successful and the message was sent
; *              OS_ERR_MBOX_FULL     If the mailbox already contains a message.  You can can only send one
; *                                   message at a time and thus, the message MUST be consumed before you
; *                                   are allowed to send another one.
; *              OS_ERR_EVENT_TYPE    If you are attempting to post to a non mailbox.
; *              OS_ERR_PEVENT_NULL   If 'pevent' is a NULL pointer
; *              OS_ERR_POST_NULL_PTR If you are attempting to post a NULL pointer
; *
; * Note(s)    : 1) HPT means Highest Priority Task
; *
; * Warning    : Interrupts can be disabled for a long time if you do a 'broadcast'.  In fact, the
; *              interrupt disable time is proportional to the number of tasks waiting on the mailbox.
; *********************************************************************************************************
; */
; #if OS_MBOX_POST_OPT_EN > 0u
; INT8U  OSMboxPostOpt (OS_EVENT  *pevent,
; void      *pmsg,
; INT8U      opt)
; {
       xdef      _OSMboxPostOpt
_OSMboxPostOpt:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    8(A6),D2
       move.l    12(A6),D3
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; return (OS_ERR_PEVENT_NULL);
; }
; if (pmsg == (void *)0) {                          /* Make sure we are not posting a NULL pointer   */
; return (OS_ERR_POST_NULL_PTR);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MBOX) {  /* Validate event block type                     */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     OSMboxPostOpt_1
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSMboxPostOpt_3
OSMboxPostOpt_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                   /* See if any task pending on mailbox            */
       move.l    D2,A0
       move.b    8(A0),D0
       beq       OSMboxPostOpt_4
; if ((opt & OS_POST_OPT_BROADCAST) != 0x00u) { /* Do we need to post msg to ALL waiting tasks ? */
       move.b    19(A6),D0
       and.b     #1,D0
       beq.s     OSMboxPostOpt_6
; while (pevent->OSEventGrp != 0u) {        /* Yes, Post to ALL tasks waiting on mailbox     */
OSMboxPostOpt_8:
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSMboxPostOpt_10
; (void)OS_EventTaskRdy(pevent, pmsg, OS_STAT_MBOX, OS_STAT_PEND_OK);
       clr.l     -(A7)
       pea       2
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
       bra       OSMboxPostOpt_8
OSMboxPostOpt_10:
       bra.s     OSMboxPostOpt_7
OSMboxPostOpt_6:
; }
; } else {                                      /* No,  Post to HPT waiting on mbox              */
; (void)OS_EventTaskRdy(pevent, pmsg, OS_STAT_MBOX, OS_STAT_PEND_OK);
       clr.l     -(A7)
       pea       2
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
OSMboxPostOpt_7:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; if ((opt & OS_POST_OPT_NO_SCHED) == 0u) {     /* See if scheduler needs to be invoked          */
       move.b    19(A6),D0
       and.b     #4,D0
       bne.s     OSMboxPostOpt_11
; OS_Sched();                               /* Find HPT ready to run                         */
       jsr       _OS_Sched
OSMboxPostOpt_11:
; }
; return (OS_ERR_NONE);
       clr.b     D0
       bra.s     OSMboxPostOpt_3
OSMboxPostOpt_4:
; }
; if (pevent->OSEventPtr != (void *)0) {            /* Make sure mailbox doesn't already have a msg  */
       move.l    D2,A0
       move.l    2(A0),D0
       beq.s     OSMboxPostOpt_13
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_MBOX_FULL);
       moveq     #20,D0
       bra.s     OSMboxPostOpt_3
OSMboxPostOpt_13:
; }
; pevent->OSEventPtr = pmsg;                        /* Place message in mailbox                      */
       move.l    D2,A0
       move.l    D3,2(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSMboxPostOpt_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       QUERY A MESSAGE MAILBOX
; *
; * Description: This function obtains information about a message mailbox.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired mailbox
; *
; *              p_mbox_data   is a pointer to a structure that will contain information about the message
; *                            mailbox.
; *
; * Returns    : OS_ERR_NONE         The call was successful and the message was sent
; *              OS_ERR_EVENT_TYPE   If you are attempting to obtain data from a non mailbox.
; *              OS_ERR_PEVENT_NULL  If 'pevent'      is a NULL pointer
; *              OS_ERR_PDATA_NULL   If 'p_mbox_data' is a NULL pointer
; *********************************************************************************************************
; */
; #if OS_MBOX_QUERY_EN > 0u
; INT8U  OSMboxQuery (OS_EVENT      *pevent,
; OS_MBOX_DATA  *p_mbox_data)
; {
       xdef      _OSMboxQuery
_OSMboxQuery:
       link      A6,#-8
       movem.l   D2/D3/D4,-(A7)
       move.l    8(A6),D2
       move.l    12(A6),D4
; INT8U       i;
; OS_PRIO    *psrc;
; OS_PRIO    *pdest;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR   cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; return (OS_ERR_PEVENT_NULL);
; }
; if (p_mbox_data == (OS_MBOX_DATA *)0) {                /* Validate 'p_mbox_data'                   */
; return (OS_ERR_PDATA_NULL);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MBOX) {       /* Validate event block type                */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #1,D0
       beq.s     OSMboxQuery_1
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSMboxQuery_3
OSMboxQuery_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; p_mbox_data->OSEventGrp = pevent->OSEventGrp;          /* Copy message mailbox wait list           */
       move.l    D2,A0
       move.l    D4,A1
       move.b    8(A0),12(A1)
; psrc                    = &pevent->OSEventTbl[0];
       moveq     #10,D0
       add.l     D2,D0
       move.l    D0,-8(A6)
; pdest                   = &p_mbox_data->OSEventTbl[0];
       moveq     #4,D0
       add.l     D4,D0
       move.l    D0,-4(A6)
; for (i = 0u; i < OS_EVENT_TBL_SIZE; i++) {
       clr.b     D3
OSMboxQuery_4:
       cmp.b     #8,D3
       bhs.s     OSMboxQuery_6
; *pdest++ = *psrc++;
       move.l    -8(A6),A0
       addq.l    #1,-8(A6)
       move.l    -4(A6),A1
       addq.l    #1,-4(A6)
       move.b    (A0),(A1)
       addq.b    #1,D3
       bra       OSMboxQuery_4
OSMboxQuery_6:
; }
; p_mbox_data->OSMsg = pevent->OSEventPtr;               /* Get message from mailbox                 */
       move.l    D2,A0
       move.l    D4,A1
       move.l    2(A0),(A1)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSMboxQuery_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                            MEMORY MANAGEMENT
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : OS_MEM.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #include <ucos_ii.h>
; #endif
; #if (OS_MEM_EN > 0u) && (OS_MAX_MEM_PART > 0u)
; /*
; *********************************************************************************************************
; *                                      CREATE A MEMORY PARTITION
; *
; * Description : Create a fixed-sized memory partition that will be managed by uC/OS-II.
; *
; * Arguments   : addr     is the starting address of the memory partition
; *
; *               nblks    is the number of memory blocks to create from the partition.
; *
; *               blksize  is the size (in bytes) of each block in the memory partition.
; *
; *               perr     is a pointer to a variable containing an error message which will be set by
; *                        this function to either:
; *
; *                        OS_ERR_NONE              if the memory partition has been created correctly.
; *                        OS_ERR_MEM_INVALID_ADDR  if you are specifying an invalid address for the memory
; *                                                 storage of the partition or, the block does not align
; *                                                 on a pointer boundary
; *                        OS_ERR_MEM_INVALID_PART  no free partitions available
; *                        OS_ERR_MEM_INVALID_BLKS  user specified an invalid number of blocks (must be >= 2)
; *                        OS_ERR_MEM_INVALID_SIZE  user specified an invalid block size
; *                                                   - must be greater than the size of a pointer
; *                                                   - must be able to hold an integral number of pointers
; * Returns    : != (OS_MEM *)0  is the partition was created
; *              == (OS_MEM *)0  if the partition was not created because of invalid arguments or, no
; *                              free partition is available.
; *********************************************************************************************************
; */
; OS_MEM  *OSMemCreate (void   *addr,
; INT32U  nblks,
; INT32U  blksize,
; INT8U  *perr)
; {
       xdef      _OSMemCreate
_OSMemCreate:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/D7/A2,-(A7)
       move.l    8(A6),D4
       lea       _OSMemFreeList.L,A2
       move.l    12(A6),D7
; OS_MEM    *pmem;
; INT8U     *pblk;
; void     **plink;
; INT32U     loops;
; INT32U     i;
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_MEM *)0);
; }
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; if (OSSafetyCriticalStartFlag == OS_TRUE) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_MEM *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (addr == (void *)0) {                          /* Must pass a valid address for the memory part.*/
; *perr = OS_ERR_MEM_INVALID_ADDR;
; return ((OS_MEM *)0);
; }
; if (((INT32U)addr & (sizeof(void *) - 1u)) != 0u){  /* Must be pointer size aligned                */
; *perr = OS_ERR_MEM_INVALID_ADDR;
; return ((OS_MEM *)0);
; }
; if (nblks < 2u) {                                 /* Must have at least 2 blocks per partition     */
; *perr = OS_ERR_MEM_INVALID_BLKS;
; return ((OS_MEM *)0);
; }
; if (blksize < sizeof(void *)) {                   /* Must contain space for at least a pointer     */
; *perr = OS_ERR_MEM_INVALID_SIZE;
; return ((OS_MEM *)0);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pmem = OSMemFreeList;                             /* Get next free memory partition                */
       move.l    (A2),D2
; if (OSMemFreeList != (OS_MEM *)0) {               /* See if pool of free partitions was empty      */
       move.l    (A2),D0
       beq.s     OSMemCreate_1
; OSMemFreeList = (OS_MEM *)OSMemFreeList->OSMemFreeList;
       move.l    (A2),A0
       move.l    4(A0),(A2)
OSMemCreate_1:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (pmem == (OS_MEM *)0) {                        /* See if we have a memory partition             */
       tst.l     D2
       bne.s     OSMemCreate_3
; *perr = OS_ERR_MEM_INVALID_PART;
       move.l    20(A6),A0
       move.b    #90,(A0)
; return ((OS_MEM *)0);
       clr.l     D0
       bra       OSMemCreate_5
OSMemCreate_3:
; }
; plink = (void **)addr;                            /* Create linked list of free memory blocks      */
       move.l    D4,D5
; pblk  = (INT8U *)addr;
       move.l    D4,D3
; loops  = nblks - 1u;
       move.l    D7,D0
       subq.l    #1,D0
       move.l    D0,-4(A6)
; for (i = 0u; i < loops; i++) {
       clr.l     D6
OSMemCreate_6:
       cmp.l     -4(A6),D6
       bhs.s     OSMemCreate_8
; pblk +=  blksize;                             /* Point to the FOLLOWING block                  */
       move.l    16(A6),D0
       add.l     D0,D3
; *plink = (void  *)pblk;                        /* Save pointer to NEXT block in CURRENT block   */
       move.l    D5,A0
       move.l    D3,(A0)
; plink = (void **)pblk;                        /* Position to  NEXT      block                  */
       move.l    D3,D5
       addq.l    #1,D6
       bra       OSMemCreate_6
OSMemCreate_8:
; }
; *plink              = (void *)0;                  /* Last memory block points to NULL              */
       move.l    D5,A0
       clr.l     (A0)
; pmem->OSMemAddr     = addr;                       /* Store start address of memory partition       */
       move.l    D2,A0
       move.l    D4,(A0)
; pmem->OSMemFreeList = addr;                       /* Initialize pointer to pool of free blocks     */
       move.l    D2,A0
       move.l    D4,4(A0)
; pmem->OSMemNFree    = nblks;                      /* Store number of free blocks in MCB            */
       move.l    D2,A0
       move.l    D7,16(A0)
; pmem->OSMemNBlks    = nblks;
       move.l    D2,A0
       move.l    D7,12(A0)
; pmem->OSMemBlkSize  = blksize;                    /* Store block size of each memory blocks        */
       move.l    D2,A0
       move.l    16(A6),8(A0)
; *perr               = OS_ERR_NONE;
       move.l    20(A6),A0
       clr.b     (A0)
; return (pmem);
       move.l    D2,D0
OSMemCreate_5:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                         GET A MEMORY BLOCK
; *
; * Description : Get a memory block from a partition
; *
; * Arguments   : pmem    is a pointer to the memory partition control block
; *
; *               perr    is a pointer to a variable containing an error message which will be set by this
; *                       function to either:
; *
; *                       OS_ERR_NONE             if the memory partition has been created correctly.
; *                       OS_ERR_MEM_NO_FREE_BLKS if there are no more free memory blocks to allocate to caller
; *                       OS_ERR_MEM_INVALID_PMEM if you passed a NULL pointer for 'pmem'
; *
; * Returns     : A pointer to a memory block if no error is detected
; *               A pointer to NULL if an error is detected
; *********************************************************************************************************
; */
; void  *OSMemGet (OS_MEM  *pmem,
; INT8U   *perr)
; {
       xdef      _OSMemGet
_OSMemGet:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    8(A6),D2
; void      *pblk;
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((void *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pmem == (OS_MEM *)0) {                        /* Must point to a valid memory partition        */
; *perr = OS_ERR_MEM_INVALID_PMEM;
; return ((void *)0);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pmem->OSMemNFree > 0u) {                      /* See if there are any free memory blocks       */
       move.l    D2,A0
       move.l    16(A0),D0
       cmp.l     #0,D0
       bls.s     OSMemGet_1
; pblk                = pmem->OSMemFreeList;    /* Yes, point to next free memory block          */
       move.l    D2,A0
       move.l    4(A0),D3
; pmem->OSMemFreeList = *(void **)pblk;         /*      Adjust pointer to new free list          */
       move.l    D3,A0
       move.l    D2,A1
       move.l    (A0),4(A1)
; pmem->OSMemNFree--;                           /*      One less memory block in this partition  */
       move.l    D2,D0
       add.l     #16,D0
       move.l    D0,A0
       subq.l    #1,(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;                          /*      No error                                 */
       move.l    12(A6),A0
       clr.b     (A0)
; return (pblk);                                /*      Return memory block to caller            */
       move.l    D3,D0
       bra.s     OSMemGet_3
OSMemGet_1:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_MEM_NO_FREE_BLKS;                  /* No,  Notify caller of empty memory partition  */
       move.l    12(A6),A0
       move.b    #93,(A0)
; return ((void *)0);                               /*      Return NULL pointer to caller            */
       clr.l     D0
OSMemGet_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                 GET THE NAME OF A MEMORY PARTITION
; *
; * Description: This function is used to obtain the name assigned to a memory partition.
; *
; * Arguments  : pmem      is a pointer to the memory partition
; *
; *              pname     is a pointer to a pointer to an ASCII string that will receive the name of the memory partition.
; *
; *              perr      is a pointer to an error code that can contain one of the following values:
; *
; *                        OS_ERR_NONE                if the name was copied to 'pname'
; *                        OS_ERR_MEM_INVALID_PMEM    if you passed a NULL pointer for 'pmem'
; *                        OS_ERR_PNAME_NULL          You passed a NULL pointer for 'pname'
; *                        OS_ERR_NAME_GET_ISR        You called this function from an ISR
; *
; * Returns    : The length of the string or 0 if 'pmem' is a NULL pointer.
; *********************************************************************************************************
; */
; #if OS_MEM_NAME_EN > 0u
; INT8U  OSMemNameGet (OS_MEM   *pmem,
; INT8U   **pname,
; INT8U    *perr)
; {
       xdef      _OSMemNameGet
_OSMemNameGet:
       link      A6,#-4
; INT8U      len;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pmem == (OS_MEM *)0) {                   /* Is 'pmem' a NULL pointer?                          */
; *perr = OS_ERR_MEM_INVALID_PMEM;
; return (0u);
; }
; if (pname == (INT8U **)0) {                  /* Is 'pname' a NULL pointer?                         */
; *perr = OS_ERR_PNAME_NULL;
; return (0u);
; }
; #endif
; if (OSIntNesting > 0u) {                     /* See if trying to call from an ISR                  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMemNameGet_1
; *perr = OS_ERR_NAME_GET_ISR;
       move.l    16(A6),A0
       move.b    #17,(A0)
; return (0u);
       clr.b     D0
       bra.s     OSMemNameGet_3
OSMemNameGet_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; *pname = pmem->OSMemName;
       move.l    8(A6),A0
       move.l    12(A6),A1
       move.l    20(A0),(A1)
; len    = OS_StrLen(*pname);
       move.l    12(A6),A0
       move.l    (A0),-(A7)
       jsr       _OS_StrLen
       addq.w    #4,A7
       move.b    D0,-1(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr  = OS_ERR_NONE;
       move.l    16(A6),A0
       clr.b     (A0)
; return (len);
       move.b    -1(A6),D0
OSMemNameGet_3:
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                 ASSIGN A NAME TO A MEMORY PARTITION
; *
; * Description: This function assigns a name to a memory partition.
; *
; * Arguments  : pmem      is a pointer to the memory partition
; *
; *              pname     is a pointer to an ASCII string that contains the name of the memory partition.
; *
; *              perr      is a pointer to an error code that can contain one of the following values:
; *
; *                        OS_ERR_NONE                if the name was copied to 'pname'
; *                        OS_ERR_MEM_INVALID_PMEM    if you passed a NULL pointer for 'pmem'
; *                        OS_ERR_PNAME_NULL          You passed a NULL pointer for 'pname'
; *                        OS_ERR_MEM_NAME_TOO_LONG   if the name doesn't fit in the storage area
; *                        OS_ERR_NAME_SET_ISR        if you called this function from an ISR
; *
; * Returns    : None
; *********************************************************************************************************
; */
; #if OS_MEM_NAME_EN > 0u
; void  OSMemNameSet (OS_MEM  *pmem,
; INT8U   *pname,
; INT8U   *perr)
; {
       xdef      _OSMemNameSet
_OSMemNameSet:
       link      A6,#0
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return;
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pmem == (OS_MEM *)0) {                   /* Is 'pmem' a NULL pointer?                          */
; *perr = OS_ERR_MEM_INVALID_PMEM;
; return;
; }
; if (pname == (INT8U *)0) {                   /* Is 'pname' a NULL pointer?                         */
; *perr = OS_ERR_PNAME_NULL;
; return;
; }
; #endif
; if (OSIntNesting > 0u) {                     /* See if trying to call from an ISR                  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMemNameSet_1
; *perr = OS_ERR_NAME_SET_ISR;
       move.l    16(A6),A0
       move.b    #18,(A0)
; return;
       bra.s     OSMemNameSet_3
OSMemNameSet_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pmem->OSMemName = pname;
       move.l    8(A6),A0
       move.l    12(A6),20(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr           = OS_ERR_NONE;
       move.l    16(A6),A0
       clr.b     (A0)
OSMemNameSet_3:
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       RELEASE A MEMORY BLOCK
; *
; * Description : Returns a memory block to a partition
; *
; * Arguments   : pmem    is a pointer to the memory partition control block
; *
; *               pblk    is a pointer to the memory block being released.
; *
; * Returns     : OS_ERR_NONE              if the memory block was inserted into the partition
; *               OS_ERR_MEM_FULL          if you are returning a memory block to an already FULL memory
; *                                        partition (You freed more blocks than you allocated!)
; *               OS_ERR_MEM_INVALID_PMEM  if you passed a NULL pointer for 'pmem'
; *               OS_ERR_MEM_INVALID_PBLK  if you passed a NULL pointer for the block to release.
; *********************************************************************************************************
; */
; INT8U  OSMemPut (OS_MEM  *pmem,
; void    *pblk)
; {
       xdef      _OSMemPut
_OSMemPut:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pmem == (OS_MEM *)0) {                   /* Must point to a valid memory partition             */
; return (OS_ERR_MEM_INVALID_PMEM);
; }
; if (pblk == (void *)0) {                     /* Must release a valid block                         */
; return (OS_ERR_MEM_INVALID_PBLK);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pmem->OSMemNFree >= pmem->OSMemNBlks) {  /* Make sure all blocks not already returned          */
       move.l    D2,A0
       move.l    D2,A1
       move.l    16(A0),D0
       cmp.l     12(A1),D0
       blo.s     OSMemPut_1
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_MEM_FULL);
       moveq     #94,D0
       bra.s     OSMemPut_3
OSMemPut_1:
; }
; *(void **)pblk      = pmem->OSMemFreeList;   /* Insert released block into free block list         */
       move.l    D2,A0
       move.l    12(A6),D0
       move.l    D0,A1
       move.l    4(A0),(A1)
; pmem->OSMemFreeList = pblk;
       move.l    D2,A0
       move.l    12(A6),4(A0)
; pmem->OSMemNFree++;                          /* One more memory block in this partition            */
       move.l    D2,D0
       add.l     #16,D0
       move.l    D0,A0
       addq.l    #1,(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);                        /* Notify caller that memory block was released       */
       clr.b     D0
OSMemPut_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       QUERY MEMORY PARTITION
; *
; * Description : This function is used to determine the number of free memory blocks and the number of
; *               used memory blocks from a memory partition.
; *
; * Arguments   : pmem        is a pointer to the memory partition control block
; *
; *               p_mem_data  is a pointer to a structure that will contain information about the memory
; *                           partition.
; *
; * Returns     : OS_ERR_NONE               if no errors were found.
; *               OS_ERR_MEM_INVALID_PMEM   if you passed a NULL pointer for 'pmem'
; *               OS_ERR_MEM_INVALID_PDATA  if you passed a NULL pointer to the data recipient.
; *********************************************************************************************************
; */
; #if OS_MEM_QUERY_EN > 0u
; INT8U  OSMemQuery (OS_MEM       *pmem,
; OS_MEM_DATA  *p_mem_data)
; {
       xdef      _OSMemQuery
_OSMemQuery:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    12(A6),D2
       move.l    8(A6),D3
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pmem == (OS_MEM *)0) {                   /* Must point to a valid memory partition             */
; return (OS_ERR_MEM_INVALID_PMEM);
; }
; if (p_mem_data == (OS_MEM_DATA *)0) {        /* Must release a valid storage area for the data     */
; return (OS_ERR_MEM_INVALID_PDATA);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; p_mem_data->OSAddr     = pmem->OSMemAddr;
       move.l    D3,A0
       move.l    D2,A1
       move.l    (A0),(A1)
; p_mem_data->OSFreeList = pmem->OSMemFreeList;
       move.l    D3,A0
       move.l    D2,A1
       move.l    4(A0),4(A1)
; p_mem_data->OSBlkSize  = pmem->OSMemBlkSize;
       move.l    D3,A0
       move.l    D2,A1
       move.l    8(A0),8(A1)
; p_mem_data->OSNBlks    = pmem->OSMemNBlks;
       move.l    D3,A0
       move.l    D2,A1
       move.l    12(A0),12(A1)
; p_mem_data->OSNFree    = pmem->OSMemNFree;
       move.l    D3,A0
       move.l    D2,A1
       move.l    16(A0),16(A1)
; OS_EXIT_CRITICAL();
       dc.w      18143
; p_mem_data->OSNUsed    = p_mem_data->OSNBlks - p_mem_data->OSNFree;
       move.l    D2,A0
       move.l    12(A0),D0
       move.l    D2,A0
       sub.l     16(A0),D0
       move.l    D2,A0
       move.l    D0,20(A0)
; return (OS_ERR_NONE);
       clr.b     D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; #endif                                           /* OS_MEM_QUERY_EN                                    */
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                 INITIALIZE MEMORY PARTITION MANAGER
; *
; * Description : This function is called by uC/OS-II to initialize the memory partition manager.  Your
; *               application MUST NOT call this function.
; *
; * Arguments   : none
; *
; * Returns     : none
; *
; * Note(s)    : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; void  OS_MemInit (void)
; {
       xdef      _OS_MemInit
_OS_MemInit:
       movem.l   D2/D3/A2,-(A7)
       lea       _OSMemTbl.L,A2
; #if OS_MAX_MEM_PART == 1u
; OS_MemClr((INT8U *)&OSMemTbl[0], sizeof(OSMemTbl));   /* Clear the memory partition table          */
; OSMemFreeList               = (OS_MEM *)&OSMemTbl[0]; /* Point to beginning of free list           */
; #if OS_MEM_NAME_EN > 0u
; OSMemFreeList->OSMemName    = (INT8U *)"?";           /* Unknown name                              */
; #endif
; #endif
; #if OS_MAX_MEM_PART >= 2u
; OS_MEM  *pmem;
; INT16U   i;
; OS_MemClr((INT8U *)&OSMemTbl[0], sizeof(OSMemTbl));   /* Clear the memory partition table          */
       pea       120
       move.l    A2,-(A7)
       jsr       _OS_MemClr
       addq.w    #8,A7
; for (i = 0u; i < (OS_MAX_MEM_PART - 1u); i++) {       /* Init. list of free memory partitions      */
       clr.w     D3
OS_MemInit_1:
       cmp.w     #4,D3
       bhs       OS_MemInit_3
; pmem                = &OSMemTbl[i];               /* Point to memory control block (MCB)       */
       move.l    A2,D0
       and.l     #65535,D3
       move.l    D3,D1
       muls      #24,D1
       add.l     D1,D0
       move.l    D0,D2
; pmem->OSMemFreeList = (void *)&OSMemTbl[i + 1u];  /* Chain list of free partitions             */
       move.l    A2,D0
       and.l     #65535,D3
       move.l    D3,D1
       addq.l    #1,D1
       muls      #24,D1
       add.l     D1,D0
       move.l    D2,A0
       move.l    D0,4(A0)
; #if OS_MEM_NAME_EN > 0u
; pmem->OSMemName  = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,20(A1)
       addq.w    #1,D3
       bra       OS_MemInit_1
OS_MemInit_3:
; #endif
; }
; pmem                = &OSMemTbl[i];
       move.l    A2,D0
       and.l     #65535,D3
       move.l    D3,D1
       muls      #24,D1
       add.l     D1,D0
       move.l    D0,D2
; pmem->OSMemFreeList = (void *)0;                      /* Initialize last node                      */
       move.l    D2,A0
       clr.l     4(A0)
; #if OS_MEM_NAME_EN > 0u
; pmem->OSMemName = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,20(A1)
; #endif
; OSMemFreeList   = &OSMemTbl[0];                       /* Point to beginning of free list           */
       move.l    A2,_OSMemFreeList.L
       movem.l   (A7)+,D2/D3/A2
       rts
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                  MUTUAL EXCLUSION SEMAPHORE MANAGEMENT
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : OS_MUTEX.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #include <ucos_ii.h>
; #endif
; #if OS_MUTEX_EN > 0u
; /*
; *********************************************************************************************************
; *                                           LOCAL CONSTANTS
; *********************************************************************************************************
; */
; #define  OS_MUTEX_KEEP_LOWER_8   ((INT16U)0x00FFu)
; #define  OS_MUTEX_KEEP_UPPER_8   ((INT16U)0xFF00u)
; #define  OS_MUTEX_AVAILABLE      ((INT16U)0x00FFu)
; /*
; *********************************************************************************************************
; *                                           LOCAL CONSTANTS
; *********************************************************************************************************
; */
; static  void  OSMutex_RdyAtPrio(OS_TCB *ptcb, INT8U prio);
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                  ACCEPT MUTUAL EXCLUSION SEMAPHORE
; *
; * Description: This  function checks the mutual exclusion semaphore to see if a resource is available.
; *              Unlike OSMutexPend(), OSMutexAccept() does not suspend the calling task if the resource is
; *              not available or the event did not occur.
; *
; * Arguments  : pevent     is a pointer to the event control block
; *
; *              perr       is a pointer to an error code which will be returned to your application:
; *                            OS_ERR_NONE         if the call was successful.
; *                            OS_ERR_EVENT_TYPE   if 'pevent' is not a pointer to a mutex
; *                            OS_ERR_PEVENT_NULL  'pevent' is a NULL pointer
; *                            OS_ERR_PEND_ISR     if you called this function from an ISR
; *                            OS_ERR_PCP_LOWER    If the priority of the task that owns the Mutex is
; *                                                HIGHER (i.e. a lower number) than the PCP.  This error
; *                                                indicates that you did not set the PCP higher (lower
; *                                                number) than ALL the tasks that compete for the Mutex.
; *                                                Unfortunately, this is something that could not be
; *                                                detected when the Mutex is created because we don't know
; *                                                what tasks will be using the Mutex.
; *
; * Returns    : == OS_TRUE    if the resource is available, the mutual exclusion semaphore is acquired
; *              == OS_FALSE   a) if the resource is not available
; *                            b) you didn't pass a pointer to a mutual exclusion semaphore
; *                            c) you called this function from an ISR
; *
; * Warning(s) : This function CANNOT be called from an ISR because mutual exclusion semaphores are
; *              intended to be used by tasks only.
; *********************************************************************************************************
; */
; #if OS_MUTEX_ACCEPT_EN > 0u
; BOOLEAN  OSMutexAccept (OS_EVENT  *pevent,
; INT8U     *perr)
; {
       xdef      _OSMutexAccept
_OSMutexAccept:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       move.l    8(A6),D2
       move.l    12(A6),D3
       lea       _OSTCBCur.L,A2
; INT8U      pcp;                                    /* Priority Ceiling Priority (PCP)              */
; #if OS_CRITICAL_METHOD == 3u                           /* Allocate storage for CPU status register     */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (OS_FALSE);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                     /* Validate 'pevent'                            */
; *perr = OS_ERR_PEVENT_NULL;
; return (OS_FALSE);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MUTEX) {  /* Validate event block type                    */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #4,D0
       beq.s     OSMutexAccept_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D3,A0
       move.b    #1,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra       OSMutexAccept_3
OSMutexAccept_1:
; }
; if (OSIntNesting > 0u) {                           /* Make sure it's not called from an ISR        */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMutexAccept_4
; *perr = OS_ERR_PEND_ISR;
       move.l    D3,A0
       move.b    #2,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra       OSMutexAccept_3
OSMutexAccept_4:
; }
; OS_ENTER_CRITICAL();                               /* Get value (0 or 1) of Mutex                  */
       dc.w      16615
       dc.w      124
       dc.w      1792
; pcp = (INT8U)(pevent->OSEventCnt >> 8u);           /* Get PCP from mutex                           */
       move.l    D2,A0
       move.w    6(A0),D0
       lsr.w     #8,D0
       move.b    D0,D4
; if ((pevent->OSEventCnt & OS_MUTEX_KEEP_LOWER_8) == OS_MUTEX_AVAILABLE) {
       move.l    D2,A0
       move.w    6(A0),D0
       and.w     #255,D0
       cmp.w     #255,D0
       bne       OSMutexAccept_6
; pevent->OSEventCnt &= OS_MUTEX_KEEP_UPPER_8;   /*      Mask off LSByte (Acquire Mutex)         */
       move.l    D2,A0
       and.w     #65280,6(A0)
; pevent->OSEventCnt |= OSTCBCur->OSTCBPrio;     /*      Save current task priority in LSByte    */
       move.l    D2,A0
       move.l    (A2),A1
       move.b    52(A1),D0
       and.w     #255,D0
       or.w      D0,6(A0)
; pevent->OSEventPtr  = (void *)OSTCBCur;        /*      Link TCB of task owning Mutex           */
       move.l    D2,A0
       move.l    (A2),2(A0)
; if ((pcp != OS_PRIO_MUTEX_CEIL_DIS) &&
       cmp.b     #255,D4
       beq.s     OSMutexAccept_8
       move.l    (A2),A0
       cmp.b     52(A0),D4
       blo.s     OSMutexAccept_8
; (OSTCBCur->OSTCBPrio <= pcp)) {            /*      PCP 'must' have a SMALLER prio ...      */
; OS_EXIT_CRITICAL();                       /*      ... than current task!                  */
       dc.w      18143
; *perr = OS_ERR_PCP_LOWER;
       move.l    D3,A0
       move.b    #120,(A0)
       bra.s     OSMutexAccept_9
OSMutexAccept_8:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
OSMutexAccept_9:
; }
; return (OS_TRUE);
       moveq     #1,D0
       bra.s     OSMutexAccept_3
OSMutexAccept_6:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; return (OS_FALSE);
       clr.b     D0
OSMutexAccept_3:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                 CREATE A MUTUAL EXCLUSION SEMAPHORE
; *
; * Description: This function creates a mutual exclusion semaphore.
; *
; * Arguments  : prio          is the priority to use when accessing the mutual exclusion semaphore.  In
; *                            other words, when the semaphore is acquired and a higher priority task
; *                            attempts to obtain the semaphore then the priority of the task owning the
; *                            semaphore is raised to this priority.  It is assumed that you will specify
; *                            a priority that is LOWER in value than ANY of the tasks competing for the
; *                            mutex. If the priority is specified as OS_PRIO_MUTEX_CEIL_DIS, then the
; *                            priority ceiling promotion is disabled. This way, the tasks accessing the
; *                            semaphore do not have their priority promoted.
; *
; *              perr          is a pointer to an error code which will be returned to your application:
; *                               OS_ERR_NONE         if the call was successful.
; *                               OS_ERR_CREATE_ISR   if you attempted to create a MUTEX from an ISR
; *                               OS_ERR_PRIO_EXIST   if a task at the priority ceiling priority
; *                                                   already exist.
; *                               OS_ERR_PEVENT_NULL  No more event control blocks available.
; *                               OS_ERR_PRIO_INVALID if the priority you specify is higher that the
; *                                                   maximum allowed (i.e. > OS_LOWEST_PRIO)
; *
; * Returns    : != (void *)0  is a pointer to the event control clock (OS_EVENT) associated with the
; *                            created mutex.
; *              == (void *)0  if an error is detected.
; *
; * Note(s)    : 1) The LEAST significant 8 bits of '.OSEventCnt' hold the priority number of the task
; *                 owning the mutex or 0xFF if no task owns the mutex.
; *
; *              2) The MOST  significant 8 bits of '.OSEventCnt' hold the priority number used to
; *                 reduce priority inversion or 0xFF (OS_PRIO_MUTEX_CEIL_DIS) if priority ceiling
; *                 promotion is disabled.
; *********************************************************************************************************
; */
; OS_EVENT  *OSMutexCreate (INT8U   prio,
; INT8U  *perr)
; {
       xdef      _OSMutexCreate
_OSMutexCreate:
       link      A6,#0
       movem.l   D2/D3/D4/A2/A3,-(A7)
       move.b    11(A6),D3
       and.l     #255,D3
       move.l    12(A6),D4
       lea       _OSEventFreeList.L,A2
       lea       _OSTCBPrioTbl.L,A3
; OS_EVENT  *pevent;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_EVENT *)0);
; }
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; if (OSSafetyCriticalStartFlag == OS_TRUE) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_EVENT *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio != OS_PRIO_MUTEX_CEIL_DIS) {
; if (prio >= OS_LOWEST_PRIO) {                      /* Validate PCP                             */
; *perr = OS_ERR_PRIO_INVALID;
; return ((OS_EVENT *)0);
; }
; }
; #endif
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMutexCreate_1
; *perr = OS_ERR_CREATE_ISR;                         /* ... can't CREATE mutex from an ISR       */
       move.l    D4,A0
       move.b    #16,(A0)
; return ((OS_EVENT *)0);
       clr.l     D0
       bra       OSMutexCreate_3
OSMutexCreate_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (prio != OS_PRIO_MUTEX_CEIL_DIS) {
       cmp.b     #255,D3
       beq.s     OSMutexCreate_4
; if (OSTCBPrioTbl[prio] != (OS_TCB *)0) {           /* Mutex priority must not already exist    */
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       beq.s     OSMutexCreate_6
; OS_EXIT_CRITICAL();                            /* Task already exist at priority ...       */
       dc.w      18143
; *perr = OS_ERR_PRIO_EXIST;                      /* ... ceiling priority                     */
       move.l    D4,A0
       move.b    #40,(A0)
; return ((OS_EVENT *)0);
       clr.l     D0
       bra       OSMutexCreate_3
OSMutexCreate_6:
; }
; OSTCBPrioTbl[prio] = OS_TCB_RESERVED;              /* Reserve the table entry                  */
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       move.l    #1,0(A3,D0.L)
OSMutexCreate_4:
; }
; pevent = OSEventFreeList;                              /* Get next free event control block        */
       move.l    (A2),D2
; if (pevent == (OS_EVENT *)0) {                         /* See if an ECB was available              */
       tst.l     D2
       bne.s     OSMutexCreate_8
; if (prio != OS_PRIO_MUTEX_CEIL_DIS) {
       cmp.b     #255,D3
       beq.s     OSMutexCreate_10
; OSTCBPrioTbl[prio] = (OS_TCB *)0;              /* No, Release the table entry              */
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       clr.l     0(A3,D0.L)
OSMutexCreate_10:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_PEVENT_NULL;                         /* No more event control blocks             */
       move.l    D4,A0
       move.b    #4,(A0)
; return (pevent);
       move.l    D2,D0
       bra       OSMutexCreate_3
OSMutexCreate_8:
; }
; OSEventFreeList     = (OS_EVENT *)OSEventFreeList->OSEventPtr; /* Adjust the free list             */
       move.l    (A2),A0
       move.l    2(A0),(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; pevent->OSEventType = OS_EVENT_TYPE_MUTEX;
       move.l    D2,A0
       move.b    #4,(A0)
; pevent->OSEventCnt  = (INT16U)((INT16U)prio << 8u) | OS_MUTEX_AVAILABLE; /* Resource is avail.     */
       move.b    D3,D0
       and.w     #255,D0
       lsl.w     #8,D0
       or.w      #255,D0
       move.l    D2,A0
       move.w    D0,6(A0)
; pevent->OSEventPtr  = (void *)0;                       /* No task owning the mutex                 */
       move.l    D2,A0
       clr.l     2(A0)
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; OS_EventWaitListInit(pevent);
       move.l    D2,-(A7)
       jsr       _OS_EventWaitListInit
       addq.w    #4,A7
; *perr = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; return (pevent);
       move.l    D2,D0
OSMutexCreate_3:
       movem.l   (A7)+,D2/D3/D4/A2/A3
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           DELETE A MUTEX
; *
; * Description: This function deletes a mutual exclusion semaphore and readies all tasks pending on the it.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired mutex.
; *
; *              opt           determines delete options as follows:
; *                            opt == OS_DEL_NO_PEND   Delete mutex ONLY if no task pending
; *                            opt == OS_DEL_ALWAYS    Deletes the mutex even if tasks are waiting.
; *                                                    In this case, all the tasks pending will be readied.
; *
; *              perr          is a pointer to an error code that can contain one of the following values:
; *                            OS_ERR_NONE             The call was successful and the mutex was deleted
; *                            OS_ERR_DEL_ISR          If you attempted to delete the MUTEX from an ISR
; *                            OS_ERR_INVALID_OPT      An invalid option was specified
; *                            OS_ERR_TASK_WAITING     One or more tasks were waiting on the mutex
; *                            OS_ERR_EVENT_TYPE       If you didn't pass a pointer to a mutex
; *                            OS_ERR_PEVENT_NULL      If 'pevent' is a NULL pointer.
; *
; * Returns    : pevent        upon error
; *              (OS_EVENT *)0 if the mutex was successfully deleted.
; *
; * Note(s)    : 1) This function must be used with care.  Tasks that would normally expect the presence of
; *                 the mutex MUST check the return code of OSMutexPend().
; *
; *              2) This call can potentially disable interrupts for a long time.  The interrupt disable
; *                 time is directly proportional to the number of tasks waiting on the mutex.
; *
; *              3) Because ALL tasks pending on the mutex will be readied, you MUST be careful because the
; *                 resource(s) will no longer be guarded by the mutex.
; *
; *              4) IMPORTANT: In the 'OS_DEL_ALWAYS' case, we assume that the owner of the Mutex (if there
; *                            is one) is ready-to-run and is thus NOT pending on another kernel object or
; *                            has delayed itself.  In other words, if a task owns the mutex being deleted,
; *                            that task will be made ready-to-run at its original priority.
; *********************************************************************************************************
; */
; #if OS_MUTEX_DEL_EN > 0u
; OS_EVENT  *OSMutexDel (OS_EVENT  *pevent,
; INT8U      opt,
; INT8U     *perr)
; {
       xdef      _OSMutexDel
_OSMutexDel:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/D7/A2,-(A7)
       move.l    8(A6),D2
       move.l    16(A6),D4
       lea       _OSEventFreeList.L,A2
; BOOLEAN    tasks_waiting;
; OS_EVENT  *pevent_return;
; INT8U      pcp;                                        /* Priority ceiling priority                */
; INT8U      prio;
; OS_TCB    *ptcb;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_EVENT *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; *perr = OS_ERR_PEVENT_NULL;
; return (pevent);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MUTEX) {      /* Validate event block type                */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #4,D0
       beq.s     OSMutexDel_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return (pevent);
       move.l    D2,D0
       bra       OSMutexDel_3
OSMutexDel_1:
; }
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMutexDel_4
; *perr = OS_ERR_DEL_ISR;                             /* ... can't DELETE from an ISR             */
       move.l    D4,A0
       move.b    #15,(A0)
; return (pevent);
       move.l    D2,D0
       bra       OSMutexDel_3
OSMutexDel_4:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                        /* See if any tasks waiting on mutex        */
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSMutexDel_6
; tasks_waiting = OS_TRUE;                           /* Yes                                      */
       moveq     #1,D7
       bra.s     OSMutexDel_7
OSMutexDel_6:
; } else {
; tasks_waiting = OS_FALSE;                          /* No                                       */
       moveq     #0,D7
OSMutexDel_7:
; }
; switch (opt) {
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq       OSMutexDel_11
       bhi       OSMutexDel_8
       tst.l     D0
       beq.s     OSMutexDel_10
       bra       OSMutexDel_8
OSMutexDel_10:
; case OS_DEL_NO_PEND:                               /* DELETE MUTEX ONLY IF NO TASK WAITING --- */
; if (tasks_waiting == OS_FALSE) {
       tst.b     D7
       bne       OSMutexDel_13
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName   = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; pcp                   = (INT8U)(pevent->OSEventCnt >> 8u);
       move.l    D2,A0
       move.w    6(A0),D0
       lsr.w     #8,D0
       move.b    D0,D3
; if (pcp != OS_PRIO_MUTEX_CEIL_DIS) {
       cmp.b     #255,D3
       beq.s     OSMutexDel_15
; OSTCBPrioTbl[pcp] = (OS_TCB *)0;      /* Free up the PCP                          */
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       clr.l     0(A0,D0.L)
OSMutexDel_15:
; }
; pevent->OSEventType   = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent->OSEventPtr    = OSEventFreeList;  /* Return Event Control Block to free list  */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pevent->OSEventCnt    = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; OSEventFreeList       = pevent;
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                 = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; pevent_return         = (OS_EVENT *)0;    /* Mutex has been deleted                   */
       clr.l     D5
       bra.s     OSMutexDel_14
OSMutexDel_13:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                 = OS_ERR_TASK_WAITING;
       move.l    D4,A0
       move.b    #73,(A0)
; pevent_return         = pevent;
       move.l    D2,D5
OSMutexDel_14:
; }
; break;
       bra       OSMutexDel_9
OSMutexDel_11:
; case OS_DEL_ALWAYS:                                /* ALWAYS DELETE THE MUTEX ---------------- */
; pcp  = (INT8U)(pevent->OSEventCnt >> 8u);                       /* Get PCP of mutex       */
       move.l    D2,A0
       move.w    6(A0),D0
       lsr.w     #8,D0
       move.b    D0,D3
; if (pcp != OS_PRIO_MUTEX_CEIL_DIS) {
       cmp.b     #255,D3
       beq       OSMutexDel_21
; prio = (INT8U)(pevent->OSEventCnt & OS_MUTEX_KEEP_LOWER_8); /* Get owner's orig prio  */
       move.l    D2,A0
       move.w    6(A0),D0
       and.w     #255,D0
       move.b    D0,-1(A6)
; ptcb = (OS_TCB *)pevent->OSEventPtr;
       move.l    D2,A0
       move.l    2(A0),D6
; if (ptcb != (OS_TCB *)0) {                /* See if any task owns the mutex           */
       tst.l     D6
       beq.s     OSMutexDel_21
; if (ptcb->OSTCBPrio == pcp) {         /* See if original prio was changed         */
       move.l    D6,A0
       cmp.b     52(A0),D3
       bne.s     OSMutexDel_21
; OSMutex_RdyAtPrio(ptcb, prio);    /* Yes, Restore the task's original prio    */
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D6,-(A7)
       jsr       @ucos_ii_OSMutex_RdyAtPrio
       addq.w    #8,A7
OSMutexDel_21:
; }
; }
; }
; while (pevent->OSEventGrp != 0u) {            /* Ready ALL tasks waiting for mutex        */
OSMutexDel_23:
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSMutexDel_25
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_MUTEX, OS_STAT_PEND_ABORT);
       pea       2
       pea       16
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
       bra       OSMutexDel_23
OSMutexDel_25:
; }
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName   = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; pcp                   = (INT8U)(pevent->OSEventCnt >> 8u);
       move.l    D2,A0
       move.w    6(A0),D0
       lsr.w     #8,D0
       move.b    D0,D3
; if (pcp != OS_PRIO_MUTEX_CEIL_DIS) {
       cmp.b     #255,D3
       beq.s     OSMutexDel_26
; OSTCBPrioTbl[pcp] = (OS_TCB *)0;          /* Free up the PCP                          */
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       clr.l     0(A0,D0.L)
OSMutexDel_26:
; }
; pevent->OSEventType   = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent->OSEventPtr    = OSEventFreeList;      /* Return Event Control Block to free list  */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pevent->OSEventCnt    = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; OSEventFreeList       = pevent;               /* Get next free event control block        */
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (tasks_waiting == OS_TRUE) {               /* Reschedule only if task(s) were waiting  */
       cmp.b     #1,D7
       bne.s     OSMutexDel_28
; OS_Sched();                               /* Find highest priority task ready to run  */
       jsr       _OS_Sched
OSMutexDel_28:
; }
; *perr         = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; pevent_return = (OS_EVENT *)0;                /* Mutex has been deleted                   */
       clr.l     D5
; break;
       bra.s     OSMutexDel_9
OSMutexDel_8:
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr         = OS_ERR_INVALID_OPT;
       move.l    D4,A0
       move.b    #7,(A0)
; pevent_return = pevent;
       move.l    D2,D5
; break;
OSMutexDel_9:
; }
; return (pevent_return);
       move.l    D5,D0
OSMutexDel_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                 PEND ON MUTUAL EXCLUSION SEMAPHORE
; *
; * Description: This function waits for a mutual exclusion semaphore.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired
; *                            mutex.
; *
; *              timeout       is an optional timeout period (in clock ticks).  If non-zero, your task will
; *                            wait for the resource up to the amount of time specified by this argument.
; *                            If you specify 0, however, your task will wait forever at the specified
; *                            mutex or, until the resource becomes available.
; *
; *              perr          is a pointer to where an error message will be deposited.  Possible error
; *                            messages are:
; *                               OS_ERR_NONE        The call was successful and your task owns the mutex
; *                               OS_ERR_TIMEOUT     The mutex was not available within the specified 'timeout'.
; *                               OS_ERR_PEND_ABORT  The wait on the mutex was aborted.
; *                               OS_ERR_EVENT_TYPE  If you didn't pass a pointer to a mutex
; *                               OS_ERR_PEVENT_NULL 'pevent' is a NULL pointer
; *                               OS_ERR_PEND_ISR    If you called this function from an ISR and the result
; *                                                  would lead to a suspension.
; *                               OS_ERR_PCP_LOWER   If the priority of the task that owns the Mutex is
; *                                                  HIGHER (i.e. a lower number) than the PCP.  This error
; *                                                  indicates that you did not set the PCP higher (lower
; *                                                  number) than ALL the tasks that compete for the Mutex.
; *                                                  Unfortunately, this is something that could not be
; *                                                  detected when the Mutex is created because we don't know
; *                                                  what tasks will be using the Mutex.
; *                               OS_ERR_PEND_LOCKED If you called this function when the scheduler is locked
; *
; * Returns    : none
; *
; * Note(s)    : 1) The task that owns the Mutex MUST NOT pend on any other event while it owns the mutex.
; *
; *              2) You MUST NOT change the priority of the task that owns the mutex
; *********************************************************************************************************
; */
; void  OSMutexPend (OS_EVENT  *pevent,
; INT32U     timeout,
; INT8U     *perr)
; {
       xdef      _OSMutexPend
_OSMutexPend:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3,-(A7)
       lea       _OSTCBCur.L,A2
       move.l    8(A6),D3
       move.l    16(A6),D5
       lea       _OSRdyTbl.L,A3
; INT8U      pcp;                                        /* Priority Ceiling Priority (PCP)          */
; INT8U      mprio;                                      /* Mutex owner priority                     */
; BOOLEAN    rdy;                                        /* Flag indicating task was ready           */
; OS_TCB    *ptcb;
; OS_EVENT  *pevent2;
; INT8U      y;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return;
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; *perr = OS_ERR_PEVENT_NULL;
; return;
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MUTEX) {      /* Validate event block type                */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #4,D0
       beq.s     OSMutexPend_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D5,A0
       move.b    #1,(A0)
; return;
       bra       OSMutexPend_3
OSMutexPend_1:
; }
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMutexPend_4
; *perr = OS_ERR_PEND_ISR;                           /* ... can't PEND from an ISR               */
       move.l    D5,A0
       move.b    #2,(A0)
; return;
       bra       OSMutexPend_3
OSMutexPend_4:
; }
; if (OSLockNesting > 0u) {                              /* See if called with scheduler locked ...  */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMutexPend_6
; *perr = OS_ERR_PEND_LOCKED;                        /* ... can't PEND when locked               */
       move.l    D5,A0
       move.b    #13,(A0)
; return;
       bra       OSMutexPend_3
OSMutexPend_6:
; }
; /*$PAGE*/
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pcp = (INT8U)(pevent->OSEventCnt >> 8u);               /* Get PCP from mutex                       */
       move.l    D3,A0
       move.w    6(A0),D0
       lsr.w     #8,D0
       move.b    D0,D7
; /* Is Mutex available?                      */
; if ((INT8U)(pevent->OSEventCnt & OS_MUTEX_KEEP_LOWER_8) == OS_MUTEX_AVAILABLE) {
       move.l    D3,A0
       move.w    6(A0),D0
       and.w     #255,D0
       and.w     #255,D0
       cmp.w     #255,D0
       bne       OSMutexPend_8
; pevent->OSEventCnt &= OS_MUTEX_KEEP_UPPER_8;       /* Yes, Acquire the resource                */
       move.l    D3,A0
       and.w     #65280,6(A0)
; pevent->OSEventCnt |= OSTCBCur->OSTCBPrio;         /*      Save priority of owning task        */
       move.l    D3,A0
       move.l    (A2),A1
       move.b    52(A1),D0
       and.w     #255,D0
       or.w      D0,6(A0)
; pevent->OSEventPtr  = (void *)OSTCBCur;            /*      Point to owning task's OS_TCB       */
       move.l    D3,A0
       move.l    (A2),2(A0)
; if ((pcp != OS_PRIO_MUTEX_CEIL_DIS) &&
       cmp.b     #255,D7
       beq.s     OSMutexPend_10
       move.l    (A2),A0
       cmp.b     52(A0),D7
       blo.s     OSMutexPend_10
; (OSTCBCur->OSTCBPrio <= pcp)) {                /*      PCP 'must' have a SMALLER prio ...  */
; OS_EXIT_CRITICAL();                           /*      ... than current task!              */
       dc.w      18143
; *perr = OS_ERR_PCP_LOWER;
       move.l    D5,A0
       move.b    #120,(A0)
       bra.s     OSMutexPend_11
OSMutexPend_10:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D5,A0
       clr.b     (A0)
OSMutexPend_11:
; }
; return;
       bra       OSMutexPend_3
OSMutexPend_8:
; }
; if (pcp != OS_PRIO_MUTEX_CEIL_DIS) {
       cmp.b     #255,D7
       beq       OSMutexPend_16
; mprio = (INT8U)(pevent->OSEventCnt & OS_MUTEX_KEEP_LOWER_8); /*  Get priority of mutex owner   */
       move.l    D3,A0
       move.w    6(A0),D0
       and.w     #255,D0
       move.b    D0,-2(A6)
; ptcb  = (OS_TCB *)(pevent->OSEventPtr);                   /*     Point to TCB of mutex owner   */
       move.l    D3,A0
       move.l    2(A0),D2
; if (ptcb->OSTCBPrio > pcp) {                              /*     Need to promote prio of owner?*/
       move.l    D2,A0
       cmp.b     52(A0),D7
       bhs       OSMutexPend_16
; if (mprio > OSTCBCur->OSTCBPrio) {
       move.l    (A2),A0
       move.b    -2(A6),D0
       cmp.b     52(A0),D0
       bls       OSMutexPend_16
; y = ptcb->OSTCBY;
       move.l    D2,A0
       move.b    54(A0),D6
; if ((OSRdyTbl[y] & ptcb->OSTCBBitX) != 0u) {      /*     See if mutex owner is ready   */
       and.l     #255,D6
       move.b    0(A3,D6.L),D0
       move.l    D2,A0
       and.b     55(A0),D0
       beq.s     OSMutexPend_18
; OSRdyTbl[y] &= (OS_PRIO)~ptcb->OSTCBBitX;     /*     Yes, Remove owner from Rdy ...*/
       and.l     #255,D6
       move.l    D2,A0
       move.b    55(A0),D0
       not.b     D0
       and.b     D0,0(A3,D6.L)
; if (OSRdyTbl[y] == 0u) {                      /*          ... list at current prio */
       and.l     #255,D6
       move.b    0(A3,D6.L),D0
       bne.s     OSMutexPend_20
; OSRdyGrp &= (OS_PRIO)~ptcb->OSTCBBitY;
       move.l    D2,A0
       move.b    56(A0),D0
       not.b     D0
       and.b     D0,_OSRdyGrp.L
OSMutexPend_20:
; }
; rdy = OS_TRUE;
       move.b    #1,-1(A6)
       bra       OSMutexPend_19
OSMutexPend_18:
; } else {
; pevent2 = ptcb->OSTCBEventPtr;
       move.l    D2,A0
       move.l    28(A0),D4
; if (pevent2 != (OS_EVENT *)0) {               /* Remove from event wait list       */
       tst.l     D4
       beq       OSMutexPend_24
; y = ptcb->OSTCBY;
       move.l    D2,A0
       move.b    54(A0),D6
; pevent2->OSEventTbl[y] &= (OS_PRIO)~ptcb->OSTCBBitX;
       move.l    D4,A0
       and.l     #255,D6
       add.l     D6,A0
       move.l    D2,A1
       move.b    55(A1),D0
       not.b     D0
       and.b     D0,10(A0)
; if (pevent2->OSEventTbl[y] == 0u) {
       move.l    D4,A0
       and.l     #255,D6
       add.l     D6,A0
       move.b    10(A0),D0
       bne.s     OSMutexPend_24
; pevent2->OSEventGrp &= (OS_PRIO)~ptcb->OSTCBBitY;
       move.l    D4,A0
       move.l    D2,A1
       move.b    56(A1),D0
       not.b     D0
       and.b     D0,8(A0)
OSMutexPend_24:
; }
; }
; rdy = OS_FALSE;                        /* No                                       */
       clr.b     -1(A6)
OSMutexPend_19:
; }
; ptcb->OSTCBPrio = pcp;                     /* Change owner task prio to PCP            */
       move.l    D2,A0
       move.b    D7,52(A0)
; #if OS_LOWEST_PRIO <= 63u
; ptcb->OSTCBY    = (INT8U)( ptcb->OSTCBPrio >> 3u);
       move.l    D2,A0
       move.b    52(A0),D0
       lsr.b     #3,D0
       move.l    D2,A0
       move.b    D0,54(A0)
; ptcb->OSTCBX    = (INT8U)( ptcb->OSTCBPrio & 0x07u);
       move.l    D2,A0
       move.b    52(A0),D0
       and.b     #7,D0
       move.l    D2,A0
       move.b    D0,53(A0)
; #else
; ptcb->OSTCBY    = (INT8U)((INT8U)(ptcb->OSTCBPrio >> 4u) & 0xFFu);
; ptcb->OSTCBX    = (INT8U)( ptcb->OSTCBPrio & 0x0Fu);
; #endif
; ptcb->OSTCBBitY = (OS_PRIO)(1uL << ptcb->OSTCBY);
       moveq     #1,D0
       move.l    D2,A0
       move.b    54(A0),D1
       and.l     #255,D1
       lsl.l     D1,D0
       move.l    D2,A0
       move.b    D0,56(A0)
; ptcb->OSTCBBitX = (OS_PRIO)(1uL << ptcb->OSTCBX);
       moveq     #1,D0
       move.l    D2,A0
       move.b    53(A0),D1
       and.l     #255,D1
       lsl.l     D1,D0
       move.l    D2,A0
       move.b    D0,55(A0)
; if (rdy == OS_TRUE) {                      /* If task was ready at owner's priority ...*/
       move.b    -1(A6),D0
       cmp.b     #1,D0
       bne.s     OSMutexPend_26
; OSRdyGrp               |= ptcb->OSTCBBitY; /* ... make it ready at new priority.   */
       move.l    D2,A0
       move.b    56(A0),D0
       or.b      D0,_OSRdyGrp.L
; OSRdyTbl[ptcb->OSTCBY] |= ptcb->OSTCBBitX;
       move.l    D2,A0
       move.b    54(A0),D0
       and.l     #255,D0
       move.l    D2,A0
       move.b    55(A0),D1
       or.b      D1,0(A3,D0.L)
       bra       OSMutexPend_28
OSMutexPend_26:
; } else {
; pevent2 = ptcb->OSTCBEventPtr;
       move.l    D2,A0
       move.l    28(A0),D4
; if (pevent2 != (OS_EVENT *)0) {        /* Add to event wait list                   */
       tst.l     D4
       beq.s     OSMutexPend_28
; pevent2->OSEventGrp               |= ptcb->OSTCBBitY;
       move.l    D4,A0
       move.l    D2,A1
       move.b    56(A1),D0
       or.b      D0,8(A0)
; pevent2->OSEventTbl[ptcb->OSTCBY] |= ptcb->OSTCBBitX;
       move.l    D4,A0
       move.l    D2,A1
       move.b    54(A1),D0
       and.l     #255,D0
       add.l     D0,A0
       move.l    D2,A1
       move.b    55(A1),D0
       or.b      D0,10(A0)
OSMutexPend_28:
; }
; }
; OSTCBPrioTbl[pcp] = ptcb;
       and.l     #255,D7
       move.l    D7,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    D2,0(A0,D0.L)
OSMutexPend_16:
; }
; }
; }
; OSTCBCur->OSTCBStat     |= OS_STAT_MUTEX;         /* Mutex not available, pend current task        */
       move.l    (A2),A0
       or.b      #16,50(A0)
; OSTCBCur->OSTCBStatPend  = OS_STAT_PEND_OK;
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBDly       = timeout;               /* Store timeout in current task's TCB           */
       move.l    (A2),A0
       move.l    12(A6),46(A0)
; OS_EventTaskWait(pevent);                         /* Suspend task until event or timeout occurs    */
       move.l    D3,-(A7)
       jsr       _OS_EventTaskWait
       addq.w    #4,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                       /* Find next highest priority task ready         */
       jsr       _OS_Sched
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; switch (OSTCBCur->OSTCBStatPend) {                /* See if we timed-out or aborted                */
       move.l    (A2),A0
       move.b    51(A0),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq.s     OSMutexPend_34
       bhi.s     OSMutexPend_36
       tst.l     D0
       beq.s     OSMutexPend_32
       bra.s     OSMutexPend_34
OSMutexPend_36:
       cmp.l     #2,D0
       beq.s     OSMutexPend_33
       bra.s     OSMutexPend_34
OSMutexPend_32:
; case OS_STAT_PEND_OK:
; *perr = OS_ERR_NONE;
       move.l    D5,A0
       clr.b     (A0)
; break;
       bra.s     OSMutexPend_31
OSMutexPend_33:
; case OS_STAT_PEND_ABORT:
; *perr = OS_ERR_PEND_ABORT;               /* Indicate that we aborted getting mutex        */
       move.l    D5,A0
       move.b    #14,(A0)
; break;
       bra.s     OSMutexPend_31
OSMutexPend_34:
; case OS_STAT_PEND_TO:
; default:
; OS_EventTaskRemove(OSTCBCur, pevent);
       move.l    D3,-(A7)
       move.l    (A2),-(A7)
       jsr       _OS_EventTaskRemove
       addq.w    #8,A7
; *perr = OS_ERR_TIMEOUT;                  /* Indicate that we didn't get mutex within TO   */
       move.l    D5,A0
       move.b    #10,(A0)
; break;
OSMutexPend_31:
; }
; OSTCBCur->OSTCBStat          =  OS_STAT_RDY;      /* Set   task  status to ready                   */
       move.l    (A2),A0
       clr.b     50(A0)
; OSTCBCur->OSTCBStatPend      =  OS_STAT_PEND_OK;  /* Clear pend  status                            */
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBEventPtr      = (OS_EVENT  *)0;    /* Clear event pointers                          */
       move.l    (A2),A0
       clr.l     28(A0)
; #if (OS_EVENT_MULTI_EN > 0u)
; OSTCBCur->OSTCBEventMultiPtr = (OS_EVENT **)0;
       move.l    (A2),A0
       clr.l     32(A0)
; #endif
; OS_EXIT_CRITICAL();
       dc.w      18143
OSMutexPend_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                POST TO A MUTUAL EXCLUSION SEMAPHORE
; *
; * Description: This function signals a mutual exclusion semaphore
; *
; * Arguments  : pevent              is a pointer to the event control block associated with the desired
; *                                  mutex.
; *
; * Returns    : OS_ERR_NONE             The call was successful and the mutex was signaled.
; *              OS_ERR_EVENT_TYPE       If you didn't pass a pointer to a mutex
; *              OS_ERR_PEVENT_NULL      'pevent' is a NULL pointer
; *              OS_ERR_POST_ISR         Attempted to post from an ISR (not valid for MUTEXes)
; *              OS_ERR_NOT_MUTEX_OWNER  The task that did the post is NOT the owner of the MUTEX.
; *              OS_ERR_PCP_LOWER        If the priority of the new task that owns the Mutex is
; *                                      HIGHER (i.e. a lower number) than the PCP.  This error
; *                                      indicates that you did not set the PCP higher (lower
; *                                      number) than ALL the tasks that compete for the Mutex.
; *                                      Unfortunately, this is something that could not be
; *                                      detected when the Mutex is created because we don't know
; *                                      what tasks will be using the Mutex.
; *********************************************************************************************************
; */
; INT8U  OSMutexPost (OS_EVENT *pevent)
; {
       xdef      _OSMutexPost
_OSMutexPost:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       move.l    8(A6),D2
       lea       _OSTCBCur.L,A2
; INT8U      pcp;                                   /* Priority ceiling priority                     */
; INT8U      prio;
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; if (OSIntNesting > 0u) {                          /* See if called from ISR ...                    */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMutexPost_1
; return (OS_ERR_POST_ISR);                     /* ... can't POST mutex from an ISR              */
       moveq     #5,D0
       bra       OSMutexPost_3
OSMutexPost_1:
; }
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; return (OS_ERR_PEVENT_NULL);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MUTEX) { /* Validate event block type                     */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #4,D0
       beq.s     OSMutexPost_4
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSMutexPost_3
OSMutexPost_4:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pcp  = (INT8U)(pevent->OSEventCnt >> 8u);         /* Get priority ceiling priority of mutex        */
       move.l    D2,A0
       move.w    6(A0),D0
       lsr.w     #8,D0
       move.b    D0,D4
; prio = (INT8U)(pevent->OSEventCnt & OS_MUTEX_KEEP_LOWER_8);  /* Get owner's original priority      */
       move.l    D2,A0
       move.w    6(A0),D0
       and.w     #255,D0
       move.b    D0,D3
; if (OSTCBCur != (OS_TCB *)pevent->OSEventPtr) {   /* See if posting task owns the MUTEX            */
       move.l    D2,A0
       move.l    (A2),D0
       cmp.l     2(A0),D0
       beq.s     OSMutexPost_6
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NOT_MUTEX_OWNER);
       moveq     #100,D0
       bra       OSMutexPost_3
OSMutexPost_6:
; }
; if (pcp != OS_PRIO_MUTEX_CEIL_DIS) {
       cmp.b     #255,D4
       beq.s     OSMutexPost_8
; if (OSTCBCur->OSTCBPrio == pcp) {             /* Did we have to raise current task's priority? */
       move.l    (A2),A0
       cmp.b     52(A0),D4
       bne.s     OSMutexPost_10
; OSMutex_RdyAtPrio(OSTCBCur, prio);        /* Restore the task's original priority          */
       and.l     #255,D3
       move.l    D3,-(A7)
       move.l    (A2),-(A7)
       jsr       @ucos_ii_OSMutex_RdyAtPrio
       addq.w    #8,A7
OSMutexPost_10:
; }
; OSTCBPrioTbl[pcp] = OS_TCB_RESERVED;          /* Reserve table entry                           */
       and.l     #255,D4
       move.l    D4,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    #1,0(A0,D0.L)
OSMutexPost_8:
; }
; if (pevent->OSEventGrp != 0u) {                   /* Any task waiting for the mutex?               */
       move.l    D2,A0
       move.b    8(A0),D0
       beq       OSMutexPost_12
; /* Yes, Make HPT waiting for mutex ready         */
; prio                = OS_EventTaskRdy(pevent, (void *)0, OS_STAT_MUTEX, OS_STAT_PEND_OK);
       clr.l     -(A7)
       pea       16
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       move.b    D0,D3
; pevent->OSEventCnt &= OS_MUTEX_KEEP_UPPER_8;  /*      Save priority of mutex's new owner       */
       move.l    D2,A0
       and.w     #65280,6(A0)
; pevent->OSEventCnt |= prio;
       move.l    D2,A0
       and.w     #255,D3
       or.w      D3,6(A0)
; pevent->OSEventPtr  = OSTCBPrioTbl[prio];     /*      Link to new mutex owner's OS_TCB         */
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    D2,A1
       move.l    0(A0,D0.L),2(A1)
; if ((pcp  != OS_PRIO_MUTEX_CEIL_DIS) &&
       cmp.b     #255,D4
       beq.s     OSMutexPost_14
       cmp.b     D4,D3
       bhi.s     OSMutexPost_14
; (prio <= pcp)) {                          /*      PCP 'must' have a SMALLER prio ...       */
; OS_EXIT_CRITICAL();                       /*      ... than current task!                   */
       dc.w      18143
; OS_Sched();                               /*      Find highest priority task ready to run  */
       jsr       _OS_Sched
; return (OS_ERR_PCP_LOWER);
       moveq     #120,D0
       bra.s     OSMutexPost_3
OSMutexPost_14:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                               /*      Find highest priority task ready to run  */
       jsr       _OS_Sched
; return (OS_ERR_NONE);
       clr.b     D0
       bra.s     OSMutexPost_3
OSMutexPost_12:
; }
; }
; pevent->OSEventCnt |= OS_MUTEX_AVAILABLE;         /* No,  Mutex is now available                   */
       move.l    D2,A0
       or.w      #255,6(A0)
; pevent->OSEventPtr  = (void *)0;
       move.l    D2,A0
       clr.l     2(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSMutexPost_3:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                 QUERY A MUTUAL EXCLUSION SEMAPHORE
; *
; * Description: This function obtains information about a mutex
; *
; * Arguments  : pevent          is a pointer to the event control block associated with the desired mutex
; *
; *              p_mutex_data    is a pointer to a structure that will contain information about the mutex
; *
; * Returns    : OS_ERR_NONE          The call was successful and the message was sent
; *              OS_ERR_QUERY_ISR     If you called this function from an ISR
; *              OS_ERR_PEVENT_NULL   If 'pevent'       is a NULL pointer
; *              OS_ERR_PDATA_NULL    If 'p_mutex_data' is a NULL pointer
; *              OS_ERR_EVENT_TYPE    If you are attempting to obtain data from a non mutex.
; *********************************************************************************************************
; */
; #if OS_MUTEX_QUERY_EN > 0u
; INT8U  OSMutexQuery (OS_EVENT       *pevent,
; OS_MUTEX_DATA  *p_mutex_data)
; {
       xdef      _OSMutexQuery
_OSMutexQuery:
       link      A6,#-8
       movem.l   D2/D3/D4,-(A7)
       move.l    12(A6),D2
       move.l    8(A6),D3
; INT8U       i;
; OS_PRIO    *psrc;
; OS_PRIO    *pdest;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR   cpu_sr = 0u;
; #endif
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSMutexQuery_1
; return (OS_ERR_QUERY_ISR);                         /* ... can't QUERY mutex from an ISR        */
       moveq     #6,D0
       bra       OSMutexQuery_3
OSMutexQuery_1:
; }
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; return (OS_ERR_PEVENT_NULL);
; }
; if (p_mutex_data == (OS_MUTEX_DATA *)0) {              /* Validate 'p_mutex_data'                  */
; return (OS_ERR_PDATA_NULL);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_MUTEX) {      /* Validate event block type                */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #4,D0
       beq.s     OSMutexQuery_4
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSMutexQuery_3
OSMutexQuery_4:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; p_mutex_data->OSMutexPCP  = (INT8U)(pevent->OSEventCnt >> 8u);
       move.l    D3,A0
       move.w    6(A0),D0
       lsr.w     #8,D0
       move.l    D2,A0
       move.b    D0,11(A0)
; p_mutex_data->OSOwnerPrio = (INT8U)(pevent->OSEventCnt & OS_MUTEX_KEEP_LOWER_8);
       move.l    D3,A0
       move.w    6(A0),D0
       and.w     #255,D0
       move.l    D2,A0
       move.b    D0,10(A0)
; if (p_mutex_data->OSOwnerPrio == 0xFFu) {
       move.l    D2,A0
       move.b    10(A0),D0
       cmp.b     #255,D0
       bne.s     OSMutexQuery_6
; p_mutex_data->OSValue = OS_TRUE;
       move.l    D2,A0
       move.b    #1,9(A0)
       bra.s     OSMutexQuery_7
OSMutexQuery_6:
; } else {
; p_mutex_data->OSValue = OS_FALSE;
       move.l    D2,A0
       clr.b     9(A0)
OSMutexQuery_7:
; }
; p_mutex_data->OSEventGrp  = pevent->OSEventGrp;        /* Copy wait list                           */
       move.l    D3,A0
       move.l    D2,A1
       move.b    8(A0),8(A1)
; psrc                      = &pevent->OSEventTbl[0];
       moveq     #10,D0
       add.l     D3,D0
       move.l    D0,-8(A6)
; pdest                     = &p_mutex_data->OSEventTbl[0];
       move.l    D2,-4(A6)
; for (i = 0u; i < OS_EVENT_TBL_SIZE; i++) {
       clr.b     D4
OSMutexQuery_8:
       cmp.b     #8,D4
       bhs.s     OSMutexQuery_10
; *pdest++ = *psrc++;
       move.l    -8(A6),A0
       addq.l    #1,-8(A6)
       move.l    -4(A6),A1
       addq.l    #1,-4(A6)
       move.b    (A0),(A1)
       addq.b    #1,D4
       bra       OSMutexQuery_8
OSMutexQuery_10:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSMutexQuery_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; #endif                                                     /* OS_MUTEX_QUERY_EN                        */
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                            RESTORE A TASK BACK TO ITS ORIGINAL PRIORITY
; *
; * Description: This function makes a task ready at the specified priority
; *
; * Arguments  : ptcb            is a pointer to OS_TCB of the task to make ready
; *
; *              prio            is the desired priority
; *
; * Returns    : none
; *********************************************************************************************************
; */
; static  void  OSMutex_RdyAtPrio (OS_TCB  *ptcb,
; INT8U    prio)
; {
@ucos_ii_OSMutex_RdyAtPrio:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       move.l    8(A6),D2
       move.b    15(A6),D3
       and.l     #255,D3
       lea       _OSRdyTbl.L,A2
; INT8U  y;
; y            =  ptcb->OSTCBY;                          /* Remove owner from ready list at 'pcp'    */
       move.l    D2,A0
       move.b    54(A0),D4
; OSRdyTbl[y] &= (OS_PRIO)~ptcb->OSTCBBitX;
       and.l     #255,D4
       move.l    D2,A0
       move.b    55(A0),D0
       not.b     D0
       and.b     D0,0(A2,D4.L)
; if (OSRdyTbl[y] == 0u) {
       and.l     #255,D4
       move.b    0(A2,D4.L),D0
       bne.s     @ucos_ii_OSMutex_RdyAtPrio_1
; OSRdyGrp &= (OS_PRIO)~ptcb->OSTCBBitY;
       move.l    D2,A0
       move.b    56(A0),D0
       not.b     D0
       and.b     D0,_OSRdyGrp.L
@ucos_ii_OSMutex_RdyAtPrio_1:
; }
; ptcb->OSTCBPrio         = prio;
       move.l    D2,A0
       move.b    D3,52(A0)
; OSPrioCur               = prio;                        /* The current task is now at this priority */
       move.b    D3,_OSPrioCur.L
; #if OS_LOWEST_PRIO <= 63u
; ptcb->OSTCBY            = (INT8U)((INT8U)(prio >> 3u) & 0x07u);
       move.b    D3,D0
       lsr.b     #3,D0
       and.b     #7,D0
       move.l    D2,A0
       move.b    D0,54(A0)
; ptcb->OSTCBX            = (INT8U)(prio & 0x07u);
       move.b    D3,D0
       and.b     #7,D0
       move.l    D2,A0
       move.b    D0,53(A0)
; #else
; ptcb->OSTCBY            = (INT8U)((INT8U)(prio >> 4u) & 0x0Fu);
; ptcb->OSTCBX            = (INT8U) (prio & 0x0Fu);
; #endif
; ptcb->OSTCBBitY         = (OS_PRIO)(1uL << ptcb->OSTCBY);
       moveq     #1,D0
       move.l    D2,A0
       move.b    54(A0),D1
       and.l     #255,D1
       lsl.l     D1,D0
       move.l    D2,A0
       move.b    D0,56(A0)
; ptcb->OSTCBBitX         = (OS_PRIO)(1uL << ptcb->OSTCBX);
       moveq     #1,D0
       move.l    D2,A0
       move.b    53(A0),D1
       and.l     #255,D1
       lsl.l     D1,D0
       move.l    D2,A0
       move.b    D0,55(A0)
; OSRdyGrp               |= ptcb->OSTCBBitY;             /* Make task ready at original priority     */
       move.l    D2,A0
       move.b    56(A0),D0
       or.b      D0,_OSRdyGrp.L
; OSRdyTbl[ptcb->OSTCBY] |= ptcb->OSTCBBitX;
       move.l    D2,A0
       move.b    54(A0),D0
       and.l     #255,D0
       move.l    D2,A0
       move.b    55(A0),D1
       or.b      D1,0(A2,D0.L)
; OSTCBPrioTbl[prio]      = ptcb;
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    D2,0(A0,D0.L)
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                        MESSAGE QUEUE MANAGEMENT
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : OS_Q.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #include <ucos_ii.h>
; #endif
; #if (OS_Q_EN > 0u) && (OS_MAX_QS > 0u)
; /*
; *********************************************************************************************************
; *                                      ACCEPT MESSAGE FROM QUEUE
; *
; * Description: This function checks the queue to see if a message is available.  Unlike OSQPend(),
; *              OSQAccept() does not suspend the calling task if a message is not available.
; *
; * Arguments  : pevent        is a pointer to the event control block
; *
; *              perr          is a pointer to where an error message will be deposited.  Possible error
; *                            messages are:
; *
; *                            OS_ERR_NONE         The call was successful and your task received a
; *                                                message.
; *                            OS_ERR_EVENT_TYPE   You didn't pass a pointer to a queue
; *                            OS_ERR_PEVENT_NULL  If 'pevent' is a NULL pointer
; *                            OS_ERR_Q_EMPTY      The queue did not contain any messages
; *
; * Returns    : != (void *)0  is the message in the queue if one is available.  The message is removed
; *                            from the so the next time OSQAccept() is called, the queue will contain
; *                            one less entry.
; *              == (void *)0  if you received a NULL pointer message
; *                            if the queue is empty or,
; *                            if 'pevent' is a NULL pointer or,
; *                            if you passed an invalid event type
; *
; * Note(s)    : As of V2.60, you can now pass NULL pointers through queues.  Because of this, the argument
; *              'perr' has been added to the API to tell you about the outcome of the call.
; *********************************************************************************************************
; */
; #if OS_Q_ACCEPT_EN > 0u
; void  *OSQAccept (OS_EVENT  *pevent,
; INT8U     *perr)
; {
       xdef      _OSQAccept
_OSQAccept:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
       move.l    12(A6),D4
; void      *pmsg;
; OS_Q      *pq;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((void *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {               /* Validate 'pevent'                                  */
; *perr = OS_ERR_PEVENT_NULL;
; return ((void *)0);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_Q) {/* Validate event block type                          */
       move.l    8(A6),A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     OSQAccept_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return ((void *)0);
       clr.l     D0
       bra       OSQAccept_3
OSQAccept_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pq = (OS_Q *)pevent->OSEventPtr;             /* Point at queue control block                       */
       move.l    8(A6),A0
       move.l    2(A0),D2
; if (pq->OSQEntries > 0u) {                   /* See if any messages in the queue                   */
       move.l    D2,A0
       move.w    22(A0),D0
       cmp.w     #0,D0
       bls       OSQAccept_4
; pmsg = *pq->OSQOut++;                    /* Yes, extract oldest message from the queue         */
       move.l    D2,D0
       add.l     #16,D0
       move.l    D0,A0
       move.l    (A0),A1
       addq.l    #4,(A0)
       move.l    (A1),D3
; pq->OSQEntries--;                        /* Update the number of entries in the queue          */
       move.l    D2,D0
       add.l     #22,D0
       move.l    D0,A0
       subq.w    #1,(A0)
; if (pq->OSQOut == pq->OSQEnd) {          /* Wrap OUT pointer if we are at the end of the queue */
       move.l    D2,A0
       move.l    D2,A1
       move.l    16(A0),D0
       cmp.l     8(A1),D0
       bne.s     OSQAccept_6
; pq->OSQOut = pq->OSQStart;
       move.l    D2,A0
       move.l    D2,A1
       move.l    4(A0),16(A1)
OSQAccept_6:
; }
; *perr = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
       bra.s     OSQAccept_5
OSQAccept_4:
; } else {
; *perr = OS_ERR_Q_EMPTY;
       move.l    D4,A0
       move.b    #31,(A0)
; pmsg  = (void *)0;                       /* Queue is empty                                     */
       clr.l     D3
OSQAccept_5:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (pmsg);                               /* Return message received (or NULL)                  */
       move.l    D3,D0
OSQAccept_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       CREATE A MESSAGE QUEUE
; *
; * Description: This function creates a message queue if free event control blocks are available.
; *
; * Arguments  : start         is a pointer to the base address of the message queue storage area.  The
; *                            storage area MUST be declared as an array of pointers to 'void' as follows
; *
; *                            void *MessageStorage[size]
; *
; *              size          is the number of elements in the storage area
; *
; * Returns    : != (OS_EVENT *)0  is a pointer to the event control clock (OS_EVENT) associated with the
; *                                created queue
; *              == (OS_EVENT *)0  if no event control blocks were available or an error was detected
; *********************************************************************************************************
; */
; OS_EVENT  *OSQCreate (void    **start,
; INT16U    size)
; {
       xdef      _OSQCreate
_OSQCreate:
       link      A6,#0
       movem.l   D2/D3/D4/A2/A3,-(A7)
       lea       _OSEventFreeList.L,A2
       move.l    8(A6),D4
       lea       _OSQFreeList.L,A3
; OS_EVENT  *pevent;
; OS_Q      *pq;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; if (OSSafetyCriticalStartFlag == OS_TRUE) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_EVENT *)0);
; }
; #endif
; if (OSIntNesting > 0u) {                     /* See if called from ISR ...                         */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSQCreate_1
; return ((OS_EVENT *)0);                  /* ... can't CREATE from an ISR                       */
       clr.l     D0
       bra       OSQCreate_3
OSQCreate_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pevent = OSEventFreeList;                    /* Get next free event control block                  */
       move.l    (A2),D2
; if (OSEventFreeList != (OS_EVENT *)0) {      /* See if pool of free ECB pool was empty             */
       move.l    (A2),D0
       beq.s     OSQCreate_4
; OSEventFreeList = (OS_EVENT *)OSEventFreeList->OSEventPtr;
       move.l    (A2),A0
       move.l    2(A0),(A2)
OSQCreate_4:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (pevent != (OS_EVENT *)0) {               /* See if we have an event control block              */
       tst.l     D2
       beq       OSQCreate_9
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pq = OSQFreeList;                        /* Get a free queue control block                     */
       move.l    (A3),D3
; if (pq != (OS_Q *)0) {                   /* Were we able to get a queue control block ?        */
       tst.l     D3
       beq       OSQCreate_8
; OSQFreeList            = OSQFreeList->OSQPtr; /* Yes, Adjust free list pointer to next free*/
       move.l    (A3),A0
       move.l    (A0),(A3)
; OS_EXIT_CRITICAL();
       dc.w      18143
; pq->OSQStart           = start;               /*      Initialize the queue                 */
       move.l    D3,A0
       move.l    D4,4(A0)
; pq->OSQEnd             = &start[size];
       move.l    D4,D0
       move.w    14(A6),D1
       and.l     #65535,D1
       lsl.l     #2,D1
       add.l     D1,D0
       move.l    D3,A0
       move.l    D0,8(A0)
; pq->OSQIn              = start;
       move.l    D3,A0
       move.l    D4,12(A0)
; pq->OSQOut             = start;
       move.l    D3,A0
       move.l    D4,16(A0)
; pq->OSQSize            = size;
       move.l    D3,A0
       move.w    14(A6),20(A0)
; pq->OSQEntries         = 0u;
       move.l    D3,A0
       clr.w     22(A0)
; pevent->OSEventType    = OS_EVENT_TYPE_Q;
       move.l    D2,A0
       move.b    #2,(A0)
; pevent->OSEventCnt     = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; pevent->OSEventPtr     = pq;
       move.l    D2,A0
       move.l    D3,2(A0)
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; OS_EventWaitListInit(pevent);                 /*      Initialize the wait list             */
       move.l    D2,-(A7)
       jsr       _OS_EventWaitListInit
       addq.w    #4,A7
       bra.s     OSQCreate_9
OSQCreate_8:
; } else {
; pevent->OSEventPtr = (void *)OSEventFreeList; /* No,  Return event control block on error  */
       move.l    D2,A0
       move.l    (A2),2(A0)
; OSEventFreeList    = pevent;
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; pevent = (OS_EVENT *)0;
       clr.l     D2
OSQCreate_9:
; }
; }
; return (pevent);
       move.l    D2,D0
OSQCreate_3:
       movem.l   (A7)+,D2/D3/D4/A2/A3
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       DELETE A MESSAGE QUEUE
; *
; * Description: This function deletes a message queue and readies all tasks pending on the queue.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired
; *                            queue.
; *
; *              opt           determines delete options as follows:
; *                            opt == OS_DEL_NO_PEND   Delete the queue ONLY if no task pending
; *                            opt == OS_DEL_ALWAYS    Deletes the queue even if tasks are waiting.
; *                                                    In this case, all the tasks pending will be readied.
; *
; *              perr          is a pointer to an error code that can contain one of the following values:
; *                            OS_ERR_NONE             The call was successful and the queue was deleted
; *                            OS_ERR_DEL_ISR          If you tried to delete the queue from an ISR
; *                            OS_ERR_INVALID_OPT      An invalid option was specified
; *                            OS_ERR_TASK_WAITING     One or more tasks were waiting on the queue
; *                            OS_ERR_EVENT_TYPE       If you didn't pass a pointer to a queue
; *                            OS_ERR_PEVENT_NULL      If 'pevent' is a NULL pointer.
; *
; * Returns    : pevent        upon error
; *              (OS_EVENT *)0 if the queue was successfully deleted.
; *
; * Note(s)    : 1) This function must be used with care.  Tasks that would normally expect the presence of
; *                 the queue MUST check the return code of OSQPend().
; *              2) OSQAccept() callers will not know that the intended queue has been deleted unless
; *                 they check 'pevent' to see that it's a NULL pointer.
; *              3) This call can potentially disable interrupts for a long time.  The interrupt disable
; *                 time is directly proportional to the number of tasks waiting on the queue.
; *              4) Because ALL tasks pending on the queue will be readied, you MUST be careful in
; *                 applications where the queue is used for mutual exclusion because the resource(s)
; *                 will no longer be guarded by the queue.
; *              5) If the storage for the message queue was allocated dynamically (i.e. using a malloc()
; *                 type call) then your application MUST release the memory storage by call the counterpart
; *                 call of the dynamic allocation scheme used.  If the queue storage was created statically
; *                 then, the storage can be reused.
; *              6) All tasks that were waiting for the queue will be readied and returned an 
; *                 OS_ERR_PEND_ABORT if OSQDel() was called with OS_DEL_ALWAYS
; *********************************************************************************************************
; */
; #if OS_Q_DEL_EN > 0u
; OS_EVENT  *OSQDel (OS_EVENT  *pevent,
; INT8U      opt,
; INT8U     *perr)
; {
       xdef      _OSQDel
_OSQDel:
       link      A6,#0
       movem.l   D2/D3/D4/D5/D6/A2/A3,-(A7)
       move.l    8(A6),D2
       move.l    16(A6),D4
       lea       _OSEventFreeList.L,A2
       lea       _OSQFreeList.L,A3
; BOOLEAN    tasks_waiting;
; OS_EVENT  *pevent_return;
; OS_Q      *pq;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_EVENT *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; *perr = OS_ERR_PEVENT_NULL;
; return (pevent);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_Q) {          /* Validate event block type                */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     OSQDel_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return (pevent);
       move.l    D2,D0
       bra       OSQDel_3
OSQDel_1:
; }
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSQDel_4
; *perr = OS_ERR_DEL_ISR;                            /* ... can't DELETE from an ISR             */
       move.l    D4,A0
       move.b    #15,(A0)
; return (pevent);
       move.l    D2,D0
       bra       OSQDel_3
OSQDel_4:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                        /* See if any tasks waiting on queue        */
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSQDel_6
; tasks_waiting = OS_TRUE;                           /* Yes                                      */
       moveq     #1,D6
       bra.s     OSQDel_7
OSQDel_6:
; } else {
; tasks_waiting = OS_FALSE;                          /* No                                       */
       clr.b     D6
OSQDel_7:
; }
; switch (opt) {
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq       OSQDel_11
       bhi       OSQDel_8
       tst.l     D0
       beq.s     OSQDel_10
       bra       OSQDel_8
OSQDel_10:
; case OS_DEL_NO_PEND:                               /* Delete queue only if no task waiting     */
; if (tasks_waiting == OS_FALSE) {
       tst.b     D6
       bne       OSQDel_13
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; pq                     = (OS_Q *)pevent->OSEventPtr;  /* Return OS_Q to free list     */
       move.l    D2,A0
       move.l    2(A0),D3
; pq->OSQPtr             = OSQFreeList;
       move.l    D3,A0
       move.l    (A3),(A0)
; OSQFreeList            = pq;
       move.l    D3,(A3)
; pevent->OSEventType    = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent->OSEventPtr     = OSEventFreeList; /* Return Event Control Block to free list  */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pevent->OSEventCnt     = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; OSEventFreeList        = pevent;          /* Get next free event control block        */
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                  = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; pevent_return          = (OS_EVENT *)0;   /* Queue has been deleted                   */
       clr.l     D5
       bra.s     OSQDel_14
OSQDel_13:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                  = OS_ERR_TASK_WAITING;
       move.l    D4,A0
       move.b    #73,(A0)
; pevent_return          = pevent;
       move.l    D2,D5
OSQDel_14:
; }
; break;
       bra       OSQDel_9
OSQDel_11:
; case OS_DEL_ALWAYS:                                /* Always delete the queue                  */
; while (pevent->OSEventGrp != 0u) {            /* Ready ALL tasks waiting for queue        */
OSQDel_15:
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSQDel_17
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_Q, OS_STAT_PEND_ABORT);
       pea       2
       pea       4
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
       bra       OSQDel_15
OSQDel_17:
; }
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; pq                     = (OS_Q *)pevent->OSEventPtr;   /* Return OS_Q to free list        */
       move.l    D2,A0
       move.l    2(A0),D3
; pq->OSQPtr             = OSQFreeList;
       move.l    D3,A0
       move.l    (A3),(A0)
; OSQFreeList            = pq;
       move.l    D3,(A3)
; pevent->OSEventType    = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent->OSEventPtr     = OSEventFreeList;     /* Return Event Control Block to free list  */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pevent->OSEventCnt     = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; OSEventFreeList        = pevent;              /* Get next free event control block        */
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (tasks_waiting == OS_TRUE) {               /* Reschedule only if task(s) were waiting  */
       cmp.b     #1,D6
       bne.s     OSQDel_18
; OS_Sched();                               /* Find highest priority task ready to run  */
       jsr       _OS_Sched
OSQDel_18:
; }
; *perr                  = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; pevent_return          = (OS_EVENT *)0;       /* Queue has been deleted                   */
       clr.l     D5
; break;
       bra.s     OSQDel_9
OSQDel_8:
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                  = OS_ERR_INVALID_OPT;
       move.l    D4,A0
       move.b    #7,(A0)
; pevent_return          = pevent;
       move.l    D2,D5
; break;
OSQDel_9:
; }
; return (pevent_return);
       move.l    D5,D0
OSQDel_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                             FLUSH QUEUE
; *
; * Description : This function is used to flush the contents of the message queue.
; *
; * Arguments   : none
; *
; * Returns     : OS_ERR_NONE         upon success
; *               OS_ERR_EVENT_TYPE   If you didn't pass a pointer to a queue
; *               OS_ERR_PEVENT_NULL  If 'pevent' is a NULL pointer
; *
; * WARNING     : You should use this function with great care because, when to flush the queue, you LOOSE
; *               the references to what the queue entries are pointing to and thus, you could cause
; *               'memory leaks'.  In other words, the data you are pointing to that's being referenced
; *               by the queue entries should, most likely, need to be de-allocated (i.e. freed).
; *********************************************************************************************************
; */
; #if OS_Q_FLUSH_EN > 0u
; INT8U  OSQFlush (OS_EVENT *pevent)
; {
       xdef      _OSQFlush
_OSQFlush:
       link      A6,#0
       move.l    D2,-(A7)
; OS_Q      *pq;
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; return (OS_ERR_PEVENT_NULL);
; }
; if (pevent->OSEventType != OS_EVENT_TYPE_Q) {     /* Validate event block type                     */
; return (OS_ERR_EVENT_TYPE);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pq             = (OS_Q *)pevent->OSEventPtr;      /* Point to queue storage structure              */
       move.l    8(A6),A0
       move.l    2(A0),D2
; pq->OSQIn      = pq->OSQStart;
       move.l    D2,A0
       move.l    D2,A1
       move.l    4(A0),12(A1)
; pq->OSQOut     = pq->OSQStart;
       move.l    D2,A0
       move.l    D2,A1
       move.l    4(A0),16(A1)
; pq->OSQEntries = 0u;
       move.l    D2,A0
       clr.w     22(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                    PEND ON A QUEUE FOR A MESSAGE
; *
; * Description: This function waits for a message to be sent to a queue
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired queue
; *
; *              timeout       is an optional timeout period (in clock ticks).  If non-zero, your task will
; *                            wait for a message to arrive at the queue up to the amount of time
; *                            specified by this argument.  If you specify 0, however, your task will wait
; *                            forever at the specified queue or, until a message arrives.
; *
; *              perr          is a pointer to where an error message will be deposited.  Possible error
; *                            messages are:
; *
; *                            OS_ERR_NONE         The call was successful and your task received a
; *                                                message.
; *                            OS_ERR_TIMEOUT      A message was not received within the specified 'timeout'.
; *                            OS_ERR_PEND_ABORT   The wait on the queue was aborted.
; *                            OS_ERR_EVENT_TYPE   You didn't pass a pointer to a queue
; *                            OS_ERR_PEVENT_NULL  If 'pevent' is a NULL pointer
; *                            OS_ERR_PEND_ISR     If you called this function from an ISR and the result
; *                                                would lead to a suspension.
; *                            OS_ERR_PEND_LOCKED  If you called this function with the scheduler is locked
; *
; * Returns    : != (void *)0  is a pointer to the message received
; *              == (void *)0  if you received a NULL pointer message or,
; *                            if no message was received or,
; *                            if 'pevent' is a NULL pointer or,
; *                            if you didn't pass a pointer to a queue.
; *
; * Note(s)    : As of V2.60, this function allows you to receive NULL pointer messages.
; *********************************************************************************************************
; */
; void  *OSQPend (OS_EVENT  *pevent,
; INT32U     timeout,
; INT8U     *perr)
; {
       xdef      _OSQPend
_OSQPend:
       link      A6,#0
       movem.l   D2/D3/D4/D5/A2,-(A7)
       lea       _OSTCBCur.L,A2
       move.l    16(A6),D3
       move.l    8(A6),D5
; void      *pmsg;
; OS_Q      *pq;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((void *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {               /* Validate 'pevent'                                  */
; *perr = OS_ERR_PEVENT_NULL;
; return ((void *)0);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_Q) {/* Validate event block type                          */
       move.l    D5,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     OSQPend_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D3,A0
       move.b    #1,(A0)
; return ((void *)0);
       clr.l     D0
       bra       OSQPend_3
OSQPend_1:
; }
; if (OSIntNesting > 0u) {                     /* See if called from ISR ...                         */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSQPend_4
; *perr = OS_ERR_PEND_ISR;                 /* ... can't PEND from an ISR                         */
       move.l    D3,A0
       move.b    #2,(A0)
; return ((void *)0);
       clr.l     D0
       bra       OSQPend_3
OSQPend_4:
; }
; if (OSLockNesting > 0u) {                    /* See if called with scheduler locked ...            */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSQPend_6
; *perr = OS_ERR_PEND_LOCKED;              /* ... can't PEND when locked                         */
       move.l    D3,A0
       move.b    #13,(A0)
; return ((void *)0);
       clr.l     D0
       bra       OSQPend_3
OSQPend_6:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pq = (OS_Q *)pevent->OSEventPtr;             /* Point at queue control block                       */
       move.l    D5,A0
       move.l    2(A0),D2
; if (pq->OSQEntries > 0u) {                   /* See if any messages in the queue                   */
       move.l    D2,A0
       move.w    22(A0),D0
       cmp.w     #0,D0
       bls       OSQPend_8
; pmsg = *pq->OSQOut++;                    /* Yes, extract oldest message from the queue         */
       move.l    D2,D0
       add.l     #16,D0
       move.l    D0,A0
       move.l    (A0),A1
       addq.l    #4,(A0)
       move.l    (A1),D4
; pq->OSQEntries--;                        /* Update the number of entries in the queue          */
       move.l    D2,D0
       add.l     #22,D0
       move.l    D0,A0
       subq.w    #1,(A0)
; if (pq->OSQOut == pq->OSQEnd) {          /* Wrap OUT pointer if we are at the end of the queue */
       move.l    D2,A0
       move.l    D2,A1
       move.l    16(A0),D0
       cmp.l     8(A1),D0
       bne.s     OSQPend_10
; pq->OSQOut = pq->OSQStart;
       move.l    D2,A0
       move.l    D2,A1
       move.l    4(A0),16(A1)
OSQPend_10:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; return (pmsg);                           /* Return message received                            */
       move.l    D4,D0
       bra       OSQPend_3
OSQPend_8:
; }
; OSTCBCur->OSTCBStat     |= OS_STAT_Q;        /* Task will have to pend for a message to be posted  */
       move.l    (A2),A0
       or.b      #4,50(A0)
; OSTCBCur->OSTCBStatPend  = OS_STAT_PEND_OK;
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBDly       = timeout;          /* Load timeout into TCB                              */
       move.l    (A2),A0
       move.l    12(A6),46(A0)
; OS_EventTaskWait(pevent);                    /* Suspend task until event or timeout occurs         */
       move.l    D5,-(A7)
       jsr       _OS_EventTaskWait
       addq.w    #4,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                  /* Find next highest priority task ready to run       */
       jsr       _OS_Sched
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; switch (OSTCBCur->OSTCBStatPend) {                /* See if we timed-out or aborted                */
       move.l    (A2),A0
       move.b    51(A0),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq       OSQPend_16
       bhi.s     OSQPend_18
       tst.l     D0
       beq.s     OSQPend_14
       bra.s     OSQPend_16
OSQPend_18:
       cmp.l     #2,D0
       beq.s     OSQPend_15
       bra.s     OSQPend_16
OSQPend_14:
; case OS_STAT_PEND_OK:                         /* Extract message from TCB (Put there by QPost) */
; pmsg =  OSTCBCur->OSTCBMsg;
       move.l    (A2),A0
       move.l    36(A0),D4
; *perr =  OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; break;
       bra.s     OSQPend_13
OSQPend_15:
; case OS_STAT_PEND_ABORT:
; pmsg = (void *)0;
       clr.l     D4
; *perr =  OS_ERR_PEND_ABORT;               /* Indicate that we aborted                      */
       move.l    D3,A0
       move.b    #14,(A0)
; break;
       bra.s     OSQPend_13
OSQPend_16:
; case OS_STAT_PEND_TO:
; default:
; OS_EventTaskRemove(OSTCBCur, pevent);
       move.l    D5,-(A7)
       move.l    (A2),-(A7)
       jsr       _OS_EventTaskRemove
       addq.w    #8,A7
; pmsg = (void *)0;
       clr.l     D4
; *perr =  OS_ERR_TIMEOUT;                  /* Indicate that we didn't get event within TO   */
       move.l    D3,A0
       move.b    #10,(A0)
; break;
OSQPend_13:
; }
; OSTCBCur->OSTCBStat          =  OS_STAT_RDY;      /* Set   task  status to ready                   */
       move.l    (A2),A0
       clr.b     50(A0)
; OSTCBCur->OSTCBStatPend      =  OS_STAT_PEND_OK;  /* Clear pend  status                            */
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBEventPtr      = (OS_EVENT  *)0;    /* Clear event pointers                          */
       move.l    (A2),A0
       clr.l     28(A0)
; #if (OS_EVENT_MULTI_EN > 0u)
; OSTCBCur->OSTCBEventMultiPtr = (OS_EVENT **)0;
       move.l    (A2),A0
       clr.l     32(A0)
; #endif
; OSTCBCur->OSTCBMsg           = (void      *)0;    /* Clear  received message                       */
       move.l    (A2),A0
       clr.l     36(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (pmsg);                                    /* Return received message                       */
       move.l    D4,D0
OSQPend_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                  ABORT WAITING ON A MESSAGE QUEUE
; *
; * Description: This function aborts & readies any tasks currently waiting on a queue.  This function
; *              should be used to fault-abort the wait on the queue, rather than to normally signal
; *              the queue via OSQPost(), OSQPostFront() or OSQPostOpt().
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired queue.
; *
; *              opt           determines the type of ABORT performed:
; *                            OS_PEND_OPT_NONE         ABORT wait for a single task (HPT) waiting on the
; *                                                     queue
; *                            OS_PEND_OPT_BROADCAST    ABORT wait for ALL tasks that are  waiting on the
; *                                                     queue
; *
; *              perr          is a pointer to where an error message will be deposited.  Possible error
; *                            messages are:
; *
; *                            OS_ERR_NONE         No tasks were     waiting on the queue.
; *                            OS_ERR_PEND_ABORT   At least one task waiting on the queue was readied
; *                                                and informed of the aborted wait; check return value
; *                                                for the number of tasks whose wait on the queue
; *                                                was aborted.
; *                            OS_ERR_EVENT_TYPE   If you didn't pass a pointer to a queue.
; *                            OS_ERR_PEVENT_NULL  If 'pevent' is a NULL pointer.
; *
; * Returns    : == 0          if no tasks were waiting on the queue, or upon error.
; *              >  0          if one or more tasks waiting on the queue are now readied and informed.
; *********************************************************************************************************
; */
; #if OS_Q_PEND_ABORT_EN > 0u
; INT8U  OSQPendAbort (OS_EVENT  *pevent,
; INT8U      opt,
; INT8U     *perr)
; {
       xdef      _OSQPendAbort
_OSQPendAbort:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
       move.l    8(A6),D2
       move.l    16(A6),D4
; INT8U      nbr_tasks;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; *perr = OS_ERR_PEVENT_NULL;
; return (0u);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_Q) {          /* Validate event block type                */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     OSQPendAbort_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return (0u);
       clr.b     D0
       bra       OSQPendAbort_3
OSQPendAbort_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                        /* See if any task waiting on queue?        */
       move.l    D2,A0
       move.b    8(A0),D0
       beq       OSQPendAbort_4
; nbr_tasks = 0u;
       clr.b     D3
; switch (opt) {
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq.s     OSQPendAbort_8
       bhi       OSQPendAbort_9
       tst.l     D0
       beq.s     OSQPendAbort_9
       bra.s     OSQPendAbort_9
OSQPendAbort_8:
; case OS_PEND_OPT_BROADCAST:                    /* Do we need to abort ALL waiting tasks?   */
; while (pevent->OSEventGrp != 0u) {        /* Yes, ready ALL tasks waiting on queue    */
OSQPendAbort_11:
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSQPendAbort_13
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_Q, OS_STAT_PEND_ABORT);
       pea       2
       pea       4
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; nbr_tasks++;
       addq.b    #1,D3
       bra       OSQPendAbort_11
OSQPendAbort_13:
; }
; break;
       bra.s     OSQPendAbort_7
OSQPendAbort_9:
; case OS_PEND_OPT_NONE:
; default:                                       /* No,  ready HPT       waiting on queue    */
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_Q, OS_STAT_PEND_ABORT);
       pea       2
       pea       4
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; nbr_tasks++;
       addq.b    #1,D3
; break;
OSQPendAbort_7:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                        /* Find HPT ready to run                    */
       jsr       _OS_Sched
; *perr = OS_ERR_PEND_ABORT;
       move.l    D4,A0
       move.b    #14,(A0)
; return (nbr_tasks);
       move.b    D3,D0
       bra.s     OSQPendAbort_3
OSQPendAbort_4:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; return (0u);                                           /* No tasks waiting on queue                */
       clr.b     D0
OSQPendAbort_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       POST MESSAGE TO A QUEUE
; *
; * Description: This function sends a message to a queue
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired queue
; *
; *              pmsg          is a pointer to the message to send.
; *
; * Returns    : OS_ERR_NONE           The call was successful and the message was sent
; *              OS_ERR_Q_FULL         If the queue cannot accept any more messages because it is full.
; *              OS_ERR_EVENT_TYPE     If you didn't pass a pointer to a queue.
; *              OS_ERR_PEVENT_NULL    If 'pevent' is a NULL pointer
; *
; * Note(s)    : As of V2.60, this function allows you to send NULL pointer messages.
; *********************************************************************************************************
; */
; #if OS_Q_POST_EN > 0u
; INT8U  OSQPost (OS_EVENT  *pevent,
; void      *pmsg)
; {
       xdef      _OSQPost
_OSQPost:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    8(A6),D3
; OS_Q      *pq;
; #if OS_CRITICAL_METHOD == 3u                           /* Allocate storage for CPU status register     */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                     /* Validate 'pevent'                            */
; return (OS_ERR_PEVENT_NULL);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_Q) {      /* Validate event block type                    */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     OSQPost_1
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSQPost_3
OSQPost_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                    /* See if any task pending on queue             */
       move.l    D3,A0
       move.b    8(A0),D0
       beq.s     OSQPost_4
; /* Ready highest priority task waiting on event */
; (void)OS_EventTaskRdy(pevent, pmsg, OS_STAT_Q, OS_STAT_PEND_OK);
       clr.l     -(A7)
       pea       4
       move.l    12(A6),-(A7)
       move.l    D3,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                    /* Find highest priority task ready to run      */
       jsr       _OS_Sched
; return (OS_ERR_NONE);
       clr.b     D0
       bra       OSQPost_3
OSQPost_4:
; }
; pq = (OS_Q *)pevent->OSEventPtr;                   /* Point to queue control block                 */
       move.l    D3,A0
       move.l    2(A0),D2
; if (pq->OSQEntries >= pq->OSQSize) {               /* Make sure queue is not full                  */
       move.l    D2,A0
       move.l    D2,A1
       move.w    22(A0),D0
       cmp.w     20(A1),D0
       blo.s     OSQPost_6
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_Q_FULL);
       moveq     #30,D0
       bra       OSQPost_3
OSQPost_6:
; }
; *pq->OSQIn++ = pmsg;                               /* Insert message into queue                    */
       move.l    D2,D0
       add.l     #12,D0
       move.l    D0,A0
       move.l    (A0),A1
       addq.l    #4,(A0)
       move.l    12(A6),(A1)
; pq->OSQEntries++;                                  /* Update the nbr of entries in the queue       */
       move.l    D2,D0
       add.l     #22,D0
       move.l    D0,A0
       addq.w    #1,(A0)
; if (pq->OSQIn == pq->OSQEnd) {                     /* Wrap IN ptr if we are at end of queue        */
       move.l    D2,A0
       move.l    D2,A1
       move.l    12(A0),D0
       cmp.l     8(A1),D0
       bne.s     OSQPost_8
; pq->OSQIn = pq->OSQStart;
       move.l    D2,A0
       move.l    D2,A1
       move.l    4(A0),12(A1)
OSQPost_8:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSQPost_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                POST MESSAGE TO THE FRONT OF A QUEUE
; *
; * Description: This function sends a message to a queue but unlike OSQPost(), the message is posted at
; *              the front instead of the end of the queue.  Using OSQPostFront() allows you to send
; *              'priority' messages.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired queue
; *
; *              pmsg          is a pointer to the message to send.
; *
; * Returns    : OS_ERR_NONE           The call was successful and the message was sent
; *              OS_ERR_Q_FULL         If the queue cannot accept any more messages because it is full.
; *              OS_ERR_EVENT_TYPE     If you didn't pass a pointer to a queue.
; *              OS_ERR_PEVENT_NULL    If 'pevent' is a NULL pointer
; *
; * Note(s)    : As of V2.60, this function allows you to send NULL pointer messages.
; *********************************************************************************************************
; */
; #if OS_Q_POST_FRONT_EN > 0u
; INT8U  OSQPostFront (OS_EVENT  *pevent,
; void      *pmsg)
; {
       xdef      _OSQPostFront
_OSQPostFront:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    8(A6),D3
; OS_Q      *pq;
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; return (OS_ERR_PEVENT_NULL);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_Q) {     /* Validate event block type                     */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     OSQPostFront_1
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSQPostFront_3
OSQPostFront_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                   /* See if any task pending on queue              */
       move.l    D3,A0
       move.b    8(A0),D0
       beq.s     OSQPostFront_4
; /* Ready highest priority task waiting on event  */
; (void)OS_EventTaskRdy(pevent, pmsg, OS_STAT_Q, OS_STAT_PEND_OK);
       clr.l     -(A7)
       pea       4
       move.l    12(A6),-(A7)
       move.l    D3,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                   /* Find highest priority task ready to run       */
       jsr       _OS_Sched
; return (OS_ERR_NONE);
       clr.b     D0
       bra       OSQPostFront_3
OSQPostFront_4:
; }
; pq = (OS_Q *)pevent->OSEventPtr;                  /* Point to queue control block                  */
       move.l    D3,A0
       move.l    2(A0),D2
; if (pq->OSQEntries >= pq->OSQSize) {              /* Make sure queue is not full                   */
       move.l    D2,A0
       move.l    D2,A1
       move.w    22(A0),D0
       cmp.w     20(A1),D0
       blo.s     OSQPostFront_6
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_Q_FULL);
       moveq     #30,D0
       bra       OSQPostFront_3
OSQPostFront_6:
; }
; if (pq->OSQOut == pq->OSQStart) {                 /* Wrap OUT ptr if we are at the 1st queue entry */
       move.l    D2,A0
       move.l    D2,A1
       move.l    16(A0),D0
       cmp.l     4(A1),D0
       bne.s     OSQPostFront_8
; pq->OSQOut = pq->OSQEnd;
       move.l    D2,A0
       move.l    D2,A1
       move.l    8(A0),16(A1)
OSQPostFront_8:
; }
; pq->OSQOut--;
       move.l    D2,D0
       add.l     #16,D0
       move.l    D0,A0
       subq.l    #4,(A0)
; *pq->OSQOut = pmsg;                               /* Insert message into queue                     */
       move.l    D2,A0
       move.l    16(A0),A0
       move.l    12(A6),(A0)
; pq->OSQEntries++;                                 /* Update the nbr of entries in the queue        */
       move.l    D2,D0
       add.l     #22,D0
       move.l    D0,A0
       addq.w    #1,(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSQPostFront_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       POST MESSAGE TO A QUEUE
; *
; * Description: This function sends a message to a queue.  This call has been added to reduce code size
; *              since it can replace both OSQPost() and OSQPostFront().  Also, this function adds the
; *              capability to broadcast a message to ALL tasks waiting on the message queue.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired queue
; *
; *              pmsg          is a pointer to the message to send.
; *
; *              opt           determines the type of POST performed:
; *                            OS_POST_OPT_NONE         POST to a single waiting task
; *                                                     (Identical to OSQPost())
; *                            OS_POST_OPT_BROADCAST    POST to ALL tasks that are waiting on the queue
; *                            OS_POST_OPT_FRONT        POST as LIFO (Simulates OSQPostFront())
; *                            OS_POST_OPT_NO_SCHED     Indicates that the scheduler will NOT be invoked
; *
; * Returns    : OS_ERR_NONE           The call was successful and the message was sent
; *              OS_ERR_Q_FULL         If the queue cannot accept any more messages because it is full.
; *              OS_ERR_EVENT_TYPE     If you didn't pass a pointer to a queue.
; *              OS_ERR_PEVENT_NULL    If 'pevent' is a NULL pointer
; *
; * Warning    : Interrupts can be disabled for a long time if you do a 'broadcast'.  In fact, the
; *              interrupt disable time is proportional to the number of tasks waiting on the queue.
; *********************************************************************************************************
; */
; #if OS_Q_POST_OPT_EN > 0u
; INT8U  OSQPostOpt (OS_EVENT  *pevent,
; void      *pmsg,
; INT8U      opt)
; {
       xdef      _OSQPostOpt
_OSQPostOpt:
       link      A6,#0
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    8(A6),D3
       move.l    12(A6),D4
       move.b    19(A6),D5
       and.l     #255,D5
; OS_Q      *pq;
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; return (OS_ERR_PEVENT_NULL);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_Q) {     /* Validate event block type                     */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     OSQPostOpt_1
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSQPostOpt_3
OSQPostOpt_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0x00u) {                /* See if any task pending on queue              */
       move.l    D3,A0
       move.b    8(A0),D0
       beq       OSQPostOpt_4
; if ((opt & OS_POST_OPT_BROADCAST) != 0x00u) { /* Do we need to post msg to ALL waiting tasks ? */
       move.b    D5,D0
       and.b     #1,D0
       beq.s     OSQPostOpt_6
; while (pevent->OSEventGrp != 0u) {        /* Yes, Post to ALL tasks waiting on queue       */
OSQPostOpt_8:
       move.l    D3,A0
       move.b    8(A0),D0
       beq.s     OSQPostOpt_10
; (void)OS_EventTaskRdy(pevent, pmsg, OS_STAT_Q, OS_STAT_PEND_OK);
       clr.l     -(A7)
       pea       4
       move.l    D4,-(A7)
       move.l    D3,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
       bra       OSQPostOpt_8
OSQPostOpt_10:
       bra.s     OSQPostOpt_7
OSQPostOpt_6:
; }
; } else {                                      /* No,  Post to HPT waiting on queue             */
; (void)OS_EventTaskRdy(pevent, pmsg, OS_STAT_Q, OS_STAT_PEND_OK);
       clr.l     -(A7)
       pea       4
       move.l    D4,-(A7)
       move.l    D3,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
OSQPostOpt_7:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; if ((opt & OS_POST_OPT_NO_SCHED) == 0u) {     /* See if scheduler needs to be invoked          */
       move.b    D5,D0
       and.b     #4,D0
       bne.s     OSQPostOpt_11
; OS_Sched();                               /* Find highest priority task ready to run       */
       jsr       _OS_Sched
OSQPostOpt_11:
; }
; return (OS_ERR_NONE);
       clr.b     D0
       bra       OSQPostOpt_3
OSQPostOpt_4:
; }
; pq = (OS_Q *)pevent->OSEventPtr;                  /* Point to queue control block                  */
       move.l    D3,A0
       move.l    2(A0),D2
; if (pq->OSQEntries >= pq->OSQSize) {              /* Make sure queue is not full                   */
       move.l    D2,A0
       move.l    D2,A1
       move.w    22(A0),D0
       cmp.w     20(A1),D0
       blo.s     OSQPostOpt_13
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_Q_FULL);
       moveq     #30,D0
       bra       OSQPostOpt_3
OSQPostOpt_13:
; }
; if ((opt & OS_POST_OPT_FRONT) != 0x00u) {         /* Do we post to the FRONT of the queue?         */
       move.b    D5,D0
       and.b     #2,D0
       beq       OSQPostOpt_15
; if (pq->OSQOut == pq->OSQStart) {             /* Yes, Post as LIFO, Wrap OUT pointer if we ... */
       move.l    D2,A0
       move.l    D2,A1
       move.l    16(A0),D0
       cmp.l     4(A1),D0
       bne.s     OSQPostOpt_17
; pq->OSQOut = pq->OSQEnd;                  /*      ... are at the 1st queue entry           */
       move.l    D2,A0
       move.l    D2,A1
       move.l    8(A0),16(A1)
OSQPostOpt_17:
; }
; pq->OSQOut--;
       move.l    D2,D0
       add.l     #16,D0
       move.l    D0,A0
       subq.l    #4,(A0)
; *pq->OSQOut = pmsg;                           /*      Insert message into queue                */
       move.l    D2,A0
       move.l    16(A0),A0
       move.l    D4,(A0)
       bra.s     OSQPostOpt_19
OSQPostOpt_15:
; } else {                                          /* No,  Post as FIFO                             */
; *pq->OSQIn++ = pmsg;                          /*      Insert message into queue                */
       move.l    D2,D0
       add.l     #12,D0
       move.l    D0,A0
       move.l    (A0),A1
       addq.l    #4,(A0)
       move.l    D4,(A1)
; if (pq->OSQIn == pq->OSQEnd) {                /*      Wrap IN ptr if we are at end of queue    */
       move.l    D2,A0
       move.l    D2,A1
       move.l    12(A0),D0
       cmp.l     8(A1),D0
       bne.s     OSQPostOpt_19
; pq->OSQIn = pq->OSQStart;
       move.l    D2,A0
       move.l    D2,A1
       move.l    4(A0),12(A1)
OSQPostOpt_19:
; }
; }
; pq->OSQEntries++;                                 /* Update the nbr of entries in the queue        */
       move.l    D2,D0
       add.l     #22,D0
       move.l    D0,A0
       addq.w    #1,(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSQPostOpt_3:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                        QUERY A MESSAGE QUEUE
; *
; * Description: This function obtains information about a message queue.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired queue
; *
; *              p_q_data      is a pointer to a structure that will contain information about the message
; *                            queue.
; *
; * Returns    : OS_ERR_NONE         The call was successful and the message was sent
; *              OS_ERR_EVENT_TYPE   If you are attempting to obtain data from a non queue.
; *              OS_ERR_PEVENT_NULL  If 'pevent'   is a NULL pointer
; *              OS_ERR_PDATA_NULL   If 'p_q_data' is a NULL pointer
; *********************************************************************************************************
; */
; #if OS_Q_QUERY_EN > 0u
; INT8U  OSQQuery (OS_EVENT  *pevent,
; OS_Q_DATA *p_q_data)
; {
       xdef      _OSQQuery
_OSQQuery:
       link      A6,#-8
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    12(A6),D2
       move.l    8(A6),D4
; OS_Q       *pq;
; INT8U       i;
; OS_PRIO    *psrc;
; OS_PRIO    *pdest;
; #if OS_CRITICAL_METHOD == 3u                           /* Allocate storage for CPU status register     */
; OS_CPU_SR   cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                     /* Validate 'pevent'                            */
; return (OS_ERR_PEVENT_NULL);
; }
; if (p_q_data == (OS_Q_DATA *)0) {                  /* Validate 'p_q_data'                          */
; return (OS_ERR_PDATA_NULL);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_Q) {      /* Validate event block type                    */
       move.l    D4,A0
       move.b    (A0),D0
       cmp.b     #2,D0
       beq.s     OSQQuery_1
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSQQuery_3
OSQQuery_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; p_q_data->OSEventGrp = pevent->OSEventGrp;         /* Copy message queue wait list                 */
       move.l    D4,A0
       move.l    D2,A1
       move.b    8(A0),16(A1)
; psrc                 = &pevent->OSEventTbl[0];
       moveq     #10,D0
       add.l     D4,D0
       move.l    D0,-8(A6)
; pdest                = &p_q_data->OSEventTbl[0];
       moveq     #8,D0
       add.l     D2,D0
       move.l    D0,-4(A6)
; for (i = 0u; i < OS_EVENT_TBL_SIZE; i++) {
       clr.b     D5
OSQQuery_4:
       cmp.b     #8,D5
       bhs.s     OSQQuery_6
; *pdest++ = *psrc++;
       move.l    -8(A6),A0
       addq.l    #1,-8(A6)
       move.l    -4(A6),A1
       addq.l    #1,-4(A6)
       move.b    (A0),(A1)
       addq.b    #1,D5
       bra       OSQQuery_4
OSQQuery_6:
; }
; pq = (OS_Q *)pevent->OSEventPtr;
       move.l    D4,A0
       move.l    2(A0),D3
; if (pq->OSQEntries > 0u) {
       move.l    D3,A0
       move.w    22(A0),D0
       cmp.w     #0,D0
       bls.s     OSQQuery_7
; p_q_data->OSMsg = *pq->OSQOut;                 /* Get next message to return if available      */
       move.l    D3,A0
       move.l    16(A0),A0
       move.l    D2,A1
       move.l    (A0),(A1)
       bra.s     OSQQuery_8
OSQQuery_7:
; } else {
; p_q_data->OSMsg = (void *)0;
       move.l    D2,A0
       clr.l     (A0)
OSQQuery_8:
; }
; p_q_data->OSNMsgs = pq->OSQEntries;
       move.l    D3,A0
       move.l    D2,A1
       move.w    22(A0),4(A1)
; p_q_data->OSQSize = pq->OSQSize;
       move.l    D3,A0
       move.l    D2,A1
       move.w    20(A0),6(A1)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSQQuery_3:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; #endif                                                 /* OS_Q_QUERY_EN                                */
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                     QUEUE MODULE INITIALIZATION
; *
; * Description : This function is called by uC/OS-II to initialize the message queue module.  Your
; *               application MUST NOT call this function.
; *
; * Arguments   :  none
; *
; * Returns     : none
; *
; * Note(s)    : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; void  OS_QInit (void)
; {
       xdef      _OS_QInit
_OS_QInit:
       link      A6,#-8
       movem.l   D2/D3/A2,-(A7)
       lea       _OSQTbl.L,A2
; #if OS_MAX_QS == 1u
; OSQFreeList         = &OSQTbl[0];                /* Only ONE queue!                                */
; OSQFreeList->OSQPtr = (OS_Q *)0;
; #endif
; #if OS_MAX_QS >= 2u
; INT16U   ix;
; INT16U   ix_next;
; OS_Q    *pq1;
; OS_Q    *pq2;
; OS_MemClr((INT8U *)&OSQTbl[0], sizeof(OSQTbl));  /* Clear the queue table                          */
       pea       96
       move.l    A2,-(A7)
       jsr       _OS_MemClr
       addq.w    #8,A7
; for (ix = 0u; ix < (OS_MAX_QS - 1u); ix++) {     /* Init. list of free QUEUE control blocks        */
       clr.w     D2
OS_QInit_1:
       cmp.w     #3,D2
       bhs       OS_QInit_3
; ix_next = ix + 1u;
       move.w    D2,D0
       addq.w    #1,D0
       move.w    D0,-6(A6)
; pq1 = &OSQTbl[ix];
       move.l    A2,D0
       and.l     #65535,D2
       move.l    D2,D1
       muls      #24,D1
       add.l     D1,D0
       move.l    D0,D3
; pq2 = &OSQTbl[ix_next];
       move.l    A2,D0
       move.w    -6(A6),D1
       and.l     #65535,D1
       muls      #24,D1
       add.l     D1,D0
       move.l    D0,-4(A6)
; pq1->OSQPtr = pq2;
       move.l    D3,A0
       move.l    -4(A6),(A0)
       addq.w    #1,D2
       bra       OS_QInit_1
OS_QInit_3:
; }
; pq1         = &OSQTbl[ix];
       move.l    A2,D0
       and.l     #65535,D2
       move.l    D2,D1
       muls      #24,D1
       add.l     D1,D0
       move.l    D0,D3
; pq1->OSQPtr = (OS_Q *)0;
       move.l    D3,A0
       clr.l     (A0)
; OSQFreeList = &OSQTbl[0];
       move.l    A2,_OSQFreeList.L
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                          SEMAPHORE MANAGEMENT
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : OS_SEM.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #include <ucos_ii.h>
; #endif
; #if OS_SEM_EN > 0u
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                          ACCEPT SEMAPHORE
; *
; * Description: This function checks the semaphore to see if a resource is available or, if an event
; *              occurred.  Unlike OSSemPend(), OSSemAccept() does not suspend the calling task if the
; *              resource is not available or the event did not occur.
; *
; * Arguments  : pevent     is a pointer to the event control block
; *
; * Returns    : >  0       if the resource is available or the event did not occur the semaphore is
; *                         decremented to obtain the resource.
; *              == 0       if the resource is not available or the event did not occur or,
; *                         if 'pevent' is a NULL pointer or,
; *                         if you didn't pass a pointer to a semaphore
; *********************************************************************************************************
; */
; #if OS_SEM_ACCEPT_EN > 0u
; INT16U  OSSemAccept (OS_EVENT *pevent)
; {
       xdef      _OSSemAccept
_OSSemAccept:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    8(A6),D3
; INT16U     cnt;
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; return (0u);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_SEM) {   /* Validate event block type                     */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     OSSemAccept_1
; return (0u);
       clr.w     D0
       bra.s     OSSemAccept_3
OSSemAccept_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; cnt = pevent->OSEventCnt;
       move.l    D3,A0
       move.w    6(A0),D2
; if (cnt > 0u) {                                   /* See if resource is available                  */
       cmp.w     #0,D2
       bls.s     OSSemAccept_4
; pevent->OSEventCnt--;                         /* Yes, decrement semaphore and notify caller    */
       move.l    D3,D0
       addq.l    #6,D0
       move.l    D0,A0
       subq.w    #1,(A0)
OSSemAccept_4:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (cnt);                                     /* Return semaphore count                        */
       move.w    D2,D0
OSSemAccept_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                         CREATE A SEMAPHORE
; *
; * Description: This function creates a semaphore.
; *
; * Arguments  : cnt           is the initial value for the semaphore.  If the value is 0, no resource is
; *                            available (or no event has occurred).  You initialize the semaphore to a
; *                            non-zero value to specify how many resources are available (e.g. if you have
; *                            10 resources, you would initialize the semaphore to 10).
; *
; * Returns    : != (void *)0  is a pointer to the event control block (OS_EVENT) associated with the
; *                            created semaphore
; *              == (void *)0  if no event control blocks were available
; *********************************************************************************************************
; */
; OS_EVENT  *OSSemCreate (INT16U cnt)
; {
       xdef      _OSSemCreate
_OSSemCreate:
       link      A6,#0
       movem.l   D2/A2,-(A7)
       lea       _OSEventFreeList.L,A2
; OS_EVENT  *pevent;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; if (OSSafetyCriticalStartFlag == OS_TRUE) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_EVENT *)0);
; }
; #endif
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSSemCreate_1
; return ((OS_EVENT *)0);                            /* ... can't CREATE from an ISR             */
       clr.l     D0
       bra       OSSemCreate_3
OSSemCreate_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; pevent = OSEventFreeList;                              /* Get next free event control block        */
       move.l    (A2),D2
; if (OSEventFreeList != (OS_EVENT *)0) {                /* See if pool of free ECB pool was empty   */
       move.l    (A2),D0
       beq.s     OSSemCreate_4
; OSEventFreeList = (OS_EVENT *)OSEventFreeList->OSEventPtr;
       move.l    (A2),A0
       move.l    2(A0),(A2)
OSSemCreate_4:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (pevent != (OS_EVENT *)0) {                         /* Get an event control block               */
       tst.l     D2
       beq.s     OSSemCreate_6
; pevent->OSEventType    = OS_EVENT_TYPE_SEM;
       move.l    D2,A0
       move.b    #3,(A0)
; pevent->OSEventCnt     = cnt;                      /* Set semaphore value                      */
       move.l    D2,A0
       move.w    10(A6),6(A0)
; pevent->OSEventPtr     = (void *)0;                /* Unlink from ECB free list                */
       move.l    D2,A0
       clr.l     2(A0)
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; OS_EventWaitListInit(pevent);                      /* Initialize to 'nobody waiting' on sem.   */
       move.l    D2,-(A7)
       jsr       _OS_EventWaitListInit
       addq.w    #4,A7
OSSemCreate_6:
; }
; return (pevent);
       move.l    D2,D0
OSSemCreate_3:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                         DELETE A SEMAPHORE
; *
; * Description: This function deletes a semaphore and readies all tasks pending on the semaphore.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired
; *                            semaphore.
; *
; *              opt           determines delete options as follows:
; *                            opt == OS_DEL_NO_PEND   Delete semaphore ONLY if no task pending
; *                            opt == OS_DEL_ALWAYS    Deletes the semaphore even if tasks are waiting.
; *                                                    In this case, all the tasks pending will be readied.
; *
; *              perr          is a pointer to an error code that can contain one of the following values:
; *                            OS_ERR_NONE             The call was successful and the semaphore was deleted
; *                            OS_ERR_DEL_ISR          If you attempted to delete the semaphore from an ISR
; *                            OS_ERR_INVALID_OPT      An invalid option was specified
; *                            OS_ERR_TASK_WAITING     One or more tasks were waiting on the semaphore
; *                            OS_ERR_EVENT_TYPE       If you didn't pass a pointer to a semaphore
; *                            OS_ERR_PEVENT_NULL      If 'pevent' is a NULL pointer.
; *
; * Returns    : pevent        upon error
; *              (OS_EVENT *)0 if the semaphore was successfully deleted.
; *
; * Note(s)    : 1) This function must be used with care.  Tasks that would normally expect the presence of
; *                 the semaphore MUST check the return code of OSSemPend().
; *              2) OSSemAccept() callers will not know that the intended semaphore has been deleted unless
; *                 they check 'pevent' to see that it's a NULL pointer.
; *              3) This call can potentially disable interrupts for a long time.  The interrupt disable
; *                 time is directly proportional to the number of tasks waiting on the semaphore.
; *              4) Because ALL tasks pending on the semaphore will be readied, you MUST be careful in
; *                 applications where the semaphore is used for mutual exclusion because the resource(s)
; *                 will no longer be guarded by the semaphore.
; *              5) All tasks that were waiting for the semaphore will be readied and returned an 
; *                 OS_ERR_PEND_ABORT if OSSemDel() was called with OS_DEL_ALWAYS
; *********************************************************************************************************
; */
; #if OS_SEM_DEL_EN > 0u
; OS_EVENT  *OSSemDel (OS_EVENT  *pevent,
; INT8U      opt,
; INT8U     *perr)
; {
       xdef      _OSSemDel
_OSSemDel:
       link      A6,#0
       movem.l   D2/D3/D4/D5/A2,-(A7)
       move.l    8(A6),D2
       move.l    16(A6),D3
       lea       _OSEventFreeList.L,A2
; BOOLEAN    tasks_waiting;
; OS_EVENT  *pevent_return;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_EVENT *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; *perr = OS_ERR_PEVENT_NULL;
; return (pevent);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_SEM) {        /* Validate event block type                */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     OSSemDel_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D3,A0
       move.b    #1,(A0)
; return (pevent);
       move.l    D2,D0
       bra       OSSemDel_3
OSSemDel_1:
; }
; if (OSIntNesting > 0u) {                               /* See if called from ISR ...               */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSSemDel_4
; *perr = OS_ERR_DEL_ISR;                            /* ... can't DELETE from an ISR             */
       move.l    D3,A0
       move.b    #15,(A0)
; return (pevent);
       move.l    D2,D0
       bra       OSSemDel_3
OSSemDel_4:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                        /* See if any tasks waiting on semaphore    */
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSSemDel_6
; tasks_waiting = OS_TRUE;                           /* Yes                                      */
       moveq     #1,D5
       bra.s     OSSemDel_7
OSSemDel_6:
; } else {
; tasks_waiting = OS_FALSE;                          /* No                                       */
       clr.b     D5
OSSemDel_7:
; }
; switch (opt) {
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq       OSSemDel_11
       bhi       OSSemDel_8
       tst.l     D0
       beq.s     OSSemDel_10
       bra       OSSemDel_8
OSSemDel_10:
; case OS_DEL_NO_PEND:                               /* Delete semaphore only if no task waiting */
; if (tasks_waiting == OS_FALSE) {
       tst.b     D5
       bne.s     OSSemDel_13
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; pevent->OSEventType    = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent->OSEventPtr     = OSEventFreeList; /* Return Event Control Block to free list  */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pevent->OSEventCnt     = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; OSEventFreeList        = pevent;          /* Get next free event control block        */
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                  = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; pevent_return          = (OS_EVENT *)0;   /* Semaphore has been deleted               */
       clr.l     D4
       bra.s     OSSemDel_14
OSSemDel_13:
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                  = OS_ERR_TASK_WAITING;
       move.l    D3,A0
       move.b    #73,(A0)
; pevent_return          = pevent;
       move.l    D2,D4
OSSemDel_14:
; }
; break;
       bra       OSSemDel_9
OSSemDel_11:
; case OS_DEL_ALWAYS:                                /* Always delete the semaphore              */
; while (pevent->OSEventGrp != 0u) {            /* Ready ALL tasks waiting for semaphore    */
OSSemDel_15:
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSSemDel_17
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_SEM, OS_STAT_PEND_ABORT);
       pea       2
       pea       1
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
       bra       OSSemDel_15
OSSemDel_17:
; }
; #if OS_EVENT_NAME_EN > 0u
; pevent->OSEventName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,18(A1)
; #endif
; pevent->OSEventType    = OS_EVENT_TYPE_UNUSED;
       move.l    D2,A0
       clr.b     (A0)
; pevent->OSEventPtr     = OSEventFreeList;     /* Return Event Control Block to free list  */
       move.l    D2,A0
       move.l    (A2),2(A0)
; pevent->OSEventCnt     = 0u;
       move.l    D2,A0
       clr.w     6(A0)
; OSEventFreeList        = pevent;              /* Get next free event control block        */
       move.l    D2,(A2)
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (tasks_waiting == OS_TRUE) {               /* Reschedule only if task(s) were waiting  */
       cmp.b     #1,D5
       bne.s     OSSemDel_18
; OS_Sched();                               /* Find highest priority task ready to run  */
       jsr       _OS_Sched
OSSemDel_18:
; }
; *perr                  = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; pevent_return          = (OS_EVENT *)0;       /* Semaphore has been deleted               */
       clr.l     D4
; break;
       bra.s     OSSemDel_9
OSSemDel_8:
; default:
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                  = OS_ERR_INVALID_OPT;
       move.l    D3,A0
       move.b    #7,(A0)
; pevent_return          = pevent;
       move.l    D2,D4
; break;
OSSemDel_9:
; }
; return (pevent_return);
       move.l    D4,D0
OSSemDel_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                          PEND ON SEMAPHORE
; *
; * Description: This function waits for a semaphore.
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired
; *                            semaphore.
; *
; *              timeout       is an optional timeout period (in clock ticks).  If non-zero, your task will
; *                            wait for the resource up to the amount of time specified by this argument.
; *                            If you specify 0, however, your task will wait forever at the specified
; *                            semaphore or, until the resource becomes available (or the event occurs).
; *
; *              perr          is a pointer to where an error message will be deposited.  Possible error
; *                            messages are:
; *
; *                            OS_ERR_NONE         The call was successful and your task owns the resource
; *                                                or, the event you are waiting for occurred.
; *                            OS_ERR_TIMEOUT      The semaphore was not received within the specified
; *                                                'timeout'.
; *                            OS_ERR_PEND_ABORT   The wait on the semaphore was aborted.
; *                            OS_ERR_EVENT_TYPE   If you didn't pass a pointer to a semaphore.
; *                            OS_ERR_PEND_ISR     If you called this function from an ISR and the result
; *                                                would lead to a suspension.
; *                            OS_ERR_PEVENT_NULL  If 'pevent' is a NULL pointer.
; *                            OS_ERR_PEND_LOCKED  If you called this function when the scheduler is locked
; *
; * Returns    : none
; *********************************************************************************************************
; */
; /*$PAGE*/
; void  OSSemPend (OS_EVENT  *pevent,
; INT32U     timeout,
; INT8U     *perr)
; {
       xdef      _OSSemPend
_OSSemPend:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       lea       _OSTCBCur.L,A2
       move.l    16(A6),D2
       move.l    8(A6),D3
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return;
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; *perr = OS_ERR_PEVENT_NULL;
; return;
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_SEM) {   /* Validate event block type                     */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     OSSemPend_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D2,A0
       move.b    #1,(A0)
; return;
       bra       OSSemPend_3
OSSemPend_1:
; }
; if (OSIntNesting > 0u) {                          /* See if called from ISR ...                    */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSSemPend_4
; *perr = OS_ERR_PEND_ISR;                      /* ... can't PEND from an ISR                    */
       move.l    D2,A0
       move.b    #2,(A0)
; return;
       bra       OSSemPend_3
OSSemPend_4:
; }
; if (OSLockNesting > 0u) {                         /* See if called with scheduler locked ...       */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSSemPend_6
; *perr = OS_ERR_PEND_LOCKED;                   /* ... can't PEND when locked                    */
       move.l    D2,A0
       move.b    #13,(A0)
; return;
       bra       OSSemPend_3
OSSemPend_6:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventCnt > 0u) {                    /* If sem. is positive, resource available ...   */
       move.l    D3,A0
       move.w    6(A0),D0
       cmp.w     #0,D0
       bls.s     OSSemPend_8
; pevent->OSEventCnt--;                         /* ... decrement semaphore only if positive.     */
       move.l    D3,D0
       addq.l    #6,D0
       move.l    D0,A0
       subq.w    #1,(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return;
       bra       OSSemPend_3
OSSemPend_8:
; }
; /* Otherwise, must wait until event occurs       */
; OSTCBCur->OSTCBStat     |= OS_STAT_SEM;           /* Resource not available, pend on semaphore     */
       move.l    (A2),A0
       or.b      #1,50(A0)
; OSTCBCur->OSTCBStatPend  = OS_STAT_PEND_OK;
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBDly       = timeout;               /* Store pend timeout in TCB                     */
       move.l    (A2),A0
       move.l    12(A6),46(A0)
; OS_EventTaskWait(pevent);                         /* Suspend task until event or timeout occurs    */
       move.l    D3,-(A7)
       jsr       _OS_EventTaskWait
       addq.w    #4,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                       /* Find next highest priority task ready         */
       jsr       _OS_Sched
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; switch (OSTCBCur->OSTCBStatPend) {                /* See if we timed-out or aborted                */
       move.l    (A2),A0
       move.b    51(A0),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq.s     OSSemPend_14
       bhi.s     OSSemPend_16
       tst.l     D0
       beq.s     OSSemPend_12
       bra.s     OSSemPend_14
OSSemPend_16:
       cmp.l     #2,D0
       beq.s     OSSemPend_13
       bra.s     OSSemPend_14
OSSemPend_12:
; case OS_STAT_PEND_OK:
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; break;
       bra.s     OSSemPend_11
OSSemPend_13:
; case OS_STAT_PEND_ABORT:
; *perr = OS_ERR_PEND_ABORT;               /* Indicate that we aborted                      */
       move.l    D2,A0
       move.b    #14,(A0)
; break;
       bra.s     OSSemPend_11
OSSemPend_14:
; case OS_STAT_PEND_TO:
; default:
; OS_EventTaskRemove(OSTCBCur, pevent);
       move.l    D3,-(A7)
       move.l    (A2),-(A7)
       jsr       _OS_EventTaskRemove
       addq.w    #8,A7
; *perr = OS_ERR_TIMEOUT;                  /* Indicate that we didn't get event within TO   */
       move.l    D2,A0
       move.b    #10,(A0)
; break;
OSSemPend_11:
; }
; OSTCBCur->OSTCBStat          =  OS_STAT_RDY;      /* Set   task  status to ready                   */
       move.l    (A2),A0
       clr.b     50(A0)
; OSTCBCur->OSTCBStatPend      =  OS_STAT_PEND_OK;  /* Clear pend  status                            */
       move.l    (A2),A0
       clr.b     51(A0)
; OSTCBCur->OSTCBEventPtr      = (OS_EVENT  *)0;    /* Clear event pointers                          */
       move.l    (A2),A0
       clr.l     28(A0)
; #if (OS_EVENT_MULTI_EN > 0u)
; OSTCBCur->OSTCBEventMultiPtr = (OS_EVENT **)0;
       move.l    (A2),A0
       clr.l     32(A0)
; #endif
; OS_EXIT_CRITICAL();
       dc.w      18143
OSSemPend_3:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                    ABORT WAITING ON A SEMAPHORE
; *
; * Description: This function aborts & readies any tasks currently waiting on a semaphore.  This function
; *              should be used to fault-abort the wait on the semaphore, rather than to normally signal
; *              the semaphore via OSSemPost().
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired
; *                            semaphore.
; *
; *              opt           determines the type of ABORT performed:
; *                            OS_PEND_OPT_NONE         ABORT wait for a single task (HPT) waiting on the
; *                                                     semaphore
; *                            OS_PEND_OPT_BROADCAST    ABORT wait for ALL tasks that are  waiting on the
; *                                                     semaphore
; *
; *              perr          is a pointer to where an error message will be deposited.  Possible error
; *                            messages are:
; *
; *                            OS_ERR_NONE         No tasks were     waiting on the semaphore.
; *                            OS_ERR_PEND_ABORT   At least one task waiting on the semaphore was readied
; *                                                and informed of the aborted wait; check return value
; *                                                for the number of tasks whose wait on the semaphore
; *                                                was aborted.
; *                            OS_ERR_EVENT_TYPE   If you didn't pass a pointer to a semaphore.
; *                            OS_ERR_PEVENT_NULL  If 'pevent' is a NULL pointer.
; *
; * Returns    : == 0          if no tasks were waiting on the semaphore, or upon error.
; *              >  0          if one or more tasks waiting on the semaphore are now readied and informed.
; *********************************************************************************************************
; */
; #if OS_SEM_PEND_ABORT_EN > 0u
; INT8U  OSSemPendAbort (OS_EVENT  *pevent,
; INT8U      opt,
; INT8U     *perr)
; {
       xdef      _OSSemPendAbort
_OSSemPendAbort:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
       move.l    8(A6),D2
       move.l    16(A6),D4
; INT8U      nbr_tasks;
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; *perr = OS_ERR_PEVENT_NULL;
; return (0u);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_SEM) {   /* Validate event block type                     */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     OSSemPendAbort_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D4,A0
       move.b    #1,(A0)
; return (0u);
       clr.b     D0
       bra       OSSemPendAbort_3
OSSemPendAbort_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                   /* See if any task waiting on semaphore?         */
       move.l    D2,A0
       move.b    8(A0),D0
       beq       OSSemPendAbort_4
; nbr_tasks = 0u;
       clr.b     D3
; switch (opt) {
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     #1,D0
       beq.s     OSSemPendAbort_8
       bhi       OSSemPendAbort_9
       tst.l     D0
       beq.s     OSSemPendAbort_9
       bra.s     OSSemPendAbort_9
OSSemPendAbort_8:
; case OS_PEND_OPT_BROADCAST:               /* Do we need to abort ALL waiting tasks?        */
; while (pevent->OSEventGrp != 0u) {   /* Yes, ready ALL tasks waiting on semaphore     */
OSSemPendAbort_11:
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSSemPendAbort_13
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_SEM, OS_STAT_PEND_ABORT);
       pea       2
       pea       1
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; nbr_tasks++;
       addq.b    #1,D3
       bra       OSSemPendAbort_11
OSSemPendAbort_13:
; }
; break;
       bra.s     OSSemPendAbort_7
OSSemPendAbort_9:
; case OS_PEND_OPT_NONE:
; default:                                  /* No,  ready HPT       waiting on semaphore     */
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_SEM, OS_STAT_PEND_ABORT);
       pea       2
       pea       1
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; nbr_tasks++;
       addq.b    #1,D3
; break;
OSSemPendAbort_7:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                   /* Find HPT ready to run                         */
       jsr       _OS_Sched
; *perr = OS_ERR_PEND_ABORT;
       move.l    D4,A0
       move.b    #14,(A0)
; return (nbr_tasks);
       move.b    D3,D0
       bra.s     OSSemPendAbort_3
OSSemPendAbort_4:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    D4,A0
       clr.b     (A0)
; return (0u);                                      /* No tasks waiting on semaphore                 */
       clr.b     D0
OSSemPendAbort_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                         POST TO A SEMAPHORE
; *
; * Description: This function signals a semaphore
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired
; *                            semaphore.
; *
; * Returns    : OS_ERR_NONE         The call was successful and the semaphore was signaled.
; *              OS_ERR_SEM_OVF      If the semaphore count exceeded its limit. In other words, you have
; *                                  signaled the semaphore more often than you waited on it with either
; *                                  OSSemAccept() or OSSemPend().
; *              OS_ERR_EVENT_TYPE   If you didn't pass a pointer to a semaphore
; *              OS_ERR_PEVENT_NULL  If 'pevent' is a NULL pointer.
; *********************************************************************************************************
; */
; INT8U  OSSemPost (OS_EVENT *pevent)
; {
       xdef      _OSSemPost
_OSSemPost:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; return (OS_ERR_PEVENT_NULL);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_SEM) {   /* Validate event block type                     */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     OSSemPost_1
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSSemPost_3
OSSemPost_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (pevent->OSEventGrp != 0u) {                   /* See if any task waiting for semaphore         */
       move.l    D2,A0
       move.b    8(A0),D0
       beq.s     OSSemPost_4
; /* Ready HPT waiting on event                    */
; (void)OS_EventTaskRdy(pevent, (void *)0, OS_STAT_SEM, OS_STAT_PEND_OK);
       clr.l     -(A7)
       pea       1
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRdy
       add.w     #16,A7
       and.l     #255,D0
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                   /* Find HPT ready to run                         */
       jsr       _OS_Sched
; return (OS_ERR_NONE);
       clr.b     D0
       bra.s     OSSemPost_3
OSSemPost_4:
; }
; if (pevent->OSEventCnt < 65535u) {                /* Make sure semaphore will not overflow         */
       move.l    D2,A0
       move.w    6(A0),D0
       cmp.w     #65535,D0
       bhs.s     OSSemPost_6
; pevent->OSEventCnt++;                         /* Increment semaphore count to register event   */
       move.l    D2,D0
       addq.l    #6,D0
       move.l    D0,A0
       addq.w    #1,(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
       bra.s     OSSemPost_3
OSSemPost_6:
; }
; OS_EXIT_CRITICAL();                               /* Semaphore value has reached its maximum       */
       dc.w      18143
; return (OS_ERR_SEM_OVF);
       moveq     #51,D0
OSSemPost_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                          QUERY A SEMAPHORE
; *
; * Description: This function obtains information about a semaphore
; *
; * Arguments  : pevent        is a pointer to the event control block associated with the desired
; *                            semaphore
; *
; *              p_sem_data    is a pointer to a structure that will contain information about the
; *                            semaphore.
; *
; * Returns    : OS_ERR_NONE         The call was successful and the message was sent
; *              OS_ERR_EVENT_TYPE   If you are attempting to obtain data from a non semaphore.
; *              OS_ERR_PEVENT_NULL  If 'pevent'     is a NULL pointer.
; *              OS_ERR_PDATA_NULL   If 'p_sem_data' is a NULL pointer
; *********************************************************************************************************
; */
; #if OS_SEM_QUERY_EN > 0u
; INT8U  OSSemQuery (OS_EVENT     *pevent,
; OS_SEM_DATA  *p_sem_data)
; {
       xdef      _OSSemQuery
_OSSemQuery:
       link      A6,#-8
       movem.l   D2/D3/D4,-(A7)
       move.l    8(A6),D2
       move.l    12(A6),D4
; INT8U       i;
; OS_PRIO    *psrc;
; OS_PRIO    *pdest;
; #if OS_CRITICAL_METHOD == 3u                               /* Allocate storage for CPU status register */
; OS_CPU_SR   cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                         /* Validate 'pevent'                        */
; return (OS_ERR_PEVENT_NULL);
; }
; if (p_sem_data == (OS_SEM_DATA *)0) {                  /* Validate 'p_sem_data'                    */
; return (OS_ERR_PDATA_NULL);
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_SEM) {        /* Validate event block type                */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     OSSemQuery_1
; return (OS_ERR_EVENT_TYPE);
       moveq     #1,D0
       bra       OSSemQuery_3
OSSemQuery_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; p_sem_data->OSEventGrp = pevent->OSEventGrp;           /* Copy message mailbox wait list           */
       move.l    D2,A0
       move.l    D4,A1
       move.b    8(A0),10(A1)
; psrc                   = &pevent->OSEventTbl[0];
       moveq     #10,D0
       add.l     D2,D0
       move.l    D0,-8(A6)
; pdest                  = &p_sem_data->OSEventTbl[0];
       moveq     #2,D0
       add.l     D4,D0
       move.l    D0,-4(A6)
; for (i = 0u; i < OS_EVENT_TBL_SIZE; i++) {
       clr.b     D3
OSSemQuery_4:
       cmp.b     #8,D3
       bhs.s     OSSemQuery_6
; *pdest++ = *psrc++;
       move.l    -8(A6),A0
       addq.l    #1,-8(A6)
       move.l    -4(A6),A1
       addq.l    #1,-4(A6)
       move.b    (A0),(A1)
       addq.b    #1,D3
       bra       OSSemQuery_4
OSSemQuery_6:
; }
; p_sem_data->OSCnt = pevent->OSEventCnt;                /* Get semaphore count                      */
       move.l    D2,A0
       move.l    D4,A1
       move.w    6(A0),(A1)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSSemQuery_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; #endif                                                     /* OS_SEM_QUERY_EN                          */
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                            SET SEMAPHORE
; *
; * Description: This function sets the semaphore count to the value specified as an argument.  Typically,
; *              this value would be 0.
; *
; *              You would typically use this function when a semaphore is used as a signaling mechanism
; *              and, you want to reset the count value.
; *
; * Arguments  : pevent     is a pointer to the event control block
; *
; *              cnt        is the new value for the semaphore count.  You would pass 0 to reset the
; *                         semaphore count.
; *
; *              perr       is a pointer to an error code returned by the function as follows:
; *
; *                            OS_ERR_NONE          The call was successful and the semaphore value was set.
; *                            OS_ERR_EVENT_TYPE    If you didn't pass a pointer to a semaphore.
; *                            OS_ERR_PEVENT_NULL   If 'pevent' is a NULL pointer.
; *                            OS_ERR_TASK_WAITING  If tasks are waiting on the semaphore.
; *********************************************************************************************************
; */
; #if OS_SEM_SET_EN > 0u
; void  OSSemSet (OS_EVENT  *pevent,
; INT16U     cnt,
; INT8U     *perr)
; {
       xdef      _OSSemSet
_OSSemSet:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    8(A6),D2
       move.l    16(A6),D3
; #if OS_CRITICAL_METHOD == 3u                          /* Allocate storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return;
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pevent == (OS_EVENT *)0) {                    /* Validate 'pevent'                             */
; *perr = OS_ERR_PEVENT_NULL;
; return;
; }
; #endif
; if (pevent->OSEventType != OS_EVENT_TYPE_SEM) {   /* Validate event block type                     */
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #3,D0
       beq.s     OSSemSet_1
; *perr = OS_ERR_EVENT_TYPE;
       move.l    D3,A0
       move.b    #1,(A0)
; return;
       bra       OSSemSet_3
OSSemSet_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; *perr = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; if (pevent->OSEventCnt > 0u) {                    /* See if semaphore already has a count          */
       move.l    D2,A0
       move.w    6(A0),D0
       cmp.w     #0,D0
       bls.s     OSSemSet_4
; pevent->OSEventCnt = cnt;                     /* Yes, set it to the new value specified.       */
       move.l    D2,A0
       move.w    14(A6),6(A0)
       bra.s     OSSemSet_7
OSSemSet_4:
; } else {                                          /* No                                            */
; if (pevent->OSEventGrp == 0u) {               /*      See if task(s) waiting?                  */
       move.l    D2,A0
       move.b    8(A0),D0
       bne.s     OSSemSet_6
; pevent->OSEventCnt = cnt;                 /*      No, OK to set the value                  */
       move.l    D2,A0
       move.w    14(A6),6(A0)
       bra.s     OSSemSet_7
OSSemSet_6:
; } else {
; *perr              = OS_ERR_TASK_WAITING;
       move.l    D3,A0
       move.b    #73,(A0)
OSSemSet_7:
; }
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
OSSemSet_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                            TASK MANAGEMENT
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : OS_TASK.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #include <ucos_ii.h>
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                      CHANGE PRIORITY OF A TASK
; *
; * Description: This function allows you to change the priority of a task dynamically.  Note that the new
; *              priority MUST be available.
; *
; * Arguments  : oldp     is the old priority
; *
; *              newp     is the new priority
; *
; * Returns    : OS_ERR_NONE            is the call was successful
; *              OS_ERR_PRIO_INVALID    if the priority you specify is higher that the maximum allowed
; *                                     (i.e. >= OS_LOWEST_PRIO)
; *              OS_ERR_PRIO_EXIST      if the new priority already exist.
; *              OS_ERR_PRIO            there is no task with the specified OLD priority (i.e. the OLD task does
; *                                     not exist.
; *              OS_ERR_TASK_NOT_EXIST  if the task is assigned to a Mutex PIP.
; *********************************************************************************************************
; */
; #if OS_TASK_CHANGE_PRIO_EN > 0u
; INT8U  OSTaskChangePrio (INT8U  oldprio,
; INT8U  newprio)
; {
       xdef      _OSTaskChangePrio
_OSTaskChangePrio:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4,-(A7)
       lea       _OSRdyTbl.L,A3
       lea       _OSTCBPrioTbl.L,A4
; #if (OS_EVENT_EN)
; OS_EVENT  *pevent;
; #if (OS_EVENT_MULTI_EN > 0u)
; OS_EVENT **pevents;
; #endif
; #endif
; OS_TCB    *ptcb;
; INT8U      y_new;
; INT8U      x_new;
; INT8U      y_old;
; OS_PRIO    bity_new;
; OS_PRIO    bitx_new;
; OS_PRIO    bity_old;
; OS_PRIO    bitx_old;
; #if OS_CRITICAL_METHOD == 3u
; OS_CPU_SR  cpu_sr = 0u;                                 /* Storage for CPU status register         */
; #endif
; /*$PAGE*/
; #if OS_ARG_CHK_EN > 0u
; if (oldprio >= OS_LOWEST_PRIO) {
; if (oldprio != OS_PRIO_SELF) {
; return (OS_ERR_PRIO_INVALID);
; }
; }
; if (newprio >= OS_LOWEST_PRIO) {
; return (OS_ERR_PRIO_INVALID);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSTCBPrioTbl[newprio] != (OS_TCB *)0) {             /* New priority must not already exist     */
       move.b    15(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       move.l    0(A4,D0.L),D0
       beq.s     OSTaskChangePrio_1
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_PRIO_EXIST);
       moveq     #40,D0
       bra       OSTaskChangePrio_3
OSTaskChangePrio_1:
; }
; if (oldprio == OS_PRIO_SELF) {                          /* See if changing self                    */
       move.b    11(A6),D0
       cmp.b     #255,D0
       bne.s     OSTaskChangePrio_4
; oldprio = OSTCBCur->OSTCBPrio;                      /* Yes, get priority                       */
       move.l    _OSTCBCur.L,A0
       move.b    52(A0),11(A6)
OSTaskChangePrio_4:
; }
; ptcb = OSTCBPrioTbl[oldprio];
       move.b    11(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       move.l    0(A4,D0.L),D3
; if (ptcb == (OS_TCB *)0) {                              /* Does task to change exist?              */
       tst.l     D3
       bne.s     OSTaskChangePrio_6
; OS_EXIT_CRITICAL();                                 /* No, can't change its priority!          */
       dc.w      18143
; return (OS_ERR_PRIO);
       moveq     #41,D0
       bra       OSTaskChangePrio_3
OSTaskChangePrio_6:
; }
; if (ptcb == OS_TCB_RESERVED) {                          /* Is task assigned to Mutex               */
       cmp.l     #1,D3
       bne.s     OSTaskChangePrio_8
; OS_EXIT_CRITICAL();                                 /* No, can't change its priority!          */
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);
       moveq     #67,D0
       bra       OSTaskChangePrio_3
OSTaskChangePrio_8:
; }
; #if OS_LOWEST_PRIO <= 63u
; y_new                 = (INT8U)(newprio >> 3u);         /* Yes, compute new TCB fields             */
       move.b    15(A6),D0
       lsr.b     #3,D0
       move.b    D0,D5
; x_new                 = (INT8U)(newprio & 0x07u);
       move.b    15(A6),D0
       and.b     #7,D0
       move.b    D0,-3(A6)
; #else
; y_new                 = (INT8U)((INT8U)(newprio >> 4u) & 0x0Fu);
; x_new                 = (INT8U)(newprio & 0x0Fu);
; #endif
; bity_new              = (OS_PRIO)(1uL << y_new);
       moveq     #1,D0
       and.l     #255,D5
       lsl.l     D5,D0
       move.b    D0,-2(A6)
; bitx_new              = (OS_PRIO)(1uL << x_new);
       moveq     #1,D0
       move.b    -3(A6),D1
       and.l     #255,D1
       lsl.l     D1,D0
       move.b    D0,D7
; OSTCBPrioTbl[oldprio] = (OS_TCB *)0;                    /* Remove TCB from old priority            */
       move.b    11(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       clr.l     0(A4,D0.L)
; OSTCBPrioTbl[newprio] =  ptcb;                          /* Place pointer to TCB @ new priority     */
       move.b    15(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       move.l    D3,0(A4,D0.L)
; y_old                 =  ptcb->OSTCBY;
       move.l    D3,A0
       move.b    54(A0),D4
; bity_old              =  ptcb->OSTCBBitY;
       move.l    D3,A0
       move.b    56(A0),-1(A6)
; bitx_old              =  ptcb->OSTCBBitX;
       move.l    D3,A0
       move.b    55(A0),D6
; if ((OSRdyTbl[y_old] &   bitx_old) != 0u) {             /* If task is ready make it not            */
       and.l     #255,D4
       move.b    0(A3,D4.L),D0
       and.b     D6,D0
       beq.s     OSTaskChangePrio_10
; OSRdyTbl[y_old] &= (OS_PRIO)~bitx_old;
       and.l     #255,D4
       move.b    D6,D0
       not.b     D0
       and.b     D0,0(A3,D4.L)
; if (OSRdyTbl[y_old] == 0u) {
       and.l     #255,D4
       move.b    0(A3,D4.L),D0
       bne.s     OSTaskChangePrio_12
; OSRdyGrp &= (OS_PRIO)~bity_old;
       move.b    -1(A6),D0
       not.b     D0
       and.b     D0,_OSRdyGrp.L
OSTaskChangePrio_12:
; }
; OSRdyGrp        |= bity_new;                       /* Make new priority ready to run          */
       move.b    -2(A6),D0
       or.b      D0,_OSRdyGrp.L
; OSRdyTbl[y_new] |= bitx_new;
       and.l     #255,D5
       or.b      D7,0(A3,D5.L)
OSTaskChangePrio_10:
; }
; #if (OS_EVENT_EN)
; pevent = ptcb->OSTCBEventPtr;
       move.l    D3,A0
       move.l    28(A0),D2
; if (pevent != (OS_EVENT *)0) {
       tst.l     D2
       beq       OSTaskChangePrio_14
; pevent->OSEventTbl[y_old] &= (OS_PRIO)~bitx_old;    /* Remove old task prio from wait list     */
       move.l    D2,A0
       and.l     #255,D4
       add.l     D4,A0
       move.b    D6,D0
       not.b     D0
       and.b     D0,10(A0)
; if (pevent->OSEventTbl[y_old] == 0u) {
       move.l    D2,A0
       and.l     #255,D4
       add.l     D4,A0
       move.b    10(A0),D0
       bne.s     OSTaskChangePrio_16
; pevent->OSEventGrp    &= (OS_PRIO)~bity_old;
       move.l    D2,A0
       move.b    -1(A6),D0
       not.b     D0
       and.b     D0,8(A0)
OSTaskChangePrio_16:
; }
; pevent->OSEventGrp        |= bity_new;              /* Add    new task prio to   wait list     */
       move.l    D2,A0
       move.b    -2(A6),D0
       or.b      D0,8(A0)
; pevent->OSEventTbl[y_new] |= bitx_new;
       move.l    D2,A0
       and.l     #255,D5
       add.l     D5,A0
       or.b      D7,10(A0)
OSTaskChangePrio_14:
; }
; #if (OS_EVENT_MULTI_EN > 0u)
; if (ptcb->OSTCBEventMultiPtr != (OS_EVENT **)0) {
       move.l    D3,A0
       move.l    32(A0),D0
       beq       OSTaskChangePrio_22
; pevents =  ptcb->OSTCBEventMultiPtr;
       move.l    D3,A0
       move.l    32(A0),A2
; pevent  = *pevents;
       move.l    (A2),D2
; while (pevent != (OS_EVENT *)0) {
OSTaskChangePrio_20:
       tst.l     D2
       beq       OSTaskChangePrio_22
; pevent->OSEventTbl[y_old] &= (OS_PRIO)~bitx_old;   /* Remove old task prio from wait lists */
       move.l    D2,A0
       and.l     #255,D4
       add.l     D4,A0
       move.b    D6,D0
       not.b     D0
       and.b     D0,10(A0)
; if (pevent->OSEventTbl[y_old] == 0u) {
       move.l    D2,A0
       and.l     #255,D4
       add.l     D4,A0
       move.b    10(A0),D0
       bne.s     OSTaskChangePrio_23
; pevent->OSEventGrp    &= (OS_PRIO)~bity_old;
       move.l    D2,A0
       move.b    -1(A6),D0
       not.b     D0
       and.b     D0,8(A0)
OSTaskChangePrio_23:
; }
; pevent->OSEventGrp        |= bity_new;          /* Add    new task prio to   wait lists    */
       move.l    D2,A0
       move.b    -2(A6),D0
       or.b      D0,8(A0)
; pevent->OSEventTbl[y_new] |= bitx_new;
       move.l    D2,A0
       and.l     #255,D5
       add.l     D5,A0
       or.b      D7,10(A0)
; pevents++;
       addq.w    #4,A2
; pevent                     = *pevents;
       move.l    (A2),D2
       bra       OSTaskChangePrio_20
OSTaskChangePrio_22:
; }
; }
; #endif
; #endif
; ptcb->OSTCBPrio = newprio;                              /* Set new task priority                   */
       move.l    D3,A0
       move.b    15(A6),52(A0)
; ptcb->OSTCBY    = y_new;
       move.l    D3,A0
       move.b    D5,54(A0)
; ptcb->OSTCBX    = x_new;
       move.l    D3,A0
       move.b    -3(A6),53(A0)
; ptcb->OSTCBBitY = bity_new;
       move.l    D3,A0
       move.b    -2(A6),56(A0)
; ptcb->OSTCBBitX = bitx_new;
       move.l    D3,A0
       move.b    D7,55(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (OSRunning == OS_TRUE) {
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne.s     OSTaskChangePrio_25
; OS_Sched();                                         /* Find new highest priority task          */
       jsr       _OS_Sched
OSTaskChangePrio_25:
; }
; return (OS_ERR_NONE);
       clr.b     D0
OSTaskChangePrio_3:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                            CREATE A TASK
; *
; * Description: This function is used to have uC/OS-II manage the execution of a task.  Tasks can either
; *              be created prior to the start of multitasking or by a running task.  A task cannot be
; *              created by an ISR.
; *
; * Arguments  : task     is a pointer to the task's code
; *
; *              p_arg    is a pointer to an optional data area which can be used to pass parameters to
; *                       the task when the task first executes.  Where the task is concerned it thinks
; *                       it was invoked and passed the argument 'p_arg' as follows:
; *
; *                           void Task (void *p_arg)
; *                           {
; *                               for (;;) {
; *                                   Task code;
; *                               }
; *                           }
; *
; *              ptos     is a pointer to the task's top of stack.  If the configuration constant
; *                       OS_STK_GROWTH is set to 1, the stack is assumed to grow downward (i.e. from high
; *                       memory to low memory).  'pstk' will thus point to the highest (valid) memory
; *                       location of the stack.  If OS_STK_GROWTH is set to 0, 'pstk' will point to the
; *                       lowest memory location of the stack and the stack will grow with increasing
; *                       memory locations.
; *
; *              prio     is the task's priority.  A unique priority MUST be assigned to each task and the
; *                       lower the number, the higher the priority.
; *
; * Returns    : OS_ERR_NONE                      if the function was successful.
; *              OS_ERR_PRIO_EXIST                if the task priority already exist
; *                                               (each task MUST have a unique priority).
; *              OS_ERR_PRIO_INVALID              if the priority you specify is higher that the maximum
; *                                               allowed (i.e. >= OS_LOWEST_PRIO)
; *              OS_ERR_TASK_CREATE_ISR           if you tried to create a task from an ISR.
; *              OS_ERR_ILLEGAL_CREATE_RUN_TIME   if you tried to create a task after safety critical
; *                                               operation started.
; *********************************************************************************************************
; */
; #if OS_TASK_CREATE_EN > 0u
; INT8U  OSTaskCreate (void   (*task)(void *p_arg),
; void    *p_arg,
; OS_STK  *ptos,
; INT8U    prio)
; {
       xdef      _OSTaskCreate
_OSTaskCreate:
       link      A6,#-4
       movem.l   D2/D3/A2,-(A7)
       move.b    23(A6),D2
       and.l     #255,D2
       lea       _OSTCBPrioTbl.L,A2
; OS_STK     *psp;
; INT8U       err;
; #if OS_CRITICAL_METHOD == 3u                 /* Allocate storage for CPU status register               */
; OS_CPU_SR   cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; if (OSSafetyCriticalStartFlag == OS_TRUE) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (OS_ERR_ILLEGAL_CREATE_RUN_TIME);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio > OS_LOWEST_PRIO) {             /* Make sure priority is within allowable range           */
; return (OS_ERR_PRIO_INVALID);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSIntNesting > 0u) {                 /* Make sure we don't create the task from within an ISR  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTaskCreate_1
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_CREATE_ISR);
       moveq     #60,D0
       bra       OSTaskCreate_3
OSTaskCreate_1:
; }
; if (OSTCBPrioTbl[prio] == (OS_TCB *)0) { /* Make sure task doesn't already exist at this priority  */
       and.l     #255,D2
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A2,D0.L),D0
       bne       OSTaskCreate_4
; OSTCBPrioTbl[prio] = OS_TCB_RESERVED;/* Reserve the priority to prevent others from doing ...  */
       and.l     #255,D2
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    #1,0(A2,D0.L)
; /* ... the same thing until task is created.              */
; OS_EXIT_CRITICAL();
       dc.w      18143
; psp = OSTaskStkInit(task, p_arg, ptos, 0u);             /* Initialize the task's stack         */
       clr.l     -(A7)
       move.l    16(A6),-(A7)
       move.l    12(A6),-(A7)
       move.l    8(A6),-(A7)
       jsr       _OSTaskStkInit
       add.w     #16,A7
       move.l    D0,-4(A6)
; err = OS_TCBInit(prio, psp, (OS_STK *)0, 0u, 0u, (void *)0, 0u);
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    -4(A6),-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _OS_TCBInit
       add.w     #28,A7
       move.b    D0,D3
; if (err == OS_ERR_NONE) {
       tst.b     D3
       bne.s     OSTaskCreate_6
; if (OSRunning == OS_TRUE) {      /* Find highest priority task if multitasking has started */
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne.s     OSTaskCreate_8
; OS_Sched();
       jsr       _OS_Sched
OSTaskCreate_8:
       bra.s     OSTaskCreate_7
OSTaskCreate_6:
; }
; } else {
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSTCBPrioTbl[prio] = (OS_TCB *)0;/* Make this priority available to others                 */
       and.l     #255,D2
       move.l    D2,D0
       lsl.l     #2,D0
       clr.l     0(A2,D0.L)
; OS_EXIT_CRITICAL();
       dc.w      18143
OSTaskCreate_7:
; }
; return (err);
       move.b    D3,D0
       bra.s     OSTaskCreate_3
OSTaskCreate_4:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_PRIO_EXIST);
       moveq     #40,D0
OSTaskCreate_3:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                  CREATE A TASK (Extended Version)
; *
; * Description: This function is used to have uC/OS-II manage the execution of a task.  Tasks can either
; *              be created prior to the start of multitasking or by a running task.  A task cannot be
; *              created by an ISR.  This function is similar to OSTaskCreate() except that it allows
; *              additional information about a task to be specified.
; *
; * Arguments  : task      is a pointer to the task's code
; *
; *              p_arg     is a pointer to an optional data area which can be used to pass parameters to
; *                        the task when the task first executes.  Where the task is concerned it thinks
; *                        it was invoked and passed the argument 'p_arg' as follows:
; *
; *                            void Task (void *p_arg)
; *                            {
; *                                for (;;) {
; *                                    Task code;
; *                                }
; *                            }
; *
; *              ptos      is a pointer to the task's top of stack.  If the configuration constant
; *                        OS_STK_GROWTH is set to 1, the stack is assumed to grow downward (i.e. from high
; *                        memory to low memory).  'ptos' will thus point to the highest (valid) memory
; *                        location of the stack.  If OS_STK_GROWTH is set to 0, 'ptos' will point to the
; *                        lowest memory location of the stack and the stack will grow with increasing
; *                        memory locations.  'ptos' MUST point to a valid 'free' data item.
; *
; *              prio      is the task's priority.  A unique priority MUST be assigned to each task and the
; *                        lower the number, the higher the priority.
; *
; *              id        is the task's ID (0..65535)
; *
; *              pbos      is a pointer to the task's bottom of stack.  If the configuration constant
; *                        OS_STK_GROWTH is set to 1, the stack is assumed to grow downward (i.e. from high
; *                        memory to low memory).  'pbos' will thus point to the LOWEST (valid) memory
; *                        location of the stack.  If OS_STK_GROWTH is set to 0, 'pbos' will point to the
; *                        HIGHEST memory location of the stack and the stack will grow with increasing
; *                        memory locations.  'pbos' MUST point to a valid 'free' data item.
; *
; *              stk_size  is the size of the stack in number of elements.  If OS_STK is set to INT8U,
; *                        'stk_size' corresponds to the number of bytes available.  If OS_STK is set to
; *                        INT16U, 'stk_size' contains the number of 16-bit entries available.  Finally, if
; *                        OS_STK is set to INT32U, 'stk_size' contains the number of 32-bit entries
; *                        available on the stack.
; *
; *              pext      is a pointer to a user supplied memory location which is used as a TCB extension.
; *                        For example, this user memory can hold the contents of floating-point registers
; *                        during a context switch, the time each task takes to execute, the number of times
; *                        the task has been switched-in, etc.
; *
; *              opt       contains additional information (or options) about the behavior of the task.  The
; *                        LOWER 8-bits are reserved by uC/OS-II while the upper 8 bits can be application
; *                        specific.  See OS_TASK_OPT_??? in uCOS-II.H.  Current choices are:
; *
; *                        OS_TASK_OPT_STK_CHK      Stack checking to be allowed for the task
; *                        OS_TASK_OPT_STK_CLR      Clear the stack when the task is created
; *                        OS_TASK_OPT_SAVE_FP      If the CPU has floating-point registers, save them
; *                                                 during a context switch.
; *
; * Returns    : OS_ERR_NONE                      if the function was successful.
; *              OS_ERR_PRIO_EXIST                if the task priority already exist
; *                                               (each task MUST have a unique priority).
; *              OS_ERR_PRIO_INVALID              if the priority you specify is higher that the maximum
; *                                               allowed (i.e. > OS_LOWEST_PRIO)
; *              OS_ERR_TASK_CREATE_ISR           if you tried to create a task from an ISR.
; *              OS_ERR_ILLEGAL_CREATE_RUN_TIME   if you tried to create a task after safety critical
; *                                               operation started.
; *********************************************************************************************************
; */
; /*$PAGE*/
; #if OS_TASK_CREATE_EXT_EN > 0u
; INT8U  OSTaskCreateExt (void   (*task)(void *p_arg),
; void    *p_arg,
; OS_STK  *ptos,
; INT8U    prio,
; INT16U   id,
; OS_STK  *pbos,
; INT32U   stk_size,
; void    *pext,
; INT16U   opt)
; {
       xdef      _OSTaskCreateExt
_OSTaskCreateExt:
       link      A6,#-4
       movem.l   D2/D3/D4/A2,-(A7)
       move.b    23(A6),D2
       and.l     #255,D2
       move.w    42(A6),D4
       and.l     #65535,D4
       lea       _OSTCBPrioTbl.L,A2
; OS_STK     *psp;
; INT8U       err;
; #if OS_CRITICAL_METHOD == 3u                 /* Allocate storage for CPU status register               */
; OS_CPU_SR   cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; if (OSSafetyCriticalStartFlag == OS_TRUE) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (OS_ERR_ILLEGAL_CREATE_RUN_TIME);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio > OS_LOWEST_PRIO) {             /* Make sure priority is within allowable range           */
; return (OS_ERR_PRIO_INVALID);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSIntNesting > 0u) {                 /* Make sure we don't create the task from within an ISR  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTaskCreateExt_1
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_CREATE_ISR);
       moveq     #60,D0
       bra       OSTaskCreateExt_3
OSTaskCreateExt_1:
; }
; if (OSTCBPrioTbl[prio] == (OS_TCB *)0) { /* Make sure task doesn't already exist at this priority  */
       and.l     #255,D2
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A2,D0.L),D0
       bne       OSTaskCreateExt_4
; OSTCBPrioTbl[prio] = OS_TCB_RESERVED;/* Reserve the priority to prevent others from doing ...  */
       and.l     #255,D2
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    #1,0(A2,D0.L)
; /* ... the same thing until task is created.              */
; OS_EXIT_CRITICAL();
       dc.w      18143
; #if (OS_TASK_STAT_STK_CHK_EN > 0u)
; OS_TaskStkClr(pbos, stk_size, opt);                    /* Clear the task stack (if needed)     */
       and.l     #65535,D4
       move.l    D4,-(A7)
       move.l    32(A6),-(A7)
       move.l    28(A6),-(A7)
       jsr       _OS_TaskStkClr
       add.w     #12,A7
; #endif
; psp = OSTaskStkInit(task, p_arg, ptos, opt);           /* Initialize the task's stack          */
       and.l     #65535,D4
       move.l    D4,-(A7)
       move.l    16(A6),-(A7)
       move.l    12(A6),-(A7)
       move.l    8(A6),-(A7)
       jsr       _OSTaskStkInit
       add.w     #16,A7
       move.l    D0,-4(A6)
; err = OS_TCBInit(prio, psp, pbos, id, stk_size, pext, opt);
       and.l     #65535,D4
       move.l    D4,-(A7)
       move.l    36(A6),-(A7)
       move.l    32(A6),-(A7)
       move.w    26(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    28(A6),-(A7)
       move.l    -4(A6),-(A7)
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _OS_TCBInit
       add.w     #28,A7
       move.b    D0,D3
; if (err == OS_ERR_NONE) {
       tst.b     D3
       bne.s     OSTaskCreateExt_6
; if (OSRunning == OS_TRUE) {                        /* Find HPT if multitasking has started */
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne.s     OSTaskCreateExt_8
; OS_Sched();
       jsr       _OS_Sched
OSTaskCreateExt_8:
       bra.s     OSTaskCreateExt_7
OSTaskCreateExt_6:
; }
; } else {
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSTCBPrioTbl[prio] = (OS_TCB *)0;                  /* Make this priority avail. to others  */
       and.l     #255,D2
       move.l    D2,D0
       lsl.l     #2,D0
       clr.l     0(A2,D0.L)
; OS_EXIT_CRITICAL();
       dc.w      18143
OSTaskCreateExt_7:
; }
; return (err);
       move.b    D3,D0
       bra.s     OSTaskCreateExt_3
OSTaskCreateExt_4:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_PRIO_EXIST);
       moveq     #40,D0
OSTaskCreateExt_3:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                            DELETE A TASK
; *
; * Description: This function allows you to delete a task.  The calling task can delete itself by
; *              its own priority number.  The deleted task is returned to the dormant state and can be
; *              re-activated by creating the deleted task again.
; *
; * Arguments  : prio    is the priority of the task to delete.  Note that you can explicitly delete
; *                      the current task without knowing its priority level by setting 'prio' to
; *                      OS_PRIO_SELF.
; *
; * Returns    : OS_ERR_NONE             if the call is successful
; *              OS_ERR_TASK_DEL_IDLE    if you attempted to delete uC/OS-II's idle task
; *              OS_ERR_PRIO_INVALID     if the priority you specify is higher that the maximum allowed
; *                                      (i.e. >= OS_LOWEST_PRIO) or, you have not specified OS_PRIO_SELF.
; *              OS_ERR_TASK_DEL         if the task is assigned to a Mutex PIP.
; *              OS_ERR_TASK_NOT_EXIST   if the task you want to delete does not exist.
; *              OS_ERR_TASK_DEL_ISR     if you tried to delete a task from an ISR
; *
; * Notes      : 1) To reduce interrupt latency, OSTaskDel() 'disables' the task:
; *                    a) by making it not ready
; *                    b) by removing it from any wait lists
; *                    c) by preventing OSTimeTick() from making the task ready to run.
; *                 The task can then be 'unlinked' from the miscellaneous structures in uC/OS-II.
; *              2) The function OS_Dummy() is called after OS_EXIT_CRITICAL() because, on most processors,
; *                 the next instruction following the enable interrupt instruction is ignored.
; *              3) An ISR cannot delete a task.
; *              4) The lock nesting counter is incremented because, for a brief instant, if the current
; *                 task is being deleted, the current task would not be able to be rescheduled because it
; *                 is removed from the ready list.  Incrementing the nesting counter prevents another task
; *                 from being schedule.  This means that an ISR would return to the current task which is
; *                 being deleted.  The rest of the deletion would thus be able to be completed.
; *********************************************************************************************************
; */
; #if OS_TASK_DEL_EN > 0u
; INT8U  OSTaskDel (INT8U prio)
; {
       xdef      _OSTaskDel
_OSTaskDel:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
       move.b    11(A6),D3
       and.l     #255,D3
; #if (OS_FLAG_EN > 0u) && (OS_MAX_FLAGS > 0u)
; OS_FLAG_NODE *pnode;
; #endif
; OS_TCB       *ptcb;
; #if OS_CRITICAL_METHOD == 3u                            /* Allocate storage for CPU status register    */
; OS_CPU_SR     cpu_sr = 0u;
; #endif
; if (OSIntNesting > 0u) {                            /* See if trying to delete from ISR            */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTaskDel_1
; return (OS_ERR_TASK_DEL_ISR);
       moveq     #64,D0
       bra       OSTaskDel_3
OSTaskDel_1:
; }
; if (prio == OS_TASK_IDLE_PRIO) {                    /* Not allowed to delete idle task             */
       cmp.b     #63,D3
       bne.s     OSTaskDel_4
; return (OS_ERR_TASK_DEL_IDLE);
       moveq     #62,D0
       bra       OSTaskDel_3
OSTaskDel_4:
; }
; #if OS_ARG_CHK_EN > 0u
; if (prio >= OS_LOWEST_PRIO) {                       /* Task priority valid ?                       */
; if (prio != OS_PRIO_SELF) {
; return (OS_ERR_PRIO_INVALID);
; }
; }
; #endif
; /*$PAGE*/
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (prio == OS_PRIO_SELF) {                         /* See if requesting to delete self            */
       cmp.b     #255,D3
       bne.s     OSTaskDel_6
; prio = OSTCBCur->OSTCBPrio;                     /* Set priority to delete to current           */
       move.l    _OSTCBCur.L,A0
       move.b    52(A0),D3
OSTaskDel_6:
; }
; ptcb = OSTCBPrioTbl[prio];
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb == (OS_TCB *)0) {                          /* Task to delete must exist                   */
       tst.l     D2
       bne.s     OSTaskDel_8
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);
       moveq     #67,D0
       bra       OSTaskDel_3
OSTaskDel_8:
; }
; if (ptcb == OS_TCB_RESERVED) {                      /* Must not be assigned to Mutex               */
       cmp.l     #1,D2
       bne.s     OSTaskDel_10
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_DEL);
       moveq     #61,D0
       bra       OSTaskDel_3
OSTaskDel_10:
; }
; OSRdyTbl[ptcb->OSTCBY] &= (OS_PRIO)~ptcb->OSTCBBitX;
       move.l    D2,A0
       move.b    54(A0),D0
       and.l     #255,D0
       lea       _OSRdyTbl.L,A0
       move.l    D2,A1
       move.b    55(A1),D1
       not.b     D1
       and.b     D1,0(A0,D0.L)
; if (OSRdyTbl[ptcb->OSTCBY] == 0u) {                 /* Make task not ready                         */
       move.l    D2,A0
       move.b    54(A0),D0
       and.l     #255,D0
       lea       _OSRdyTbl.L,A0
       move.b    0(A0,D0.L),D0
       bne.s     OSTaskDel_12
; OSRdyGrp           &= (OS_PRIO)~ptcb->OSTCBBitY;
       move.l    D2,A0
       move.b    56(A0),D0
       not.b     D0
       and.b     D0,_OSRdyGrp.L
OSTaskDel_12:
; }
; #if (OS_EVENT_EN)
; if (ptcb->OSTCBEventPtr != (OS_EVENT *)0) {
       move.l    D2,A0
       move.l    28(A0),D0
       beq.s     OSTaskDel_14
; OS_EventTaskRemove(ptcb, ptcb->OSTCBEventPtr);  /* Remove this task from any event   wait list */
       move.l    D2,A0
       move.l    28(A0),-(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRemove
       addq.w    #8,A7
OSTaskDel_14:
; }
; #if (OS_EVENT_MULTI_EN > 0u)
; if (ptcb->OSTCBEventMultiPtr != (OS_EVENT **)0) {   /* Remove this task from any events' wait lists*/
       move.l    D2,A0
       move.l    32(A0),D0
       beq.s     OSTaskDel_16
; OS_EventTaskRemoveMulti(ptcb, ptcb->OSTCBEventMultiPtr);
       move.l    D2,A0
       move.l    32(A0),-(A7)
       move.l    D2,-(A7)
       jsr       _OS_EventTaskRemoveMulti
       addq.w    #8,A7
OSTaskDel_16:
; }
; #endif
; #endif
; #if (OS_FLAG_EN > 0u) && (OS_MAX_FLAGS > 0u)
; pnode = ptcb->OSTCBFlagNode;
       move.l    D2,A0
       move.l    40(A0),D4
; if (pnode != (OS_FLAG_NODE *)0) {                   /* If task is waiting on event flag            */
       tst.l     D4
       beq.s     OSTaskDel_18
; OS_FlagUnlink(pnode);                           /* Remove from wait list                       */
       move.l    D4,-(A7)
       jsr       _OS_FlagUnlink
       addq.w    #4,A7
OSTaskDel_18:
; }
; #endif
; ptcb->OSTCBDly      = 0u;                           /* Prevent OSTimeTick() from updating          */
       move.l    D2,A0
       clr.l     46(A0)
; ptcb->OSTCBStat     = OS_STAT_RDY;                  /* Prevent task from being resumed             */
       move.l    D2,A0
       clr.b     50(A0)
; ptcb->OSTCBStatPend = OS_STAT_PEND_OK;
       move.l    D2,A0
       clr.b     51(A0)
; if (OSLockNesting < 255u) {                         /* Make sure we don't context switch           */
       move.b    _OSLockNesting.L,D0
       cmp.b     #255,D0
       bhs.s     OSTaskDel_20
; OSLockNesting++;
       addq.b    #1,_OSLockNesting.L
OSTaskDel_20:
; }
; OS_EXIT_CRITICAL();                                 /* Enabling INT. ignores next instruc.         */
       dc.w      18143
; OS_Dummy();                                         /* ... Dummy ensures that INTs will be         */
       jsr       _OS_Dummy
; OS_ENTER_CRITICAL();                                /* ... disabled HERE!                          */
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSLockNesting > 0u) {                           /* Remove context switch lock                  */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTaskDel_22
; OSLockNesting--;
       subq.b    #1,_OSLockNesting.L
OSTaskDel_22:
; }
; OSTaskDelHook(ptcb);                                /* Call user defined hook                      */
       move.l    D2,-(A7)
       jsr       _OSTaskDelHook
       addq.w    #4,A7
; OSTaskCtr--;                                        /* One less task being managed                 */
       subq.b    #1,_OSTaskCtr.L
; OSTCBPrioTbl[prio] = (OS_TCB *)0;                   /* Clear old priority entry                    */
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       clr.l     0(A0,D0.L)
; if (ptcb->OSTCBPrev == (OS_TCB *)0) {               /* Remove from TCB chain                       */
       move.l    D2,A0
       move.l    24(A0),D0
       bne.s     OSTaskDel_24
; ptcb->OSTCBNext->OSTCBPrev = (OS_TCB *)0;
       move.l    D2,A0
       move.l    20(A0),A0
       clr.l     24(A0)
; OSTCBList                  = ptcb->OSTCBNext;
       move.l    D2,A0
       move.l    20(A0),_OSTCBList.L
       bra.s     OSTaskDel_25
OSTaskDel_24:
; } else {
; ptcb->OSTCBPrev->OSTCBNext = ptcb->OSTCBNext;
       move.l    D2,A0
       move.l    D2,A1
       move.l    24(A1),A1
       move.l    20(A0),20(A1)
; ptcb->OSTCBNext->OSTCBPrev = ptcb->OSTCBPrev;
       move.l    D2,A0
       move.l    D2,A1
       move.l    20(A1),A1
       move.l    24(A0),24(A1)
OSTaskDel_25:
; }
; ptcb->OSTCBNext     = OSTCBFreeList;                /* Return TCB to free TCB list                 */
       move.l    D2,A0
       move.l    _OSTCBFreeList.L,20(A0)
; OSTCBFreeList       = ptcb;
       move.l    D2,_OSTCBFreeList.L
; #if OS_TASK_NAME_EN > 0u
; ptcb->OSTCBTaskName = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,78(A1)
; #endif
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (OSRunning == OS_TRUE) {
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne.s     OSTaskDel_26
; OS_Sched();                                     /* Find new highest priority task              */
       jsr       _OS_Sched
OSTaskDel_26:
; }
; return (OS_ERR_NONE);
       clr.b     D0
OSTaskDel_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                  REQUEST THAT A TASK DELETE ITSELF
; *
; * Description: This function is used to:
; *                   a) notify a task to delete itself.
; *                   b) to see if a task requested that the current task delete itself.
; *              This function is a little tricky to understand.  Basically, you have a task that needs
; *              to be deleted however, this task has resources that it has allocated (memory buffers,
; *              semaphores, mailboxes, queues etc.).  The task cannot be deleted otherwise these
; *              resources would not be freed.  The requesting task calls OSTaskDelReq() to indicate that
; *              the task needs to be deleted.  Deleting of the task is however, deferred to the task to
; *              be deleted.  For example, suppose that task #10 needs to be deleted.  The requesting task
; *              example, task #5, would call OSTaskDelReq(10).  When task #10 gets to execute, it calls
; *              this function by specifying OS_PRIO_SELF and monitors the returned value.  If the return
; *              value is OS_ERR_TASK_DEL_REQ, another task requested a task delete.  Task #10 would look like
; *              this:
; *
; *                   void Task(void *p_arg)
; *                   {
; *                       .
; *                       .
; *                       while (1) {
; *                           OSTimeDly(1);
; *                           if (OSTaskDelReq(OS_PRIO_SELF) == OS_ERR_TASK_DEL_REQ) {
; *                               Release any owned resources;
; *                               De-allocate any dynamic memory;
; *                               OSTaskDel(OS_PRIO_SELF);
; *                           }
; *                       }
; *                   }
; *
; * Arguments  : prio    is the priority of the task to request the delete from
; *
; * Returns    : OS_ERR_NONE            if the task exist and the request has been registered
; *              OS_ERR_TASK_NOT_EXIST  if the task has been deleted.  This allows the caller to know whether
; *                                     the request has been executed.
; *              OS_ERR_TASK_DEL        if the task is assigned to a Mutex.
; *              OS_ERR_TASK_DEL_IDLE   if you requested to delete uC/OS-II's idle task
; *              OS_ERR_PRIO_INVALID    if the priority you specify is higher that the maximum allowed
; *                                     (i.e. >= OS_LOWEST_PRIO) or, you have not specified OS_PRIO_SELF.
; *              OS_ERR_TASK_DEL_REQ    if a task (possibly another task) requested that the running task be
; *                                     deleted.
; *********************************************************************************************************
; */
; /*$PAGE*/
; #if OS_TASK_DEL_EN > 0u
; INT8U  OSTaskDelReq (INT8U prio)
; {
       xdef      _OSTaskDelReq
_OSTaskDelReq:
       link      A6,#-4
       movem.l   D2/D3,-(A7)
       move.b    11(A6),D3
       and.l     #255,D3
; INT8U      stat;
; OS_TCB    *ptcb;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; if (prio == OS_TASK_IDLE_PRIO) {                            /* Not allowed to delete idle task     */
       cmp.b     #63,D3
       bne.s     OSTaskDelReq_1
; return (OS_ERR_TASK_DEL_IDLE);
       moveq     #62,D0
       bra       OSTaskDelReq_3
OSTaskDelReq_1:
; }
; #if OS_ARG_CHK_EN > 0u
; if (prio >= OS_LOWEST_PRIO) {                               /* Task priority valid ?               */
; if (prio != OS_PRIO_SELF) {
; return (OS_ERR_PRIO_INVALID);
; }
; }
; #endif
; if (prio == OS_PRIO_SELF) {                                 /* See if a task is requesting to ...  */
       cmp.b     #255,D3
       bne.s     OSTaskDelReq_4
; OS_ENTER_CRITICAL();                                    /* ... this task to delete itself      */
       dc.w      16615
       dc.w      124
       dc.w      1792
; stat = OSTCBCur->OSTCBDelReq;                           /* Return request status to caller     */
       move.l    _OSTCBCur.L,A0
       move.b    57(A0),-1(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (stat);
       move.b    -1(A6),D0
       bra       OSTaskDelReq_3
OSTaskDelReq_4:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; ptcb = OSTCBPrioTbl[prio];
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb == (OS_TCB *)0) {                                  /* Task to delete must exist           */
       tst.l     D2
       bne.s     OSTaskDelReq_6
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);                         /* Task must already be deleted        */
       moveq     #67,D0
       bra.s     OSTaskDelReq_3
OSTaskDelReq_6:
; }
; if (ptcb == OS_TCB_RESERVED) {                              /* Must NOT be assigned to a Mutex     */
       cmp.l     #1,D2
       bne.s     OSTaskDelReq_8
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_DEL);
       moveq     #61,D0
       bra.s     OSTaskDelReq_3
OSTaskDelReq_8:
; }
; ptcb->OSTCBDelReq = OS_ERR_TASK_DEL_REQ;                    /* Set flag indicating task to be DEL. */
       move.l    D2,A0
       move.b    #63,57(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSTaskDelReq_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       GET THE NAME OF A TASK
; *
; * Description: This function is called to obtain the name of a task.
; *
; * Arguments  : prio      is the priority of the task that you want to obtain the name from.
; *
; *              pname     is a pointer to a pointer to an ASCII string that will receive the name of the task.
; *
; *              perr      is a pointer to an error code that can contain one of the following values:
; *
; *                        OS_ERR_NONE                if the requested task is resumed
; *                        OS_ERR_TASK_NOT_EXIST      if the task has not been created or is assigned to a Mutex
; *                        OS_ERR_PRIO_INVALID        if you specified an invalid priority:
; *                                                   A higher value than the idle task or not OS_PRIO_SELF.
; *                        OS_ERR_PNAME_NULL          You passed a NULL pointer for 'pname'
; *                        OS_ERR_NAME_GET_ISR        You called this function from an ISR
; *
; *
; * Returns    : The length of the string or 0 if the task does not exist.
; *********************************************************************************************************
; */
; #if OS_TASK_NAME_EN > 0u
; INT8U  OSTaskNameGet (INT8U    prio,
; INT8U  **pname,
; INT8U   *perr)
; {
       xdef      _OSTaskNameGet
_OSTaskNameGet:
       link      A6,#-4
       movem.l   D2/D3/D4,-(A7)
       move.l    16(A6),D3
       move.b    11(A6),D4
       and.l     #255,D4
; OS_TCB    *ptcb;
; INT8U      len;
; #if OS_CRITICAL_METHOD == 3u                             /* Allocate storage for CPU status register   */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio > OS_LOWEST_PRIO) {                         /* Task priority valid ?                      */
; if (prio != OS_PRIO_SELF) {
; *perr = OS_ERR_PRIO_INVALID;                 /* No                                         */
; return (0u);
; }
; }
; if (pname == (INT8U **)0) {                          /* Is 'pname' a NULL pointer?                 */
; *perr = OS_ERR_PNAME_NULL;                       /* Yes                                        */
; return (0u);
; }
; #endif
; if (OSIntNesting > 0u) {                              /* See if trying to call from an ISR          */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTaskNameGet_1
; *perr = OS_ERR_NAME_GET_ISR;
       move.l    D3,A0
       move.b    #17,(A0)
; return (0u);
       clr.b     D0
       bra       OSTaskNameGet_3
OSTaskNameGet_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (prio == OS_PRIO_SELF) {                          /* See if caller desires it's own name        */
       cmp.b     #255,D4
       bne.s     OSTaskNameGet_4
; prio = OSTCBCur->OSTCBPrio;
       move.l    _OSTCBCur.L,A0
       move.b    52(A0),D4
OSTaskNameGet_4:
; }
; ptcb = OSTCBPrioTbl[prio];
       and.l     #255,D4
       move.l    D4,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb == (OS_TCB *)0) {                           /* Does task exist?                           */
       tst.l     D2
       bne.s     OSTaskNameGet_6
; OS_EXIT_CRITICAL();                              /* No                                         */
       dc.w      18143
; *perr = OS_ERR_TASK_NOT_EXIST;
       move.l    D3,A0
       move.b    #67,(A0)
; return (0u);
       clr.b     D0
       bra       OSTaskNameGet_3
OSTaskNameGet_6:
; }
; if (ptcb == OS_TCB_RESERVED) {                       /* Task assigned to a Mutex?                  */
       cmp.l     #1,D2
       bne.s     OSTaskNameGet_8
; OS_EXIT_CRITICAL();                              /* Yes                                        */
       dc.w      18143
; *perr = OS_ERR_TASK_NOT_EXIST;
       move.l    D3,A0
       move.b    #67,(A0)
; return (0u);
       clr.b     D0
       bra.s     OSTaskNameGet_3
OSTaskNameGet_8:
; }
; *pname = ptcb->OSTCBTaskName;
       move.l    D2,A0
       move.l    12(A6),A1
       move.l    78(A0),(A1)
; len    = OS_StrLen(*pname);
       move.l    12(A6),A0
       move.l    (A0),-(A7)
       jsr       _OS_StrLen
       addq.w    #4,A7
       move.b    D0,-1(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr  = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; return (len);
       move.b    -1(A6),D0
OSTaskNameGet_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       ASSIGN A NAME TO A TASK
; *
; * Description: This function is used to set the name of a task.
; *
; * Arguments  : prio      is the priority of the task that you want the assign a name to.
; *
; *              pname     is a pointer to an ASCII string that contains the name of the task.
; *
; *              perr       is a pointer to an error code that can contain one of the following values:
; *
; *                        OS_ERR_NONE                if the requested task is resumed
; *                        OS_ERR_TASK_NOT_EXIST      if the task has not been created or is assigned to a Mutex
; *                        OS_ERR_PNAME_NULL          You passed a NULL pointer for 'pname'
; *                        OS_ERR_PRIO_INVALID        if you specified an invalid priority:
; *                                                   A higher value than the idle task or not OS_PRIO_SELF.
; *                        OS_ERR_NAME_SET_ISR        if you called this function from an ISR
; *
; * Returns    : None
; *********************************************************************************************************
; */
; #if OS_TASK_NAME_EN > 0u
; void  OSTaskNameSet (INT8U   prio,
; INT8U  *pname,
; INT8U  *perr)
; {
       xdef      _OSTaskNameSet
_OSTaskNameSet:
       link      A6,#0
       movem.l   D2/D3/D4,-(A7)
       move.l    16(A6),D3
       move.b    11(A6),D4
       and.l     #255,D4
; OS_TCB    *ptcb;
; #if OS_CRITICAL_METHOD == 3u                         /* Allocate storage for CPU status register       */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return;
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio > OS_LOWEST_PRIO) {                     /* Task priority valid ?                          */
; if (prio != OS_PRIO_SELF) {
; *perr = OS_ERR_PRIO_INVALID;             /* No                                             */
; return;
; }
; }
; if (pname == (INT8U *)0) {                       /* Is 'pname' a NULL pointer?                     */
; *perr = OS_ERR_PNAME_NULL;                   /* Yes                                            */
; return;
; }
; #endif
; if (OSIntNesting > 0u) {                         /* See if trying to call from an ISR              */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTaskNameSet_1
; *perr = OS_ERR_NAME_SET_ISR;
       move.l    D3,A0
       move.b    #18,(A0)
; return;
       bra       OSTaskNameSet_3
OSTaskNameSet_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (prio == OS_PRIO_SELF) {                      /* See if caller desires to set it's own name     */
       cmp.b     #255,D4
       bne.s     OSTaskNameSet_4
; prio = OSTCBCur->OSTCBPrio;
       move.l    _OSTCBCur.L,A0
       move.b    52(A0),D4
OSTaskNameSet_4:
; }
; ptcb = OSTCBPrioTbl[prio];
       and.l     #255,D4
       move.l    D4,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb == (OS_TCB *)0) {                       /* Does task exist?                               */
       tst.l     D2
       bne.s     OSTaskNameSet_6
; OS_EXIT_CRITICAL();                          /* No                                             */
       dc.w      18143
; *perr = OS_ERR_TASK_NOT_EXIST;
       move.l    D3,A0
       move.b    #67,(A0)
; return;
       bra.s     OSTaskNameSet_3
OSTaskNameSet_6:
; }
; if (ptcb == OS_TCB_RESERVED) {                   /* Task assigned to a Mutex?                      */
       cmp.l     #1,D2
       bne.s     OSTaskNameSet_8
; OS_EXIT_CRITICAL();                          /* Yes                                            */
       dc.w      18143
; *perr = OS_ERR_TASK_NOT_EXIST;
       move.l    D3,A0
       move.b    #67,(A0)
; return;
       bra.s     OSTaskNameSet_3
OSTaskNameSet_8:
; }
; ptcb->OSTCBTaskName = pname;
       move.l    D2,A0
       move.l    12(A6),78(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr               = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
OSTaskNameSet_3:
       movem.l   (A7)+,D2/D3/D4
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       RESUME A SUSPENDED TASK
; *
; * Description: This function is called to resume a previously suspended task.  This is the only call that
; *              will remove an explicit task suspension.
; *
; * Arguments  : prio     is the priority of the task to resume.
; *
; * Returns    : OS_ERR_NONE                if the requested task is resumed
; *              OS_ERR_PRIO_INVALID        if the priority you specify is higher that the maximum allowed
; *                                         (i.e. >= OS_LOWEST_PRIO)
; *              OS_ERR_TASK_RESUME_PRIO    if the task to resume does not exist
; *              OS_ERR_TASK_NOT_EXIST      if the task is assigned to a Mutex PIP
; *              OS_ERR_TASK_NOT_SUSPENDED  if the task to resume has not been suspended
; *********************************************************************************************************
; */
; #if OS_TASK_SUSPEND_EN > 0u
; INT8U  OSTaskResume (INT8U prio)
; {
       xdef      _OSTaskResume
_OSTaskResume:
       link      A6,#0
       move.l    D2,-(A7)
; OS_TCB    *ptcb;
; #if OS_CRITICAL_METHOD == 3u                                  /* Storage for CPU status register       */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio >= OS_LOWEST_PRIO) {                             /* Make sure task priority is valid      */
; return (OS_ERR_PRIO_INVALID);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; ptcb = OSTCBPrioTbl[prio];
       move.b    11(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb == (OS_TCB *)0) {                                /* Task to suspend must exist            */
       tst.l     D2
       bne.s     OSTaskResume_1
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_RESUME_PRIO);
       moveq     #70,D0
       bra       OSTaskResume_3
OSTaskResume_1:
; }
; if (ptcb == OS_TCB_RESERVED) {                            /* See if assigned to Mutex              */
       cmp.l     #1,D2
       bne.s     OSTaskResume_4
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);
       moveq     #67,D0
       bra       OSTaskResume_3
OSTaskResume_4:
; }
; if ((ptcb->OSTCBStat & OS_STAT_SUSPEND) != OS_STAT_RDY) { /* Task must be suspended                */
       move.l    D2,A0
       move.b    50(A0),D0
       and.b     #8,D0
       beq       OSTaskResume_6
; ptcb->OSTCBStat &= (INT8U)~(INT8U)OS_STAT_SUSPEND;    /* Remove suspension                     */
       move.l    D2,A0
       moveq     #8,D0
       not.b     D0
       and.b     D0,50(A0)
; if (ptcb->OSTCBStat == OS_STAT_RDY) {                 /* See if task is now ready              */
       move.l    D2,A0
       move.b    50(A0),D0
       bne       OSTaskResume_8
; if (ptcb->OSTCBDly == 0u) {
       move.l    D2,A0
       move.l    46(A0),D0
       bne       OSTaskResume_10
; OSRdyGrp               |= ptcb->OSTCBBitY;    /* Yes, Make task ready to run           */
       move.l    D2,A0
       move.b    56(A0),D0
       or.b      D0,_OSRdyGrp.L
; OSRdyTbl[ptcb->OSTCBY] |= ptcb->OSTCBBitX;
       move.l    D2,A0
       move.b    54(A0),D0
       and.l     #255,D0
       lea       _OSRdyTbl.L,A0
       move.l    D2,A1
       move.b    55(A1),D1
       or.b      D1,0(A0,D0.L)
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (OSRunning == OS_TRUE) {
       move.b    _OSRunning.L,D0
       cmp.b     #1,D0
       bne.s     OSTaskResume_12
; OS_Sched();                               /* Find new highest priority task        */
       jsr       _OS_Sched
OSTaskResume_12:
       bra.s     OSTaskResume_11
OSTaskResume_10:
; }
; } else {
; OS_EXIT_CRITICAL();
       dc.w      18143
OSTaskResume_11:
       bra.s     OSTaskResume_9
OSTaskResume_8:
; }
; } else {                                              /* Must be pending on event              */
; OS_EXIT_CRITICAL();
       dc.w      18143
OSTaskResume_9:
; }
; return (OS_ERR_NONE);
       clr.b     D0
       bra.s     OSTaskResume_3
OSTaskResume_6:
; }
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_SUSPENDED);
       moveq     #68,D0
OSTaskResume_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           STACK CHECKING
; *
; * Description: This function is called to check the amount of free memory left on the specified task's
; *              stack.
; *
; * Arguments  : prio          is the task priority
; *
; *              p_stk_data    is a pointer to a data structure of type OS_STK_DATA.
; *
; * Returns    : OS_ERR_NONE            upon success
; *              OS_ERR_PRIO_INVALID    if the priority you specify is higher that the maximum allowed
; *                                     (i.e. > OS_LOWEST_PRIO) or, you have not specified OS_PRIO_SELF.
; *              OS_ERR_TASK_NOT_EXIST  if the desired task has not been created or is assigned to a Mutex PIP
; *              OS_ERR_TASK_OPT        if you did NOT specified OS_TASK_OPT_STK_CHK when the task was created
; *              OS_ERR_PDATA_NULL      if 'p_stk_data' is a NULL pointer
; *********************************************************************************************************
; */
; #if (OS_TASK_STAT_STK_CHK_EN > 0u) && (OS_TASK_CREATE_EXT_EN > 0u)
; INT8U  OSTaskStkChk (INT8U         prio,
; OS_STK_DATA  *p_stk_data)
; {
       xdef      _OSTaskStkChk
_OSTaskStkChk:
       link      A6,#-8
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    12(A6),D4
       move.b    11(A6),D5
       and.l     #255,D5
; OS_TCB    *ptcb;
; OS_STK    *pchk;
; INT32U     nfree;
; INT32U     size;
; #if OS_CRITICAL_METHOD == 3u                           /* Allocate storage for CPU status register     */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio > OS_LOWEST_PRIO) {                       /* Make sure task priority is valid             */
; if (prio != OS_PRIO_SELF) {
; return (OS_ERR_PRIO_INVALID);
; }
; }
; if (p_stk_data == (OS_STK_DATA *)0) {              /* Validate 'p_stk_data'                        */
; return (OS_ERR_PDATA_NULL);
; }
; #endif
; p_stk_data->OSFree = 0u;                           /* Assume failure, set to 0 size                */
       move.l    D4,A0
       clr.l     (A0)
; p_stk_data->OSUsed = 0u;
       move.l    D4,A0
       clr.l     4(A0)
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (prio == OS_PRIO_SELF) {                        /* See if check for SELF                        */
       cmp.b     #255,D5
       bne.s     OSTaskStkChk_1
; prio = OSTCBCur->OSTCBPrio;
       move.l    _OSTCBCur.L,A0
       move.b    52(A0),D5
OSTaskStkChk_1:
; }
; ptcb = OSTCBPrioTbl[prio];
       and.l     #255,D5
       move.l    D5,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb == (OS_TCB *)0) {                         /* Make sure task exist                         */
       tst.l     D2
       bne.s     OSTaskStkChk_3
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);
       moveq     #67,D0
       bra       OSTaskStkChk_5
OSTaskStkChk_3:
; }
; if (ptcb == OS_TCB_RESERVED) {
       cmp.l     #1,D2
       bne.s     OSTaskStkChk_6
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);
       moveq     #67,D0
       bra       OSTaskStkChk_5
OSTaskStkChk_6:
; }
; if ((ptcb->OSTCBOpt & OS_TASK_OPT_STK_CHK) == 0u) { /* Make sure stack checking option is set      */
       move.l    D2,A0
       move.w    16(A0),D0
       and.w     #1,D0
       bne.s     OSTaskStkChk_8
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_OPT);
       moveq     #69,D0
       bra       OSTaskStkChk_5
OSTaskStkChk_8:
; }
; nfree = 0u;
       clr.l     D3
; size  = ptcb->OSTCBStkSize;
       move.l    D2,A0
       move.l    12(A0),-4(A6)
; pchk  = ptcb->OSTCBStkBottom;
       move.l    D2,A0
       move.l    8(A0),-8(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; #if OS_STK_GROWTH == 1u
; while (*pchk++ == (OS_STK)0) {                    /* Compute the number of zero entries on the stk */
OSTaskStkChk_10:
       move.l    -8(A6),A0
       addq.l    #2,-8(A6)
       move.w    (A0),D0
       bne.s     OSTaskStkChk_12
; nfree++;
       addq.l    #1,D3
       bra       OSTaskStkChk_10
OSTaskStkChk_12:
; }
; #else
; while (*pchk-- == (OS_STK)0) {
; nfree++;
; }
; #endif
; p_stk_data->OSFree = nfree;                       /* Store   number of free entries on the stk     */
       move.l    D4,A0
       move.l    D3,(A0)
; p_stk_data->OSUsed = size - nfree;                /* Compute number of entries used on the stk     */
       move.l    -4(A6),D0
       sub.l     D3,D0
       move.l    D4,A0
       move.l    D0,4(A0)
; return (OS_ERR_NONE);
       clr.b     D0
OSTaskStkChk_5:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           SUSPEND A TASK
; *
; * Description: This function is called to suspend a task.  The task can be the calling task if the
; *              priority passed to OSTaskSuspend() is the priority of the calling task or OS_PRIO_SELF.
; *
; * Arguments  : prio     is the priority of the task to suspend.  If you specify OS_PRIO_SELF, the
; *                       calling task will suspend itself and rescheduling will occur.
; *
; * Returns    : OS_ERR_NONE               if the requested task is suspended
; *              OS_ERR_TASK_SUSPEND_IDLE  if you attempted to suspend the idle task which is not allowed.
; *              OS_ERR_PRIO_INVALID       if the priority you specify is higher that the maximum allowed
; *                                        (i.e. >= OS_LOWEST_PRIO) or, you have not specified OS_PRIO_SELF.
; *              OS_ERR_TASK_SUSPEND_PRIO  if the task to suspend does not exist
; *              OS_ERR_TASK_NOT_EXITS     if the task is assigned to a Mutex PIP
; *
; * Note       : You should use this function with great care.  If you suspend a task that is waiting for
; *              an event (i.e. a message, a semaphore, a queue ...) you will prevent this task from
; *              running when the event arrives.
; *********************************************************************************************************
; */
; #if OS_TASK_SUSPEND_EN > 0u
; INT8U  OSTaskSuspend (INT8U prio)
; {
       xdef      _OSTaskSuspend
_OSTaskSuspend:
       link      A6,#0
       movem.l   D2/D3/D4/D5,-(A7)
       move.b    11(A6),D4
       and.l     #255,D4
; BOOLEAN    self;
; OS_TCB    *ptcb;
; INT8U      y;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio == OS_TASK_IDLE_PRIO) {                            /* Not allowed to suspend idle task    */
; return (OS_ERR_TASK_SUSPEND_IDLE);
; }
; if (prio >= OS_LOWEST_PRIO) {                               /* Task priority valid ?               */
; if (prio != OS_PRIO_SELF) {
; return (OS_ERR_PRIO_INVALID);
; }
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (prio == OS_PRIO_SELF) {                                 /* See if suspend SELF                 */
       cmp.b     #255,D4
       bne.s     OSTaskSuspend_1
; prio = OSTCBCur->OSTCBPrio;
       move.l    _OSTCBCur.L,A0
       move.b    52(A0),D4
; self = OS_TRUE;
       moveq     #1,D3
       bra.s     OSTaskSuspend_4
OSTaskSuspend_1:
; } else if (prio == OSTCBCur->OSTCBPrio) {                   /* See if suspending self              */
       move.l    _OSTCBCur.L,A0
       cmp.b     52(A0),D4
       bne.s     OSTaskSuspend_3
; self = OS_TRUE;
       moveq     #1,D3
       bra.s     OSTaskSuspend_4
OSTaskSuspend_3:
; } else {
; self = OS_FALSE;                                        /* No suspending another task          */
       clr.b     D3
OSTaskSuspend_4:
; }
; ptcb = OSTCBPrioTbl[prio];
       and.l     #255,D4
       move.l    D4,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb == (OS_TCB *)0) {                                  /* Task to suspend must exist          */
       tst.l     D2
       bne.s     OSTaskSuspend_5
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_SUSPEND_PRIO);
       moveq     #72,D0
       bra       OSTaskSuspend_7
OSTaskSuspend_5:
; }
; if (ptcb == OS_TCB_RESERVED) {                              /* See if assigned to Mutex            */
       cmp.l     #1,D2
       bne.s     OSTaskSuspend_8
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);
       moveq     #67,D0
       bra       OSTaskSuspend_7
OSTaskSuspend_8:
; }
; y            = ptcb->OSTCBY;
       move.l    D2,A0
       move.b    54(A0),D5
; OSRdyTbl[y] &= (OS_PRIO)~ptcb->OSTCBBitX;                   /* Make task not ready                 */
       and.l     #255,D5
       lea       _OSRdyTbl.L,A0
       move.l    D2,A1
       move.b    55(A1),D0
       not.b     D0
       and.b     D0,0(A0,D5.L)
; if (OSRdyTbl[y] == 0u) {
       and.l     #255,D5
       lea       _OSRdyTbl.L,A0
       move.b    0(A0,D5.L),D0
       bne.s     OSTaskSuspend_10
; OSRdyGrp &= (OS_PRIO)~ptcb->OSTCBBitY;
       move.l    D2,A0
       move.b    56(A0),D0
       not.b     D0
       and.b     D0,_OSRdyGrp.L
OSTaskSuspend_10:
; }
; ptcb->OSTCBStat |= OS_STAT_SUSPEND;                         /* Status of task is 'SUSPENDED'       */
       move.l    D2,A0
       or.b      #8,50(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; if (self == OS_TRUE) {                                      /* Context switch only if SELF         */
       cmp.b     #1,D3
       bne.s     OSTaskSuspend_12
; OS_Sched();                                             /* Find new highest priority task      */
       jsr       _OS_Sched
OSTaskSuspend_12:
; }
; return (OS_ERR_NONE);
       clr.b     D0
OSTaskSuspend_7:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                            QUERY A TASK
; *
; * Description: This function is called to obtain a copy of the desired task's TCB.
; *
; * Arguments  : prio         is the priority of the task to obtain information from.
; *
; *              p_task_data  is a pointer to where the desired task's OS_TCB will be stored.
; *
; * Returns    : OS_ERR_NONE            if the requested task is suspended
; *              OS_ERR_PRIO_INVALID    if the priority you specify is higher that the maximum allowed
; *                                     (i.e. > OS_LOWEST_PRIO) or, you have not specified OS_PRIO_SELF.
; *              OS_ERR_PRIO            if the desired task has not been created
; *              OS_ERR_TASK_NOT_EXIST  if the task is assigned to a Mutex PIP
; *              OS_ERR_PDATA_NULL      if 'p_task_data' is a NULL pointer
; *********************************************************************************************************
; */
; #if OS_TASK_QUERY_EN > 0u
; INT8U  OSTaskQuery (INT8U    prio,
; OS_TCB  *p_task_data)
; {
       xdef      _OSTaskQuery
_OSTaskQuery:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.b    11(A6),D3
       and.l     #255,D3
; OS_TCB    *ptcb;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio > OS_LOWEST_PRIO) {                 /* Task priority valid ?                              */
; if (prio != OS_PRIO_SELF) {
; return (OS_ERR_PRIO_INVALID);
; }
; }
; if (p_task_data == (OS_TCB *)0) {            /* Validate 'p_task_data'                             */
; return (OS_ERR_PDATA_NULL);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (prio == OS_PRIO_SELF) {                  /* See if suspend SELF                                */
       cmp.b     #255,D3
       bne.s     OSTaskQuery_1
; prio = OSTCBCur->OSTCBPrio;
       move.l    _OSTCBCur.L,A0
       move.b    52(A0),D3
OSTaskQuery_1:
; }
; ptcb = OSTCBPrioTbl[prio];
       and.l     #255,D3
       move.l    D3,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb == (OS_TCB *)0) {                   /* Task to query must exist                           */
       tst.l     D2
       bne.s     OSTaskQuery_3
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_PRIO);
       moveq     #41,D0
       bra.s     OSTaskQuery_5
OSTaskQuery_3:
; }
; if (ptcb == OS_TCB_RESERVED) {               /* Task to query must not be assigned to a Mutex      */
       cmp.l     #1,D2
       bne.s     OSTaskQuery_6
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);
       moveq     #67,D0
       bra.s     OSTaskQuery_5
OSTaskQuery_6:
; }
; /* Copy TCB into user storage area                    */
; OS_MemCopy((INT8U *)p_task_data, (INT8U *)ptcb, sizeof(OS_TCB));
       pea       86
       move.l    D2,-(A7)
       move.l    12(A6),-(A7)
       jsr       _OS_MemCopy
       add.w     #12,A7
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_NONE);
       clr.b     D0
OSTaskQuery_5:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                              GET THE CURRENT VALUE OF A TASK REGISTER
; *
; * Description: This function is called to obtain the current value of a task register.  Task registers
; *              are application specific and can be used to store task specific values such as 'error
; *              numbers' (i.e. errno), statistics, etc.  Each task register can hold a 32-bit value.
; *
; * Arguments  : prio      is the priority of the task you want to get the task register from.  If you
; *                        specify OS_PRIO_SELF then the task register of the current task will be obtained.
; *
; *              id        is the 'id' of the desired task register.  Note that the 'id' must be less
; *                        than OS_TASK_REG_TBL_SIZE
; *
; *              perr      is a pointer to a variable that will hold an error code related to this call.
; *
; *                        OS_ERR_NONE            if the call was successful
; *                        OS_ERR_PRIO_INVALID    if you specified an invalid priority
; *                        OS_ERR_ID_INVALID      if the 'id' is not between 0 and OS_TASK_REG_TBL_SIZE-1
; *
; * Returns    : The current value of the task's register or 0 if an error is detected.
; *
; * Note(s)    : The maximum number of task variables is 254
; *********************************************************************************************************
; */
; #if OS_TASK_REG_TBL_SIZE > 0u
; INT32U  OSTaskRegGet (INT8U   prio,
; INT8U   id,
; INT8U  *perr)
; {
       xdef      _OSTaskRegGet
_OSTaskRegGet:
       link      A6,#-4
       move.l    D2,-(A7)
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; INT32U     value;
; OS_TCB    *ptcb;
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio >= OS_LOWEST_PRIO) {
; if (prio != OS_PRIO_SELF) {
; *perr = OS_ERR_PRIO_INVALID;
; return (0u);
; }
; }
; if (id >= OS_TASK_REG_TBL_SIZE) {
; *perr = OS_ERR_ID_INVALID;
; return (0u);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (prio == OS_PRIO_SELF) {                  /* See if need to get register from current task      */
       move.b    11(A6),D0
       cmp.b     #255,D0
       bne.s     OSTaskRegGet_1
; ptcb = OSTCBCur;
       move.l    _OSTCBCur.L,D2
       bra.s     OSTaskRegGet_2
OSTaskRegGet_1:
; } else {
; ptcb = OSTCBPrioTbl[prio];
       move.b    11(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
OSTaskRegGet_2:
; }
; value = ptcb->OSTCBRegTbl[id];
       move.l    D2,A0
       move.b    15(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       add.l     D0,A0
       move.l    82(A0),-4(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    16(A6),A0
       clr.b     (A0)
; return (value);
       move.l    -4(A6),D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; ************************************************************************************************************************
; *                                    ALLOCATE THE NEXT AVAILABLE TASK REGISTER ID
; *
; * Description: This function is called to obtain a task register ID.  This function thus allows task registers IDs to be
; *              allocated dynamically instead of statically.
; *
; * Arguments  : p_err       is a pointer to a variable that will hold an error code related to this call.
; *
; *                            OS_ERR_NONE               if the call was successful
; *                            OS_ERR_NO_MORE_ID_AVAIL   if you are attempting to assign more task register IDs than you 
; *                                                           have available through OS_TASK_REG_TBL_SIZE.
; *
; * Returns    : The next available task register 'id' or OS_TASK_REG_TBL_SIZE if an error is detected.
; ************************************************************************************************************************
; */
; #if OS_TASK_REG_TBL_SIZE > 0u
; INT8U  OSTaskRegGetID (INT8U  *perr)
; {
       xdef      _OSTaskRegGetID
_OSTaskRegGetID:
       link      A6,#-4
; #if OS_CRITICAL_METHOD == 3u                                    /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; INT8U      id;
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((INT8U)OS_TASK_REG_TBL_SIZE);
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (OSTaskRegNextAvailID >= OS_TASK_REG_TBL_SIZE) {         /* See if we exceeded the number of IDs available     */
       move.b    _OSTaskRegNextAvailID.L,D0
       cmp.b     #1,D0
       blo.s     OSTaskRegGetID_1
; *perr = OS_ERR_NO_MORE_ID_AVAIL;                         /* Yes, cannot allocate more task register IDs        */
       move.l    8(A6),A0
       move.b    #150,(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return ((INT8U)OS_TASK_REG_TBL_SIZE);
       moveq     #1,D0
       bra.s     OSTaskRegGetID_3
OSTaskRegGetID_1:
; }
; id   = OSTaskRegNextAvailID;                                /* Assign the next available ID                       */
       move.b    _OSTaskRegNextAvailID.L,-1(A6)
; OSTaskRegNextAvailID++;                                     /* Increment available ID for next request            */
       addq.b    #1,_OSTaskRegNextAvailID.L
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr = OS_ERR_NONE;
       move.l    8(A6),A0
       clr.b     (A0)
; return (id);
       move.b    -1(A6),D0
OSTaskRegGetID_3:
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                              SET THE CURRENT VALUE OF A TASK VARIABLE
; *
; * Description: This function is called to change the current value of a task register.  Task registers
; *              are application specific and can be used to store task specific values such as 'error
; *              numbers' (i.e. errno), statistics, etc.  Each task register can hold a 32-bit value.
; *
; * Arguments  : prio      is the priority of the task you want to set the task register for.  If you
; *                        specify OS_PRIO_SELF then the task register of the current task will be obtained.
; *
; *              id        is the 'id' of the desired task register.  Note that the 'id' must be less
; *                        than OS_TASK_REG_TBL_SIZE
; *
; *              value     is the desired value for the task register.
; *
; *              perr      is a pointer to a variable that will hold an error code related to this call.
; *
; *                        OS_ERR_NONE            if the call was successful
; *                        OS_ERR_PRIO_INVALID    if you specified an invalid priority
; *                        OS_ERR_ID_INVALID      if the 'id' is not between 0 and OS_TASK_REG_TBL_SIZE-1
; *
; * Returns    : The current value of the task's variable or 0 if an error is detected.
; *
; * Note(s)    : The maximum number of task variables is 254
; *********************************************************************************************************
; */
; #if OS_TASK_REG_TBL_SIZE > 0u
; void  OSTaskRegSet (INT8U    prio,
; INT8U    id,
; INT32U   value,
; INT8U   *perr)
; {
       xdef      _OSTaskRegSet
_OSTaskRegSet:
       link      A6,#0
       move.l    D2,-(A7)
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; OS_TCB    *ptcb;
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return;
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (prio >= OS_LOWEST_PRIO) {
; if (prio != OS_PRIO_SELF) {
; *perr = OS_ERR_PRIO_INVALID;
; return;
; }
; }
; if (id >= OS_TASK_REG_TBL_SIZE) {
; *perr = OS_ERR_ID_INVALID;
; return;
; }
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; if (prio == OS_PRIO_SELF) {                  /* See if need to get register from current task      */
       move.b    11(A6),D0
       cmp.b     #255,D0
       bne.s     OSTaskRegSet_1
; ptcb = OSTCBCur;
       move.l    _OSTCBCur.L,D2
       bra.s     OSTaskRegSet_2
OSTaskRegSet_1:
; } else {
; ptcb = OSTCBPrioTbl[prio];
       move.b    11(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
OSTaskRegSet_2:
; }
; ptcb->OSTCBRegTbl[id] = value;
       move.l    D2,A0
       move.b    15(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       add.l     D0,A0
       move.l    16(A6),82(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; *perr                 = OS_ERR_NONE;
       move.l    20(A6),A0
       clr.b     (A0)
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                    CATCH ACCIDENTAL TASK RETURN
; *
; * Description: This function is called if a task accidentally returns without deleting itself.  In other
; *              words, a task should either be an infinite loop or delete itself if it's done.
; *
; * Arguments  : none
; *
; * Returns    : none
; *
; * Note(s)    : This function is INTERNAL to uC/OS-II and your application should not call it.
; *********************************************************************************************************
; */
; void  OS_TaskReturn (void)
; {
       xdef      _OS_TaskReturn
_OS_TaskReturn:
; OSTaskReturnHook(OSTCBCur);                   /* Call hook to let user decide on what to do        */
       move.l    _OSTCBCur.L,-(A7)
       jsr       _OSTaskReturnHook
       addq.w    #4,A7
; #if OS_TASK_DEL_EN > 0u
; (void)OSTaskDel(OS_PRIO_SELF);                /* Delete task if it accidentally returns!           */
       pea       255
       jsr       _OSTaskDel
       addq.w    #4,A7
       and.l     #255,D0
       rts
; #else
; for (;;) {
; OSTimeDly(OS_TICKS_PER_SEC);
; }
; #endif
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                          CLEAR TASK STACK
; *
; * Description: This function is used to clear the stack of a task (i.e. write all zeros)
; *
; * Arguments  : pbos     is a pointer to the task's bottom of stack.  If the configuration constant
; *                       OS_STK_GROWTH is set to 1, the stack is assumed to grow downward (i.e. from high
; *                       memory to low memory).  'pbos' will thus point to the lowest (valid) memory
; *                       location of the stack.  If OS_STK_GROWTH is set to 0, 'pbos' will point to the
; *                       highest memory location of the stack and the stack will grow with increasing
; *                       memory locations.  'pbos' MUST point to a valid 'free' data item.
; *
; *              size     is the number of 'stack elements' to clear.
; *
; *              opt      contains additional information (or options) about the behavior of the task.  The
; *                       LOWER 8-bits are reserved by uC/OS-II while the upper 8 bits can be application
; *                       specific.  See OS_TASK_OPT_??? in uCOS-II.H.
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if (OS_TASK_STAT_STK_CHK_EN > 0u) && (OS_TASK_CREATE_EXT_EN > 0u)
; void  OS_TaskStkClr (OS_STK  *pbos,
; INT32U   size,
; INT16U   opt)
; {
       xdef      _OS_TaskStkClr
_OS_TaskStkClr:
       link      A6,#0
; if ((opt & OS_TASK_OPT_STK_CHK) != 0x0000u) {      /* See if stack checking has been enabled       */
       move.w    18(A6),D0
       and.w     #1,D0
       beq.s     OS_TaskStkClr_7
; if ((opt & OS_TASK_OPT_STK_CLR) != 0x0000u) {  /* See if stack needs to be cleared             */
       move.w    18(A6),D0
       and.w     #2,D0
       beq.s     OS_TaskStkClr_7
; #if OS_STK_GROWTH == 1u
; while (size > 0u) {                        /* Stack grows from HIGH to LOW memory          */
OS_TaskStkClr_5:
       move.l    12(A6),D0
       cmp.l     #0,D0
       bls.s     OS_TaskStkClr_7
; size--;
       subq.l    #1,12(A6)
; *pbos++ = (OS_STK)0;                   /* Clear from bottom of stack and up!           */
       move.l    8(A6),A0
       addq.l    #2,8(A6)
       clr.w     (A0)
       bra       OS_TaskStkClr_5
OS_TaskStkClr_7:
       unlk      A6
       rts
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                             TIME MANAGEMENT
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : OS_TIME.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #include <ucos_ii.h>
; #endif
; /*
; *********************************************************************************************************
; *                                        DELAY TASK 'n' TICKS
; *
; * Description: This function is called to delay execution of the currently running task until the
; *              specified number of system ticks expires.  This, of course, directly equates to delaying
; *              the current task for some time to expire.  No delay will result If the specified delay is
; *              0.  If the specified delay is greater than 0 then, a context switch will result.
; *
; * Arguments  : ticks     is the time delay that the task will be suspended in number of clock 'ticks'.
; *                        Note that by specifying 0, the task will not be delayed.
; *
; * Returns    : none
; *********************************************************************************************************
; */
; void  OSTimeDly (INT32U ticks)
; {
       xdef      _OSTimeDly
_OSTimeDly:
       link      A6,#0
       movem.l   D2/A2,-(A7)
       lea       _OSTCBCur.L,A2
; INT8U      y;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; if (OSIntNesting > 0u) {                     /* See if trying to call from an ISR                  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTimeDly_1
; return;
       bra       OSTimeDly_6
OSTimeDly_1:
; }
; if (OSLockNesting > 0u) {                    /* See if called with scheduler locked                */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTimeDly_4
; return;
       bra       OSTimeDly_6
OSTimeDly_4:
; }
; if (ticks > 0u) {                            /* 0 means no delay!                                  */
       move.l    8(A6),D0
       cmp.l     #0,D0
       bls       OSTimeDly_6
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; y            =  OSTCBCur->OSTCBY;        /* Delay current task                                 */
       move.l    (A2),A0
       move.b    54(A0),D2
; OSRdyTbl[y] &= (OS_PRIO)~OSTCBCur->OSTCBBitX;
       and.l     #255,D2
       lea       _OSRdyTbl.L,A0
       move.l    (A2),A1
       move.b    55(A1),D0
       not.b     D0
       and.b     D0,0(A0,D2.L)
; if (OSRdyTbl[y] == 0u) {
       and.l     #255,D2
       lea       _OSRdyTbl.L,A0
       move.b    0(A0,D2.L),D0
       bne.s     OSTimeDly_8
; OSRdyGrp &= (OS_PRIO)~OSTCBCur->OSTCBBitY;
       move.l    (A2),A0
       move.b    56(A0),D0
       not.b     D0
       and.b     D0,_OSRdyGrp.L
OSTimeDly_8:
; }
; OSTCBCur->OSTCBDly = ticks;              /* Load ticks in TCB                                  */
       move.l    (A2),A0
       move.l    8(A6),46(A0)
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                              /* Find next task to run!                             */
       jsr       _OS_Sched
OSTimeDly_6:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; }
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                    DELAY TASK FOR SPECIFIED TIME
; *
; * Description: This function is called to delay execution of the currently running task until some time
; *              expires.  This call allows you to specify the delay time in HOURS, MINUTES, SECONDS and
; *              MILLISECONDS instead of ticks.
; *
; * Arguments  : hours     specifies the number of hours that the task will be delayed (max. is 255)
; *              minutes   specifies the number of minutes (max. 59)
; *              seconds   specifies the number of seconds (max. 59)
; *              ms        specifies the number of milliseconds (max. 999)
; *
; * Returns    : OS_ERR_NONE
; *              OS_ERR_TIME_INVALID_MINUTES
; *              OS_ERR_TIME_INVALID_SECONDS
; *              OS_ERR_TIME_INVALID_MS
; *              OS_ERR_TIME_ZERO_DLY
; *              OS_ERR_TIME_DLY_ISR
; *
; * Note(s)    : The resolution on the milliseconds depends on the tick rate.  For example, you can't do
; *              a 10 mS delay if the ticker interrupts every 100 mS.  In this case, the delay would be
; *              set to 0.  The actual delay is rounded to the nearest tick.
; *********************************************************************************************************
; */
; #if OS_TIME_DLY_HMSM_EN > 0u
; INT8U  OSTimeDlyHMSM (INT8U   hours,
; INT8U   minutes,
; INT8U   seconds,
; INT16U  ms)
; {
       xdef      _OSTimeDlyHMSM
_OSTimeDlyHMSM:
       link      A6,#-4
; INT32U ticks;
; if (OSIntNesting > 0u) {                     /* See if trying to call from an ISR                  */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTimeDlyHMSM_1
; return (OS_ERR_TIME_DLY_ISR);
       moveq     #85,D0
       bra       OSTimeDlyHMSM_3
OSTimeDlyHMSM_1:
; }
; if (OSLockNesting > 0u) {                    /* See if called with scheduler locked                */
       move.b    _OSLockNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTimeDlyHMSM_4
; return (OS_ERR_SCHED_LOCKED);
       moveq     #50,D0
       bra       OSTimeDlyHMSM_3
OSTimeDlyHMSM_4:
; }
; #if OS_ARG_CHK_EN > 0u
; if (hours == 0u) {
; if (minutes == 0u) {
; if (seconds == 0u) {
; if (ms == 0u) {
; return (OS_ERR_TIME_ZERO_DLY);
; }
; }
; }
; }
; if (minutes > 59u) {
; return (OS_ERR_TIME_INVALID_MINUTES);    /* Validate arguments to be within range              */
; }
; if (seconds > 59u) {
; return (OS_ERR_TIME_INVALID_SECONDS);
; }
; if (ms > 999u) {
; return (OS_ERR_TIME_INVALID_MS);
; }
; #endif
; /* Compute the total number of clock ticks required.. */
; /* .. (rounded to the nearest tick)                   */
; ticks = ((INT32U)hours * 3600uL + (INT32U)minutes * 60uL + (INT32U)seconds) * OS_TICKS_PER_SEC
       move.b    11(A6),D0
       and.l     #255,D0
       move.l    D0,-(A7)
       pea       3600
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.b    15(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       60
       jsr       ULMUL
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       move.b    19(A6),D1
       and.l     #255,D1
       add.l     D1,D0
       move.l    D0,-(A7)
       pea       100
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.w    22(A6),D1
       and.l     #65535,D1
       addq.l    #5,D1
       move.l    D1,-(A7)
       pea       100
       jsr       ULMUL
       move.l    (A7),D1
       addq.w    #8,A7
       move.l    D1,-(A7)
       pea       1000
       jsr       ULDIV
       move.l    (A7),D1
       addq.w    #8,A7
       add.l     D1,D0
       move.l    D0,-4(A6)
; + OS_TICKS_PER_SEC * ((INT32U)ms + 500uL / OS_TICKS_PER_SEC) / 1000uL;
; OSTimeDly(ticks);
       move.l    -4(A6),-(A7)
       jsr       _OSTimeDly
       addq.w    #4,A7
; return (OS_ERR_NONE);
       clr.b     D0
OSTimeDlyHMSM_3:
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                        RESUME A DELAYED TASK
; *
; * Description: This function is used resume a task that has been delayed through a call to either
; *              OSTimeDly() or OSTimeDlyHMSM().  Note that you can call this function to resume a
; *              task that is waiting for an event with timeout.  This would make the task look
; *              like a timeout occurred.
; *
; * Arguments  : prio                      specifies the priority of the task to resume
; *
; * Returns    : OS_ERR_NONE               Task has been resumed
; *              OS_ERR_PRIO_INVALID       if the priority you specify is higher that the maximum allowed
; *                                        (i.e. >= OS_LOWEST_PRIO)
; *              OS_ERR_TIME_NOT_DLY       Task is not waiting for time to expire
; *              OS_ERR_TASK_NOT_EXIST     The desired task has not been created or has been assigned to a Mutex.
; *********************************************************************************************************
; */
; #if OS_TIME_DLY_RESUME_EN > 0u
; INT8U  OSTimeDlyResume (INT8U prio)
; {
       xdef      _OSTimeDlyResume
_OSTimeDlyResume:
       link      A6,#0
       move.l    D2,-(A7)
; OS_TCB    *ptcb;
; #if OS_CRITICAL_METHOD == 3u                                   /* Storage for CPU status register      */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; if (prio >= OS_LOWEST_PRIO) {
       move.b    11(A6),D0
       cmp.b     #63,D0
       blo.s     OSTimeDlyResume_1
; return (OS_ERR_PRIO_INVALID);
       moveq     #42,D0
       bra       OSTimeDlyResume_3
OSTimeDlyResume_1:
; }
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; ptcb = OSTCBPrioTbl[prio];                                 /* Make sure that task exist            */
       move.b    11(A6),D0
       and.l     #255,D0
       lsl.l     #2,D0
       lea       _OSTCBPrioTbl.L,A0
       move.l    0(A0,D0.L),D2
; if (ptcb == (OS_TCB *)0) {
       tst.l     D2
       bne.s     OSTimeDlyResume_4
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);                        /* The task does not exist              */
       moveq     #67,D0
       bra       OSTimeDlyResume_3
OSTimeDlyResume_4:
; }
; if (ptcb == OS_TCB_RESERVED) {
       cmp.l     #1,D2
       bne.s     OSTimeDlyResume_6
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TASK_NOT_EXIST);                        /* The task does not exist              */
       moveq     #67,D0
       bra       OSTimeDlyResume_3
OSTimeDlyResume_6:
; }
; if (ptcb->OSTCBDly == 0u) {                                /* See if task is delayed               */
       move.l    D2,A0
       move.l    46(A0),D0
       bne.s     OSTimeDlyResume_8
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (OS_ERR_TIME_NOT_DLY);                          /* Indicate that task was not delayed   */
       moveq     #80,D0
       bra       OSTimeDlyResume_3
OSTimeDlyResume_8:
; }
; ptcb->OSTCBDly = 0u;                                       /* Clear the time delay                 */
       move.l    D2,A0
       clr.l     46(A0)
; if ((ptcb->OSTCBStat & OS_STAT_PEND_ANY) != OS_STAT_RDY) {
       move.l    D2,A0
       move.b    50(A0),D0
       and.b     #55,D0
       beq.s     OSTimeDlyResume_10
; ptcb->OSTCBStat     &= ~OS_STAT_PEND_ANY;              /* Yes, Clear status flag               */
       move.l    D2,A0
       and.b     #-56,50(A0)
; ptcb->OSTCBStatPend  =  OS_STAT_PEND_TO;               /* Indicate PEND timeout                */
       move.l    D2,A0
       move.b    #1,51(A0)
       bra.s     OSTimeDlyResume_11
OSTimeDlyResume_10:
; } else {
; ptcb->OSTCBStatPend  =  OS_STAT_PEND_OK;
       move.l    D2,A0
       clr.b     51(A0)
OSTimeDlyResume_11:
; }
; if ((ptcb->OSTCBStat & OS_STAT_SUSPEND) == OS_STAT_RDY) {  /* Is task suspended?                   */
       move.l    D2,A0
       move.b    50(A0),D0
       and.b     #8,D0
       bne.s     OSTimeDlyResume_12
; OSRdyGrp               |= ptcb->OSTCBBitY;             /* No,  Make ready                      */
       move.l    D2,A0
       move.b    56(A0),D0
       or.b      D0,_OSRdyGrp.L
; OSRdyTbl[ptcb->OSTCBY] |= ptcb->OSTCBBitX;
       move.l    D2,A0
       move.b    54(A0),D0
       and.l     #255,D0
       lea       _OSRdyTbl.L,A0
       move.l    D2,A1
       move.b    55(A1),D1
       or.b      D1,0(A0,D0.L)
; OS_EXIT_CRITICAL();
       dc.w      18143
; OS_Sched();                                            /* See if this is new highest priority  */
       jsr       _OS_Sched
       bra.s     OSTimeDlyResume_13
OSTimeDlyResume_12:
; } else {
; OS_EXIT_CRITICAL();                                    /* Task may be suspended                */
       dc.w      18143
OSTimeDlyResume_13:
; }
; return (OS_ERR_NONE);
       clr.b     D0
OSTimeDlyResume_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       GET CURRENT SYSTEM TIME
; *
; * Description: This function is used by your application to obtain the current value of the 32-bit
; *              counter which keeps track of the number of clock ticks.
; *
; * Arguments  : none
; *
; * Returns    : The current value of OSTime
; *********************************************************************************************************
; */
; #if OS_TIME_GET_SET_EN > 0u
; INT32U  OSTimeGet (void)
; {
       xdef      _OSTimeGet
_OSTimeGet:
       link      A6,#-4
; INT32U     ticks;
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; ticks = OSTime;
       move.l    _OSTime.L,-4(A6)
; OS_EXIT_CRITICAL();
       dc.w      18143
; return (ticks);
       move.l    -4(A6),D0
       unlk      A6
       rts
; }
; #endif
; /*
; *********************************************************************************************************
; *                                          SET SYSTEM CLOCK
; *
; * Description: This function sets the 32-bit counter which keeps track of the number of clock ticks.
; *
; * Arguments  : ticks      specifies the new value that OSTime needs to take.
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TIME_GET_SET_EN > 0u
; void  OSTimeSet (INT32U ticks)
; {
       xdef      _OSTimeSet
_OSTimeSet:
       link      A6,#0
; #if OS_CRITICAL_METHOD == 3u                     /* Allocate storage for CPU status register           */
; OS_CPU_SR  cpu_sr = 0u;
; #endif
; OS_ENTER_CRITICAL();
       dc.w      16615
       dc.w      124
       dc.w      1792
; OSTime = ticks;
       move.l    8(A6),_OSTime.L
; OS_EXIT_CRITICAL();
       dc.w      18143
       unlk      A6
       rts
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *                                            TIMER MANAGEMENT
; *
; *                              (c) Copyright 1992-2012, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; *
; * File    : OS_TMR.C
; * By      : Jean J. Labrosse
; * Version : V2.92.07
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micrium to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  MICRIUM_SOURCE
; #ifndef  OS_MASTER_FILE
; #include <ucos_ii.h>
; #endif
; /*
; *********************************************************************************************************
; *                                                        NOTES
; *
; * 1) Your application MUST define the following #define constants:
; *
; *    OS_TASK_TMR_PRIO          The priority of the Timer management task
; *    OS_TASK_TMR_STK_SIZE      The size     of the Timer management task's stack
; *
; * 2) You must call OSTmrSignal() to notify the Timer management task that it's time to update the timers.
; *********************************************************************************************************
; */
; /*
; *********************************************************************************************************
; *                                              CONSTANTS
; *********************************************************************************************************
; */
; #define  OS_TMR_LINK_DLY       0u
; #define  OS_TMR_LINK_PERIODIC  1u
; /*
; *********************************************************************************************************
; *                                          LOCAL PROTOTYPES
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; static  OS_TMR  *OSTmr_Alloc         (void);
; static  void     OSTmr_Free          (OS_TMR *ptmr);
; static  void     OSTmr_InitTask      (void);
; static  void     OSTmr_Link          (OS_TMR *ptmr, INT8U type);
; static  void     OSTmr_Unlink        (OS_TMR *ptmr);
; static  void     OSTmr_Task          (void   *p_arg);
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           CREATE A TIMER
; *
; * Description: This function is called by your application code to create a timer.
; *
; * Arguments  : dly           Initial delay.
; *                            If the timer is configured for ONE-SHOT mode, this is the timeout used.
; *                            If the timer is configured for PERIODIC mode, this is the first timeout to 
; *                               wait for before the timer starts entering periodic mode.
; *
; *              period        The 'period' being repeated for the timer.
; *                               If you specified 'OS_TMR_OPT_PERIODIC' as an option, when the timer 
; *                               expires, it will automatically restart with the same period.
; *
; *              opt           Specifies either:
; *                               OS_TMR_OPT_ONE_SHOT       The timer counts down only once
; *                               OS_TMR_OPT_PERIODIC       The timer counts down and then reloads itself
; *
; *              callback      Is a pointer to a callback function that will be called when the timer expires. 
; *                               The callback function must be declared as follows:
; *
; *                               void MyCallback (OS_TMR *ptmr, void *p_arg);
; *
; *              callback_arg  Is an argument (a pointer) that is passed to the callback function when it is called.
; *
; *              pname         Is a pointer to an ASCII string that is used to name the timer.  Names are 
; *                               useful for debugging.
; *
; *              perr          Is a pointer to an error code.  '*perr' will contain one of the following:
; *                               OS_ERR_NONE
; *                               OS_ERR_TMR_INVALID_DLY     you specified an invalid delay
; *                               OS_ERR_TMR_INVALID_PERIOD  you specified an invalid period
; *                               OS_ERR_TMR_INVALID_OPT     you specified an invalid option
; *                               OS_ERR_TMR_ISR             if the call was made from an ISR
; *                               OS_ERR_TMR_NON_AVAIL       if there are no free timers from the timer pool
; *
; * Returns    : A pointer to an OS_TMR data structure.
; *              This is the 'handle' that your application will use to reference the timer created.
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; OS_TMR  *OSTmrCreate (INT32U           dly,
; INT32U           period,
; INT8U            opt,
; OS_TMR_CALLBACK  callback,
; void            *callback_arg,
; INT8U           *pname,
; INT8U           *perr)
; {
       xdef      _OSTmrCreate
_OSTmrCreate:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    32(A6),D3
; OS_TMR   *ptmr;
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_TMR *)0);
; }
; #endif
; #ifdef OS_SAFETY_CRITICAL_IEC61508
; if (OSSafetyCriticalStartFlag == OS_TRUE) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return ((OS_TMR *)0);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; switch (opt) {                                          /* Validate arguments                                     */
; case OS_TMR_OPT_PERIODIC:
; if (period == 0u) {
; *perr = OS_ERR_TMR_INVALID_PERIOD;
; return ((OS_TMR *)0);
; }
; break;
; case OS_TMR_OPT_ONE_SHOT:
; if (dly == 0u) {
; *perr = OS_ERR_TMR_INVALID_DLY;
; return ((OS_TMR *)0);
; }
; break;
; default:
; *perr = OS_ERR_TMR_INVALID_OPT;
; return ((OS_TMR *)0);
; }
; #endif
; if (OSIntNesting > 0u) {                                /* See if trying to call from an ISR                      */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTmrCreate_1
; *perr  = OS_ERR_TMR_ISR;
       move.l    D3,A0
       move.b    #139,(A0)
; return ((OS_TMR *)0);
       clr.l     D0
       bra       OSTmrCreate_3
OSTmrCreate_1:
; }
; OSSchedLock();
       jsr       _OSSchedLock
; ptmr = OSTmr_Alloc();                                   /* Obtain a timer from the free pool                      */
       jsr       @ucos_ii_OSTmr_Alloc
       move.l    D0,D2
; if (ptmr == (OS_TMR *)0) {
       tst.l     D2
       bne.s     OSTmrCreate_4
; OSSchedUnlock();
       jsr       _OSSchedUnlock
; *perr = OS_ERR_TMR_NON_AVAIL;
       move.l    D3,A0
       move.b    #134,(A0)
; return ((OS_TMR *)0);
       clr.l     D0
       bra       OSTmrCreate_3
OSTmrCreate_4:
; }
; ptmr->OSTmrState       = OS_TMR_STATE_STOPPED;          /* Indicate that timer is not running yet                 */
       move.l    D2,A0
       move.b    #1,35(A0)
; ptmr->OSTmrDly         = dly;
       move.l    D2,A0
       move.l    8(A6),22(A0)
; ptmr->OSTmrPeriod      = period;
       move.l    D2,A0
       move.l    12(A6),26(A0)
; ptmr->OSTmrOpt         = opt;
       move.l    D2,A0
       move.b    19(A6),34(A0)
; ptmr->OSTmrCallback    = callback;
       move.l    D2,A0
       move.l    20(A6),2(A0)
; ptmr->OSTmrCallbackArg = callback_arg;
       move.l    D2,A0
       move.l    24(A6),6(A0)
; #if OS_TMR_CFG_NAME_EN > 0u
; if (pname == (INT8U *)0) {                              /* Is 'pname' a NULL pointer?                             */
       move.l    28(A6),D0
       bne.s     OSTmrCreate_6
; ptmr->OSTmrName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,30(A1)
       bra.s     OSTmrCreate_7
OSTmrCreate_6:
; } else {
; ptmr->OSTmrName    = pname;
       move.l    D2,A0
       move.l    28(A6),30(A0)
OSTmrCreate_7:
; }
; #endif
; OSSchedUnlock();
       jsr       _OSSchedUnlock
; *perr = OS_ERR_NONE;
       move.l    D3,A0
       clr.b     (A0)
; return (ptmr);
       move.l    D2,D0
OSTmrCreate_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                           DELETE A TIMER
; *
; * Description: This function is called by your application code to delete a timer.
; *
; * Arguments  : ptmr          Is a pointer to the timer to stop and delete.
; *
; *              perr          Is a pointer to an error code.  '*perr' will contain one of the following:
; *                               OS_ERR_NONE
; *                               OS_ERR_TMR_INVALID        'ptmr'  is a NULL pointer
; *                               OS_ERR_TMR_INVALID_TYPE   'ptmr'  is not pointing to an OS_TMR
; *                               OS_ERR_TMR_ISR            if the function was called from an ISR
; *                               OS_ERR_TMR_INACTIVE       if the timer was not created
; *                               OS_ERR_TMR_INVALID_STATE  the timer is in an invalid state
; *
; * Returns    : OS_TRUE       If the call was successful
; *              OS_FALSE      If not
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; BOOLEAN  OSTmrDel (OS_TMR  *ptmr,
; INT8U   *perr)
; {
       xdef      _OSTmrDel
_OSTmrDel:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       move.l    12(A6),D2
       move.l    8(A6),D3
       lea       _OSSchedUnlock.L,A2
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (OS_FALSE);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (ptmr == (OS_TMR *)0) {
; *perr = OS_ERR_TMR_INVALID;
; return (OS_FALSE);
; }
; #endif
; if (ptmr->OSTmrType != OS_TMR_TYPE) {                   /* Validate timer structure                               */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #100,D0
       beq.s     OSTmrDel_1
; *perr = OS_ERR_TMR_INVALID_TYPE;
       move.l    D2,A0
       move.b    #137,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra       OSTmrDel_3
OSTmrDel_1:
; }
; if (OSIntNesting > 0u) {                                /* See if trying to call from an ISR                      */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTmrDel_4
; *perr  = OS_ERR_TMR_ISR;
       move.l    D2,A0
       move.b    #139,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra       OSTmrDel_3
OSTmrDel_4:
; }
; OSSchedLock();
       jsr       _OSSchedLock
; switch (ptmr->OSTmrState) {
       move.l    D3,A0
       move.b    35(A0),D0
       and.l     #255,D0
       cmp.l     #4,D0
       bhs       OSTmrDel_6
       asl.l     #1,D0
       move.w    OSTmrDel_8(PC,D0.L),D0
       jmp       OSTmrDel_8(PC,D0.W)
OSTmrDel_8:
       dc.w      OSTmrDel_12-OSTmrDel_8
       dc.w      OSTmrDel_10-OSTmrDel_8
       dc.w      OSTmrDel_10-OSTmrDel_8
       dc.w      OSTmrDel_9-OSTmrDel_8
OSTmrDel_9:
; case OS_TMR_STATE_RUNNING:
; OSTmr_Unlink(ptmr);                            /* Remove from current wheel spoke                        */
       move.l    D3,-(A7)
       jsr       @ucos_ii_OSTmr_Unlink
       addq.w    #4,A7
; OSTmr_Free(ptmr);                              /* Return timer to free list of timers                    */
       move.l    D3,-(A7)
       jsr       @ucos_ii_OSTmr_Free
       addq.w    #4,A7
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return (OS_TRUE);
       moveq     #1,D0
       bra       OSTmrDel_3
OSTmrDel_10:
; case OS_TMR_STATE_STOPPED:                          /* Timer has not started or ...                           */
; case OS_TMR_STATE_COMPLETED:                        /* ... timer has completed the ONE-SHOT time              */
; OSTmr_Free(ptmr);                              /* Return timer to free list of timers                    */
       move.l    D3,-(A7)
       jsr       @ucos_ii_OSTmr_Free
       addq.w    #4,A7
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return (OS_TRUE);
       moveq     #1,D0
       bra.s     OSTmrDel_3
OSTmrDel_12:
; case OS_TMR_STATE_UNUSED:                           /* Already deleted                                        */
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INACTIVE;
       move.l    D2,A0
       move.b    #135,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra.s     OSTmrDel_3
OSTmrDel_6:
; default:
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INVALID_STATE;
       move.l    D2,A0
       move.b    #141,(A0)
; return (OS_FALSE);
       clr.b     D0
OSTmrDel_3:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                       GET THE NAME OF A TIMER
; *
; * Description: This function is called to obtain the name of a timer.
; *
; * Arguments  : ptmr          Is a pointer to the timer to obtain the name for
; *
; *              pdest         Is a pointer to pointer to where the name of the timer will be placed.
; *
; *              perr          Is a pointer to an error code.  '*perr' will contain one of the following:
; *                               OS_ERR_NONE               The call was successful
; *                               OS_ERR_TMR_INVALID_DEST   'pdest' is a NULL pointer
; *                               OS_ERR_TMR_INVALID        'ptmr'  is a NULL pointer
; *                               OS_ERR_TMR_INVALID_TYPE   'ptmr'  is not pointing to an OS_TMR
; *                               OS_ERR_NAME_GET_ISR       if the call was made from an ISR
; *                               OS_ERR_TMR_INACTIVE       'ptmr'  points to a timer that is not active
; *                               OS_ERR_TMR_INVALID_STATE  the timer is in an invalid state
; *
; * Returns    : The length of the string or 0 if the timer does not exist.
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u && OS_TMR_CFG_NAME_EN > 0u
; INT8U  OSTmrNameGet (OS_TMR   *ptmr,
; INT8U   **pdest,
; INT8U    *perr)
; {
       xdef      _OSTmrNameGet
_OSTmrNameGet:
       link      A6,#-4
       movem.l   D2/D3/A2,-(A7)
       move.l    16(A6),D2
       lea       _OSSchedUnlock.L,A2
       move.l    8(A6),D3
; INT8U  len;
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (pdest == (INT8U **)0) {
; *perr = OS_ERR_TMR_INVALID_DEST;
; return (0u);
; }
; if (ptmr == (OS_TMR *)0) {
; *perr = OS_ERR_TMR_INVALID;
; return (0u);
; }
; #endif
; if (ptmr->OSTmrType != OS_TMR_TYPE) {              /* Validate timer structure                                    */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #100,D0
       beq.s     OSTmrNameGet_1
; *perr = OS_ERR_TMR_INVALID_TYPE;
       move.l    D2,A0
       move.b    #137,(A0)
; return (0u);
       clr.b     D0
       bra       OSTmrNameGet_3
OSTmrNameGet_1:
; }
; if (OSIntNesting > 0u) {                           /* See if trying to call from an ISR                           */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTmrNameGet_4
; *perr = OS_ERR_NAME_GET_ISR;
       move.l    D2,A0
       move.b    #17,(A0)
; return (0u);
       clr.b     D0
       bra       OSTmrNameGet_3
OSTmrNameGet_4:
; }
; OSSchedLock();
       jsr       _OSSchedLock
; switch (ptmr->OSTmrState) {
       move.l    D3,A0
       move.b    35(A0),D0
       and.l     #255,D0
       cmp.l     #4,D0
       bhs       OSTmrNameGet_6
       asl.l     #1,D0
       move.w    OSTmrNameGet_8(PC,D0.L),D0
       jmp       OSTmrNameGet_8(PC,D0.W)
OSTmrNameGet_8:
       dc.w      OSTmrNameGet_12-OSTmrNameGet_8
       dc.w      OSTmrNameGet_9-OSTmrNameGet_8
       dc.w      OSTmrNameGet_9-OSTmrNameGet_8
       dc.w      OSTmrNameGet_9-OSTmrNameGet_8
OSTmrNameGet_9:
; case OS_TMR_STATE_RUNNING:
; case OS_TMR_STATE_STOPPED:
; case OS_TMR_STATE_COMPLETED:
; *pdest = ptmr->OSTmrName;
       move.l    D3,A0
       move.l    12(A6),A1
       move.l    30(A0),(A1)
; len    = OS_StrLen(*pdest);
       move.l    12(A6),A0
       move.l    (A0),-(A7)
       jsr       _OS_StrLen
       addq.w    #4,A7
       move.b    D0,-1(A6)
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return (len);
       move.b    -1(A6),D0
       bra.s     OSTmrNameGet_3
OSTmrNameGet_12:
; case OS_TMR_STATE_UNUSED:                      /* Timer is not allocated                                      */
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INACTIVE;
       move.l    D2,A0
       move.b    #135,(A0)
; return (0u);
       clr.b     D0
       bra.s     OSTmrNameGet_3
OSTmrNameGet_6:
; default:
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INVALID_STATE;
       move.l    D2,A0
       move.b    #141,(A0)
; return (0u);
       clr.b     D0
OSTmrNameGet_3:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                          GET HOW MUCH TIME IS LEFT BEFORE A TIMER EXPIRES
; *
; * Description: This function is called to get the number of ticks before a timer times out.
; *
; * Arguments  : ptmr          Is a pointer to the timer to obtain the remaining time from.
; *
; *              perr          Is a pointer to an error code.  '*perr' will contain one of the following:
; *                               OS_ERR_NONE
; *                               OS_ERR_TMR_INVALID        'ptmr' is a NULL pointer
; *                               OS_ERR_TMR_INVALID_TYPE   'ptmr'  is not pointing to an OS_TMR
; *                               OS_ERR_TMR_ISR            if the call was made from an ISR
; *                               OS_ERR_TMR_INACTIVE       'ptmr' points to a timer that is not active
; *                               OS_ERR_TMR_INVALID_STATE  the timer is in an invalid state
; *
; * Returns    : The time remaining for the timer to expire.  The time represents 'timer' increments. 
; *              In other words, if OSTmr_Task() is signaled every 1/10 of a second then the returned 
; *              value represents the number of 1/10 of a second remaining before the timer expires.
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; INT32U  OSTmrRemainGet (OS_TMR  *ptmr,
; INT8U   *perr)
; {
       xdef      _OSTmrRemainGet
_OSTmrRemainGet:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       move.l    12(A6),D2
       move.l    8(A6),D3
       lea       _OSSchedUnlock.L,A2
; INT32U  remain;
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (ptmr == (OS_TMR *)0) {
; *perr = OS_ERR_TMR_INVALID;
; return (0u);
; }
; #endif
; if (ptmr->OSTmrType != OS_TMR_TYPE) {              /* Validate timer structure                                    */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #100,D0
       beq.s     OSTmrRemainGet_1
; *perr = OS_ERR_TMR_INVALID_TYPE;
       move.l    D2,A0
       move.b    #137,(A0)
; return (0u);
       clr.l     D0
       bra       OSTmrRemainGet_3
OSTmrRemainGet_1:
; }
; if (OSIntNesting > 0u) {                           /* See if trying to call from an ISR                           */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTmrRemainGet_4
; *perr = OS_ERR_TMR_ISR;
       move.l    D2,A0
       move.b    #139,(A0)
; return (0u);
       clr.l     D0
       bra       OSTmrRemainGet_3
OSTmrRemainGet_4:
; }
; OSSchedLock();
       jsr       _OSSchedLock
; switch (ptmr->OSTmrState) {
       move.l    D3,A0
       move.b    35(A0),D0
       and.l     #255,D0
       cmp.l     #4,D0
       bhs       OSTmrRemainGet_6
       asl.l     #1,D0
       move.w    OSTmrRemainGet_8(PC,D0.L),D0
       jmp       OSTmrRemainGet_8(PC,D0.W)
OSTmrRemainGet_8:
       dc.w      OSTmrRemainGet_12-OSTmrRemainGet_8
       dc.w      OSTmrRemainGet_10-OSTmrRemainGet_8
       dc.w      OSTmrRemainGet_11-OSTmrRemainGet_8
       dc.w      OSTmrRemainGet_9-OSTmrRemainGet_8
OSTmrRemainGet_9:
; case OS_TMR_STATE_RUNNING:
; remain = ptmr->OSTmrMatch - OSTmrTime;    /* Determine how much time is left to timeout                  */
       move.l    D3,A0
       move.l    18(A0),D0
       sub.l     _OSTmrTime.L,D0
       move.l    D0,D4
; OSSchedUnlock();
       jsr       (A2)
; *perr  = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return (remain);
       move.l    D4,D0
       bra       OSTmrRemainGet_3
OSTmrRemainGet_10:
; case OS_TMR_STATE_STOPPED:                     /* It's assumed that the timer has not started yet             */
; switch (ptmr->OSTmrOpt) {
       move.l    D3,A0
       move.b    34(A0),D0
       and.l     #255,D0
       cmp.l     #2,D0
       beq.s     OSTmrRemainGet_16
       bhi.s     OSTmrRemainGet_17
       cmp.l     #1,D0
       beq.s     OSTmrRemainGet_17
       bra.s     OSTmrRemainGet_17
OSTmrRemainGet_16:
; case OS_TMR_OPT_PERIODIC:
; if (ptmr->OSTmrDly == 0u) {
       move.l    D3,A0
       move.l    22(A0),D0
       bne.s     OSTmrRemainGet_19
; remain = ptmr->OSTmrPeriod;
       move.l    D3,A0
       move.l    26(A0),D4
       bra.s     OSTmrRemainGet_20
OSTmrRemainGet_19:
; } else {
; remain = ptmr->OSTmrDly;
       move.l    D3,A0
       move.l    22(A0),D4
OSTmrRemainGet_20:
; }
; OSSchedUnlock();
       jsr       (A2)
; *perr  = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; break;
       bra.s     OSTmrRemainGet_15
OSTmrRemainGet_17:
; case OS_TMR_OPT_ONE_SHOT:
; default:
; remain = ptmr->OSTmrDly;
       move.l    D3,A0
       move.l    22(A0),D4
; OSSchedUnlock();
       jsr       (A2)
; *perr  = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; break;
OSTmrRemainGet_15:
; }
; return (remain);
       move.l    D4,D0
       bra.s     OSTmrRemainGet_3
OSTmrRemainGet_11:
; case OS_TMR_STATE_COMPLETED:                   /* Only ONE-SHOT that timed out can be in this state           */
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return (0u);
       clr.l     D0
       bra.s     OSTmrRemainGet_3
OSTmrRemainGet_12:
; case OS_TMR_STATE_UNUSED:
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INACTIVE;
       move.l    D2,A0
       move.b    #135,(A0)
; return (0u);
       clr.l     D0
       bra.s     OSTmrRemainGet_3
OSTmrRemainGet_6:
; default:
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INVALID_STATE;
       move.l    D2,A0
       move.b    #141,(A0)
; return (0u);
       clr.l     D0
OSTmrRemainGet_3:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                  FIND OUT WHAT STATE A TIMER IS IN
; *
; * Description: This function is called to determine what state the timer is in:
; *
; *                  OS_TMR_STATE_UNUSED     the timer has not been created
; *                  OS_TMR_STATE_STOPPED    the timer has been created but has not been started or has been stopped
; *                  OS_TMR_STATE_COMPLETED  the timer is in ONE-SHOT mode and has completed it's timeout
; *                  OS_TMR_STATE_RUNNING    the timer is currently running
; *
; * Arguments  : ptmr          Is a pointer to the desired timer
; *
; *              perr          Is a pointer to an error code.  '*perr' will contain one of the following:
; *                               OS_ERR_NONE
; *                               OS_ERR_TMR_INVALID        'ptmr' is a NULL pointer
; *                               OS_ERR_TMR_INVALID_TYPE   'ptmr'  is not pointing to an OS_TMR
; *                               OS_ERR_TMR_ISR            if the call was made from an ISR
; *                               OS_ERR_TMR_INACTIVE       'ptmr' points to a timer that is not active
; *                               OS_ERR_TMR_INVALID_STATE  if the timer is not in a valid state
; *
; * Returns    : The current state of the timer (see description).
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; INT8U  OSTmrStateGet (OS_TMR  *ptmr,
; INT8U   *perr)
; {
       xdef      _OSTmrStateGet
_OSTmrStateGet:
       link      A6,#0
       movem.l   D2/D3,-(A7)
       move.l    12(A6),D2
; INT8U  state;
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (0u);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (ptmr == (OS_TMR *)0) {
; *perr = OS_ERR_TMR_INVALID;
; return (0u);
; }
; #endif
; if (ptmr->OSTmrType != OS_TMR_TYPE) {              /* Validate timer structure                                    */
       move.l    8(A6),A0
       move.b    (A0),D0
       cmp.b     #100,D0
       beq.s     OSTmrStateGet_1
; *perr = OS_ERR_TMR_INVALID_TYPE;
       move.l    D2,A0
       move.b    #137,(A0)
; return (0u);
       clr.b     D0
       bra       OSTmrStateGet_3
OSTmrStateGet_1:
; }
; if (OSIntNesting > 0u) {                           /* See if trying to call from an ISR                           */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTmrStateGet_4
; *perr = OS_ERR_TMR_ISR;
       move.l    D2,A0
       move.b    #139,(A0)
; return (0u);
       clr.b     D0
       bra       OSTmrStateGet_3
OSTmrStateGet_4:
; }
; OSSchedLock();
       jsr       _OSSchedLock
; state = ptmr->OSTmrState;
       move.l    8(A6),A0
       move.b    35(A0),D3
; switch (state) {
       and.l     #255,D3
       move.l    D3,D0
       cmp.l     #4,D0
       bhs.s     OSTmrStateGet_6
       asl.l     #1,D0
       move.w    OSTmrStateGet_8(PC,D0.L),D0
       jmp       OSTmrStateGet_8(PC,D0.W)
OSTmrStateGet_8:
       dc.w      OSTmrStateGet_9-OSTmrStateGet_8
       dc.w      OSTmrStateGet_9-OSTmrStateGet_8
       dc.w      OSTmrStateGet_9-OSTmrStateGet_8
       dc.w      OSTmrStateGet_9-OSTmrStateGet_8
OSTmrStateGet_9:
; case OS_TMR_STATE_UNUSED:
; case OS_TMR_STATE_STOPPED:
; case OS_TMR_STATE_COMPLETED:
; case OS_TMR_STATE_RUNNING:
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; break;
       bra.s     OSTmrStateGet_7
OSTmrStateGet_6:
; default:
; *perr = OS_ERR_TMR_INVALID_STATE;
       move.l    D2,A0
       move.b    #141,(A0)
; break;
OSTmrStateGet_7:
; }
; OSSchedUnlock();
       jsr       _OSSchedUnlock
; return (state);
       move.b    D3,D0
OSTmrStateGet_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                            START A TIMER
; *
; * Description: This function is called by your application code to start a timer.
; *
; * Arguments  : ptmr          Is a pointer to an OS_TMR
; *
; *              perr          Is a pointer to an error code.  '*perr' will contain one of the following:
; *                               OS_ERR_NONE
; *                               OS_ERR_TMR_INVALID
; *                               OS_ERR_TMR_INVALID_TYPE    'ptmr'  is not pointing to an OS_TMR
; *                               OS_ERR_TMR_ISR             if the call was made from an ISR
; *                               OS_ERR_TMR_INACTIVE        if the timer was not created
; *                               OS_ERR_TMR_INVALID_STATE   the timer is in an invalid state
; *
; * Returns    : OS_TRUE    if the timer was started
; *              OS_FALSE   if an error was detected
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; BOOLEAN  OSTmrStart (OS_TMR   *ptmr,
; INT8U    *perr)
; {
       xdef      _OSTmrStart
_OSTmrStart:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       move.l    12(A6),D2
       move.l    8(A6),D3
       lea       _OSSchedUnlock.L,A2
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (OS_FALSE);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (ptmr == (OS_TMR *)0) {
; *perr = OS_ERR_TMR_INVALID;
; return (OS_FALSE);
; }
; #endif
; if (ptmr->OSTmrType != OS_TMR_TYPE) {                   /* Validate timer structure                               */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #100,D0
       beq.s     OSTmrStart_1
; *perr = OS_ERR_TMR_INVALID_TYPE;
       move.l    D2,A0
       move.b    #137,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra       OSTmrStart_3
OSTmrStart_1:
; }
; if (OSIntNesting > 0u) {                                /* See if trying to call from an ISR                      */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTmrStart_4
; *perr  = OS_ERR_TMR_ISR;
       move.l    D2,A0
       move.b    #139,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra       OSTmrStart_3
OSTmrStart_4:
; }
; OSSchedLock();
       jsr       _OSSchedLock
; switch (ptmr->OSTmrState) {
       move.l    D3,A0
       move.b    35(A0),D0
       and.l     #255,D0
       cmp.l     #4,D0
       bhs       OSTmrStart_6
       asl.l     #1,D0
       move.w    OSTmrStart_8(PC,D0.L),D0
       jmp       OSTmrStart_8(PC,D0.W)
OSTmrStart_8:
       dc.w      OSTmrStart_12-OSTmrStart_8
       dc.w      OSTmrStart_10-OSTmrStart_8
       dc.w      OSTmrStart_10-OSTmrStart_8
       dc.w      OSTmrStart_9-OSTmrStart_8
OSTmrStart_9:
; case OS_TMR_STATE_RUNNING:                          /* Restart the timer                                      */
; OSTmr_Unlink(ptmr);                            /* ... Stop the timer                                     */
       move.l    D3,-(A7)
       jsr       @ucos_ii_OSTmr_Unlink
       addq.w    #4,A7
; OSTmr_Link(ptmr, OS_TMR_LINK_DLY);             /* ... Link timer to timer wheel                          */
       clr.l     -(A7)
       move.l    D3,-(A7)
       jsr       @ucos_ii_OSTmr_Link
       addq.w    #8,A7
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return (OS_TRUE);
       moveq     #1,D0
       bra       OSTmrStart_3
OSTmrStart_10:
; case OS_TMR_STATE_STOPPED:                          /* Start the timer                                        */
; case OS_TMR_STATE_COMPLETED:
; OSTmr_Link(ptmr, OS_TMR_LINK_DLY);             /* ... Link timer to timer wheel                          */
       clr.l     -(A7)
       move.l    D3,-(A7)
       jsr       @ucos_ii_OSTmr_Link
       addq.w    #8,A7
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; return (OS_TRUE);
       moveq     #1,D0
       bra.s     OSTmrStart_3
OSTmrStart_12:
; case OS_TMR_STATE_UNUSED:                           /* Timer not created                                      */
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INACTIVE;
       move.l    D2,A0
       move.b    #135,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra.s     OSTmrStart_3
OSTmrStart_6:
; default:
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INVALID_STATE;
       move.l    D2,A0
       move.b    #141,(A0)
; return (OS_FALSE);
       clr.b     D0
OSTmrStart_3:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                            STOP A TIMER
; *
; * Description: This function is called by your application code to stop a timer.
; *
; * Arguments  : ptmr          Is a pointer to the timer to stop.
; *
; *              opt           Allows you to specify an option to this functions which can be:
; *
; *                               OS_TMR_OPT_NONE          Do nothing special but stop the timer
; *                               OS_TMR_OPT_CALLBACK      Execute the callback function, pass it the 
; *                                                        callback argument specified when the timer 
; *                                                        was created.
; *                               OS_TMR_OPT_CALLBACK_ARG  Execute the callback function, pass it the 
; *                                                        callback argument specified in THIS function call.
; *
; *              callback_arg  Is a pointer to a 'new' callback argument that can be passed to the callback 
; *                            function instead of the timer's callback argument.  In other words, use 
; *                            'callback_arg' passed in THIS function INSTEAD of ptmr->OSTmrCallbackArg.
; *
; *              perr          Is a pointer to an error code.  '*perr' will contain one of the following:
; *                               OS_ERR_NONE
; *                               OS_ERR_TMR_INVALID         'ptmr' is a NULL pointer
; *                               OS_ERR_TMR_INVALID_TYPE    'ptmr'  is not pointing to an OS_TMR
; *                               OS_ERR_TMR_ISR             if the function was called from an ISR
; *                               OS_ERR_TMR_INACTIVE        if the timer was not created
; *                               OS_ERR_TMR_INVALID_OPT     if you specified an invalid option for 'opt'
; *                               OS_ERR_TMR_STOPPED         if the timer was already stopped
; *                               OS_ERR_TMR_INVALID_STATE   the timer is in an invalid state
; *                               OS_ERR_TMR_NO_CALLBACK     if the timer does not have a callback function defined
; *
; * Returns    : OS_TRUE       If we stopped the timer (if the timer is already stopped, we also return OS_TRUE)
; *              OS_FALSE      If not
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; BOOLEAN  OSTmrStop (OS_TMR  *ptmr,
; INT8U    opt,
; void    *callback_arg,
; INT8U   *perr)
; {
       xdef      _OSTmrStop
_OSTmrStop:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       move.l    20(A6),D2
       move.l    8(A6),D3
       lea       _OSSchedUnlock.L,A2
; OS_TMR_CALLBACK  pfnct;
; #ifdef OS_SAFETY_CRITICAL
; if (perr == (INT8U *)0) {
; OS_SAFETY_CRITICAL_EXCEPTION();
; return (OS_FALSE);
; }
; #endif
; #if OS_ARG_CHK_EN > 0u
; if (ptmr == (OS_TMR *)0) {
; *perr = OS_ERR_TMR_INVALID;
; return (OS_FALSE);
; }
; #endif
; if (ptmr->OSTmrType != OS_TMR_TYPE) {                         /* Validate timer structure                         */
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #100,D0
       beq.s     OSTmrStop_1
; *perr = OS_ERR_TMR_INVALID_TYPE;
       move.l    D2,A0
       move.b    #137,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra       OSTmrStop_3
OSTmrStop_1:
; }
; if (OSIntNesting > 0u) {                                      /* See if trying to call from an ISR                */
       move.b    _OSIntNesting.L,D0
       cmp.b     #0,D0
       bls.s     OSTmrStop_4
; *perr  = OS_ERR_TMR_ISR;
       move.l    D2,A0
       move.b    #139,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra       OSTmrStop_3
OSTmrStop_4:
; }
; OSSchedLock();
       jsr       _OSSchedLock
; switch (ptmr->OSTmrState) {
       move.l    D3,A0
       move.b    35(A0),D0
       and.l     #255,D0
       cmp.l     #4,D0
       bhs       OSTmrStop_6
       asl.l     #1,D0
       move.w    OSTmrStop_8(PC,D0.L),D0
       jmp       OSTmrStop_8(PC,D0.W)
OSTmrStop_8:
       dc.w      OSTmrStop_12-OSTmrStop_8
       dc.w      OSTmrStop_10-OSTmrStop_8
       dc.w      OSTmrStop_10-OSTmrStop_8
       dc.w      OSTmrStop_9-OSTmrStop_8
OSTmrStop_9:
; case OS_TMR_STATE_RUNNING:
; OSTmr_Unlink(ptmr);                                  /* Remove from current wheel spoke                  */
       move.l    D3,-(A7)
       jsr       @ucos_ii_OSTmr_Unlink
       addq.w    #4,A7
; *perr = OS_ERR_NONE;
       move.l    D2,A0
       clr.b     (A0)
; switch (opt) {
       move.b    15(A6),D0
       and.l     #255,D0
       cmp.l     #3,D0
       beq.s     OSTmrStop_16
       bhi.s     OSTmrStop_20
       tst.l     D0
       beq       OSTmrStop_18
       bra       OSTmrStop_14
OSTmrStop_20:
       cmp.l     #4,D0
       beq.s     OSTmrStop_17
       bra       OSTmrStop_14
OSTmrStop_16:
; case OS_TMR_OPT_CALLBACK:
; pfnct = ptmr->OSTmrCallback;                /* Execute callback function if available ...       */
       move.l    D3,A0
       move.l    2(A0),D4
; if (pfnct != (OS_TMR_CALLBACK)0) {
       tst.l     D4
       beq.s     OSTmrStop_21
; (*pfnct)((void *)ptmr, ptmr->OSTmrCallbackArg);  /* Use callback arg when timer was created */
       move.l    D3,A0
       move.l    6(A0),-(A7)
       move.l    D3,-(A7)
       move.l    D4,A0
       jsr       (A0)
       addq.w    #8,A7
       bra.s     OSTmrStop_22
OSTmrStop_21:
; } else {
; *perr = OS_ERR_TMR_NO_CALLBACK;
       move.l    D2,A0
       move.b    #143,(A0)
OSTmrStop_22:
; }
; break;
       bra       OSTmrStop_15
OSTmrStop_17:
; case OS_TMR_OPT_CALLBACK_ARG:
; pfnct = ptmr->OSTmrCallback;                /* Execute callback function if available ...       */
       move.l    D3,A0
       move.l    2(A0),D4
; if (pfnct != (OS_TMR_CALLBACK)0) {
       tst.l     D4
       beq.s     OSTmrStop_23
; (*pfnct)((void *)ptmr, callback_arg);   /* ... using the 'callback_arg' provided in call    */
       move.l    16(A6),-(A7)
       move.l    D3,-(A7)
       move.l    D4,A0
       jsr       (A0)
       addq.w    #8,A7
       bra.s     OSTmrStop_24
OSTmrStop_23:
; } else {
; *perr = OS_ERR_TMR_NO_CALLBACK;
       move.l    D2,A0
       move.b    #143,(A0)
OSTmrStop_24:
; }
; break;
       bra.s     OSTmrStop_15
OSTmrStop_18:
; case OS_TMR_OPT_NONE:
; break;
       bra.s     OSTmrStop_15
OSTmrStop_14:
; default:
; *perr = OS_ERR_TMR_INVALID_OPT;
       move.l    D2,A0
       move.b    #132,(A0)
; break;
OSTmrStop_15:
; }
; OSSchedUnlock();
       jsr       (A2)
; return (OS_TRUE);
       moveq     #1,D0
       bra.s     OSTmrStop_3
OSTmrStop_10:
; case OS_TMR_STATE_COMPLETED:                              /* Timer has already completed the ONE-SHOT or ...  */
; case OS_TMR_STATE_STOPPED:                                /* ... timer has not started yet.                   */
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_STOPPED;
       move.l    D2,A0
       move.b    #142,(A0)
; return (OS_TRUE);
       moveq     #1,D0
       bra.s     OSTmrStop_3
OSTmrStop_12:
; case OS_TMR_STATE_UNUSED:                                 /* Timer was not created                            */
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INACTIVE;
       move.l    D2,A0
       move.b    #135,(A0)
; return (OS_FALSE);
       clr.b     D0
       bra.s     OSTmrStop_3
OSTmrStop_6:
; default:
; OSSchedUnlock();
       jsr       (A2)
; *perr = OS_ERR_TMR_INVALID_STATE;
       move.l    D2,A0
       move.b    #141,(A0)
; return (OS_FALSE);
       clr.b     D0
OSTmrStop_3:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                             SIGNAL THAT IT'S TIME TO UPDATE THE TIMERS
; *
; * Description: This function is typically called by the ISR that occurs at the timer tick rate and is 
; *              used to signal to OSTmr_Task() that it's time to update the timers.
; *
; * Arguments  : none
; *
; * Returns    : OS_ERR_NONE         The call was successful and the timer task was signaled.
; *              OS_ERR_SEM_OVF      If OSTmrSignal() was called more often than OSTmr_Task() can handle 
; *                                  the timers. This would indicate that your system is heavily loaded.
; *              OS_ERR_EVENT_TYPE   Unlikely you would get this error because the semaphore used for 
; *                                  signaling is created by uC/OS-II.
; *              OS_ERR_PEVENT_NULL  Again, unlikely you would ever get this error because the semaphore 
; *                                  used for signaling is created by uC/OS-II.
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; INT8U  OSTmrSignal (void)
; {
       xdef      _OSTmrSignal
_OSTmrSignal:
       link      A6,#-4
; INT8U  err;
; err = OSSemPost(OSTmrSemSignal);
       move.l    _OSTmrSemSignal.L,-(A7)
       jsr       _OSSemPost
       addq.w    #4,A7
       move.b    D0,-1(A6)
; return (err);
       move.b    -1(A6),D0
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                      ALLOCATE AND FREE A TIMER
; *
; * Description: This function is called to allocate a timer.
; *
; * Arguments  : none
; *
; * Returns    : a pointer to a timer if one is available
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; static  OS_TMR  *OSTmr_Alloc (void)
; {
@ucos_ii_OSTmr_Alloc:
       movem.l   D2/A2,-(A7)
       lea       _OSTmrFreeList.L,A2
; OS_TMR *ptmr;
; if (OSTmrFreeList == (OS_TMR *)0) {
       move.l    (A2),D0
       bne.s     @ucos_ii_OSTmr_Alloc_1
; return ((OS_TMR *)0);
       clr.l     D0
       bra.s     @ucos_ii_OSTmr_Alloc_3
@ucos_ii_OSTmr_Alloc_1:
; }
; ptmr            = (OS_TMR *)OSTmrFreeList;
       move.l    (A2),D2
; OSTmrFreeList   = (OS_TMR *)ptmr->OSTmrNext;
       move.l    D2,A0
       move.l    10(A0),(A2)
; ptmr->OSTmrNext = (OS_TCB *)0;
       move.l    D2,A0
       clr.l     10(A0)
; ptmr->OSTmrPrev = (OS_TCB *)0;
       move.l    D2,A0
       clr.l     14(A0)
; OSTmrUsed++;
       addq.w    #1,_OSTmrUsed.L
; OSTmrFree--;
       subq.w    #1,_OSTmrFree.L
; return (ptmr);
       move.l    D2,D0
@ucos_ii_OSTmr_Alloc_3:
       movem.l   (A7)+,D2/A2
       rts
; }
; #endif
; /*
; *********************************************************************************************************
; *                                   RETURN A TIMER TO THE FREE LIST
; *
; * Description: This function is called to return a timer object to the free list of timers.
; *
; * Arguments  : ptmr     is a pointer to the timer to free
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; static  void  OSTmr_Free (OS_TMR *ptmr)
; {
@ucos_ii_OSTmr_Free:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; ptmr->OSTmrState       = OS_TMR_STATE_UNUSED;      /* Clear timer object fields                                   */
       move.l    D2,A0
       clr.b     35(A0)
; ptmr->OSTmrOpt         = OS_TMR_OPT_NONE;
       move.l    D2,A0
       clr.b     34(A0)
; ptmr->OSTmrPeriod      = 0u;
       move.l    D2,A0
       clr.l     26(A0)
; ptmr->OSTmrMatch       = 0u;
       move.l    D2,A0
       clr.l     18(A0)
; ptmr->OSTmrCallback    = (OS_TMR_CALLBACK)0;
       move.l    D2,A0
       clr.l     2(A0)
; ptmr->OSTmrCallbackArg = (void *)0;
       move.l    D2,A0
       clr.l     6(A0)
; #if OS_TMR_CFG_NAME_EN > 0u
; ptmr->OSTmrName        = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,30(A1)
; #endif
; ptmr->OSTmrPrev        = (OS_TCB *)0;              /* Chain timer to free list                                    */
       move.l    D2,A0
       clr.l     14(A0)
; ptmr->OSTmrNext        = OSTmrFreeList;
       move.l    D2,A0
       move.l    _OSTmrFreeList.L,10(A0)
; OSTmrFreeList          = ptmr;
       move.l    D2,_OSTmrFreeList.L
; OSTmrUsed--;                                       /* Update timer object statistics                              */
       subq.w    #1,_OSTmrUsed.L
; OSTmrFree++;
       addq.w    #1,_OSTmrFree.L
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                                    INITIALIZATION
; *                                          INITIALIZE THE FREE LIST OF TIMERS
; *
; * Description: This function is called by OSInit() to initialize the free list of OS_TMRs.
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; void  OSTmr_Init (void)
; {
       xdef      _OSTmr_Init
_OSTmr_Init:
       link      A6,#-8
       movem.l   D2/D3/A2,-(A7)
       lea       _OSTmrTbl.L,A2
; #if OS_EVENT_NAME_EN > 0u
; INT8U    err;
; #endif
; INT16U   ix;
; INT16U   ix_next;
; OS_TMR  *ptmr1;
; OS_TMR  *ptmr2;
; OS_MemClr((INT8U *)&OSTmrTbl[0],      sizeof(OSTmrTbl));            /* Clear all the TMRs                         */
       pea       576
       move.l    A2,-(A7)
       jsr       _OS_MemClr
       addq.w    #8,A7
; OS_MemClr((INT8U *)&OSTmrWheelTbl[0], sizeof(OSTmrWheelTbl));       /* Clear the timer wheel                      */
       pea       32
       pea       _OSTmrWheelTbl.L
       jsr       _OS_MemClr
       addq.w    #8,A7
; for (ix = 0u; ix < (OS_TMR_CFG_MAX - 1u); ix++) {                   /* Init. list of free TMRs                    */
       clr.w     D3
OSTmr_Init_1:
       cmp.w     #15,D3
       bhs       OSTmr_Init_3
; ix_next = ix + 1u;
       move.w    D3,D0
       addq.w    #1,D0
       move.w    D0,-6(A6)
; ptmr1 = &OSTmrTbl[ix];
       move.l    A2,D0
       and.l     #65535,D3
       move.l    D3,D1
       muls      #36,D1
       add.l     D1,D0
       move.l    D0,D2
; ptmr2 = &OSTmrTbl[ix_next];
       move.l    A2,D0
       move.w    -6(A6),D1
       and.l     #65535,D1
       muls      #36,D1
       add.l     D1,D0
       move.l    D0,-4(A6)
; ptmr1->OSTmrType    = OS_TMR_TYPE;
       move.l    D2,A0
       move.b    #100,(A0)
; ptmr1->OSTmrState   = OS_TMR_STATE_UNUSED;                      /* Indicate that timer is inactive            */
       move.l    D2,A0
       clr.b     35(A0)
; ptmr1->OSTmrNext    = (void *)ptmr2;                            /* Link to next timer                         */
       move.l    D2,A0
       move.l    -4(A6),10(A0)
; #if OS_TMR_CFG_NAME_EN > 0u
; ptmr1->OSTmrName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,30(A1)
       addq.w    #1,D3
       bra       OSTmr_Init_1
OSTmr_Init_3:
; #endif
; }
; ptmr1               = &OSTmrTbl[ix];
       move.l    A2,D0
       and.l     #65535,D3
       move.l    D3,D1
       muls      #36,D1
       add.l     D1,D0
       move.l    D0,D2
; ptmr1->OSTmrType    = OS_TMR_TYPE;
       move.l    D2,A0
       move.b    #100,(A0)
; ptmr1->OSTmrState   = OS_TMR_STATE_UNUSED;                          /* Indicate that timer is inactive            */
       move.l    D2,A0
       clr.b     35(A0)
; ptmr1->OSTmrNext    = (void *)0;                                    /* Last OS_TMR                                */
       move.l    D2,A0
       clr.l     10(A0)
; #if OS_TMR_CFG_NAME_EN > 0u
; ptmr1->OSTmrName    = (INT8U *)(void *)"?";
       lea       @ucos_ii_1.L,A0
       move.l    D2,A1
       move.l    A0,30(A1)
; #endif
; OSTmrTime           = 0u;
       clr.l     _OSTmrTime.L
; OSTmrUsed           = 0u;
       clr.w     _OSTmrUsed.L
; OSTmrFree           = OS_TMR_CFG_MAX;
       move.w    #16,_OSTmrFree.L
; OSTmrFreeList       = &OSTmrTbl[0];
       move.l    A2,_OSTmrFreeList.L
; OSTmrSem            = OSSemCreate(1u);
       pea       1
       jsr       _OSSemCreate
       addq.w    #4,A7
       move.l    D0,_OSTmrSem.L
; OSTmrSemSignal      = OSSemCreate(0u);
       clr.l     -(A7)
       jsr       _OSSemCreate
       addq.w    #4,A7
       move.l    D0,_OSTmrSemSignal.L
; #if OS_EVENT_NAME_EN > 0u                                               /* Assign names to semaphores                 */
; OSEventNameSet(OSTmrSem,       (INT8U *)(void *)"uC/OS-II TmrLock",   &err);
       pea       -7(A6)
       pea       @ucos_ii_4.L
       move.l    _OSTmrSem.L,-(A7)
       jsr       _OSEventNameSet
       add.w     #12,A7
; OSEventNameSet(OSTmrSemSignal, (INT8U *)(void *)"uC/OS-II TmrSignal", &err);
       pea       -7(A6)
       pea       @ucos_ii_5.L
       move.l    _OSTmrSemSignal.L,-(A7)
       jsr       _OSEventNameSet
       add.w     #12,A7
; #endif
; OSTmr_InitTask();
       jsr       @ucos_ii_OSTmr_InitTask
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                INITIALIZE THE TIMER MANAGEMENT TASK
; *
; * Description: This function is called by OSTmrInit() to create the timer management task.
; *                               * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; static  void  OSTmr_InitTask (void)
; {
@ucos_ii_OSTmr_InitTask:
       link      A6,#-4
; #if OS_TASK_NAME_EN > 0u
; INT8U  err;
; #endif
; #if OS_TASK_CREATE_EXT_EN > 0u
; #if OS_STK_GROWTH == 1u
; (void)OSTaskCreateExt(OSTmr_Task,
       pea       3
       clr.l     -(A7)
       pea       128
       pea       _OSTmrTaskStk.L
       pea       65533
       pea       5
       lea       _OSTmrTaskStk.L,A0
       add.w     #254,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       @ucos_ii_OSTmr_Task.L
       jsr       _OSTaskCreateExt
       add.w     #36,A7
       and.l     #255,D0
; (void *)0,                                       /* No arguments passed to OSTmrTask()      */
; &OSTmrTaskStk[OS_TASK_TMR_STK_SIZE - 1u],        /* Set Top-Of-Stack                        */
; OS_TASK_TMR_PRIO,
; OS_TASK_TMR_ID,
; &OSTmrTaskStk[0],                                /* Set Bottom-Of-Stack                     */
; OS_TASK_TMR_STK_SIZE,
; (void *)0,                                       /* No TCB extension                        */
; OS_TASK_OPT_STK_CHK | OS_TASK_OPT_STK_CLR);      /* Enable stack checking + clear stack     */
; #else
; (void)OSTaskCreateExt(OSTmr_Task,
; (void *)0,                                       /* No arguments passed to OSTmrTask()      */
; &OSTmrTaskStk[0],                                /* Set Top-Of-Stack                        */
; OS_TASK_TMR_PRIO,
; OS_TASK_TMR_ID,
; &OSTmrTaskStk[OS_TASK_TMR_STK_SIZE - 1u],        /* Set Bottom-Of-Stack                     */
; OS_TASK_TMR_STK_SIZE,
; (void *)0,                                       /* No TCB extension                        */
; OS_TASK_OPT_STK_CHK | OS_TASK_OPT_STK_CLR);      /* Enable stack checking + clear stack     */
; #endif
; #else
; #if OS_STK_GROWTH == 1u
; (void)OSTaskCreate(OSTmr_Task,
; (void *)0,
; &OSTmrTaskStk[OS_TASK_TMR_STK_SIZE - 1u],
; OS_TASK_TMR_PRIO);
; #else
; (void)OSTaskCreate(OSTmr_Task,
; (void *)0,
; &OSTmrTaskStk[0],
; OS_TASK_TMR_PRIO);
; #endif
; #endif
; #if OS_TASK_NAME_EN > 0u
; OSTaskNameSet(OS_TASK_TMR_PRIO, (INT8U *)(void *)"uC/OS-II Tmr", &err);
       pea       -1(A6)
       pea       @ucos_ii_6.L
       pea       5
       jsr       _OSTaskNameSet
       add.w     #12,A7
       unlk      A6
       rts
; #endif
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                 INSERT A TIMER INTO THE TIMER WHEEL
; *
; * Description: This function is called to insert the timer into the timer wheel.  The timer is always 
; *              inserted at the beginning of the list.
; *
; * Arguments  : ptmr          Is a pointer to the timer to insert.
; *
; *              type          Is either:
; *                               OS_TMR_LINK_PERIODIC    Means to re-insert the timer after a period expired
; *                               OS_TMR_LINK_DLY         Means to insert    the timer the first time
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; static  void  OSTmr_Link (OS_TMR  *ptmr,
; INT8U    type)
; {
@ucos_ii_OSTmr_Link:
       link      A6,#-4
       movem.l   D2/D3/D4/A2,-(A7)
       move.l    8(A6),D2
       lea       _OSTmrTime.L,A2
; OS_TMR       *ptmr1;
; OS_TMR_WHEEL *pspoke;
; INT16U        spoke;
; ptmr->OSTmrState = OS_TMR_STATE_RUNNING;
       move.l    D2,A0
       move.b    #3,35(A0)
; if (type == OS_TMR_LINK_PERIODIC) {                            /* Determine when timer will expire                */
       move.b    15(A6),D0
       cmp.b     #1,D0
       bne.s     @ucos_ii_OSTmr_Link_1
; ptmr->OSTmrMatch = ptmr->OSTmrPeriod + OSTmrTime;
       move.l    D2,A0
       move.l    26(A0),D0
       add.l     (A2),D0
       move.l    D2,A0
       move.l    D0,18(A0)
       bra.s     @ucos_ii_OSTmr_Link_4
@ucos_ii_OSTmr_Link_1:
; } else {
; if (ptmr->OSTmrDly == 0u) {
       move.l    D2,A0
       move.l    22(A0),D0
       bne.s     @ucos_ii_OSTmr_Link_3
; ptmr->OSTmrMatch = ptmr->OSTmrPeriod + OSTmrTime;
       move.l    D2,A0
       move.l    26(A0),D0
       add.l     (A2),D0
       move.l    D2,A0
       move.l    D0,18(A0)
       bra.s     @ucos_ii_OSTmr_Link_4
@ucos_ii_OSTmr_Link_3:
; } else {
; ptmr->OSTmrMatch = ptmr->OSTmrDly    + OSTmrTime;
       move.l    D2,A0
       move.l    22(A0),D0
       add.l     (A2),D0
       move.l    D2,A0
       move.l    D0,18(A0)
@ucos_ii_OSTmr_Link_4:
; }
; }
; spoke  = (INT16U)(ptmr->OSTmrMatch % OS_TMR_CFG_WHEEL_SIZE);
       move.l    D2,D0
       add.l     #18,D0
       move.l    D0,A0
       move.l    (A0),-(A7)
       pea       8
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       move.w    D0,-2(A6)
; pspoke = &OSTmrWheelTbl[spoke];
       lea       _OSTmrWheelTbl.L,A0
       move.w    -2(A6),D0
       and.l     #65535,D0
       lsl.l     #2,D0
       add.l     D0,A0
       move.l    A0,D3
; if (pspoke->OSTmrFirst == (OS_TMR *)0) {                       /* Link into timer wheel                           */
       move.l    D3,A0
       move.l    (A0),D0
       bne.s     @ucos_ii_OSTmr_Link_5
; pspoke->OSTmrFirst   = ptmr;
       move.l    D3,A0
       move.l    D2,(A0)
; ptmr->OSTmrNext      = (OS_TMR *)0;
       move.l    D2,A0
       clr.l     10(A0)
; pspoke->OSTmrEntries = 1u;
       move.l    D3,A0
       move.w    #1,4(A0)
       bra.s     @ucos_ii_OSTmr_Link_6
@ucos_ii_OSTmr_Link_5:
; } else {
; ptmr1                = pspoke->OSTmrFirst;                 /* Point to first timer in the spoke               */
       move.l    D3,A0
       move.l    (A0),D4
; pspoke->OSTmrFirst   = ptmr;
       move.l    D3,A0
       move.l    D2,(A0)
; ptmr->OSTmrNext      = (void *)ptmr1;
       move.l    D2,A0
       move.l    D4,10(A0)
; ptmr1->OSTmrPrev     = (void *)ptmr;
       move.l    D4,A0
       move.l    D2,14(A0)
; pspoke->OSTmrEntries++;
       move.l    D3,D0
       addq.l    #4,D0
       move.l    D0,A0
       addq.w    #1,(A0)
@ucos_ii_OSTmr_Link_6:
; }
; ptmr->OSTmrPrev = (void *)0;                                   /* Timer always inserted as first node in list     */
       move.l    D2,A0
       clr.l     14(A0)
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                 REMOVE A TIMER FROM THE TIMER WHEEL
; *
; * Description: This function is called to remove the timer from the timer wheel.
; *
; * Arguments  : ptmr          Is a pointer to the timer to remove.
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; static  void  OSTmr_Unlink (OS_TMR *ptmr)
; {
@ucos_ii_OSTmr_Unlink:
       link      A6,#-4
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    8(A6),D2
; OS_TMR        *ptmr1;
; OS_TMR        *ptmr2;
; OS_TMR_WHEEL  *pspoke;
; INT16U         spoke;
; spoke  = (INT16U)(ptmr->OSTmrMatch % OS_TMR_CFG_WHEEL_SIZE);
       move.l    D2,D0
       add.l     #18,D0
       move.l    D0,A0
       move.l    (A0),-(A7)
       pea       8
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       move.w    D0,-2(A6)
; pspoke = &OSTmrWheelTbl[spoke];
       lea       _OSTmrWheelTbl.L,A0
       move.w    -2(A6),D0
       and.l     #65535,D0
       lsl.l     #2,D0
       add.l     D0,A0
       move.l    A0,D5
; if (pspoke->OSTmrFirst == ptmr) {                       /* See if timer to remove is at the beginning of list     */
       move.l    D5,A0
       cmp.l     (A0),D2
       bne.s     @ucos_ii_OSTmr_Unlink_1
; ptmr1              = (OS_TMR *)ptmr->OSTmrNext;
       move.l    D2,A0
       move.l    10(A0),D3
; pspoke->OSTmrFirst = (OS_TMR *)ptmr1;
       move.l    D5,A0
       move.l    D3,(A0)
; if (ptmr1 != (OS_TMR *)0) {
       tst.l     D3
       beq.s     @ucos_ii_OSTmr_Unlink_3
; ptmr1->OSTmrPrev = (void *)0;
       move.l    D3,A0
       clr.l     14(A0)
@ucos_ii_OSTmr_Unlink_3:
       bra.s     @ucos_ii_OSTmr_Unlink_5
@ucos_ii_OSTmr_Unlink_1:
; }
; } else {
; ptmr1            = (OS_TMR *)ptmr->OSTmrPrev;       /* Remove timer from somewhere in the list                */
       move.l    D2,A0
       move.l    14(A0),D3
; ptmr2            = (OS_TMR *)ptmr->OSTmrNext;
       move.l    D2,A0
       move.l    10(A0),D4
; ptmr1->OSTmrNext = ptmr2;
       move.l    D3,A0
       move.l    D4,10(A0)
; if (ptmr2 != (OS_TMR *)0) {
       tst.l     D4
       beq.s     @ucos_ii_OSTmr_Unlink_5
; ptmr2->OSTmrPrev = (void *)ptmr1;
       move.l    D4,A0
       move.l    D3,14(A0)
@ucos_ii_OSTmr_Unlink_5:
; }
; }
; ptmr->OSTmrState = OS_TMR_STATE_STOPPED;
       move.l    D2,A0
       move.b    #1,35(A0)
; ptmr->OSTmrNext  = (void *)0;
       move.l    D2,A0
       clr.l     10(A0)
; ptmr->OSTmrPrev  = (void *)0;
       move.l    D2,A0
       clr.l     14(A0)
; pspoke->OSTmrEntries--;
       move.l    D5,D0
       addq.l    #4,D0
       move.l    D0,A0
       subq.w    #1,(A0)
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; #endif
; /*$PAGE*/
; /*
; *********************************************************************************************************
; *                                        TIMER MANAGEMENT TASK
; *
; * Description: This task is created by OSTmrInit().
; *
; * Arguments  : none
; *
; * Returns    : none
; *********************************************************************************************************
; */
; #if OS_TMR_EN > 0u
; static  void  OSTmr_Task (void *p_arg)
; {
@ucos_ii_OSTmr_Task:
       link      A6,#-12
       movem.l   D2/D3/A2,-(A7)
       lea       _OSTmrTime.L,A2
; INT8U            err;
; OS_TMR          *ptmr;
; OS_TMR          *ptmr_next;
; OS_TMR_CALLBACK  pfnct;
; OS_TMR_WHEEL    *pspoke;
; INT16U           spoke;
; p_arg = p_arg;                                               /* Prevent compiler warning for not using 'p_arg'    */
; for (;;) {
@ucos_ii_OSTmr_Task_1:
; OSSemPend(OSTmrSemSignal, 0u, &err);                     /* Wait for signal indicating time to update timers  */
       pea       -11(A6)
       clr.l     -(A7)
       move.l    _OSTmrSemSignal.L,-(A7)
       jsr       _OSSemPend
       add.w     #12,A7
; OSSchedLock();
       jsr       _OSSchedLock
; OSTmrTime++;                                             /* Increment the current time                        */
       addq.l    #1,(A2)
; spoke  = (INT16U)(OSTmrTime % OS_TMR_CFG_WHEEL_SIZE);    /* Position on current timer wheel entry             */
       move.l    (A2),-(A7)
       pea       8
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       move.w    D0,-2(A6)
; pspoke = &OSTmrWheelTbl[spoke];
       lea       _OSTmrWheelTbl.L,A0
       move.w    -2(A6),D0
       and.l     #65535,D0
       lsl.l     #2,D0
       add.l     D0,A0
       move.l    A0,-6(A6)
; ptmr   = pspoke->OSTmrFirst;
       move.l    -6(A6),A0
       move.l    (A0),D2
; while (ptmr != (OS_TMR *)0) {
@ucos_ii_OSTmr_Task_4:
       tst.l     D2
       beq       @ucos_ii_OSTmr_Task_6
; ptmr_next = (OS_TMR *)ptmr->OSTmrNext;               /* Point to next timer to update because current ... */
       move.l    D2,A0
       move.l    10(A0),-10(A6)
; /* ... timer could get unlinked from the wheel.      */
; if (OSTmrTime == ptmr->OSTmrMatch) {                 /* Process each timer that expires                   */
       move.l    D2,A0
       move.l    (A2),D0
       cmp.l     18(A0),D0
       bne       @ucos_ii_OSTmr_Task_11
; OSTmr_Unlink(ptmr);                              /* Remove from current wheel spoke                   */
       move.l    D2,-(A7)
       jsr       @ucos_ii_OSTmr_Unlink
       addq.w    #4,A7
; if (ptmr->OSTmrOpt == OS_TMR_OPT_PERIODIC) {
       move.l    D2,A0
       move.b    34(A0),D0
       cmp.b     #2,D0
       bne.s     @ucos_ii_OSTmr_Task_9
; OSTmr_Link(ptmr, OS_TMR_LINK_PERIODIC);      /* Recalculate new position of timer in wheel        */
       pea       1
       move.l    D2,-(A7)
       jsr       @ucos_ii_OSTmr_Link
       addq.w    #8,A7
       bra.s     @ucos_ii_OSTmr_Task_10
@ucos_ii_OSTmr_Task_9:
; } else {
; ptmr->OSTmrState = OS_TMR_STATE_COMPLETED;   /* Indicate that the timer has completed             */
       move.l    D2,A0
       move.b    #2,35(A0)
@ucos_ii_OSTmr_Task_10:
; }
; pfnct = ptmr->OSTmrCallback;                     /* Execute callback function if available            */
       move.l    D2,A0
       move.l    2(A0),D3
; if (pfnct != (OS_TMR_CALLBACK)0) {
       tst.l     D3
       beq.s     @ucos_ii_OSTmr_Task_11
; (*pfnct)((void *)ptmr, ptmr->OSTmrCallbackArg);
       move.l    D2,A0
       move.l    6(A0),-(A7)
       move.l    D2,-(A7)
       move.l    D3,A0
       jsr       (A0)
       addq.w    #8,A7
@ucos_ii_OSTmr_Task_11:
; }
; }
; ptmr = ptmr_next;
       move.l    -10(A6),D2
       bra       @ucos_ii_OSTmr_Task_4
@ucos_ii_OSTmr_Task_6:
; }
; OSSchedUnlock();
       jsr       _OSSchedUnlock
       bra       @ucos_ii_OSTmr_Task_1
; /*
; *********************************************************************************************************
; *                                                uC/OS-II
; *                                          The Real-Time Kernel
; *
; *                              (c) Copyright 1992-2009, Micrium, Weston, FL
; *                                           All Rights Reserved
; *
; * File    : uCOS_II.C
; * By      : Jean J. Labrosse
; * Version : V2.91
; *
; * LICENSING TERMS:
; * ---------------
; *   uC/OS-II is provided in source form for FREE evaluation, for educational use or for peaceful research.
; * If you plan on using  uC/OS-II  in a commercial product you need to contact Micriµm to properly license
; * its use in your product. We provide ALL the source code for your convenience and to help you experience
; * uC/OS-II.   The fact that the  source is provided does  NOT  mean that you can use it without  paying a
; * licensing fee.
; *********************************************************************************************************
; */
; #define  OS_GLOBALS                           /* Declare GLOBAL variables                              */
; #include "ucos_ii.h"
; #define  OS_MASTER_FILE                       /* Prevent the following files from including includes.h */
; #include "os_core.c"
; #include "os_flag.c"
; #include "os_mbox.c"
; #include "os_mem.c"
; #include "os_mutex.c"
; #include "os_q.c"
; #include "os_sem.c"
; #include "os_task.c"
; #include "os_time.c"
; #include "os_tmr.c"
       section   const
@ucos_ii_1:
       dc.b      63,0
@ucos_ii_2:
       dc.b      117,67,47,79,83,45,73,73,32,73,100,108,101,0
@ucos_ii_3:
       dc.b      117,67,47,79,83,45,73,73,32,83,116,97,116,0
@ucos_ii_4:
       dc.b      117,67,47,79,83,45,73,73,32,84,109,114,76,111
       dc.b      99,107,0
@ucos_ii_5:
       dc.b      117,67,47,79,83,45,73,73,32,84,109,114,83,105
       dc.b      103,110,97,108,0
@ucos_ii_6:
       dc.b      117,67,47,79,83,45,73,73,32,84,109,114,0
       xdef      _OSUnMapTbl
_OSUnMapTbl:
       dc.b      0,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0
       dc.b      1,0,3,0,1,0,2,0,1,0,5,0,1,0,2,0,1,0,3,0,1,0
       dc.b      2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,6,0
       dc.b      1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0
       dc.b      3,0,1,0,2,0,1,0,5,0,1,0,2,0,1,0,3,0,1,0,2,0
       dc.b      1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,7,0,1,0
       dc.b      2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0
       dc.b      1,0,2,0,1,0,5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
       dc.b      4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,6,0,1,0,2,0
       dc.b      1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0
       dc.b      2,0,1,0,5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0
       dc.b      1,0,2,0,1,0,3,0,1,0,2,0,1,0
       section   bss
       xdef      _OSCtxSwCtr
_OSCtxSwCtr:
       ds.b      4
       xdef      _OSEventFreeList
_OSEventFreeList:
       ds.b      4
       xdef      _OSEventTbl
_OSEventTbl:
       ds.b      220
       xdef      _OSFlagTbl
_OSFlagTbl:
       ds.b      60
       xdef      _OSFlagFreeList
_OSFlagFreeList:
       ds.b      4
       xdef      _OSCPUUsage
_OSCPUUsage:
       ds.b      1
       xdef      _OSIdleCtrMax
_OSIdleCtrMax:
       ds.b      4
       xdef      _OSIdleCtrRun
_OSIdleCtrRun:
       ds.b      4
       xdef      _OSStatRdy
_OSStatRdy:
       ds.b      1
       xdef      _OSTaskStatStk
_OSTaskStatStk:
       ds.b      256
       xdef      _OSIntNesting
_OSIntNesting:
       ds.b      1
       xdef      _OSLockNesting
_OSLockNesting:
       ds.b      1
       xdef      _OSPrioCur
_OSPrioCur:
       ds.b      1
       xdef      _OSPrioHighRdy
_OSPrioHighRdy:
       ds.b      1
       xdef      _OSRdyGrp
_OSRdyGrp:
       ds.b      1
       xdef      _OSRdyTbl
_OSRdyTbl:
       ds.b      8
       xdef      _OSRunning
_OSRunning:
       ds.b      1
       xdef      _OSTaskCtr
_OSTaskCtr:
       ds.b      1
       xdef      _OSIdleCtr
_OSIdleCtr:
       ds.b      4
       xdef      _OSTaskIdleStk
_OSTaskIdleStk:
       ds.b      256
       xdef      _OSTCBCur
_OSTCBCur:
       ds.b      4
       xdef      _OSTCBFreeList
_OSTCBFreeList:
       ds.b      4
       xdef      _OSTCBHighRdy
_OSTCBHighRdy:
       ds.b      4
       xdef      _OSTCBList
_OSTCBList:
       ds.b      4
       xdef      _OSTCBPrioTbl
_OSTCBPrioTbl:
       ds.b      256
       xdef      _OSTCBTbl
_OSTCBTbl:
       ds.b      1892
       xdef      _OSMemFreeList
_OSMemFreeList:
       ds.b      4
       xdef      _OSMemTbl
_OSMemTbl:
       ds.b      120
       xdef      _OSQFreeList
_OSQFreeList:
       ds.b      4
       xdef      _OSQTbl
_OSQTbl:
       ds.b      96
       xdef      _OSTaskRegNextAvailID
_OSTaskRegNextAvailID:
       ds.b      1
       xdef      _OSTime
_OSTime:
       ds.b      4
       xdef      _OSTmrFree
_OSTmrFree:
       ds.b      2
       xdef      _OSTmrUsed
_OSTmrUsed:
       ds.b      2
       xdef      _OSTmrTime
_OSTmrTime:
       ds.b      4
       xdef      _OSTmrSem
_OSTmrSem:
       ds.b      4
       xdef      _OSTmrSemSignal
_OSTmrSemSignal:
       ds.b      4
       xdef      _OSTmrTbl
_OSTmrTbl:
       ds.b      576
       xdef      _OSTmrFreeList
_OSTmrFreeList:
       ds.b      4
       xdef      _OSTmrTaskStk
_OSTmrTaskStk:
       ds.b      256
       xdef      _OSTmrWheelTbl
_OSTmrWheelTbl:
       ds.b      32
       xref      _OSTaskStatHook
       xref      _OSInitHookBegin
       xref      _OSTaskStkInit
       xref      _OSInitHookEnd
       xref      ULMUL
       xref      _OSTimeTickHook
       xref      _OSTaskIdleHook
       xref      _OSTaskDelHook
       xref      _OSIntCtxSw
       xref      _OSTaskCreateHook
       xref      ULDIV
       xref      _OSTCBInitHook
       xref      _OSStartHighRdy
       xref      _OSTaskReturnHook
