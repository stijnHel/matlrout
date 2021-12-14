function [event,namen,dim,eT,gegs,str,err] = leesdago(smet,start,lengte)
% LEESDAGO - Leest gegevens van dia-dago
% funktie om gegevens weggeschreven door DAGO in te lezen.
% inlezen gebeurt door :
%    [e,ne,dim]=leesdago({nr},start,lengte);     (nr van gegevens invullen natuurlijk)
%  e is een matrix met per rij 1 meting
%  ne geeft de namen van de rijen
%  dim geeft de dimensies van de rijen
%  start geeft het begin van het gewenste deel van de meting aan
%  lengte geeft de lengte van het gewenste deel aan
%
%  Indien start niet gegeven is, wordt er van het begin van de meting gelezen
%  Indien lengte niet gegeven is, of indien lengte+start groter is dan de aktuele
%    lengte, wordt er gelezen tot het einde van de totale meting.

% !!!!!!!!!!!!
%  oorspronkelijk gemaakt voor een oude versie (op een "oude manier")
%    nadien aangepast voor metingen van KISS - op een snelle manier!!!!!
global LASTCOMMENT LASTEVENT
% Inlezen van de datafile.
LASTEVENT = smet;
str='';
err=0;
[pth,nme,ext]=fileparts(smet);
if isempty(ext)
	smet=[smet filesep '.dat'];
end
fevent=fopen([zetev smet],'r');
s=[fscanf(fevent,'%c') ' '];
lijnen=[findstr(setstr([13 10]),s)+2 length(s)+3 100000];
nl=length(lijnen)-2;
lijn=1;

% zoek begin van global header
while ~strcmp(s(lijnen(lijn):lijnen(lijn+1)-3),'#BEGINGLOBALHEADER')
	lijn=lijn+1;
end
lijn=lijn+1;
% lees global header
while ~strcmp(s(lijnen(lijn):lijnen(lijn+1)-3),'#ENDGLOBALHEADER')
	i=lijnen(lijn);
	while s(i)~=','
		i=i+1;
	end
	infonr=str2num(s(lijnen(lijn):i-1));
	t=s(i+1:lijnen(lijn+1)-3);
	switch infonr
	case 1
		%%OD??
	case 101
		LASTCOMMENT=t;
		disp(LASTCOMMENT)
	case 102
		str=strvcat(str,t);
	case 103
		xxxx=t;	% ownder?
	otherwise
		fprintf('onverwachte data in global header (%d)\n',infonr)
	end
	lijn=lijn+1;
end;
kanalen=struct('naam',{},'dim',{},'explicit',{}	...
	,'startingv',{},'stepwidth',{},'issigned',{}	...
	,'startpointer',{},'minim',{},'maxim',{}	...
	,'type',{},'nmetingen',{},'fnaam',{});
kanaal0=kanalen;
kanaal0(1).naam='';
% lees channel headers
while lijn<nl
	% zoek begin van header
	while (lijn<nl) & ~strcmp(s(lijnen(lijn):lijnen(lijn+1)-3),'#BEGINCHANNELHEADER')
		lijn=lijn+1;
	end
	if lijn<nl
		lijn=lijn+1;
		nmetingen=-1;
		% lees header
		kanaal=kanaal0;
		while ~strcmp(s(lijnen(lijn):lijnen(lijn+1)-3),'#ENDCHANNELHEADER')
			i=lijnen(lijn);
			while s(i)~=','
				i=i+1;
			end
			infonr=str2num(s(lijnen(lijn):i-1));
			t=s(i+1:lijnen(lijn+1)-3);
			switch infonr
			case 200
				kanaal.naam=t;
			case 201
				% ?oorsprong? timing?
			case 202
				if isempty(t)
					t='-';
				end
				kanaal.dim=t;
			case 210
				if t(1)=='I'
					% impliciete rij
					kanaal.explicit=0;
				else
					% expliciete rij
					kanaal.explicit=1;
				end
			case 211
				kanaal.fnaam=t;
			case 213
				%??channel??
			case 214
				kanaal.type=t;
				switch t
				case 'WORD16'
					kanaal.issigned=0;
				case 'INT16'
					kanaal.issigned=1;
				otherwise
					disp('''WORD16''-formaten werden verwacht ! Deze wordt overgeslagen')
					kanaal.issigned=0;
				end
			case 220
				kanaal.nmetingen=str2num(t);
			case 221
				kanaal.startpointer=str2num(t);
				% startpointer van meting wordt gegeven
				% dit is (voorlopig) niet gebruikt
			case 240
				kanaal.startingv=str2num(t);
				% (starting value / offset)
			case 241
				kanaal.stepwidth=str2num(t);
			case 250
				kanaal.minim=str2num(t);
			case 251
				kanal.maxim=str2num(t);
			case 252
				% ??? NoValues ???
			case 253
				% monotony
				fprintf('%03d : %s\n',infonr,t);
			case 260
				%???Numeric
				if ~strcmp(t,'Numeric')
					fprintf('%03d : !andere waarde dan verwacht! : %s\n',infonr,t);
				end
			case 273
				if ~strcmp(t,'100')
					fprintf('%03d : !andere waarde dan verwacht! : %s\n',infonr,t);
				end
			case 274
				if ~strcmp(t,'0')
					fprintf('%03d : !andere waarde dan verwacht! : %s\n',infonr,t);
				end
			case 301
				%fprintf('%03d : %s\n',infonr,t);
			otherwise
				fprintf('Onverwachte data in channel header (%d)\n',infonr)
			end
			lijn=lijn+1;
		end % einde van lezen van een header
		kanalen(end+1)=kanaal;
	end % lijn<length(lijnen)
end % einde van lezen van headers
fclose(fevent);
isexpl=cat(2,kanalen.explicit);
% verwijder aparte tijd-kanalen per kanaal
if ~any(isexpl(3:2:end))
	kanalen(3:2:end)=[];
end
nmetingen=cat(2,kanalen.nmetingen);
if any(nmetingen-nmetingen(1))
	error('Alle metingen moeten voor deze routine evenveel punten bevatten.')
end
nmetingen=nmetingen(1);
nkanalen=length(kanalen);
% lezen van metingen
if ~exist('start')
	start=0;
else
	if start>nmetingen;event=[];return;end
	if start<0;start=0;end
end
if ~exist('lengte')
	lengte=nmetingen-start;
else
	if lengte+start>nmetingen;lengte=nmetingen-start;end
end
event=zeros(lengte,nkanalen);
%fevent=fopen([zetev smet,'.w16'],'r','ieee-le');
for i=1:nkanalen
	if kanalen(i).explicit
		if lengte
			fevent=fopen([zetev kanalen(i).fnaam],'r');
			fseek(fevent,start*2,'bof');
			if kanalen(i).issigned
				tp='int16';
			else
				tp='uint16';
			end
			event(:,i)=kanalen(i).stepwidth*fread(fevent,lengte,tp)	...
				+kanalen(i).startingv;
			fseek(fevent,(nmetingen-lengte)*2,'cof');
			fclose(fevent);
		end
	else
		event(:,i)=(start:start+lengte-1)'*kanalen(i).stepwidth+kanalen(i).startingv;
	end
end
%fclose(fevent);
namen=strvcat(kanalen.naam);
dim=strvcat(kanalen.dim);
if ~kanalen(1).explicit
	namen=strvcat('t',namen(2:end,:));
	dim=strvcat('s',dim(2:end,:));
end

if nargout>3
	%	datum=[dag maand jaar uur minu sec];
	eT=[];
	datum=[1 1 1904 0 0 0];
	if length(datum)~=6
		datum=zeros(1,6);
	end
	Nkan=size(namen,1)-1;%-isempty(ts);
	%	isSigned=((numberFormat>6)|~rem(numberFormat,2))&(numberFormat<=8);
	isSigned=max(cat(1,kanalen.issigned));%(!!)
	Nmet=size(event,1);
	%           1 : versie
	%           2 : LPH-nummer
	%           3 : lenge van de header
	%           4 : dag
	%           5 : maand
	%           6 : jaar
	%           7 : uur
	%           8 : minuut
	%           9 : seconde
	%          10 : referentiepunt
	%          11 : aantal kanalen
	%          12 : dt
	%          13 : aantal kanalen per blok
	%          14 : resolutie (# bits)
	%          15 : (un)signed
	%          16 : lengte van de tekst
	%          17 : aantal meetpunten
	%          18 : lengte van de file
	%       1    2 3 4-6,7-9 0  1   2  3    4        5     6  7      8
	%	gegs=[versie 0 0 datum   0 Nkan mean(diff(A(:,1))) 0 signBits isSigned 0 Nmet filep+lengte+1 DataGegs(volgorde,iGain)' DataGegs(volgorde,iScOffset)'];
	gegs=[0 0 0 datum   0 Nkan mean(diff(event(:,1))) 0 12 isSigned 0 size(event,1) 0 ones(1,nkanalen) zeros(1,nkanalen)];
	err=0;
end
