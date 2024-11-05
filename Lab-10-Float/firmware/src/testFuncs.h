/* ************************************************************************** */
/** Descriptive File Name

  @Company
    Company Name

  @File Name
    filename.h

  @Summary
    Brief description of the file.

  @Description
    Describe the purpose of this file.
 */
/* ************************************************************************** */

#ifndef _TEST_FUNCS_H    /* Guard against multiple inclusion */
#define _TEST_FUNCS_H


/* ************************************************************************** */
/* ************************************************************************** */
/* Section: Included Files                                                    */
/* ************************************************************************** */
/* ************************************************************************** */

/* This section lists the other files that are included in this file.
 */

/* TODO:  Include other files here if needed. */


/* Provide C++ Compatibility */
#ifdef __cplusplus
extern "C" {
#endif


    /* ************************************************************************** */
    /* ************************************************************************** */
    /* Section: Constants                                                         */
    /* ************************************************************************** */
    /* ************************************************************************** */

    /*  A brief description of a section can be given directly below the section
        banner.
     */


    /* ************************************************************************** */
    /** Descriptive Constant Name

      @Summary
        Brief one-line summary of the constant.
    
      @Description
        Full description, explaining the purpose and usage of the constant.
        <p>
        Additional description in consecutive paragraphs separated by HTML 
        paragraph breaks, as necessary.
        <p>
        Type "JavaDoc" in the "How Do I?" IDE toolbar for more information on tags.
    
      @Remarks
        Any additional remarks
     */
// #define EXAMPLE_CONSTANT 0


#define PLUS_INF ((0x7F800000))
#define NEG_INF  ((0xFF800000))
#define NAN_MASK  (~NEG_INF)

#ifndef NAN
#define NAN ((0.0/0.0))
#endif

#ifndef INFINITY
#define INFINITY ((1.0f/0.0f))
#define NEG_INFINITY ((-1.0f/0.0f))
#endif


    // *****************************************************************************
    // *****************************************************************************
    // Section: Data Types
    // *****************************************************************************
    // *****************************************************************************


    // *****************************************************************************

    /** Descriptive Data Type Name

      @Summary
        Brief one-line summary of the data type.
    
      @Description
        Full description, explaining the purpose and usage of the data type.
        <p>
        Additional description in consecutive paragraphs separated by HTML 
        paragraph breaks, as necessary.
        <p>
        Type "JavaDoc" in the "How Do I?" IDE toolbar for more information on tags.

      @Remarks
        Any additional remarks
        <p>
        Describe enumeration elements and structure and union members above each 
        element or member.
     */
typedef struct _expectedValues
{
    float floatVal;
    uint32_t intVal;
    uint32_t signBit;
    uint32_t biasedExp;
    int32_t unbiasedExp; // adjusted to -126 wen -127 and not 
    uint32_t  mantissa; // adjusted to have hidden bit when appropriate
} expectedValues;

    

    // *****************************************************************************
    // *****************************************************************************
    // Section: Interface Functions
    // *****************************************************************************
    // *****************************************************************************

    /*  A brief description of a section can be given directly below the section
        banner.
     */

    // *****************************************************************************
    /**
      @Function
        int ExampleFunctionName ( int param1, int param2 ) 

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
uint32_t reinterpret_float_to_uint(float f);

// Allows easy conversion of a bit pattern to its equivalent float value
// More modern C standards support these conversions, but I don't think
// the MPLABS compiler does. At least, I couldn't make it work. --VB
float reinterpret_uint_to_float(uint32_t ui);


void calcExpectedValues(
        float input, // test number
        expectedValues *e);   // ptr to struct where values will be stored


void testResult(int testNum, 
                      float testVal1, // val passed to asm in r0
                      float testVal2, // val passed to asm in r1
                      float*pResult, // pointer to max chosen by asm code
                      float *pGood, //ptr to correct location
                      int32_t* passCnt,
                      int32_t* failCnt,
                      volatile bool * txComplete);


    /* Provide C++ Compatibility */
#ifdef __cplusplus
}
#endif

#endif /* _TEST_FUNCS_H */

/* *****************************************************************************
 End of File
 */
