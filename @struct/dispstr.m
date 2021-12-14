function dispstr(c,s)
% DISPSTR - toont de inhoud van een struct op een recursieve manier

disp(c)
if isstruct(c)
	n=fieldnames(c);
	for i=1:length(n)
		if isstruct(getfield(c,n{i}))
			if exist('s')&~isempty(s)
				t=sprintf('%s.%s',s,n{i});
			else
				t=n{i};
			end
			fprintf('%s :\n',t)
			dispstr(getfield(c,n{i}),t)
		end
	end
end
