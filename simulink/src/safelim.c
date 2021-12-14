/*
 * safelim.c: C-S-function for limiting block (without the bug of the simulink
 *            saturation block of simulink versions 2 and 3.
 *
 *
 */

#define S_FUNCTION_LEVEL 2
#define S_FUNCTION_NAME  safelim

#include "simstruc.h"


/*====================*
 * S-function methods *
 *====================*/

static boolean_T IsRealScalar(const mxArray *m)
{
	if (mxIsNumeric(m) &&
			mxIsDouble(m) &&
			!mxIsLogical(m) &&
			!mxIsComplex(m) &&
			!mxIsSparse(m) &&
			!mxIsEmpty(m) &&
			mxGetNumberOfDimensions(m) == 2 &&
			mxGetNumberOfElements(m) == 1) {
	        
		real_T *data = mxGetPr(m);
		if (!mxIsFinite(data[0])) {
			return(0);
			}
		return(1);
		}
	else {
		return(0);
		}
}

/* Function: mdlInitializeSizes ===============================================
 * Abstract:
 *    The sizes information is used by Simulink to determine the S-function
 *    block's characteristics (number of inputs, outputs, states, etc.).
 */
static void mdlInitializeSizes(SimStruct *S)
{
	ssSetNumSFcnParams(S, 2);  /* Number of expected parameters */
	if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
		/* Return if number of expected != number of actual parameters */
		return;
		}
	
	ssSetNumContStates(S, 0);
	ssSetNumDiscStates(S, 0);
	
	if (!ssSetNumInputPorts(S, 1)) return;
	ssSetInputPortWidth(S, 0, 1);
	ssSetInputPortDirectFeedThrough(S, 0, 1);
	
	if (!ssSetNumOutputPorts(S, 1)) return;
	ssSetOutputPortWidth(S, 0, 1);
	
	ssSetNumSampleTimes(S, 1);
	ssSetNumRWork(S, 0);
	ssSetNumIWork(S, 0);
	ssSetNumPWork(S, 0);
	ssSetNumModes(S, 0);
	ssSetNumNonsampledZCs(S, 0);
	
	ssSetOptions(S, SS_OPTION_EXCEPTION_FREE_CODE);
}

/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *    This function is used to specify the sample time(s) for your
 *    S-function. You must register the same number of sample times as
 *    specified in ssSetNumSampleTimes.
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
	ssSetSampleTime(S, 0, CONTINUOUS_SAMPLE_TIME);
	ssSetOffsetTime(S, 0, 0.0);
}

#define MDL_START  /* Change to #undef to remove function */
/* Function: mdlStart =======================================================
* Abstract:
*    This function is called once at start of model execution. If you
*    have states that should be initialized once, this is the place
*    to do it.
*/
static void mdlStart(SimStruct *S)
{
	real_T	mn;
	real_T	mx;
	if (!IsRealScalar(ssGetSFcnParam(S,0)) || !IsRealScalar(ssGetSFcnParam(S,1)))
		ssSetErrorStatus(S,"Parameters moeten scalars zijn");
	mn=*mxGetPr(ssGetSFcnParam(S,0));
	mx=*mxGetPr(ssGetSFcnParam(S,1));
	if (mn>mx)
		ssSetErrorStatus(S,"Minimum (parameter 1) moet maximum gelijk zijn aan het maximum (parameter 2)");
}

/* Function: mdlOutputs =======================================================
 * Abstract:
 *    In this function, you compute the outputs of your S-function
 *    block. Generally outputs are placed in the output vector, ssGetY(S).
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{
	real_T	*y = ssGetOutputPortRealSignal(S,0);
	real_T	u = **ssGetInputPortRealSignalPtrs(S,0);
	real_T	mn=*mxGetPr(ssGetSFcnParam(S,0));
	real_T	mx=*mxGetPr(ssGetSFcnParam(S,1));
	if (u<mn)
		u=mn;
	else if (u>mx)
		u=mx;
	*y = u;
}


/* Function: mdlTerminate =====================================================
 * Abstract:
 *    In this function, you should perform any actions that are necessary
 *    at the termination of a simulation.  For example, if memory was
 *    allocated in mdlStart, this is the place to free it.
 */
static void mdlTerminate(SimStruct *S)
{
}


/*======================================================*
 * See sfuntmpl.doc for the optional S-function methods *
 *======================================================*/

/*=============================*
 * Required S-function trailer *
 *=============================*/

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
