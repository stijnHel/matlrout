function data_uit=leesdaf(f)
% LEESDAF  - Leest een daf-file
%   is ook uitgebreid om een tune uit een mx-file te halen.
if strcmp(lower(f(length(f)-2:length(f))),'.mx')
	extrUitMX=1;
	startadr=sscanf('13c000','%x');
	eindadr=sscanf('140000','%x');
else
	extrUitMX=0;
end
fid=fopen(f,'rt');
if fid<=0
	error('File niet gevonden')
end
fseek(fid,0,'eof');
flen=ftell(fid);
fseek(fid,0,'bof');
lnr=0;
geg0=[];
geg5=[];
geg7=[];
adr=[];
data=zeros(65536,1);
status('Lezen van daf-file',0)
while ~feof(fid)
	l=fscanf(fid,'%s',1);
	lnr=lnr+1;
	if isempty(l)
		break;
	end
	if l(1)=='S'
		a=sscanf(l(3:length(l)),'%2x');
		if rem(sum(a),256)~=255
			fprintf('CRC-error in lijn %d\n',lnr);
		end
		if a(1)+1~=length(a)
			fprintf('Fout met aantal getallen\n');
		end
		a=a(2:length(a)-1);
		if l(2)=='0'
			if ~isempty(geg0)
				fprintf('Er is twee maal geg0 gegeven\n');
			end
			geg0=a;
		elseif l(2)=='3'
			adres1=[16777216 65536 256 1]*a(1:4);
			a(1:4)=[];
			ok=1;
			if extrUitMX
				if (adres1<startadr)|(adres1>=eindadr)
					ok=0;
				end
			end
			if ok
				if isempty(adr)
					adr=adres1;
					startadr=adr;
					if adr~=sscanf('13c000','%x')
						fprintf('!!Ander start-adres dan verwacht\n')
					end
				elseif adr~=adres1
					fclose(fid);
					status
					error('Geen aaneensluitend adresbereik');
				end
				nb=length(a);
				data(adr-startadr+1:adr-startadr+nb)=a(:);
				adr=adr+nb;
			end
		elseif l(2)=='5'
			if ~isempty(geg5)
				fprintf('Er is twee maal geg5 gegeven\n');
			end
			geg5=a;
		elseif l(2)=='7'
			if ~isempty(geg7)
				fprintf('Er is twee maal geg7 gegeven\n');
			end
			geg7=a;
		else
			fprintf('Onbekende kode (%s)\n',l);
		end
	elseif ~isempty(l)
		fclose(fid)
		status
		error(sprintf('onverwacht gegeven "%s"',l))
	end
	status(ftell(fid)/flen);
end
fclose(fid);
if adr-startadr<length(data)
	data(adr-startadr+1:length(data))=[];
end
data_uit=data;
status