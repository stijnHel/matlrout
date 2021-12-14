function s = ReplHexChars(s)
%ReplHexChars - Replace "HEX-characters" in a string
%       s = ReplHexChars(s)

Bhex = false(1,255);	% (assuming no zeros)
Bhex(abs(['0':'9','A':'F','a':'f'])) = true;

i=1;
while i<length(s)-1
	if s(i)=='%' && all(Bhex(abs(s(i+1:i+2))))
		c = char(hex2dec(s(i+1:i+2)));
		s = [s(1:i-1) c s(i+3:end)];
	end
	i = i+1;
end
