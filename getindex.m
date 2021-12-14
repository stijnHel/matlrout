function [iList,hOut]=getindex(bAll)
% GETINDEX - Geeft indices van getoonde meetsignaal (gelimitteerd volgens x-as)

if nargin==0
	bAll=false;
end
l=[findobj(gca,'type','line');findobj(gca,'type','image');findobj(gca,'type','stair')];
if isempty(l)
	error('geen lijn gevonden in huidige as')
end
if bAll
	iList=cell(1,length(l));
	h=l;
else
	iList=[];
	h=[];
end
n=0;
xlim=get(gca,'XLim');
for i=1:length(l)
	X=get(l(i),'xdata');
	i1=find(X>=xlim(1)&X<=xlim(2));
	n1=length(i1);
	if bAll
		iList{i}=i1;
	elseif n1>n
		n=n1;
		iList=i1;
		h=l(i);
		if false&&length(i1)>2&&~bAll	%!!!!
			break;
		end
	end
end
if nargout>1
	hOut=h;
end
