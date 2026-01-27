function [lOut,varargout]=plotlong(X,Y,varargin)
%plotlong - Plot long data - shows only visible part for faster updates
%    l=plotlong(X,Y)
%    l=plotlong(X,Y[,options][,X2,Y2,...)
%          X : X-vector or dX
%  Made for use together with navfig
%    show only part:
%          plotlong(<x-limit>,<axes>)
% other use
%    X=plotlong('getx',l);
%    Y=plotlong('gety',l);
%    plotlong('setX',l,X)
%    plotlong('setY',l,Y)
%    plotlong('setXY',l,[X,Y])
%    plotlong('setXY',l,X,Y)
%    plotlong decimrate - gives the rate at which the data is decimated
%    plotlong show <type>
%               <type>: mean : plot the mean of decimated parts (default)
%                       minmax : plot a line back and forth showing the min/max
%                       min : plot the minimum
%                       max : plot the maximum
%                       zigzag : plot a "zig-zag-line" (full band)
%                           more statistical calculations:
%                       median :
%                       std : standard deviation
%                       kurtosis :
%                       skewness :
%                       rms : Root Mean Square
%    plotlong showall - shows all (temporarily)
%    plotlong('set',<parameter>,value[,...])	% change settings
%         parameters: nPtMaxFull, nPtDec - determines how much data is shown

if ischar(X)
	switch lower(X)
		case 'getx'
			lOut=getappdata(Y,'Xdata');
			if nargout>1
				xl=get(get(Y,'Parent'),'XLim');
				varargout={lOut(lOut>=xl(1)&lOut<=xl(2))};
				if nargout>2
					varargout{2}=get(Y,'Xdata');
				end
			end
		case 'gety'
			lOut=getappdata(Y,'Ydata');
			if nargout>1
				X=getappdata(Y,'Xdata');
				xl=get(get(Y,'Parent'),'XLim');
				varargout={lOut(X>=xl(1)&X<=xl(2))};
				if nargout>2
					varargout{2}=get(Y,'Ydata');
				end
			end
		case 'setx'
			setappdata(Y,'Xdata',varargin{1});
			plotlong(get(get(Y,'Parent'),'Xlim'),Y)
		case 'sety'
			setappdata(Y,'Ydata',varargin{1});
			plotlong(get(get(Y,'Parent'),'Xlim'),Y)
		case 'setxy'
			if nargin<4
				Z=varargin{1};
				X=Z(:,1);
				Z=Z(:,2);
			else
				X=varargin{1};
				Y=varargin{2};
			end
			setappdata(Y,'Xdata',X);
			setappdata(Y,'Ydata',Z);
			plotlong(get(get(Y,'Parent'),'Xlim'),Y)
		case 'set'
			f=gcf;
			nPtMaxFull=getappdata(f,'nPtMaxFull');
			nPtDec=getappdata(f,'nPtDec');
			setoptions({'nPtMaxFull','nPtDec'},[{Y},varargin]);
			bMax=isempty(nPtMaxFull);
			bDec=isempty(nPtDec);
			if ~bMax&&~bDec&&nPtMaxFull<nPtDec
				error('nPtDec must be smaller than nPtMaxFull!')
			elseif bMax+bDec==1
				if bMax
					nPtMaxFull=round(nPtDec*1.5);
				else
					nPtDec=nPtMaxFull;
				end
			end
			setappdata(f,'nPtMaxFull',nPtMaxFull);
			setappdata(f,'nPtDec',nPtDec);
		case 'decimrate'
			if nargin<2
				Y=findobj(gcf,'Tag','longData');
			end
			if isempty(Y)
				error('No lines found')
			end
			DR=zeros(1,length(Y));
			for i=1:length(Y)
				xl=get(get(Y(i),'Parent'),'XLim');
				X=getappdata(Y(i),'Xdata');
				nReal=sum(X>=xl(1)&X<=xl(2));
				Xs=get(Y(i),'Xdata');
				nShown=sum(Xs>=xl(1)&Xs<=xl(2));
				DR(i)=nShown/nReal;
			end
			if nargout
				lOut=DR;
			else
				DR=DR*100;
				if length(DR)==1||std(DR)<1e-2
					fprintf('shown fraction = %g%%\n',mean(DR))
				else
					fprintf('shown fraction = [%g%%',DR(1))
					fprintf(',%g%%',DR(2:end))
					fprintf(']\n')
				end
			end
		case 'showall'
			if nargin<2
				l=findobj(gcf,'Tag','longData');
			else
				l=Y;
			end
			if isempty(l)
				error('No lines found')
			end
			for i=1:length(l)
				xl=get(get(l(i),'Parent'),'XLim');
				X=getappdata(l(i),'Xdata');
				B=X>=xl(1)&X<=xl(2);
				nReal=sum(B);
				Xs=get(l(i),'Xdata');
				nShown=sum(Xs>=xl(1)&Xs<=xl(2));
				if nShown<nReal
					Y=getappdata(l(i),'Ydata');
					set(l(i),'Xdata',X(B),'Ydata',Y(B))
				end
			end
		case 'show'
			if ~exist('Y','var')||isnumeric(Y)
				if exist('Y','var')
					l=Y;
				else
					l=findobj(gcf,'Tag','longData');
				end
				l=l(1);
				tS=getappdata(l,'show');
				switch tS
					case {[],1}
						tShow='mean';
					case 2
						tShow='minmax';
					case 3
						tShow='min';
					case 4
						tShow='max';
					case 5
						tShow='zigzag';
					case 6
						tShow='median';
					case 7
						tShow='std';
					case 8
						tShow='kurtosis';
					case 9
						tShow='skewness';
					case 10
						tShow='rms';
					otherwise
						error('Unknown show type')
				end
				if nargout
					lOut=tShow;
				else
					fprintf('show type: %s\n',tShow)
				end
			else
				switch lower(Y)
					case 'mean'
						tShow=1;
					case 'minmax'
						tShow=2;
					case 'min'
						tShow=3;
					case 'max'
						tShow=4;
					case 'zigzag'
						tShow=5;
					case 'median'
						tShow=6;
					case 'std'
						tShow=7;
					case 'kurtosis'
						tShow=8;
					case 'skewness'
						tShow=9;
					case 'rms'
						tShow=10;
					otherwise
						error('Wrong show-type')
				end
				if nargin>2
					l=varargin{1};
				else
					l=findobj(gcf,'Tag','longData');
				end
				for i=1:length(l)
					setappdata(l(i),'show',tShow)
					plotlong(get(get(l(i),'Parent'),'Xlim'),l(i))
				end
			end
		otherwise
			error('Wrong use of this function (format plotlong(<string>))')
	end
	return
elseif size(X,1)==1&&size(X,2)==2	% show plots (internal use)
	par=Y;
	l=findobj(par,'Tag','longData');
	nPtMaxFull=[];
	nPtDec=[];
	if ~isempty(l)
		f1=ancestor(l(1),'figure');
		nPtMaxFull=getappdata(f1,'nPtMaxFull');
		nPtDec=getappdata(f1,'nPtDec');
	end
	if isempty(nPtMaxFull)
		nPtMaxFull=1000000;
	end
	if isempty(nPtDec)
		nPtDec=500000;
	end
	for i=1:length(l)
		XX=getappdata(l(i),'Xdata');
		YY=getappdata(l(i),'Ydata');
		tShow=getappdata(l(i),'show');
		bb=XX>=X(1)&XX<=X(2);
		N=sum(bb);
		if N<nPtMaxFull
			XXX=XX(bb);
			YYY=YY(bb);
		else
			nDec=floor(N/nPtDec);
			switch tShow
				case 2	% min/max
					XXX=mean(reshapetrunc(XX(bb),nDec,[]));
					YYY=reshapetrunc(YY(bb),nDec,[]);
					YYYmin=min(YYY);
					YYYmax=max(YYY);
					XXX=XXX([1:end end:-1:1 1]);
					YYY=[YYYmin YYYmax(end:-1:1) YYYmin(1)];
				case {1,3,4,6,7,8,9,10}
					XXX=mean(reshapetrunc(XX(bb),nDec,[]));
					YYY=reshapetrunc(YY(bb),nDec,[]);
					switch tShow
						case 1
							YYY=mean(YYY);
						case 3
							YYY=min(YYY);
						case 4
							YYY=max(YYY);
						case 6
							YYY=median(YYY);
						case 7
							YYY=std(YYY);
						case 8
							YYY=kurtosis(YYY);
						case 9
							YYY=skewness(YYY);
						case 10
							YYY=sqrt(mean(YYY.^2));
					end
				case 5	% zigzag
					XXX=repmat(mean(reshapetrunc(XX(bb),nDec,[])),2,1);
					YYY=reshapetrunc(YY(bb),nDec,[]);
					YYYmin=min(YYY);
					YYYmax=max(YYY);
					YYY=[YYYmin;YYYmax];YYY=YYY(:);
					XXX=XXX(:);
					%!!!this is not optimal and in fact no zigzag
					% make also possible to draw path?
				otherwise
					error('Wrong show-type')
			end
		end
		set(l(i),'XData',XXX,'YData',YYY)
	end
else
	tShow=1;
	if ~isscalar(X) && isrow(X)
		X = X';
	end
	if nargin>1 && isrow(Y)
		Y = Y';
	end
			if nargin==1
		Y=X;
		X=(1:size(X,1))';
	elseif numel(X)==1
		X=(0:size(Y,1)-1)'*X;
	else
		X=X(:);
	end
	iArgIn=1;
	if ~isempty(varargin)
		l=zeros(1,0);
		iPlot=0;
		while true
			iArgIn0=iArgIn;
			if ischar(X)
				error('Wrong use of plotlong')
			end
			while iArgIn<length(varargin)
				if ~ischar(varargin{iArgIn})
					break
				end
				iArgIn=iArgIn+2;
			end
			l1=plot(X(1),Y(1,:),varargin{iArgIn0:iArgIn-1},'Tag','longData');
			for i=1:length(l1)
				setappdata(l1(i),'Xdata',X);
				setappdata(l1(i),'Ydata',Y(:,i));
				setappdata(l1(i),'show',tShow);
			end
			l(1,end+1:end+length(l1))=l1;
			iPlot=iPlot+1;
			if iPlot==1
				hold all
			end
			if iArgIn<length(varargin)
				X=varargin{iArgIn};
				Y=varargin{iArgIn+1};
				iArgIn=iArgIn+2;
			else
				if iArgIn==length(varargin)
					error('Wrong use of plotlong')
				end
				break
			end
		end
		hold off
	else
		l=plot(X(1),Y(1,:),'Tag','longData');
		for i=1:length(l)
			setappdata(l(i),'Xdata',X);
			setappdata(l(i),'Ydata',Y(:,i));
			setappdata(l(i),'show',tShow);
		end
	end
	plotlong(X([1 end])',get(l(1),'Parent'))
	if nargout
		lOut=l;
	end
	navfig longplot
end
