#include "Bios.h"
/*
**  These basic IO routines are designed to handle input and output of characters
**  via the serial port to the console of hyperternal
**
**  You need to include this code into your projects, either as a source file, or copy into your code
*/

// things that need to be done at initialisation/boot include
// 1) initialise serial port and LCD display
// 2) initialise the LCD display
// 3) install the trap handler for a context switch (trap0)
// 4) install the TickISR for level 3 IRQ
// these actions can be performed in OSInitHookBegin() in file OS_CPU_C.c (one the Port files)

/*********************************************************************************************
*Subroutine to initialise the RS232 Port by writing some commands to the internal registers
*********************************************************************************************/
void Init_RS232(void)
{
    RS232_Control = (char)(0x15) ; //  %00010101    divide by 16 clock, set rts low, 8 bits no parity, 1 stop bit transmitter interrupt disabled
    RS232_Baud = (char)(0x1) ;      // program baud rate generator 000 = 230k, 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
}

int kbhit(void)
{
    if(((char)(RS232_Status) & (char)(0x02)) == (char)(0x02))    // wait for Tx bit in status register to be '1'
        return 1 ;
    else
        return 0 ;
}

/*********************************************************************************************************
**  Subroutine to provide a low level output function to 6850 ACIA
**  This routine provides the basic functionality to output a single character to the serial Port
**  to allow the board to communicate with HyperTerminal Program
**
**  NOTE you do not call this function directly, instead you call the normal putchar() function
**  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
**  call _putch() also
*********************************************************************************************************/

int _putch( int c)
{
    while(((char)(RS232_Status) & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
        ;

    (char)(RS232_TxData) = ((char)(c) & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
    return c ;                                              // putchar() expects the character to be returned
}

/*********************************************************************************************************
**  Subroutine to provide a low level input function to 6850 ACIA
**  This routine provides the basic functionality to input a single character from the serial Port
**  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
**
**  NOTE you do not call this function directly, instead you call the normal _getch() function
**  which in turn calls _getch() below). Other functions like gets(), scanf() call _getch() so will
**  call _getch() also
*********************************************************************************************************/

int _getch( void )
{
    int c ;
    while(((char)(RS232_Status) & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
        ;

    c = (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
    _putch(c);
    return c ;
}

/************************************************************************************
*Subroutine to give the 68000 something useless to do to waste 1 mSec
************************************************************************************/
void Wait1ms(void)
{
    long int  i ;
    for(i = 0; i < 1000; i ++)
        ;
}

/************************************************************************************
*Subroutine to give the 68000 something useless to do to waste 3 mSec
**************************************************************************************/
void Wait3ms(void)
{
    int i ;
    for(i = 0; i < 3; i++)
        Wait1ms() ;
}

/*********************************************************************************************
*Subroutine to initialise the display by writing some commands to the LCD internal registers
*********************************************************************************************/
void Init_LCD(void)
{
    LCDcommand = (char)(0x0c) ;
    Wait3ms() ;
    LCDcommand = (char)(0x38) ;
    Wait3ms() ;
}

/******************************************************************************
*subroutine to output a single character held in d1 to the LCD display
*it is assumed the character is an ASCII code and it will be displayed at the
*current cursor position
*******************************************************************************/
void Outchar(int c)
{
    LCDdata = (char)(c);
    Wait1ms() ;
}

/**********************************************************************************
*subroutine to output a message at the current cursor position of the LCD display
************************************************************************************/
void OutMess(char *theMessage)
{
    char c ;
    while((c = *theMessage++) != (char)(0))
        Outchar(c) ;
}

/******************************************************************************
*subroutine to clear the line by issuing 24 space characters
*******************************************************************************/
void Clearln(void)
{
    unsigned char i ;
    for(i = 0; i < 24; i ++)
        Outchar(' ') ;  /* write a space char to the LCD display */
}

/******************************************************************************
*subroutine to move the cursor to the start of line 1 and clear that line
*******************************************************************************/
void Oline0(char *theMessage)
{
    LCDcommand = (char)(0x80) ;
    Wait3ms();
    Clearln() ;
    LCDcommand = (char)(0x80) ;
    Wait3ms() ;
    OutMess(theMessage) ;
}

/******************************************************************************
*subroutine to move the cursor to the start of line 2 and clear that line
*******************************************************************************/
void Oline1(char *theMessage)
{
    LCDcommand = (char)(0xC0) ;
    Wait3ms();
    Clearln() ;
    LCDcommand = (char)(0xC0) ;
    Wait3ms() ;
    OutMess(theMessage) ;
}

/*********************************************************************************
** Timer ISR
**********************************************************************************/
void Timer_ISR(void)
{
   	if(Timer1Status == 1) {       // Did Timer 1 produce the Interrupt?
   	    Timer1Control = 3;      	// if so clear interrupt and restart timer
   	}
}

/**********************************************************************************
** Timer Initialisation Routine
**********************************************************************************/
void Timer1_Init(void)
{
    Timer1Data = 0x03;		// program 100 hz time delay into timer 1.

/*
** timer driven off 25Mhz clock so program value so that it counts down in 0.01 secs
** the example 0x03 above is loaded into top 8 bits of a 24 bit timer so reads as
** 0x03FFFF a value of 0x03 would be 262,143/25,000,000, so is close to 1/100th sec
**
**
** Now write binary 00000011 to timer control register:
**	Bit0 = 1 (enable interrupt from that timer)
**	Bit 1 = 1 enable counting
*/

    Timer1Control = 3;
}

/*********************************************************************************************************************************
**  IMPORTANT FUNCTION
**  This function installs an exception (interrupt) handler so you can capture and deal with any 68000 exception in your program
**  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
**  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
**  Calling this function allows you to deal with Interrupts for example
**
**	e.g. to install the function 'void Timer_ISR()' (see above in this program) to deal with interrupts from the timer do this
**
**	InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-8 on level 3 IRQ (exception number 27 on 68k)
**
**	see main below for other examples
***********************************************************************************************************************************/

/*
void InstallExceptionHandler( void (*function_ptr)(), int level)
{
    volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor

    RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
}
*/