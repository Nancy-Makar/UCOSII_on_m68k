; C:\CPEN412\GITHUB_STEUP\M68KV6.0 - 800BY480\PROGRAMS\DEBUGMONITORCODE\M68KUSERPROGRAM (DE1).C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; /*********************************************************************************************
; **	RS232 port addresses
; *********************************************************************************************/
; #define RS232_Control *(volatile unsigned char *)(0x00400040)
; #define RS232_Status *(volatile unsigned char *)(0x00400040)
; #define RS232_TxData *(volatile unsigned char *)(0x00400042)
; #define RS232_RxData *(volatile unsigned char *)(0x00400042)
; #define RS232_Baud *(volatile unsigned char *)(0x00400044)
; /*************************************************************
; ** I2C Controller registers
; **************************************************************/
; #define I2C_PRESCALE_LOW (*(volatile unsigned char *)(0x00408000))
; #define I2C_PRESCALE_HIGH (*(volatile unsigned char *)(0x00408002))
; #define I2C_CTR (*(volatile unsigned char *)(0x00408004))
; #define I2C_TxRx (*(volatile unsigned char *)(0x00408006))
; #define I2C_CMDR (*(volatile unsigned char *)(0x00408008))
; // Constants specific to EEPROM
; #define CTR_BYTE 0x0A
; #define B0 0x00
; #define A0 0x00
; #define A1 0x00
; // IIC command register bit masks
; #define I2C_CTR_STA 0x80
; #define I2C_CTR_STO 0x40
; #define I2C_CTR_RD 0x20
; #define I2C_CTR_WR 0x10
; #define I2C_CTR_ACK 0x08
; #define I2C_CTR_IACK 0x01
; // IIC status register bit masks
; #define IIC_SR_RxAck 0x80
; #define IIC_SR_Busy 0x40
; #define IIC_SR_AL 0x20
; #define IIC_SR_TIP 0x02 // 1 while transferring, 0 when complete
; #define IIC_SR_IF 0x01  // poll to see when data is received
; /*********************************************************************************************************************************
; (( DO NOT initialise global variables here, do it main even if you want 0
; (( it's a limitation of the compiler
; (( YOU HAVE BEEN WARNED
; *********************************************************************************************************************************/
; // IIC Function Prototypes
; void I2C_Init(void);
; void I2C_Start(unsigned char WR_RD);
; void I2C_Stop(void);
; void WaitForDevice(void);
; void TransmitContolByteToEEPROM(unsigned char WE);
; void WaitForRxACK(void);
; void WaitForSRTIPFlag(void);
; void EEPROMWriteByte(unsigned char data, char upper_address, char lower_address);
; void WaitForDeviceReadyandAck(void);
; void EEPROMReadByte(unsigned char data, unsigned char lower_address);
; void EEPROMWritePage(unsigned char data);
; void EEPROMReadPage(void);
; /*****************************************************************************************
; **	Interrupt service routine for Timers
; **
; **  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
; **  out which timer is producing the interrupt
; **
; *****************************************************************************************/
; // converts hex char to 4 bit binary equiv in range 0000-1111 (0-F)
; // char assumed to be a valid hex char 0-9, a-f, A-F
; char xtod(int c)
; {
       section   code
       xdef      _xtod
_xtod:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if ((char)(c) <= (char)('9'))
       cmp.b     #57,D2
       bgt.s     xtod_1
; return c - (char)(0x30);      // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
       move.b    D2,D0
       sub.b     #48,D0
       bra.s     xtod_3
xtod_1:
; else if ((char)(c) > (char)('F')) // assume lower case
       cmp.b     #70,D2
       ble.s     xtod_4
; return c - (char)(0x57);      // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
       move.b    D2,D0
       sub.b     #87,D0
       bra.s     xtod_3
xtod_4:
; else
; return c - (char)(0x37); // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
       move.b    D2,D0
       sub.b     #55,D0
xtod_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get2HexDigits(char *CheckSumPtr)
; {
       xdef      _Get2HexDigits
_Get2HexDigits:
       link      A6,#0
       move.l    D2,-(A7)
; register int i = (xtod(_getch()) << 4) | (xtod(_getch()));
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       asl.l     #4,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       __getch
       move.l    (A7)+,D1
       move.l    D0,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D2
; if (CheckSumPtr)
       tst.l     8(A6)
       beq.s     Get2HexDigits_1
; *CheckSumPtr += i;
       move.l    8(A6),A0
       add.b     D2,(A0)
Get2HexDigits_1:
; return i;
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get4HexDigits(char *CheckSumPtr)
; {
       xdef      _Get4HexDigits
_Get4HexDigits:
       link      A6,#0
; return (Get2HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get6HexDigits(char *CheckSumPtr)
; {
       xdef      _Get6HexDigits
_Get6HexDigits:
       link      A6,#0
; return (Get4HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get8HexDigits(char *CheckSumPtr)
; {
       xdef      _Get8HexDigits
_Get8HexDigits:
       link      A6,#0
; return (Get4HexDigits(CheckSumPtr) << 16) | (Get4HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int _putch( int c)
; {
       xdef      __putch
__putch:
       link      A6,#0
; while((RS232_Status & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
_putch_1:
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       beq.s     _putch_3
       bra       _putch_1
_putch_3:
; ;
; RS232_TxData = (c & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
       move.l    8(A6),D0
       and.l     #127,D0
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
; **  NOTE you do not call this function directly, instead you call the normal getchar() function
; **  which in turn calls _getch() below). Other functions like gets(), scanf() call getchar() so will
; **  call _getch() also
; *********************************************************************************************************/
; int _getch( void )
; {
       xdef      __getch
__getch:
       link      A6,#-4
; char c ;
; while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
_getch_1:
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     _getch_3
       bra       _getch_1
_getch_3:
; ;
; return (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
       move.b    4194370,D0
       and.l     #255,D0
       and.l     #127,D0
       unlk      A6
       rts
; }
; void I2C_Start(unsigned char WR_RD)
; {
       xdef      _I2C_Start
_I2C_Start:
       link      A6,#0
; I2C_CMDR = I2C_CTR_STA | WR_RD ;
       move.w    #128,D0
       move.b    11(A6),D1
       and.w     #255,D1
       or.w      D1,D0
       move.b    D0,4227080
       unlk      A6
       rts
; }
; void I2C_Stop(void)
; {
       xdef      _I2C_Stop
_I2C_Stop:
; I2C_CMDR = I2C_CTR_STO;
       move.b    #64,4227080
       rts
; }
; void I2C_Init(void)
; {
       xdef      _I2C_Init
_I2C_Init:
; // Make sure I2C core is off before adjusting soft core clock
; I2C_CTR = 0x00;
       clr.b     4227076
; // Set SCL frequency to 100kHz
; I2C_PRESCALE_LOW = 0x31;
       move.b    #49,4227072
; I2C_PRESCALE_HIGH = 0x00;
       clr.b     4227074
; // Enable core and disable interrupts
; I2C_CTR = (I2C_CTR & 0x3F) | (1 << 7);
       move.b    4227076,D0
       and.b     #63,D0
       or.b      #128,D0
       move.b    D0,4227076
       rts
; }
; void TransmitByte(unsigned char data)
; {
       xdef      _TransmitByte
_TransmitByte:
       link      A6,#0
; I2C_TxRx = data;
       move.b    11(A6),4227078
       unlk      A6
       rts
; }
; void TransmitContolByteToEEPROM(unsigned char WE)
; {
       xdef      _TransmitContolByteToEEPROM
_TransmitContolByteToEEPROM:
       link      A6,#0
; TransmitByte((CTR_BYTE << 4) | (B0 << 3) | (A1 << 2) | (A0 << 1) | WE);
       move.w    #160,D1
       or.b      11(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _TransmitByte
       addq.w    #4,A7
       unlk      A6
       rts
; }
; void WaitForRxACK(void)
; {
       xdef      _WaitForRxACK
_WaitForRxACK:
; // Status Register [7] == 0
; while (I2C_CMDR & 0x80);
WaitForRxACK_1:
       move.b    4227080,D0
       and.w     #255,D0
       and.w     #128,D0
       beq.s     WaitForRxACK_3
       bra       WaitForRxACK_1
WaitForRxACK_3:
       rts
; }
; void WaitForDevice(void)
; {
       xdef      _WaitForDevice
_WaitForDevice:
; // Status Register bits 7,6,1,0 should be 0
; while (I2C_CMDR & 0xC2);
WaitForDevice_1:
       move.b    4227080,D0
       and.w     #255,D0
       and.w     #194,D0
       beq.s     WaitForDevice_3
       bra       WaitForDevice_1
WaitForDevice_3:
       rts
; }
; void WaitForSRTIPFlag(void) {
       xdef      _WaitForSRTIPFlag
_WaitForSRTIPFlag:
; while (I2C_CMDR & IIC_SR_TIP);
WaitForSRTIPFlag_1:
       move.b    4227080,D0
       and.b     #2,D0
       beq.s     WaitForSRTIPFlag_3
       bra       WaitForSRTIPFlag_1
WaitForSRTIPFlag_3:
       rts
; }
; void WaitForDeviceReadyandAck(void)
; {
       xdef      _WaitForDeviceReadyandAck
_WaitForDeviceReadyandAck:
; WaitForDevice();
       jsr       _WaitForDevice
; WaitForRxACK();
       jsr       _WaitForRxACK
       rts
; }
; void EEPROMWriteByte(unsigned char data, char upper_address, char lower_address)
; {
       xdef      _EEPROMWriteByte
_EEPROMWriteByte:
       link      A6,#0
       movem.l   A2/A3/A4/A5,-(A7)
       lea       _WaitForRxACK.L,A2
       lea       _WaitForSRTIPFlag.L,A3
       lea       _printf.L,A4
       lea       _TransmitByte.L,A5
; printf("\r\nDevice is not ready");
       pea       @m68kus~1_1.L
       jsr       (A4)
       addq.w    #4,A7
; WaitForDevice();
       jsr       _WaitForDevice
; printf("\r\nDevice is ready");
       pea       @m68kus~1_2.L
       jsr       (A4)
       addq.w    #4,A7
; TransmitContolByteToEEPROM(0x00);
       clr.l     -(A7)
       jsr       _TransmitContolByteToEEPROM
       addq.w    #4,A7
; I2C_CMDR =  I2C_CTR_STA | I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #145,4227080
; // I2C_CMDR = 0X91;
; WaitForSRTIPFlag();
       jsr       (A3)
; WaitForRxACK();
       jsr       (A2)
; printf("\r\n Sent control byte");
       pea       @m68kus~1_3.L
       jsr       (A4)
       addq.w    #4,A7
; // Transmit EEPROM internal address, high byte followed by low byte
; TransmitByte(upper_address);
       move.b    15(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A5)
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #17,4227080
; //I2C_CMDR = 0x11;
; WaitForSRTIPFlag();
       jsr       (A3)
; WaitForRxACK();
       jsr       (A2)
; TransmitByte(lower_address);
       move.b    19(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A5)
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #17,4227080
; // I2C_CMDR = 0x11;
; WaitForSRTIPFlag();
       jsr       (A3)
; WaitForRxACK();
       jsr       (A2)
; printf("\r\n Sent address bytes");
       pea       @m68kus~1_4.L
       jsr       (A4)
       addq.w    #4,A7
; // Transmit byte to be written in EEPROM
; TransmitByte(data);
       move.b    11(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A5)
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_STO | I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #81,4227080
; WaitForSRTIPFlag();
       jsr       (A3)
; WaitForRxACK();
       jsr       (A2)
       movem.l   (A7)+,A2/A3/A4/A5
       unlk      A6
       rts
; }
; int I2C_Check_Read(void) {
       xdef      _I2C_Check_Read
_I2C_Check_Read:
       link      A6,#-4
; int value = I2C_CTR;
       move.b    4227076,D0
       and.l     #255,D0
       move.l    D0,-4(A6)
; return ((value & 0x01) == 0x01);
       move.l    -4(A6),D0
       and.l     #1,D0
       cmp.l     #1,D0
       bne.s     I2C_Check_Read_1
       moveq     #1,D0
       bra.s     I2C_Check_Read_2
I2C_Check_Read_1:
       clr.l     D0
I2C_Check_Read_2:
       unlk      A6
       rts
; }
; void WaitForI2CRead(void) {
       xdef      _WaitForI2CRead
_WaitForI2CRead:
; while (I2C_Check_Read() == 0) {
WaitForI2CRead_1:
       jsr       _I2C_Check_Read
       tst.l     D0
       bne.s     WaitForI2CRead_3
; //do nothing
; }
       bra       WaitForI2CRead_1
WaitForI2CRead_3:
       rts
; }
; void EEPROMReadByte(unsigned char upper_address, unsigned char lower_address)
; {
       xdef      _EEPROMReadByte
_EEPROMReadByte:
       link      A6,#-4
       movem.l   A2/A3/A4,-(A7)
       lea       _printf.L,A2
       lea       _WaitForSRTIPFlag.L,A3
       lea       _WaitForRxACK.L,A4
; unsigned char byteRead;
; // Check that the SPI bus is not busy
; printf("\r\nDevice not ready");
       pea       @m68kus~1_5.L
       jsr       (A2)
       addq.w    #4,A7
; WaitForDevice(); // only check the busy bit
       jsr       _WaitForDevice
; printf("\r\nDevice ready");
       pea       @m68kus~1_6.L
       jsr       (A2)
       addq.w    #4,A7
; // Transmit Control Byte
; TransmitContolByteToEEPROM(0x00);
       clr.l     -(A7)
       jsr       _TransmitContolByteToEEPROM
       addq.w    #4,A7
; // 0x91
; I2C_CMDR = I2C_CTR_STA | I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #145,4227080
; printf("\r\n I2C_CMDR: 0x02", I2C_CMDR);
       move.b    4227080,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_7.L
       jsr       (A2)
       addq.w    #8,A7
; WaitForSRTIPFlag();
       jsr       (A3)
; WaitForRxACK();
       jsr       (A4)
; printf("\r\nSent Control byte");
       pea       @m68kus~1_8.L
       jsr       (A2)
       addq.w    #4,A7
; // Transmit EEPROM internal address, high byte followed by low byte
; TransmitByte(upper_address);
       move.b    11(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _TransmitByte
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #17,4227080
; WaitForSRTIPFlag();
       jsr       (A3)
; WaitForRxACK();
       jsr       (A4)
; printf("\r\nSent 1st address");
       pea       @m68kus~1_9.L
       jsr       (A2)
       addq.w    #4,A7
; TransmitByte(lower_address);
       move.b    15(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _TransmitByte
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #17,4227080
; WaitForSRTIPFlag();
       jsr       (A3)
; WaitForRxACK();
       jsr       (A4)
; printf("\r\nSent 2nd address");
       pea       @m68kus~1_10.L
       jsr       (A2)
       addq.w    #4,A7
; // Send repeated start and control byte with RD flag set
; TransmitContolByteToEEPROM(0x01);
       pea       1
       jsr       _TransmitContolByteToEEPROM
       addq.w    #4,A7
; /**I2C_CMDR = I2C_CTR_STA | I2C_CTR_WR | I2C_CTR_IACK;
; //I2C_CMDR = 0x69;
; WaitForSRTIPFlag();
; WaitForRxACK();
; printf("\r\nSent second control byte");**/
; I2C_CMDR = I2C_CTR_STO | I2C_CTR_RD | I2C_CTR_IACK;
       move.b    #97,4227080
; WaitForSRTIPFlag();
       jsr       (A3)
; byteRead = I2C_TxRx;
       move.b    4227078,-1(A6)
; printf("\r\nRead: %02x from address %02x\r\n", byteRead, lower_address);
       move.b    15(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_11.L
       jsr       (A2)
       add.w     #12,A7
; I2C_CMDR = I2C_CTR_STO;
       move.b    #64,4227080
       movem.l   (A7)+,A2/A3/A4
       unlk      A6
       rts
; }
; void EEPROMWritePage(unsigned char data) {
       xdef      _EEPROMWritePage
_EEPROMWritePage:
       link      A6,#0
       movem.l   D2/A2/A3/A4/A5,-(A7)
       lea       _printf.L,A2
       lea       _WaitForRxACK.L,A3
       lea       _WaitForSRTIPFlag.L,A4
       lea       _TransmitByte.L,A5
; unsigned char i;
; // Check that the SPI bus is not busy
; printf("\r\nDevice is not ready");
       pea       @m68kus~1_1.L
       jsr       (A2)
       addq.w    #4,A7
; WaitForDevice();
       jsr       _WaitForDevice
; printf("\r\nDevice is ready");
       pea       @m68kus~1_2.L
       jsr       (A2)
       addq.w    #4,A7
; TransmitContolByteToEEPROM(0x00);
       clr.l     -(A7)
       jsr       _TransmitContolByteToEEPROM
       addq.w    #4,A7
; I2C_CMDR =  I2C_CTR_STA | I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #145,4227080
; // I2C_CMDR = 0X91;
; WaitForSRTIPFlag();
       jsr       (A4)
; WaitForRxACK();
       jsr       (A3)
; printf("\r\n Sent control byte");
       pea       @m68kus~1_3.L
       jsr       (A2)
       addq.w    #4,A7
; // Transmit EEPROM internal address, high byte followed by low byte
; TransmitByte(0x00);
       clr.l     -(A7)
       jsr       (A5)
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #17,4227080
; //I2C_CMDR = 0x11;
; WaitForSRTIPFlag();
       jsr       (A4)
; WaitForRxACK();
       jsr       (A3)
; TransmitByte(0x00);
       clr.l     -(A7)
       jsr       (A5)
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #17,4227080
; // I2C_CMDR = 0x11;
; WaitForSRTIPFlag();
       jsr       (A4)
; WaitForRxACK();
       jsr       (A3)
; printf("\r\n Sent address bytes");
       pea       @m68kus~1_4.L
       jsr       (A2)
       addq.w    #4,A7
; // Transmit bytes to be written in EEPROM
; // 128 bytes
; for (i = 0x0; i < 0x80; i++) {
       clr.b     D2
EEPROMWritePage_1:
       and.w     #255,D2
       cmp.w     #128,D2
       bhs.s     EEPROMWritePage_3
; // Transmit byte to be written in EEPROM
; TransmitByte(i);
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       (A5)
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #17,4227080
; WaitForRxACK();
       jsr       (A3)
; WaitForSRTIPFlag();
       jsr       (A4)
       addq.b    #1,D2
       bra       EEPROMWritePage_1
EEPROMWritePage_3:
; }
; I2C_CMDR = I2C_CTR_STO | I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #81,4227080
; printf("\r\n Sent stop command");
       pea       @m68kus~1_12.L
       jsr       (A2)
       addq.w    #4,A7
       movem.l   (A7)+,D2/A2/A3/A4/A5
       unlk      A6
       rts
; }
; void EEPROMReadPage() {
       xdef      _EEPROMReadPage
_EEPROMReadPage:
       link      A6,#-4
       movem.l   D2/A2/A3/A4,-(A7)
       lea       _printf.L,A2
       lea       _WaitForRxACK.L,A3
       lea       _WaitForSRTIPFlag.L,A4
; unsigned char i;
; unsigned char byteRead;
; // Check that the SPI bus is not busy
; printf("\r\nDevice not ready");
       pea       @m68kus~1_5.L
       jsr       (A2)
       addq.w    #4,A7
; WaitForDevice();
       jsr       _WaitForDevice
; printf("\r\nDevice ready");
       pea       @m68kus~1_6.L
       jsr       (A2)
       addq.w    #4,A7
; // Transmit Control Byte
; TransmitContolByteToEEPROM(0x00);
       clr.l     -(A7)
       jsr       _TransmitContolByteToEEPROM
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_STA | I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #145,4227080
; WaitForSRTIPFlag();
       jsr       (A4)
; WaitForRxACK();
       jsr       (A3)
; printf("\r\nSent Control byte");
       pea       @m68kus~1_8.L
       jsr       (A2)
       addq.w    #4,A7
; // Transmit EEPROM internal address, high byte followed by low byte
; TransmitByte(0x00);
       clr.l     -(A7)
       jsr       _TransmitByte
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #17,4227080
; WaitForSRTIPFlag();
       jsr       (A4)
; WaitForRxACK();
       jsr       (A3)
; printf("\r\nSent 1st address");
       pea       @m68kus~1_9.L
       jsr       (A2)
       addq.w    #4,A7
; TransmitByte(0x00);
       clr.l     -(A7)
       jsr       _TransmitByte
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #17,4227080
; WaitForSRTIPFlag();
       jsr       (A4)
; WaitForRxACK();
       jsr       (A3)
; printf("\r\nSent 2nd address");
       pea       @m68kus~1_10.L
       jsr       (A2)
       addq.w    #4,A7
; // Send repeated start and control byte with RD flag set
; TransmitContolByteToEEPROM(0x01);
       pea       1
       jsr       _TransmitContolByteToEEPROM
       addq.w    #4,A7
; I2C_CMDR = I2C_CTR_STA | I2C_CTR_WR | I2C_CTR_IACK;
       move.b    #145,4227080
; //I2C_CMDR = 0x69;
; WaitForSRTIPFlag();
       jsr       (A4)
; WaitForRxACK();
       jsr       (A3)
; printf("\r\nSent second control byte\n");
       pea       @m68kus~1_13.L
       jsr       (A2)
       addq.w    #4,A7
; for (i = 0x0; i < 0x08; i++)
       clr.b     D2
EEPROMReadPage_1:
       cmp.b     #8,D2
       bhs.s     EEPROMReadPage_3
; {
; I2C_CMDR = I2C_CTR_RD | I2C_CTR_ACK | I2C_CTR_IACK;
       move.b    #41,4227080
; WaitForSRTIPFlag();
       jsr       (A4)
; I2C_CMDR = I2C_CTR_RD | I2C_CTR_ACK | I2C_CTR_IACK;
       move.b    #41,4227080
; WaitForRxACK();
       jsr       (A3)
; byteRead = I2C_TxRx;
       move.b    4227078,-1(A6)
; printf("%02x ", byteRead);
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_14.L
       jsr       (A2)
       addq.w    #8,A7
       addq.b    #1,D2
       bra       EEPROMReadPage_1
EEPROMReadPage_3:
; }
; I2C_CMDR = I2C_CTR_STO;
       move.b    #64,4227080
       movem.l   (A7)+,D2/A2/A3/A4
       unlk      A6
       rts
; }
; void main()
; {
       xdef      _main
_main:
       link      A6,#-8
       move.l    D2,-(A7)
; int i;
; unsigned char byteToWrite, address;
; byteToWrite = 0x12;
       move.b    #18,-1(A6)
; I2C_CMDR = 0x00;
       clr.b     4227080
; I2C_Init();
       jsr       _I2C_Init
; address = 0x13;
       moveq     #19,D2
; EEPROMWriteByte(byteToWrite, 0x00, address);
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       clr.l     -(A7)
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _EEPROMWriteByte
       add.w     #12,A7
; EEPROMReadByte(0x00, address);
       and.l     #255,D2
       move.l    D2,-(A7)
       clr.l     -(A7)
       jsr       _EEPROMReadByte
       addq.w    #8,A7
; //EEPROMWritePage(0x00);
; // EEPROMReadByte(0x00, 0x12);
; /*EEPROMReadPage();
; for (i = 0x0; i < 0x80; i++) {
; EEPROMReadByte(0x00, i);
; }*/
; I2C_CTR = 0x00;
       clr.b     4227076
; while (1)
main_1:
; {}
       bra       main_1
; // programs should NOT exit as there is nothing to Exit TO !!!!!!
; // There is no OS - just press the reset button to end program and call debug
; }
       section   const
@m68kus~1_1:
       dc.b      13,10,68,101,118,105,99,101,32,105,115,32,110
       dc.b      111,116,32,114,101,97,100,121,0
@m68kus~1_2:
       dc.b      13,10,68,101,118,105,99,101,32,105,115,32,114
       dc.b      101,97,100,121,0
@m68kus~1_3:
       dc.b      13,10,32,83,101,110,116,32,99,111,110,116,114
       dc.b      111,108,32,98,121,116,101,0
@m68kus~1_4:
       dc.b      13,10,32,83,101,110,116,32,97,100,100,114,101
       dc.b      115,115,32,98,121,116,101,115,0
@m68kus~1_5:
       dc.b      13,10,68,101,118,105,99,101,32,110,111,116,32
       dc.b      114,101,97,100,121,0
@m68kus~1_6:
       dc.b      13,10,68,101,118,105,99,101,32,114,101,97,100
       dc.b      121,0
@m68kus~1_7:
       dc.b      13,10,32,73,50,67,95,67,77,68,82,58,32,48,120
       dc.b      48,50,0
@m68kus~1_8:
       dc.b      13,10,83,101,110,116,32,67,111,110,116,114,111
       dc.b      108,32,98,121,116,101,0
@m68kus~1_9:
       dc.b      13,10,83,101,110,116,32,49,115,116,32,97,100
       dc.b      100,114,101,115,115,0
@m68kus~1_10:
       dc.b      13,10,83,101,110,116,32,50,110,100,32,97,100
       dc.b      100,114,101,115,115,0
@m68kus~1_11:
       dc.b      13,10,82,101,97,100,58,32,37,48,50,120,32,102
       dc.b      114,111,109,32,97,100,100,114,101,115,115,32
       dc.b      37,48,50,120,13,10,0
@m68kus~1_12:
       dc.b      13,10,32,83,101,110,116,32,115,116,111,112,32
       dc.b      99,111,109,109,97,110,100,0
@m68kus~1_13:
       dc.b      13,10,83,101,110,116,32,115,101,99,111,110,100
       dc.b      32,99,111,110,116,114,111,108,32,98,121,116
       dc.b      101,10,0
@m68kus~1_14:
       dc.b      37,48,50,120,32,0
       xref      _printf
