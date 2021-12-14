function [Z,lOut]=DecimLines(h,n,varargin)
%DecimLines - Decimate data
%     Z=DecimLines(h,n[,options])
%     Z=DecimLines(X,n)
%     DecimLines(h,'restore')
%     DecimLines('restore')
%     DecimLines(h,'resample')	% resample rather than decimate
%  uses decimate (with correction for DC-offset error in decimate)

if nargin<2
	if nargin==0
		n=10;
		h=[];
	else
		n=h;
		h=[];
	end
end
if ischar(h)
	n=h;
	h=[];
elseif ~isscalar(h)&&(isvector(h)||numel(h)>100)
	X=h;
	meanX=mean(X(:,1));
	Z=decimate(X(:,1)-meanX,n)+meanX;
	if size(X,2)>1
		Z(1,size(X,2))=0;
		for i=2:size(X,2)
			meanX=mean(X(:,i));
			Z(:,i)=decimate(X(:,i)-meanX,n)+meanX;
		end
	end
	return
end

[bKeepData] = true;
[bRestore] = false;
[bResample] = false;
dx = [];
if ischar(n)
	if strcmpi(n,'resample')	% fix sample rate
		bResample = true;
		n = 1;
	else
		bRestore=true;
	end
end
if bRestore
	if ~strcmpi(n,'restore')
		error('Wrong use of this function!')
	end
else
	minN=n*3;
end
if nargin>2
	setoptions({'bKeepData','bResample','dx'},varargin{:})
end

if isempty(h)
	h=gcf;
end
if isscalar(h)&&strcmp(get(h,'type'),'figure')
	h=GetNormalAxes(h);
end
l=findobj(h,'type','line','visible','on');
N=zeros(1,length(l));
if nargout
	Z=cell(length(l),2);
	lOut=l;
end
for i=1:length(l)
	if bRestore
		if isappdata(l(i),'OrigData')
			O=getappdata(l(i),'OrigData');
			set(l(i),'XData',O{end,1},'YData',O{end,2})
			if size(O,1)==1
				rmappdata(l(i),'OrigData')
			else
				setappdata(l(i),'OrigData',O(1:end-1,:))
			end
		else
			warning('No restore data available')
		end
	else
		X=get(l(i),'XData');
		N(i)=length(X);
		if N(i)>=minN
			Y=get(l(i),'YData');
			if bKeepData
				if isappdata(l(i),'OrigData')
					O=getappdata(l(i),'OrigData');
					O{end+1,1}=X;
					O{end,2}=Y;
					setappdata(l(i),'OrigData',O)
				else
					setappdata(l(i),'OrigData',{X,Y})
				end
			end
			[X,mnX]=DeNaN(X);
			[Y,mnY]=DeNaN(Y);
			if bResample
				if isempty(dx)
					dx1 = mean(diff(X));
					if min(diff(X))/dx1<0.1
						warning('Resampled to dx = %g, but minimum delta_x = %g!\n',dx1,min(diff(X)))
					end
				else
					dx1 = dx;
				end
				Xnew = (X(1):dx1:X(end))';
				Y = interp1(X(:),Y(:),Xnew);
				X = Xnew;
			end
			if n>1
				Y=decimate(Y-mnY,n)+mnY;
				mn_dX=(X(end)-X(1))/(length(X)-1);
				if mn_dX>0 && std(diff(X))/mn_dX<1e-6
					x1=X(1);
					x2=X(end);
					X=X(round(n/2):n:end);
					if length(X)<length(Y)
						X(end+1)=2*X(end)-X(end-1);
						dx1=X(1)-x1;
						dx2=x2-X(end);
						dx=(dx1-dx2)/2;
						X=X-dx;
					end
				else
					X=decimate(X-mnX,n)+mnX;
				end
			end
			set(l(i),'XData',X,'YData',Y)
			if nargout
				Z{i,1}=X;
				Z{i,2}=Y;
			end
		end
	end		% decimate (no restore)
end		% for i

function [Y,mnY]=DeNaN(Y)
if any(isnan(Y))
	iNaN=find(isnan(Y));
	if iNaN(1)==1
		Y(1)=0;
		iNaN(1)=[];
	end
	for i=1:length(iNaN)
		Y(iNaN(i))=Y(iNaN(i)-1);
	end
end		% NaNs
mnY=mean(Y);
