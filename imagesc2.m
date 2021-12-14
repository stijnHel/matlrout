function imagesc2(T,F,X)
%IMAGESC2 - Scaled image - with different X- and Y-steps
%        imagesc2(T,F,X)
%    This could be done with surf too, but displaying big surfaces
%       even in 2D is slow.  Therefore this 2D-imaging is made.
%    This function is not suited for continuously varing data, it is made
%       for data which has stepwise changing dT or dF, or different pieces
%       of the same dT or dF
%    An example of when this routine can be used is after a spectrogram of
%       data which non-linearly spaced data

% example :
% A=rand(1001,201);
% X=[0 0;50 150;200 200];
% Y=[0 0;50 800;1000 1000];
% x=interp1(X(:,1),X(:,2),0:200);
% x(101:end)=x(101:end)+400;
% y=interp1(Y(:,1),Y(:,2),0:1000);
% figure
% imagesc2(x,y,A)
%%%% and compare this with:
% imagesc(x,y,A)

% possible extensions :
%   if all(diff(T)<0) swap plot horizontally
%   if all(diff(F)<0) swap plot vertically

iT=splitranges(T);
iF=splitranges(F);

if size(iT,1)==1&&size(iF,1)==1
	imagesc(T,F,X);
	grid
	axis xy
	return
end

%N_COLOR=64;

mnX=min(X(:));
mxX=max(X(:));
%X=(X-mnX)*(N_COLOR/(mxX-mnX))+1;
hold off
delete(plot(1,1));
grid
set(gca,'CLim',[mnX mxX])
hold on
for iiT=1:size(iT,1)
	i=iT(iiT,1):iT(iiT,2);
	for jjF=1:size(iF,1)
		j=iF(jjF,1):iF(jjF,2);
		imagesc(T(i),F(j),X(j,i))
	end
end
hold off
axis([T(1) T(end) F(1) F(end)])
set(gca,'Layer','top')

function ix=splitranges(x)
LIMDIF=0.1;	% relative difference of x for 
rLow=1-LIMDIF;
rHigh=1+LIMDIF;
dx=diff(x);
if any(dx)<=0
	error('Ranges must be monotonically increasing')
end
ix=zeros(max(10,ceil(length(x)/10)),2);
ix(1)=1;

dx1=dx(1);
i=2;
nx=1;
while i<=length(dx)
	if dx(i)>dx1*rLow&dx(i)<dx1*rHigh
	else
		if ix(nx,1)<i-1
			ix(nx,2)=i+1;
			nx=nx+1;
			ix(nx,1)=i+1;
		elseif nx>1
			ix(nx-1,2)=i-1;
		end
		dx1=dx(i);
	end
	i=i+1;
end
ix(nx,2)=i;
ix=ix(1:nx,:);
