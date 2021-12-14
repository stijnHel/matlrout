function Dp=diffm(p,n)
% DIFFM    - Toont of geeft differenties van een rij getallen
if ~exist('n');n=[];end
if nargin==0;help diffm;return;end
if length(p)<2
	Dp=p;
	return
end
s=size(p);
nn=prod(s);
p=p(:);
if isempty(n)
	n=nn-1;
end
n=min(nn-1,n);

dp=zeros(nn,n+1);
dp(:,1)=p;
for i=1:n
	dp(1:nn-i,i+1)=diff(dp(1:nn-i+1,i));
end


if nargout
	if s(2)>1
		Dp=dp';
	else
		Dp=dp;
	end
else
	if all(p==floor(p))
		nc=0;
	else
		ss=max(abs(p));
		if ss==0;ss=1;end
		nc=5-max(0,ceil(log10(ss))+1);
	end
	t=sprintf('%%6.%df  ',nc);
	for i=1:n+1
		fprintf(blanks((i-1)*4));
		fprintf(t,dp(1:nn-i+1,i));
		fprintf('\n')
	end
end
