function SetPtsNaN(h,ax,f,value)
%SetPtsNav - Removes points in graph
%   SetPtsNaN(h,ax,f,value)
%    h    - handle of figure, axes
%    ax   - 'x' or 'y'
%    f    - function (@lt, ..., '<','>','='
%    value - limit value
%      if not given, a default (5.sigma) is used (only for '<' or '>')
%         this is done for every line separately, otherwise one value
%            for all line is used

if ischar(f)
	switch f
		case '='
			f=@eq;
		case '<'
			f=@lt;
		case '<='
			f=@le;
		case '>'
			f=@gt;
		case '>='
			f=@ge;
		otherwise
			error('unknown function')
	end
end
if ~exist('value','var')
	value=[];
end
if isempty(value)
	if isequal(f,@lt)||isequal(f,@le)
		bLow=true;
	elseif isequal(f,@gt)||isequal(f,@ge)
		bLow=false;
	else
		error('Default value can only be done for "<" and ">"!')
	end
end

l=findobj(h,'type','line');
v=value;
for i=1:length(l)
	z=get(l(i),[ax 'data']);
	if isempty(value)
		mn=mean(z(~isnan(z)&~isinf(z)));
		s=std(z(~isnan(z)&~isinf(z)));
		if bLow
			v=mn-5*s;
		else
			v=mn+5*s;
		end
	end
	z(f(z,v))=NaN;
	set(l(i),[ax 'data'],z)
end
