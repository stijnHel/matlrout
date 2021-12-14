function MakeFigScalable(fig)
%MakeFigScalable - Make figure scalable
%    Units of elements on the figure are changed to normalized

if nargin<1||isempty(fig)
	fig = gcf;
end

C = {'uicontrol','axes'};

for i=1:length(C)
	C{i} = findobj(fig,'type',C{i});
end
set(cat(1,C{:}),'Unit','normalized')
