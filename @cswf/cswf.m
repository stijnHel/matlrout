function c=cswf(f,type)
% CSWF/CSWF - contstructor voor SWF-object
%    c=cswf(SWF)	(vanuit swf-struct)
%    c=cswf(f[,type])
%         type : (?) gebruik maken van leesswf of leesswf1

global SWF_tags

if ischar(f)
	if nargin>1&~isempty(type)&type
		[C,x]=leesswf1(f,type);
	else
		[C,x]=leesswf(f);
	end
elseif isstruct(f)
	C=f;
	f='onbekendefile';
	x=[];
else
	[C,x]=leesswf(f);
	f='onbekendefile';
end
ids1=cat(2,C.frames{1}.tagID);
C.protected=any(ids1==24);	% !alleen eerste frame wordt bekeken!
C.file=f;
C.x=uint8(x);
c=class(C,'cswf');
