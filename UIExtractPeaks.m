function UIExtractPeaks(varargin)
%UIExtractPeaks - Find the peak in selected regions
%     UIExtractPeaks start - Starts the functionality for the current figure
%         UIExtractPeaks(<fig>,'start')	 - the same for figure <fig>
%     UIExtractPeaks stop - Stops the functionality
%     UIExtractPeaks(<option-name>,<option-value>) - sets an option
%         options:
%
%   Using UIExtractPeaks
%      after startup (see above):
%          select a rectangular area - all consequtive points are taken, a
%          polynomial is fitted, and the maximum is calculated


if nargin==0
	error('An input argument must be given')
elseif ~ischar(varargin{1})
	error('The first argument must be a string')
end

if isnumeric(varargin{1})
	fig=varargin{1};
	if ~all(ishandle(fig))
		error('No handle?!')
	end
	in=varargin(2:end);
	if nargin<2
		error('If a handle is given, at least two inputs are expected!')
	end
else
	fig=gcf;
	in=varargin;
end
switch lower(in{1})
	case 'start'
		S=struct('bPlotLine',false);
		set(GetNormalAxes(fig),'ButtonDownFcn',@PointClicked)
		if length(in)>1
			S=setoptions(S,in{2:end});
		end
		setappdata(fig,'UIEP_SETTINGS',S)
	case 'stop'
		set(GetNormalAxes(fig),'ButtonDownFcn','')
	case 'remove'
		l=findobj(fig,'Tag','UIEP_marker');
		if ~isempty(l)
			delete(l)
		end
	otherwise
		error('unknown input')
end

function PointClicked(h,~)
ax = ancestor(h,'axes');
pt1 = get(ax,'CurrentPoint');
rbbox;
pt2 = get(ax,'CurrentPoint');
S=getappdata(get(ax,'Parent'),'UIEP_SETTINGS');
pt1 = pt1(1,1:2);
pt2 = pt2(1,1:2);
p1 = min(pt1,pt2);
p2 = max(pt1,pt2);
l=findobj(ax,'Type','line');
for i=1:length(l)
	X=get(l(i),'XData');
	Y=get(l(i),'YData');
	B=X>=p1(1)&X<=p2(1)&Y>=p1(2)&Y<=p2(2);
	if any(B)&&~strcmp(get(l(i),'Tag'),'UIEP_marker')	% don't handle "own lines"
		j=1;
		n=length(B);
		while j<=n
			if B(j)
				j1=j;
				while j<=n&&B(j)
					j=j+1;
				end
				ii=j1:j-1;
				if isscalar(ii)
					x=X(ii);
					y=Y(ii);
				elseif length(ii)==2
					if Y(ii(1))>Y(ii(2))
						x=X(ii(1));
						y=Y(ii(1));
					elseif Y(ii(1))<Y(ii(2))
						x=X(ii(2));
						y=Y(ii(2));
					else	% equal
						x=mean(X(ii));
						y=Y(ii(1));
					end
				else	% more points
					[p,~,mu]=polyfit(X(ii),Y(ii),2);
					x=mu(1)-p(2)/2/p(1)*mu(2);
					y=p(3)-p(2)^2/4/p(1);
				end
				if S.bPlotLine
					if length(ii)<=2	% plot point
						line(x,y,'Color',[1 0 1]	...
							,'Marker','o'	...
							,'Tag','UIEP_marker')
					else	% plot line
						mnX=min(X(ii));
						mxX=max(X(ii));
						if mxX>mnX
							xPlot=mnX:(mxX-mnX)/20:mxX;
							yPlot=polyval(p,xPlot);
							line(xPlot,yPlot,'Color',[1 0 1]	...
								,'Tag','UIEP_marker')
						end
					end		% plot line
				end		% S.bPlotLine
				fprintf('Peak: (%10g , %10g)\n',x,y)
			end		% if B(j)
			j=j+1;
		end		% while j<=n
	end		% any point selected
end
