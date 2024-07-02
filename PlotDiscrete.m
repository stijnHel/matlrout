function lOut=PlotDiscrete(x,y,spec,varargin)
%PlotDiscrete - Plot discrete values
%     PlotDiscrete(x,y[,spec,...])
%         unique values of y are shown as labels in y-axes
%         y can be numeric, but also cell-vector of strings
%     PlotDiscrete(y[,spec,...])
%         spec: cell array: {values;
%                            labels}
%   options:
%         maxValues : 
%         bPlotYdirect : 
%         sTickSpec : in case no spec - format of labels
%                  ( sprintf(sTickSpec,value) ) - default '%g'

sTitle = [];
[plotOptions] = {};

options=varargin;
if nargin<2||(~isnumeric(y)&&~iscell(y))||isempty(y)
	if nargin>2
		options=[{y,spec},varargin];
		spec=[];
	elseif nargin>1
		options={y};
		spec=[];
	else
		spec=[];
	end
	if isa(x,'Simulink.SimulationData.Signal')
		x = x.Values;
	end
	if isa(x,'timeseries')
		sTitle = x.Name;
		y = x.Data;
		x = x.Time;
	else
		y=x;
		x=1:length(y);
	end
elseif nargin<3
	spec=[];
elseif ~iscell(spec)
	options=[{spec},varargin];
	spec=[];
end
if min(size(y))>1
	error('Sorry, this function only works (currently) for vectors!')
end

maxValues=20;
[bPlotYdirect] = [];	% directly plot y-values, otherwise index values
	% default: if small variation true, otherwise false
sTickSpec='%g';
[bUseStairs] = true;

if ~isempty(options)
	setoptions({'maxValues','bPlotYdirect','sTickSpec','bUseStairs','plotOptions'},options{:})
end

if isempty(spec)
	[M,N]=enumeration(y);
	if ~isempty(M)
		[M,iM]=unique(M);
		N=N(iM);
		spec=[num2cell(double(M'));N'];
	end
	if ~iscell(y)
		y=double(y);
	end
end

if isnumeric(y)
	uy=unique(y(~isnan(y)));
else
	uy=unique(y);
end
if length(uy)>maxValues
	error('Sorry, this data has too high number of unique values (#%d)',length(uy))
end

if isempty(bPlotYdirect)
	if ~isnumeric(y)
		bPlotYdirect=false;
	elseif length(uy)<3
		bPlotYdirect=true;
	else
		bPlotYdirect=max(diff(uy))/min(diff(uy))<=4;
	end
end

if bPlotYdirect
	yPlot=y;
	yLabels=uy;
else
	yPlot=nan(size(y));
	for i=1:length(uy)
		if isnumeric(uy)
			yPlot(y==uy(i))=i;
		else
			yPlot(strcmp(uy(i),y))=i;
		end
	end
	yLabels=1:length(uy);
end
if bUseStairs
	l = stairs(x,yPlot,plotOptions{:});
else
	l = plot(x,yPlot,plotOptions{:});
end
grid
if ~bPlotYdirect
	yMin=min(yPlot);
	yMax=max(yPlot);
	ylim([yMin-0.2,yMax+0.2])
end
if iscell(y)
	Yt=uy;
	set(gca,'Ytick',yLabels,'YtickLabel',Yt)
elseif isempty(spec)
	Yt=cell(1,length(uy));
	for i=1:length(Yt)
		Yt{i}=sprintf(sTickSpec,uy(i));
	end
	set(gca,'Ytick',yLabels,'YtickLabel',Yt)
else
	values=[spec{1,:}];
	[~,ii,jj]=intersect(values,uy);
	set(gca,'Ytick',yLabels(jj),'YtickLabel',spec(2,ii))
	if isprop(gca,'TickLabelInterpreter')
		set(gca,'TickLabelInterpreter','none')
	end
end
if ~isempty(sTitle)
	title(sTitle)
end
if nargout
	lOut=l;
end
