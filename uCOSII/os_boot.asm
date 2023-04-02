;********************************************************************************************************
;                                               uC/OS-II
;                                         The Real-Time Kernel
;
;                            (c) Copyright 1999, Jean J. Labrosse, Weston, FL
;                                          All Rights Reserved
;
;
;                                        IDE68K Specific boot code
;
;
; File         : OS_BOOT.ASM
; By           : Peter J. Fondse
;********************************************************************************************************

;********************************************************************************************************
;                                               NOTES
;
; This is the "Board Support Package" or BSP for the IDE68K simulator. It defines memory layout,
; interrupt vectors and a few BIOS functions.
;
;********************************************************************************************************

;********************************************************************************************************
;                                           REVISION HISTORY
;
; $Log$
;
;********************************************************************************************************

ROM        equ         $00000000       ; ROM starts at $00000000
RAM        equ         $00800000       ; RAM starts at $00800000 (for example)
RAMsize    equ         $00040000       ; Size of RAM (256 Kbyte for example)

           option      S0              ; Enter program ID in S0 record in .hex file

           section     code
           org         ROM
begin_ROM  equ         *
code       equ         *

           section     const
const      equ         *

           section     data
end_ROM    equ         *
           org         RAM
begin_RAM  equ         *
data       equ         *

           section     bss
bss        equ         *

           section     heap
end_RAM    equ         *
heap       equ         *

           section     code
           dc.l        __stack         ; Vector #  0, 0x00000000: Initial SP
           dc.l        startup         ; Vector #  1, 0x00000004: Initial PC
           dc.l        $04             ; Vector #  2, 0x00000008: Bus Error
           dc.l        $08             ; Vector #  3, 0x0000000C: Address Error
           dc.l        $0C             ; Vector #  4, 0x00000010: Illegal Instruction
           dc.l        $10             ; Vector #  5, 0x00000014: Zero Division
           dc.l        $14             ; Vector #  6, 0x00000018: CHK, CHK2 Instruction
           dc.l        $18             ; Vector #  7, 0x0000001C: TRAPxx, TRAPV Instructions
           dc.l        $1C             ; Vector #  8, 0x00000020: Privilege Violation
           dc.l        $20             ; Vector #  9, 0x00000024: Trace
           dc.l        $24             ; Vector # 10, 0x00000028: Line 1010 Emulator
           dc.l        $28             ; Vector # 11, 0x0000002C: Line 1111 Emulator
           dc.l        $2C             ; Vector # 12, 0x00000030: Hardware Breakpoint
           dc.l        $2C             ; Vector # 13, 0x00000034: Coprocessor Protocol Violation
           dc.l        $2C             ; Vector # 14, 0x00000038: Format error
           dc.l        $2C             ; Vector # 15, 0x0000003C: Format error
           dc.l        _OSTickISR      ; Vector # 16, 0x00000040: Timer Tick ISR
           dc.l        $2C             ; Vector # 17, 0x00000044: Reserved
           dc.l        $2C             ; Vector # 18, 0x00000048: Reserved
           dc.l        $2C             ; Vector # 19, 0x0000004C: Reserved
           dc.l        $4C             ; Vector # 20, 0x00000050: Reserved
           dc.l        $2C             ; Vector # 21, 0x00000054: Reserved
           dc.l        $2C             ; Vector # 22, 0x00000058: Reserved
           dc.l        $2C             ; Vector # 23, 0x0000005C: Reserved
           dc.l        $30             ; Vector # 24, 0x00000060: Spurious interrupt
           dc.l        $34             ; Vector # 25, 0x00000064: Level 1 Interrupt Autovector
           dc.l        $38             ; Vector # 26, 0x00000068: Level 2 Interrupt Autovector
           dc.l        $3C             ; Vector # 27, 0x0000006C: Level 3 Interrupt Autovector
           dc.l        $40             ; Vector # 28, 0x00000070: Level 4 Interrupt Autovector
           dc.l        $44             ; Vector # 29, 0x00000074: Level 5 Interrupt Autovector
           dc.l        $48             ; Vector # 30, 0x00000078: Level 6 Interrupt Autovector
           dc.l        $4C             ; Vector # 31, 0x0000007C: Level 7 Interrupt Autovector
           dc.l        _OSCtxSw        ; Vector # 32, 0x00000080: Trap # 0 Context switch
           dc.l        $54             ; Vector # 33, 0x00000084: Trap # 1
           dc.l        $58             ; Vector # 34, 0x00000088: Trap # 2
           dc.l        $5C             ; Vector # 35, 0x0000008C: Trap # 3
           dc.l        $60             ; Vector # 36, 0x00000090: Trap # 4
           dc.l        $64             ; Vector # 37, 0x00000094: Trap # 5
           dc.l        $68             ; Vector # 38, 0x00000098: Trap # 6
           dc.l        $6C             ; Vector # 39, 0x0000009C: Trap # 7
           dc.l        $70             ; Vector # 40, 0x000000A0: Trap # 8
           dc.l        $74             ; Vector # 41, 0x000000A4: Trap # 9
           dc.l        $78             ; Vector # 42, 0x000000A8: Trap #10
           dc.l        $7C             ; Vector # 43, 0x000000AC: Trap #11
           dc.l        $80             ; Vector # 44, 0x000000B0: Trap #12
           dc.l        $84             ; Vector # 45, 0x000000B4: Trap #13
           dc.l        $88             ; Vector # 46, 0x000000B8: Trap #14
           dc.l        $8C             ; Vector # 47, 0x000000BC: Trap #15 System call
           dc.l        $90             ; Vector # 48, 0x000000C0: Reserved
           dc.l        $94             ; Vector # 49, 0x000000C4: Reserved
           dc.l        $98             ; Vector # 50, 0x000000C8: Reserved
           dc.l        $9C             ; Vector # 51, 0x000000CC: Reserved
           dc.l        $A0             ; Vector # 52, 0x000000D0: Reserved
           dc.l        $A4             ; Vector # 53, 0x000000D4: Reserved
           dc.l        $A8             ; Vector # 54, 0x000000D8: Reserved
           dc.l        $AC             ; Vector # 55, 0x000000DC: Reserved
           dc.l        $B0             ; Vector # 56, 0x000000E0: Reserved
           dc.l        $B4             ; Vector # 57, 0x000000E4: Reserved
           dc.l        $B8             ; Vector # 58, 0x000000E8: Reserved
           dc.l        $BC             ; Vector # 59, 0x000000EC: Reserved
           dc.l        $C0             ; Vector # 60, 0x000000F0: Reserved
           dc.l        $C4             ; Vector # 61, 0x000000F4: Reserved
           dc.l        $C8             ; Vector # 62, 0x000000F8: Reserved
           dc.l        $CC             ; Vector # 63, 0x000000FC: Reserved
           dc.l        0               ; Vector # 64, 0x00000100: User Defined Vector
           dc.l        0               ; Vector # 65, 0x00000104: User Defined Vector
           dc.l        0               ; Vector # 66, 0x00000108: User Defined Vector
           dc.l        0               ; Vector # 67, 0x0000010C: User Defined Vector
           dc.l        0               ; Vector # 68, 0x00000110: User Defined Vector
           dc.l        0               ; Vector # 69, 0x00000114: User Defined Vector
           dc.l        0               ; Vector # 70, 0x00000118: User Defined Vector
           dc.l        0               ; Vector # 71, 0x0000011C: User Defined Vector
           dc.l        0               ; Vector # 72, 0x00000120: User Defined Vector
           dc.l        0               ; Vector # 73, 0x00000124: User Defined Vector
           dc.l        0               ; Vector # 74, 0x00000128: User Defined Vector
           dc.l        0               ; Vector # 75, 0x0000012C: User Defined Vector
           dc.l        0               ; Vector # 76, 0x00000130: User Defined Vector
           dc.l        0               ; Vector # 77, 0x00000134: User Defined Vector
           dc.l        0               ; Vector # 78, 0x00000138: User Defined Vector
           dc.l        0               ; Vector # 79, 0x0000013C: User Defined Vector
           dc.l        0               ; Vector # 80, 0x00000140: User Defined Vector
           dc.l        0               ; Vector # 81, 0x00000144: User Defined Vector
           dc.l        0               ; Vector # 82, 0x00000148: User Defined Vector
           dc.l        0               ; Vector # 83, 0x0000014C: User Defined Vector
           dc.l        0               ; Vector # 84, 0x00000150: User Defined Vector
           dc.l        0               ; Vector # 85, 0x00000154: User Defined Vector
           dc.l        0               ; Vector # 86, 0x00000158: User Defined Vector
           dc.l        0               ; Vector # 87, 0x0000015C: User Defined Vector
           dc.l        0               ; Vector # 88, 0x00000160: User Defined Vector
           dc.l        0               ; Vector # 89, 0x00000164: User Defined Vector
           dc.l        0               ; Vector # 90, 0x00000168: User Defined Vector
           dc.l        0               ; Vector # 91, 0x0000016C: User Defined Vector
           dc.l        0               ; Vector # 92, 0x00000170: User Defined Vector
           dc.l        0               ; Vector # 93, 0x00000174: User Defined Vector
           dc.l        0               ; Vector # 94, 0x00000178: User Defined Vector
           dc.l        0               ; Vector # 95, 0x0000017C: User Defined Vector
           dc.l        0               ; Vector # 96, 0x00000180: User Defined Vector
           dc.l        0               ; Vector # 97, 0x00000184: User Defined Vector
           dc.l        0               ; Vector # 98, 0x00000188: User Defined Vector
           dc.l        0               ; Vector # 99, 0x0000018C: User Defined Vector
           dc.l        0               ; Vector #100, 0x00000190: User Defined Vector
           dc.l        0               ; Vector #101, 0x00000194: User Defined Vector
           dc.l        0               ; Vector #102, 0x00000198: User Defined Vector
           dc.l        0               ; Vector #103, 0x0000019C: User Defined Vector
           dc.l        0               ; Vector #104, 0x000001A0: User Defined Vector
           dc.l        0               ; Vector #105, 0x000001A4: User Defined Vector
           dc.l        0               ; Vector #106, 0x000001A8: User Defined Vector
           dc.l        0               ; Vector #107, 0x000001AC: User Defined Vector
           dc.l        0               ; Vector #108, 0x000001B0: User Defined Vector
           dc.l        0               ; Vector #109, 0x000001B4: User Defined Vector
           dc.l        0               ; Vector #110, 0x000001B8: User Defined Vector
           dc.l        0               ; Vector #111, 0x000001BC: User Defined Vector
           dc.l        0               ; Vector #112, 0x000001C0: User Defined Vector
           dc.l        0               ; Vector #113, 0x000001C4: User Defined Vector
           dc.l        0               ; Vector #114, 0x000001C8: User Defined Vector
           dc.l        0               ; Vector #115, 0x000001CC: User Defined Vector
           dc.l        0               ; Vector #116, 0x000001D0: User Defined Vector
           dc.l        0               ; Vector #117, 0x000001D4: User Defined Vector
           dc.l        0               ; Vector #118, 0x000001D8: User Defined Vector
           dc.l        0               ; Vector #119, 0x000001DC: User Defined Vector
           dc.l        0               ; Vector #120, 0x000001E0: User Defined Vector
           dc.l        0               ; Vector #121, 0x000001E4: User Defined Vector
           dc.l        0               ; Vector #122, 0x000001E8: User Defined Vector
           dc.l        0               ; Vector #123, 0x000001EC: User Defined Vector
           dc.l        0               ; Vector #124, 0x000001F0: User Defined Vector
           dc.l        0               ; Vector #125, 0x000001F4: User Defined Vector
           dc.l        0               ; Vector #126, 0x000001F8: User Defined Vector
           dc.l        0               ; Vector #127, 0x000001FC: User Defined Vector
           dc.l        0               ; Vector #128, 0x00000200: User Defined Vector
           dc.l        0               ; Vector #129, 0x00000204: User Defined Vector
           dc.l        0               ; Vector #130, 0x00000208: User Defined Vector
           dc.l        0               ; Vector #131, 0x0000020C: User Defined Vector
           dc.l        0               ; Vector #132, 0x00000210: User Defined Vector
           dc.l        0               ; Vector #133, 0x00000214: User Defined Vector
           dc.l        0               ; Vector #134, 0x00000218: User Defined Vector
           dc.l        0               ; Vector #135, 0x0000021C: User Defined Vector
           dc.l        0               ; Vector #136, 0x00000220: User Defined Vector
           dc.l        0               ; Vector #137, 0x00000224: User Defined Vector
           dc.l        0               ; Vector #138, 0x00000228: User Defined Vector
           dc.l        0               ; Vector #139, 0x0000022C: User Defined Vector
           dc.l        0               ; Vector #140, 0x00000230: User Defined Vector
           dc.l        0               ; Vector #141, 0x00000234: User Defined Vector
           dc.l        0               ; Vector #142, 0x00000238: User Defined Vector
           dc.l        0               ; Vector #143, 0x0000023C: User Defined Vector
           dc.l        0               ; Vector #144, 0x00000240: User Defined Vector
           dc.l        0               ; Vector #145, 0x00000244: User Defined Vector
           dc.l        0               ; Vector #146, 0x00000248: User Defined Vector
           dc.l        0               ; Vector #147, 0x0000024C: User Defined Vector
           dc.l        0               ; Vector #148, 0x00000250: User Defined Vector
           dc.l        0               ; Vector #149, 0x00000254: User Defined Vector
           dc.l        0               ; Vector #150, 0x00000258: User Defined Vector
           dc.l        0               ; Vector #151, 0x0000025C: User Defined Vector
           dc.l        0               ; Vector #152, 0x00000260: User Defined Vector
           dc.l        0               ; Vector #153, 0x00000264: User Defined Vector
           dc.l        0               ; Vector #154, 0x00000268: User Defined Vector
           dc.l        0               ; Vector #155, 0x0000026C: User Defined Vector
           dc.l        0               ; Vector #156, 0x00000270: User Defined Vector
           dc.l        0               ; Vector #157, 0x00000274: User Defined Vector
           dc.l        0               ; Vector #158, 0x00000278: User Defined Vector
           dc.l        0               ; Vector #159, 0x0000027C: User Defined Vector
           dc.l        0               ; Vector #160, 0x00000280: User Defined Vector
           dc.l        0               ; Vector #161, 0x00000284: User Defined Vector
           dc.l        0               ; Vector #162, 0x00000288: User Defined Vector
           dc.l        0               ; Vector #163, 0x0000028C: User Defined Vector
           dc.l        0               ; Vector #164, 0x00000290: User Defined Vector
           dc.l        0               ; Vector #165, 0x00000294: User Defined Vector
           dc.l        0               ; Vector #166, 0x00000298: User Defined Vector
           dc.l        0               ; Vector #167, 0x0000029C: User Defined Vector
           dc.l        0               ; Vector #168, 0x000002A0: User Defined Vector
           dc.l        0               ; Vector #169, 0x000002A4: User Defined Vector
           dc.l        0               ; Vector #170, 0x000002A8: User Defined Vector
           dc.l        0               ; Vector #171, 0x000002AC: User Defined Vector
           dc.l        0               ; Vector #172, 0x000002B0: User Defined Vector
           dc.l        0               ; Vector #173, 0x000002B4: User Defined Vector
           dc.l        0               ; Vector #174, 0x000002B8: User Defined Vector
           dc.l        0               ; Vector #175, 0x000002BC: User Defined Vector
           dc.l        0               ; Vector #176, 0x000002C0: User Defined Vector
           dc.l        0               ; Vector #177, 0x000002C4: User Defined Vector
           dc.l        0               ; Vector #178, 0x000002C8: User Defined Vector
           dc.l        0               ; Vector #179, 0x000002CC: User Defined Vector
           dc.l        0               ; Vector #180, 0x000002D0: User Defined Vector
           dc.l        0               ; Vector #181, 0x000002D4: User Defined Vector
           dc.l        0               ; Vector #182, 0x000002D8: User Defined Vector
           dc.l        0               ; Vector #183, 0x000002DC: User Defined Vector
           dc.l        0               ; Vector #184, 0x000002E0: User Defined Vector
           dc.l        0               ; Vector #185, 0x000002E4: User Defined Vector
           dc.l        0               ; Vector #186, 0x000002E8: User Defined Vector
           dc.l        0               ; Vector #187, 0x000002EC: User Defined Vector
           dc.l        0               ; Vector #188, 0x000002F0: User Defined Vector
           dc.l        0               ; Vector #189, 0x000002F4: User Defined Vector
           dc.l        0               ; Vector #190, 0x000002F8: User Defined Vector
           dc.l        0               ; Vector #191, 0x000002FC: User Defined Vector
           dc.l        0               ; Vector #192, 0x00000300: User Defined Vector
           dc.l        0               ; Vector #193, 0x00000304: User Defined Vector
           dc.l        0               ; Vector #194, 0x00000308: User Defined Vector
           dc.l        0               ; Vector #195, 0x0000030C: User Defined Vector
           dc.l        0               ; Vector #196, 0x00000310: User Defined Vector
           dc.l        0               ; Vector #197, 0x00000314: User Defined Vector
           dc.l        0               ; Vector #198, 0x00000318: User Defined Vector
           dc.l        0               ; Vector #199, 0x0000031C: User Defined Vector
           dc.l        0               ; Vector #200, 0x00000320: User Defined Vector
           dc.l        0               ; Vector #201, 0x00000324: User Defined Vector
           dc.l        0               ; Vector #202, 0x00000328: User Defined Vector
           dc.l        0               ; Vector #203, 0x0000032C: User Defined Vector
           dc.l        0               ; Vector #204, 0x00000330: User Defined Vector
           dc.l        0               ; Vector #205, 0x00000334: User Defined Vector
           dc.l        0               ; Vector #206, 0x00000338: User Defined Vector
           dc.l        0               ; Vector #207, 0x0000033C: User Defined Vector
           dc.l        0               ; Vector #208, 0x00000340: User Defined Vector
           dc.l        0               ; Vector #209, 0x00000344: User Defined Vector
           dc.l        0               ; Vector #210, 0x00000348: User Defined Vector
           dc.l        0               ; Vector #211, 0x0000034C: User Defined Vector
           dc.l        0               ; Vector #212, 0x00000350: User Defined Vector
           dc.l        0               ; Vector #213, 0x00000354: User Defined Vector
           dc.l        0               ; Vector #214, 0x00000358: User Defined Vector
           dc.l        0               ; Vector #215, 0x0000035C: User Defined Vector
           dc.l        0               ; Vector #216, 0x00000360: User Defined Vector
           dc.l        0               ; Vector #217, 0x00000364: User Defined Vector
           dc.l        0               ; Vector #218, 0x00000368: User Defined Vector
           dc.l        0               ; Vector #219, 0x0000036C: User Defined Vector
           dc.l        0               ; Vector #220, 0x00000370: User Defined Vector
           dc.l        0               ; Vector #221, 0x00000374: User Defined Vector
           dc.l        0               ; Vector #222, 0x00000378: User Defined Vector
           dc.l        0               ; Vector #223, 0x0000037C: User Defined Vector
           dc.l        0               ; Vector #224, 0x00000380: User Defined Vector
           dc.l        0               ; Vector #225, 0x00000384: User Defined Vector
           dc.l        0               ; Vector #226, 0x00000388: User Defined Vector
           dc.l        0               ; Vector #227, 0x0000038C: User Defined Vector
           dc.l        0               ; Vector #228, 0x00000390: User Defined Vector
           dc.l        0               ; Vector #229, 0x00000394: User Defined Vector
           dc.l        0               ; Vector #230, 0x00000398: User Defined Vector
           dc.l        0               ; Vector #231, 0x0000039C: User Defined Vector
           dc.l        0               ; Vector #232, 0x000003A0: User Defined Vector
           dc.l        0               ; Vector #233, 0x000003A4: User Defined Vector
           dc.l        0               ; Vector #234, 0x000003A8: User Defined Vector
           dc.l        0               ; Vector #235, 0x000003AC: User Defined Vector
           dc.l        0               ; Vector #236, 0x000003B0: User Defined Vector
           dc.l        0               ; Vector #237, 0x000003B4: User Defined Vector
           dc.l        0               ; Vector #238, 0x000003B8: User Defined Vector
           dc.l        0               ; Vector #239, 0x000003BC: User Defined Vector
           dc.l        0               ; Vector #240, 0x000003C0: User Defined Vector
           dc.l        0               ; Vector #241, 0x000003C4: User Defined Vector
           dc.l        0               ; Vector #242, 0x000003C8: User Defined Vector
           dc.l        0               ; Vector #243, 0x000003CC: User Defined Vector
           dc.l        0               ; Vector #244, 0x000003D0: User Defined Vector
           dc.l        0               ; Vector #245, 0x000003D4: User Defined Vector
           dc.l        0               ; Vector #246, 0x000003D8: User Defined Vector
           dc.l        0               ; Vector #247, 0x000003DC: User Defined Vector
           dc.l        0               ; Vector #248, 0x000003E0: User Defined Vector
           dc.l        0               ; Vector #249, 0x000003E4: User Defined Vector
           dc.l        0               ; Vector #250, 0x000003E8: User Defined Vector
           dc.l        0               ; Vector #251, 0x000003EC: User Defined Vector
           dc.l        0               ; Vector #252, 0x000003F0: User Defined Vector
           dc.l        0               ; Vector #253, 0x000003F4: User Defined Vector
           dc.l        0               ; Vector #254, 0x000003F8: User Defined Vector
           dc.l        0               ; Vector #255, 0x000003FC: User Defined Vector
startup:
           lea         bss,A0
           clr.b       (A0)+           ; set bss section to zero
           cmp.l       #heap,A0
           bcs.s       *-8
           move.l      #-1,__ungetbuf  ; init ungetbuffer for keyboard input
           move.l      #(end_ROM-begin_ROM),__romsize
           move.l      #(end_RAM-begin_RAM),__ramsize
           jsr         _main

           xdef        __exit
__exit:                                ; exit() and _exit()functions
           trap        #15
           dc.w        0               ; IDE68K system call 0 -> EXIT (no return)
           bra         startup         ; when re-started after exit() call

           xdef        __putch
__putch:                               ; Basic character output routine
           move.l      4(A7),D0
           trap        #15
           dc.w        1               ; IDE68K system call 1 -> PUTCH
           rts

           xdef        __getch
__getch:                               ; Basic character input routine
           trap        #15
           dc.w        3               ; IDE68K system call 3 -> GETCH
           ext.w       D0
           ext.l       D0              ; D0.L is char, sign extended to 32 bits
           rts

           xdef        __kbhit
__kbhit:
           trap        #15
           dc.w        4               ; IDE68K system call 4 -> KBHIT
           sne         D0              ; D0.B = $FF if char in buffer, $00 if not
           rts

           xdef        __time
__time:
           trap        #15             ; IDE68K system call 40 -> GETTIME
           dc.w        40              ; D0 = seconds since Jan 1, 1970, 00:00:00 hr UTC
           rts

           xdef        __localoffset
__localoffset:
           trap        #15             ; IDE68K system call 41 -> LOCALOFFSET
           dc.w        41              ; D0 = offset in seconds between UTC and local time
           rts

           section     bss
           xdef        __ungetbuf
__ungetbuf:                            ; ungetbuffer for stdio functions
           ds.l        1
           xdef        __timezone
__timezone:                            ; difference, in seconds, between local time and UTC
           ds.l        1
           xdef        __daylight
__daylight:                            ; flag, '1' for daylight saving time, '0' for standard time.
           ds.l        1
           xdef        __romsize
__romsize:                             ; size of ROM used by program
           ds.l        1
           xdef        __ramsize
__ramsize:                             ; size of RAM used by program
           ds.l        1

           section     heap
__stack    equ         RAM+RAMsize     ; stack for main function, no longer needed after OSStart() is called
