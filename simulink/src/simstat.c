/*
 * simstat.c: C-S-function om status van simulatie weer te geven.
 *     Geen inputs/outputs/parameters zijn te geven.  Het "standaard"
 *           (matlrout-)status venster wordt gebruikt.
 *
 */

#define S_FUNCTION_LEVEL 2
#define S_FUNCTION_NAME  simstat

#include <windows.h> 
#include "simstruc.h"

/*====================*
 * S-function methods *
 *====================*/

static const DWORD	Dt=1000;
static DWORD	t0;
static DWORD	lastt;

/* Function: mdlInitializeSizes ==============================================
 * Abstract:
 *    The sizes information is used by Simulink to determine the S-function
 *    block's characteristics (number of inputs, outputs, states, etc.).
 */
static void mdlInitializeSizes(SimStruct *S)
{
	mxArray	*arr[2];
	int	npars=ssGetSFcnParamsCount(S);
	if (!ssSetNumInputPorts(S, 0)) return;
	ssSetNumSFcnParams(S, 0);
	
	ssSetNumContStates(S, 0);
	ssSetNumDiscStates(S, 0);
	
	if (!ssSetNumOutputPorts(S,0)) return;
	
	ssSetNumSampleTimes(S, 1);
	ssSetNumRWork(S, 0);
	ssSetNumIWork(S, 0);
	ssSetNumPWork(S, 0);
	ssSetNumModes(S, 0);
	ssSetNumNonsampledZCs(S, 0);
	
	ssSetOptions(S, 0);
	t0=lastt=GetTickCount();
	*arr=mxCreateString("Simulatie-status");
	arr[1]=mxCreateDoubleMatrix(1,1,0);
	*mxGetPr(arr[1])=0.0;
	mexCallMATLAB(0,NULL,2,arr,"status");
	mxDestroyArray(arr[0]);
	mxDestroyArray(arr[1]);
	ssSetSimStateCompliance(S, HAS_NO_SIM_STATE);
}

/* Function: mdlInitializeSampleTimes ========================================
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
	ssSetSampleTime(S, 0, CONTINUOUS_SAMPLE_TIME);
	ssSetOffsetTime(S, 0, 0.0);
}

static void mdlOutputs(SimStruct *S, int_T tid)
{
	mxArray	*arr[1];
	DWORD	t1=GetTickCount();
	if (t1-lastt>Dt) {
		lastt=t1;
		*arr=mxCreateDoubleMatrix(1,1,0);
		*mxGetPr(*arr)=ssGetT(S)/(ssGetTFinal(S)-ssGetTStart(S));
		mexCallMATLAB(0,NULL,1,arr,"status");
		mxDestroyArray(*arr);
		}
}

static void mdlTerminate(SimStruct *S)
{
	mexCallMATLAB(0,NULL,0,NULL,"status");
}


#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
