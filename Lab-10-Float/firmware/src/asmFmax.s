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
    
    // mask the input value to extract the sign bit
    ldr r1, =0x80000000     // 0x80000000 is the 32-bit representation of the sign bit
    ldr r2, [r0]            // load the input value into r2
    and r2, r2, r1          // mask the input value to extract the sign bit
    lsr r2, r2, 31          // shift the sign bit into the lower bit of r2
    str r2, [r1]            // store the sign bit in the memory location given by r1
    
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
    ldr r1, =0x7F800000     // 0x7F800000 is the 32-bit representation of the stored exponent mask
    and r0, r0, r1          // mask the input value to extract the stored exponent
    lsr r0, r0, #23         // shift the stored exponent bits into the lower 8 bits of r0
    
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
    ldr r1, =0x007FFFFF     // 0x007FFFFF is the 32-bit representation of the mantissa mask
    and r0, r0, r1          // mask the input value to extract the mantissa

    // set the implied 1 bit in the mantissa
    ldr r1, =0x00800000     // 0x00800000 is the 32-bit representation of the implied 1 bit
    orr r1, r1, r0          // set the implied 1 bit in the mantissa
    mov r0, r1              // store the mantissa with the implied 1 bit in r0

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
    ldr r1, =0x7F800000      // 0x7F800000 is the 32-bit representation of positive infinity
    ldr r1, [r1]
    cmp r0, r1              // compare the input value to the positive infinity value
    beq is_positive_inf     // if the input value is positive infinity, return 1

    // compare the input value to the negative infinity value
    ldr r1, =0xFF800000      // 0xFF800000 is the 32-bit representation of negative infinity
    cmp r0, r1
    beq is_negative_inf

    // if the input value is not infinity, return 0
    mov r0, 0
    b restore_registers_inf

is_positive_inf:
    // if the input value is positive infinity, return 1
    mov r0, 1
    b restore_registers_inf

is_negative_inf:
    // if the input value is negative infinity, return -1
    mov r0, -1

restore_registers_inf:
    /* Restore the caller's registers, as required by the ARM calling convention */
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

    // unpack the f0 value
    ldr r0, [r0]            // load the f0 value into r0
    bl getSignBit           // get the sign bit of f0
    ldr r1, =sbMax          // load the address of sbMax into r1
    str r0, [r1]            // store the sign bit of f0 in sbMax
    bl getExponent          // get the stored exponent of f0
    ldr r1, =storedExpMax   // load the address of storedExpMax into r1
    str r0, [r1]            // store the stored exponent of f0 in storedExpMax
    sub r0, r0, #127        // adjust the stored exponent of f0 to get the real exponent
    ldr r1, =realExpMax     // load the address of realExpMax into r1
    str r0, [r1]            // store the real exponent of f0 in realExpMax
    bl getMantissa          // get the mantissa of f0
    ldr r1, =mantMax        // load the address of mantMax into r1
    str r0, [r1]            // store the mantissa of f0 in mantMax

    // unpack the f1 value
    ldr r0, [r1]            // load the f1 value into r0
    bl getSignBit           // get the sign bit of f1
    ldr r1, =sbMax          // load the address of sbMax into r1
    str r0, [r1]            // store the sign bit of f1 in sbMax
    bl getExponent          // get the stored exponent of f1
    ldr r1, =storedExpMax   // load the address of storedExpMax into r1
    str r0, [r1]            // store the stored exponent of f1 in storedExpMax
    sub r0, r0, #127        // adjust the stored exponent of f1 to get the real exponent
    ldr r1, =realExpMax     // load the address of realExpMax into r1
    str r0, [r1]            // store the real exponent of f1 in realExpMax
    bl getMantissa          // get the mantissa of f1
    ldr r1, =mantMax        // load the address of mantMax into r1
    str r0, [r1]            // store the mantissa of f1 in mantMax

    // compare the f0 and f1 values
    ldr r0, =f0             // load the address of f0 into r0
    ldr r0, [r0]            // load the f0 value into r0
    ldr r1, =f1             // load the address of f1 into r1
    ldr r1, [r1]            // load the f1 value into r1
    cmp r0, r1              // compare the f0 and f1 values
    bge f0_is_greater       // if f0 is greater than or equal to f1, return f0
    ldr r0, =f1             // load the address of f1 into r0
    ldr r0, [r0]            // load the f1 value into r0
    
f0_is_greater:
    // store the greater value in fMax
    ldr r1, =fMax           // load the address of fMax into r1
    str r0, [r1]            // store the greater value in fMax

restore_registers:
    /* Restore the caller's registers, as required by the ARM calling convention */
    pop {r4-r11,LR}

    /* asmIsInf return to caller */    
    mov pc, lr      
    
    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



