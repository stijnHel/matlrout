function addlog(fn,txt,def)
% ADDLOG   - Schrijft tekst bij in een file (bedoeld als een soort logboek)
%     addlog(fnaam,tekst,[def])
%     addlog(fid,tekst,[def])
%  Als def gegegen en niet leeg of 0, wordt een "default" lijn begin gegeven

nfid=0;
if exist('def')&~isempty(def)&def
	% Dit wordt hier gedaan om de file zo kort mogelijk open te houden.
	[i,hn]=dos('hostname');
	while (abs(hn(end))==13)|(abs(hn(end))==10)
		hn(end)='';
	end
	deftekst=sprintf('%s (%s, %s) ',datestr(now),hn,version);
	def=1;
else
	def=0;
end
if ~exist('txt')
	txt='';
end
if isstr(fn)
	fid=fopen(fn,'at');
	if fid<3
		fprintf('!!!Kon niet wegschrijven!!!\n');
		return
	end
	nfid=1;
else
	fid=fn;
end

if def
	fprintf(fid,'%s %s\n',deftekst,txt);
else
	fprintf(fid,'%s\n',txt);
end
if nfid
	fclose(fid);
end

