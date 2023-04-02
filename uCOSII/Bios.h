/*******************************************************************************************
** Function Prototypes for Serial Port
*******************************************************************************************/
void Init_RS232(void);
int _getch( void );
void Init_RS232(void);
int kbhit(void);
int _putch( int c);

/*******************************************************************************************
** Function Prototypes for LCD
*******************************************************************************************/
void Wait1ms(void);
void Wait3ms(void);
void Init_LCD(void) ;
void Outchar(int c);
void OutMess(char *theMessage);
void Clearln(void);
void Oline0(char *theMessage);
void Oline1(char *theMessage);

/*******************************************************************************************
** Function Prototypes for Timer
*******************************************************************************************/
void Timer1_Init(void);
void Timer_ISR(void);

/********************************************************************************************
**	Timer Port addresses
*********************************************************************************************/

#define Timer1Data      *(volatile unsigned char *)(0x00400030)
#define Timer1Control   *(volatile unsigned char *)(0x00400032)
#define Timer1Status    *(volatile unsigned char *)(0x00400032)

#define Timer2Data      *(volatile unsigned char *)(0x00400034)
#define Timer2Control   *(volatile unsigned char *)(0x00400036)
#define Timer2Status    *(volatile unsigned char *)(0x00400036)

#define Timer3Data      *(volatile unsigned char *)(0x00400038)
#define Timer3Control   *(volatile unsigned char *)(0x0040003A)
#define Timer3Status    *(volatile unsigned char *)(0x0040003A)

#define Timer4Data      *(volatile unsigned char *)(0x0040003C)
#define Timer4Control   *(volatile unsigned char *)(0x0040003E)
#define Timer4Status    *(volatile unsigned char *)(0x0040003E)

#define Timer5Data      *(volatile unsigned char *)(0x00400130)
#define Timer5Control   *(volatile unsigned char *)(0x00400132)
#define Timer5Status    *(volatile unsigned char *)(0x00400132)

#define Timer6Data      *(volatile unsigned char *)(0x00400134)
#define Timer6Control   *(volatile unsigned char *)(0x00400136)
#define Timer6Status    *(volatile unsigned char *)(0x00400136)

#define Timer7Data      *(volatile unsigned char *)(0x00400138)
#define Timer7Control   *(volatile unsigned char *)(0x0040013A)
#define Timer7Status    *(volatile unsigned char *)(0x0040013A)

#define Timer8Data      *(volatile unsigned char *)(0x0040013C)
#define Timer8Control   *(volatile unsigned char *)(0x0040013E)
#define Timer8Status    *(volatile unsigned char *)(0x0040013E)

/*********************************************************************************************
**	RS232 port addresses
*********************************************************************************************/

#define RS232_Control     *(volatile unsigned char *)(0x00400040)
#define RS232_Status      *(volatile unsigned char *)(0x00400040)
#define RS232_TxData      *(volatile unsigned char *)(0x00400042)
#define RS232_RxData      *(volatile unsigned char *)(0x00400042)
#define RS232_Baud        *(volatile unsigned char *)(0x00400044)

/**********************************************************************************************
**	LCD display port addresses
**********************************************************************************************/

#define LCDcommand   *(volatile unsigned char *)(0x00400020)
#define LCDdata      *(volatile unsigned char *)(0x00400022)

/**********************************************************************************************
**	Parallel port addresses
**********************************************************************************************/

#define PortA   *(volatile unsigned char *)(0x00400000)     // red leds 0-7
#define PortB   *(volatile unsigned char *)(0x00400002)     // red leds 8 and 9
#define PortC   *(volatile unsigned char *)(0x00400004)     // not connected
#define PortD   *(volatile unsigned char *)(0x00400006)     // not connected
#define PortE   *(volatile unsigned char *)(0x00400008)     // not connected

/*********************************************************************************************
**	Hex 7 seg displays port addresses
*********************************************************************************************/

#define HEX_A        *(volatile unsigned char *)(0x00400010)
#define HEX_B        *(volatile unsigned char *)(0x00400012)
#define HEX_C        *(volatile unsigned char *)(0x00400014)

#define StartOfExceptionVectorTable 0x08000000  // this has to be the same value declared in os_boot.asm bss section (org $08000000)