function UIRemovePoints(varargin)
%UIRemovePoints - Removal of points of lines in a user interactive way
%     UIRemovePoints start - Starts the functionality for the current figure
%         UIRemovePoints(<fig>,'start')	 - the same for figure <fig>
%     UIRemovePoints stop - Stops the functionality
%     UIRemovePoints(<option-name>,<option-value>) - sets an option
%         options:
%                 'style': 'remove': just removing points
%                          'fill-linear': fill in via linear interpolation
%                          'set0': sets to zero
%
%   Using UIRemovePoints
%      after startup (see above):
%          select a rectangular area - all points of all lines within this
%              area will be removed


% toevoegen: bijhouden wat weggehaald wordt

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
		set(GetNormalAxes(fig),'ButtonDownFcn',@PointClicked)
		if length(in)>1
			if ischar(in{2})
				UIRemovePoints('style',in{2})
			else
				error('Wrong input')
			end
		end
	case 'stop'
		set(GetNormalAxes(fig),'ButtonDownFcn','')
	case 'style'
		if nargin<1
			s=RPstyle(fig);
			fprintf('UIRemovePoints style = ''%s''\n',s)
			return
		elseif ~ischar(in{2})||isempty(in{2})
			error('A not-empty char is expected for style')
		elseif strncmpi(in{2},'remove',length(in{2}))
			s='remove';
		elseif strncmpi(in{2},'set0',length(in{2}))
			s='set0';
		elseif strncmpi(in{2},'fill-linear',length(in{2}))
			s='fill-linear';
		else
			error('Unknown style')
		end
		setappdata(fig,'UIRPstyle',s)
	otherwise
		error('unknown input')
end

function PointClicked(h,~)
ax = ancestor(h,'axes');
pt1 = get(ax,'CurrentPoint');
rbbox;
pt2 = get(ax,'CurrentPoint');
pt1 = pt1(1,1:2);
pt2 = pt2(1,1:2);
p1 = min(pt1,pt2);
p2 = max(pt1,pt2);
fig=get(ax,'Parent');
style=RPstyle(fig);
l=findobj(ax,'Type','line');
for i=1:length(l)
	X=get(l(i),'XData');
	Y=get(l(i),'YData');
	B=X>=p1(1)&X<=p2(1)&Y>=p1(2)&Y<=p2(2);
	if any(B)
		switch style
			case 'remove'
				X(B)=[];
				Y(B)=[];
			case 'set0'
				Y(B)=0;
			case 'fill-linear'
				j=1;
				n=length(B);
				while j<=n
					if B(j)
						j1=j;
						while j<=n&&B(j)
							j=j+1;
						end
						if j1==1
							if j>n
								warning('All points of line #%d removed!',i)
								X=[];
								Y=[];
							else
								Y(1:j-1)=Y(j);
							end
						elseif j>n
							Y(j1:n)=Y(j1-1);
						else
							Y(j1:j-1)=Y(j1-1)+(1:j-j1)/(j-j1+1)*(Y(j)-Y(j1-1));
						end
					end		% if B(j)
					j=j+1;
				end		% while j<=n
			otherwise
				error('Unknown style')
		end
		set(l(i),'XData',X,'YData',Y)
	end
end

function s=RPstyle(fig)
s=getappdata(fig,'UIRPstyle');
if isempty(s)
	s='remove';
end
