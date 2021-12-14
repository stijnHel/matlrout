function [e,ne,de,e2,gegs,str,err]=leeslvtxt2(fnaam,start,lengte,ongeschaald,kanalen)
% LEESLVTXT2 - Leest LabView-text-meetfile (met meer gebruik van header)

% enkel eerste argument gebruikt!! andere toegevoegd voor compatibiliteit
str='';
err='';

fid=fopen(zetev([],fnaam),'rt');
if fid<3
	error('Kan file niet openen');
end
head1={};
head2={};
ver=0;
dd=[0 0 0];
tt=[0 0 0];
ddd=0;
nKan=1;
% Lees head van meting
s=deblank(fgetl(fid));
endmarker='***end_of_header***';
while ~strcmp(lower(s),endmarker)
	head1{end+1}=s;
	i=find(s==9);
	if ~isempty(i)
		i=[i length(s)+1];
		s1=s(1:i(1)-1);
		if length(i)>1
			s2=deblank(s(i(1)+1:i(2)-1));
		end
		switch lower(s1)
			case 'writer_version'
				s2(s2==',')='.';
				ver=str2num(s2);
			case 'separator'
				if ~strcmp(lower(s2),'tab')
					warning('!!!Dit is (nog) niet gemaakt voor non-tab-separators!!!')
				end
			case 'multiheadings'
			case 'time_pref'
			case 'date'
				ddd=ddd+datenum(s2,'dd/mm/yyyy');
				dd=sscanf(s2,'%d/%d/%d');
				dd=dd([3 2 1])';
			case 'time'
				s2(s2==',')='.';
				ddm=datenum(s2,'HH:MM');
				ddd=ddd+ddm-floor(ddm);
				ddm=sscanf(s2,'%d:%f');
				tt=[ddm(1) floor(ddm(2)) (ddm(2)-floor(ddm(2)))*60];
			case 'x_columns'
				% iets mee doen ipv tellen van tabs
		end
	end
	if length(head1)>100
		fclose(fid);
		global LVTXThead1
		LVTXThead1=head1;
		error('Te lange fileheader - of einde header werd niet gevonden!!!')
	end
	s=deblank(fgetl(fid));
end
s=deblank(fgetl(fid));
while ~strcmp(lower(s),endmarker)
	head2{end+1}=s;
	i=find(s==9);
	if ~isempty(i)
		i=[i length(s)+1];
		s1=s(1:i(1)-1);
		switch lower(s1)
			case 'channels'
				nKan=str2num(s(i(1)+1:i(2)-1));
			case 'samples'
				nSamp=str2num(s(i(1)+1:end));
			case 'date'
				dates=sscanf(s(i(1)+1:end),'%4d/%d/%d ');
			case 'time'
				times=sscanf(s(i(1)+1:end),'%d:%d:%g ');
		end
	end
	if length(head2)>100
		fclose(fid);
		global LVTXThead2
		LVTXThead2=head;
		error('Te lange blokheader - of einde header werd niet gevonden!!!')
	end
	s=deblank(fgetl(fid));
	if ~ischar(s)
		fclose(fid);
		error('!!kan begin meetstuk niet vinden!!');
	end
end
% Lees head van blok
s=fgetl(fid);
while isempty(s)
	s=fgetl(fid);
	if ~ischar(s)
		fclose(fid);
		error('Kan begin van meetstuk niet vinden!!')
	end
end
iTab=[0 find(s==9) length(s)+1];
ix=[];
nData=length(iTab)-1;
if nData~=nKan+1
	warning('!!!!Verschillende aantallen kanalen gevonden?')
end
for i=1:length(iTab)-1
	s1=deblank(s(iTab(i)+1:iTab(i+1)-1));
	if strcmp(lower(s1),'x_value')
		ix(end+1)=i;
	elseif strcmp(lower(s1),'comment')
		nData=i-1;
		break;
	end
end
lH=ftell(fid);
e=fscanf(fid,'%g');
lF=ftell(fid);
fclose(fid);
e2=[];
if any(nSamp~=nSamp(1))
	if length(unique(nSamp))>2
		error('Te complexe data voor deze eenvoudige functie')
	end
	if min(nSamp)>1
		error('Te complexe data voor deze heel eenvoudige functie')
	end
	lBlock=sum(nSamp)+max(nSamp);	% (!!?) alle kanalen + 1 tijdblock
	if rem(length(e),lBlock)
		warning('!!Geen volledige blokken!!');
		e(end+1:end+lBlock-rem(length(e),lBlock))=0;
	end
	E=reshape(e,lBlock,[]);
	%iF=find(nSamp>1);	% fast data
	iS=find(nSamp==1);	% slow data
	e2=E([1 iS+1],:)';
	E(iS+1,:)=[];
	e=reshape(E,sum(nSamp>1)+1,[])';
else
	e=reshape(e,nData,[])';
end
if length(ix)>1
	dt=e(:,ix(2:end))-e(:,ix(1)+zeros(length(ix)-1,1))~=0;
	if any(dt(:))
		warning('!!!Niet alle kanalen gesamples op zelfde tijdstip!!')
	end
	e(:,ix(2:end))=[];
end
ne=char(zeros(nKan,1)+'-');
de=ne;
if ~isempty(ix)
	ne=['t';ne];
	de=['s';de];
	if size(e,1)>1&&all(e(1,ix(1))==e(:,ix(1)))
		warning('!!!!alle tijd-punten zijn nul!!! - wordt vervangen door 0,1,...')
		e(:,ix(1))=(0:size(e,1)-1)';
		ne(1)='#';
		de(1)='-';
	end
end
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
gegs=[ver 0 lH dd tt ...
	0 nKan mean(diff(e(:,1))) 0 16 1 0 size(e,1) lF ones(1,nKan) zeros(1,nKan)];

%gegs=struct('filehead',{head1},'blokhead',{head2});  % niet standaard!!
