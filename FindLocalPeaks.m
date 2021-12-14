function Sout=FindLocalPeaks(fig,varargin)
%FindLocalPeaks - Find local peaks via polyfit of local maxima/minima
%    S=FindLocalPeaks(fig) - gcf if fig is not given
%         (fig can also be a handle to an axes - or even to a line)
%    S=FindLocalPeaks(x,y)

if nargin==0||isempty(fig)
	fig=gcf;
end

[bMinimum]=false;
[bPlotPts]=false;
[cMarker]=[1 0 0];
marker='o';
markerSize=get(0,'defaultlinemarkersize');
if length(fig)<20&&all(ishandle(fig))
	nInUsed=1;
	bGraphInput=true;
	l=findobj(fig,'Type','line');
	nSigs=numel(l);
	S=struct('line',num2cell(l),'xMax',[],'yMax',[]);
else
	X=fig;
	Y=varargin{1};
	bGraphInput=false;
	nInUsed=2;
	nSigs=max(size(X,2),size(Y,2));
end

if nargin>nInUsed
	setoptions({'bMinimum','bPlotPts','cMarker','marker'},varargin{nInUsed:end})
end

for i=1:nSigs
	if bGraphInput
		x=get(l(i),'XData');
		y=get(l(i),'YData');
		xl=get(ancestor(l(i),'axes'),'XLim');
		B=x>=xl(1)&x<=xl(2);
		x=x(B);
		y=y(B);
	else
		if bPlotPts
			error('Sorry, bPlotPts-option is only possible in graphical case!')
		end
		if i<=size(X,2)
			x=X(:,i);
		end
		if i<=size(Y,2)
			y=Y(:,i);
		end
	end
	if length(x)<3
		continue
	end
	
	if bMinimum
		ii=find(y(2:end-1)<=y(1:end-2)&y(2:end-1)<y(3:end));	% could be improved especially if y_i==y_i+1!
	else
		ii=find(y(2:end-1)>=y(1:end-2)&y(2:end-1)>y(3:end));	% could be improved especially if y_i==y_i+1!
	end
	xMax=zeros(1,length(ii));
	yMax=zeros(1,length(ii));
	for j=1:length(ii)
		i0=ii(j)+1;
		p=polyfit(x(ii(j):ii(j)+2)-x(i0),y(ii(j):ii(j)+2)-y(i0),2);
		xMax(j)=-p(2)/p(1)/2;
		yMax(j)=polyval(p,xMax(j))+y(i0);
		xMax(j)=x(i0)+xMax(j);
		if nargout==0
			fprintf('#%2d',i)
			if length(ii)>1
				fprintf(' (%d)',j)
			end
			fprintf(': x=%10g, y=%10g\n',xMax(j),yMax(j))
		end
	end
	if bPlotPts
		line(xMax,yMax,'Parent',ancestor(l(i),'axes'),'Color',cMarker	...
			,'markerSize',markerSize,'Tag','FLPmarker','linestyle','none'	...
			,'Marker',marker)
	end
	S(i).xMax=xMax;
	S(i).yMax=yMax;
end

if nargout
	Sout=S;
end
