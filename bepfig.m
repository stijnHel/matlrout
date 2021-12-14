function bepfig(ax,h)
% BEPFIG beperkt de horizontale schalen van een figuur.  Alle assen worden
%    opgezocht, en aangepast.
%
%    bepfig(x0,x1)
%    bepfig(X [,f])
%        met - x0 = minimale x-coordinaat
%            - x1 = maximale x-coordinaat
%            - X  = [x0 x1]
%            - f  = figuur (of handle van figuur-onderdeel)
%
%    Indien f niet gegeven is, beperk de schalen van de huidige figuur.
%
%    Zie ook : bepfigs
if nargin==0
	help bepfig
	return
end
if nargin<2
	h=gcf;
end
if length(ax)==1
	if length(h)~=1
		error('Error bij gebruik van bepfig.');
	end
	ax=[ax h];
	h=gcf;
elseif numel(ax)>2
	error('Verkeerd gebruik van bepfig (teveel elementen als grens)')
end
if ax(1)>=ax(2)
	error('Verkeerd gebruik van bepfig (ondergrens moet onder bovengrens liggen).')
end
h0=[];
i=1;
while i<length(h)
	if strcmp(get(h(i),'Type'),'figure')
		h1=findobj(h(i),'Type','axes');
		h0=[h0;h1(:)]; %#ok<AGROW>
		h(i)=[];
	else
		i=i+1;
	end
end
h=[h(:);h0];
h=findobj(h,'Type','axes','Visible','on');
notToInclude={'legend','Colorbar'};
for tp=notToInclude
	ll=findobj(h,'Tag',tp{1});
	if ~isempty(ll)
		h=setdiff(h,ll);
	end
end
set(h,'XLim',ax)
B=false(1,length(h));
for i=1:length(h)
	B(i)=isequal(getappdata(h(i),'updateAxes'),@axtick2date);
end
if any(B)
	axtick2date(h(B))
end
