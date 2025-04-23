function s = percent_string(s,sPercent)
%percent_string - Convert "percent encoded strings"
%       sConverted = percent_string(sPercent)
%       s = percent_string([],s)

if nargin==2 && ~isempty(sPercent)
	if ~isempty(s)
		warning('First argument is neglected!')
	end
	s = sPercent;
	if isstring(s)
		s = char(s);
	end
	cReserved = '!#$&''()*+,/:;=?@[]';
	cUnreserved = ['0':'9','A':'Z','a':'z','-._~'];
	BCok = false(1,max(abs(s)));
	if any(abs(s)>255)
		warning('!!! 16-bit characters are not(really) forseen!!')
	end
	Breserved = false(1,255);
	Breserved(abs(cReserved)) = true;
	Bunreserved = false(1,255);
	Bunreserved(abs(cUnreserved)) = true;
	i = 1;
	while i<=length(s)
		c = s(i);
		if c>255
			bb = typecast(uint16(c),'uint8');
			cc = sprintf('%%%02X',bb);
			s = [s(1:i-1),cc,s(i+1:end)];
			i = i+6;
		elseif c==0	|| Breserved(abs(c)) || ~Bunreserved(abs(c))
			cc = sprintf('%%%02X',abs(c));
			s = [s(1:i-1),cc,s(i+1:end)];
			i = i+3;
		else
			i = i+1;
		end
	end
else
	if isstring(s)
		s = char(s);
	end
	i = 1;
	while i<length(s)-1
		if s(i)=='%'
			h = upper(s(i+1:i+2));
			if any(h<'0' | h>'F' | (h>'9' & h<'A'))
				warning('Wrong percent-code?! (#%d - "%s")',i,h)
			else
				s = [s(1:i-1),char(hex2dec(h)),s(i+3:end)];
			end
		end
		i = i+1;
	end		% while i
end		% if convert from 
