function XY=FindBlocks(h,bSqueeze)
%FindBlocks - Find consecutive blocks in plots (split by NaNs)
%      XY=FindBlocks(h[,bSqueeze])
%   Lines are searched in h (can be axes, figures, ...), default for h: gcf
%      With the "bSqueeze"-option, the lines are put close to each other,
%      still being separated by NaNs.
%
%   here only "X-separated blocks"!
%
%  The result is a 2x2x<n> matrix with
%        first row the minimum (of X and Y) (Y has no meaning!)
%        second row is the maximum
%        first column X
%        second column Y
%        <n> is number of found blocks.

if nargin==0||isempty(h)
	h=gcf;
end

l=findobj(h,'type','line','visible','on');
B=true(size(l));
for i=1:length(l)
	if strcmp(get(l(i),'Tag'),'discardBlocks')
		B(i)=false;
	end
end
if ~all(B)
	l=l(B);
end

XY={};
dx=0;

for i=1:length(l)
	X=get(l(i),'XData');
	Y=get(l(i),'YData');
	B=isnan(X)|isnan(Y);
	j=1;
	n=length(B);
	while j<=n
		if B(j)
			j=j+1;	% do nothin
		else
			k=j+1;
			while k<=n&&~B(k)
				k=k+1;
			end
			[XY,dx]=AddBlock(XY,dx,X(j:k-1),Y(j:k-1));
			j=k+1;
		end
	end		% for all points
end		% for i (all lines)
XY=cat(3,XY{:});
X1=XY(1,1,:);
[~,ii]=sort(X1);
XY=XY(:,:,ii);

if nargin>1&&~isempty(bSqueeze)&&bSqueeze
	n=size(XY,3);
	offset=zeros(1,n);
	offset(1)=-XY(1);
	x=XY(2)-XY(1);
	for i=2:n
		x=x+dx;
		offset(i)=x-XY(1,1,i);
		x=x+XY(2,1,i)-XY(1,1,i);
	end
	for i=1:length(l)
		X=get(l(i),'XData');
		for j=1:n
			B=X>=XY(1,1,j)&X<=XY(2,1,j);
			if any(B)
				X(B)=X(B)+offset(j);
			end
		end
		set(l(i),'XData',X)
	end
end

function [XY,dx]=AddBlock(XY,dx,X,Y)
mnX=min(X);
mxX=max(X);
mnY=min(Y);
mxY=max(Y);

B=false(size(XY));
for i=1:length(XY)
	if (mnX<XY{i}(1)&&mxX>XY{i}(2))	...
			||(mnX>=XY{i}(1)&&mnX<=XY{i}(2))	...
			||(mxX>=XY{i}(1)&&mxX<=XY{i}(2))
		B(i)=true;
		XY{i}(1)=min(XY{i}(1),mnX);
		XY{i}(2)=max(XY{i}(2),mxX);
		% keep running for finding overlaps with others
	end
end
if ~any(B)
	XY{end+1}=[mnX mnY;mxX,mxY];
elseif sum(B)>1
	ii=find(B);
	xy=XY{ii(1)};
	for i=2:length(ii)
		xy(1)=min(xy(1),XY{ii(i)}(1));
		xy(2)=max(xy(2),XY{ii(i)}(2));
	end
	XY{ii(1)}=xy;
	XY(ii(2:end))=[];
end
if length(X)>1
	dx1=abs(median(nonzeros(diff(X))));
	if ~isempty(dx1)&&dx1>0
		if dx==0
			dx=dx1;
		else
			dx=min(dx,dx1);
		end
	end
end
