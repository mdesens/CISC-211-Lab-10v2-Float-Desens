/*******************************************************************************
  Main Source File

  Company:
    Microchip Technology Inc.

  File Name:
    main.c

  Summary:
    This file contains the "main" function for a project. It is intended to
    be used as the starting point for CISC-211 Curiosity Nano Board
    programming projects. After initializing the hardware, it will
    go into a 0.5s loop that calls an assembly function specified in a separate
    .s file. It will print the iteration number and the result of the assembly 
    function call to the serial port.
    As an added bonus, it will toggle the LED on each iteration
    to provide feedback that the code is actually running.
  
    NOTE: PC serial port should be set to 115200 rate.

  Description:
    This file contains the "main" function for a project.  The
    "main" function calls the "SYS_Initialize" function to initialize the state
    machines of all modules in the system
 *******************************************************************************/

// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************

#include <stdio.h>
#include <stddef.h>                     // Defines NULL
#include <stdbool.h>                    // Defines true
#include <stdlib.h>                     // Defines EXIT_FAILURE
#include <string.h>
#include <float.h>
#include "definitions.h"                // SYS function prototypes
#include "printFuncs.h"  // lab print funcs
#include "testFuncs.h"  // lab test funcs

#include "asmExterns.h"  // references to data defined in asmFloat.s

/* RTC Time period match values for input clock of 1 KHz */
#define PERIOD_50MS                             51
#define PERIOD_500MS                            512
#define PERIOD_1S                               1024
#define PERIOD_2S                               2048
#define PERIOD_4S                               4096

#define MAX_PRINT_LEN 1000

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


static volatile bool isRTCExpired = false;
static volatile bool changeTempSamplingRate = false;
static volatile bool isUSARTTxComplete = true;
static uint8_t uartTxBuffer[MAX_PRINT_LEN] = {0};

// static char * pass = "PASS";
// static char * fail = "FAIL";
// static char * oops = "OOPS";

// Assembly function signature
// For this lab, return the larger of the two floating point values passed in.
// Note to profs:
// The floats are being reinterpreted as uints so that they get passed to assy
// in r0 and r1. Otherwise, C forces them to be passed in the fp registers
// s0 and s1
extern float * asmFmax(uint32_t, uint32_t);


// STUDENTS: To test a single test case,
//           set debug_mode to true
//           set debug_testcase to the test case you want to test.
bool     debug_mode = false;
uint32_t debug_testcase = 0;

static float tc[][2] = { // DO NOT MODIFY THESE!!!!!
    {   1.175503179e-38, 1.10203478208e-38 },  //  Test case 0
    {    -0.2,                 -0.1},          //  Test case 1
    {     1.0,                  2.0},          //  TC #2
    {    -3.1,                  -1.2},         //  TC #3
    {    -7.25,                 -6.5},         //  TC #4
    {     NAN,                  1.0},          //  TC #5
    {    -1.0,                  NAN},          //  TC #6
    {     0.1,                  0.99},         //  TC #7
    {     1.14437421182e-28,   785.066650391}, //  TC #8
    { -4000.1,                   0.0,},        //  TC #9
    {    -1.9e-5,               -1.9e-5},      //  TC #10
    {     1.347e10,              2.867e-10},   //  TC #11

    // PROF NOTE: Check subnormals: they seem to generate 0x00000000 as inputs
    // PROF ADDENDUM 4/16/2024: Turns out some compilers and/or hardware convert
    // subnormal numbers to 0. See:
    // "Disabling subnormal floats at the code level"
    // https://en.wikipedia.org/wiki/Subnormal_number
    //
    // Student's code should see these values as 0 and process accordingly
    
    {     1.4e-42,              -3.2e-43},     // subnormals   TC #12
    {     -2.4e-42,              2.313e29},    // subnormals   TC #13
    {    INFINITY,           NEG_INFINITY},    //  TC #14
    {    NEG_INFINITY,           -6.24},       //  TC #15
    {     1.0,                   0.0}          //  TC #16
};

#define USING_HW 1

#if USING_HW
static void rtcEventHandler (RTC_TIMER32_INT_MASK intCause, uintptr_t context)
{
    if (intCause & RTC_MODE0_INTENSET_CMP0_Msk)
    {            
        isRTCExpired    = true;
    }
}
static void usartDmaChannelHandler(DMAC_TRANSFER_EVENT event, uintptr_t contextHandle)
{
    if (event == DMAC_TRANSFER_EVENT_COMPLETE)
    {
        isUSARTTxComplete = true;
    }
}
#endif

static void blinkAndLoopForever(uint32_t delay)
{
    RTC_Timer32Compare0Set(delay); // set blink period to specified delay
    RTC_Timer32CounterSet(0); // reset timer to start at 0
    isRTCExpired = false;

    while(1)
    {
        isRTCExpired = false;
        LED0_Toggle();
        while (isRTCExpired == false); // wait here until timer expires
    }

}


// *****************************************************************************
// *****************************************************************************
// Section: Main Entry Point
// *****************************************************************************
// *****************************************************************************
int main ( void )
{
    
 
#if USING_HW
    /* Initialize all modules */
    SYS_Initialize ( NULL );
    DMAC_ChannelCallbackRegister(DMAC_CHANNEL_0, usartDmaChannelHandler, 0);
    RTC_Timer32CallbackRegister(rtcEventHandler, 0);
    RTC_Timer32Compare0Set(PERIOD_50MS);
    RTC_Timer32CounterSet(0);
    RTC_Timer32Start();

#else // using the simulator
    isRTCExpired = true;
    isUSARTTxComplete = true;
#endif //SIMULATOR

    int32_t passCount = 0;
    int32_t failCount = 0;
    int32_t totalPassCount = 0;
    int32_t totalFailCount = 0;
    int32_t totalTestCount = 0;
    int iteration = 0;   
    int maxIterations = sizeof(tc)/sizeof(tc[0]);
    
    while ( true )
    {
        if (isRTCExpired == true)
        {
            isRTCExpired = false;
            
            LED0_Toggle();
            
            // Set to true if you want to force specific values for debugging
            if (false)
            {
                tc[iteration][0] = reinterpret_uint_to_float(0x0080003F);
                tc[iteration][1] = reinterpret_uint_to_float(0x000FFF3F);
            }
            
            // if you try to pass floats as floats to assy, they get put
            // into s0,s1, etc registers. So need to fool C into thinking
            // 32b ints are being passed instead, so that args are passed
            // in r0 and r1
            uint32_t ff0 = reinterpret_float_to_uint(tc[iteration][0]);
            uint32_t ff1 = reinterpret_float_to_uint(tc[iteration][1]);
            
            // Place to store the result of the call to the assy function
            float *max;
            
            // check to see if in debug mode and this is the testcase to debug,
            // or if we are in normal test mode and running all test cases.
            // If either is true, execute the test.
            if ( (debug_mode == false) ||
                 (debug_mode == true && debug_testcase == iteration) )
            {
                // Make the call to the assembly function
                max = asmFmax(ff0,ff1);

                testResult(iteration,tc[iteration][0],tc[iteration][1],
                        max,
                        &fMax,
                        &passCount,
                        &failCount,
                        &isUSARTTxComplete);
                totalPassCount += passCount;        
                totalFailCount += failCount;        
                totalTestCount += failCount + passCount;
                if (debug_mode == true)
                {
                    break;
                }
            }
            ++iteration;
            
            // check to see if in debug mode and this was the debug testcase,
            // or if we are in normal test mode and have completed all tests.
            // If either is true, exit the test loop.
            if (iteration >= maxIterations)
            {
                break; // tally the results and end program
            }

        }
    }

#if USING_HW
    static char * t1 = "ALL TESTS COMPLETE!";
    static char * t2 = "DEBUG MODE RESULT! IGNORE SCORE.";
    char * testString = t1;
    if (debug_mode == true)
    {
        testString = t2;
    }

    snprintf((char*)uartTxBuffer, MAX_PRINT_LEN,
            "========= %s: asmFmax.s %s\r\n"
            "tests passed: %ld \r\n"
            "tests failed: %ld \r\n"
            "total tests:  %ld \r\n"
            "score: %ld/20 points \r\n\r\n",
            (char *) nameStrPtr, testString,
            totalPassCount,
            totalFailCount,
            totalTestCount,
            20*totalPassCount/totalTestCount); 
            isUSARTTxComplete = false;
    
    printAndWait((char*)uartTxBuffer,&isUSARTTxComplete);

    blinkAndLoopForever(PERIOD_1S);

#else
            isRTCExpired = true;
            isUSARTTxComplete = true;
            if (iteration >= maxIterations)
            {
                break; // end program
            }

            continue;
#endif

    
    /* Execution should not come here during normal operation */

    return ( EXIT_FAILURE );
}
/*******************************************************************************
 End of File
*/

