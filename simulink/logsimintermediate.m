function [sys,x0,str,ts]=logsimintermediate(t,~,u,flag)
%logsimintermediate - Log Simulink simulation intermediate steps
%   log wordt gedaan via LogPoints
%        'simInit', 'simDer','simDisUpd','simOut','simTerm','simX'
%   see also LogPoints

global bLogRtime

if isempty(bLogRtime)
	bLogRtime=false;
end

sys=[];
switch flag
	case 0
		LogPoints('simInit',now)
		sys=[0 0 1 1 0 1 1]';
		x0=[];
		str=[];
		ts=[0 0];
		L={'simDer','simDisUpd','simOut','simX'};
		L=intersect(L,LogPoints('get'));
		for tp=L
			LogPoints('clear',tp{1})
		end
	case 1	% Derivatives
		if bLogRtime
			U=[t now u];
		else
			U=[t u];
		end
		LogPoints('simDer',U)
	case 2	% Discrete state update
		if bLogRtime
			U=[t now u];
		else
			U=[t u];
		end
		LogPoints('simDisUpd',U)
	case 3	% outputs
		if bLogRtime
			U=[t now u];
		else
			U=[t u];
		end
		LogPoints('simOut',U)
		sys=u;
	case 9	% Terminate
		LogPoints('simTerm',[now t])
	otherwise
		LogPoints('simX',[t flag])
end
