function l=baselen(L)
%clens/baselen - Gives "base length" of lens
%     for circular objects (like a spherical lens) this is the diameter

l=0;
for i=1:length(L)
	switch L(i).type
		case 'sferisch'
			l1=L(i).D.D;
		case 'prisma'
			l1=sqrt(max(sum(diff(L(i).D.grondvlak([1:end 1],:)).^2,2)));
			l1=max(l1,sqrt(sum(L(i).D.ribbe.^2)));
		case {'bol','cilinder','cilindrisch'}
			l1=L(i).D.r;
		otherwise
			l1=0;
			warning('No implementation of baselen("%s")!',L(i).type)
	end
	l=max(l,l1);
end
