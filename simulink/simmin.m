function [ret,x0,str,ts,xts]=simmin(t,x,u,flag);
% SIMMIN	is the M-file description of the SIMULINK system named SIMMIN.
%	The block-diagram can be displayed by typing: SIMMIN.
%
%	SYS=SIMMIN(T,X,U,FLAG) returns depending on FLAG certain
%	system values given time point, T, current state vector, X,
%	and input vector, U.
%	FLAG is used to indicate the type of output to be returned in SYS.
%
%	Setting FLAG=1 causes SIMMIN to return state derivatives, FLAG=2
%	discrete states, FLAG=3 system outputs and FLAG=4 next sample
%	time. For more information and other options see SFUNC.
%
%	Calling SIMMIN with a FLAG of zero:
%	[SIZES]=SIMMIN([],[],[],0),  returns a vector, SIZES, which
%	contains the sizes of the state vector and other parameters.
%		SIZES(1) number of states
%		SIZES(2) number of discrete states
%		SIZES(3) number of outputs
%		SIZES(4) number of inputs
%		SIZES(5) number of roots (currently unsupported)
%		SIZES(6) direct feedthrough flag
%		SIZES(7) number of sample times
%
%	For the definition of other parameters in SIZES, see SFUNC.
%	See also, TRIM, LINMOD, LINSIM, EULER, RK23, RK45, ADAMS, GEAR.

% Note: This M-file is only used for saving graphical information;
%       after the model is loaded into memory an internal model
%       representation is used.

% the system will take on the name of this mfile:
sys = mfilename;
new_system(sys)
simver(1.3)
if (0 == (nargin + nargout))
     set_param(sys,'Location',[101,119,362,247])
     open_system(sys)
end;
set_param(sys,'algorithm',     'RK-45')
set_param(sys,'Start time',    '0.0')
set_param(sys,'Stop time',     '999999')
set_param(sys,'Min step size', '0.0001')
set_param(sys,'Max step size', '10')
set_param(sys,'Relative error','1e-3')
set_param(sys,'Return vars',   '')

add_block('built-in/Inport',[sys,'/','in1'])
set_param([sys,'/','in1'],...
		'position',[10,30,30,50])

add_block('built-in/Inport',[sys,'/','in2'])
set_param([sys,'/','in2'],...
		'Port','2',...
		'position',[10,70,30,90])

add_block('built-in/Relational Operator',[sys,'/',['Relational',13,'Operator']])
set_param([sys,'/',['Relational',13,'Operator']],...
		'hide name',0,...
		'Operator','<=',...
		'position',[90,18,115,102])

add_block('built-in/Switch',[sys,'/','Switch'])
set_param([sys,'/','Switch'],...
		'hide name',0,...
		'Threshold','0.5',...
		'position',[155,44,185,76])

add_block('built-in/Outport',[sys,'/','min'])
set_param([sys,'/','min'],...
		'position',[220,50,240,70])
add_line(sys,[120,60;150,60])
add_line(sys,[35,40;85,40])
add_line(sys,[35,80;85,80])
add_line(sys,[190,60;215,60])
add_line(sys,[35,40;60,40;60,10;130,10;130,50;150,50])
add_line(sys,[35,80;60,80;60,115;130,115;130,70;150,70])

drawnow

% Return any arguments.
if (nargin | nargout)
	% Must use feval here to access system in memory
	if (nargin > 3)
		if (flag == 0)
			eval(['[ret,x0,str,ts,xts]=',sys,'(t,x,u,flag);'])
		else
			eval(['ret =', sys,'(t,x,u,flag);'])
		end
	else
		[ret,x0,str,ts,xts] = feval(sys);
	end
else
	drawnow % Flash up the model and execute load callback
end
