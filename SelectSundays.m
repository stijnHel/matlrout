function SelectSundays(f,varargin)
%SelectSundays - Select sundays in graph

if nargin==0||isempty(f)
	f = gcf;
end

bWarned = false;
l = findobj(f,'Type','line');
for i=1:length(l)
	ax = l(i).Parent;
	tForm = getappdata(ax,'TIMEFORMAT');
	if isempty(tForm)
		if ~bWarned
			warning('Currently only axes using "automatic axtic2data" are handled!')
			bWarned = true;
		end
	else
		t = l(i).XData;
		if ~strcmp(tForm,'matlab')
			t = Tim2MLtime(t,tForm);
		end
		Bsunday = rem(floor(t),7)==2;
		set(l(i),'BrushData',uint8(Bsunday));
	end
end		% for i