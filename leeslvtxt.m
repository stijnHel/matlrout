function [e,ne,de,e2,gegs,str,err]=leeslvtxt(fnaam,varargin)
% LEESLVTXT - Leest LabView-text-meetfile

bMultiHead=false;
start=0;
lengte=Inf;
options=varargin;
if ~isempty(options)
	if isnumeric(options{1})
		start=options{1};
		options(1)=[];
		if ~isempty(options)
			lengte=options{1};
			options(1)=[];
		end
	end
end
if ~isempty(options)
	setoptions({'bMultiHead'},options{:})
end

str={};
err='';
ne={};
de={};
bStructGegs=true;

fid=fopen(fnaam,'rt');
if fid<3
	fid=fopen(zetev([],fnaam),'rt');
end
if fid<3
	[pth,fn,fext]=fileparts(fnaam);
	if isempty(fext)
		fid=fopen(zetev([],[fnaam '.txt']),'rt');
		if fid<3
			error('Kan file niet openen (niet zonder en niet met .txt extensie)');
		end
	else
		error('Kan file niet openen');
	end
end
head1={};
head2={};
ver=0;
dd=[0 0 0];
tt=[0 0 0];
ddd=0;
nKan=1;
nBlok=1;
xColumns=1;
nSamp=[];
dates=[];
times=[];
dex=[];
% Lees head van meting
s=deblank(fgetl(fid));
endmarker='***end_of_header***';
if strcmpi(s,'labview measurement')
	while ~strncmpi(s,endmarker,length(endmarker))
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
					str{end+1}=s1;
					str{end+1}=s2;
				case 'reader_version'
					str{end+1}=s1;
					str{end+1}=s2;
				case 'separator'
					if ~strcmpi(s2,'tab')
						warning('!!!Dit is (nog) niet gemaakt voor non-tab-separators!!!')
					end
				case 'multi_headings'
					if ~strcmpi(s2,'no')
						if ~bMultiHead
							warning('Tussenliggende header-data wordt genegeerd!')
						end
						nBlok=inf;
					end
				case 'time_pref'
					str{end+1}=s1;
					str{end+1}=s2;
				case 'date'
					if ~any(s2=='/')&&any(s2=='-')
						s2(s2=='-')='/';
					end
					dd=sscanf(s2,'%d/%d/%d')';
					if dd(1)<1900
						dd=dd([3 2 1])';
					end
					ddd=ddd+datenum(dd);
				case 'time'
					s2(s2==',')='.';
					nCol=sum(s2==':');
					if nCol==1
						ddm=sscanf(s2,'%d:%f');
						tt=[ddm(1) floor(ddm(2)) (ddm(2)-floor(ddm(2)))*60];
					elseif nCol==2
						ddm=sscanf(s2,'%d:%d:%f');
						tt=ddm';
					else
						warning('unexpected time format')
					end
					ddd=ddd+tt*[3600;60;1]/(3600*24);
				case 'x_columns'
					if strcmpi(s2,'one')
						% dit is het normale
						xColumns=1;
					elseif strcmpi(s2,'multi')
						% !enkel de eerste x-kolom wordt gebruikt!
						warning('Multiple x-columns is hier nog niet voorzien')
						xColumns=2;
					elseif strcmpi(s2,'no')
						xColumns=0;
					else
						warning('this type of x-columns is hier nog niet voorzien (%s)',s2)
					end
				case 'operator'
					str{end+1}=s1;
					str{end+1}=s2;
				otherwise
					fprintf('Onbekende header %s\n',s1)
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
end
iBlok=0;
E=cell(1,1000);
nDataTot=0;
while iBlok<nBlok
	s=fgetl(fid);
	if feof(fid)
		break;
	end
	s=deblank(s);
	while ~strncmpi(s,endmarker,length(endmarker))
		if iBlok==0
			head2{end+1}=s;
		end
		if iBlok==0||bMultiHead
			i=find(s==9);
			if ~isempty(i)
				i=[i length(s)+1];
				s1=s(1:i(1)-1);
				cLijn=strread(s,'%s',length(i)+1,'delimiter',char(9));
				% door strread te gebruiken is find(s==9) niet meer nodig!!
				switch lower(s1)
					case 'channels'
						nKan=str2num(s(i(1)+1:i(2)-1));
					case 'samples'
						nSamp=str2num(s(i(1)+1:end));
					case 'date'
						dates=sscanf(s(i(1)+1:end),'%4d/%d/%d ')';
					case 'time'
						times=sscanf(s(i(1)+1:end),'%d:%d:%g ')';
					case 'y_unit_label'
						de=cLijn(2:end);
					case 'x_dimension'
						dex=cLijn(2:end);
					case 'x0'
						x0=sscanf(s(i(1)+1:end),'%g');
					case 'delta_x'
						dx=sscanf(s(i(1)+1:end),'%g');
					otherwise
						warning('onbekende blok-header (%s)',s1)
				end
			end
			if length(head2)>100
				fclose(fid);
				global LVTXThead2
				LVTXThead2=head1;
				error('Te lange blokheader - of einde header werd niet gevonden!!!')
			end
		end
		s=deblank(fgetl(fid));
		if ~ischar(s)
			if nBlok>1
				break;
			end
			fclose(fid);
			error('!!kan begin meetstuk niet vinden!!');
		end
	end
	if iBlok==0||bMultiHead
		B1=var2struct('nSamp','dates','times','dex');
		if iBlok==0
			B=B1;
		else
			B(iBlok)=B1;
		end
	end
	if feof(fid)
		break;
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
	if iBlok==0
		iTab=[0 find(s==9) length(s)+1];
		ix=[];
		iy=[];
		nData=length(iTab)-1;
		for i=1:length(iTab)-1
			s1=deblank(s(iTab(i)+1:iTab(i+1)-1));
			if strcmpi(s1,'x_value')
				ix(end+1)=i;
				if xColumns==0
					nData=nData-1;
				end
			elseif strcmpi(s1,'comment')
				nData=nData-1;
				break;
			else
				ne{end+1}=s1;
				iy(end+1)=i;
			end
			lH=ftell(fid);
		end
	end
	e1=fscanf(fid,'%g');
	e1=reshape(e1,nData,[])';
	if length(ix)>1
		dt=e1(:,ix(2:end))-e1(:,ix(1)+zeros(length(ix)-1,1))~=0;
		if any(dt(:))
			warning('!!!Niet alle kanalen gesamples op zelfde tijdstip!!')
		end
		e1(:,ix(2:end))=[];
	end
	if start>0
		dS=min(size(e1,1),start);
		e1(1:dS,:)=[];
		start=start-dS;
	end
	iBlok=iBlok+1;
	if iBlok>length(E)
		E{end+1000}=[];
	end
	E{iBlok}=e1;
	nDataTot=nDataTot+size(e1,1);
	if nDataTot>=lengte
		if nDataTot>lengte
			dS=nDataTot-lengte;
			E{iBlok}(end-dS+1:end,:)=[];
		end
		break
	end
end
e=cat(1,E{1:iBlok});
lF=ftell(fid);
fseek(fid,0,'eof');
lEnd=ftell(fid);
if nBlok==1&&lEnd>lF
	warning('??Niet alles gelezen (%d/%d)??',lF,lEnd)
end
fclose(fid);
e2=[];
if isempty(ne)
	%ne=char(zeros(nKan,1)+'-');
	ne={'-'};
	ne=ne(ones(1,nKan),1);
end
if isempty(de)
	de=ne;
end
if ~isempty(ix)
	if xColumns>0
		ne=[{'t'},ne];
		%de={'s',de{iy-1}};
		de=[{'s'},de];
	end
	if size(e,1)>1&&all(e(1,ix(1))==e(:,ix(1)))
		warning('!!!!constant first channel...')
		%warning('!!!!alle tijd-punten zijn nul!!! - wordt vervangen door 0,1,...')
		%e(:,ix(1))=(0:size(e,1)-1)';
		%ne{1}='#';
		%de{1}='-';
	end
end
if isempty(dx)
	dx=mean(diff(e(:,1)));
end
if bStructGegs
	gegs=struct('version',ver,'time',[dd tt],'datenum',ddd,'dt',dx	...
		,'nChannels',nKan,'blockData',B	...
		);
else
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
		0 nKan dx 0 16 1 0 size(e,1) lF ones(1,nKan) zeros(1,nKan)];
end

%gegs=struct('filehead',{head1},'blokhead',{head2});  % niet standaard!!
