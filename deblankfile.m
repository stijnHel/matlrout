function deblankfile(fsource,fdest,verleeg)
% DEBLANKFILE - Verwijdert spaties op het einde van elke lijn van een tekstfile.
%
%    deblankfile(fsource,fdest[,verleeg])
%           als verleeg : optie om lege lijnen te verwijderen

if strcmp(fsource,fdest)
	error('Gelijke "source" en "dest" is (nog) niet toegestaan.')
end
if ~exist('verleeg','var')|isempty(verleeg)
	verleeg=0;
end

fid=fopen(fsource,'rt');
if fid<3
	error('Kan source-file niet openen')
end
fid2=fopen(fdest,'wt');
if fid2<3
	error('Kan destination-file niet openen')
end
while ~feof(fid)
	s=fgetl(fid);
	s=deblank(s);
	if ~verleeg|~isempty(s)
		fprintf(fid2,'%s\n',s);
	end
end
fclose(fid);
fclose(fid2);
