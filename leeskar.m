function x=leeskar(f)
% LEESKAR  - Leest karakteristiek zoals weggeschreven (en aangepast) door plotui

fid=fopen(f,'rt');
if fid<3
	error('Kan file niet openen');
end
s=fgetl(fid);
heeftschaal=0;
if strcmp(s(1:min(end,6)),'schaal')
	% ?iets doen met schaal?
	heeftschaal=1;
	s=fgetl(fid);
end
x=struct('gas',{},'N',{},'T',{});
while ~isempty(s)&s(1)=='l'
	% ?iets doen met de nummer ?
	n=fscanf(fid,'%d\n',1);
	if heeftschaal
		a=fscanf(fid,'%g %g - %g %g\n',4*n);
		a=reshape(a,4,n)';
		a(:,1:2)=[];
	else
		a=fscanf(fid,'%g %g\n',2*n);
		a=reshape(a,2,n);
	end
	x(end+1).N=a(:,1);
	x(end).T=a(:,2);
	s=fgetl(fid);
end

if isempty(s)
	g=fscanf(fid,'%g',length(x));
else
	g=sscanf(s,'%g',length(x));
end
if length(g)<length(x)
	warning('Geen gasklepstanden gevonden!!');
else
	g=num2cell(g);
	[x.gas]=deal(g{:});
end
fclose(fid);
