function [x,j]=GetXMLelement(XML,pth)
%GetXMLelement - Get an element from an XML-struct
%    x=GetXMLelement(XML,pth)
%            XML - result of readxml (flattened or not flattened data)
%    pth=GetXMLelement(XML,idx)
%
%  see also readxml

if ischar(pth)
	S=regexp(pth,'/','split');
	if isempty(S{1})
		S(1)=[];
	end
	if isempty(S{end})
		S(end)=[];
	end

	if isscalar(XML)
		x=XML;
		for i=1:length(S)
			j=find(strcmp(S{i},{x.children.tag}));
			if isempty(j)
				error('Can''t find the path (%d - "%s")',i,S{i})
			elseif ~isscalar(j)
				error('Multiple children with the right tag! (%d - "%s")',i,S{i})
			end
			x=x.children(j);
		end
	else
		F=[0 XML(2:end).from];
		iX=1;
		for i=1:length(S)
			jj=find(F==iX);
			j=jj(strcmp(S{i},{XML(jj).tag}));
			if isempty(j)
				error('Can''t find the path (%d - "%s")',i,S{i})
			elseif ~isscalar(j)
				error('Multiple children with the right tag! (%d - "%s")',i,S{i})
			end
			iX=j;
		end
		x=XML(j);
		x.children=XML(F==j);
	end
elseif isnumeric(pth)&&isscalar(pth)
	if isscalar(XML)
		error('Conversion to path can only be used on flattened XML-struct!')
	end
	x=zeros(1,100);
	nx=0;
	iX=pth;
	while iX>1
		nx=nx+1;
		x(nx)=iX;
		iX=XML(iX).from;
	end
	x=sprintf('/%s',XML(x(nx:-1:1)).tag);
else
	error('Wrong input for path (argument 2)!')
end