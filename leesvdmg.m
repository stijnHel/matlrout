function x=leesvdmg(a)
% LEESVDMG - Leest "VDM-gegevens"
%    x=leesvdmg(a)
%      a=struct : met volgende mogelijkheden (en alle combinaties hiervan)
%          'koppel' : motor-koppelgegevens
%          'verbruik' : motor-verbruik-gegevens
%          

if isfield(a,'koppel')
	fid=fopen(a.koppel,'rt');
	if fid<3
		error('Koppelgegevens konden niet gelezen worden')
	end
	n=fscanf(fid,'%d\n',1);
	N=fscanf(fid,'%f',n);
	T=cell(n,1);
	for i=1:n
		fscanf(fid,'%f %s\n',2);
		n1=fscanf(fid,'%d\n',1);
		T{i}=fscanf(fid,'%f',[n1 2]);
	end
	x.koppel=struct('N',N,'T',{T});
	fclose(fid);
end

if isfield(a,'verbruik')
	fid=fopen(a.verbruik,'rt');
	if fid<3
		error('verbruiksgegevens konden niet gelezen worden')
	end
	N0=fscanf(fid,'%f\n',1);
	Nfcutoff=fscanf(fid,'%f\n',1);
	dt=fscanf(fid,'%f\n',1);
	vrb=fscanf(fid,'%f\n',3);
	n=fscanf(fid,'%d\n',1);
	N=fscanf(fid,'%f',n);
	T=cell(n,1);
	for i=1:n
		fscanf(fid,'%f %s\n',2);
		n1=fscanf(fid,'%d\n',1);
		T{i}=fscanf(fid,'%f',[n1 2]);
	end
	x.verbruik=struct('N0',N0,'Nfcutoff',Nfcutoff,'vrb',vrb,'N',N,'T',{T});
	fclose(fid);
end
