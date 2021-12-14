function fName=GetNextFileNr(fName)
%GetNextFileNr - Gives the next available filename
%    fName=GetNextFileNr(fName)
%        fName: <path><name><ext>
%           name: xxxx<nr>
%    returns a name that doesn't exist with a number at least as high as
%    <nr> and the same number of digits (or higher)
%    if no number is given, '0' is added automatically

[fPth,fn,fext]=fileparts(fName);
if ~isempty(fPth)&&~exist(fPth,'dir')
	error('Path doesn''t exist')
end

if fn(end)<'0'||fn(end)>'9'
	fn(end+1)='0';
end
i=length(fn);
while i>1&&fn(i-1)>='0'&&fn(i-1)<='9'
	i=i-1;
end
nDig=length(fn)-i+1;
sName=['%s%0' num2str(nDig) 'd%s'];
if isempty(fPth)
	fBase=fn(1:i-1);
else
	fBase=[fPth filesep fn(1:i-1)];
end

nr=str2double(fn(i:end));
while true
	fName=sprintf(sName,fBase,nr,fext);
	if ~exist(fName,'file')
		break
	end
	nr=nr+1;
end
