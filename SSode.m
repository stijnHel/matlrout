function dXdt=SSode(t,X,B,T,U)
%SSode    - ODE-definition function using state space description
%     dXdt=SSode(t,X,U) - Standard use for ODE-functions
%     SSode('set',A,B[,T_U,U]) - Set state space definition
%     SSode('set',T_U,U) - input
%
%   see also SimulateSSmodel

global SStLast SSiLast SSnCall SStStart SStMAX
persistent SS_A SS_B SS_T SS_U SS_Ttot

if ischar(t)
	SS_Ttot=0;
	if strcmpi(t,'set')
		SS_A=X;
		SS_B=B;
		if nargin>3
			SS_T=T;
			SS_U=U;
		end
	elseif strcmpi(t,'setU')
		SS_T=X;
		SS_U=B;
	elseif strcmpi(t,'get')
		dXdt=var2struct(SS_A,SS_B,SS_T,SS_U);
	elseif strcmpi(t,'getU')
		dXdt=var2struct(SS_T,SS_U);
	elseif strcmpi(t,'setTtot')
		SS_Ttot=X;	% should be set just before starting the simulation
	else
		error('Wrong use of this function')
	end
	return
end
if isempty(SS_A)||isempty(SS_T)
	error('State space description not set!')
end
if isempty(SStMAX)
	SStMAX=10/1440;	% 10s
end
if isempty(SStLast)||isempty(SSiLast)||t<SStLast
	SSiLast=1;
	SSnCall=0;
	SStStart=now;
	fprintf('Started %s\n',datestr(SStStart))
end
SSnCall=SSnCall+1;
if now-SStStart>SStMAX
	DT=(now-SStStart)*86400;
	if SS_Ttot
		status	% close status window (or decrease level)
	end
	error('Too long simulation! (%d calls in %gs - %g#/s)',SSnCall	...
		,DT,SSnCall/DT)
end

while SSiLast<length(SS_T)&&SS_T(SSiLast+1)<=t
	SSiLast=SSiLast+1;
end
t1=SS_T(SSiLast);
if t<=t1||SSiLast>=length(SS_T)
	u=SS_U(SSiLast,:)';
else
	t2=SS_T(SSiLast+1);
	u=(SS_U(SSiLast,:)+(t-t1)/(t2-t1)*(SS_U(SSiLast+1,:)-SS_U(SSiLast,:)))';
end
%u=interp1(SS_T,SS_U,t)'; % too slow!!
dXdt=SS_A*X+SS_B*u;
SStLast=t;
if SS_Ttot>0
	status(t/SS_Ttot)
end

function varargout=OutputFcn(varargin)
fprintf('%d in, %d out\n',nargin,nargout)

