function [e,ne,de,E,gegs,str,err]=leeseasy(f,start,lengte,ongeschaald,kannrs)
% LEESEASY - Leest easy-files (/directories)

if ~exist('start')|isempty(start)
	start=0;
end
if ~exist('lengte')|isempty(lengte)
	lengte=inf;
end
if ~exist('ongeschaald')|isempty(ongeschaald)
	ongeschaald=0;
end
if ~exist('kannrs')
	kannrs=[];
end

kanalen=struct('naam',{},'dim',{},'nr',{},'dt',{},'phys',{},'bereik',{},'grens',{},'schaal',{},'meting',{},'lengte',{},'lengteT',{});
[dire,fnaam,ext]=fileparts(f);
if ~isempty(dire)&~strcmp(upper([dire filesep]),zetev)
	if isempty(zetev)
		fprintf('Meting-directory gezet op "%s".\n',dire);
	else
		fprintf('Meting-directory veranderd van "%s" naar "%s".\n',zetev,dire);
	end
	zetev(dire);
end
for appnr=1:2
	% Lees meetapparaat-gegevens
	fid=fopen([zetev fnaam '.pb' num2str(appnr)],'rt');
	if fid<3
		fprintf('Kan file niet openen (%s)',[zetev fnaam '.pb' num2str(appnr)]);
		e=[];
		ne='';
		de='';
		return
	end
	l1=fgetl(fid);	% 0     Zst -1.000 ms Beg:         -1 End:          0 Vers:          0 Offs_rk:          0 Len_rk:          0
	l2=fgetl(fid);	% 4  ADC-Univ. Max  16 Kan C:\WIN16APP\EASY\B
	l3=fgetl(fid);	% ''
	l4=fgetl(fid);	% Nr  Bezeichng.      Meátakt  phys.We. Tolb.  Meáber. Grenz.   Tiefp       Aufl”sg vorl.Dat Meágr”áe.. Werteb. Mod Quellkanal Konstan. ët[ms] N2 Eig Han ASAP. Offs_rk... Len_rk....
	
	while ~feof(fid)
		l1=fgetl(fid);	% ''
		while isempty(l1)
			l1=fgetl(fid);
		end
		if ~ischar(l1)
			break;
		end
		[nr,n,errstr,i]=sscanf(l1,'%d',1);
		[naam,n,errstr,i1]=sscanf(l1(i:end),'%s',1);i=i+i1-1;
		[d,n,errstr,i1]=sscanf(l1(i:end),'%g',9);i=i+i1;
		dt=d(1)/1000;
		phys=d(2);	% ???
		tolb=d(3);	% ???
		bereik=d(4);
		grens=d(5);
		schaal=grens/32767;
		% ' 1  KS_GE           8.00000  10.00000 0.000  26.3680 30.000       0       26.3680 11962.37            30.0000                                     1     $0012          0          0'
		l2=fgetl(fid);
		% '    g               8.00000  0.000000 0.000  -26.368 -30.00   0.000       -26.368  1495296            -30.000'
		[dim,n,errstr,i]=sscanf(l2,'%s',1);
		kanalen(end+1)=struct('naam',naam,'dim',dim,'nr',nr,'dt',dt,'phys',phys,'bereik',bereik,'grens',grens,'schaal',schaal,'meting',[],'lengte',[],'lengteT',[]);
	end
	fclose(fid);
end
if isempty(kannrs)
	kannrs=1:length(kanalen);
end
for j=1:length(kannrs)
	i=kannrs(j);
	fid=fopen([zetev fnaam sprintf('.n%02x',i-1)],'r');
	if fid<3
		error('Meetfile niet gevonden (probeer misschien leeseasy2)');
	end
	fseek(fid,floor(start*2/kanalen(i).dt),'bof');
	kanalen(i).meting=fread(fid,lengte,'int16')*kanalen(i).schaal;
	fseek(fid,0,'eof');
	kanalen(i).lengte=ftell(fid)/2;
	kanalen(i).lengteT=kanalen(i).lengte*kanalen(i).dt;
	fclose(fid);
end
e=kanalen(kannrs);
if nargout>1
	ne=cell(length(kannrs),1);
	de=ne;
	[ne{kannrs}]=deal(e(kannrs).naam);
	[de{kannrs}]=deal(e(kannrs).dim);
	dts=cat(1,e.dt);
	ne=strvcat(ne);
	de=strvcat(de);
end
