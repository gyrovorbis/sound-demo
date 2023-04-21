                                    
        ;; SoundDemo.s
        ;;
        ;; version 1.0
        ;;
        ;; by <Butze@Rockin-B.de>
        ;; ! misc.i: ocr,  modified, trl, trh for bmp2asm compatibility modified!



timer1lr        equ     $4
timer1lc        equ     $5
count           equ     $6

helpscreens     equ     8


        ;; bits in keys
pressed_sleep   equ     7       ; same like port 3, if 0: button pressed
pressed_mode    equ     6
pressed_b       equ     5
pressed_a       equ     4
pressed_right   equ     3
pressed_left    equ     2
pressed_down    equ     1
pressed_up      equ     0




        ;; parts borrowed from tiny tetris by Marcus Comstedt

	.include "sfr.i"



	;; Reset and interrupt vectors
	
	.org	0

	jmpf	start

	.org	$3

	jmp	nop_irq

	.org	$b

	jmp	nop_irq
	
        .org	$13

        jmp     nop_irq

	.org	$1b

	jmp	t1int
	
	.org	$23

	jmp	nop_irq

	.org	$2b

	jmp	nop_irq
	
	.org	$33

	jmp	nop_irq

	.org	$3b

	jmp	nop_irq

	.org	$43

	jmp	nop_irq

	.org	$4b

	clr1	p3int,0
	clr1	p3int,1
nop_irq:
	reti



        ;; some firmware calls that can be found
        ;; in various homebrew games in this form

        .org $100
writeflash:
        not1 ext, 0
        jmpf writeflash
        ret

        .org $110
verifyflash:
        not1 ext, 0
        jmpf verifyflash
        ret

        .org $120
readflash:
        not1 ext, 0
        jmpf readflash
        ret




	.org	$130
	
t1int:
	push	ie
	clr1	ie,7
	not1	ext,0
	jmpf	t1int
	pop	ie
	reti

		
	.org	$1f0

goodbye:	
	not1	ext,0
	jmpf	goodbye


	;; Header
	
	.org	$200

        .byte   "Sound Demo      "      ; 16 letters
        .byte   "Created by Butze@Rockin-B.de    "      ; 32 letters

	;; Icon header
	
	.org	$240

        .word   3,10            ; Three frames

        ;; Icon palette

	.org	$260

	.word	$F000,$F800,$F080,$F880,$F008,$F808,$F088,$FCCC
	.word	$F888,$FF00,$F0F0,$FFF0,$F00F,$FF0F,$F0FF,$FFFF

        ;; The "Rockin-B" icon for VMU file browser on Dreamcast 

	.org	$280

        include"icon.i"
	
        ;; Your main program starts here.

	.org	$680

start:
        clr1 ie,7               ; block nonmasked interrupts
        mov #$a1,ocr            ; clock divisor 6, subclock mode(32kHz), main clock stopped
        mov #$09,mcr            ; refresh rate 166Hz, Graphic mode on
        mov #$80,vccr           ; lcd enabled
	clr1 p3int,0
	clr1 p1,7
        mov #$ff,p3             ; initialise keys

        set1 ie,7               ; enable all interrupts

        call clrscr             ; clear screen


;; now here the demo

SoundDemo:
        ;; set SUB clock 32768/6 = 5461 Hz
        clr1 ocr, mainclk       ; disable MAIN clock
        set1 ocr, mainctl       ; stop MAIN clock
        set1 ocr, halfclk       ; set frequency divisor to 6
        set1 ocr, subclk        ; enable SUB clock
        set1 ocr, rcctl         ; stop RC oscillator

        ;; init variables for sound control

        mov #0, acc
        st timer1lr
        st t1lr

        mov #127, acc
        st timer1lc
        st t1lc


        ;; set timer 1 control, enable timer 1 low compare to allow sound output

        mov #%00010000, t1cnt



main:
        call getkeys
        bne #$FF, main

        mov #<title, trl
        mov #>title, trh

        call setscr

.waitkey:
        call getkeys
        be #$FF, .waitkey



menu:
        call getkeys
        bne #$FF, menu

        mov #<select, trl
        mov #>select, trh

        call setscr

.waitkey:
        call getkeys
        be #$FF, .waitkey

        bn acc, pressed_a, timer1low
        bn acc, pressed_b, help
        br .waitkey



help:
        call getkeys
        bne #$FF, help

        mov #<help1, trl
        mov #>help1, trh

        mov #0, count

.next:
        call getkeys
        bne #$FF, .next

        call setscr

.waitkey:
        call getkeys
        be #$FF, .waitkey

        ;; check if it was the last screen

        inc count
        ld count
        be #helpscreens, .end 

        ;; update flashrom pointers

        ld trl
        add #192
        st trl
        bn psw, cy, .no_ovf
        inc trh

.no_ovf:
        br .next

.end
        brf main



timer1low:
        callf getkeys
        bne #$FF, timer1low

        ;; initially set the picture

        mov #<set_t1l, trl
        mov #>set_t1l, trh

        call setscr

.loop:

        ;; update display

        mov #1, xbnk
        mov #$81, 2
        ld timer1lr
        st @R2

        mov #$84, 2
        ld timer1lc
        st @R2

        ;; check keys

.waitkeys:
        call getkeys
        be #$FF, .waitkeys
        st c

        bp c, pressed_a, .skip_a
        brf cpufreq

.skip_a:
        bp c, pressed_left, .skip_left
        dec timer1lr

        br .timer1lradj

.skip_left:
        bp c, pressed_right, .skip_right
        inc timer1lr        

.timer1lradj:
        ld timer1lr
        st t1lr

        ;; adjust duty to 50%

        mov #$FF, acc
        sub timer1lr
        clr1 acc, 0
        ror
        add timer1lr        
        st timer1lc
        st t1lc

        ;; wait untill next half second

        clr1 psw, rambk0

        ld $1E
.wait1:
        be $1E, .wait1

        set1 psw, rambk0

.skip_right:
        bp c, pressed_up, .skip_up
        inc timer1lc

        br .timer1lcadj

.skip_up:
        bp c, pressed_down, .skip_down
        dec timer1lc        

.timer1lcadj:
        ld timer1lc
        st t1lc

        ;; wait untill next half second

        clr1 psw, rambk0

        ld $1E
.wait2:
        be $1E, .wait2

        set1 psw, rambk0

.skip_down:

        bp c, pressed_b , .skip_b
        not1 t1cnt, t1lrun

.waitrelease:
        callf getkeys
        bne #$FF, .waitrelease

.skip_b:

        br .loop




cpufreq:
        callf getkeys
        bne #$FF, cpufreq

        ;; initially set the picture

        mov #<set_freq, trl
        mov #>set_freq, trh

        call setscr

.loop:
        callf getkeys
        bne #$FF, .loop

        ;; check keys

.waitkeys:
        call getkeys
        be #$FF, .waitkeys
        st c

        bp c, pressed_a, .skip_a
        brf main

.skip_a:

        bp c, pressed_left, .skip_left
        ;; set SUB clock 32768/6 = 5461 Hz
        clr1 ocr, mainclk       ; disable MAIN clock
        set1 ocr, mainctl       ; stop MAIN clock
        set1 ocr, halfclk       ; set frequency divisor to 6
        set1 ocr, subclk        ; enable SUB clock
        set1 ocr, rcctl         ; stop RC oscillator

.skip_left:
        bp c, pressed_right, .skip_right
        ;; activate RC clock 600/6 = 100 kHz
        clr1 ocr, mainclk       ; disable MAIN clock
        set1 ocr, mainctl       ; stop MAIN clock
        set1 ocr, halfclk       ; set frequency divisor to 6
        clr1 ocr, rcctl         ; start RC oscillator
        clr1 ocr, subclk        ; enable RC clock

.skip_right:
        bp c, pressed_up, .skip_up
        ;; activate RC clock 600/12 = 50 kHz
        clr1 ocr, mainclk       ; disable MAIN clock
        set1 ocr, mainctl       ; stop MAIN clock
        clr1 ocr, halfclk       ; set frequency divisor to 12
        clr1 ocr, rcctl         ; start RC oscillator
        clr1 ocr, subclk        ; enable RC clock

.skip_up:
        bp c, pressed_down, .skip_down
        ;; set SUB clock 32768/12 = 2730 Hz
        clr1 ocr, mainclk       ; disable MAIN clock
        set1 ocr, mainctl       ; stop MAIN clock
        clr1 ocr, halfclk       ; set frequency divisor to 12
        set1 ocr, subclk        ; enable SUB clock
        set1 ocr, rcctl         ; stop RC oscillator

.skip_down:

        br .loop





        ;; some needful functions

        include"misc.i"

        ;; some screen images

        include "title.i"
        include "select.i"
        include "help1.i"
        include "help2.i"
        include "help3.i"
        include "help4.i"
        include "help5.i"
        include "help6.i"
        include "help7.i"
        include "help8.i"
        include "set_T1L.i"
        include "set_FREQ.i"

	.cnop	0,$200		; pad to an even number of blocks
