function ConvertStair2Line(h)
%ConvertStair2Line - Convert stair plots to lines
%    ConvertStair2Line(h)
%         h can be figure(s), axes(s) or stairs

if nargin<1||isempty(h)
	h=gcf;
end

copyProps={'ButtonDownFcn','Color','HitTest','HandleVisibility','Tag'	...
	,'LineStyle','LineWidth','Marker','MarkerEdgeColor','MarkerFaceColor'	...
	,'MarkerSize','PickableParts','UserData','Visible'	...
	};

l=findobj(h,'type','stair');
for i=1:length(l)
	ax=get(l(i),'Parent');
	li=line(get(l(i),'XData'),get(l(i),'YData'),'Parent',ax);
	for j=1:length(copyProps)
		set(li,copyProps{j},get(l(i),copyProps{j}))
	end
	delete(l(i))
end
