function c=plus(a,b)
% UINT8/PLUS - a+b for UINT8 class
%   eenvoudige implementatie langs double om

if isa(a,'uint8')
	if isa(b,'uint8')
		c=uint8(bitand(255,double(a)+double(b)));
	elseif isa(b,'int8')
		c=int8(bitand(255,double(a)+double(b)));	% !!!!
	else
		c=double(a)+double(b);
		if ~isa(b,'double')
			c=cat(b,class(b));
		end
	end
else	% b must be uint8 (otherwise this function wasn't called
end
