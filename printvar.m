function st=printvar(N,v,g)
% PRINTVAR - Print numerieke waarden van een variogram

if nargin==1
   [N,v,g]=leeslu(N);
end
%   12345678901234567890123456789012345678901324567890
sv='thp \\ V %4.0f %4.0f %4.0f %4.0f %4.0f %4.0f %4.0f %4.0f %4.0f';
sg='%5.1f%% - %4.0f %4.0f %4.0f %4.0f %4.0f %4.0f %4.0f %4.0f %4.0f';
while ~isempty(v)
	nv=min(length(v),8);
	if length(v)-nv==1;nv=nv+1;end
	fprintf([sv(1:8+nv*6) ' [kph]\n'],v(1:nv));
	for i=1:length(g)
		fprintf([sg(1:9+nv*6) '\n'],[g(i) N(1:nv,i)']);
	end
	fprintf('\n')
	v(1:nv)=[];
	N(1:nv,:)=[];
end