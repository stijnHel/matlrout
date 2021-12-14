function Xout=pictdata(c,i,j)
% CSWF/PICTDATA - Geeft picture-data
%    pictdata(c,i)	(i-de picture)
%    pictdata(c,i,j)

if nargin==2
	if length(i)==1
		k=zoekpicts(c);
		j=k(i,2);
		i=k(i,1);
	else
		j=i(2);
		i=i(1);
	end
end

x=gettagdata(c,i,j);
if isfield(x,'JPEG')
	%x=x.JPEG;
	%if x(1)~=255|x(2)~=216
	%	error('Verkeerde data')
	%end
	%i1=find(x(3:end-1)==255&x(4:end)==216);
	%i2=find(x(3:end-1)==255&x(4:end)==217);
	j=cjpeg(x.JPEG);
	X=leesscan(j);	% ??meerdere scans?
else
	error('Dit type is nog niet voorzien.')
end

if nargout
	Xout=X;
else
	nfigure
	colormap(gray)
	for i=1:length(X)
		subplot(length(X),1,i)
		image(X{i})
	end
end
