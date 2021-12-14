function figrot(figs)
% FIGROT  - Laat toe te 'roteren' tussen verschillende figuren op basis van 'keypress'

for i=1:length(figs)-1
	set(figs(i),'KeyPressFcn',sprintf('figure(%d)',figs(i+1)));
end
set(figs(end),'KeyPressFcn',sprintf('figure(%d)',figs(1)));
