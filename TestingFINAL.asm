#Runs through many pairs of numbers, and does each operation on them, checking if the answer matches with the FPU
.data
	op1Arr:	.float	2, 2, 0, 0, -1, 4, 9, 0.2354, 4.35, 10000, 99999999
	op2Arr:	.float	2, 0, 2, 0, -1, 2, 2, -4.234, 14.3, 0.1  , 2
	opArrSize: .word 11

	new_line_string:.asciiz "\n"
	tab_string:	.asciiz "\t"
.macro PRINT_NEWLINE
	li $v0, 4
	la $a0, new_line_string
	syscall
.end_macro
.macro PRINT_TAB
	li $v0, 4
	la $a0, tab_string
	syscall
.end_macro
.macro PRINT_STR (%str)
	.data	
		str_to_print:	.asciiz	%str
	.text
		li $v0, 4
		la $a0, str_to_print
		syscall
.end_macro
.macro PRINT_INT (%x)
	li  $v0, 1
	add $a0, $0, %x
	syscall
.end_macro
.macro PRINT_FLOAT (%x)
	li    $v0, 2
	mtc1  %x, $f12
	syscall
.end_macro
.macro PRINT_HEX (%x)
	li  $v0, 34
	add $a0, $0, %x
	syscall
.end_macro
.macro PRINT_BIN (%x)
	li  $v0, 35
	add $a0, $0, %x
	syscall
.end_macro

.text

lw $s0, opArrSize
li $s1, 0	#loop counter
la $s2, op1Arr	#op1 mem location
la $s3, op2Arr	#op2 mem location

#store these values on the stack
addi $sp, $sp, -16
sw $s0, 12($sp)
sw $s1, 8($sp)
sw $s2, 4($sp)
sw $s3, 0($sp)

loop:
#refresh variables from last loop
lw $s0, 12($sp)
lw $s1, 8($sp)
lw $s2, 4($sp)
lw $s3, 0($sp)

beq $s0, $s1, loop_end

	addi $s1, $s1, 1	#incriment counter before stack is changed
	sw $s1, 8($sp)		#save new value on stack

	lw $t0, 0($s2)		#load op1
	addi $s2, $s2, 4	#incriment to next mem location
	sw $s2, 4($sp)		#store mem location of op1Arr 
	
	lw $t1, 0($s3)		#load op2
	addi $s3, $s3, 4	#incriment to next mem location
	sw $s3, 0($sp)		#store mem location of op2Arr
	
	
	addi $sp, $sp, -48	#push stack down
	sw $t0, 44($sp)		#store op1 on stack
	sw $t1, 40($sp)		#store op2 on stack
	
	#get parts
	lw $a0, 44($sp)		#going to call get_sign
	jal get_sign		#get sign of op1
	sw $v0, 36($sp)		#store sign of op1
	
	lw $a0, 44($sp)		#going to call get_exponent
	jal get_exponent	#get exponent of op1
	sw $v0, 32($sp)		#store exp of op1
	
	lw $a0, 44($sp)		#setting up to call get_fraction
	jal get_fraction	#get fraction of op1
	sw $v0, 28($sp)		#store fraction of op1
	
	lw $a0, 40($sp)		#going to call get_sign
	jal get_sign		#get sign of op2
	sw $v0, 24($sp)		#store sign of op2
	
	lw $a0, 40($sp)		#going to call get_exponent
	jal get_exponent	#get exponent of op2
	sw $v0, 20($sp)		#store exp of op2
	
	lw $a0, 40($sp)		#setting up to call get_fraction
	jal get_fraction	#get fraction of op2
	sw $v0, 16($sp)		#store fraction of op2
	
	#call add
	lw $v0, 36($sp)	#op1 sign
	lw $v1, 32($sp) #op1 exp
	lw $a0, 28($sp)	#op1 fraction
	lw $a1, 24($sp)	#op2 sign
	lw $a2, 20($sp) #op2 exp
	lw $a3, 16($sp)	#op2 fraction
	li $t8, 1
	jal add_fp
	sw $v0, 12($sp)	#store calc add

	#call subtract
	lw $v0, 36($sp)	#op1 sign
	lw $v1, 32($sp) #op1 exp
	lw $a0, 28($sp)	#op1 fraction
	lw $a1, 24($sp)	#op2 sign
	lw $a2, 20($sp) #op2 exp
	lw $a3, 16($sp)	#op2 fraction
	li $t8, 2
	jal sub_fp
	sw $v0, 8($sp)	#store calc sub
	
	#call multiply 
	lw $v0, 36($sp)	#op1 sign
	lw $v1, 32($sp) #op1 exp
	lw $a0, 28($sp)	#op1 fraction
	lw $a1, 24($sp)	#op2 sign
	lw $a2, 20($sp) #op2 exp
	lw $a3, 16($sp)	#op2 fraction
	li $t8, 3
	jal mult_fp
	sw $v0, 4($sp)	#store calc mult
	
	#call divide
	lw $v0, 36($sp)	#op1 sign
	lw $v1, 32($sp) #op1 exp
	lw $a0, 28($sp)	#op1 fraction
	lw $a1, 24($sp)	#op2 sign
	lw $a2, 20($sp) #op2 exp
	lw $a3, 16($sp)	#op2 fraction
	li $t8, 4
	li $t0, 0
	li $t1, 0
	jal div_fp
	sw $v0, 0($sp)	#store calc div
	
	#calculate actual answers using FP Unit
	lw $t1, 44($sp) #load op1
	mtc1 $t1, $f1	#store op1 in FPU
	lw $t2, 40($sp) #load op2
	mtc1 $t2, $f2	#store op2 in FPU
	
	add.s $f4, $f1, $f2
	sub.s $f5, $f1, $f2
	mul.s $f6, $f1, $f2
	div.s $f7, $f1, $f2
	
	mfc1 $s4, $f4	#move answers to regular registers
	mfc1 $s5, $f5	#move answers to regular registers
	mfc1 $s6, $f6	#move answers to regular registers
	mfc1 $s7, $f7	#move answers to regular registers
	
	#restore calculated answers from stack
	lw $s0, 12($sp)
	lw $s1, 8($sp)
	lw $s2, 4($sp)
	lw $s3, 0($sp)
	
	#restore operands
	lw $t8, 44($sp)
	lw $t9, 40($sp)
	
	# $s0 = calc add
	# $s1 = calc sub
	# $s2 = calc mult
	# $s3 = calc div
	# $s4 = actual add answer
	# $s5 = actual sub answer
	# $s6 = actual mult answer
	# $s7 = actual div answer
	
	PRINT_FLOAT($t8)
	PRINT_STR(" + ")
	PRINT_FLOAT($t9)
	PRINT_STR(" = \t")
	PRINT_FLOAT($s0)
	beq $s0, $s4, goodAdd		#check for equal answers
		PRINT_STR("\tActual answer: ")
		PRINT_FLOAT($s4)
		PRINT_STR("\tINCORRECT")
	goodAdd:
	PRINT_NEWLINE
	
	PRINT_FLOAT($t8)
	PRINT_STR(" - ")
	PRINT_FLOAT($t9)
	PRINT_STR(" = \t")
	PRINT_FLOAT($s1)
	beq $s1, $s5, goodSub		#check for equal answers
		PRINT_STR("\tActual answer: ")
		PRINT_FLOAT($s5)
		PRINT_STR("\tINCORRECT")
	goodSub:
	PRINT_NEWLINE
	
	PRINT_FLOAT($t8)
	PRINT_STR(" * ")
	PRINT_FLOAT($t9)
	PRINT_STR(" = \t")
	PRINT_FLOAT($s2)
	beq $s2, $s6, goodMult		#check for equal answers
		PRINT_STR("\tActual answer: ")
		PRINT_FLOAT($s6)
		PRINT_STR("\tINCORRECT")
	goodMult:
	PRINT_NEWLINE
	
	PRINT_FLOAT($t8)
	PRINT_STR(" / ")
	PRINT_FLOAT($t9)
	PRINT_STR(" = \t")
	PRINT_FLOAT($s3)
	beq $s3, $s7, goodDiv		#check for equal answers
		PRINT_STR("\tActual answer: ")
		PRINT_FLOAT($s7)
		PRINT_STR("\tINCORRECT")
	goodDiv:
	PRINT_NEWLINE
	
	PRINT_NEWLINE

	addi $sp, $sp, 48	#restore stack
j loop
loop_end:

li $v0, 10	#end program
syscall

#functions to use below

####################################################################################################################################
add_fp:
j sub_fp
#end add
#####################################################################################################################################
#Subtract two numbers provided by calling function
#sign, exp, mant => vo, v1, a0; a1, a2, a3

sub_fp:
addi $v1, $v1, 127
addi $a2, $a2, 127

exp_zero_check:			#Checks if exponents are equal to ZERO
beq $v1, $zero, mant_1_zero
beq $a2, $zero, mant_2_zero
j sub_cont

mant_1_zero:			#Checks if op1 mantissa is equal to ZERO
beq $a0, $zero, ans_is_op2
j sub_cont

mant_2_zero:			#Checks if op2 mantissa is equal to ZERO
beq $a3, $zero, ans_is_op1
j sub_cont

ans_is_op2:			#Returns the value of Operand 2
addi $t7, $0, 2		
add $a0, $a1, $zero
addi $a1, $a2, -127
add $a2, $a3, $zero
beq $t8, $t7, ans_is_neg2
j recombine_fp

ans_is_neg2:
xori $a0, $a0, 0xFFFFFFFF
j recombine_fp

ans_is_op1:
add $a2, $a0, $zero			#Returns the value of Operand 1
add $a0, $v0, $zero
addi $a1, $v1, -127
j recombine_fp

sub_cont:
ori $t0, $a0, 0x00800000
ori $t1, $a3, 0x00800000   #change one from implicit to explicit
sll $t0, $t0, 6
sll $t1, $t1, 6            #shift number portion to desirable spot (leave one space for sign, one space for growth)
blt $v1, $a2, subeq1       
blt $a2, $v1, subeq2       #branch to one of two subfunctions to set exponents equal and shift the number
j subbody                  #skip the subfunctions if exponents are equal

subeq1:
sub $t2, $a2, $v1
srlv $t0, $t0, $t2		
add $v1, $v1, $t2		
j subbody

subeq2:
sub $t2, $v1, $a2
srlv $t1, $t1, $t2		
add $a2, $a2, $t2		
j subbody

subbody:
sll $t2, $v0, 31
sll $t3, $a1, 31               #move sign to leftmost bit
or $t0, $t0, $t2
or $t1, $t1, $t3               #combine sign and number
beq $v0, $0, subskip1          #if positive, already in two's comp
xori $t0, $t0, 0x7FFFFFFF      #flip bits aside from leftmost
addi $t0, $t0, 0x00000001      #add 1
subskip1:
beq $a1, $0, subskip2
xori $t1, $t1, 0x7FFFFFFF
addi $t1, $t1, 0x00000001
subskip2:
addi $t6, $0, 1
beq $t8, $t6, subadd
sub $t0, $t0, $t1              #subtract and get our answer
j addskip
subadd:
add $t0, $t0, $t1
addskip:
andi $t1, $t0, 0x80000000      #t1 gets our sign which is already in the right spot for our answer
beq $t1, $0, subskip3          #if positive, already in sign-mag
subi $t0, $t0, 1
xori $t0, $t0, 0x7FFFFFFF
subskip3:
addi $t2, $0, -2               #set a counter that will come up as -1 if the magnitude increased 1, or otherwise show the decrease
addi $t5, $0, 30
subadjloop:
addi $t2, $t2, 1               #increment counter
sll $t0, $t0, 1                #shift the answer left one
andi $t3, $t0, 0x80000000      #check if leftmost bit is a one
beq $t2, $t5, subzero          #if nothing has come up as a one after 30 loops, the answer is zero
beq $t3, $0, subadjloop        #loop if leftmost bit is still zero
sll $t0, $t0, 1                #knock off the implied one
srl $t0, $t0, 9                #set the mantissa into the correct spot
or $t0, $t0, $t1               #put the sign in place
sub $t1, $v1, $t2              #adjust exponent
sll $t1, $t1, 23               #move exponent
or $t9, $t0, $t1               #place exponent
add $v0, $t9, $0
jr $ra                         #return answer

subzero:
add $v0, $0, $0
jr $ra
#end sub
#####################################################################################################################################
mult_fp:
	#v0= first sign, v1= first exponent, a0= first mantissa
	#a1= second sign, a2= second exponent, a3= second mantissa
	# Checking to see if either of the values == 0
	# Since the iee format will be broken up, i can just check if one or the other
	# exponent & mantissa equals all zero, if so, the output =0.
	addi $v1, $v1, 127
	addi $a2, $a2, 127
	#First, check if either = 0
	beqz $v1, mult_checkFirstMan #if the first exponent =0, check the mantissa
	mult_clearOne:
	beqz $a2, mult_checkSecondMan # if the second exponent =0, check the mantissa
	mult_clearTwo:
	# Both are clear, so do math
	xor $t6, $v0, $a1 #getting the new sign
	add $t7, $v1, $a2 # getting new exponent
	addi $t7, $t7, -254 # Getting the exponent to the actual, base ten exponent.
	addi $t7, $t7, 127 #Shift it to biased, cannot call to recombine_fp
	ori $a0, $a0, 0x00800000
	ori $a3, $a3, 0x00800000
	lui $t1 ,0x8000
	mult $a0, $a3
	mfhi $t3
	mflo $t0
	sll $t3, $t3, 16
	srl $t0, $t0, 16
	or $t3, $t3, $t0
	and $t4, $t3, $t1 #checking if needs to be normalized
	beqz $t4, mult_notNormal #if it passes, it needs to be normalized, so it will have 1 added to the exponent
	addi $t7, $t7, 1
	#Checking if there is underflow here
	li $t5, 255
	beq $t5, $t7, mult_overflow #if this is true, overflow is detected
	li $t5, 0
	beq $t5, $t7, mult_underflow
	
	mult_notNormal:
	mult_shift:
	and $t2, $t3, $t1
	sll $t3, $t3, 1
	beqz $t2, mult_shift
	srl $t8, $t3, 9
	
	
	#a1 exponent (8 bits) (signed, so will add 127 to it)
	#a2 mantissa (23 bits)
	#returns IEEE 754 single precision FP number from given parts in $v0
	move $v0, $t8
	sll $t6, $t6, 31	#sign bit to left-most bit
	or  $v0, $v0, $t6	#place sign bit in $v0
	
	sll $t7, $t7, 24	#shift exp to left-most, then shift back (so as onlt the correct 8 bits are set)(32-8=24)
	srl $t7, $t7, 1		#shift exp to proper place
	or  $v0, $v0, $t7	#place exponent in $v0
	jr $ra			#we done
	
	
	
	
	mult_checkFirstMan: # Checking the mantissa
		beqz $a0, mult_setToZero #If it equals zero, set it all == o
		j mult_clearOne
	mult_checkSecondMan: # Checking the second mantissa
		beqz $a3, mult_setToZero #If it equals zero, set it all == o
		j mult_clearTwo
	mult_setToZero: # If either of the tests passed, setting everything equal to 0
		li $v0, 0
		jr $ra
	mult_overflow:
		#Overflow detected, do something here
	mult_underflow:
		#underflow detected, do something else here
	# Need rounding


#end mult
#####################################################################################################################################
div_fp: 
	
	#Since mips only offers integer division, we need to work around this
	#The algorithim to find the new mantissa is essentailly just a long divison algorithm
	#If the divisor fits into the dividend, it returns a 1, grabs the remainder of that number
	# then repeats from there. If not, it adds a zero to the dividend and tries again
	#v0= first sign, v1= first exponent, a0= first mantissa THE NUMERATOR
	#a1= second sign, a2= second exponent, a3= second mantissa THE DENOMINATOR
	# Will not be calling recombine_Fp, tis not needed
	
	addi $v1, $v1, 127	#put exponents back in biased
	addi $a2, $a2, 127
	
	#Four cases: #/#: normal division, #/0: Infinity, 0/#: 0, 0/0: NaN
	add $s1, $v1, $a0	#$s1 will be zero if op1 exp and fraction are zero	(DISREGARDS SIGN BIT because -0.0
	add $s2, $a2, $a3 	#$s2 will be zero if op2 exp and fraction are zero	 IS SAME AS +0.0)
	
	bnez $s1, div_op1_notZero
	bnez $s2, div_returnZero
		li $v0, 0x7FFFFFFF	#op1 == 0, op2 == 0, return NaN
		jr $ra			#NAN = sign 0, exp 1's, fraction 1's
	div_returnZero:		
		li $v0, 0		#op1 == 0, op2 == a number
		jr $ra			# 0/# == 0
	div_op1_notZero:
	bnez $s2, div_ops_notZero
		li $v0, 0x7F800000	#op1 == a number, op2 == 0
		jr $ra			#return INF (sign =0, exp = 1's, fraction = 1's)
	div_ops_notZero:
	
	# both are non zero numbers, do actual division
	xor $t6, $v0, $a1 	#getting new sign GOOD
	
	sub $t7, $v1, $a2 	#getting new exponent GOOD
	addi $t7, $t7, 127 	#putting bias in place
	
	#ori $a0, $a0,0x00800000 #add the implicit one to op1 fraction
	#ori $a3, $a3,0x00800000 #add the implicit one to op2 fraction
	sll $a3, $a3, 9		#shift only divisor (op2 fraction) to rightmost bit
	
	li $t9, 0	#quotient register
	li $t8, 0	#loop counter
	div_loop:
	bgtu $t8, 32, div_exit
	
	subu $a0, $a0, $a3	#remainder -= divisor
	
	sll  $t9, $t9, 1	#shift quotient left 1
		
	blez $a0, div_quo_gtZero	#answer if negative (in 2's comp) if leftmost bit is a 1
		addu $a0, $a0, $a3	#remainder += divisor	(restore from earlier)
		j div_endif		#set rightmost bit of quotient to 0 (by doing nothing)
	div_quo_gtZero:
		addi $t9, $t9, 1	#set rightmost bit of quotient to 1
	div_endif:
	
	srl $a3, $a3, 1		#shift divisor right by 1
	add $t8, $t8, 1		#increment counter
	j div_loop
	
	div_exit:
	
	srl $t9, $t9, 9		#shift remainder back 9 bits
	PRINT_HEX($t9)
	PRINT_NEWLINE
	
	#srl $a0, $t9, 9		#shift quotient back
	#put it back together
	sll $t6, $t6, 31	#sign bit to left-most bit
	or  $v0, $t9, $t6	#place sign bit and quotient
	
	sll $t7, $t7, 24	#shift exp to left-most, then shift back (so as onlt the correct 8 bits are set)(32-8=24)
	srl $t7, $t7, 1		#shift exp to proper place
	or  $v0, $v0, $t7	#place exponent in $v0
	jr $ra			#we done
#end div
####################################################################################################################################
get_fraction:
	#$a0 floating point number
	#returns $v0, the unsigned fractional part of a 32 bit floating point number
	#ie bit 0 to bit 22
	#does not add the implicit 1
	
	andi $v0, $a0, 0x007FFFFF	#clear unwanted bits
	
	jr $ra #return
#end get_fraction

####################################################################################################################################
get_exponent:
	#a0 floating point number
	#returns signed part of a 32 bit floating point number
	#bits 23 to 30
	#basically gets bits and subtracts 127 from them
	#remember this is 2^exponent, so the returned value wont be the same as 10^exponent
	
	andi $v0, $a0, 0x7F800000	#clear all bits except exponent part
	srl  $v0, $v0, 23		#shift exponent to right most bit
	sub  $v0, $v0, 127		#shift for biased
	
	jr $ra #return
#end get_exponent

####################################################################################################################################
get_sign:
	#a0 floating point number
	#returns the sign of a 32 bit floating point number (0 for positive, 1 for negative)
	#bit 31
	
	andi $v0, $a0, 0x80000000	#clear all bits except for sign bit
	srl  $v0, $v0, 31	

	jr $ra #return
#end get_sign

####################################################################################################################################
recombine_fp:
	#a0 sign bit
	#a1 exponent (8 bits) (signed, so will add 127 to it)
	#a2 mantissa (23 bits)
	#returns IEEE 754 single precision FP number from given parts in $v0
	
	li $v0, 0	#set $v0 to 0
	addi $a1, $a1, 127	#shift exponent to biased
	
	sll $a0, $a0, 31	#sign bit to left-most bit
	or  $v0, $v0, $a0	#place sign bit in $v0
	
	sll $a1, $a1, 24	#shift exp to left-most, then shift back (so as onlt the correct 8 bits are set)(32-8=24)
	srl $a1, $a1, 1		#shift exp to proper place
	or  $v0, $v0, $a1	#place exponent in $v0
	
	sll $a2, $a2, 9		#shift mantissa to cut off any higher order bits
	srl $a2, $a2, 9		#shift to proper place
	or $v0, $v0, $a2	#place mantissa in $v0
	
	jr $ra #return
#end recombine_fp
####################################################################################################################################
