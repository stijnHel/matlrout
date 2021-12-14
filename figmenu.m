function figmenu(f)
% FIGMENU  - Zet figuur-menu op figuur-venster

if ~exist('f','var')||isempty(f)
	f=gcf;
elseif ischar(f)
	in=f;
	f=gcf;
	switch lower(in)
		case {'off','none'}
			set(f,'menubar','none')
			return
		case 'on'
		otherwise
			error('Verkeerd gebruik van figmenu')
	end
end
set(f,'menubar','figure')
