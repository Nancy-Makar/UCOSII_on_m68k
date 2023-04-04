; C:\IDE68K\UCOSII\BIOS.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include "Bios.h"
; /*
; **  These basic IO routines are designed to handle input and output of characters
; **  via the serial port to the console of hyperternal
; **
; **  You need to include this code into your projects, either as a source file, or copy into your code
; */
; // things that need to be done at initialisation/boot include
; // 1) initialise serial port and LCD display
; // 2) initialise the LCD display
; // 3) install the trap handler for a context switch (trap0)
; // 4) install the TickISR for level 3 IRQ
; // these actions can be performed in OSInitHookBegin() in file OS_CPU_C.c (one the Port files)
; /*********************************************************************************************
; *Subroutine to initialise the RS232 Port by writing some commands to the internal registers
; *********************************************************************************************/
; void Init_RS232(void)
; {
       section   code
       xdef      _Init_RS232
_Init_RS232:
; RS232_Control = (char)(0x15) ; //  %00010101    divide by 16 clock, set rts low, 8 bits no parity, 1 stop bit transmitter interrupt disabled
       move.b    #21,4194368
; RS232_Baud = (char)(0x1) ;      // program baud rate generator 000 = 230k, 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
       move.b    #1,4194372
       rts
; }
; int kbhit(void)
; {
       xdef      _kbhit
_kbhit:
; if(((char)(RS232_Status) & (char)(0x02)) == (char)(0x02))    // wait for Tx bit in status register to be '1'
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       bne.s     kbhit_1
; return 1 ;
       moveq     #1,D0
       bra.s     kbhit_3
kbhit_1:
; else
; return 0 ;
       clr.l     D0
kbhit_3:
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level output function to 6850 ACIA
; **  This routine provides the basic functionality to output a single character to the serial Port
; **  to allow the board to communicate with HyperTerminal Program
; **
; **  NOTE you do not call this function directly, instead you call the normal putchar() function
; **  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
; **  call _putch() also
; *********************************************************************************************************/
; int _putch( int c)
; {
       xdef      __putch
__putch:
       link      A6,#0
; while(((char)(RS232_Status) & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
_putch_1:
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       beq.s     _putch_3
       bra       _putch_1
_putch_3:
; ;
; (char)(RS232_TxData) = ((char)(c) & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
       move.l    8(A6),D0
       and.b     #127,D0
       move.b    D0,4194370
; return c ;                                              // putchar() expects the character to be returned
       move.l    8(A6),D0
       unlk      A6
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level input function to 6850 ACIA
; **  This routine provides the basic functionality to input a single character from the serial Port
; **  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
; **
; **  NOTE you do not call this function directly, instead you call the normal _getch() function
; **  which in turn calls _getch() below). Other functions like gets(), scanf() call _getch() so will
; **  call _getch() also
; *********************************************************************************************************/
; int _getch( void )
; {
       xdef      __getch
__getch:
       move.l    D2,-(A7)
; int c ;
; while(((char)(RS232_Status) & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
_getch_1:
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     _getch_3
       bra       _getch_1
_getch_3:
; ;
; c = (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
       move.b    4194370,D0
       and.l     #255,D0
       and.l     #127,D0
       move.l    D0,D2
; _putch(c);
       move.l    D2,-(A7)
       jsr       __putch
       addq.w    #4,A7
; return c ;
       move.l    D2,D0
       move.l    (A7)+,D2
       rts
; }
; /************************************************************************************
; *Subroutine to give the 68000 something useless to do to waste 1 mSec
; ************************************************************************************/
; void Wait1ms(void)
; {
       xdef      _Wait1ms
_Wait1ms:
       move.l    D2,-(A7)
; long int  i ;
; for(i = 0; i < 1000; i ++)
       clr.l     D2
Wait1ms_1:
       cmp.l     #1000,D2
       bge.s     Wait1ms_3
       addq.l    #1,D2
       bra       Wait1ms_1
Wait1ms_3:
       move.l    (A7)+,D2
       rts
; ;
; }
; /************************************************************************************
; *Subroutine to give the 68000 something useless to do to waste 3 mSec
; **************************************************************************************/
; void Wait3ms(void)
; {
       xdef      _Wait3ms
_Wait3ms:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 3; i++)
       clr.l     D2
Wait3ms_1:
       cmp.l     #3,D2
       bge.s     Wait3ms_3
; Wait1ms() ;
       jsr       _Wait1ms
       addq.l    #1,D2
       bra       Wait3ms_1
Wait3ms_3:
       move.l    (A7)+,D2
       rts
; }
; /*********************************************************************************************
; *Subroutine to initialise the display by writing some commands to the LCD internal registers
; *********************************************************************************************/
; void Init_LCD(void)
; {
       xdef      _Init_LCD
_Init_LCD:
; LCDcommand = (char)(0x0c) ;
       move.b    #12,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDcommand = (char)(0x38) ;
       move.b    #56,4194336
; Wait3ms() ;
       jsr       _Wait3ms
       rts
; }
; /******************************************************************************
; *subroutine to output a single character held in d1 to the LCD display
; *it is assumed the character is an ASCII code and it will be displayed at the
; *current cursor position
; *******************************************************************************/
; void Outchar(int c)
; {
       xdef      _Outchar
_Outchar:
       link      A6,#0
; LCDdata = (char)(c);
       move.l    8(A6),D0
       move.b    D0,4194338
; Wait1ms() ;
       jsr       _Wait1ms
       unlk      A6
       rts
; }
; /**********************************************************************************
; *subroutine to output a message at the current cursor position of the LCD display
; ************************************************************************************/
; void OutMess(char *theMessage)
; {
       xdef      _OutMess
_OutMess:
       link      A6,#-4
; char c ;
; while((c = *theMessage++) != (char)(0))
OutMess_1:
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),-1(A6)
       move.b    (A0),D0
       beq.s     OutMess_3
; Outchar(c) ;
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Outchar
       addq.w    #4,A7
       bra       OutMess_1
OutMess_3:
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to clear the line by issuing 24 space characters
; *******************************************************************************/
; void Clearln(void)
; {
       xdef      _Clearln
_Clearln:
       move.l    D2,-(A7)
; unsigned char i ;
; for(i = 0; i < 24; i ++)
       clr.b     D2
Clearln_1:
       cmp.b     #24,D2
       bhs.s     Clearln_3
; Outchar(' ') ;  /* write a space char to the LCD display */
       pea       32
       jsr       _Outchar
       addq.w    #4,A7
       addq.b    #1,D2
       bra       Clearln_1
Clearln_3:
       move.l    (A7)+,D2
       rts
; }
; /******************************************************************************
; *subroutine to move the cursor to the start of line 1 and clear that line
; *******************************************************************************/
; void Oline0(char *theMessage)
; {
       xdef      _Oline0
_Oline0:
       link      A6,#0
; LCDcommand = (char)(0x80) ;
       move.b    #128,4194336
; Wait3ms();
       jsr       _Wait3ms
; Clearln() ;
       jsr       _Clearln
; LCDcommand = (char)(0x80) ;
       move.b    #128,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; OutMess(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _OutMess
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to move the cursor to the start of line 2 and clear that line
; *******************************************************************************/
; void Oline1(char *theMessage)
; {
       xdef      _Oline1
_Oline1:
       link      A6,#0
; LCDcommand = (char)(0xC0) ;
       move.b    #192,4194336
; Wait3ms();
       jsr       _Wait3ms
; Clearln() ;
       jsr       _Clearln
; LCDcommand = (char)(0xC0) ;
       move.b    #192,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; OutMess(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _OutMess
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /*********************************************************************************
; ** Timer ISR
; **********************************************************************************/
; void Timer_ISR(void)
; {
       xdef      _Timer_ISR
_Timer_ISR:
; if(Timer1Status == 1) {       // Did Timer 1 produce the Interrupt?
       move.b    4194354,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_1
; Timer1Control = 3;      	// if so clear interrupt and restart timer
       move.b    #3,4194354
Timer_ISR_1:
       rts
; }
; }
; /**********************************************************************************
; ** Timer Initialisation Routine
; **********************************************************************************/
; void Timer1_Init(void)
; {
       xdef      _Timer1_Init
_Timer1_Init:
; Timer1Data = 0x03;		// program 100 hz time delay into timer 1.
       move.b    #3,4194352
; /*
; ** timer driven off 25Mhz clock so program value so that it counts down in 0.01 secs
; ** the example 0x03 above is loaded into top 8 bits of a 24 bit timer so reads as
; ** 0x03FFFF a value of 0x03 would be 262,143/25,000,000, so is close to 1/100th sec
; **
; **
; ** Now write binary 00000011 to timer control register:
; **	Bit0 = 1 (enable interrupt from that timer)
; **	Bit 1 = 1 enable counting
; */
; Timer1Control = 3;
       move.b    #3,4194354
       rts
; }
; /*********************************************************************************************************************************
; **  IMPORTANT FUNCTION
; **  This function installs an exception (interrupt) handler so you can capture and deal with any 68000 exception in your program
; **  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
; **  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
; **  Calling this function allows you to deal with Interrupts for example
; **
; **	e.g. to install the function 'void Timer_ISR()' (see above in this program) to deal with interrupts from the timer do this
; **
; **	InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-8 on level 3 IRQ (exception number 27 on 68k)
; **
; **	see main below for other examples
; ***********************************************************************************************************************************/
; /*
; void InstallExceptionHandler( void (*function_ptr)(), int level)
; {
; volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor
; RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
; }
; */
