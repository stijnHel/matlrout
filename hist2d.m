function [varargout]=hist2d(x,y,dx,dy)
%hist2d   - Create a 2D histogram
%    [A,X,Y]=hist2d(x,y,dx,dy)
%    [A,X,Y]=hist2d(x,y,nx,ny)

if nargin<3
	dx=[];
end
if nargin<4
	dy=[];
end

mnX=min(x);
mxX=max(x);
if isempty(dx)
	dx=(mxX-mnX)/99;
elseif dx<0||dx==round(dx)
	nX=abs(dx);
	dx=(mxX-mnX)/nX;
end
nX=round((mxX-mnX)/dx+1);
mnY=min(y);
mxY=max(y);
if isempty(dy)
	dy=(mxY-mnY)/99;
elseif dy<0||dy==round(dy)
	nY=abs(dy);
	dy=(mxY-mnY)/nY;
end
nY=round((mxY-mnY)/dy+1);

A=zeros(nY,nX);
ix=round((x-mnX)/dx);
iy=round((y-mnY)/dy);
bOK=ix>=0&ix<nX&iy>=0&iy<nY;
ix=ix(bOK);
iy=iy(bOK);
for i=1:length(ix)
	ii=ix(i)+1;
	jj=iy(i)+1;
	A(jj,ii)=A(jj,ii)+1;
end

varargout=cell(1,nargout);
varargout{1}=A;
if nargout>1
	varargout{2}=(0:nX-1)*dx+mnX;
	if nargout>2
		varargout{3}=(0:nY-1)'*dy+mnY;
	end
end
