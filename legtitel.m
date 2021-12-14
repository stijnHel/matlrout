function out=legtitel(maxn,varargin)
% LEGTITEL - Maakt legende op basis van gegevens van titel
%   legtitel[(maxn)]
%   legtitel(maxn,...)
%       maxn (als gegeven) geeft maximum aantal karakters per naam
%            als = 0 : worden variabelen als output gegeven
%            als char : naam tot eerste voorkomen van maxn wordt genomen
%                    '&<xxx>' : neemt alles achter <xxx>
%       additional arguments are "forwarded" to legend
%             e.g. for {'location','northwest'}
%   legtitel({[maxn,]...})
%       options: totstring, nastring, bAll, ax

doout=0;
totstring='';
nastring='';
ax=[];
lines=[];
bSingles=true;
if nargin==0||isempty(maxn)
	maxn=256;
elseif iscell(maxn)
	in=maxn;
	maxn=256;
	bAll=false;
	if isnumeric(in{1})
		maxn=in{1};
		in(1)=[];
		if maxn==0
			maxn=256;
			doout=1;
		end
	end
	if ~isempty(in)	% normal case(!)
		setoptions({'maxn','totstring','nastring','bAll','ax','lines','bSingles'}	...
			,in)
	end
	if bAll
		ax=GetNormalAxes(gcf); %#ok<UNRCH>
	end
	if length(ax)>1
		for i=1:length(ax)
			legtitel({maxn,'totstring',totstring,'nastring',nastring	...
				,'ax',ax(i),'bSingles',bSingles})
		end
		return
	end
elseif ischar(maxn)
	if maxn(1)=='&'
		nastring=maxn(2:end);
	else
		totstring=maxn;
	end
	maxn=256;
elseif maxn==0
	maxn=256;
	doout=1;
end
if isempty(ax)
	ax=gca;
end
s=get(get(ax,'title'),'string');
icomma=[0 find(s==',') length(s)+1];
nvars=length(icomma)-1;
if isempty(lines)
	lines=findobj(ax,'type','line','visible','on');
	lines=lines(end:-1:1);
end
if nvars~=length(lines)
	warning('LEGTITEL:DiffNumVars','!!!aantal variabelen in titel (%d) en lijnen in grafiek (%d) zijn verschillend!!!',nvars,length(findobj(ax,'type','line')))
end
namen=cell(1,nvars);
for i=1:nvars
	namen{i}=strtrim(s(icomma(i)+1:min(icomma(i)+maxn,icomma(i+1)-1)));
	if ~isempty(totstring)
		j=strfind(namen{i},totstring);
		if ~isempty(j)
			namen{i}=namen{i}(1:j(1)-1);
		end
	elseif ~isempty(nastring)
		if strncmpi(namen{i},nastring,length(nastring))
			namen{i}=namen{i}(length(nastring)+1:end);
		end
	end
end
if doout
	out=namen;
	return
end
pars={};
if nargin>1
	if ischar(varargin{1})
		pars=varargin;
	else
		pars=varargin(2:end);
	end
end
if bSingles||length(namen)>1
	hL=legend(lines,namen{:},pars{:});
	set(hL,'Interpreter','none');
end
