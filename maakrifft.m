function [x,yy]=maakrifft(y,opt)
%MAAKRIFFT - Maak reele inverse fft
%      [x,yy]=maakrifft(y,opt);
%             y : voorstel fft
%             opt :
%                 1 (default) : verdubbel lengte met juiste symmetrie
%                 momenteel geen andere mogelijkheden

if nargin>1
	if isempty(opt)||(length(opt)==1&&opt==1)
		% OK
	else
		error('Onmogelijke optie')
	end
end
yy=y;
if size(yy,1)==1
	yy=[yy conj(yy(end-1:-1:2))];
else
	yy=[yy;conj(yy(end-1:-1:2))];
end
x=real(ifft(yy));
