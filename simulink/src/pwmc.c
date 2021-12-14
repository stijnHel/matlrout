/*  File    : pwmc.c
 *  Abstract:
 *
 *      C-file S-function for a PWM.
 *
 */

#define S_FUNCTION_NAME pwmc
#define S_FUNCTION_LEVEL 2

#include "simstruc.h"

#define PWMdc	ssGetRWorkValue(S, 0)
#define PWMt	ssGetRWorkValue(S, 1)
#define PWMamp	ssGetRWorkValue(S, 2)
#define PWMt0	ssGetRWorkValue(S, 3)
#define PWMdt	ssGetRWorkValue(S, 4)

#define PWMstate	ssGetIWorkValue(S, 0)

#define setPWMdc(dc)	ssSetRWorkValue(S, 0, dc)
#define setPWMt(t)	ssSetRWorkValue(S, 1, t)
#define setPWMamp(A)	ssSetRWorkValue(S, 2, A)
#define setPWMt0(t0)	ssSetRWorkValue(S, 3, t0)
#define setPWMdt(dt)	ssSetRWorkValue(S, 4, dt)

#define setPWMstate(s)	ssSetIWorkValue(S, 0, s)

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
	const mxArray *m;
	int	npars=ssGetSFcnParamsCount(S);
	if (npars>3) {
		ssSetNumSFcnParams(S,3);
		return;
		}
	ssSetNumSFcnParams(S,npars);
	if (npars>0) {
		m=ssGetSFcnParam(S,0);
		if (!IsRealScalar(m)) {
			ssSetErrorStatus(S,"Parameter 1 (T) van pwmc moet een scalar zijn");
			return;
			}
		}
	if (npars>1) {
		m=ssGetSFcnParam(S,1);
		if (!IsRealScalar(m)) {
			ssSetErrorStatus(S,"Parameter 2 (A) van pwmc moet een scalar zijn");
			return;
			}
		}
	if (npars>2) {
		m=ssGetSFcnParam(S,2);
		if (!IsRealScalar(m)) {
			ssSetErrorStatus(S,"Parameter 3 (dt) van pwmc moet een scalar zijn");
			return;
			}
		}
	
	ssSetNumContStates(S, 0);
	ssSetNumDiscStates(S, 0);
	
	if (!ssSetNumInputPorts(S, 1)) return;
	ssSetInputPortWidth(S, 0, 1);
	ssSetInputPortDirectFeedThrough(S, 0, true);
	
	if (!ssSetNumOutputPorts(S, 1)) return;
	ssSetOutputPortWidth(S, 0, 1);
	
	ssSetNumSampleTimes(S, 1);
	ssSetNumRWork(S, 5);
	ssSetNumIWork(S, 1);
	ssSetNumPWork(S, 0);
	ssSetNumModes(S, 0);
	ssSetNumNonsampledZCs(S, 0);

	ssSetOptions(S, SS_OPTION_EXCEPTION_FREE_CODE | SS_OPTION_DISCRETE_VALUED_OUTPUT);
}

/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *    Variable-Step S-function
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
	ssSetSampleTime(S, 0, VARIABLE_SAMPLE_TIME);
	//mexPrintf("VARIABLE_SAMPLE_TIME: %d\n",VARIABLE_SAMPLE_TIME);
	ssSetOffsetTime(S, 0, 0.0);
}

#define MDL_INITIALIZE_CONDITIONS
/* Function: mdlInitializeConditions ========================================
 * Abstract:
 *    Initialize discrete state to zero.
 */
static void mdlInitializeConditions(SimStruct *S)
{
	InputRealPtrsType uPtrs = ssGetInputPortRealSignalPtrs(S,0);
	int	npars=ssGetSFcnParamsCount(S);

	if (npars>2) 
		setPWMdt((real_T) (*mxGetPr(ssGetSFcnParam(S,2))));
	else
		setPWMdt(0.0);
	if (npars>1)
		setPWMamp((real_T) (*mxGetPr(ssGetSFcnParam(S,1))));
	else
		setPWMamp(1.0);
	if (npars>0) {
		setPWMt((real_T) (*mxGetPr(ssGetSFcnParam(S,0))));
		if (PWMt<=0) {
			ssSetErrorStatus(S,"Parameter 1 (T) van pwmc groter zijn dan 0 zijn");
			return;
			}
		}
	else
		setPWMt(0.016384);
	setPWMstate(0);
	setPWMt0(0.0);
	if (uPtrs==NULL)
		mexPrintf("init DC0 = %p\n",uPtrs);
	else {
		//mexPrintf("init DC0 = %p,%p,%10.5lf\n",uPtrs,*uPtrs,**uPtrs);
		setPWMdc(**uPtrs/100.0);
		}
}

#define MDL_GET_TIME_OF_NEXT_VAR_HIT
static void mdlGetTimeOfNextVarHit(SimStruct *S)
{
	real_T	nextT;
	InputRealPtrsType uPtrs = ssGetInputPortRealSignalPtrs(S,0);
	real_T	newDC=0.5;
	//real_T	newDC=**uPtrs/100.0;
	if (uPtrs==NULL)
		mexPrintf("nextT DC0 = %p\n",uPtrs);
	else {
		//mexPrintf("nextT DC0 = %p, %p, %10.5lf\n",uPtrs,*uPtrs,**uPtrs);
		newDC=**uPtrs/100.0;
		}

	if (PWMt0<PWMdt) {
		setPWMt0(PWMdt);
		ssSetTNext(S, PWMdt);
		return;
		}
	if (PWMstate) {	// output was high
		if (PWMdc>=1.0) {
			if ((newDC>0.0)&&(newDC<1.0))
				nextT=PWMt0+PWMt*newDC;
			else
				nextT=PWMt0+PWMt;
			setPWMt0(PWMt0+PWMt);
			setPWMdc(newDC);
			}
		else {
			setPWMstate(0);
			nextT=PWMt0;
			}
		}
	else {	//	output was low
		if (newDC>0.0) {
			setPWMstate(1);
			if (newDC<1.0)
				nextT=PWMt0+PWMt*newDC;
			else
				nextT=PWMt0+PWMt;
			}
		else
			nextT=PWMt0+PWMt;
		setPWMt0(PWMt0+PWMt);
		setPWMdc(newDC);
		}
	ssSetTNext(S, nextT);
}

/* Function: mdlOutputs =======================================================
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{
	*ssGetOutputPortRealSignal(S,0) = PWMstate*PWMamp;
}

/* Function: mdlTerminate =====================================================
 */
static void mdlTerminate(SimStruct *S)
{
}

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
