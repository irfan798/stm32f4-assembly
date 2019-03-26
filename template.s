@ STM32F4 Discovery - Assembly template
@ Turns on an LED attached to GPIOD Pin 12
@ We need to enable the clock for GPIOD and set up pin 12 as output.

@ Start with enabling thumb 32 mode since Cortex-M4 do not work with arm mode
@ Unified syntax is used to enable good of the both words...

@ Make sure to run arm-none-eabi-objdump.exe -d prj1.elf to check if
@ the assembler used proper instructions. (Like ADDS)

.thumb
.syntax unified
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

@ GPIOD base address is 0x40020C00
@   MODER register offset is 0x00
@   ODR   register offset is 0x14
.equ     GPIOD_MODER,   0x40020C00      @ GPIOD port mode register (page 281)
.equ     GPIOD_ODR,     0x40020C14      @ GPIOD port output data register (page 283)

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
	@ Enable GPIOD Peripheral Clock (bit 3 in AHB1ENR register)
	ldr r6, = RCC_AHB1ENR               @ Load peripheral clock register address to r6
	ldr r5, [r6]                        @ Read its content to r5
	orr r5, 0x00000008                  @ Set bit 3 to enable GPIOD clock
	str r5, [r6]                        @ Store back the result in peripheral clock register

	@ Make GPIOD Pin12 as output pin (bits 25:24 in MODER register)
	ldr r6, = GPIOD_MODER               @ Load GPIOD MODER register address to r6
	ldr r5, [r6]                        @ Read its content to r5
	and r5, 0xFCFFFFFF                  @ Clear bits 24, 25 for P12
	orr r5, 0x01000000                  @ Write 01 to bits 24, 25 for P12
	str r5, [r6]                        @ Store back the result in GPIOD MODER register

	mov r8, 2 @ test
	mov r9, 10 @tewset
	udiv r1, r8, r9 @ stst
		
	mov r8, 2006
	mov r9, 1000
	b digits

	ldr r4, = 12
	bl fibonacci
	bl open_led
	ldr r0, =3 	@3 secs delay
	bl delay
	bl close_led
	bl delay
	bl open_led
	ldr r0, =1 	@3 secs delay
	bl delay
	bl close_led


digits:
	@ R8 is number parameter 4508
	@ R9 10 000

	ldr r7, =10 @ For every loop divide ten for next digit	
	cmp r8, r9 @ Compare number and Division factor exp. 2006?1000
	bge _write_digit @ If number greater than division factor generate morse 
	udiv r9, r7 @ for next digit divided, division factor. 1000/10

	b digits

_get_next_digit:
	udiv r9, r7 @ for next digit divided, division factor. 1000/10

_write_digit:
	mov r4, r8 @ Save origin number to temp
	udiv r8, r9 @ Divide to division factor

	mov r1, r8 @ Write digit to parameter
	@bl _run_morse

	mul r5, r8, r9 @ Multiply division factor with digit to get last digit
	subs r8, r4, r5 @ Substract from original number

	cmp r9, 1 @ Control division factor if ended
	bne _get_next_digit @ Bigger then

	@Finish


fibonacci:
		mov r1, #0
		mov r2, #1
		f_first:
			subs r4, r4, #1
		f_compute:
			add r3, r1, r2
			mov r1, r2
			mov r2, r3
			subs r4, r4, #1
			beq f_end
			bal f_compute
		f_end:
			mov r9, r3
			bx lr

open_led:
	@ Set GPIOB Pin7 to 1 (bit 7 in ODR register)
	ldr r6, = GPIOD_ODR                 @ Load GPIOD output data register
	ldr r5, [r6]                        @ Read its content to r5
	orr r5, 0x1000                      @ write 1 to pin 12
	str r5, [r6]                        @ Store back the result in GPIOD output data register
	bx lr @ Jump back to link registern


close_led:
	@ Set GPIOB Pin7 to 1 (bit 7 in ODR register)
	ldr r6, = GPIOD_ODR                 @ Load GPIOD output data register
	ldr r5, [r6]                        @ Read its content to r5
	@and r5, 0x0000
	bic r5, 0x1000                     @ write 0 to pin 7
	str r5, [r6]                        @ Store back the result in GPIOD output data register
	ldr r0, = 3
	bx lr @ Jump back to link register

delay:
	@ 32.768Khz 0x01F40000 
	ldr r1,=5200000		@ loop+delay makes 6 operations? divide to 6 
	muls r0, r1			@ Multiplier MAX 825 seconds

loop_delay:
	subs r0, #1		@ In each loop decrement
	bne loop_delay	@ until r0 == 0
	bx lr @ Jump back to link register


loop:
	nop                                 @ No operation. Do nothing.
	b loop                              @ Jump to loop
