stm8/

	#include "mapping.inc"
    #include "stm8s103f.inc"
	
	
pointerX MACRO first
	ldw X,first
	MEND
pointerY MACRO first
	ldw Y,first
	MEND
matrix_Cwrite MACRO first
    ld a,#{low first}
	ld data,a
    ld a,#{high first}
	ld address,a
	call matrix_Cwrite1
	MEND
	
millis MACRO first
	pushw Y
	ldw Y,first
	call delayYx1mS
	popw Y
	MEND
	
micros MACRO first
	pushw Y
	ldw Y,first
	call usdelay
	popw Y
	MEND
	
	
	
	
	
	
	
		  segment byte at 100 'ram1'
buffer1  		ds.b
buffer2  		ds.b
buffer3  		ds.b
nibble1  		ds.b
temp	 		ds.b
temp1           ds.b
temp2           ds.b
temp3           ds.b
temp4           ds.b
temp5           ds.b
temp6           ds.b
temp7           ds.b
temp8           ds.b
pad1     		ds.b
SLAVE_REG 		ds.b  
address  		ds.b
data 	 		ds.b
array_start 	ds.b
ASCII 			ds.b
address_counter ds.b
seven 			ds.b
count			ds.b
array_label 	ds.b
read_data_len 	ds.b
HOUR1stdigit  	ds.b
HOUR2nddigit  	ds.b
COLON1	      	ds.b
MINUTES1stdigit ds.b
MINUTES2nddigit ds.b
COLON2        	ds.b
SECOND1stdigit 	ds.b 
SECOND2nddigit 	ds.b
BLANK			ds.b
DATE1stdigit   	ds.b
DATE2nddigit  	ds.b
SLASH1     		ds.b
MONTH1stdigit   ds.b
MONTH2nddigit 	ds.b
SLASH2			ds.b
YEAR1stdigit  	ds.b
YEAR2nddigit  	ds.b
SLASH3  		ds.b
DAY1  			ds.b
DAY2  			ds.b
DAY3  			ds.b
DAY4  			ds.b
DAY5  			ds.b
DAY6  			ds.b
DAY7  			ds.b
DAY8  			ds.b
DAY9			ds.b
PERIOD  		ds.b
hourbcd  		ds.b
minbcd  		ds.b
datebcd  		ds.b
monbcd  		ds.b
yearbcd  		ds.b
weekbcd  		ds.b
alarm2_2 		ds.b
alarm2_3 		ds.b
alarm2_4 		ds.b
alarm_ctrl 		ds.b
buf7 			ds.b 8				;reserves 8 bytes in ram,USED AS BUFFER TO READ DS3231 TIME DATA
data_length 	ds.b
smachine 		ds.b
Temp2 			ds.w
screen1			ds.b 8
screen2			ds.b 8
screen3			ds.b 8
screen4			ds.b 8
screen5			ds.b 8
screen6			ds.b 8
screen7         ds.b 8
screen8			ds.b 8






	segment 'rom'
main.l
	; initialize SP
	ldw X,#stack_end
	ldw SP,X

	#ifdef RAM0	
	; clear RAM0
ram0_start.b EQU $ram0_segment_start
ram0_end.b EQU $ram0_segment_end
	ldw X,#ram0_start
clear_ram0.l
	clr (X)
	incw X
	cpw X,#ram0_end	
	jrule clear_ram0
	#endif

	#ifdef RAM1
	; clear RAM1
ram1_start.w EQU $ram1_segment_start
ram1_end.w EQU $ram1_segment_end	
	ldw X,#ram1_start
clear_ram1.l
	clr (X)
	incw X
	cpw X,#ram1_end	
	jrule clear_ram1
	#endif

	; clear stack
stack_start.w EQU $stack_segment_start
stack_end.w EQU $stack_segment_end
	ldw X,#stack_start
clear_stack.l
	clr (X)
	incw X
	cpw X,#stack_end	
	jrule clear_stack
	
	
	

infinite_loop.l
		
	mov CLK_CKDIVR,#$00	  ; cpu clock no divisor = 16mhz
	mov PD_CR1,#%00011100 ; pullup enable on PD2,PD3,PD4 (PD_DDR is already reset to0x00)
	clr I2C_CR1			; write PE=0 incase it is a re init
	mov I2C_FREQR,#$10	; set i2c clock input frequency to 16mhz
	mov I2C_CCRH,#$00	; I2C period = 2 * CCR * tMASTER 100KHz : tabe 50 RM0016 P 315
	mov I2C_CCRL,#$50	; cpu 16mhz ,for 100Khz CCR=0x50 as per table ,FS bit 0 for std
	mov I2C_OARH,#$40	; ADD_CONF bit #6 should be always written as 1 as per data sheet
	mov I2C_TRISER,#17	; for 16 MHz : (1000 ns / 62.5 ns = 16 ) + 1 = 17
	mov I2C_CR1,#$1		; enable I2C peripheral
	
	mov data_length,#7
	mov array_start,#$20
	call SPI_INIT
	call matrix_init
	clr count
	jp main_loop

jumpMENU:
	jp MENU	
	
		
main_loop:
	btjf PD_IDR,#2 ,jumpMENU
	call read_time
	inc count
	ld a,#220
	cp a,count
	jrne main_loop
		
	call SRAMload
	call update_matrix1
	call ms30
	call shift_buffer_rh_to_lh
	mov pad1,DATE1stdigit
	call scroll_buffer
	mov pad1,DATE2nddigit
	call scroll_buffer
	mov pad1,SLASH1
	call scroll_buffer
	mov pad1,MONTH1stdigit
	call scroll_buffer
	mov pad1,MONTH2nddigit
	call scroll_buffer
	mov pad1,SLASH2
	call scroll_buffer
	mov pad1,YEAR1stdigit
	call scroll_buffer
	mov pad1,YEAR2nddigit
	call scroll_buffer
	mov pad1,SLASH3
	call scroll_buffer
	mov pad1,DAY1
	call scroll_buffer
	mov pad1,DAY2
	call scroll_buffer
	mov pad1,DAY3
	call scroll_buffer
	mov pad1,DAY4
	call scroll_buffer
	mov pad1,DAY5
	call scroll_buffer
	mov pad1,DAY6
	call scroll_buffer
	mov pad1,DAY7
	call scroll_buffer
	mov pad1,DAY8
	call scroll_buffer
	mov pad1,DAY9
	call scroll_buffer
	call shift_buffer_rh_to_lh
	clr count
	jp main_loop
	
		 
bufferloop: 
	 ld a,(Y)
	 ld (X),a
	 incw Y
	 incw X
	 dec buffer1
	 jrne bufferloop
	 ret


SRAMload:
	mov buffer1,#8
	pointerX #screen1
	mov ASCII,HOUR1stdigit
	call find_font
	call bufferloop
	
	mov buffer1,#8
	pointerX #screen2
	mov ASCII,HOUR2nddigit
	call find_font
	call bufferloop
	
	mov buffer1,#8
	pointerX #screen3
	mov ASCII,COLON1
	call find_font
	call bufferloop
	
	mov buffer1,#8
	pointerX #screen4
	mov ASCII,MINUTES1stdigit
	call find_font
	call bufferloop
	
	mov buffer1,#8
	pointerX #screen5
	mov ASCII,MINUTES2nddigit
	call find_font
	call bufferloop
	
	mov buffer1,#8
	pointerX #screen6
	mov ASCII,COLON2
	call find_font
	call bufferloop
	
	mov buffer1,#8
	pointerX #screen7
	mov ASCII,SECOND1stdigit
	call find_font
	call bufferloop
	
	mov buffer1,#8
	pointerX #screen8
	mov ASCII,SECOND2nddigit
	call find_font
	call bufferloop
	ret
	
read_time:
	call info_read
	call BCD_TO_ASCII
	call direct_matrix1
	call ms250
	ret
	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;SUBROUTINE TO READ INFO FORM DS3231 AND STORE IN SRAM BUFFER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

info_read:					; function to read time registers to buffer
	mov buffer2,#$D0		;#DS1307_write_address; DS1307 write address
	ldw X,#buf7				; setting pointer to buffer
	call startn_address_write	; issues start and sends write address
	mov buffer2,#$00     		; DS1307 has its time register addresses starting from 0x00
	call write_data			; function used to transmit above data
	call i2c_read			; function to read DS1307 registers
	ret	 

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPI routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
SPI_INIT:
	mov SPI_CR1,#%01011100 ; msb,enable, master/16,master,clock 0 at idle,first edge
	mov SPI_CR2,#%01000011 ; BODE enabled for output on MOSI ,SSm,SSI,%00000011 = duplex(for miso and mosi)
	bset PA_DDR,#3		   ; PA3 direction as output for SS
	bset PA_CR1,#3		   ; PA3 as push pull output
	ld a,PC_CR1	  		   ; copy PC_CR1 register to A
	mov buffer1,#%01100000 ; set bit6 and bit5
	or a,buffer1
	ld PC_CR1,a  		   ; PC5,PC6 output for mosia nd clk
	mov PC_CR2,#%01100000  ; PC5,PC6 as fast pushpull for SPI
	ret
SS_LO:
	bres PA_ODR,#3
	ret

SS_HI:
	btjt SPI_SR, #7, SS_HI
	bset PA_ODR,#3
	ret
	
SPI_TX:
	btjf SPI_SR, #1, SPI_TX
	ld SPI_DR,a
	ret
MAX_SPI_TX:
	ld a,address
	call SPI_TX
	ld a,data
	call SPI_TX
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

matrix_Cwrite1:
	mov address_counter,#8
	call SS_LO
Cloop:
	call MAX_SPI_TX
	dec address_counter
	jrne Cloop
	call SS_HI
	ret
	
matrix_init:	
	matrix_Cwrite matrixon
	matrix_Cwrite nodecode
	;matrix_Cwrite fullbright
	;matrix_Cwrite halfbright
	matrix_Cwrite quartbright
	matrix_Cwrite row
	matrix_Cwrite dsplytestmode
	matrix_Cwrite dsplynormal
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;find_font function   uses registers- temp,array_start,ASCII,
;characters to be printed has to be passed into register ASCII as ASCII values
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
find_font:
	push buffer2
	pointerY #fonts
	ld a,ASCII
	sub a,array_start
	jreq ASCII0
	ld ASCII,a
	clr buffer2
multiply:
	addw Y,#8
	inc buffer2
	cp a,buffer2
	jrne multiply
ASCII0:
	pop buffer2
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;clear matrix- clears all matrices by writing 0 toallmax7219 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_matrix1:
	push buffer1
	clr buffer1					; counter used for write routine to select correct font byte for each column )
	mov address,#1			; initialize address register to address of column0,later we increase this register
column_select1:
	mov address_counter,#8		; counter used by screen_write routine(counts how many LED matrix,we use 8 for time display)
	clr data					; data register loaded with 0 to be written to columns
	call SS_LO					; make SS pin low to activate MAX7219 and start SPI transfer
clear_screen:
	call MAX_SPI_TX				; transmit 0x00 written in data register to the column address selected for all matrices
	dec address_counter			; address counter was loaded with 8 ,so 0x00 will be transmitted 8 times for 1 column address
	Jrne clear_screen			; transmit till 8 bytes are clocked out ,1 column of all 8 matrix will be erased
	call SS_HI					; make SS pin HI to latch the 8x8 bytes transmitted to the addressed columns of 8 LEDmatrices 
	inc address					; increase the address by 1 , all column addresses are concecutivex
	inc buffer1						; increase byte count of the font array,
	ld a,#9
	cp a,buffer1				; if r23 is 0x09 all columns has been addressed 
	jrne column_select1			; if r23 has not reached value 0x09 loop back till all columns have been addressed
	pop buffer1
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;clears screen buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_buffer:
	push buffer1
	pointerY #screen1
	mov buffer1,#64
	clr data
CB:	
	ld a,data
	ld (y),a
	incw Y
	dec buffer1
	jrne CB
	pop buffer1
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;update matrix -writes the screen buffer to LED row wise
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_matrix1:
	pushw Y
	clr Temp2
	clr {Temp2 + 1}
	mov address,#1
column_select11:
	mov address_counter,#8
	pointerY #screen1
	addw Y,Temp2
	call SS_LO
	call screen_write1
	call SS_HI
	inc address
	inc {Temp2 + 1}
	ld a,#8
	cp a,{Temp2 + 1}
	jrne column_select11
	popw Y
	ret
screen_write1:
	ld a,(Y)
	ld data,a
	call MAX_SPI_TX
	addw Y,#8
	dec address_counter
	jrne screen_write1
	ret
	

	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;DELAY routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	

	
delayYx1mS:
	call delay1mS
	decw Y
	jrne delayYx1mS
	ret
delay1mS:
	pushw Y
	ldw Y,#{{fclk/1000}/3}
delay1mS_01:
	decw Y
	jrne delay1mS_01
	popw Y
	ret


usdelay:
	decw Y
	pushw Y
	popw Y
	pushw Y
	popw Y
	jrne usdelay
	ret

ms2000:
	millis #2000
	ret
	
ms500:
	millis #500
	ret
ms250:
	millis #250
	ret
ms50:
	millis #50
ms30:
	millis #30
	ret
ms10:
	millis #10
	ret	






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LED matrix update subroutine (8 peices of 64LED matrix is used to display time).
; sends 8 bytes of data for each column from column0 to column7, 1st all 8 column 0's are sent with 1st byte of the font. then 1,2,3...7
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
direct_matrix1:
	clr Temp2
	clr {Temp2 + 1}
	mov address,#1
column_select22:
	mov address_counter,#8
	pointerX #HOUR1stdigit
	call SS_LO
	call screen_write22
	call SS_HI
	inc address
	inc {Temp2 + 1}
	ld a,#8
	cp a,{Temp2 + 1}
	jrne column_select22
	ret
screen_write22:
	ld a,(X)
	ld ASCII,a
	incw X
	call find_font
	addw Y,Temp2
	ld a,(Y)
	ld data,a
	call MAX_SPI_TX
	dec address_counter
	jrne screen_write22
	ret
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; shift buffer - shifts entire buffer to lhs from rhs   empties the screen leftward
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
shift_buffer_rh_to_lh:
	push buffer3
	push buffer1
	mov buffer3,#64
LO1:
	call bit_shift_lh
	call update_matrix1
	call ms30
	dec buffer3
	jrne LO1
	pop buffer1
	pop buffer3
	ret
	
bit_shift_lh:
	push buf7
	push {buf7 + 1}
	push {buf7 + 2}
	push {buf7 + 3}
	push {buf7 + 4}
	push {buf7 + 5}
	push {buf7 + 6}
	push {buf7 + 7}
	rcf					;reset/clear carry flag
	pointerY #screen1
	pointerX #buf7
	call shift_proc
	rcf
	pointerY #screen1
	addw Y,#1
	pointerX #buf7
	call shift_proc
	rcf
	pointerY #screen1
	addw Y,#2
	pointerX #buf7
	call shift_proc
	rcf
	pointerY #screen1
	addw Y,#3
	pointerX #buf7
	call shift_proc
	rcf
	pointerY #screen1
	addw Y,#4
	pointerX #buf7
	call shift_proc
	rcf
	pointerY #screen1
	addw Y,#5
	pointerX #buf7
	call shift_proc
	rcf
	pointerY #screen1
	addw Y,#6
	pointerX #buf7
	call shift_proc
	rcf
	pointerY #screen1
	addw Y,#7
	pointerX #buf7
	call shift_proc
	pop {buf7 + 7}
	pop {buf7 + 6}
	pop {buf7 + 5}
	pop {buf7 + 4}
	pop {buf7 + 3}
	pop {buf7 + 2}
	pop {buf7 + 1}
	pop buf7
	ret
	
	
shift_proc:
	mov buffer1,#8
L1:
	ld a,(Y)
	ld (X),a
	addw Y,#8
	addw X,#1
	dec buffer1
	jrne L1
	sll {buf7 + 7}
	rlc {buf7 + 6}
	rlc {buf7 + 5}
	rlc {buf7 + 4}
	rlc {buf7 + 3}
	rlc {buf7 + 2}
	rlc {buf7 + 1}
	rlc  buf7 
	
	mov buffer1,#8
	subw X,#1
	subw Y,#8
L2:
	
	ld a,(X)
	ld (Y),a
	subw X,#1
	subw Y,#8
	dec buffer1
	jrne L2
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;cSCROLL buffer scrolls caharcter 1 pixel each and loads 1 character, call with ASCII character in pad1 register
;;;;;;;;  example -- mov pad1,HOUR1stdigit  and call scroll_buffer whch will scroll in character into LSB of screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
scroll_buffer:
	push buffer1
	push buffer2
	push buffer3
	pushw X
	pushw Y
	mov ASCII,pad1
	call find_font
	ld a,(Y)
	ld temp1,a
	incw Y
	ld a,(Y)
	ld temp2,a
	incw Y
	ld a,(Y)
	ld temp3,a
	incw Y
	ld a,(Y)
	ld temp4,a
	incw Y
	ld a,(Y)
	ld temp5,a
	incw Y
	ld a,(Y)
	ld temp6,a
	incw Y
	ld a,(Y)
	ld temp7,a
	incw Y
	ld a,(Y)
	ld temp8,a
	call scroll_in_lh
	call update_matrix1
	call ms50
	call SLL_PROC
	call scroll_in_lh
	call update_matrix1
	call ms50
	call SLL_PROC
	call scroll_in_lh
	call update_matrix1
	call ms50
	call SLL_PROC
	call scroll_in_lh
	call update_matrix1
	call ms50
	call SLL_PROC
	call scroll_in_lh
	call update_matrix1
	call ms50
	call SLL_PROC
	call scroll_in_lh
	call update_matrix1
	call ms50
	call SLL_PROC
	call scroll_in_lh
	call update_matrix1
	call ms50
	call SLL_PROC
	call scroll_in_lh
	call update_matrix1
	call ms50
	popw Y
	popw X 
	pop  buffer3
	pop  buffer2
	pop  buffer1
	ret


scroll_in_lh:
	push buf7
	push {buf7 + 1}
	push {buf7 + 2}
	push {buf7 + 3}
	push {buf7 + 4}
	push {buf7 + 5}
	push {buf7 + 6}
	push {buf7 + 7}
	rcf
	pointerY #screen8
	pointerX #buf7
	addw X,#7
	mov temp,temp1
	call scroll_proc
	rcf
	pointerY #screen8
	addw Y,#1
	pointerX #buf7
	addw X,#7
	mov temp,temp2
	call scroll_proc
	rcf
	pointerY #screen8
	addw Y,#2
	pointerX #buf7
	addw X,#7
	mov temp,temp3
	call scroll_proc
	rcf
	pointerY #screen8
	addw Y,#3
	pointerX #buf7
	addw X,#7
	mov temp,temp4
	call scroll_proc
	rcf
	pointerY #screen8
	addw Y,#4
	pointerX #buf7
	addw X,#7
	mov temp,temp5
	call scroll_proc
	rcf
	pointerY #screen8
	addw Y,#5
	pointerX #buf7
	addw X,#7
	mov temp,temp6
	call scroll_proc
	rcf
	pointerY #screen8
	addw Y,#6
	pointerX #buf7
	addw X,#7
	mov temp,temp7
	call scroll_proc
	rcf
	pointerY #screen8
	addw Y,#7
	pointerX #buf7
	addw X,#7
	mov temp,temp8
	call scroll_proc
	pop {buf7 + 7}
	pop {buf7 + 6}
	pop {buf7 + 5}
	pop {buf7 + 4}
	pop {buf7 + 3}
	pop {buf7 + 2}
	pop {buf7 + 1}
	pop buf7
	ret

scroll_proc:
	mov buffer1,#8
L3:
	ld a,(Y)
	ld (X),a
	subw Y,#8
	subw X,#1
	dec buffer1
	jrne L3
	sll temp
	rlc {buf7 + 7}
	rlc {buf7 + 6}
	rlc {buf7 + 5}
	rlc {buf7 + 4}
	rlc {buf7 + 3}
	rlc {buf7 + 2}
	rlc {buf7 + 1}
	rlc  buf7 
	
	mov buffer1,#8
	addw X,#1
	addw Y,#8
L4:
	
	ld a,(X)
	ld (Y),a
	addw X,#1
	addw Y,#8
	dec buffer1
	jrne L4
	ret
	
SLL_PROC:
	rcf
	sll temp1
	sll temp2
	sll temp3
	sll temp4
	sll temp5
	sll temp6
	sll temp7
	sll temp8
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;HARDWARE I2C PROCEDURES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
startn_address_write:					;  Send Address
    bset I2C_CR2,#2         			; set ACK bit
    bset I2C_CR2,#0         			; set SB START
wait_start_tx:              			; wait SB in I2C_SR1
    btjf I2C_SR1, #0, wait_start_tx		; If bit 0 of I2C_SR1 = 0 jump to label
	ld a,I2C_SR1            			; Clear SB bit
	ld a, buffer2						; LCD write address 0x4E in buffer2	
	ld I2C_DR,a							; copy A to I2C data register,I2C address
wait_adr_tx:		    				; this waits for address transmission
	btjf I2C_SR1,#1, wait_adr_tx		; If bit 1 of I2C_SR1 = 0 jump to label, if 1 continue
	ld a,I2C_SR1            			; clear ADDR bit  (reading SR1 and then SR3 clears ADDR flag)  
	ld a,I2C_SR3            			; clear ADDR bit  (reading SR1 and then SR3 clears ADDR flag)
	nop
  	ret
	
	
	
write_data:
	ld a,buffer2			; copy data to be transmitted from buffer2
	ld I2C_DR,a				; write data from buffer to I2C hardware data register 
wait_zero_tx:               			; wait for TXE bit to set(1),TXE=1 means data register empty    
	btjf I2C_SR1,#7, wait_zero_tx
	ret
	
	
stop:	
	bset I2C_CR2,#1         ; STOP
	bres I2C_CR2,#7         ; set SWRST
	ret	
	
	
DS1307_write_address.b equ $D0
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;I2C MASTER RECEIVER SUBROUTINE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

i2c_read:	
;--------------------------------------------------
    
	bset I2C_CR2,#2         	; set ACK bit
    
	bset I2C_CR2,#0         	; START

wait_start_rx:              		; wait SB in I2C_SR1
    
	btjf I2C_SR1, #0, wait_start_rx
    
	ld a,I2C_SR1            	; Clear SB bit
 	
	ld a,#DS1307_write_address	; LCD address with write=0x68<<0=0xD0	
	inc a						; increase 1 to write address makes it read address, D0+1=D1 or 0x68 << 1 
	ld  I2C_DR, a      			; DS1307 address RAED Mode
	
	ldw X,#buf7					; setting pointer to buffer

w0:
    
	btjf I2C_SR1,#1, w0			; wait till ADDR bit in SR1 is set indicating address tx success
    bset I2C_CR2,#2         	; send ACK
    
	ld a,I2C_SR1            	; clear ADDR bit
    
	ld a,I2C_SR3            	; clear ADDR bit
	
	ld a,data_length
	cp a,#1
	jreq single_setup			; if data length is 1 jump to single setup for one byte reception
	clr buffer3					; clear buffer3 in SRAM to use as data byte counter
i2c_multi_read:
	btjf I2C_SR1,#6,i2c_multi_read	; wait till bit6 (RXNE)of I2C_SR1 is set
	ld a,I2C_DR					; copy/read data from I2C_DR register to a
	ld (x),a					; store value in a to adress pointed by X
	incw x						; increase address pointer which will increase buf7 address
	inc buffer3					; buffer 3 is used as counter ,increase 1 count
	ld a,data_length			; load data length to be read ie 7(7 registers of DS130)
	sub a,#1					; subtract 1 from seven to find the 2nd last byte
	cp a,buffer3				; compare buffer3 value icremented each time to 6 = datalength - 1
	jrne i2c_multi_read			; if not yet datalength -1 loop to receive again

single_setup:
	bres I2C_CR2,#2         	; NACK loaded 
	bset I2C_CR2,#1         	; STOP loaded 
last_byte:
	btjf I2C_SR1,#6,last_byte
	ld a,I2C_DR
	ld (x),a
	bres I2C_CR2,#7				; set SWRST
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;SUBROUTINES TO CONVERT HEXADECIMAL TO ASCII
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
hex_ascii:          ;routine to convert HEX values selected for time adjustment to be displayed on LCD
	
	ld a,(x)
	ld pad1,a
	and a,#$F0
	swap a
	or a,#$30
	ld (Y),a         ; store ascii character in space pointed by Y
	incw Y
	ld a,pad1
	and a,#$0F
	or a,#$30
	ld (Y),a         ; store ascii character in space pointed by Y
	decw Y
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clockwrite:				; routine to copy adjusted time from SRAM to DS1307
	mov buffer2,#DS1307_write_address
	call startn_address_write
	mov buffer2,#$00    ; DS1307 has its time register addresses staring from 0x00
	call write_data
	mov buffer2,#$80	; bit 7 is CH bit if written 1 clock is stopped. if clock not stopped before write doesnt update
	call write_data
	call stop
	mov buffer2,#DS1307_write_address
	call startn_address_write
	mov buffer2,#$00    ; DS1307 has its time register addresses staring from 0x00 auto incremented
	call write_data
	mov buffer2,#$00	; 00 seconds to senconds register
	call write_data
	mov buffer2,minbcd	; write saved minutes
	call write_data	
	mov buffer2,hourbcd	; write saved hours
	call write_data		
	mov buffer2,weekbcd	; write from saved day of week 
	call write_data
	mov buffer2,datebcd	; write to date register  
	call write_data
	mov buffer2,monbcd	; write to month register
	call write_data
	mov buffer2,yearbcd	; write to year register 
	call write_data
	call stop
	jp main_loop
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;SUBROUTINE TO CONVERT BCD VALUES READ FROM DS3231 TO ASCII FOR LCD		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BCD_TO_ASCII:			; routine to convert BCD to ASCII and store in appropriate registers
	ldw X,#buf7			; pointer to the start address of buffer
	ld a,(x)
	ld pad1,a			; copy seconds data to SRAM address PAD1 for temprerory storage while processing
	swap a				; 
	and a,#$3f			; AND with 0b00111111 and only swapped seconds data remains ,tenth position is in lower nibble and unit position in higher nibble
	or a,#$30			; OR with ascii for 0 which is 0x30 (0b00110000) , higher nibble is invalidated and only lower nibble which is 10th seconds gets converted to ascii
	ld SECOND1stdigit,a		; store the 10th seconds ascii digit in SRAM location SECOND1stdigit			
	ld a,pad1			; copy previously stored seconds data from PAD1
	and a,#$3f			; AND with 0b00111111 and seconds data remains with higher nibble as 10th place and lower nibble as unit place
	or a,#$30			; OR the above value with ASCII0 (0b00110000) 0x30, upper nibble becomes 0x3 and lower nibble will remain as it is, which is unit part of seconds data
	ld SECOND2nddigit,a		; copy his ASCII unit seconds value to SECOND2nddigit in SRAM
	ld a,#' '			; load ascii blank   in r16
	ld BLANK,a			; store colon in SRAM location BLANK which will be used to print on LCD after the seconds digits

	addw x,#1
	ld a,(X)
	ld pad1,a			; copy minutes data to SRAM address PAD1 for temprerory storage while processing
	swap a				; 
	and a,#$3f			; AND with 0b00111111 and only swapped minutes data remains ,tenth position is in lower nibble and unit position in higher nibble
	or a,#$30			; OR with ascii for 0 which is 0x30 (0b00110000) , higher nibble is invalidated and only lower nibble which is 10th minutes gets converted to ascii
	ld MINUTES1stdigit,a		; store the 10th minutes ascii digit in SRAM location MINUTES1stdigit			
	ld a,pad1			; copy previously stored minutes data from PAD1
	and a,#$3f			; AND with 0b00111111 and minutes data remains with higher nibble as 10th place and lower nibble as unit place
	or a,#$30			; OR the above value with ASCII0 (0b00110000) 0x30, upper nibble becomes 0x3 and lower nibble will remain as it is, which is unit part of minutes data
	ld MINUTES2nddigit,a		; copy his ASCII unit minutes value to MINUTES2nddigit in SRAM
	ld a,#':'			; load ascii :  (colon) in r16
	ld COLON2,a			; store colon in SRAM location COLON1 which will be used to print on LCD after the minutes digits


	addw x,#1
	ld a,(X)
	ld pad1,a			; copy hour data to SRAM address PAD1 for temprerory storage while processing
	swap a				; 
	and a,#$3f			; AND with 0b00111111 and only swapped hour data remains ,tenth position is in lower nibble and unit position in higher nibble
	or a,#$30			; OR with ascii for 0 which is 0x30 (0b00110000) , higher nibble is invalidated and only lower nibble which is 10th hour gets converted to ascii
	ld HOUR1stdigit,a		; store the 10th hour ascii digit in SRAM location HOUR1stdigit			
	ld a,pad1			; copy previously stored hour data from PAD1
	and a,#$3f			; AND with 0b00111111 and hour data remains with higher nibble as 10th place and lower nibble as unit place
	or a,#$30			; OR the above value with ASCII0 (0b00110000) 0x30, upper nibble becomes 0x3 and lower nibble will remain as it is, which is unit part of hour data
	ld HOUR2nddigit,a		; copy his ASCII unit hour value to HOUR2nddigit in SRAM
	ld a,#':'			; load ascii :  (colon) in r16
	ld COLON1,a			; store colon in SRAM location COLON1 which will be used to print on LCD after the hour digits


	pointerY #WEEK0
	addw x,#1			; increase pointer x by 1 byte
	ld a,(x)			; copy data pointed by x to a
	and a,#$07			; AND with 0b00000111 so that only lower 3 bits remain , 1 monday to 7 sunday
	ld temp,a			; copy ANDed value to SRAM location temp for addtion
	cp a,#$00
	jreq C0
	ld a,temp
	cp a,#$01
	jreq C1
	ld a,temp
	cp a,#$02
	jreq C2
	ld a,temp
	cp a,#$03
	jreq C3
	ld a,temp
	cp a,#$04
	jreq C4
	ld a,temp
	cp a,#$05
	jreq C5
	ld a,temp
	cp a,#$06
	jreq C6
	ld a,temp
	cp a,#$07
	jreq C7
	ld a,temp
	cp a,#$08
	jreq C8
	
C0:
	call store_week
	jp out
C1:
	addw Y,#9
	call store_week
	jp out
C2:
	addw Y,#18
	call store_week
	jp out
C3:
	addw Y,#27
	call store_week
	jp out
C4:
	addw Y,#36
	call store_week
	jp out
C5:
	addw Y,#45
	call store_week
	jp out
C6:
	addw Y,#54
	call store_week
	jp out
C7:
	addw Y,#63
	call store_week
	jp out
C8:
	addw Y,#72
	call store_week
	jp out
	
store_week:
	ld a,(Y)
	ld DAY1,a
	incw Y
	ld a,(Y)
	ld DAY2,a
	incw Y
	ld a,(Y)
	ld DAY3,a
	incw Y
	ld a,(Y)
	ld DAY4,a
	incw Y
	ld a,(Y)
	ld DAY5,a
	incw Y
	ld a,(Y)
	ld DAY6,a
	incw Y
	ld a,(Y)
	ld DAY7,a
	incw Y
	ld a,(Y)
	ld DAY8,a
	incw Y
	ld a,(Y)
	ld DAY9,a
	ret
out:
	
	


	addw x,#1
	ld a,(X)
	ld pad1,a			; copy date data to SRAM address PAD1 for temprerory storage while processing
	swap a				; 
	and a,#$3f			; AND with 0b00111111 and only swapped date data remains ,tenth position is in lower nibble and unit position in higher nibble
	or a,#$30			; OR with ascii for 0 which is 0x30 (0b00110000) , higher nibble is invalidated and only lower nibble which is 10th date gets converted to ascii
	ld DATE1stdigit,a		; store the 10th date ascii digit in SRAM location DATE1stdigit			
	ld a,pad1			; copy previously stored date data from PAD1
	and a,#$3f			; AND with 0b00111111 and date data remains with higher nibble as 10th place and lower nibble as unit place
	or a,#$30			; OR the above value with ASCII0 (0b00110000) 0x30, upper nibble becomes 0x3 and lower nibble will remain as it is, which is unit part of date data
	ld DATE2nddigit,a		; copy this ASCII unit date value to DATE2nddigit in SRAM
	ld a,#'/'			; load ascii /   in r16
	ld SLASH1,a			; store / in SRAM location BLANK which will be used to print on LCD after the date digits



	addw x,#1
	ld a,(X)
	ld pad1,a			; copy month data to SRAM address PAD1 for temprerory storage while processing
	swap a				; 
	and a,#$3f			; AND with 0b00111111 and only swapped month data remains ,tenth position is in lower nibble and unit position in higher nibble
	or a,#$30			; OR with ascii for 0 which is 0x30 (0b00110000) , higher nibble is invalidated and only lower nibble which is 10th month gets converted to ascii
	ld MONTH1stdigit,a		; store the 10th month ascii digit in SRAM location MONTH1stdigit			
	ld a,pad1			; copy previously stored month data from PAD1
	and a,#$3f			; AND with 0b00111111 and month data remains with higher nibble as 10th place and lower nibble as unit place
	or a,#$30			; OR the above value with ASCII0 (0b00110000) 0x30, upper nibble becomes 0x3 and lower nibble will remain as it is, which is unit part of month data
	ld MONTH2nddigit,a		; copy this ASCII unit date value to MONTH2nddigit in SRAM
	ld a,#'/'			; load ascii /   in r16
	ld SLASH2,a			; store / in SRAM location BLANK which will be used to print on LCD after the month digits



	addw x,#1
	ld a,(X)
	ld pad1,a			; copy year data to SRAM address PAD1 for temprerory storage while processing
	swap a				; 
	and a,#$3f			; AND with 0b00111111 and only swapped year data remains ,tenth position is in lower nibble and unit position in higher nibble
	or a,#$30			; OR with ascii for 0 which is 0x30 (0b00110000) , higher nibble is invalidated and only lower nibble which is 10th year gets converted to ascii
	ld YEAR1stdigit,a		; store the 10th year ascii digit in SRAM location YEAR1stdigit			
	ld a,pad1			; copy previously stored year data from PAD1
	and a,#$3f			; AND with 0b00111111 and year data remains with higher nibble as 10th place and lower nibble as unit place
	or a,#$30			; OR the above value with ASCII0 (0b00110000) 0x30, upper nibble becomes 0x3 and lower nibble will remain as it is, which is unit part of year data
	ld YEAR2nddigit,a		; copy this ASCII unit date value to YEAR2nddigit in SRAM
	ld a,#' '			; load ascii ' '   in r16
	ld SLASH3,a			; store  ' ' in SRAM location BLANK which will be used to print on LCD after the year digits

	ret






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;FONTS   fonts below 5bytes ,assembler will add one byte of padding with 0. hence array lenth =6
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fonts:
  dc.b $00,$00,$00,$00,$00,$00,$00,$00 ; space
  dc.b $00,$10,$10,$10,$10,$00,$10,$00 ; !
  dc.b $36,$36,$12,$24,$00,$00,$00,$00 ; "   
  dc.b $14,$14,$7f,$14,$7f,$14,$14,$00 ; # 3  0x23
  dc.b $14,$3f,$54,$54,$3e,$15,$7e,$14 ; $ 4  0x24
  dc.b $00,$62,$64,$08,$10,$26,$46,$00 ; % 5  0x25
  dc.b $1c,$22,$12,$3c,$48,$4a,$3c,$08 ; & 6  0x26
  dc.b $18,$18,$08,$10,$00,$00,$00,$00 ; ' 7  0x27
  dc.b $00,$10,$20,$20,$20,$20,$10,$00 ; ( 8  0x28
  dc.b $00,$10,$08,$08,$08,$08,$10,$00 ; )  0x29
  dc.b $00,$2a,$1c,$08,$1c,$2a,$00,$00 ; * 10 0x2A
  dc.b $00,$10,$10,$7c,$10,$10,$00,$00 ; + 11 0x2B
  dc.b $00,$00,$00,$00,$30,$30,$10,$20 ; , 12 0x2C
  dc.b $00,$00,$00,$7c,$00,$00,$00,$00 ; - 13 0x2D
  dc.b $00,$00,$00,$00,$00,$00,$20,$00 ; . 14 0x2E
  dc.b $00,$04,$08,$10,$20,$40,$80,$00 ; / 15 0x2F
  dc.b $00,$38,$4c,$54,$64,$44,$38,$00 ;0
  dc.b $00,$10,$30,$10,$10,$10,$7c,$00 ;1
  dc.b $00,$30,$48,$08,$10,$20,$78,$00 ;2
  dc.b $00,$7c,$08,$38,$04,$04,$78,$00 ;3
  dc.b $00,$08,$18,$28,$7c,$08,$08,$00 ;4
  dc.b $00,$7c,$40,$78,$04,$04,$78,$00 ;5
  dc.b $00,$38,$40,$78,$44,$44,$38,$00 ;6
  dc.b $00,$7c,$08,$10,$20,$20,$20,$00 ;7
  dc.b $00,$38,$44,$38,$44,$44,$38,$00 ;8
  dc.b $00,$38,$44,$44,$3c,$04,$38,$00 ;9
  dc.b $00,$10,$00,$00,$00,$00,$10,$00 ;:
  dc.b $00,$18,$18,$00,$18,$18,$08,$10 ; ; 27 0x3B
  dc.b $00,$10,$20,$40,$40,$20,$10,$00 ; < 28 0X3C
  dc.b $00,$00,$7c,$00,$7c,$00,$00,$00 ; = 29 0X3D
  dc.b $00,$00,$08,$04,$02,$04,$08,$00 ; > 30 0X3E
  dc.b $00,$38,$44,$04,$18,$10,$00,$10 ; ? 31 0X3F
  dc.b $3c,$42,$99,$a5,$a5,$9f,$40,$3f ; @ 32 0X40
  dc.b $10,$28,$44,$44,$7c,$44,$44,$00 ;A
  dc.b $00,$70,$48,$78,$44,$44,$78,$00 ;B
  dc.b $00,$38,$40,$40,$40,$40,$38,$00 ;C
  dc.b $00,$78,$44,$44,$44,$44,$78,$00 ;D
  dc.b $00,$78,$40,$78,$40,$40,$7c,$00 ;E
  dc.b $00,$78,$40,$78,$40,$40,$40,$00 ;F
  dc.b $00,$38,$40,$40,$5c,$54,$34,$00 ;G
  dc.b $00,$44,$44,$7c,$44,$44,$44,$00 ;H
  dc.b $00,$38,$10,$10,$10,$10,$7c,$00 ;I
  dc.b $00,$7c,$10,$10,$10,$50,$30,$00 ;J
  dc.b $00,$48,$50,$60,$50,$48,$44,$00 ;K
  dc.b $00,$40,$40,$40,$40,$40,$7c,$00 ;L
  dc.b $00,$44,$6c,$54,$44,$44,$44,$00 ;M
  dc.b $00,$42,$62,$52,$4a,$46,$42,$00 ;N
  dc.b $00,$3c,$42,$42,$42,$42,$3c,$00 ;O
  dc.b $00,$78,$44,$44,$78,$40,$40,$00 ;P
  dc.b $00,$38,$44,$44,$54,$4c,$3c,$02 ;Q
  dc.b $00,$78,$44,$44,$78,$50,$48,$00 ;R
  dc.b $00,$3c,$40,$3c,$02,$02,$7c,$00 ;S
  dc.b $00,$7c,$10,$10,$10,$10,$10,$00 ;T
  dc.b $00,$44,$44,$44,$44,$44,$38,$00 ;U
  dc.b $00,$44,$44,$44,$44,$28,$10,$00 ;V
  dc.b $00,$42,$42,$42,$5a,$66,$42,$00 ;W
  dc.b $00,$42,$24,$18,$18,$24,$42,$00 ;X
  dc.b $00,$44,$44,$28,$10,$10,$10,$00 ;Y
  dc.b $00,$7c,$08,$10,$20,$40,$7c,$00 ;Z
  dc.b $3c,$20,$20,$20,$20,$20,$20,$3c ; [ 59 0X5B
  dc.b $00,$40,$20,$10,$08,$04,$02,$00 ; \ 60 0X5C
  dc.b $1c,$04,$04,$04,$04,$04,$04,$1c ; ] 61 0X5D
  dc.b $08,$14,$22,$00,$00,$00,$00,$00 ; ^ 62 0X5E
  dc.b $00,$00,$00,$00,$00,$00,$00,$7e ; _ 63 0X5F
	
	
	
	
	
number dc.B $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$10,$11,$12,$13,$14,$15  ;max allowd is 16/line
number0 dc.B $16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31 ; max alloed is 16/line
number1 dc.B $32,$33,$34,$35,$36,$37,$38,$39,$40,$41,$42,$43,$44,$45,$46,$47
number2 dc.B $48,$49,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$60,$61,$62,$63
number3 dc.B $64,$65,$66,$67,$68,$69,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79
number4 dc.B $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$90,$91,$92,$93,$94,$95
number5 dc.B $96,$97,$98,$99
	
	
string  dc.B "Hello world!\0"
string0 dc.B "ADJ TIME"
string1 dc.B "ADJ DATE"
string2 dc.B "ADJ WEEK"		

WEEK0 dc.B "NEXT     "
WEEK1 dc.B "MONDAY   "
WEEK2 dc.B "TUESDAY  "
WEEK3 dc.B "WEDNESDAY"
WEEK4 dc.B "THURSDAY "
WEEK5 dc.B "FRIDAY   "
WEEK6 dc.B "SATURDAY "
WEEK7 dc.B "SUNDAY   "
WEEK8 dc.B "XXXXXXXX "

no_op.b 	equ $00
digit0.b 	equ $01
digit1.b 	equ $02
digit2.b 	equ $03
digit3.b 	equ $04
digit4.b 	equ $05
digit5.b 	equ $06
digit6.b 	equ $07
digit7.b 	equ $08
decode.b 	equ $09
bright.b 	equ $0A
scanlimit.b equ $0B 
shutdown.b 	equ $0C
dsplytest.b equ $0F
matrixoff.w equ $0c00
matrixon.w 	equ $0c01
nodecode.w 	equ $0900
decodeall.w equ $09FF
fullbright.w equ $0A0F
halfbright.w equ $0A07
quartbright.w equ $0A03
row.w 		equ  $0b07
dsplytestmode.w equ $0F01
dsplynormal.w equ   $0F00
fclk.l 		equ 16000000
DS1307WAD.b equ $D0
DS1307RAD.b equ $D1



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MENU:
	
	clr hourbcd
	clr minbcd
	clr datebcd
	clr monbcd
	clr yearbcd
	clr weekbcd
	mov HOUR1stdigit,#$30	; store 0x30 in sram register HOUR1stdigit
	mov HOUR2nddigit,#$30	; store 0x30 in sram register HOUR2nddigit
	mov MINUTES1stdigit,#$30	; store 0x30 in sram register MINUTE1stdigit
	mov MINUTES2nddigit,#$30	; store 0x30 in sram register MINUTE2nddigit
	mov SECOND1stdigit,#$30	; store 0x30 in sram register SECOND1stdigit
	mov SECOND2nddigit,#$30	; store 0x30 in sram register SECOND2nddigit
	mov	DATE1stdigit,#$30   
	mov DATE2nddigit,#$30  	
	mov	MONTH1stdigit,#$30   
	mov	MONTH2nddigit,#$30 	
	mov	YEAR1stdigit,#$30  	
	mov	YEAR2nddigit,#$30  	
	mov DAY1,#$30
	mov DAY2,#$30
	mov DAY3,#$30
	mov DAY4,#$30
	mov DAY5,#$30
	mov DAY6,#$30
	mov DAY7,#$30
	mov DAY8,#$30
	
	
	mov count,#8
	pointerX #string0
SWL0:
	ld a,(X)
	ld pad1,a
	call scroll_buffer
	call ms10
	incw X
	dec count
	jrne SWL0
	call ms2000
	call clear_buffer
	

hour:					;;procedure to adjust hour 24 format
	mov buffer3,#24
	pointerX #number
	pointerY #HOUR1stdigit
scroll_hour:
	call hex_ascii
	dec buffer3
	pushw X
	pushw Y
	call direct_matrix1
	popw Y
	popw X
	call ms250
scan_button:
	ld a,PD_IDR
	and a,#$10
	jreq save_hour
scan_next:
	ld a,PD_IDR
	and a,#$08
	jrne scan_button
	ld a, buffer3
	cp a,#0
	jreq hour
	call ms250
	incw x
	jp scroll_hour
save_hour:
	call ms2000
	mov hourbcd,pad1
	
		
	
minute:						;procedure to adjust minute
	mov buffer3,#60
	pointerX #number
	pointerY #MINUTES1stdigit
scroll_minute:
	call hex_ascii
	dec buffer3
	pushw X
	pushw Y
	call direct_matrix1
	popw Y
	popw X
	call ms250
scan_button1:
	ld a,PD_IDR
	and a,#$10
	jreq save_minute
scan_next1:
	ld a,PD_IDR
	and a,#$08
	jrne scan_button1
	ld a, buffer3
	cp a,#0
	jreq minute
	call ms250
	incw x
	jp scroll_minute
save_minute:
	call ms2000
	mov minbcd,pad1
	
	
	mov count,#8
	pointerX #string1
SWL1:
	ld a,(X)
	ld pad1,a
	call scroll_buffer
	call ms10
	incw X
	dec count
	jrne SWL1
	call ms2000
	call clear_buffer
	

date:
	mov buffer3,#32		;load buffer3 in SRAM with #60 max seection of year 2060,increase array if need more
	pointerX #number		;macro to load index reg x with address of label "number",
	pointerY #DATE1stdigit
scroll_date:
	call hex_ascii		;convert selectted number in array to ASCII format to display on LCD
	dec buffer3			;decrease the count by 1 to 0 on each iteration
	pushw X
	pushw Y
	call direct_matrix2
	popw Y
	popw X
	call ms250
scan_button5:
	ld a,PD_IDR			;copy port pin data reg to reg a
	and a,#$10			; and with 0x10 to verify PD4 is pressed (0),not pressed (1)"save button" 
	jreq save_date		; if 0 save button pressed , jump to label save date to store date selected
scan_next5:
	ld a,PD_IDR			;copy port pin data reg to reg a
	and a,#$08			;and a with 0x08 to check PD3 is pressed(0),not pressed(1),"select/next button"
	jrne scan_button5	;if (1) sit in a tight loop till "next" or "save"button is pressed looping to scanbutton
	ld a, buffer3		;copy buffer3 to a to test the value of array counter
	cp a,#0				;compare a reg is equal to 0
	jreq date			; if buffer3 counter reached 0 jump to date to reload counter as no value is saved
	call ms250
	incw x				; if buffer3 counter is higher than 0 we increase x to move up the number array
	jp scroll_date		;jump back to label scroll date to repeat the process with new number from array
save_date:
	call ms2000
	mov datebcd,pad1	;copy and store the selected value from pad1 to datebcd register we created in SRAM
			


month:
	mov buffer3,#13
	pointerX #number
	pointerY #MONTH1stdigit
scroll_month:
	call hex_ascii
	dec buffer3
	pushw X
	pushw Y
	call direct_matrix2
	popw Y
	popw X
	call ms250
scan_button3:
	ld a,PD_IDR
	and a,#$10
	jreq save_month
scan_next3:
	ld a,PD_IDR
	and a,#$08
	jrne scan_button3
	ld a, buffer3
	cp a,#0
	jreq month
	call ms250
	incw x
	jp scroll_month
save_month:
	call ms2000
	mov monbcd,pad1
	

year:					;procedure to adjust year
	mov buffer3,#60
	pointerX #number
	pointerY #YEAR1stdigit
scroll_year:
	call hex_ascii
	dec buffer3
	pushw X
	pushw Y
	call direct_matrix2
	popw Y
	popw X
	call ms250
scan_button4:
	ld a,PD_IDR
	and a,#$10
	jreq save_year
scan_next4:
	ld a,PD_IDR
	and a,#$08
	jrne scan_button4
	ld a, buffer3
	cp a,#0
	jreq year
	call ms250
	incw x
	jp scroll_year
save_year:
	call ms2000
	mov yearbcd,pad1
	
	
	
	mov count,#8
	pointerX #string2
SWL2:
	ld a,(X)
	ld pad1,a
	call scroll_buffer
	call ms10
	incw X
	dec count
	jrne SWL2
	call ms2000
	call clear_buffer	
	
week:
	mov buffer3,#8
	pointerX #number
scroll_week:
	ld a,(X)
	ld weekbcd,a
	mov pad1,weekbcd
	call show_week
	call ms250
	dec buffer3
;	incw X
scan_button2:
	ld a,PD_IDR
	and a,#$10
	jreq save_week
scan_next2:
	ld a,PD_IDR
	and a,#$08
	jrne scan_button2
	ld a, buffer3
	cp a,#0
	jreq week
	call ms250
	incw x
	jp scroll_week
save_week:
	call ms2000
	mov weekbcd,pad1
	jp clockwrite
		


show_week:
	pushw Y
	pushw X
	ld a,weekbcd
	and a,#7
	inc a
	pointerY #WEEK0
WL:
	addw Y,#9
	dec a
	jrne WL
	subw Y,#9
	ld a,(Y)
	ld DAY1,a
	incw Y
	ld a,(Y)
	ld DAY2,a
	incw Y
	ld a,(Y)
	ld DAY3,a
	incw Y
	ld a,(Y)
	ld DAY4,a
	incw Y
	ld a,(Y)
	ld DAY5,a
	incw Y
	ld a,(Y)
	ld DAY6,a
	incw Y
	ld a,(Y)
	ld DAY7,a
	incw Y
	ld a,(Y)
	ld DAY8,a
	incw Y
	ld a,(Y)
	ld DAY9,a
	call direct_matrix3
	popw X
	popw Y
	ret
	
	


direct_matrix2:
	clr Temp2
	clr {Temp2 + 1}
	mov address,#1
column_select222:
	mov address_counter,#8
	pointerX #DATE1stdigit
	call SS_LO
	call screen_write222
	call SS_HI
	inc address
	inc {Temp2 + 1}
	ld a,#8
	cp a,{Temp2 + 1}
	jrne column_select222
	ret
screen_write222:
	ld a,(X)
	ld ASCII,a
	incw X
	call find_font
	addw Y,Temp2
	ld a,(Y)
	ld data,a
	call MAX_SPI_TX
	dec address_counter
	jrne screen_write222
	ret


direct_matrix3:
	clr Temp2
	clr {Temp2 + 1}
	mov address,#1
column_select223:
	mov address_counter,#8
	pointerX #DAY1
	call SS_LO
	call screen_write223
	call SS_HI
	inc address
	inc {Temp2 + 1}
	ld a,#8
	cp a,{Temp2 + 1}
	jrne column_select223
	ret
screen_write223:
	ld a,(X)
	ld ASCII,a
	incw X
	call find_font
	addw Y,Temp2
	ld a,(Y)
	ld data,a
	call MAX_SPI_TX
	dec address_counter
	jrne screen_write223
	ret

	
	

	interrupt NonHandledInterrupt
NonHandledInterrupt.l
	iret

	segment 'vectit'
	dc.l {$82000000+main}									; reset
	dc.l {$82000000+NonHandledInterrupt}	; trap
	dc.l {$82000000+NonHandledInterrupt}	; irq0
	dc.l {$82000000+NonHandledInterrupt}	; irq1
	dc.l {$82000000+NonHandledInterrupt}	; irq2
	dc.l {$82000000+NonHandledInterrupt}	; irq3
	dc.l {$82000000+NonHandledInterrupt}	; irq4
	dc.l {$82000000+NonHandledInterrupt}	; irq5
	dc.l {$82000000+NonHandledInterrupt}	; irq6
	dc.l {$82000000+NonHandledInterrupt}	; irq7
	dc.l {$82000000+NonHandledInterrupt}	; irq8
	dc.l {$82000000+NonHandledInterrupt}	; irq9
	dc.l {$82000000+NonHandledInterrupt}	; irq10
	dc.l {$82000000+NonHandledInterrupt}	; irq11
	dc.l {$82000000+NonHandledInterrupt}	; irq12
	dc.l {$82000000+NonHandledInterrupt}	; irq13
	dc.l {$82000000+NonHandledInterrupt}	; irq14
	dc.l {$82000000+NonHandledInterrupt}	; irq15
	dc.l {$82000000+NonHandledInterrupt}	; irq16
	dc.l {$82000000+NonHandledInterrupt}	; irq17
	dc.l {$82000000+NonHandledInterrupt}	; irq18
	dc.l {$82000000+NonHandledInterrupt}	; irq19
	dc.l {$82000000+NonHandledInterrupt}	; irq20
	dc.l {$82000000+NonHandledInterrupt}	; irq21
	dc.l {$82000000+NonHandledInterrupt}	; irq22
	dc.l {$82000000+NonHandledInterrupt}	; irq23
	dc.l {$82000000+NonHandledInterrupt}	; irq24
	dc.l {$82000000+NonHandledInterrupt}	; irq25
	dc.l {$82000000+NonHandledInterrupt}	; irq26
	dc.l {$82000000+NonHandledInterrupt}	; irq27
	dc.l {$82000000+NonHandledInterrupt}	; irq28
	dc.l {$82000000+NonHandledInterrupt}	; irq29

	end
