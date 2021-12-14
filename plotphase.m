function [l,xPhase]=plotphase(x,y,phase,varargin)
%plotphase - Plot cyclic data (phase diagram)
%    Plot cyclic data in a phase diagram (without lines crossing the graph)
%       also plots lines
%        l=plotphase(x,y,phase[,<plotargs>])
%              phase: binary (true when new phase)
%                     index (indexes of start of new phase)
%       counts on relatively small successive change in "speed" (diff(x))
% see also plotcycl

bPlotMultiLines=false;
bNormX=true;
options=varargin;
if ~isempty(options)
	if length(options)==1
		options=options{1};
	end
	[S,B]=setoptions(2,{'bPlotMultiLines','bNormX'},options);
	if all(B)
		struct2var(S);
		options={};
	elseif any(B)
		struct2var(S);
		options=reshape(options,2,[]);
		options=options(:,~B);
		options=options(:)';
	end
end

if islogical(phase)||length(phase)>length(x)-5
	iCross=find(phase);
else
	iCross=phase;
end
xNew=zeros(length(x)+3*length(iCross),1);
yNew=zeros(size(xNew));
II=zeros(1,length(iCross));
xPhase=NaN(length(x),1);	% only needed if nargout>1

iStart=2;
%i1=0;	% if use start
i1=iCross(1);
di=-i1;
x2=x(max(1,i1));
for i=iStart:length(iCross)-1
	iX=iCross(i);
	ii=i1+1:iX;
	jj=ii+di;
	x1=x2;
	x2=x(iX);
	xPhase(ii)=(x(ii)-x1)/(x2-x1);
	if bNormX
		xNew(jj)=(x(ii)-x1)/(x2-x1);
		xNew(iX+di+1)=(x(iX+1)-x1)/(x2-x1);
		xNew(iX+di+3)=(x(iX)-x2)/(x2-x1);
	else
		xNew(jj)=x(ii)-x1; %#ok<UNRCH>
		xNew(iX+di+1)=x(iX+1)-x1;
		xNew(iX+di+3)=x(iX)-x2;
	end
	yNew(jj)=y(ii);
	yNew(iX+di+1)=y(iX+1);
	xNew(iX+di+2)=NaN;	% new line segment
	yNew(iX+di+2)=NaN;
	yNew(iX+di+3)=y(iX);
	II(i+1)=iX+di+2;
	i1=iX;
	di=di+3;
end
xNew=xNew(1:iX+di-1);
yNew=yNew(1:iX+di-1);
if bPlotMultiLines
	lPlot=zeros(1,length(II)-1);
	delete(plot(0,0));	% use default plot-display
	for i=iStart:length(lPlot)
		ii=II(i)+1:II(i+1)-1;
		lPlot(i)=line(xNew(ii),yNew(ii));
	end
else
	lPlot=plot(xNew,yNew,options{:});
end
set(gca,'xlim',[0 1])
if nargout>0
	l=lPlot;
end
