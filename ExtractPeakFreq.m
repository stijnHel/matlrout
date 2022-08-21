function [Sout,Aout]=ExtractPeakFreq(fig,varargin)
%ExtractPeakFreq - Extract frequency (and amplitude) from FFT-plot
%    S=ExtractPeakFreq(fig) - gcf if fig is not given
%         (fig can also be a handle to an axes - or even to a line)
%         S: struct with peak frequencies
%    [f,A]=ExtractPeakFreq(...)
%
%   taken from StoneHann
%
% It is supposed that a hanning window is used (default for plotffts).
%
% see also plotffts, StoneHann

bDisp=nargout==0;
[bPlotPeak]=false;
[bDot]=false;
[bHalfPlot]=false;	% Plot half amplitudes (max peak in DFT plot)
nPeaks=1;
[bCalcPeriods]=false;	% Calculate periods (1/f)

if nargin==0||isempty(fig)
	fig=[];
	options=varargin;
elseif ischar(fig)
	options=[{fig},varargin];
	fig=[];
else
	options=varargin;
end
if isempty(fig)
	fig=gcf;
end
if ~isempty(options)
	setoptions({'bDisp','bPlotPeak','bDot','bHalfPlot','nPeaks','bCalcPeriods'}	...
		,options{:})
end

l=findobj(fig,'Type','line');

S=struct('line',num2cell(l),'f',[],'A',[],'per',[],'iMax',[],'di',[]);
for i=1:length(l)
	x=get(l(i),'XData');
	if length(x)<8
		continue
	end
	y=get(l(i),'YData');
	xl=get(ancestor(l(i),'axes'),'XLim');
	B=x>=xl(1)&x<=xl(2);
	x=x(B);
	y=y(B);
	if length(x)>1
		dx=x(2)-x(1);
	else
		dx=0;
	end
	
	if sum(B)<2
		continue
	end
	[S(i).f,S(i).A,S(i).iMax,S(i).di]=CalcFreqPeak(x,y,nPeaks);
	S(i).per=1./S(i).f;
	S(i).dx=dx;
	if bDisp && ~isempty(S(i).A)
		if bCalcPeriods
			fprintf('#%2d: per=%10g (%9g-%9g), A=%10g\n',i,S(i).per(1),1./x(S(i).iMax+S(i).di+[1 0]),S(i).A(1))
			%fprintf('#%2d: per=%10g, A=%10g\n',i,S(i).per(1),S(i).A(1))
		else
			fprintf('#%2d: f=%10g Hz (%8g), A=%10g\n',i,S(i).f(1),dx,S(i).A(1))
		end
		if length(S(i).A)>1
			if bCalcPeriods
				fprintf('     per=%10g, A=%10g\n',[S(i).per(2:end);S(i).A(2:end)])
			else
				fprintf('     f=%10g Hz, A=%10g\n',[S(i).f(2:end);S(i).A(2:end)])
			end
		end
	end
	if bPlotPeak
		A=S(i).A;
		if bHalfPlot
			A=A/2;
		end
		if bDot
			line(S(i).f,A,'Color',get(l(i),'Color')	...
				,'Parent',get(l(i),'Parent')	...
				,'Marker','o','linestyle','none'	...
				,'Tag','FreqPeakLine'	...
				)
		else
			for j=1:length(A)
				line(S(i).f(j)+[0 0],[0,A(j)],'Color',get(l(i),'Color')	...
					,'Parent',get(l(i),'Parent')	...
					,'Tag','FreqPeakLine'	...
					)
			end
		end
	end
end

if nargout
	if nargout==1
		Sout=S;
	else
		Sout=[S.f];
		Aout=[S.A];
	end
end
