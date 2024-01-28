function MakeColorUnique(f)
%MakeColorUnique - Make colors of lines unique (per axes)
%    MakeColorUnique(f)
% Colors are changed to "invisibly different colors".

ax = GetNormalAxes(f);
for i=1:length(ax)
	l = findobj(ax(i),'Type','line');
	l = l(end:-1:1);	% to make "chronological order"
	C = get(l,'Color');
	C = cat(1,C{:});
	% (not counted on expected periodical color order!?!)
	for j=2:length(l)
		B = all(C(j,:)==C(1:j-1,:));
		if any(B)
			Cj = C(j,:);
			dC = sign(0.5-Cj)*1e-3;
			while any(B)
				Cj = Cj+dC;
				B = all(Cj==C(1:j-1,:));
			end
			C(j,:) = Cj;
			l(j).Color = Cj;
		end
	end
end
