/*
 * twowpwm.c: C-S-function for implementing a two way PWM valve
 *
 */

#define S_FUNCTION_LEVEL 2
#define S_FUNCTION_NAME  twowpwm

#include "simstruc.h"
#include <math.h>

/*====================*
 * S-function methods *
 *====================*/

#define T_PARAM(S) ssGetSFcnParam(S,0)
#define DT_PARAM(S) ssGetSFcnParam(S,1)
#define TO_PARAM(S) ssGetSFcnParam(S,2)
	// Time of opening (#/s)
#define TC_PARAM(S) ssGetSFcnParam(S,3)
	// Time of closing (#/s) (positive value)
#define AO_PARAM(S) ssGetSFcnParam(S,4)
	// Area open
#define AC_PARAM(S) ssGetSFcnParam(S,5)
	// Area closed

#define PWMdc	ssGetRWorkValue(S, 0)
#define PWMt	ssGetRWorkValue(S, 1)
#define PWMt0	ssGetRWorkValue(S, 2)
	// start-tijd van volgende duty-cycle
#define PWMdt	ssGetRWorkValue(S, 3)
	// start-tijd van werking PWM (offset-time)
#define PWMt1	ssGetRWorkValue(S, 4)
	// start-tijd van huidige duty-cycle
#define PWMt2	ssGetRWorkValue(S, 5)
	// eind van hoogtijd
#define PWMt3	ssGetRWorkValue(S, 6)
	// referentie-tijdstip
#define PWMx	ssGetRWorkValue(S, 7)
	// opening op tijdstip t3

#define PWMstate	ssGetIWorkValue(S, 0)

#define setPWMdc(dc)	ssSetRWorkValue(S, 0, dc)
#define setPWMt(t)	ssSetRWorkValue(S, 1, t)
#define setPWMt0(t0)	ssSetRWorkValue(S, 2, t0)
#define setPWMdt(dt)	ssSetRWorkValue(S, 3, dt)
#define setPWMt1(t1)	ssSetRWorkValue(S, 4, t1)
#define setPWMt2(t2)	ssSetRWorkValue(S, 5, t2)
#define setPWMt3(t3)	ssSetRWorkValue(S, 6, t3)
#define setPWMx(x)	ssSetRWorkValue(S, 7, x)

#define setPWMstate(s)	ssSetIWorkValue(S, 0, s)

static const double	eps=1.0e-13;

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

#define MDL_CHECK_PARAMETERS   /* Change to #undef to remove function */
/* Function: mdlCheckParameters =============================================
 */
static void mdlCheckParameters(SimStruct *S)
{
	if (!IsRealScalar(DT_PARAM(S)) || !IsRealScalar(T_PARAM(S))
			|| !IsRealScalar(TO_PARAM(S)) || !IsRealScalar(TC_PARAM(S)))
		ssSetErrorStatus(S,"Parameters moeten reele scalars zijn.");
	if (*mxGetPr(T_PARAM(S))<=0) {
		ssSetErrorStatus(S,"Parameter 1 (T) van pwmc moet groter zijn dan 0 zijn");
		return;
		}
	if (*mxGetPr(DT_PARAM(S))<0) {
		ssSetErrorStatus(S,"Parameter 2 (DT) van pwmc moet minstens 0 zijn");
		return;
		}
	if (*mxGetPr(TO_PARAM(S))<0) {
		ssSetErrorStatus(S,"Parameter 3 (SO) van pwmc moet minstens 0 zijn");
		return;
		}
	if (*mxGetPr(TC_PARAM(S))<0) {
		ssSetErrorStatus(S,"Parameter 4 (SC) van pwmc moet minstens 0 zijn");
		return;
		}
}

/* Function: mdlInitializeSizes ==============================================
 * Abstract:
 *    The sizes information is used by Simulink to determine the S-function
 *    block's characteristics (number of inputs, outputs, states, etc.).
 */
static void mdlInitializeSizes(SimStruct *S)
{
	int	npars=ssGetSFcnParamsCount(S);
	if (npars==4) {
		if (!ssSetNumInputPorts(S, 3)) return;
		ssSetInputPortWidth(S, 0, 1);
		ssSetInputPortWidth(S, 1, 1);
		ssSetInputPortWidth(S, 2, 1);
		ssSetInputPortDirectFeedThrough(S, 0, 0);
		ssSetInputPortDirectFeedThrough(S, 1, 1);
		ssSetInputPortDirectFeedThrough(S, 2, 1);
		ssSetNumSFcnParams(S, 4);
		}
	else if (npars==6) {
		if (!ssSetNumInputPorts(S, 1)) return;
		ssSetInputPortWidth(S, 0, 1);
		ssSetInputPortDirectFeedThrough(S, 0, 0);
		ssSetNumSFcnParams(S, 6);
		}
	else {
		mexPrintf("%d parameters gegeven.\n",npars);
		ssSetErrorStatus(S,"4 of 6 parameters zijn vereist.");
		return;
		}
	mdlCheckParameters(S);
	if (ssGetErrorStatus(S) != NULL) return;
	
	ssSetNumContStates(S, 0);
	ssSetNumDiscStates(S, 0);
	
	if (!ssSetNumOutputPorts(S, 2)) return;
	ssSetOutputPortWidth(S, 0, 1);
	ssSetOutputPortWidth(S, 1, 1);
	
	ssSetNumSampleTimes(S, 2);
	ssSetNumRWork(S, 8);
	ssSetNumIWork(S, 1);
	ssSetNumPWork(S, 0);
	ssSetNumModes(S, 0);
	ssSetNumNonsampledZCs(S, 0);
	
	ssSetOptions(S, SS_OPTION_EXCEPTION_FREE_CODE);
}

/* Function: mdlInitializeSampleTimes ========================================
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
	ssSetSampleTime(S, 0, VARIABLE_SAMPLE_TIME);
	ssSetOffsetTime(S, 0, 0.0);
	ssSetSampleTime(S, 1, CONTINUOUS_SAMPLE_TIME);
	ssSetOffsetTime(S, 1, 0.0);
}

#define MDL_INITIALIZE_CONDITIONS
static void mdlInitializeConditions(SimStruct *S)
{
	InputRealPtrsType	uPtrs = ssGetInputPortRealSignalPtrs(S,0);

	if (*mxGetPr(DT_PARAM(S))>0)
		setPWMstate(-1);
	else {
		setPWMstate(0);
		}
	setPWMdt((real_T) (*mxGetPr(DT_PARAM(S))));
	setPWMt((real_T) (*mxGetPr(T_PARAM(S))));
	setPWMt0(0.0);
	setPWMdc(**uPtrs/100.0);
	setPWMx(0.0);
}

#define MDL_PROCESS_PARAMETERS
/* Function: mdlProcessParameters ===========================================
 */
static void mdlProcessParameters(SimStruct *S)
{
	mexPrintf("Process\n");
	setPWMdt((real_T) (*mxGetPr(DT_PARAM(S))));
	setPWMt((real_T) (*mxGetPr(T_PARAM(S))));
}

#define MDL_GET_TIME_OF_NEXT_VAR_HIT
static void mdlGetTimeOfNextVarHit(SimStruct *S)
{
	real_T	nextT;
	InputRealPtrsType	uPtrs = ssGetInputPortRealSignalPtrs(S,0);
	real_T	newDC=**uPtrs/100.0;
	real_T	t_hoog;
	const real_T	TO=*mxGetPr(TO_PARAM(S));
	const real_T	TC=*mxGetPr(TC_PARAM(S));
	const real_T	t=ssGetT(S);
	real_T	dc=PWMdc;
	const real_T	t0=PWMt0;
	const real_T	t2=PWMt2;
	real_T	a=PWMx;
	real_T	t3=PWMt3;
	const int	state=PWMstate;
	real_T	b;

	if (newDC<0.0)
		newDC=0.0;
	else if (newDC>1.0)
		newDC=1.0;
	t_hoog=newDC*PWMt;
	/*
		PWMstates :
			-1	: t<start-tijd
			0	: PWM gesloten
			1	: PWM aan het openen
			2	: PWM open
			3	: PWM aan het sluiten
	*/
	if (state==-1) {
		setPWMstate(0);
		setPWMt0(PWMdt);
		ssSetTNext(S, PWMdt);
		return;
		}
	if (t==t0) {
		mexPrintf("t0\n");
		nextT=t0+PWMt;
		setPWMdc(newDC);
		setPWMt0(nextT);
		setPWMt1(t0);
		setPWMt2(t0+t_hoog);
		setPWMt3(t0);
		}
	switch (state) {
		case 0:	// closed PWM
			if (t==t0 && newDC>0)
				if (TO<=0.0) {	// Immediate opening of PWM
					setPWMx(1.0);
					setPWMstate(2);
					nextT=t0+t_hoog;
					}
				else {
					setPWMstate(1);
					if (t_hoog>=TO)
						nextT=t0+TO;
					else
						nextT=t0+t_hoog;
					}
			break;
		case 1:	// opening
			if (t<t2) {
				nextT=PWMt2;
				setPWMstate(2);
				}
			else if (t==t0) {	// start of dc
				b=a+(t-t3)/TO;
				if (newDC>0.0) {
					if (b>1.0) {	//??rekening houden met afrondingen ?
						mexPrintf("!!!!!opening wordt groter dan 1 (%g)!!!!!(t=%g)\n",b,t);
						b=1.0;
						}
					t3+=(1.0-b)*TO*newDC;
					if (t3<nextT)
						nextT=t3;
					}
				else if (TC<=0.0)	// dc==0
					setPWMstate(0);
				else {	// dc==0 && TC>0
					t3=t0+b*TC;
					if (t3<nextT)
						nextT=t3;
					setPWMx(b);
					setPWMt3(t0);
					setPWMstate(3);
					}
				}
			else if (TC<=0.0) {	// immediate closing of PWM
				nextT=t0;
				setPWMstate(0);
				}
			else {	// end of duty cycle
				a+=(t-t3)/TO;
				if (a-1.0>eps) {	//??rekening houden met afrondingen ?
					mexPrintf("!!!!!opening wordt groter dan 1 (%g)!!!!!(t=%g)\n",a,t);
					a=1.0;
					}
				else if (a>1.0)
					a=1.0;
				setPWMx(a);
				setPWMt3(t2);
				setPWMstate(3);
				t3=t2+a*TC;
				if (t3<=t0)
					nextT=t3;
				else
					nextT=t0;
				}
			break;
		case 2:	// open
			if (t==t0)
				if (newDC>0.0)
					nextT=t2;
				else if (TC<=0.0)
					setPWMstate(0);
				else {
					t3=t0+TC;
					if (t3<nextT)
						nextT=t3;
					setPWMx(1.0);
					setPWMt3(t0);
					setPWMstate(3);
					}
			else if (TC<=0.0) {
				nextT=t0;
				setPWMstate(0);
				}
			else {
				setPWMx(1.0);
				setPWMt3(t2);
				setPWMstate(3);
				t3=t2+TC;
				if (t3<=t0)
					nextT=t3;
				else
					nextT=t0;
				}
			break;
		// case 3:	// closing
		default:	// closing
			if (t==t0) {	// start of dc
				b=a-(t-t3)/TC;
				if (newDC<=0.0) {
					if (b<0.0) {	//??rekening houden met afrondingen ?
						mexPrintf("!!!!!opening wordt kleiner dan 0 (%g)!!!!!(t=%g)\n",b,t);
						b=0.0;
						}
					t3+=b*TC;
					if (t3<nextT)
						nextT=t3;
					}
				else if (TO<=0.0)
					setPWMstate(2);
				else {
					t3=t0+(1.0-b)*TO;
					if (t3<nextT)
						nextT=t3;
					setPWMx(b);
					setPWMt3(t0);
					setPWMstate(1);
					}
				}
			else {
				setPWMstate(0);
				nextT=t0;
				}
			break;
		}
	ssSetTNext(S, nextT);
	mexPrintf(" %1d t=%7.4f t=%7.4f t=%7.4f t=%7.4f     dc=%3.0f T=%7.4f   %7.4f\n"
		,state,t,t0,t2,t3,dc*100.0,PWMt,nextT);
}

static void mdlOutputs(SimStruct *S, int_T tid)
{
	int	npars=ssGetSFcnParamsCount(S);
	real_T	*y1 = ssGetOutputPortRealSignal(S,0);
	real_T	*y2 = ssGetOutputPortRealSignal(S,1);
	real_T	a;
	real_T	AO, AC;
	real_T	t=ssGetT(S);

	mexPrintf("t = %6.4f (%6.4f), tid = %d    :",t,PWMt3,tid);
	switch (PWMstate) {
		case 0:	// closed
			a=0.0;
			break;
		case 1:	// opening
			a=PWMx+(t-PWMt3)/ *mxGetPr(TO_PARAM(S));
			break;
		case 2:
			a=1.0;
			break;
		//case 3:
		default:
			a=PWMx-(t-PWMt3)/ *mxGetPr(TC_PARAM(S));
			break;
		}
	if (npars>4) {
		AO = *mxGetPr(AO_PARAM(S));
		AC = *mxGetPr(AC_PARAM(S));
		}
	else {
		AO = **ssGetInputPortRealSignalPtrs(S,1);
		AC = **ssGetInputPortRealSignalPtrs(S,2);
		}
	*y1=a*AO;
	*y2=(1.0-a)*AC;
	mexPrintf("a=%6.3f, AO = %4.2f, AC = %4.2f, y1 = %4.2f, y2 = %4.2f\n"
		,a,AO,AC,*y1,*y2);
}

static void mdlTerminate(SimStruct *S)
{
}


#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
