function [e,ne,de]=leesgifmet(fn,start,lengte)
% LEESGIFMET - Leest GIF-meting (r32-formaat)

if nargin<2|isempty(start)
	start=0;
end
if nargin<3|isempty(lengte)
	lengte=inf;
end
[pth,nm,ext]=fileparts(fn);
nr=sscanf(nm,'dat%d');

kalgegs=struct('fN_Tin',{59921,59901}	...
	,'fN_Tout',{59855,59673}	...
	,'Sn_Tout',{9.524,35.912}	...
	);

if ~isempty(nr)
	C=kalgegs(nr-1);
else
	warning('!!!onbekende kalibratie-gegevens!!!')
	C=kalgegs(1);
end
if strcmp(lower(ext),'.dat')
	e=leesdat(fn,start,lengte);
else
	fid=fopen([zetev fn],'r');
	if fid<3
		error('Kan file niet openen');
	end
	
	e=fread(fid,'single');
	fclose(fid);
	e=reshape(e,length(e)/15,15);
end

e(:,5)=434.7826./e(:,5);
e(:,6)=1./(e(:,6)+e(:,7));
e(:,7)=1./(e(:,8)+e(:,9));

e(:,8)=(128./(e(:,10)+e(:,11))-C.fN_Tin)/55.616;
e(:,9)=(128./(e(:,12)+e(:,13))-C.fN_Tout)/C.Sn_Tout;
e(:,10)=(128./(e(:,14)+e(:,15))-C.fN_Tout)/C.Sn_Tout;

e(:,11:end)=[];
ne=strvcat('Psec','Pclutch1','Pclutch2','Ttran'	...
	,'Ninput','Noutleft','Noutright'	...
	,'Tinput','Toutleft','Toutright');
de=strvcat('bar','bar','bar','°C'	...
	,'1/min','1/min','1/min'	...
	,'Nm','Nm','Nm');
