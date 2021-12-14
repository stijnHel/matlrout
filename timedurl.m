function timOut=timedurl(url,n,delay,target,offset,sdelay,varargin)
%timedurl - function for repetitive retrieval of url
%    timedurl(url,n,delay,target[,offset[,sdelay]])
%    timedurl(url,n,delay,target[,options])
%       target: used in an sprint command, and is expected to be e.g.:
%                 xx...xx%d.yyy
%           single '\' are replaced by '\\' to avoid unwanted translation
%           to escape codes
%
%   By default only unique files are stored. (option bOnlyUnique).

if exist('offset','var')&&(ischar(offset)||iscell(offset))
	if iscell(offset)
		options=offset;
	else
		options={offset,sdelay,varargin{:}};
	end
else
	if ~exist('offset','var')||isempty(offset)
		offset=0;
	end
	if ~exist('sdelay','var')||isempty(sdelay)
		sdelay=0;
	end
	options=varargin;
end

rData=[];
bHoldTimer=false;
bOnlyUnique=true;
if ~isempty(options)
	setoptions({'offset','sdelay','restart','rData','bHoldTimer'	...
			,'bOnlyUnique'}	...
		,options)
end
if any(target=='\')&&~any(target(1:end-1)=='\'&target(2:end)=='\')
	target=strrep(target,'\','\\');
end

S=struct('n',n,'target',target,'url',url,'offset',offset	...
	,'restart',false,'rData',rData	...
	,'bHoldTimer',bHoldTimer,'bOnlyUnique',bOnlyUnique,'xLast',[]	...
	);
tim=timer('ExecutionMode','fixedRate','Period',delay	...
	,'TasksToExecute',n		...
	,'TimerFcn',@Update,'UserData',S	...
	,'StopFcn',@Stop);
if sdelay>0
	set(tim,'StartDelay',sdelay)
end
start(tim);
if nargout
	timOut=tim;
end

function Update(h,ev)
S=get(h,'UserData');
x=urlbinread(S.url);
if S.bOnlyUnique
	if isequal(x,S.xLast)
		return	% don't save unique data
	end
	S.xLast=x;
	set(h,'UserData',S);
end
f=sprintf(S.target,h.TasksExecuted+S.offset);
fid=fopen(f,'w');
if fid<3
	stop(h);
	delete(h)
	error('Can''t open file')
end
fwrite(fid,x);
fclose(fid);

function Stop(h,ev)
fprintf('logging stopped at %s\n',datestr(now))
S=get(h,'UserData');
if isfield(S,'restart')&&S.restart
	tn=now;
	tf=tn-floor(tn);
	switch S.restart
		case 1	% restart-time
			S.restart=0;
			set(h,'UserData',S)
			d=round((S.rData-tn)*24*3600);
		case 2	% fraction of day
			d=S.rData-tf;
			if d<0
				d=d+1;
			end
			d=floor(d*24*3600);
		otherwise
			error('impossible restart-data')
	end
	if d<0
		warning('Restart-time is back in time - no restart done')
		return
	end
	S.offset=S.offset+get(h,'TasksExecuted');
	set(h,'StartDelay',d,'UserData',S);
	start(h)
	fprintf('timer restarted.\n')
elseif ~S.bHoldTimer&&~isempty(ev)&&strcmp(ev.Type,'StopFcn')	...
		&&get(h,'TasksExecuted')>=get(h,'TasksToExecute')
	delete(h)
end
