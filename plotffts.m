function [fOut,Data] = plotffts(f,varargin)
%PLOTFFTS - Plot FFT's van data van data van lijnen in een figuur
%    plotffts([f[,opties]])
% opties:
%     NMAXLIJN : maximum number of lines
%     NMINLENGTH : minimum number of points to calculate FFT
%     windowUsed : use of window (none(0), hanning(1), hamming(2))
%
% other use
%     plotffts setDefault : restore default settings
%     plotffts settings : displays the settings
%         (S = plotffts('settings'); returns the settings in a struct)
% if the figure (or first handle supplied) has PLOTFFTsets as appdata, then
%     this is used as settings (to allow "local settings")

%bLinkT_Fdomains : being added
%        idea: recalculate (and plot) FFT's after change of position
%   for simple situations it worked, but!
%        no use of settings
%        no use of window(!)

global PLOTFFTsets

[bAparteAssen] = false;
[bTotaalSig] = false;
[bClearFigs] = true;

if isempty(PLOTFFTsets)
	PLOTFFTsets=DefaultSets();
end

if nargin>0&&ischar(f)
	if strcmpi(f,'settings')
		if nargout
			fOut=PLOTFFTsets;
		elseif nargin>1&&isstruct(varargin{1})
			if nargin>2
				error('Only 2 input arguments are allowed in this case!')
			end
			PLOTFFTsets=varargin{1};
		else
			if nargin==1
				a={};
			else
				a=varargin;
			end
			PLOTFFTsets=defSetFcn(PLOTFFTsets,a{:});
		end
	elseif strcmpi(f,'setDefault')
		PLOTFFTsets=DefaultSets();
	else
		PLOTFFTsets=defSetFcn(PLOTFFTsets,varargin{:});
	end
	return
end
if ~exist('f','var')
	f=gcf;
elseif isempty(f)
	% nothing to do (except maybe settings change)
	return
end
if isappdata(f(1),'PLOTFFTsets')
	S=getappdata(f(1),'PLOTFFTsets');
else
	S=PLOTFFTsets;
end

NMAXLIJN=S.NmaxLijn;
NMINLENGTH=S.NminLength;
windowUsed=S.windowUsed;
bHalfFFT=S.bHalfFFT;
bPlotPhase=S.bPlotPhase;
interpType=S.interpType;
bFreqHz=S.bFreqHz;
bUnwrapPhase=S.bUnwrapPhase;
bLogX=S.bLogX;
bLogY=S.bLogY;
bNewFigure=S.bNewFigure;
bLinkT_Fdomains=S.bLinkT_Fdomains;
freqLim=[];
[bClearAxes]=false;	% used in combination with (~bNewFigure)
tagWin=[];
if ~isempty(varargin)
	setoptions({'NMAXLIJN','NMINLENGTH','windowUsed','bHalfFFT'	...
		,'bPlotPhase','bFreqHz','bUnwrapPhase','bLogX','bLogY'	...
		,'bNewFigure','bLinkT_Fdomains','freqLim','bClearAxes'	...
		,'tagWin','bClearFigs'},varargin{:})
end
if isscalar(f)&&strcmp(get(f,'type'),'figure')
	f=GetNormalAxes(f);
end
l=[findobj(f,'type','line');findobj(f,'type','stair')];
l=l(end:-1:1);	% voor zelfde volgorde van lijnen in zelfde grafiek
lNE=zeros(1,length(l));	% not equidistant lines
nLines=zeros(1,length(l));
assen0=zeros(1,length(l));	% currently not used further - position is used!
nAs=0;
%???is het nodig deze loop apart van de volgende te doen???
for i=1:length(l)
	ax1=get(l(i),'Parent');
	B=ax1==assen0(1:nAs);
	if any(B)
		nLines(B)=nLines(B)+1;
	else
		nAs=nAs+1;
		nLines(nAs)=1;
		assen0(nAs)=ax1;
	end
	xlim=get(ax1,'XLim');
	x=get(l(i),'XData');
	if isduration(x)
		xlim = seconds(xlim);
		x = seconds(x);
	end
	if ~bTotaalSig
		x=x(x>=xlim(1)&x<=xlim(2));
	end
	if length(x)<NMINLENGTH
		fprintf('lijn met %d punten werd weggelaten\n',length(x))
		l(i)=0;
	elseif all(diff(x)<0)  && std(diff(x))<-mean(diff(x))*1e-2
		x = -x;
	elseif any(diff(x)<=0)||std(diff(x))/mean(diff(x))>1e-2
		fprintf('lijn met niet equidistante punten (of dalende x-waarden) werd weggelaten\n')
		lNE(i)=l(i);
		l(i)=0;
	end
end
l(l==0)=[];
n=length(l);
bInterpolate=false;
if n==0
	if any(lNE)
		l=lNE(lNE~=0);
		n=length(l);
		warning('PLOTFFTS:InterplolatedData','FFT on linear interpolated data (since no equidistant data was found)!')
		bInterpolate=true;
	else
		error('geen lijnen gevonden')
	end
end
if length(l)>NMAXLIJN
	error('!te veel lijnen voor frequentieanalyse!')
end

Assen=zeros(length(l),1);	% if ~bAparteAssen - assen0 can be used!
P=zeros(length(l),4);
nAs=0;
if bPlotPhase
	AssenP=zeros(length(l),1);
end
if bNewFigure
	if ~isempty(tagWin)
		if ischar(tagWin)
			if strcmp(tagWin,'*')	% default - based on tag of source window
				tagWin=get(ancestor(f(1),'figure'),'Tag');
				if isempty(tagWin)
					warning('With tagWin=''*'' option, a tag in the original window is expected!')
					tagWin='plot';
				end
				tagWinAbs=[tagWin,'_fftAbs'];
				tagWinPhase=[tagWin '_fftPhase'];
			else
				tagWinAbs=tagWin;
				tagWinPhase=[tagWin '_phase'];
			end
		elseif iscell(tagWin)
			tagWinAbs=tagWin{1};
			if length(tagWin)>1
				tagWinPhase=tagWin{2};
			else
				tagWinPhase=[tagWinAbs '_phase'];
			end
		else
			error('Wrong input for tagWin!')
		end
		fFFT=getmakefig(tagWinAbs);
		if bClearFigs
			clf
		end
		if bPlotPhase
			fPhase=getmakefig(tagWinPhase);
			if bClearFigs
				clf
			end
		end
	elseif exist('nfigure','file')
		fFFT=nfigure;
		if bPlotPhase
			fPhase=nfigure;
		end
	else
		fFFT=figure;
		if bPlotPhase
			fPhase=figure;
		end
	end
else
	[fFFT,bNewFFTfig]=getmakefig('FFTSfigABS');
	if ~bNewFFTfig
		Assen=getappdata(fFFT,'PLOTFFTaxABS');
		nAs=length(Assen);
		P=zeros(nAs,4);
		for i=1:nAs
			P(i,:)=get(Assen(i),'Position');
		end
		if bClearAxes
			delete(findobj(Assen,'type','line'))
		end
	end
	if bPlotPhase
		[fPhase,bNewPhaseFig]=getmakefig('FFTSfigPHASE');
		if bNewPhaseFig
			AssenP=zeros(length(l),1);
		else
			AssenP=setappdata(fPhase,'PLOTFFTaxANGLE');
			if bClearAxes
				delete(findobj(AssenP,'type','line'))
			end
		end
	end
end
bDataOut = nargout>1;
if bDataOut
	Data = struct('l',[],'T',cell(1,n),'dt',[],'X',[],'Xdc',[],'F',[],'Z',[]);
end
for i=1:n
	ax1=get(l(i),'Parent');
	xlim=get(ax1,'XLim');
	bLogScale=S.bUseLogInLogP&&strcmp(get(ax1,'YScale'),'log');
	lcolor=get(l(i),'color');
	bNewAxes=false;
	if bAparteAssen
		axPlot=subplot(n,1,i,'Parent',fFFT);
		bNewAxes=true;
		if bPlotPhase
			axPPlot=subplot(n,1,i,'Parent',fPhase);
		end
	else
		p1=get(ax1,'Position');
		if nAs==0
			j=[];
		else
			dP=abs(P(1:nAs,:)-p1(ones(nAs,1),:));
			j=find(all(dP<1e-4,2));
			if ~isempty(j)
				axPlot=Assen(j(1));
				if bPlotPhase
					axPPlot=AssenP(j(1));
				end
			end
		end
		if isempty(j)
			nAs=nAs+1;
			if bNewFigure||bNewFFTfig
				axPlot=axes('Parent',fFFT,'Position',p1);
				bNewAxes=true;
				Assen(nAs)=axPlot;
				if nLines(nAs)>1
					mn=uicontextmenu('Parent',fFFT);
					uimenu(mn,'Label','Divide plot','Callback',@DivPlot);
					set(axPlot,'UIContextMenu',mn)
				end
			else
				axPlot=Assen(nAs);
			end
			if bPlotPhase
				axPPlot=axes('Parent',fPhase,'Position',p1);
				AssenP(nAs)=axPPlot;
				if nLines(nAs)>1
					mn=uicontextmenu('Parent',fPhase);
					uimenu(mn,'Label','Diff plot','Callback',@DiffPlot);
					set(axPPlot,'UIContextMenu',mn)
				end
			end
			P(nAs,:)=p1;
		end
	end
	if bNewAxes
		h=plot(axPlot,0,0);	% make default axes-setting for plots
		grid(axPlot)
		delete(h)
		hAxTit=get(ax1,'Title');
		tit=get(hAxTit,'String');
		if size(tit,1)>1
			tit=tit(1,:);
		end
		if bLogScale
			tit=['log-' tit]; %#ok<AGROW>
		end
		set(get(axPlot,'Title'),'String',['freq-' tit]	...
			,'Interpreter',get(hAxTit,'Interpreter')	...
			)
		if bPlotPhase
			h=plot(axPPlot,0,0);	% make default axes-setting for plots
			grid(axPPlot)
			delete(h)
			set(get(axPPlot,'Title')	...
				,'String',['angle-' get(get(ax1,'Title'),'String')]	...
				,'Interpreter',get(hAxTit,'Interpreter')	...
				)
		end
	end
	T=get(l(i),'xdata');
	if bTotaalSig
		j=1:length(x);
	else
		j=find(T>=xlim(1)&T<=xlim(2));
	end
	if length(j)<NMINLENGTH
		title(axPlot,'Te weinig punten')
		return
	end
	dt=mean(diff(T(j)));
	X=get(l(i),'ydata');
	if bInterpolate
		if dt>0
			T1=T(j(1));
			T2=T(j(end));
		else
			T2=T(j(1));
			T1=T(j(end));
		end
		if j(1)>1	% add previous point
			j=[j(1)-1;j(:)];
		end
		if j(end)<length(T)	% add next point
			j(end+1)=j(end)+1; %#ok<AGROW>
		end
		dt = abs(mean(diff(T(j))));
		Teq=T1:dt:T2+(T2-T1)*100*eps;
		T = T(j);
		if isempty(interpType)
			X=interp1(T,X(j),Teq);
		else
			X=interp1(T,X(j),Teq,interpType);
		end
	else
		T=T(j);
		X=X(j);
	end
	if isa(windowUsed,'function_handle') || ischar(windowUsed)&&any(strcmp(windowUsed	...
			,{'hanning','hamming','hann','bartlett','blackman'	...
			,'chebwin','taylorwin','gausswin','kaiser'	...
			,'turkeywin'}))
		H=feval(windowUsed,length(X));
	else
		switch windowUsed
			case {0,'none'}
				H=ones(length(X),1);
			case 1
				H=hanning(length(X));
			case 2
				H=hamming(length(X));
			otherwise
		end
	end
	if isrow(H)~=isrow(X)
		H=H';
	end
	X1=X;
	if bLogScale
		if any(X1<=0)
			if any(X1>0)
				X1(X1<=0)=min(X1(X1>0));
				warning('PLOTFFTS:negLog','logFFT of negative data! - truncated to minimum positive value')
			else
				warning('PLOTFFTS:logNoPos','logFFT of full negative (or zero) data!')
				X1(:)=1;
			end
		end
		X1=log(X1);
	end
	if ~isa(X1,'double')
		X1=double(X1);
	end
	if S.detrend
		X1=detrend(X1);
		Xdc = 0;
	else
		Xdc = mean(X1);
		X1=X1-Xdc;
	end
	X1=X1.*H;
	Y=fft(X1)/(length(X1)/2);
	if bHalfFFT
		Y=Y(1:ceil(end/2));
	end
	dt=abs(dt);
	F=(0:length(Y)-1)/length(X1)/dt;
	if bDataOut
		Data(i).l = l(i);
		Data(i).T = T;
		Data(i).X = X;
		Data(i).dt = dt;
		Data(i).Xdc = Xdc;
		Data(i).F = F;
		Data(i).Z = Y;
	end
	if ~bFreqHz
		F=F*(2*pi);
	end
	AxLimX=[0 0.5/dt];	% even if plotted more, show maximum up to Nyquist frequency
	if bLogX
		F(1)=[];
		Y(1)=[];
		set(axPlot,'XScale','log')
	end
	if bLogY
		set(axPlot,'YScale','log')
	end
	if ~isempty(freqLim)
		if isscalar(freqLim)
			B=F<=freqLim;
		else
			B=F>=freqLim(1)&F<=freqLim(2);
		end
		F=F(B);
		Y=Y(B);
		AxLimX=F([1 end]);
	end
	lFFT=line(F,abs(Y),'color',lcolor,'linestyle',get(l(i),'linestyle')	...
		,'Parent',axPlot);
	if bLinkT_Fdomains
		FFTlink=struct('nPt',length(X),'hFFT',lFFT);
		setappdata(l(i),'FFTlink',FFTlink)
	end
	set(axPlot,'XLim',AxLimX)
	if bPlotPhase
		A=angle(Y);
		if bUnwrapPhase
			A=unwrap(A);
		end
		line(F,A*180/pi,'color',lcolor,'linestyle',get(l(i),'linestyle'),'Parent',axPPlot);
		set(axPPlot,'XLim',[0 .5/dt])
	end
end
setappdata(fFFT,'PLOTFFTaxABS',Assen(1:nAs))
if bLinkT_Fdomains
	%use updateAxes-option in navfig
	navfig(ancestor(f(1),'figure'),'updateAxes',@UpdateFFT)
end
if bPlotPhase
	navfig('link',[fFFT,fPhase])
	setappdata(fPhase,'PLOTFFTaxANGLE',AssenP(1:nAs))
else
	navfig
end
if nargout
	fOut=fFFT;
end

function DivPlot(~,~)	% (handle can't be used since it's a uimenu and no axes
l=findobj(gca,'Type','line');
if length(l)<2
	error('Only possible for axes with multiple lines!')
end
X0=get(l(end),'XData');
Y0=get(l(end),'YData');
for i=1:length(l)-1
	if ~isequal(X0,get(l(i),'XData'))
		error('All lines should have the same X-data!')
	end
	Y=get(l(i),'YData');
	set(l(i),'YData',Y./Y0)
end
delete(l(end))

function DiffPlot(~,~)	% (handle can't be used since it's a uimenu and no axes
l=findobj(gca,'Type','line');
if length(l)<2
	error('Only possible for axes with multiple lines!')
end
X0=get(l(end),'XData');
Y0=get(l(end),'YData');
for i=1:length(l)-1
	if ~isequal(X0,get(l(i),'XData'))
		error('All lines should have the same X-data!')
	end
	Y=get(l(i),'YData');
	set(l(i),'YData',mod(Y-Y0+180,360)-180)
end
delete(l(end))

function UpdateFFT(ax)
ch=get(ax,'Children');
xl=xlim;
for i=1:length(ch)
	FFTlink=getappdata(ch(i),'FFTlink');
	if ~isempty(FFTlink)
		x=get(ch(i),'XData');
		B=x>=xl(1)&x<=xl(2);
		nPt=sum(B);
		if nPt>31
			try
				if nPt~=FFTlink.nPt
					x=x(B);
					dt=mean(diff(x));
					X=(0:length(x)-1)/length(x)/dt;
					set(FFTlink.hFFT,'XData',X);
				end
				y=get(ch(i),'YData');
				y=y(B);
				Y=abs(fft(y));	% (!!!!!) no windowing and division by length(y)/2?!
				set(FFTlink.hFFT,'YData',Y)
			catch err
				DispErr(err)
				warning('Error while updating FFT - action stopped')
				rmappdata(ch(i),'FFTlink')
			end
		end
	end
end

function S=DefaultSets()
S=struct('NmaxLijn',50,'NminLength',32,'windowUsed',1	...
	,'detrend',false,'bHalfFFT',false,'bPlotPhase',false	...
	,'interpType',[],'bUseLogInLogP',true	...
	,'bUnwrapPhase',false,'bFreqHz',true		...
	,'bLogX',false,'bLogY',false,'bNewFigure',true,'bLinkT_Fdomains',false);
