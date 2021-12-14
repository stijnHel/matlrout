function AddNFcmd(key,command,varargin)
%AddNFcmd - Add navfig command (to be executed in base workspace)
%    AddNFcmd(key,command[,options])
%       options:
%           sStatus: use status window before and after the call
%                 (value is text to be shown in status window)

f=gcf;
if ~ischar(key)||numel(key)~=1
	error('Wrong input for key')
end
sStatus=[];
if nargin>2
	setoptions({'sStatus'},varargin{:})
end
D=getappdata(f,'NFcmds');
if isempty(D)
	D=struct('key',key,'cmd',command,'sStatus',sStatus);
else
	i=find([D.key]==key);
	if isempty(i)
		i=length(D)+1;
		D(i).key=key;
	end
	D(i).cmd=command;
	D(i).sStatus=sStatus;
end
setappdata(f,'NFcmds',D);
navfig('addkey',key,0,@NFcmd)

function NFcmd(f)
c=get(f,'CurrentCharacter');
D=getappdata(f,'NFcmds');
i=find([D.key]==c);
if isempty(i)
	error('Something "impossible" happened!')
end
if ~isempty(D(i).sStatus)&&ischar(D(i).sStatus)
	status(D(i).sStatus)
end
evalin('base',D(i).cmd);
if ~isempty(D(i).sStatus)&&ischar(D(i).sStatus)
	status
end
