function b = isstringlike(s)
%isstringlike - combination of ischar and isstring
%        b = isstringlike(s)

b = ischar(s) || isstring(s);
	% only allow one string?
