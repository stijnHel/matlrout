function [g1,g2,dubbels1,dubbels2,X1,X2]=cmpflatdir(X10,X20)
% CMPFLATDIR - vergelijkt "vlak gemaakte directory"
%     [g1,g2,dubbels1,dubbels2,X1,X2]=cmpflatdir(X10,X20)
%   of
%     D=cmpflatdir(X10,X20)
%               D is struct met alle outputs
%
%   dubbels: binnen 1 directory(+subdirectories) gelijke namen
%         >0 ==> gelijke namen bestaan
%         waarde geeft "zoveelste gelijke"
%   g<i>: gelijke namen tussen 2 directories
%
%   X1,X2 zijn "flattened directories", gesorteerd op naam (niet directory)
%
% zie ook hierdir / dirrecurs

[X1,b1] = GetFlatDirectory(X10);
[X2,b2] = GetFlatDirectory(X20);
bCmpContents = b1&&b2;

i1=1;
i2=1;
dubbels1=zeros(1,length(X1));
dubbels2=zeros(1,length(X2));
g1=dubbels1;
g2=dubbels2;
gv1=false(1,length(X1));
gv2=false(1,length(X2));
while i1<=length(X1)&&i2<=length(X2)
    i10=i1;
    i20=i2;
    while i1<length(X1)&&strcmp(X1(i1).name,X1(i1+1).name)
        i1=i1+1;
        dubbels1(i1)=dubbels1(i1-1)+1;
    end
    while i2<length(X2)&&strcmp(X2(i2).name,X2(i2+1).name)
        i2=i2+1;
        dubbels2(i2)=dubbels2(i2-1)+1;
    end
    v=strcmpc(X1(i1).name,X2(i2).name);
    if v<0
        i1=i1+1;
    elseif v>0
        i2=i2+1;
    else
        g1(i10:i1)=i2;
        g2(i20:i2)=i1;
		if bCmpContents
			bEqual = isequal(X1(i1).contents,X2(i2).contents);	% (!! what if "dubbel"?)
			gv1(i1) = bEqual;
			gv2(i2) = bEqual;
		end
        i1=i1+1;
        i2=i2+1;
    end
end
if nargout<=1
    g1=struct('g1',g1,'g2',g2,'dubbels1',dubbels1,'dubbels2',dubbels2	...
		,'X1',X1,'X2',X2	...
		);
	if bCmpContents
		g1.gv1 = gv1;
		g1.gv2 = gv2;
	end
end

function [X,bUseContents] = GetFlatDirectory(X0)
bUseContents = false;
if ischar(X0)
	X0 = hierdir(X0,true);
end
if isscalar(X0)
	X0 = flattenDir(X0);
elseif ~isfield(X0,'fulldir')
	if isfield(X0,'folder')
		[X0.fulldir] = deal(X0.folder);
	end
	if isfield(X0,'level') && isfield(X0,'contents')	% results from dirrecurs
		bUseContents = isfield(X0,'contents');
	end
end

X = sort(X0,'name');
