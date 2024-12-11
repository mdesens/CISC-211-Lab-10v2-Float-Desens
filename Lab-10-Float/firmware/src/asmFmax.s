/*** asmFmax.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data  
.align

@ Define the globals so that the C code can access them

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Mark Desens"  
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
@ use these locations to store f0 values
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
@ use these locations to store f1 values
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
@ use these locations to store fMax values
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to push and pop! */

    // save the caller registers, as required by the ARM calling convention
    push {r4-r11,LR}
    
    // initialize all f0 variables to 0
    ldr r0, =f0
    mov r1, 0
    str r1, [r0]
    ldr r0, =sb0
    str r1, [r0]
    ldr r0, =storedExp0
    str r1, [r0]
    ldr r0, =realExp0
    str r1, [r0]
    ldr r0, =mant0
    str r1, [r0]

    // initialize all f1 variables to 0
    ldr r0, =f1
    str r1, [r0]
    ldr r0, =sb1
    str r1, [r0]
    ldr r0, =storedExp1
    str r1, [r0]
    ldr r0, =realExp1
    str r1, [r0]
    ldr r0, =mant1
    str r1, [r0]

    // initialize all fMax variables to 0
    ldr r0, =fMax
    str r1, [r0]
    ldr r0, =sbMax
    str r1, [r0]
    ldr r0, =storedExpMax
    str r1, [r0]
    ldr r0, =realExpMax
    str r1, [r0]
    ldr r0, =mantMax
    str r1, [r0]
    
    /* Restore the caller's registers, as required by the ARM calling convention */
    pop {r4-r11,LR}

    /* asmIsInf return to caller */    
    mov pc, lr  

    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to push and pop! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to push and pop! */

    // save the caller registers, as required by the ARM calling convention
    push {r4-r11,LR}
    
    // load the input value into r4
    ldr r4, [r0]

    // default the sign bit to 0 (positive)
    mov r1, 0

    // Check the value in r4 to determine if f* is positive or negative
    cmn r4, 0                   // 1 if the sign bit is negative, 0 if the sign bit is positive
    beq continue_processing     // if the value in r1 is 0, the sign bit is positive, so no special handling is needed

    handle_negative_value:
    // Handle the case where the value is 0xFFFFFFFF (signed -1)
    mov r1, -1                  // Move -1 into r1, since r1 contains the ouptut value for the function

    continue_processing:
    /* Restore the caller's registers, as required by the ARM calling convention */
    pop {r4-r11,LR}

    /* asmIsInf return to caller */    
    mov pc, lr  

    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to push and pop! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function doesn't
                check for +/-Inf or +/-0, so r1 always contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to push and pop! */

    // save the caller registers, as required by the ARM calling convention
    push {r4-r11,LR}
    
    // mask the input value to extract the stored exponent
    ldr r4, =0x7F800000     // 0x7F800000 is the 32-bit representation of the stored exponent mask
    and r0, r0, r4          // mask the input value to extract the stored exponent
    lsr r0, r0, 23         // shift the stored exponent bits into the lower 8 bits of r0

    // calculate the real exponent
    mov r1, 127             // 127 is the bias for the stored exponent
    sub r1, r1, r0          // calculate the real exponent by subtracting the bias from the stored exponent
    
    /* Restore the caller's registers, as required by the ARM calling convention */
    pop {r4-r11,LR}

    /* asmIsInf return to caller */    
    mov pc, lr  

    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to push and pop! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to push and pop! */

    // save the caller registers, as required by the ARM calling convention
    push {r4-r11,LR}
    
    // mask the input value to extract the mantissa
    ldr r0, [r0]            // load the input value into r0
    ldr r1, =0x007FFFFF     // 0x007FFFFF is the 32-bit representation of the mantissa mask
    and r0, r0, r1          // mask the input value to extract the mantissa without the implied 1 bit

    // set the implied 1 bit in the mantissa
    ldr r1, =0x00800000     // 0x00800000 is the 32-bit representation of the implied 1 bit
    orr r1, r1, r0          // set the implied 1 bit in the mantissa

    /* Restore the caller's registers, as required by the ARM calling convention */
    pop {r4-r11,LR}

    /* asmIsInf return to caller */    
    mov pc, lr  
    
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to push and pop! */

    // save the caller registers, as required by the ARM calling convention
    push {r4-r11,LR}

    // compare the input value to the positive zero value
    ldr r0, [r0]            // load the input value into r0
    ldr r1, =0x00000000      // 0x00000000 is the 32-bit representation of positive zero
    cmp r0, r1              // compare the input value to the positive zero value
    beq is_positive_zero    // if the input value is positive zero, return 1

    // compare the input value to the negative zero value
    ldr r1, =0x80000000      // 0x80000000 is the 32-bit representation of negative zero
    cmp r0, r1              // compare the input value to the negative zero value
    beq is_negative_zero    // if the input value is negative zero, return -1

    // if the input value is not zero, return 0
    mov r0, 0
    b restore_registers     // restore the caller registers and return to the caller

is_positive_zero:
    // if the input value is positive zero, return 1
    mov r0, 1
    b restore_registers     // restore the caller registers and return to the caller

is_negative_zero:
    // if the input value is negative zero, return -1
    mov r0, -1

restore_registers_is_zero:
    /* Restore the caller's registers, as required by the ARM calling convention */
    pop {r4-r11,LR}

    /* asmIsInf return to caller */    
    mov pc, lr  
    
    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to push and pop! */

    // save the caller registers, as required by the ARM calling convention
    push {r4-r11,LR}

    // compare the input value to the positive infinity value
    ldr r0, [r0]            // load the input value into r0
    ldr r1, =0x7F800000      // 0x7F800000 is the 32-bit representation of positive infinity
    cmp r0, r1              // compare the input value to the positive infinity value
    beq is_positive_inf     // if the input value is positive infinity, return 1

    // compare the input value to the negative infinity value
    ldr r1, =0xFF800000      // 0xFF800000 is the 32-bit representation of negative infinity
    cmp r0, r1
    beq is_negative_inf

    // if the input value is not infinity, return 0
    mov r0, 0
    b restore_registers_inf

    // if the input value is positive infinity, return 1
    is_positive_inf:
    mov r0, 1
    b restore_registers_inf

    // if the input value is negative infinity, return -1
    is_negative_inf:
    mov r0, -1

    /* Restore the caller's registers, as required by the ARM calling convention */
    restore_registers_inf:
    pop {r4-r11,LR}

    /* asmIsInf return to caller */    
    mov pc, lr  

    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */

    // save the caller registers, as required by the ARM calling convention
    push {r4-r11,LR}

    // call the initVariables function to initialize all variables to 0
    bl initVariables        

set_f0_and_f1:
    // unpack the f0 value
    ldr r4, =f0             // load the address of f0 into r4
    str r0, [r4]            // store the f0 (param) value in f0 (global)

    // unpack the f1 value
    ldr r4, =f1             // load the address of f1 into r4
    str r1, [r4]            // store the f1 (param) value in f1 (global)

// check if the f0 value equals +/- infinity using asmIsInf
is_f0_inf:
    ldr r0, =f0		        // load the address of f0 into r0, since asmIsInf uses r0 to access the value of f0
    bl asmIsInf             // call the asmIsInf function
    cmp r0, 0               // compare the result of asmIsInf to 0
    bgt f0_is_greater       // if the value is positive infinity, the other number must be equal or smaller
    blt f1_is_greater       // if the value is negative infinity, the other number must be equal or larger

// check if the f1 value equals +/- infinity using asmIsInf
is_f1_inf:
    ldr r0, =f1             // load the address of f1 into r0, since asmIsInf uses r0 to access the value of f1
    bl asmIsInf             // call the asmIsInf function
    cmp r0, 0               // compare the result of asmIsInf to 0
    bgt f1_is_greater       // if the value is positive infinity, the other number must be equal or smaller
    blt f0_is_greater       // if the value is negative infinity, the other number must be equal or larger

// unpack the sign bit of f0 using getSignBit
get_sign_bit_f0:
    ldr r0, =f0             // load the address of f0 into r0
    bl getSignBit           // call the getSignBit function
    ldr r4, =sb0            // load the address of sb0 into r5
    ldr r5, [r0]            // load the sign bit of f0 (returned from getSignBit in r1) into r5
    str r5, [r4]            // store the sign bit of f0 in sb0

// unpack the sign bit of f1 using getSignBit
get_sign_bit_f1:
    ldr r0, =f1             // load the address of f1 into r0
    bl getSignBit           // call the getSignBit function
    ldr r4, =sb1            // load the address of sb1 into r5
    ldr r5, [r0]            // load the sign bit of f1 (returned from getSignBit in r1) into r5
    str r5, [r4]            // store the sign bit of f1 in sb1

// compare the sign bits of f0 and f1 to determine the sign bit of fMax and potentially which is the largest float if signs differ
set_sign_bit_max:
    // get the sign bit of f0
    ldr r4, =sb0            // load the address of sb0 into r4
    ldr r4, [r4]            // load the sign bit of f0 into r4
    ldr r5, =sb1            // load the address of sb1 into r5
    ldr r5, [r5]            // load the sign bit of f1 into r5
    cmp r4, r5              // compare the sign bits of f0 and f1
    bgt f0_is_greater      // if the sign bit of f0 is positive, the sign bit of fMax is positive and f0 is greater
    blt f1_is_greater      // if the sign bit of f1 is positive, the sign bit of fMax is positive and f1 is greater

// unpack the stored exponent of f0 using getExponent
get_stored_exp_f0:
    ldr r0, =f0             // load the address of f0 into r0, since getExponent uses r0 to access the value of f0
    bl getExponent          // call the getExponent function
    ldr r4, =storedExp0     // load the address of storedExp0 into r4
    str r0, [r4]            // store the stored exponent of f0 in storedExp0
    ldr r4, =realExp0       // load the address of realExp0 into r4
    str r1, [r4]            // store the real exponent of f0 in realExp0

// unpack the stored exponent of f1 using getExponent
get_stored_exp_f1:
    ldr r0, =f1             // load the address of f1 into r0, since getExponent uses r0 to access the value of f1
    bl getExponent          // call the getExponent function
    ldr r5, =storedExp1     // load the address of storedExp1 into r5
    str r0, [r5]            // store the stored exponent of f1 in storedExp1
    ldr r5, =realExp1       // load the address of realExp1 into r5
    str r1, [r5]            // store the real exponent of f1 in realExp1

// compare the real exponents of f0 and f1 to determine the real exponent of fMax and potentially which is the largest float
set_real_exp_max:
    // get the real exponent of f0 (performing again in case code changes)
    ldr r4, =realExp0       // load the address of realExp0 into r4
    ldr r4, [r4]            // load the real exponent of f0 into r4
    // get the real exponent of f1
    ldr r5, =realExp1       // load the address of realExp1 into r5
    ldr r5, [r5]            // load the real exponent of f1 into r5
    // compare the real exponents of f0 and f1
    cmp r4, r5              
    bgt f0_is_greater       // if the real exponent of f0 is greater, the real exponent of fMax is the real exponent of f0 and f0 is greater
    blt f1_is_greater       // if the real exponent of f1 is greater, the real exponent of fMax is the real exponent of f1 and f1 is greater

// unpack the mantissa of f0 using getMantissa
get_mantissa_f0:
    ldr r0, =f0             // load the address of f0 into r0, since getMantissa uses r0 to access the value of f0
    bl getMantissa          // call the getMantissa function
    ldr r4, =mant0          // load the address of mant0 into r4
    str r1, [r4]            // store the mantissa with implied bit of f0 in mant0

// unpack the mantissa of f1 using getMantissa
get_mantissa_f1:
    ldr r0, =f1             // load the address of f1 into r0, since getMantissa uses r0 to access the value of f1
    bl getMantissa          // call the getMantissa function
    ldr r4, =mant1          // load the address of mant1 into r4
    str r1, [r4]            // store the mantissa with implied bit of f1 in mant1

// compare the mantissas of f0 and f1 to determine the mantissa of fMax and potentially which is the largest float
set_mant_max:
    // get the mantissa of f0 (performing again in case code changes)
    ldr r4, =mant0          // load the address of mant0 into r4
    ldr r4, [r4]            // load the mantissa with implied bit of f0 into r4
    // get the mantissa of f1
    ldr r5, =mant1          // load the address of mant1 into r5
    ldr r5, [r5]            // load the mantissa with implied bit of f1 into r5
    // compare the mantissas of f0 and f1
    cmp r4, r5
    bgt f0_is_greater       // if the mantissa of f0 is greater, the mantissa of fMax is the mantissa of f0 and f0 is greater
    blt f1_is_greater       // if the mantissa of f1 is greater, the mantissa of fMax is the mantissa of f1 and f1 is greater

f0_is_greater:
    // store the greater value in fMax
    ldr r4, =fMax           // load the address of fMax into r1
    ldr r5, =f0             // load the address of f0 into r5
    ldr r5, [r5]            // load the f0 value into r0
    str r5, [r4]            // store the greater value in fMax
    ldr r0, =fMax           // load the address of fMax into r0
    // store the sign bit of the greater value in signBitMax
    ldr r4, =sb0            // load the address of sb0 into r4
    ldr r4, [r4]            // load the sign bit of f0 into r4
    ldr r5, =sbMax          // load the address of sbMax into r5
    str r4, [r5]            // store the sign bit of the greater value in sbMax
    // store the stored exponent of the greater value in storedExpMax
    ldr r4, =storedExp0     // load the address of storedExp0 into r4
    ldr r4, [r4]            // load the stored exponent of f0 into r4
    ldr r5, =storedExpMax   // load the address of storedExpMax into r5
    str r4, [r5]            // store the stored exponent of the greater value in storedExpMax
    // store the real exponent of the greater value in realExpMax
    ldr r4, =realExp0       // load the address of realExp0 into r4
    ldr r4, [r4]            // load the real exponent of f0 into r4
    ldr r5, =realExpMax     // load the address of realExpMax into r5
    str r4, [r5]            // store the real exponent of the greater value in realExpMax
    // store the mantissa of the greater value in mantMax
    ldr r4, =mant0          // load the address of mant0 into r4
    ldr r4, [r4]            // load the mantissa with implied bit of f0 into r4
    ldr r5, =mantMax        // load the address of mantMax into r5
    str r4, [r5]            // store the mantissa of the greater value in mantMax
    // restore the caller registers and return to the caller
    b restore_registers     

f1_is_greater:
    // store the greater value in fMax
    ldr r4, =fMax           // load the address of fMax into r1
    ldr r5, =f1             // load the address of f1 into r5
    ldr r5, [r5]            // load the f1 value into r0
    str r5, [r4]            // store the greater value in fMax
    ldr r0, =fMax           // load the address of fMax into r0
    // store the sign bit of the greater value in signBitMax
    ldr r4, =sb1            // load the address of sb1 into r4
    ldr r4, [r4]            // load the sign bit of f1 into r4
    ldr r5, =sbMax          // load the address of sbMax into r5
    str r4, [r5]            // store the sign bit of the greater value in sbMax
    // store the stored exponent of the greater value in storedExpMax
    ldr r4, =storedExp1     // load the address of storedExp1 into r4
    ldr r4, [r4]            // load the stored exponent of f1 into r4
    ldr r5, =storedExpMax   // load the address of storedExpMax into r5
    str r4, [r5]            // store the stored exponent of the greater value in storedExpMax
    // store the real exponent of the greater value in realExpMax
    ldr r4, =realExp1       // load the address of realExp1 into r4
    ldr r4, [r4]            // load the real exponent of f1 into r4
    ldr r5, =realExpMax     // load the address of realExpMax into r5
    str r4, [r5]            // store the real exponent of the greater value in realExpMax
    // store the mantissa of the greater value in mantMax
    ldr r4, =mant1          // load the address of mant1 into r4
    ldr r4, [r4]            // load the mantissa with implied bit of f1 into r4
    ldr r5, =mantMax        // load the address of mantMax into r5 
    str r4, [r5]            // store the mantissa of the greater value in mantMax
    // restore the caller registers and return to the caller
    b restore_registers     // not needed, but included for consistency and in case of future changes

restore_registers:
    /* Restore the caller's registers, as required by the ARM calling convention */
    pop {r4-r11,LR}

    /* asmIsInf return to caller */    
    mov pc, lr      
    
    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */
   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



