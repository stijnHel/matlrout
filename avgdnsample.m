function y=avgdnsample(x,N,typ)
%AVGDNSAMPLE - Downsampling by averaging
%         y=avgdnsample(x,N[,typ])
%           typ : type of averaging
%               1 (default) : divide signal in N blocks and
%                     take average
%               2 : not really downsampling : convolution with
%                     N ones (divided by N for scaling)

iType=1;
if nargin>2
	if ~isempty(typ)&&typ(1)==2
		iType=2;
	end
end
if N==1
	y=x;
elseif iType==1
	y=mean(reshape(x(1:end-rem(end,N)),N,[]));
else	% iType==2
	y=conv(ones(1,N(i))/N(i),x);
	y=y(N:end-N+1);
end
