@ STM32F4 Discovery - Assembly template
@ Turns on an LED attached to GPIOD Pin 12
@ We need to enable the clock for GPIOD and set up pin 12 as output.

@ Start with enabling thumb 32 mode since Cortex-M4 do not work with arm mode
@ Unified syntax is used to enable good of the both words...

@ Make sure to run arm-none-eabi-objdump.exe -d prj1.elf to check if
@ the assembler used proper instructions. (Like ADDS)

.thumb
.syntax unified
.cpu cortex-m4
@.arch armv7e-m

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Definitions
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Definitions section. Define all the registers and
@ constants here for code readability.

@ Constants
.equ     LEDDELAY,      100000

@ Register Addresses
@ You can find the base addresses for all the peripherals from Memory Map section
@ RM0090 on page 64. Then the offsets can be found on their relevant sections.

@ RCC   base address is 0x40023800
@   AHB1ENR register offset is 0x30
.equ     RCC_AHB1ENR,   0x40023830      @ RCC AHB1 peripheral clock register (page 180)

@Button PC13 or PA0

@0x4002 0400 - 0x4002 07FF GPIOB


@ GPIOB base address is 0x40020400
@   MODER register offset is 0x00
@   ODR   register offset is 0x14
.equ     GPIOB_MODER,   0x40020400      @ GPIOB port mode register (page 281)
.equ     GPIOB_ODR,     0x40020414      @ GPIOB port output data register (page 283)

@ Start of text section
.section .text
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Vectors
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Vector table start
@ Add all other processor specific exceptions/interrupts in order here
	.long    __StackTop                 @ Top of the stack. from linker script
	.long    _start +1                  @ reset location, +1 for thumb mode

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Main code starts from here
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

_start:
	@ Enable GPIOB and GPIOC Peripheral Clock (bit 1 2 and 3 in AHB1ENR register)
	ldr r6, = RCC_AHB1ENR               @ Load peripheral clock register address to r6
	ldr r5, [r6]                        @ Read its content to r5
	orr r5, #0x00000001                 @ Set bit 1 to enable GPIOA clock
	orr r5, #0x00000002                 @ Set bit 2 to enable GPIOB clock
	orr r5, #0x00000004                 @ Set bit 3 to enable GPIOC clock
	str r5, [r6]                        @ Store back the result in peripheral clock register

	@ Make GPIOB Pin7 as output pin (bits 15:14 in MODER register)
	ldr r6, = GPIOB_MODER               @ Load GPIOD MODER register address to r6
	ldr r5, [r6]                        @ Read its content to r5
	@and r5, 0xFFFF3FFF                  @ Clear bits 14, 15 for P7
	@orr r5, 0x00004000                  @ Write 01 to bits 14, 15 for P7
	and r5, 0xFFFF3FFF                  @ Clear bits 14, 15 for P7 and 0,1 for P0
	and r5, 0xCFFFFFFF                  @ Clear bits 14, 15 for P7 and 0,1 for P0
	and r5, 0xFFFFFFFC                  @ Clear bits 14, 15 for P7 and 0,1 for P0
	orr r5, 0x00004000                  @ Write 01 to bits 14, 15 for P7 and 0,1 for P0
	orr r5, 0x10000000                  @ Write 01 to bits 14, 15 for P7 and 0,1 for P0
	orr r5, 0x00000001                  @ Write 01 to bits 14, 15 for P7 and 0,1 for P0
	str r5, [r6]                        @ Store back the result in GPIOD MODER register


	@ GPIOC mod

	bl open_led
	ldr r0, =3 	@3 secs delay
	bl delay
	bl close_led
	bl delay
	bl open_led
	ldr r0, =1 	@3 secs delay
	bl delay
	bl close_led

loop:
	nop                                 @ No operation. Do nothing.
	b loop                              @ Jump to loop



open_led:
	@ Set GPIOB Pin7 to 1 (bit 7 in ODR register)
	ldr r6, = GPIOB_ODR                 @ Load GPIOD output data register
	ldr r5, [r6]                        @ Read its content to r5
	orr r5, 0x0080                      @ write 1 to pin 7
	orr r5, 0x4000                      @ write 1 to pin 14
	orr r5, 0x0001                      @ write 1 to pin 0
	str r5, [r6]                        @ Store back the result in GPIOD output data register
	bx lr								@ Jump back to link register


delay:
	@ 32.768Khz 0x01F40000 
	ldr r1,=5200000		@ loop+delay makes 6 operations? divide to 6 
	muls r0, r1			@ Multiplier MAX 825 seconds
loop_delay:
	subs r0, #1		@ In each loop decrement
	bne loop_delay	@ until r0 == 0
	bx lr								@ Jump back to link register


close_led:
	@ Set GPIOB Pin7 to 01 (bit 7 in ODR register)
	ldr r6, = GPIOB_ODR                 @ Load GPIOD output data register
	ldr r5, [r6]                        @ Read its content to r5
	@and r5, 0x0000
	bic r5, 0x0080                      @ write 0 to pin 7
	bic r5, 0x4000                      @ write 0 to pin 14
	bic r5, 0x0001                      @ write 0 to pin 0
	str r5, [r6]                        @ Store back the result in GPIOD output data register
	ldr r0, = 3
	bx lr								@ Jump back to link register
