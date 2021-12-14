function [paf,memblok]=leespaf(fn,combineer)
% LEESPAF  - Leest paf-file (of sommige andere hex-files) in Siemens/motorola formaat
%      [paf,memblokken]=leespaf(<filename>[,combineer]);
%        paf : struct met alle aparte blokken
%        memblokken : samenvatting van geheugenblokken
%        combineer : als gegeven en verschillend van 0, worden blokken gecombineerd
%               als combineer<2 wordt de volgorde behouden
%               anders worden de blokken gesorteerd

soort=0;	% nu niet gebruikt, de bedoeling om te kiezen tussen siemens/motorola
paf=struct('geg',{},'adres',{},'data',{});
if exist(fn)~=2
	error('File niet gevonden');
end
fid=fopen(fn,'rt');
lnr=0;
while ~feof(fid)
	l=fgetl(fid);
	lnr=lnr+1;
	if rem(length(l),2)~=1
		fprintf('Verkeerde lijn-lengte (%d)\n',lnr);
	elseif ~isempty(l)&(l(1)==':')
		a=sscanf(l(2:end),'%2x');
		if rem(sum(a),256)
			fprintf('CRC-error in lijn %d\n',lnr);
		end
		if a(1)+5~=length(a)
			fprintf('Fout met aantal getallen\n');
		end
		adr=[256 1]*a(2:3);
		geg=a(4);
		a=a(5:end-1);
		if ~isempty(paf)&geg==0&paf(end).geg==0&adr==adres
			paf(end).data(end+1:end+length(a))=uint8(a)';
			adres=adres+length(a);
		else
			paf(end+1)=struct('geg',geg,'adres',adr,'data',uint8(a)');
			adres=adr+length(a);
		end
	elseif ~isempty(l)
		fclose(fid);
		error(sprintf('onverwacht gegeven "%s"',l))
	end
end
fclose(fid);

endian2=[1 256];

if nargin>1&~isempty(combineer)&combineer
	[paf,nietLinAdres]=combinBlokken(paf);
	if nietLinAdres
		if combineer<2
			warning('!!Niet constant stijgend adres in blokken!!');
		else
			[a,i]=sort(cat(1,paf.adres));
			paf=combinBlokken(paf(i));
		end
	end
	if length(paf)==1&paf.geg==0
		paf=rmfield(paf,'geg');
	end
end

if nargout>1
	if isfield(paf,'geg')
		memblok=zeros(0,3);
		for i=1:length(paf)
			switch paf(i).geg
			case 0
				memblok(end+1,:)=[i adres+paf(i).adres adres+paf(i).adres+length(paf(i).data)-1];
			case 2
				adres=endian2*double(paf(i).data(:))*4096;
			case 4
				adres=endian2*double(paf(i).data(:))*256;	% ???(of is het *65536, maar dan bigendian???)
			end
		end
		memblok=sortrows(memblok,2);	% sorteer op startadres
	else
		memblok=cat(1,paf.adres);
		for i=1:length(paf)
			memblok(i,2)=memblok(i,1)+length(paf(i).data)-1;
		end
		memblok=[(1:length(paf))' memblok];
	end
end

function [paf,nietLinAdres]=combinBlokken(paf)
endian2=[1 256];
i=1;
adres_next=Inf;
adres=0;
nietLinAdres=0;
while i<=length(paf)
	switch paf(i).geg
	case 0
		if adres+paf(i).adres==adres_next
			paf(i_data).data=[paf(i_data).data paf(i).data];
			adres_next1=adres_next+length(paf(i).data);
			paf(i)=[];
		else
			i_data=i;
			paf(i).adres=adres+paf(i).adres;
			adres_next1=paf(i).adres+length(paf(i).data);
			i=i+1;
		end
		if adres_next1<adres_next
			nietLinAdres=1;
		end
		adres_next=adres_next1;
	case 2
		adres=endian2*double(paf(i).data(:))*4096;
		paf(i)=[];
	case 4
		adres=endian2*double(paf(i).data(:))*256;	% ???(of is het *65536, maar dan bigendian???)
		paf(i)=[];
	case 1	% (?)einde
		paf(i)=[];
	otherwise
		error('probleem bij combineren van geheugenblokken door ongewone structuur')
	end
end
