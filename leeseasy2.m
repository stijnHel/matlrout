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
if size(kannrs,1)==1
	kannrs=[kannrs;ones(1,length(kannrs))];
end

if ongeschaald>0
	kanalen=struct('naam',{},'dim',{},'nr',{},'dt',{},'phys',{},'bereik',{},'grens',{},'meting',{},'offset',{},'lengte',{},'lengteT',{},'ongeschaald',{},'schaal',{});
else
	kanalen=struct('naam',{},'dim',{},'nr',{},'dt',{},'phys',{},'bereik',{},'grens',{},'meting',{},'offset',{},'lengte',{},'lengteT',{});
end
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
	l1=fgetl(fid);	% 0     Zst -1.000 ms Beg:         -1 End:          0 Vers:          0 Offs_rk:          0 Len_rk:          0
	l2=fgetl(fid);	% 4  ADC-Univ. Max  16 Kan C:\WIN16APP\EASY\B
	l3=fgetl(fid);	% ''
	l4=fgetl(fid);	% Nr  Bezeichng.      Meátakt  phys.We. Tolb.  Meáber. Grenz.   Tiefp       Aufl”sg vorl.Dat Meágr”áe.. Werteb. Mod Quellkanal Konstan. ët[ms] N2 Eig Han ASAP. Offs_rk... Len_rk....
%andere metingen
%                     0     Zst 1.0000 ms Beg:         56 End:     985912 Vers:          0 Offs_rk:          0 Len_rk:      19724
%                     4  ADC-Univ. Max  16 Kan B.LED
%
%                     Nr  Bezeichng.      Meátakt  phys.We. Tolb.  Meáber. Grenz.   Tiefp       Aufl”sg vorl.Dat Meágr”áe.. Werteb. Mod Quellkanal Konstan. ët[ms] N2 Eig Han ASAP. Offs_rk... Len_rk....
%not andere
%                                                   0
%  4  ADC-Univ. Max  16 Kan
%
%Nr  Bezeichng.           Meátakt    phys.We.  Tolb.   Meáber.    Aufl”sg    vorl.Dat   Werteb.
	
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
		[d,n,errstr,i1]=sscanf(l1(i:end),'%g',10);i=i+i1;
		if isempty(d)
			if isempty(naam)
				error('!!!!fout bij inlezen pb-file!!!')
			end
			[nr,n,errstr,i]=sscanf(l1,'%d',1);
			i1=i;
			while l1(i1)>'9'|l1(i1)<'0'
				i1=i1+1;
			end
			naam=deblank(l1(i:i1-1));
			i=i1;
			[d,n,errstr,i1]=sscanf(l1(i:end),'%g',10);i=i+i1;
		end
		[d2,n,errstr,i1]=sscanf(l1(i:end),' $%x',1);i=i+i1;
		[d3,n,errstr]=sscanf(l1(i:end),'%g');
		if isempty(d3)
			d3=[0 0];
		end
		% ' 1  KS_GE           8.00000  10.00000 0.000  26.3680 30.000       0       26.3680 11962.37            30.0000                                     1     $0012          0          0'
		l2=fgetl(fid);
		% '    g               8.00000  0.000000 0.000  -26.368 -30.00   0.000       -26.368  1495296            -30.000'
% andere metingen
%           1  KS_GE           8.00000  10.00000 0.000  26.3680 30.000       0       26.3680 986.2000            30.0000                                     1     $0012      19724       9862
%              g               200.000  0.000000 0.000  -26.368 -30.00   0.000       -26.368 4931.000            -30.000
% nog andere :
%1   KS_GE                8.000      10.000    0.000   26.368     26.368     9986.048   30.000
%    g                    8.000      00.000    0.000   -26.368    -26.368    1248256    -30.000

		[dim,n,errstr,i]=sscanf(l2,'%s',1);
		[d4,n,errstr]=sscanf(l2(i:end),'%g');

		dt=d4(1)/1000; % (???d(1) : meet-dt, d4(1) : weggeschreven dt???)
		phys  =[d4(2) d(2)];	% ???
		tolb  =[d4(3) d(3)];	% ???
		bereik=[d4(4) d(4)];
		grens =[d4(5) d(5)];
		%vermits ik merkte dat het eigenlijk niet grens is, maar "Werteb.", verving ik het vorige door :
		if length(d)==10
			grens=[d4(9) d(9)];
		elseif length(d)==7
			grens=[d4(7) d(7)];
		else
			fprintf('!!!!!andere pb-info dan verwacht!!!!!\n');
		end
		if ongeschaald>0
			kanalen(end+1)=struct('naam',naam,'dim',dim,'nr',nr,'dt',dt,'phys',phys	...
				,'bereik',bereik,'grens',grens,'meting',[]	...
				,'offset',d3(1),'lengte',d3(2),'lengteT'	...
				,[],'ongeschaald',1,'schaal',diff(grens)/65536*[1 32768]+[0 grens(1)]);
		else
			kanalen(end+1)=struct('naam',naam,'dim',dim,'nr',nr,'dt',dt,'phys',phys,'bereik',bereik,'grens',grens,'meting',[],'offset',d3(1),'lengte',d3(2),'lengteT',[]);
		end
	end
	fclose(fid);
end
if isempty(kannrs)
	kannrs=[1:length(kanalen);ones(1,length(kanalen))];
end
status('Inlezen file',0);
if kanalen(1).offset
	fid=fopen([zetev fnaam '.nrk'],'r');
	if fid<3
		error('meetfile niet gevonden');
	end
	t=fread(fid,kanalen(i).lengte/2,'int32')*0.001;	% ??dt en t gegeven!! wat hiermee doen?
	E=t;
	for j=1:size(kannrs,2)
		i=kannrs(1,j);
		i0=min(kanalen(i).lengte/2-1,floor(start/kanalen(i).dt));
		i1=min(kanalen(i).lengte/2,ceil((start+lengte)/kanalen(i).dt));
		fseek(fid,kanalen(i).offset+i0*2,'bof');
		if ongeschaald>0
			kanalen(i).meting=fread(fid,i1-i0,'*int16');
			kanalen(i).ongeschaald=1;
			kanalen(i).schaal=diff(kanalen(i).grens)/65536*[1 32768]+[0 kanalen(i).grens(1)];
		elseif ongeschaald==0
			kanalen(i).meting=(fread(fid,i1-i0,'int16')+32768)/65536*diff(kanalen(i).grens)+kanalen(i).grens(1);
		end
		if kannrs(2,j)<1
			n=round(1/kannrs(2,j));
			kanalen(i).meting=reshape(kanalen(i).meting(:,ones(1,n)),length(kanalen(i).meting)*n,1);
			kanalen(i).dt=kanalen(i).dt/n;
		elseif kannrs(2,j)>1
			n=round(kannrs(2,j));
			kanalen(i).meting=kanalen(i).meting(ceil(n/2):n:end);
			kanalen(i).dt=kanalen(i).dt*n;
		end
		kanalen(i).lengteT=kanalen(i).lengte*kanalen(i).dt;
		status(j/size(kannrs,2));
	end
	fclose(fid);
else
	for j=1:size(kannrs,2)
		i=kannrs(1,j);
		fid=fopen([zetev fnaam sprintf('.n%02x',i-1)],'r');
		i0=floor(start/kanalen(i).dt);
		i1=ceil((start+lengte)/kanalen(i).dt);
		fseek(fid,i0*2,'bof');
		if ongeschaald>0
			kanalen(i).meting=fread(fid,i1-i0,'*int16');
			kanalen(i).ongeschaald=1;
			kanalen(i).schaal=diff(kanalen(i).grens)/65536*[1 32768]+[0 kanalen(i).grens(1)];
		elseif ongeschaald==0
			kanalen(i).meting=(fread(fid,i1-i0,'int16')+32768)/65536*diff(kanalen(i).grens)+kanalen(i).grens(1);
		end
		fseek(fid,0,'eof');
		kanalen(i).lengte=ftell(fid)/2;
		kanalen(i).lengteT=kanalen(i).lengte*kanalen(i).dt;
		fclose(fid);
		if kannrs(2,j)<1
			n=round(1/kannrs(2,j));
			kanalen(i).meting=reshape(kanalen(i).meting(:,ones(1,n)),length(kanalen(i).meting)*n,1);
			kanalen(i).dt=kanalen(i).dt/n;
		elseif kannrs(2,j)>1
			n=round(kannrs(2,j));
			kanalen(i).meting=kanalen(i).meting(ceil(n/2):n:end);
			kanalen(i).dt=kanalen(i).dt*n;
		end
		status(j/size(kannrs,2));
	end
end
status
e=kanalen(kannrs(1,:));
nkan=length(e);
if nargout>1
	if ongeschaald
		bereiken=cat(1,e.grens);
		schaaloffset=[diff(bereiken')'/65536 bereiken(:,1)];
		schaaloffset=[schaaloffset(:,1) 32768*schaaloffset(:,1)+schaaloffset(:,2)];
	else
		schaaloffset=[ones(nkan,1) zeros(nkan,1)];
	end
	ne=cell(nkan,1);
	de=ne;
	[ne{kannrs(1,:)}]=deal(e(kannrs(1,:)).naam);
	[de{kannrs(1,:)}]=deal(e(kannrs(1,:)).dim);
	ne=strvcat(ne);
	de=strvcat(de);
	dts=cat(1,e.dt);
	if nargout>3
		Dt=unique(dts);
		if length(Dt)==1
			ii=1:length(e);
			try
				e=[(0:length(e(1).meting)-1)'*Dt cat(2,e.meting)];
			catch
				l=cat(1,e.lengte)/2;
				x=[(0:max(l)-1)'*Dt zeros(max(l),length(e))];
				for i=1:length(e)
					x(1:l(i),i+1)=e(i).meting;
				end
				e=x;
			end
			E=[];
		elseif length(Dt)==2
			i1=find(dts==Dt(1));
			i2=find(dts==Dt(2));
			E=[(0:length(e(i2(1)).meting)-1)'*Dt(2) cat(2,e(i2).meting)];
			e=[(0:length(e(i1(1)).meting)-1)'*Dt(1) cat(2,e(i1).meting)];
			ii=[i1;i2];
		else
			idt1=2;
			if length(Dt)>3
				idt2=length(Dt)-1;
			else
				idt2=length(Dt);
			end
			dt1=Dt(idt1);
			dt2=Dt(idt2);
			fprintf('!!%d sampletijden werden terug gebracht naar 2 (%g',length(Dt),Dt(1));
			fprintf(',%g',Dt(2:end));
			fprintf(') naar (%g,%g)\n',dt1,dt2);
			fprintf('     (!om rekentijd en geheugen te sparen werd niet gefilterd maar eenvoudig "gedownsampled"!)\n');
			n1=round(Dt(2)/Dt(1));
			nDt=histc(dts,Dt);
			i1=find(dts==Dt(1));
			i2=find(dts==Dt(2));
			ii=[i1;i2];
			%x=[(0:e(i2(1)).lengte-1)'*dt1 zeros(e(i2(1)).lengte,nDt(1)) double(cat(2,e(i2).meting))];
			x=[zeros(length(e(i2(1)).meting),nDt(1)) cat(2,e(i2).meting)];
			for i=1:length(i1)
				x(:,i)=e(i1(i)).meting(floor(n1/2):n1:end);
			end
			i1=find(dts==dt2);
			E=[(0:length(e(i1(1)).meting)-1)'*dt2 zeros(length(e(i1(1)).meting),sum(nDt(3:end)))];
			i2=find(dts>Dt(2));
			ii=[ii;i2];
			for i=1:length(i2)
				if e(i2(i)).dt<dt2
					n1=round(dt2/e(i2(i)).dt);
					E(:,i+1)=e(i2(i)).meting(floor(n1/2):n1:end);
				elseif e(i2(i)).dt>dt2
					n1=round(e(i2(i)).dt/dt2);
					E(:,i+1)=reshape(e(i2(i)).meting(:,ones(n1,1))',size(E,1),1);
				else
					E(:,i+1)=e(i2(i)).meting;
				end
			end
			e=[(0:size(x,1)-1)'*dt1 double(x)];
		end
		ne=ne(ii,:);
		de=de(ii,:);
		schaaloffset=schaaloffset(ii,:);
		gegs=[zeros(1,3)  1 1 1980 0 0 0 zeros(1,9) schaaloffset(:)'];
		str='';
		err=0;
		ne=addstr('t',ne);
		de=addstr('s',de);
	end
end
