function [l,XY,II,JJ]=plotcycl(x,y,period,varargin)
%plotcycl - Plot cyclic data (phase diagram)
%    Plot cyclic data in a phase diagram (without lines crossing the graph)
%       also plots lines
%        [l,XY]=plotcycl(x,y,period[,<plotargs>])
%
%               available "plotargs":
%                    bPlotMultiLines (separate lines if true), default false
%                    bMultiColor
%                    xOffset   offset for not going from 0..<+period>
%
% see also plotphase

bPlotMultiLines=[];
bMultiColor=false;
xOffset=0;
options=varargin;
pcOptions=options;	% plotcycl-options
if ~isempty(options)
	if length(options)==1
		options=options{1};
	end
	[S,B]=setoptions(2,{'bPlotMultiLines','bMultiColor','xOffset'},options);
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
if isempty(bPlotMultiLines)
	if bMultiColor
		bPlotMultiLines=true; %#ok<UNRCH>
	else
		bPlotMultiLines=false;
	end
end

if min(size(y))>1
	bMultiX=all(size(x)>1);
	if ~bMultiX&&size(y,1)~=length(x)
		y=y';
	end
	nChans=size(y,2);
	OUT=cell(nChans,nargout);
	for i=1:nChans
		[OUT{i,:}]=plotcycl(x,y(:,i),period,pcOptions);
		if i==1
			hold all
		end
	end
	hold off
	return
end

nPt=length(x);
xPhase=mod(x-xOffset,period)+xOffset;
iCross=find(abs(diff(xPhase))>period/2);
xNew=zeros(nPt+3*length(iCross),1);
yNew=zeros(size(xNew));
nII=length(iCross)+2;
II=zeros(2,nII);

i1=0;
di=0;
for i=1:length(iCross)
	iX=iCross(i);
	ii=i1+1:iX;
	jj=ii+di;
	xNew(jj)=xPhase(ii);
	yNew(jj)=y(ii);
	sdx=sign(x(iX+1)-x(iX));
	xNew(iX+di+1)=xPhase(iX+1)+period*sdx;
	yNew(iX+di+1)=y(iX+1);
	xNew(iX+di+2)=NaN;	% new line segment
	yNew(iX+di+2)=NaN;
	II(1,i+1)=iX+di+2;
	II(2,i+1)=iX+1;
	xNew(iX+di+3)=xPhase(iX)-period*sdx;
	yNew(iX+di+3)=y(iX);
	i1=iX;
	di=di+3;
end
ii=i1+1:nPt;
jj=ii+di;
II(1,nII)=jj(end)+1;
II(2,nII)=nPt+1;
xNew(jj)=xPhase(ii);
yNew(jj)=y(ii);
if bPlotMultiLines
	lPlot=zeros(1,nII-1);
	delete(plot(0,0));	% use default plot-display
	ccc=get(gca,'ColorOrder');
	if ~bMultiColor
		ccc=ccc(1,:);
	end
	nCol=size(ccc,1);
	for i=1:length(lPlot)
		ii=II(1,i)+1:II(1,i+1)-1;
		lPlot(i)=line(xNew(ii),yNew(ii),'Color',ccc(rem(i-1,nCol)+1,:));
	end
else
	lPlot=plot(xNew,yNew,options{:});
end
set(gca,'xlim',[0 period]+xOffset)
if nargout>0
	l=lPlot;
	if nargout>1
		XY=[xNew(:) yNew(:)];
		if nargout>3
			cII=cell(1,nII-1);
			for i=1:length(cII)
				cII{i}=max(1,II(2,i)-1):min(nPt,II(2,i+1)+1);
			end
			JJ=cat(2,cII{:});
		end
	end
end
