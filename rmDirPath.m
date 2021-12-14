function pthRemoved=rmDirPath(in,varargin)
%rmDirPath - removes directories from the path recursively
%     rmDirPath(<dir>)
%           <dir> directory - default pwd
%
%  see also: nmlpath

bCaseSensitive=~ispc;

if nargin==0
	in=pwd;
end

if in(end)==filesep
	in(end)=[];
end

pth=path;
ii=[0 find(pth==pathsep) length(pth)+1];
pthRem=cell(1,length(ii)-1);
nRem=0;
n=length(in);
for i=1:length(pthRem)
	p1=pth(ii(i)+1:ii(i+1)-1);
	if bCaseSensitive
		b=strncmp(in,p1,n);
	else
		b=strncmpi(in,p1,n);
	end
	if b
		nRem=nRem+1;
		pthRem{nRem}=p1;
	end
end
pthRem=pthRem(1:nRem);
if nRem
	rmpath(pthRem{:})
end
if nargout
	pthRemoved=pthRem;
end
