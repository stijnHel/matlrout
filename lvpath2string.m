function sPath=lvpath2string(lvpath)
%lvpath2string - Convert labView-path to path
%   sPath=lvpath2string(lvpath)
%
% lvpath is part of path after length identifier

%n=typecast(lvpath([4 3 2 1]),'uint32');
n=typecast(lvpath([4 3]),'uint16');	%!!!!!!correctie???
	%%%% wat zijn eerste twee bytes???
iS=5;
c=cell(2,n);
for i=1:n
	c{1,i}=char(lvpath(iS+1:iS+lvpath(iS)));
	c{2,i}=filesep;
	iS=iS+1+double(lvpath(iS));
end
sPath=[c{1:end-1}];
