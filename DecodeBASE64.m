function x = DecodeBASE64(s,bMulti)
%DecodeBASE64 - Decode data encoded as base64
%       x = DecodeBASE64(s[,bMulti])

if nargin<2||isempty(bMulti)
	bMulti = false;
end

Cmime = char(zeros(1,64));
Cmime( 1:26) = 'A':'Z';
Cmime(27:52) = 'a':'z';
Cmime(53:62) = '0':'9';
Cmime(63) = '+';
Cmime(64) = '/';

Xmime = zeros(1,127)-1;
Xmime(abs(Cmime)) = 0:63;

if any(s=='=')
	if bMulti
		ii = [0 find(s=='=') length(s)+1];
		BA = false(1,length(ii)-1);
		A = cell(size(BA));
		for i=1:length(BA)
			if ii(i+1)-ii(i)==2
				warning('BASE64-string of length 1?! - not decoded! (%d)',ii(i)+1)
			elseif ii(i+1)-ii(i)>2
				BA(i) = true;
				A{i} = Decode(s(ii(i)+1:ii(i+1)-1));
			end
		end
		x = A(BA);
		return
	else
		i = find(s=='=',1);
		warning('Decoding stopped after first "="-character! (%d/%d)',i,length(s))
		s = s(1:i-1);
	end
end
x = Decode(s);

	function D = Decode(s)
		X = Xmime(abs(s));
		if any(X<0)
			error('Not allowed characters!')
		end
		nBytes = length(X)*0.75;
		if rem(length(X),4)
			nBytes = floor(nBytes);
			n = ceil(length(X)/4)*4;
			X(end+1:n) = 0;
		end
		X = [262144 4096 64 1]*reshape(X,4,[]);
		Y = uint8([floor(X/65536);bitand(floor(X/256),255);bitand(X,255)]);
		D = Y(:)';
		if length(D)>nBytes
			D = D(1:nBytes);
		end
	end
end
