function [d,bytes]=hierdir(dirn,bRoot,sFileSpec)
% HIERDIR  - Vraagt hierarchische directory op
%    [d,bytes]=hierdir(dirn[,fileSpec])
%      contents of directory is put in contents-field
%    d=hierdir(dirn,bRoot)
%        puts all in a "root-directory structure"
%
%  see also dirrecurs

if nargin<3||~ischar(sFileSpec)
	sFileSpec='';
end
if nargin<2||isempty(bRoot)
	bRoot=false;
elseif ischar(bRoot)
	sFileSpec=bRoot;
	bRoot=false;
end
if nargin<1||isempty(dirn)
	dirn='.';
end
if any(dirn=='*')
	if nargin>2
		error('It''s not possible to have 3 arguments and wildcard in the dir-name')
	end
	[fPth,fNm,fExt]=fileparts(dirn);
	sFileSpec=[fNm,fExt];
	dirn=fPth;
end
if isempty(sFileSpec)
	d=dir(dirn);
else
	d=dir([dirn filesep sFileSpec]);
	dd=dir(dirn);
	d=[d;dd([dd.isdir])];
end
d(1).contents=[];
i=1;
bytes=0;
while i<=length(d)
    if strcmp(d(i).name,'.')||strcmp(d(i).name,'..')
        d(i)=[];
    elseif d(i).isdir
        [d(i).contents,B]=hierdir([dirn filesep d(i).name],sFileSpec);
		if ~isempty(sFileSpec)&&isempty(d(i).contents)
			d(i)=[];
		else
			d(i).bytes=B;
			bytes=bytes+B;
			i=i+1;
		end
	else
		B=d(i).bytes;
		if isempty(B)	% blijkt mogelijk te zijn!
			d(i)=[];	% just remove it(!)
		else
			bytes=bytes+B;
			i=i+1;
		end
    end
end
if bRoot
	d=struct('dirnaam',dirn,'contents',d,'bytes',bytes);
end
