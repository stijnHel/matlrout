function f1=dupfig(f,naam,fig,pos)
% DUPFIG   - Dupliceert een figuur
%    dupfig(f,naam)
%         f = de betreffende figuur
%    dupfig(f,naam,fig,pos)
%         Geeft de mogelijkheid om verschillende figuren
%              naar 1 figuur te kopieren (bv. om verschillende
%              grafieken op 1 blad te kunnen printen)
if ~exist('f');f=[];end
if ~exist('naam');naam=[];end

if exist('fig')&~isempty(fig)
	f1=fig;
else
	f1=nfigure;
end
if isempty(f)
	f=gcf;
elseif length(f)>1
	if ~exist('pos')
		pos=moveass('defpos',f);
	elseif length(pos)<=1
		pos=moveass('defpos',f,pos);
	elseif size(pos)~=[prod(size(f)) 4];
		error('Verkeerd gebruik van dupfig (pos heeft onbruikbare inhoud)')
	end
	for i=1:prod(size(f))
		dupfig(f(i),naam,f1,pos(i,:));
		naam=-1;
	end
	return
end
set(f1,'Color',get(f,'Color')	...
	,'Colormap',get(f,'Colormap')	...
	,'MenuBar','none'	...
	);
finfo=0;
if isempty(naam)
	set(f1,'Name',['kopie ' get(f,'Name')]);
	finfo=1;
elseif ischar(naam)
	set(f1,'Name',naam);
	finfo=1;
end
if finfo
	%m=uimenu('Label','File');
	%uimenu(m	...
	%	, 'Label','Print'	...
	%	, 'CallBack','print1([],-1);');
	set(f1,'NumberTitle',get(f,'NumberTitle')	...
		, 'PaperOrientation',get(f,'PaperOrientation')	...
		, 'PaperPosition',get(f,'PaperPosition')	...
		, 'PaperType',get(f,'PaperType')	...
		, 'Position',get(f,'Position')+[40 -40 0 0]	...
		, 'Resize',get(f,'Resize')	...
		..., 'ShareColors',get(f,'ShareColors')	...
		, 'Units',get(f,'Units')	...
		, 'Clipping',get(f,'Clipping')	...
		);
end

assen=get(f,'Children');
for i=1:length(assen)
	a=assen(i);
	if strcmp(get(a,'Type'),'axes')
		p=get(a,'Position');
		if exist('pos')&~isempty(pos)
			p(1)=pos(1)+p(1)*pos(3);
			p(2)=pos(2)+p(2)*pos(4);
			p(3)=p(3)*pos(3);
			p(4)=p(4)*pos(4);
		end
		a1=axes('Position', p);
		set(a1	...
			, 'AmbientLightColor', get(a, 'AmbientLightColor')	...
			, 'Box', get(a, 'Box')	...
			, 'CameraPosition', get(a, 'CameraPosition')	...
			, 'CameraPositionMode', get(a, 'CameraPositionMode')	...
			, 'CameraTarget', get(a, 'CameraTarget')	...
			, 'CameraTargetMode', get(a, 'CameraTargetMode')	...
			, 'CameraUpVector', get(a, 'CameraUpVector')	...
			, 'CameraUpVectorMode', get(a, 'CameraUpVectorMode')	...
			, 'CameraViewAngle', get(a, 'CameraViewAngle')	...
			, 'CameraViewAngleMode', get(a, 'CameraViewAngleMode')	...
			, 'CLim', get(a, 'CLim')	...
			, 'CLimMode', get(a, 'CLimMode')	...
			, 'Color', get(a, 'Color')	...
			, 'ColorOrder', get(a, 'ColorOrder')	...
			, 'DataAspectRatio', get(a, 'DataAspectRatio')	...
			, 'DataAspectRatioMode', get(a, 'DataAspectRatioMode')	...
			, 'Units', get(a, 'Units')	...
			);
		set(a1	...
			..., 'DrawMode', get(a, 'DrawMode')	...
			, 'FontAngle', get(a, 'FontAngle')	...
			, 'FontName', get(a, 'FontName')	...
			, 'FontSize', get(a, 'FontSize')	...
			, 'FontWeight', get(a, 'FontWeight')	...
			);
		set(a1	...
			, 'GridLineStyle', get(a, 'GridLineStyle')	...
			, 'LineStyleOrder', get(a, 'LineStyleOrder')	...
			, 'LineWidth', get(a, 'LineWidth')	...
			, 'TickLength', get(a, 'TickLength')	...
			, 'TickDir', get(a, 'TickDir')	...
			);
		set(a1	...
			, 'Visible', get(a, 'Visible')	...
			, 'Clipping', get(a, 'Clipping')	...
			);
		b=get(a, 'Children');
		B = false(size(b));
		for j=1:length(b)
			B(j) = strcmp(get(b(j),'Visible'),'off');
		end
		set(a1,'NextPlot','add');
		if any(B)
			b(B)=[];
		end
		for j=1:length(b)
			bType=get(b(j),'Type');
			if strcmp(bType, 'text')
				p=get(b(j),'Position' );
				t1=text(p(1),p(2),get(b(j),'String')	...
					, 'Color', get(b(j), 'Color')	...
					..., 'EraseMode', get(b(j), 'EraseMode')	...
					, 'FontAngle', get(b(j), 'FontAngle')	...
					, 'FontName', get(b(j), 'FontName')	...
					, 'FontSize', get(b(j), 'FontSize')	...
					, 'FontWeight', get(b(j), 'FontWeight')	...
					, 'HorizontalAlignment', get(b(j), 'HorizontalAlignment')	...
					, 'Rotation', get(b(j), 'Rotation')	...
					, 'Units', get(b(j), 'Units')	...
					, 'VerticalAlignment', get(b(j), 'VerticalAlignment')	...
					, 'Clipping', get(b(j), 'Clipping')	...
				);
			elseif strcmp(bType, 'line')
				t1=plot(get(b(j),'Xdata'),get(b(j),'Ydata'));
				set(t1	...
					, 'Color', get(b(j),'Color')	...
					..., 'EraseMode', get(b(j),'EraseMode')	...
					, 'LineStyle', get(b(j),'LineStyle')	...
					, 'LineWidth', get(b(j),'LineWidth')	...
					, 'MarkerSize', get(b(j),'MarkerSize')	...
					);
			else
				fprintf('Er zijn elementen die niet gekopieerd zijn (type=%s)\n',bType);
			end
		end
		set(a1,'NextPlot','replace');
		asTeksten=[get(a,'Title'),get(a,'XLabel'),get(a,'YLabel'),get(a,'ZLabel')];
		kopasTeksten=[get(a1,'Title'),get(a1,'XLabel'),get(a1,'YLabel'),get(a1,'ZLabel')];
		b=asTeksten;
		for j=1:length(asTeksten)
			bType=get(b(j),'Type');
			if strcmp(bType, 'text')
				set(kopasTeksten(j)	...
					, 'String',get(b(j),'String')	...
					, 'Color', get(b(j), 'Color')	...
					..., 'EraseMode', get(b(j), 'EraseMode')	...
					, 'FontAngle', get(b(j), 'FontAngle')	...
					, 'FontName', get(b(j), 'FontName')	...
					, 'FontSize', get(b(j), 'FontSize')	...
					, 'FontWeight', get(b(j), 'FontWeight')	...
					, 'HorizontalAlignment', get(b(j), 'HorizontalAlignment')	...
					, 'Rotation', get(b(j), 'Rotation')	...
					, 'Units', get(b(j), 'Units')	...
					, 'VerticalAlignment', get(b(j), 'VerticalAlignment')	...
					, 'Clipping', get(b(j), 'Clipping')	...
					, 'Visible', 'on'	...
				);
			else
				fprintf('Er zijn asTeksten die niet gekopieerd zijn (type=%s)\n',bType);
			end
		end
		set(a1	...
			, 'View', get(a, 'View')	...
			);
		set(a1	...
			, 'XColor', get(a, 'XColor')	...
			, 'XDir', get(a, 'XDir')	...
			..., 'Xform', get(a, 'Xform')	...
			, 'XGrid', get(a, 'XGrid')	...
			, 'XLim', get(a, 'XLim')	...
			, 'XLimMode', get(a, 'XLimMode')	...
			, 'XScale', get(a, 'XScale')	...
			, 'XTick', get(a, 'XTick')	...
			, 'XTickLabel', get(a, 'XTickLabel')	...
			, 'XTickLabelMode', get(a, 'XTickLabelMode')	...
			, 'XTickMode', get(a, 'XTickMode')	...
			);
		set(a1	...
			, 'YColor', get(a, 'YColor')	...
			, 'YDir', get(a, 'YDir')	...
			, 'YGrid', get(a, 'YGrid')	...
			, 'YLim', get(a, 'YLim')	...
			, 'YLimMode', get(a, 'YLimMode')	...
			, 'YScale', get(a, 'YScale')	...
			, 'YTick', get(a, 'YTick')	...
			, 'YTickLabel', get(a, 'YTickLabel')	...
			, 'YTickLabelMode', get(a, 'YTickLabelMode')	...
			, 'YTickMode', get(a, 'YTickMode')	...
			);
		set(a1	...
			, 'ZColor', get(a, 'ZColor')	...
			, 'ZDir', get(a, 'ZDir')	...
			, 'ZGrid', get(a, 'ZGrid')	...
			, 'ZLim', get(a, 'ZLim')	...
			, 'ZLimMode', get(a, 'ZLimMode')	...
			, 'ZScale', get(a, 'ZScale')	...
			, 'ZTick', get(a, 'ZTick')	...
			, 'ZTickLabel', get(a, 'ZTickLabel')	...
			, 'ZTickLabelMode', get(a, 'ZTickLabelMode')	...
			, 'ZTickMode', get(a, 'ZTickMode')	...
			);
	elseif strcmp(get(a,'Type'),'uimenu')
	elseif strcmp(get(a,'Type'),'uicontrol')
	else
		fprintf('Er zijn zaken niet getekend (%s)\n',get(a,'Type'));
	end
end
