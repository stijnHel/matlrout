function [pthOut,B]=nmlpath(varargin)
%nmlpath  - Gives the "NonMatLabPATH" - meaning the user paths in the path
%      pth=nmlpath
%  or
%      nmlpath
%
%   see also: rmDirPath

bShowML=true;
if nargin
	setoptions({'bShowML'},varargin{:})
end

ML=matlabroot;
nML=length(ML);
p=[pathsep path pathsep];
iS=find(p==pathsep);
pth=cell(1,length(iS)-1);
B=false(1,length(pth));
for i=1:length(pth)
	pth{i}=p(iS(i)+1:iS(i+1)-1);
	B(i)=~strncmpi(pth{i},ML,nML);
end
if nargout
	pthOut=pth(B);
elseif ~any(B)
	fprintf('no user directories in the path\n')
elseif bShowML
	if ~B(1)
		fprintf('...\n')
	end
	k=0;
	b=true;
	for i=1:length(B)
		if B(i)
			k=k+1;
			fprintf('%2d: %s\n',k,pth{i})
		elseif b
			fprintf('...\n')
		end
		b=B(i);
	end
else
	printstr(pth(B)) %#ok<UNRCH>
end
