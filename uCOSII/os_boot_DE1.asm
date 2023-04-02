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
; By           : PJ Davies to suit DE1 board
;********************************************************************************************************

;********************************************************************************************************
;                                               NOTES
;
; This is the "Board Support Package" or BSP for the DE1 board  It defines memory layout,
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
RAM        equ         $08000000       ; RAM starts at $08000000
RAMsize    equ         $00010000       ; Size of RAM 64kbytes

;           option      S0              ; Generate S0 record in .hex file since Rom is at location 0

           section     code				; all multiple code sections merged here at link time
           org         ROM				; starting at location 0, generate the following constants
begin_ROM  equ         *				; beginning of rom constant is 0
code       equ         *				; code starts at 0

           section     const			; constants placed in this section at link time
const      equ         *				; consts start whever the linker groups them, after the code section (but still in rom)

           section     data				; all program variables etc (data) are grouped together here by the linker
end_ROM    equ         *				; end of rom is wherever the last code/constant appears (* means here)

           org         RAM				; starting at address $08000000
begin_RAM  equ         *				; begin ram starts here
data       equ         *				; data starts here also

           section     bss				; this is the start of unintialised variable section. All C variables that are uninitialised get grouped together here and are set to zero at start of program
bss        equ         *

           section     heap
end_RAM    equ         *				; wherever the program variables end, is the start of the heap
heap       equ         *

           section     code				; going back to code section (still at location 0) reserve 256 x 4 byte vector table entries for the 68k (SEE TABLE PAGE 32/LECTURE 17)

;*******************************************************************************************************************
; start of 68000 vector table (256 long word entries covering reset, interrupts, initial stack pointer etc)
;*******************************************************************************************************************

InitialSP       dc.l __stack          ;initial supervisor state stack pointer(stack decrements first before being used
InitialPC       dc.l startup             ;address of 1st instruction of program after a reset
BusError        dc.l E_BErro           ;bus error - stop program
AddressError    dc.l E_AErro           ;address error - stop program
IllegalInstr    dc.l E_IInst           ;illegal instruction - stop program
DividebyZero    dc.l E_DZero           ;divide by zero error - stop program
Check           dc.l E_Check           ;Check instruction - stop program
TrapV           dc.l E_Trapv           ;Trapv instruction - stop program
Privilege       dc.l E_Priv            ;privilige violation - stop program
Trace           dc.l E_Trace           ;stop on trace
Line1010emul    dc.l E_1010            ;1010 instructions stop
Line1111emul    dc.l E_1111            ;1111 instructions stop
Unassigned1     dc.l E_Unnas1           ;unassigned vector
Unassigned2     dc.l E_Unnas2           ;unassigned vector
Unassigned3     dc.l E_Unnas3           ;unassigned vector
Uninit_IRQ      dc.l E_UnitI           ;uninitialised interrupt
Unassigned4     dc.l E_Unnas4           ;unassigned vector
Unassigned5     dc.l E_Unnas5           ;unassigned vector
Unassigned6     dc.l E_Unnas6           ;unassigned vector
Unassigned7     dc.l E_Unnas7           ;unassigned vector
Unassigned8     dc.l E_Unnas8           ;unassigned vector
Unassigned9     dc.l E_Unnas9           ;unassigned vector
Unassigned10    dc.l E_Unnas10           ;unassigned vector
Unassigned11    dc.l E_Unnas11           ;unassigned vector
SpuriousIRQ     dc.l E_Spuri           ;stop on spurious irq
*
*
Level1IRQ       dc.l Level1RamISR
Level2IRQ       dc.l Level2RamISR
Level3IRQ       dc.l _OSTickISR        ;Level3RamISR (Timer Tick) - ISR needs to be installed at run time for DE1 timer
Level4IRQ       dc.l Level4RamISR
Level5IRQ       dc.l Level5RamISR
Level6IRQ       dc.l Level6RamISR
Level7IRQ       dc.l Level7RamISR
*
*
Trap0           dc.l _OSCtxSw           ; User installed trap handler (Context Switch) - invoked by a trap0 instruction contained in os_cpu.h file
Trap1           dc.l Trap1RamISR        ; User installed trap handler
Trap2           dc.l Trap2RamISR        ; User installed trap handler
Trap3           dc.l Trap3RamISR        ; User installed trap handler
Trap4           dc.l Trap4RamISR        ; User installed trap handler
Trap5           dc.l Trap5RamISR        ; User installed trap handler
Trap6           dc.l Trap6RamISR        ; User installed trap handler
Trap7           dc.l Trap7RamISR        ; User installed trap handler
Trap8           dc.l Trap8RamISR        ; User installed trap handler
Trap9           dc.l Trap9RamISR        ; User installed trap handler
Trap10          dc.l Trap10RamISR       ; User installed trap handler
Trap11          dc.l Trap11RamISR       ; User installed trap handler
Trap12          dc.l Trap12RamISR       ; User installed trap handler
Trap13          dc.l Trap13RamISR       ; User installed trap handler
Trap14          dc.l Trap14RamISR       ; User installed trap handler
Trap15          dc.l Trap15RamISR       ; User installed trap handler (System call - but a legacy from running on IDE68k simulator)


*
* Other vectors 64-255 are users vectors for autovectored IO device (not implemented in TG68)
*

                org       $00000400    ; end of vector table/start of code

           ; this is where the program code initially begins (see table avove vector #1 - initial Program counter value is defined as "startup"
           ; here we can write some boot code and carry out some memory/constant initialisation
           ; add your own code here or you can do it later in C (try to keep assembler code to a minimum)
startup:
           lea         bss,A0			; put start address of unitialised variables into register A0
           clr.b       (A0)+           ; set bss section (unitialised variables) to zero (clear the byte pointed to by A0 and then increment A0)
           cmp.l       #heap,A0			; compare A0 with immediate value defined by heap
           bcs.s       *-8				; if not there yet go back 8 bytes to clr.b instruction
           move.l      #-1,__ungetbuf  ; initialose ungetbuffer for keyboard input (don't remove this otherwise scanf() etc will not work)
           ;
           move.l      #(end_ROM-begin_ROM),__romsize	; initialise some values related to rom and ram limits (needed by OS)
           move.l      #(end_RAM-begin_RAM),__ramsize
           jsr         _main							; now call main() from our C program (yeah!!!!)

*********************************************************************************************************
* Code to call Ram Based Interrupt handler and other exeception handler code
*********************************************************************************************************
Level1RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VL1IRQ,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the interrupt handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
Level2RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VL2IRQ,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the interrupt handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
Level3RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VL3IRQ,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the interrupt handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
Level4RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VL4IRQ,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the interrupt handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Level5RamISR    movem.l   d0-d7/a0-a6,-(SP)        save everything not automatically saved
                move.l    VL5IRQ,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the interrupt handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Level6RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VL6IRQ,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the interrupt handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Level7RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VL7IRQ,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the interrupt handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte


********************************************************************************************************
* Ram based Trap handler and other exeception handler code
*********************************************************************************************************

Trap0RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap0,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap1RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap1,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap2RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap2,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap3RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap3,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap4RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap4,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap5RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap5,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap6RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap6,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap7RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap7,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap8RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap8,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap9RamISR     movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap9,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap10RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap10,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap11RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap11,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap12RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap12,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap13RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap13,a0                get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap14RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap14,a0              get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

Trap15RamISR    movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrap15,a0              get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

*********************************************************************************************************
*Default exception handler for everything without a specific handler
*********************************************************************************************************

E_BErro         movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VBusError,a0            get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
E_AErro         movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VAddressError,a0        get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
E_IInst         movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VIllegalInstr,a0        get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
E_DZero         movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VDividebyZero,a0        get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
E_Check         movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VCheck,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
E_Trapv         movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrapV,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
E_Priv          movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VPrivilege,a0           get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
E_Trace         movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VTrace,a0               get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
E_1010          movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VLine1010emul,a0        get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte
E_1111          movem.l   d0-d7/a0-a6,-(SP)       save everything not automatically saved
                move.l    VLine1111emul,a0        get ram based address into a0
                jsr       0(a0)                   jump to the subroutine that is the trap handler, using ram based address
                movem.l   (SP)+,d0-d7/a0-a6       pull eveything off the stack
                rte

; at the moment all these exceptions cause the processor to stop (or at least loop) with no further application processing
E_Unnas1
E_Unnas2
E_Unnas3
E_UnitI
E_Unnas4
E_Unnas5
E_Unnas6
E_Unnas7
E_Unnas8
E_Unnas9
E_Unnas10
E_Unnas11
E_Spuri
_stop            bra _stop             ; stop

           xdef        __exit
__exit:                                ; exit() and _exit()functions

           bra         startup         ; restart program if exit() called

; I don't think these two time related functions are relevant anymore and neither is Trap 15 handler
; but they are left in for the moment until I am certain they can be removed
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
;           org         $0B000000               Ram based vector table must be stored here otherwise InstallException Handler will not work

*********************************************************************************************************
* Build a ram based vector table for interrupts so we can install our own Exception Handlers in C code at run time
* install the exception handler using the C function InstallExceptionHandler()
*********************************************************************************************************

VInitialSP       ds.l    1      dummy as we can't really install a handler for this
VInitialPC       ds.l    1      dummy as we can't reallin install a handler for this
VBusError        ds.l    1      storage for address of Bus Error Handler
VAddressError    ds.l    1      storage for address of Address Error Handler
VIllegalInstr    ds.l    1      storage for address of Illegal Instruction handler
VDividebyZero    ds.l    1      storage for address of divide by zero handler
VCheck           ds.l    1      ditto
VTrapV           ds.l    1      ditto
VPrivilege       ds.l    1      ditto
VTrace           ds.l    1
VLine1010emul    ds.l    1
VLine1111emul    ds.l    1
VUnassigned1     ds.l    1
VUnassigned2     ds.l    1
VUnassigned3     ds.l    1
VUninit_IRQ      ds.l    1
VUnassigned4     ds.l    1
VUnassigned5     ds.l    1
VUnassigned6     ds.l    1
VUnassigned7     ds.l    1
VUnassigned8     ds.l    1
VUnassigned9     ds.l    1
VUnassigned10    ds.l    1
VUnassigned11    ds.l    1
VSpuriousIRQ     ds.l    1

* Interrupt handlers Vector 25-31
VL1IRQ           ds.l    1       storage for 4 byte address of IRQ handler in your C program - install the handler using the C function InstallExceptionHandler()
VL2IRQ           ds.l    1       storage for 4 byte address of IRQ handler in your C program - install the handler using the C function InstallExceptionHandler()
VL3IRQ           ds.l    1       storage for 4 byte address of IRQ handler in your C program - install the handler using the C function InstallExceptionHandler()
VL4IRQ           ds.l    1       storage for 4 byte address of IRQ handler in your C program - install the handler using the C function InstallExceptionHandler()
VL5IRQ           ds.l    1       storage for 4 byte address of IRQ handler in your C program - install the handler using the C function InstallExceptionHandler()
VL6IRQ           ds.l    1       storage for 4 byte address of IRQ handler in your C program - install the handler using the C function InstallExceptionHandler()
VL7IRQ           ds.l    1       storage for 4 byte address of IRQ handler in your C program - install the handler using the C function InstallExceptionHandler()

* Trap Handler vectors 32-47
VTrap0           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap1           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap2           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap3           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap4           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap5           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap6           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap7           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap8           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap9           ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap10          ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap11          ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap12          ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap13          ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap14          ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()
VTrap15          ds.l   1        storage for 4 byte address of TRAP handler in your C program - install the handler using the C function InstallExceptionHandler()

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

           section     heap				; stack at top of heap
__stack    equ         RAM+RAMsize     ; stack for main function, no longer needed after OSStart() is called