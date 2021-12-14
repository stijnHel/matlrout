function [cnt,N]=cntsucc(x)
% CNTSUCC  - Count successive equal numbers
%    [cnt,N]=cntsucc(X);
%        X   : input
%        cnt : counts (cumulative number)
%        N   : number of counts
%                [index[] value[] counts[]]

cnt=ones(length(x),1);
if size(x,1)==1
	cnt=cnt';
end

for i=2:length(x)
	if x(i)==x(i-1)
		cnt(i)=cnt(i-1)+1;
	end
end
if nargout>1
	i=find(diff(cnt)<=0);
	i(end+1)=length(cnt);
	i=i(:);
	N=[i x(i) cnt(i)];
end
