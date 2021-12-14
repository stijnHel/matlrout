function theAxis = subp(nrows, ncols, thisPlot, titel, varargin)
%SUBP Create axes in tiled positions with title.
% 	SUBP(m,n,p), or SUBP(mnp), breaks the Figure window into
% 	an m-by-n matrix of small axes, selects the p-th axes for
% 	for the current plot, and returns the axis handle.  The axes
%	are counted along the top row of the Figure window, then the
%	second row, etc.  For example,
%
% 	    SUBP(2,1,1), PLOT(income)
% 	    SUBP(2,1,2), PLOT(outgo)
%
% 	plots income on the top half of the window and outgo on the
%	bottom half.
%
% 	SUBP(m,n,p), if the axis already exists, makes it current.
%	SUBP(H), where H is an axis handle, is another way of making
%	an axis current for subsequent plotting commands.
%
%	If a SUBP specification causes a new axis to overlap an
%	existing axis, the existing axis is deleted.  For example,
%	the statement SUBP(1,1,1) deletes all existing smaller
%	axes in the Figure window and creates a new full-figure axis.
%       The title can be put by :
%           SUBP(m,n,0, 'titel' )

%	Copyright (c) 1984-93 by The MathWorks, Inc.

% we will kill all overlapping siblings if we encounter the mnp
% specifier, else we won't bother to check:
narg = nargin;
kill_siblings = 0;
create_axis = 1;
delay_destroy = 0;
if narg == 0 % make compatible with 3.5, i.e. subplot == subplot(111)
	nrows = 111;
	narg = 1;
end

%check for encoded format
if narg == 1
	% The argument could be one of 3 things:
	% 1) a 3-digit number 100 < num < 1000, of the format mnp
	% 2) a 3-character string containing a number as above
	% 3) an axis handle
	code = nrows;
	
	% turn string into a number:
	if(ischar(code))
		code = eval(code);
	end
	
	% number with a fractional part can only be an identifier:
	if(rem(code,1) > 0)
		handle1 = code;
		if ~strcmp(get(handle1,'type'),'axes')
			error('Requires valid axes handle for input.')
		end
		create_axis = 0;
		% all other numbers will be converted to mnp format:
	else
		thisPlot = rem(code, 10);
		ncols = rem( fix(code-thisPlot)/10,10);
		nrows = fix(code/100);
		if nrows*ncols < thisPlot
			error('Index exceeds number of subplots.');
		end
		kill_siblings = 1;
		delay_destroy = (code == 111);
	end
elseif narg == 2
	% The arguments MUST be the string 'position' and a 4-element vector:
	if strcmpi(nrows, 'position')
		pos_size = size(ncols);
		if(pos_size(1) * pos_size(2) == 4)
			position = ncols;
		else
			error(['subplot(''position'',',...
				' [left bottom width height]) is what works'])
		end
	else
		error('Unknown command option')
	end
elseif narg >= 3
	% passed in subplot(m,n,p [,titel]) -- we should kill overlaps
	% here too:
	kill_siblings = 1;
end

% if we recovered an identifier earlier, use it:
if exist('handle1','var')
	set(get(0,'CurrentFigure'),'CurrentAxes',handle1);
	% if we haven't recovered position yet, generate it from mnp info:
elseif ~exist('position','var')
	if (thisPlot < 0) || (nrows > 9)
		error('Must be fewer than nine rows or columns.')
	elseif (thisPlot > ncols*nrows)
		error('Index exceeds number of subplots.')
	else
		% This is the percent offset from the subplot grid of the plotbox.
		PERC_OFFSET_L = 0.09;
		PERC_OFFSET_R = 0.045;
		PERC_OFFSET_B = PERC_OFFSET_L;
		PERC_OFFSET_T = PERC_OFFSET_R;
		if nrows > 2
			PERC_OFFSET_T = 0.9*PERC_OFFSET_T;
			PERC_OFFSET_B = 0.9*PERC_OFFSET_B;
		end
		if ncols > 2
			PERC_OFFSET_L = 0.9*PERC_OFFSET_L;
			PERC_OFFSET_R = 0.9*PERC_OFFSET_R;
		end
		
		row = (nrows-1) -fix((thisPlot-1)/ncols);
		col = rem (thisPlot-1, ncols);
		
		def_pos = get(0,'DefaultAxesPosition');
		totalwidth = def_pos(3);
		totalheight = def_pos(4)*0.9;
		width = (totalwidth - (ncols-1)*(PERC_OFFSET_L+PERC_OFFSET_R))/ncols;
		height = (totalheight - (nrows-1)*(PERC_OFFSET_T+PERC_OFFSET_B))/nrows;
		if thisPlot==0
			position=[def_pos(1) def_pos(2)+totalheight/0.95 totalwidth totalheight/18];
		else
			position = [def_pos(1)+col*(width+PERC_OFFSET_L+PERC_OFFSET_R) ...
				def_pos(2)+row*(height+PERC_OFFSET_T+PERC_OFFSET_B) ...
				width height];
			if width <= 0.5*totalwidth/ncols
				position(1) = def_pos(1)+col*(totalwidth/ncols);
				position(3) = 0.7*(totalwidth/ncols);
			end
			if height <= 0.5*totalheight/nrows
				position(2) = def_pos(1)+row*(totalheight/nrows);
				position(4) = 0.7*(totalheight/nrows);
			end
		end
	end
end

% kill overlapping siblings if mnp specifier was used:
nextstate = get(gcf,'nextplot');
if strcmp(nextstate,'replace'), nextstate = 'add'; end
if(kill_siblings)
	if delay_destroy, set(gcf,'NextPlot','replace'); return, end
	sibs = get(gcf, 'Children');
	for i = 1:length(sibs)
		if(strcmp(get(sibs(i),'Type'),'axes'))
			sibpos = get(sibs(i),'Position');
			intersect = 1;
			if (position(1) >= sibpos(1) + sibpos(3)) || ...
					(sibpos(1) >= position(1) + position(3)) || ...
					(position(2) >= sibpos(2) + sibpos(4)) || ...
					(sibpos(2) >= position(2) + position(4))
				intersect = 0;
			end
			if intersect
				if any(sibpos ~= position)
					delete(sibs(i));
				else
					set(gcf,'CurrentAxes',sibs(i));
					if thisPlot==0
						c=get(sibs(i),'Children');
						for l=1:length(c)
							delete(c(l))
						end
					end
					if strcmp(nextstate,'new')
						create_axis = 1;
					else
						create_axis = 0;
					end
				end
			end
		end
	end
	set(gcf,'NextPlot',nextstate);
end

% create the axis:
if create_axis
	if strcmp(nextstate,'new'), figure, end
	ax = axes('Position', position,'box','on', 'ytick',-100, 'xtick',-100);
	if thisPlot==0
		set(ax,'Units','normalized','Tag','title')
		if ~exist('titel','var')
			titel='';
		end
		text(0.5,0.5,titel,'HorizontalAlignment', 'center','FontSize',18,...
			'Units','normalized',varargin{:})
	end
else
	ax = gca;
	if thisPlot==0 && exist('titel','var')
		text(0.5,0.5,titel,'HorizontalAlignment', 'center','FontSize',18,...
			'Units','normalized',varargin{:})
	end
end

% return identifier, if requested:
if(nargout > 0)
	theAxis = ax;
end
