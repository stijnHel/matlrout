function out=RemoveLineAT(varargin)
%RemoveLineAT - Remove line from Axis-with-Title
%    RemoveLineAT(<line handle>) (default gco)

if nargin==0
	l=gco;
elseif isnumeric(varargin{1})
	l=varargin{1};
	if length(l)>1
		for i=1:length(l)
			RemoveLineAT(l(i),varargin{:})	% not the most efficient, ...
		end
		return
	end
elseif ischar(varargin{1})
	l=varargin{1};
else
	error('Bad use of this function')
end
if isempty(l)
	error('No line to be removed?')
end

if ischar(l)
	ax=gca;
else
	if ~ishandle(l)||~strcmp(get(l,'type'),'line')
		error('Bad input - no line handle')
	end
	ax=ancestor(l,'axes');
end
L=findobj(ax,'type','line');
L=L(end:-1:1);
N=GetNames(ax);
if length(L)~=length(N)
	warning('LEGTITEL:DiffNumVars','!!!aantal variabelen in titel (%d) en lijnen in grafiek (%d) zijn verschillend!!!',nvars,length(findobj(ax,'type','line')))
end
if ischar(l)
	i=find(strcmp(N,l));
	if isempty(i)
		error('Can''t find the channel')
	end
	l=L(i);
else
	i=find(L==l);
	if length(i)~=1
		error('Error in finding the line??')
	end
end
delete(l)
n=N(i);
N(i)=[];
t=sprintf('%s, ',N{:});
t=t(1:end-2);
set(get(ax,'Title'),'String',t)
if nargout
	out=n;
end

function namen=GetNames(ax)
s=get(get(ax,'title'),'string');
icomma=[0 find(s==',') length(s)+1];
nvars=length(icomma)-1;
if nvars<2
	return
end
namen=cell(1,nvars);
for i=1:nvars
	namen{i}=strtrim(s(icomma(i)+1:icomma(i+1)-1));
end
