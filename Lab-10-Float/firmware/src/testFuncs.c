/* ************************************************************************** */
/** Descriptive File Name

  @Company
    Company Name

  @File Name
    filename.c

  @Summary
    Brief description of the file.

  @Description
    Describe the purpose of this file.
 */
/* ************************************************************************** */

/* ************************************************************************** */
/* ************************************************************************** */
/* Section: Included Files                                                    */
/* ************************************************************************** */
/* ************************************************************************** */

#include <stdio.h>
#include <stddef.h>                     // Defines NULL
#include <stdbool.h>                    // Defines true
#include <stdlib.h>                     // Defines EXIT_FAILURE
#include <string.h>
#include <malloc.h>
#include <inttypes.h>   // required to print out pointers using PRIXPTR macro
#include "definitions.h"                // SYS function prototypes
#include "testFuncs.h" // lab test structs
#include "printFuncs.h"  // lab print funcs

#include "asmExterns.h"  // references to data defined in asmFloat.s

#define MAX_PRINT_LEN 1000

static uint8_t txBuffer[MAX_PRINT_LEN] = {0};

static char * pass = "PASS";
static char * fail = "FAIL";
static char * oops = "OOPS";

/* ************************************************************************** */
/* ************************************************************************** */
/* Section: File Scope or Global Data                                         */
/* ************************************************************************** */
/* ************************************************************************** */

/*  A brief description of a section can be given directly below the section
    banner.
 */

/* ************************************************************************** */
/** Descriptive Data Item Name

  @Summary
    Brief one-line summary of the data item.
    
  @Description
    Full description, explaining the purpose and usage of data item.
    <p>
    Additional description in consecutive paragraphs separated by HTML 
    paragraph breaks, as necessary.
    <p>
    Type "JavaDoc" in the "How Do I?" IDE toolbar for more information on tags.
    
  @Remarks
    Any additional remarks
 */

/* ************************************************************************** */
/* ************************************************************************** */
// Section: Local Functions                                                   */
/* ************************************************************************** */
/* ************************************************************************** */

/*  A brief description of a section can be given directly below the section
    banner.
 */

/* ************************************************************************** */

/** 
  @Function
    int ExampleLocalFunctionName ( int param1, int param2 ) 

  @Summary
    Brief one-line description of the function.

  @Description
    Full description, explaining the purpose and usage of the function.
    <p>
    Additional description in consecutive paragraphs separated by HTML 
    paragraph breaks, as necessary.
    <p>
    Type "JavaDoc" in the "How Do I?" IDE toolbar for more information on tags.

  @Precondition
    List and describe any required preconditions. If there are no preconditions,
    enter "None."

  @Parameters
    @param param1 Describe the first parameter to the function.
    
    @param param2 Describe the second parameter to the function.

  @Returns
    List (if feasible) and describe the return values of the function.
    <ul>
      <li>1   Indicates an error occurred
      <li>0   Indicates an error did not occur
    </ul>

  @Remarks
    Describe any special behavior not described above.
    <p>
    Any additional remarks.

  @Example
    @code
    if(ExampleFunctionName(1, 2) == 0)
    {
        return 3;
    }
 */

// have to play games with data types to get floats to be passed in r0 and r1
// otherwise, assy needs to use VMOV instructions to move from s registers
// to r registers
// More modern C standards support these conversions, but I don't think
// the MPLABS compiler does. At least, I couldn't make it work. --VB
uint32_t reinterpret_float_to_uint(float f)
{
    float *pf = &f;
    void * pv = (void *) pf;
    uint32_t * pi = (uint32_t *) pv;
    return *pi;
}

// #if 0

// Allows easy conversion of a bit pattern to its equivalent float value
// More modern C standards support these conversions, but I don't think
// the MPLABS compiler does. At least, I couldn't make it work. --VB
float reinterpret_uint_to_float(uint32_t ui)
{
    uint32_t *pu = &ui;
    void * pv = (void *) pu;
    float * pf = (float *) pv;
    return *pf;
}
// #endif

// returns true for NaN
static bool isNan(float inpVal) 
{
    uint32_t iFloat;
    // reinterpret the float as 32b int so we can use bitwise operators
    iFloat = reinterpret_float_to_uint(inpVal);
    // check to see if exp bits are all 1, and mantissa is non-zero
    if((iFloat&PLUS_INF) == PLUS_INF &&
       (iFloat&NAN_MASK) != 0) {
        return true;
    }
    return false;
}

// returns +1 for +inf, -1 for -inf
static int isInf(float inpVal) 
{
    uint32_t iFloat;
    // reinterpret the float as 32b int so we can use bitwise operators
    iFloat = reinterpret_float_to_uint(inpVal);
    if(iFloat == PLUS_INF) {
        return 1;
    }
    else if (iFloat == NEG_INF) {
        return -1;
    }
    return 0;
}


static void check(int32_t in1, 
        int32_t in2, 
        int32_t *goodCount, 
        int32_t *badCount,
        char **pfString )
{
    if (in1 == in2)
    {
        *goodCount += 1;
        *pfString = pass;
    }
    else
    {
        *badCount += 1;
        *pfString = fail;        
    }
    return;
}

static void checkMax(expectedValues *e, 
        int32_t unpackedValue, 
        int32_t *goodCount, 
        int32_t *badCount,
        char **pfString )
{
    if(e->biasedExp == 255) // if NaN or +/-inf ignore mantissa
    {
        uint32_t val = e->intVal & 0xFF800000; // keep sign bit and exp
        uint32_t testVal = unpackedValue & 0xFF800000;
        check((int32_t)val,(int32_t)testVal,goodCount,badCount,pfString);         
    }
    else 
    {
        check((int32_t)e->intVal,unpackedValue,goodCount,badCount,pfString);
    }
    
    return;
}

static void checkMantissa(int32_t expectedMant, 
        int32_t unpackedMant, 
        uint32_t biasedExp,    // biased exponent
        int32_t *goodCount, 
        int32_t *badCount,
        char **pfString )
{
    // if NaN or +/- inf
    if(biasedExp == 255) // only check lower 23 bits of mantissa
    {
        expectedMant = expectedMant && 0x7FFFFF;
        unpackedMant = unpackedMant && 0x7FFFFF;
        // since for NaN technically any non-zero value is valid, allow it.
        if((expectedMant != 0 && unpackedMant != 0) || // Nan
           (expectedMant == 0 && unpackedMant == 0))   //+/- inf
        {
            *goodCount += 1;
            *pfString = pass;
        }
        else
        {
            *badCount += 1;
            *pfString = fail;        
        }
    }
    else if (expectedMant == unpackedMant) // compare all 23 bits + hidden bit
    {
        *goodCount += 1;
        *pfString = pass;
    }
    else
    {
        *badCount += 1;
        *pfString = fail;        
    }
    return;
}



/* ************************************************************************** */
/* ************************************************************************** */
// Section: Interface Functions                                               */
/* ************************************************************************** */
/* ************************************************************************** */

/*  A brief description of a section can be given directly below the section
    banner.
 */

// *****************************************************************************

/** 
  @Function
    int ExampleInterfaceFunctionName ( int param1, int param2 ) 

  @Summary
    Brief one-line description of the function.

  @Remarks
    Refer to the example_file.h interface header for function usage details.
 */

void calcExpectedValues(
        float input, // test number
        expectedValues *e)  // ptr to struct where values will be stored
{

    if (true == isNan(input)) // if NaN...
    {
        e->floatVal = NAN;
        e->intVal = reinterpret_float_to_uint(e->floatVal);
        e->biasedExp = 0xFF;
        e->unbiasedExp = 0xFF-127;
        e->signBit = e->intVal >> 31;
        e->mantissa = 0x7FFFFF; // It can be any non-0 value, we'll use all 1's.
    }
    else if (true == isInf(input))   // if +/- inf
    {
        e->floatVal = input;
        e->intVal = reinterpret_float_to_uint(e->floatVal);
        e->biasedExp = 0xFF;
        e->unbiasedExp = 0xFF-127;
        e->signBit = e->intVal >> 31; // could be +/- inf
        e->mantissa = 0x0;      // for +/- inf, this must be zero 
    }
    else // either subnormal or normal float, or +/- 0
    {
        e->floatVal = input;
        e->intVal = reinterpret_float_to_uint(e->floatVal);
        e->signBit = e->intVal >> 31; // could be +/- inf
        e->biasedExp = (e->intVal >>23) & 0xFF;
        e->unbiasedExp = e->biasedExp - 127;
        e->mantissa = e->intVal & 0x7FFFFF; // mask off LSB 23 bits
        if(e->unbiasedExp == -127) // then this is 0 or a subnormal number
        {
            // adjust to -126, and skip adding hidden bit to mantissa
            e->unbiasedExp = -126;
        }
        else // not subnormal; just a run-of-the-mill float...
        {
            // add hidden bit to mantissa
            e->mantissa = e->mantissa | 0x800000; // add  missing bit    
        }
    }
        
    return;
}

// Code to test student's asmIsZero function
void testZeroResult(int testNum, 
                      uint32_t testVal, // val passed to asm in r0
                      uint32_t result,  // asm code result
                      int32_t* passCnt,
                      int32_t* failCnt,
                      volatile bool * txComplete)
{
    int32_t expectedResult = 0;
    *passCnt = 0;
    *failCnt = 0;
    char * pfString; // pass/fail string
    
    // extract the expected result
    if (testVal == PLUS_ZERO)
    {
        expectedResult = 1;  // +0.0
    }
    else if (testVal == NEG_ZERO)
    {
        expectedResult = -1; // -0.0
    }
    
    // compare expected to actual and set pass/fail
    if (result == expectedResult)
    {
        *passCnt += 1;
        pfString = pass;
    }
    else
    {
        *failCnt += 1;
        pfString = fail;
    }
    
    snprintf((char*)txBuffer, MAX_PRINT_LEN,
        "========= asmIsZero Test Number: %d; %s\r\n"
        "hex input value:     0x%08lx\r\n"
        "expected asmIsZero result: %3ld\r\n"
        "actual   asmIsZero result: %3ld\r\n"
        "\r\n",
        testNum, pfString,
        testVal,
        expectedResult,
        result); 
    
    printAndWait((char*)txBuffer,txComplete);

    return;
}


// Code to test student's asmIsInf function
void testInfResult(int testNum, 
                      uint32_t testVal, // val passed to asm in r0
                      uint32_t result,  // asm code result
                      int32_t* passCnt,
                      int32_t* failCnt,
                      volatile bool * txComplete)
{
    int32_t expectedResult = 0;
    *passCnt = 0;
    *failCnt = 0;
    char * pfString; // pass/fail string
    
    // extract the expected result
    if (testVal == PLUS_INF)
    {
        expectedResult = 1;  // +Inf
    }
    else if (testVal == NEG_INF)
    {
        expectedResult = -1; // -Inf
    }
    
    // compare expected to actual and set pass/fail
    if (result == expectedResult)
    {
        *passCnt += 1;
        pfString = pass;
    }
    else
    {
        *failCnt += 1;
        pfString = fail;
    }
    
    snprintf((char*)txBuffer, MAX_PRINT_LEN,
        "========= asmIsInf Test Number: %d; %s\r\n"
        "hex input value:     0x%08lx\r\n"
        "expected asmIsInf result: %3ld\r\n"
        "actual   asmIsInf result: %3ld\r\n"
        "\r\n",
        testNum, pfString,
        testVal,
        expectedResult,
        result); 
    
    printAndWait((char*)txBuffer,txComplete);

    return;
}



void testMaxResult(int testNum, 
                      float testVal1, // val passed to asm in r0
                      float testVal2, // val passed to asm in r1
                      float *pResult, // pointer to max chosen by asm code
                      float *pGood, //ptr to correct location
                      int32_t* passCnt,
                      int32_t* failCnt,
                      volatile bool * txComplete)
{
    float asmResult = *pResult;
    uint32_t iMax = reinterpret_float_to_uint(fMax);

    // int asmInf = isInf(asmResult);  // did the asm code return +/- inf?
    // bool asmNan = isNan(asmResult); // did the asm code return NaN?
    int inp1Inf = isInf(testVal1);  // was test input 1 +/- inf?
    bool inp1Nan = isNan(testVal1); // was test input 1 NaN?
    int inp2Inf = isInf(testVal2);  // was test input 2 +/- inf?
    bool inp2Nan = isNan(testVal2); // was test input 1 NaN?
    
    expectedValues e;

    // place to store pass/fail strings
    char * ptrCheck = oops;
    char * maxCheck = oops;
    char * sbCheck = oops;
    char * biasedExpCheck = oops;
    char * unbiasedExpCheck = oops;
    char * mantCheck = oops;

    *passCnt = 0;
    *failCnt = 0;
    
    
    //int32_t  goodExponent = ((iGoodMax >>23) & 0xFF) - 127;
    //if goodExponent == -127
    //uint32_t goodMantissa = iGoodMax & 0x7FFFFF;

    // load the expected results struct with the expected answers
    if (inp1Nan || inp2Nan) // if either or both test inputs were NaN ...
    {
        calcExpectedValues(NAN, &e);
    }
    else if ((inp1Inf ==1) || (inp2Inf == 1)) // if either input was +inf
    {
        calcExpectedValues(INFINITY, &e);
    }
    else if (inp1Inf == -1) // if f1 was -inf, then assume f2 was max
    {
        if (inp2Inf == -1)
        {
            calcExpectedValues(NEG_INFINITY, &e); // could probably use testVal2 to simplify this...
        }
        else
        {
            calcExpectedValues(testVal2, &e);
        }
    }
    else if (inp2Inf == -1)  // else if f2 was -inf, then assume f1 was max
    {
        calcExpectedValues(testVal1, &e);
    }    
    else if(testVal1<testVal2) // else, check to see which was larger
    {
        calcExpectedValues(testVal2, &e);
    }
    else // either testVal1 is greater, or they are equal, or something is horribly wrong
    {
        calcExpectedValues(testVal1, &e);
    }    
    
    // test that the pointer returned by asmFmax points to global fMax
    check((int32_t)(&fMax),(int32_t)pResult,passCnt,failCnt,&ptrCheck);

    // check whether the right value was chosen
    checkMax(&e,(int32_t)iMax,passCnt,failCnt,&maxCheck);
    
    // check the unpacked values
    check(e.signBit,signBitMax,passCnt,failCnt,&sbCheck);
    check(e.biasedExp,storedExpMax,passCnt,failCnt,&biasedExpCheck);
    check(e.unbiasedExp,realExpMax,passCnt,failCnt,&unbiasedExpCheck);
    
    // if expMax is 255, needs special handling.
    // In that case, allow mantissa with or without hidden bit set.
    checkMantissa(e.mantissa,mantMax,e.biasedExp,passCnt,failCnt,&mantCheck);
       
    snprintf((char*)txBuffer, MAX_PRINT_LEN,
            "========= asmFmax Test Number: %d\r\n"
            "input1:       %8.4e; input2:     %8.4e \r\n"
            "hex inp1:     0x%08lx; hex inp2: 0x%08lx\r\n"
            "%s: expected max: %8.4e; asm result: %8.4e\r\n"
            "%s: pointer check: expected:  0x%" PRIXPTR "; actual: 0x%" PRIXPTR "\r\n"
            "%s: sign bit expected: %ld; actual: %ld\r\n"
            "%s: biased expnt expected:   %ld; actual: %ld\r\n"
            "%s: unbiased expnt expected: %ld; actual: %ld\r\n"
            "%s: mantissa expected: 0x%08lx; actual: 0x%08lx\r\n"
            "tests passed: %ld; tests failed: %ld \r\n"
            "\r\n",
            testNum,
            testVal1,testVal2,
            reinterpret_float_to_uint(testVal1),
            reinterpret_float_to_uint(testVal2),
            maxCheck,e.floatVal,asmResult,
            ptrCheck,(uintptr_t)(&fMax), (uintptr_t)pResult,
            sbCheck,e.signBit,signBitMax,
            biasedExpCheck,e.biasedExp,storedExpMax,
            unbiasedExpCheck,e.unbiasedExp,realExpMax,
            mantCheck,e.mantissa,mantMax,
            *passCnt,*failCnt); 
    
    printAndWait((char*)txBuffer,txComplete);
    
    return;
}




/* *****************************************************************************
 End of File
 */
