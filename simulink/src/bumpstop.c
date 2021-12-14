/*
 * bumpstop.c: C-S-function for implementing a bump-stop
 *             This is a mass-system with two end-stops
 *
 * Copyright (c) 1990-1998 by The MathWorks, Inc. All Rights Reserved.
 * $Revision: 1.19 $
 */

/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!????????juist gebruik van zero crossings!!!!!!!!
!!!!!!!!!!!!!!!!mode vector is niet gebruikt, zie sfun_zc.c!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

#define S_FUNCTION_LEVEL 2
#define S_FUNCTION_NAME  bumpstop

/*
 * Need to include simstruc.h for the definition of the SimStruct and
 * its associated macro definitions.
 */
#include "simstruc.h"

#define U(element) (*uPtrs[element])  /* Pointer to Input Port0 */

#define M_PARAM(S) ssGetSFcnParam(S,0)
#define LB_PARAM(S) ssGetSFcnParam(S,1)
#define UB_PARAM(S) ssGetSFcnParam(S,2)
#define X0_PARAM(S) ssGetSFcnParam(S,3)
#define V0_PARAM(S) ssGetSFcnParam(S,4)
#define ZC_PARAM(S) ssGetSFcnParam(S,5)

/*====================*
 * S-function methods *
 *====================*/

/* Function: mdlInitializeSizes ===============================================
 * Abstract:
 *    The sizes information is used by Simulink to determine the S-function
 *    block's characteristics (number of inputs, outputs, states, etc.).
 */
static void mdlInitializeSizes(SimStruct *S)
{
	int	nparams=ssGetSFcnParamsCount(S);
	/* See sfuntmpl.doc for more details on the macros below */
	if ((nparams<3)||(nparams>6)) {
		ssSetErrorStatus(S,"Minimum 3 en maximum 6 parameters nodig voor bumpstop");
		return;
		}
	ssSetNumSFcnParams(S, nparams);
	
	ssSetNumContStates(S, 2);
	ssSetNumDiscStates(S, 0);
	
	if (!ssSetNumInputPorts(S, 1)) return;
	ssSetInputPortWidth(S, 0, 1);
	ssSetInputPortDirectFeedThrough(S, 0, 0);
	
	if (!ssSetNumOutputPorts(S, 2)) return;
	ssSetOutputPortWidth(S, 0, 1);
	ssSetOutputPortWidth(S, 1, 1);
	
	ssSetNumSampleTimes(S, 1);
	ssSetNumRWork(S, 0);
	ssSetNumIWork(S, 0);
	ssSetNumPWork(S, 0);
	if (nparams>5 && ZC_PARAM(S)!=0) {
		ssSetNumModes(S, 2);
		ssSetNumNonsampledZCs(S, 2);
		}
	else {
		ssSetNumModes(S,0);
		ssSetNumNonsampledZCs(S,0);
		}
	
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

#define MDL_INITIALIZE_CONDITIONS
static void mdlInitializeConditions(SimStruct *S)
{
	int	nparams=ssGetSFcnParamsCount(S);
	real_T *x0 = ssGetContStates(S);
	
	if (nparams>4)
		x0[0] = *mxGetPr(V0_PARAM(S));
	else
		x0[0] = 0;
	if (nparams>3)
		x0[1] = *mxGetPr(X0_PARAM(S));
	else
		x0[1] = 0;
}


/* Function: mdlOutputs =======================================================
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{
	real_T            lb    = *mxGetPr(LB_PARAM(S));
	real_T            ub    = *mxGetPr(UB_PARAM(S));
	real_T *y = ssGetOutputPortRealSignal(S,0);
	real_T *x = ssGetContStates(S);
	
	y[0] = x[0];
	if (x[1]>ub)
		y[1]=ub;
	else if (x[1]<lb)
		y[1]=lb;
	else
		y[1] = x[1];
}

#define MDL_UPDATE
static void mdlUpdate(SimStruct *S, int_T tid)
{
	real_T            lb    = *mxGetPr(LB_PARAM(S));
	real_T            ub    = *mxGetPr(UB_PARAM(S));
	real_T            *x    = ssGetContStates(S);
	int	b=0;
	
	if ((x[1] < lb && x[0] <= 0.0) || (x[1]==lb && x[0]<0)) {
		x[1]=lb;
		x[0]=0;
		b=1;
		}
	else if ((x[1] > ub && x[0] >= 0.0) || (x[1] == ub && x[0] > 0)) {
		x[1]=ub;
		x[0]=0;
		b=1;
		}
	if (b)
		ssSetSolverNeedsReset(S);
}

#define MDL_DERIVATIVES
static void mdlDerivatives(SimStruct *S)
{
	real_T            lb    = *mxGetPr(LB_PARAM(S));
	real_T            ub    = *mxGetPr(UB_PARAM(S));
	real_T            *dx   = ssGetdX(S);
	real_T            *x    = ssGetContStates(S);
	InputRealPtrsType uPtrs = ssGetInputPortRealSignalPtrs(S,0);
	
	if ((x[1] <= lb && x[0] <= 0.0 && U(0)<0.0)
			|| (x[1] >= ub && x[0] >= 0.0 && U(0)>0.0)) {
		dx[0]=dx[1]=0.0;
		}
	else {
		dx[0] = U(0)/ *mxGetPr(M_PARAM(S));
		dx[1] = x[0];
		}
	
}

#define MDL_ZERO_CROSSINGS
static void mdlZeroCrossings(SimStruct *S)
{
	if (ssGetNumNonsampledZCs(S)>=2) {
		real_T            *zcSignals = ssGetNonsampledZCs(S);
		real_T            lb    = *mxGetPr(LB_PARAM(S));
		real_T            ub    = *mxGetPr(UB_PARAM(S));
		real_T            *x    = ssGetContStates(S);
		
		zcSignals[0] = x[1]-ub;
		zcSignals[1] = x[1]-lb;
		}
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

/*=============================*
 * Required S-function trailer *
 *=============================*/

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
