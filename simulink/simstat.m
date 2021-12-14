function [sys,x0,str,ts]=simstat(t,~,~,flag)
% SIMSTAT - Geeft status-scherm tijdens simulatie
%     Add this as a S-function in your model (anywhere).

persistent TTOT

if flag==0
	status(['simulatie van ' bdroot],0);
	sys=[0;0;0;0;0;0;0];
	x0=[];
	str=[];
	ts=[];
	TTOT=get_param(bdroot,'StopTime');
	if ischar(TTOT)
		TTOT=evalin('base',TTOT);
	end
elseif flag<9
	sys=[];
	status(t/TTOT)
else
	status
end
