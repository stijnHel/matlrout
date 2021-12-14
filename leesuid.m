function lijnen=leesuid(fn)
% LEESUID  - Leest output van plotuid
%    lijnen=leesuid([fn])

if ~exist('fn','var')|isempty(fn)
	fn='plotuid.txt';
end
fid=fopen(fn);
if fid<3
	error('Kan file niet openen')
end
lijnen=cell(1,0);
nlijnen=0;
fPos=ftell(fid);
lschaal=fgetl(fid);	% (niets mee gedaan!)
if length(lschaal)<6
	fclose(fid);
	error('Error reading file (no')
end
if strcmp(lschaal(1:4),'lijn')
	fseek(fid,fPos,'bof');
	lschaal='';
end
while ~feof(fid)
	l=fgetl(fid);
	if isempty(l)
		break;
	end
	n=fscanf(fid,'%d\n',1);
	if isempty(lschaal)
		L=fscanf(fid,'%g %g\n',[2 n])';
	else
		L=fscanf(fid,'%g %g - %g %g\n',[4 n])';
	end
	nlijnen=nlijnen+1;
	lijnen{1,nlijnen}=L;
end
fclose(fid);
