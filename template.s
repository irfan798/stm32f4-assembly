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
@.equ     SEC_CONSTANS,    5200 @ 1 ms
.equ     SEC_CONSTANS,    900 @ 0.25 ms
.equ     MORSE_HOLDER,   0x0000001F  @0000 0000 0000 0000 0000 0000 0001 1111 
.equ	 START_FROM,	 1000000

.equ	COUNTEREND, 	20

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


@ GPIOA base address is 4002 0000
@   Input register offset is 0x10
.equ     GPIOA_INPUT,   0x40020010      @ 


@ GPIOC base address is 4002 0800
@   Input register offset is 0x10
.equ     GPIOC_INPUT,   0x40020810      @
@ Pull up/Pull Down offset 0x0C 
.equ     GPIOC_PUPDR,   0x4002080C      @ 



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
	@orr r5, #0x00000001                 @ Set bit 1 to enable GPIOA clock
	@orr r5, #0x00000002                 @ Set bit 2 to enable GPIOB clock
	@orr r5, #0x00000004                 @ Set bit 3 to enable GPIOC clock
	orr r5, #0x00000007                 @ Set bit 3 to enable GPIOC clock	
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


_main:
	ldr r11, =0 @ Our counter, counts from 0 to 20
	bl close_led
	bl show_group_number @Show our number

loop:
	
	@ READ BUTTON
	@ GPIOC INPUT IDR
	@ldr r6, = GPIOA_INPUT              @ Load GPIOA INPUT register address to r6
	ldr r6, = GPIOC_INPUT               @ Load GPIOC INPUT register address to r6
	ldr r5, [r6]                        @ Read its content to r5
	movs r6, 0x00002000                 @ PC13
	and r5, r6
	cmp r5, r6							@ Test if PC13 is 1
	bne loop							@ Loop until button is clicked

	@ When clicked
	adds r11, #1 @ Add one to counter

	@mov r1, r11 	@Write counter
	mov r4, r11 	@Write to parameter of fibonacci
	bl fibonacci
	mov r8, r1 @ Write fibonacci to digit parameter
	
	bl digits

	@ lastly control counter
	cmp r11, #COUNTEREND @ If counter equals to 20 reset back
	beq _main @ if counter equals go back to main 

	nop                                 @ No operation. Do nothing.
	b loop @ Jump to loop

open_led:
	@ Set GPIOB Pin7 to 1 (bit 7 in ODR register)
	ldr r6, = GPIOB_ODR                 @ Load GPIOD output data register
	ldr r5, [r6]                        @ Read its content to r5
	orr r5, 0x0080                      @ write 1 to pin 7
	orr r5, 0x4000                      @ write 1 to pin 14
	orr r5, 0x0001                      @ write 1 to pin 0
	str r5, [r6]                        @ Store back the result in GPIOD output data register
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

show_group_number:
	@ Set GPIOB Pin7 to 1 (bit 7 in ODR register)
	ldr r6, = GPIOB_ODR                 @ Load GPIOD output data register
	ldr r5, [r6]                        @ Read its content to r5
	orr r5, 0x0080                      @ write 0 to pin 7
	orr r5, 0x4000                      @ write 1 to pin 14
	bic r5, 0x0001                      @ write 1 to pin 0
	str r5, [r6]                        @ Store back the result in GPIOD output data register
	bx lr								@ Jump back to link register


delay:
	@ r0 is our parameter as miliseconds
	@ 32.768Khz 0x01F40000 
	ldr r1,=SEC_CONSTANS		@ loop+delay makes 6 operations? divide to 6 
	@ldr r1,=2600		@ loop+delay makes 6 operations? divide to 6 
	muls r0, r1			@ Multiplier MAX 825 seconds
loop_delay:
	subs r0, #1		@ In each loop decrement
	bne loop_delay	@ until r0 == 0
	bx lr								@ Jump back to link register


morse:
	@r1 is parameter
	push {lr} @ First save our link register so we can use it later
	@ 1 means dot 0 means dash
	@ r1 is our parameter
	ldr r2, =MORSE_HOLDER @ load morse holder
	ror r2, r2, r1 @ Rotate r2 by r1 and save to r2
	
	ldr r3, =0x00000001  @1000 0000 0000 0000 0000 0000 0000 0000
	ldr r4, =5 @ We have 5 signals on morse numbers

_show:
	ror r3, r3, #1 @ Right shift by one
	ands r5, r2, r3  @ Get first digit then write to r5
	cmp r3,	r5 @ Compare digit if its dash or dot

	IT EQ @ Condtion on equal
	ldreq r0, =1000 @ If digit is one (dot) set timer to 1000ms
	
	IT NE @Condition on not equal
	ldrne r0, =3000 @ If digit is zero (dash) set timer to 3000ms

	IT AL @ Not conditional
	bl open_led
	bl delay
	bl close_led

	ldr r0, =1000 @ 1000ms delay 
	bl delay

	subs r4, #1 @ Decrement counter
	bne _show	@ until r4 == 0

	@ Delay between digits
	ldr r0, =3000 @ 1000ms delay 
	bl delay

	pop {lr} @ Take our lx back
	bx lr @ Jump back where we were


fibonacci:
		@r4 is parameter
		mov r5, #0
		mov r2, #1
		f_first:
			@subs r4, r4, #1
		f_compute:
			add r3, r5, r2
			mov r5, r2
			mov r2, r3
			subs r4, r4, #1
			beq f_end
			bal f_compute
		f_end:
			@ Writes result to r1 morses parameter
			mov r1, r3
			bx lr

digits:
	@ R8 is number parameter 4508
	@ R9 10 000

	push {lr} @ First save our link register so we can use it later
	ldr r7, =10 @ For every loop divide ten for next digit
	ldr r9, =START_FROM

_digit_equ:
	cmp r8, r9 @ Compare number and Division factor exp. 2006?1000
	bge _write_digit @ If number greater than division factor generate morse 
	udiv r9, r7 @ for next digit divided, division factor. 1000/10

	b _digit_equ

_get_next_digit:
	udiv r9, r7 @ for next digit divided, division factor. 1000/10

_write_digit:
	mov r4, r8 @ Save origin number to temp
	udiv r8, r9 @ Divide to division factor

	mov r1, r8 @ Write digit to parameter

	push {r4, r7, r8, r9} @ Save our intermediate values
	bl morse
	pop {r4, r7, r8, r9} @ Load our intermediate values

	mul r8, r9 @ Multiply division factor with digit to get last digit
	subs r8, r4, r8 @ Substract from original number

	cmp r9, 1 @ Control division factor if ended
	bne _get_next_digit @ Bigger then

	pop {lr} @ Take our lx back
	bx lr @ Jump back where we were
