function SpecUtils(varargin)
%SpecUtils - UI-uitilities for spectral images.
%
% Utilty (made as a demo) to give the possibility to plot "cuts" of
% spectral images.
% With
%            SpecUtil
%    the functionality is added to the image on the current figure.
% From then on, you can right-click on the image to plot a cut through that
% point parallel to the X- or Y-axis.
% "X-cut" makes the "cut" through a point on the X-axes, which means that
% you get a graph as a function on what's displayed on the Y-axes in the
% spectral image.
% The "cut-ranges" calculates the mean over the displayed portion.
%
% Extra:
%         SpecUtil legend    (with active window plots of SpecUtil)
%              adds a legend
%         SpecUtil list
%              lists the plotted lines

%further ideas
%   range-cuts are calculating the linear mean
%       an option (check in context menu) can be added to give the
%          possibility for "linear means based on logaritmic data)
%       sum rather than mean can also be useful.
%   SpecUtils legend & list in case of categories (not numeric axes)
%       --> display category, not number!

if nargin==0
	h=[findobj(gcf,'type','image');findobj(gcf,'type','surface')];
	if isempty(h)
		error('No images found')
	end
	if length(h)>1
		tags=get(h,'Tag');
		B=startsWith(tags,'TMW_');	% still usefull?
		if any(B)
			h(B)=[];
		end
	end
elseif ischar(varargin{1})
	switch lower(varargin{1})
		case 'legend'
			S=GetLdata(gcf);
			L=cell(1,length(S));
			for i=1:length(S)
				s=[S(i).typ ': '];
				switch length(S(i).R)
					case 1
						s=[s num2str(S(i).R)]; %#ok<AGROW>
					case 2
						s=sprintf('%s%g-%g',s,S(i).R);
				end
				L{i}=s;
			end
			legend(L)
			return
		case 'list'
			S=GetLdata(gcf);
			for i=1:length(S)
				fprintf('%-8s: %8g',S(i).typ,S(i).R(1))
				if length(S(i).R)>1
					fprintf(' - %8g',S(i).R(2:end))
				end
				fprintf('\n')
			end
			return
	end
else
	h=varargin{1};
end

for iH=1:length(h)
	hCM=uicontextmenu('UserData',h(iH));
	uimenu(hCM,'Label','plot X-cut','Callback',@(h,~) PlotCut(h,'X'));
	uimenu(hCM,'Label','plot X-cut range','Callback',@(h,~) PlotCut(h,'Xrange'));
	uimenu(hCM,'Label','plot X-cut range (RMS)','Callback',@(h,~) PlotCut(h,'XrangeRMS'));
	uimenu(hCM,'Label','add X-cut','Callback',@(h,~) AddCut(h,'X'));
	uimenu(hCM,'Label','add X-cut range','Callback',@(h,~) AddCut(h,'Xrange'));
	uimenu(hCM,'Label','add X-cut range (RMS)','Callback',@(h,~) AddCut(h,'XrangeRMS'));
	uimenu(hCM,'Label','Create following X-cut','Callback',@(h,~) CreateFollowingCut(h,'X'));
	uimenu(hCM,'Label','plot Y-cut','Callback',@(h,~) PlotCut(h,'Y'),'separator','on');
	uimenu(hCM,'Label','plot Y-cut range','Callback',@(h,~) PlotCut(h,'Yrange'));
	uimenu(hCM,'Label','plot Y-cut range (RMS)','Callback',@(h,~) PlotCut(h,'YrangeRMS'));
	uimenu(hCM,'Label','add Y-cut','Callback',@(h,~) AddCut(h,'Y'));
	uimenu(hCM,'Label','add Y-cut range','Callback',@(h,~) AddCut(h,'Yrange'));
	uimenu(hCM,'Label','add Y-cut range (RMS)','Callback',@(h,~) AddCut(h,'Yrange'));
	uimenu(hCM,'Label','Create following Y-cut','Callback',@(h,~) CreateFollowingCut(h,'Y'));
	set(h(iH),'UIContextMenu',hCM);
end

function S=GetLdata(f)
l=findobj(f,'Tag','SpecPlot');
if isempty(l)
	error('No lines found!')
end
S=getappdata(l(1),'SpecData');
S(1,length(l))=S;
for i=2:length(l)
	S(i)=getappdata(l(i),'SpecData');
end
nrs=cat(2,S.i);
[~,i]=sort(nrs);
S=S(i);

function [Xdata,Ydata,D,bColorImage]=ExtractData(h,ax)
hCM=ancestor(h,'uicontextmenu');
hImage=get(hCM,'UserData');
hAx=get(hImage,'parent');
p=get(hAx,'CurrentPoint');
X=get(hImage,'Xdata');
Y=get(hImage,'Ydata');
C=get(hImage,'Cdata');
bColorImage=~ismatrix(C);
i=[];
if length(X)==2&&size(C,2)>2	% color image
	X=(0:size(C,2)-1)*(diff(X)/(size(C,2)-1))+X(1);
elseif size(C,2)==1	% single column ==> make sure X becomes scalar
	X=mean(X);
elseif size(C,2)~=length(X)
	warning('SPECUTIL:RescaledX','X-data not the right length - rescaled!')
	X=(0:size(C,2)-1)/(size(C,2)-1)*(X(end)-X(1))+X(1);
end
if length(Y)==2&&size(C,1)>2	% color image
	Y=(0:size(C,1)-1)*(diff(Y)/(size(C,1)-1))+Y(1);
elseif size(C,1)==1	% single column ==> make sure Y becomes scalar
	Y=mean(Y);
elseif size(C,1)~=length(Y)
	warning('SPECUTIL:RescaledY','Y-data not the right length - rescaled!')
	Y=(0:size(C,1)-1)/(size(C,1)-1)*(Y(end)-Y(1))+Y(1);
end
switch ax
	case 'X'
		R=p(1);
		i=findclose(X,R);
		Ydata=C(:,i,:);
		Xdata=Y;
	case 'Y'
		R=p(1,2);
		i=findclose(Y,R);
		Ydata=C(i,:,:);
		Xdata=X;
	case 'Xrange'
		xl=get(hAx,'Xlim');
		R=xl;
		b=X>=xl(1)&X<=xl(2);
		Ydata=mean(C(:,b,:),2);
		Xdata=Y;
	case 'XrangeRMS'
		xl=get(hAx,'Xlim');
		R=xl;
		b=X>=xl(1)&X<=xl(2);
		Ydata=sqrt(mean(C(:,b,:).^2,2));
		Xdata=Y;
	case 'Yrange'
		xl=get(hAx,'Ylim');
		R=xl;
		b=Y>=xl(1)&Y<=xl(2);
		Ydata=mean(C(b,:,:),1);
		Xdata=X;
	case 'YrangeRMS'
		xl=get(hAx,'Ylim');
		R=xl;
		b=Y>=xl(1)&Y<=xl(2);
		Ydata=sqrt(mean(C(b,:,:).^2,1));
		Xdata=X;
	otherwise
		error('Wrong use of this function')
end
if ~ismatrix(Ydata)
	Ydata=squeeze(Ydata);
end
D=struct('src',hImage,'typ',ax,'R',R,'C',C,'i',i,'X',X,'Y',Y);

function fPlot=GetFigure
fPlot=findobj('Type','figure','Tag','SpecUtilsPlot');
if isempty(fPlot)
	error('Can''t find a plot-window')
end
if length(fPlot)>1
	%???hoe keuze maken??
	fPlot=fPlot(1);
end

function PlotGraph(typ,X,Y,D,bColor)
switch typ
	case 'plot'
		axParent = ancestor(D.src,'axes');
		switch D.typ(1)
			case 'X'
				lab=get(axParent,'YLabel');
				xLim = ylim(axParent);
			case 'Y'
				lab=get(axParent,'XLabel');
				xLim = xlim(axParent);
			otherwise
				error('Unexpected type!')
		end
		f=nfigure('Tag','SpecUtilsPlot');
		if bColor
			set(f,'DefaultAxesColororder',[1 0 0;0 1 0;0 0 1])
		end
		l=plot(X,Y);grid
		xlabel(get(lab,'String'),'Interpreter',get(lab,'Interpreter'))
		hTit=get(axParent,'Title');
		title(get(hTit,'String'),'Interpreter',get(hTit,'Interpreter'))
		if isappdata(axParent,'LayoutPeers')
			% if colorbar with ylabel exists, use it for new ylabel
			cb = getappdata(axParent,'LayoutPeers');
			b = false;
			for i=1:length(cb)
				b = isa(cb(i),'matlab.graphics.illustration.ColorBar');
				if b
					cb = cb(i);
					break
				end
			end
			if b
				yl = get(get(cb,'YLabel'),'String');
				if ~isempty(yl)
					ylabel(yl)
				end
			end
		end
		navfig
		if isappdata(axParent,'updateAxes')	...
				&& D.typ(1)=='Y'	...
				&& isequal(getappdata(axParent,'updateAxes'),@axtick2date)
			navfig updateAxesT
		end
		bepfig(xLim)
	case 'add'
		fPlot=GetFigure;
		figure(fPlot)
		hold all
		l=plot(X,Y);
		hold off
	otherwise
		error('Wrong use of this function')
end
set(l,'Tag','SpecPlot')
n=length(findobj(get(l(1),'parent'),'Tag','SpecPlot'));
D.i=n;
for i=1:length(l)
	setappdata(l(i),'SpecData',D)
end

function PlotCut(h,typ)
[X,Y,D,bColor]=ExtractData(h,typ);
PlotGraph('plot',X,Y,D,bColor);

function AddCut(h,typ)
[X,Y,D]=ExtractData(h,typ);
PlotGraph('add',X,Y,D);

function CreateFollowingCut(h,typ)
[X,Y,D]=ExtractData(h,typ);
ax = ancestor(D.src,'axes');
f=ancestor(h,'figure');
tickLabels = [];
if typ=='X'
	fcnMoved = @MouseMovedX;
	if strcmp(get(ax,'XTickLabelMode'),'manual')&&length(D.X)==length(get(ax,'XTickLabel'))
		setappdata(f,'labelledData',true)
	elseif isappdata(f,'labelledData')
		rmappdata(f,'labelledData')
	end
	if strcmp(get(ax,'YTickLabelMode'),'manual')&&length(D.Y)==length(get(ax,'YTickLabel'))
		tickLabels = {get(ax,'YTick'),get(ax,'YTickLabel')};
	end
	xLim = ylim(ax);
else
	fcnMoved = @MouseMovedY;
	if strcmp(get(ax,'YTickLabelMode'),'manual')&&length(D.Y)==length(get(ax,'YTickLabel'))
		setappdata(f,'labelledData',true)
	elseif isappdata(f,'labelledData')
		rmappdata(f,'labelledData')
	end
	if strcmp(get(ax,'XTickLabelMode'),'manual')&&length(D.X)==length(get(ax,'XTickLabel'))
		tickLabels = {get(ax,'YTick'),get(ax,'XTickLabel')};
	end
	xLim = xlim(ax);
end
nfigure
l=plot(X,Y);grid
if ~isempty(tickLabels)
	set(gca,'XTick',tickLabels{1},'XTicklabel',tickLabels{2})
	xtickangle(45)
end
navfig
if isappdata(ax,'updateAxes')	...
		&& typ=='Y'	...
		&& isequal(getappdata(ax,'updateAxes'),@axtick2date)
	navfig updateAxesT
end
bepfig(xLim)
setappdata(f,'followLine',l)
setappdata(l,'baseFigure',f)
setappdata(f,'followData',D)
set(f,'WindowButtonMotionFcn',fcnMoved)

function MouseMovedX(h,~)
f=ancestor(h,'figure');
ax = gca(f);
l=getappdata(f,'followLine');
if ~isgraphics(l)
	set(f,'WindowButtonMotionFcn','1;')
	return
end
bLabelled = getappdata(f,'labelledData');
if isempty(bLabelled)
	bLabelled = false;
end
D=getappdata(f,'followData');

pt=get(ax,'currentPoint');
i=max(1,min(size(D.C,2),round((length(D.X)-1)*(pt(1)-D.X(1))/(D.X(end)-D.X(1))+1)));
set(l,'ydata',D.C(:,i))
if bLabelled
	LAB = get(ax,'XTickLabel');
	sVal = LAB{i};
else
	sVal = sprintf('%g',pt(1));
end
title(ancestor(l,'axes'),sprintf('%d: %s',i,sVal))

function MouseMovedY(h,~)
f=ancestor(h,'figure');
ax = gca(f);
l=getappdata(f,'followLine');
if ~isgraphics(l)
	set(f,'WindowButtonMotionFcn','1;')
	return
end
bLabelled = getappdata(f,'labelledData');
if isempty(bLabelled)
	bLabelled = false;
end
D=getappdata(f,'followData');

pt=get(ax,'currentPoint');
i=max(1,min(size(D.C,1),round((length(D.Y)-1)*(pt(1,2)-D.Y(1))/(D.Y(end)-D.Y(1))+1)));
set(l,'ydata',D.C(i,:))
if bLabelled
	LAB = get(ax,'YTickLabel');
	sVal = LAB{i};
else
	sVal = sprintf('%g',pt(1,2));
end
title(ancestor(l,'axes'),sprintf('%d: %s',i,sVal))
