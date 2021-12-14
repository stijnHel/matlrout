function x=lijnptzoeker(varargin)
% LIJNPTZOEKER - Functie om dichtste punt op lijn te zoeken.
%   lijnptzoeker('set',lijnhandle,...)
%           zonder extra inputs : toont punten in command-window
%           input3=function_handle : voert functie uit
%                     functie krijgt als inputs : (index,x,y,lijn-handle)
%           input3='data' : toont extra data (gegeven in input4)
%                als input5 gegeven, toont data in formaat bepaald door input5

if nargin==0
else
	x1=varargin{1};
	if ischar(x1)
		if strcmp(x1,'set')
			if nargin==1
				error('Bij lijnptzoeker set moet minstens aangegeven worden over welke lijnen het gaat')
			elseif nargin==2
				set(varargin{2},'ButtonDownFcn','lijnptzoeker')
			elseif isa(varargin{3},'function_handle')
				set(varargin{2},'ButtonDownFcn','lijnptzoeker(1)')
				setappdata(varargin{2},'functie',varargin{3})
			elseif ischar(varargin{3})&strcmp(varargin{3},'data')
				set(varargin{2},'ButtonDownFcn','lijnptzoeker(1)')
				setappdata(varargin{2},'data',varargin{4})
				if nargin==4
					setappdata(varargin{2},'functie',@toonextra)
				else
					setappdata(varargin{2},'formaat',varargin{5})
					setappdata(varargin{2},'functie',@toonextraform)
				end
			else
				error('Verkeerd gebruik van lijnptzoeker')
			end
			return;
		elseif strcmp(x1,'stop')
			set(varargin{2},'ButtonDownFcn','')
			return;
		else
			error('Verkeerd gebruik van lijnptzoeker')
		end
	end
end

X=get(gcbo,'XData');
Y=get(gcbo,'YData');
pt=get(get(gcbo,'Parent'),'CurrentPoint');
d2=(X-pt(1,1)).^2+(Y-pt(1,2)).^2;
[dmin,imin]=min(d2);
if nargin
	switch varargin{1}
		case 1
			feval(getappdata(gcbo,'functie'),imin,X(imin),Y(imin),gcbo)
	end
elseif nargout
	x=[imin,X(imin),Y(imin)];
else
	fprintf('pt %d : (%g,%g)\n',imin,X(imin),Y(imin))
end

function toonextra(i,x,y,l)
X=getappdata(l,'data');
fprintf('%g ',X(i,:))
fprintf('(#%d : [%g,%g])\n',i,x,y)

function toonextraform(i,x,y,l)
X=getappdata(l,'data');
fprintf(getappdata(l,'formaat'),X(i,:))
fprintf('(#%d : [%g,%g])\n',i,x,y)
