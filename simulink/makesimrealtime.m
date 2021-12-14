function [sys,x0,str,ts]=makesimrealtime(t,~,u,flag,accFactor,bLog)
%makesimrealtime - S-function to simulate in realtime (and not too fast)

persistent tStart LOG nLog btStartUpdated

if nargin<5
	accFactor=1;
	bLog=false;
	if nargin<1
		if isempty(nLog)
			error('Sorry, but no log is available!')
		end
		sys = LOG(1:nLog,:);
		return
	end
end
if isempty(accFactor)
	accFactor = 1;
end
if isempty(bLog)
	bLog = false;
end

sys=[];
switch flag
	case 0
		sys=[0 0 1 1 0 1 1]';
		%sys=[0 0 1 1 1 1 1]'; % with feedthrough
		x0=[];
		str=[];
		ts=[0 0];
		tStart=now;
		nLog = 1;
		LOG = zeros(100000,2);
		LOG(nLog,2) = tStart;
		btStartUpdated = false;
	case 3	% outputs
		tNow = now;
		if ~btStartUpdated
			if t>=0.01
				tStart = tNow - t/86400;
				btStartUpdated = true;
			else
			end
		end
		sys=u;
		tRun=(tNow-tStart)*86400;
		dt=t/accFactor-tRun;
		if dt>0.01
			pause(dt)
		end
		%assignin('base','sim_u',[t,u])	%TESTTESTTEST
		if bLog
			nLog = nLog+1;
			if nLog>size(LOG,1)
				LOG(end+10000,1) = 0;
			end
			LOG(nLog) = t;
			LOG(nLog,2) = tNow;
		end
end
