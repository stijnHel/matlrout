function Verg=filever(f1,f2,f3)
% FILEVER  - Vergelijkt twee files.
%
%      Verg=filever(f1,f2)    Vergelijkt twee files
%      Verg=filever(d1,d2)    Vergelijkt files in twee directories
%      filever toondif        Geeft resultaten van laatste vergelijking (files of directories)
%      filever grafdif        Toont resultaten van laatste file-vergelijking in grafische vorm
%      filever toonfdif       Geeft resultaten van laatste file-vergelijking
%      filever toonddif       Geeft resultaten van laatste directory-vergelijking
%      filever del2 gelijk    Verwijdert de gelijke files in de tweede directory

global LASTTekst1 LASTTekst2 LASTVerg LASTF1 LASTF2 LASTVERUse
global LASTDirVer LASTDir1 LASTDir2
global FILEVERmaxlen

lijnkar='-';
if ~exist('f2','var');f2=[];end
if ~exist('f3','var');f3=[];end
if nargin==0
	tekst1=LASTTekst1;
	tekst2=LASTTekst2;
elseif ~ischar(f1)
	error('Verkeerd gebruik van filever');
elseif strcmp(f1,'toondif')
	switch LASTVERUse
		case 1	% Gewone filever
			if nargout
				Verg=filever('toonfdif');
			else
				filever toonfdif
			end
		case 2	% Verschil tussen directories
			if nargout
				Verg=filever('toonddif');
			else
				filever toonddif
			end
	end
	return
elseif strcmp(f1,'toonfdif')
	if isempty(FILEVERmaxlen)
		maxlijnlen=70;
		FILEVERmaxlen=maxlijnlen;
	else
		maxlijnlen=FILEVERmaxlen;
	end
	fors=sprintf('%%-%ds',maxlijnlen-3);
	if ~isstruct(f3)
		if isstruct(LASTVerg)
			f3=LASTVerg;
		else
			f3=struct('file1',LASTF1,'file2',LASTF2	...
				,'verw1',[],'verw2',[],'kort',[]	...
				,'tekst1','','tekst2','');
		end
	end
	lijnver1=f3.verw1;
	lijnver2=f3.verw2;
	kort=f3.kort;
	fn1=f3.file1;
	fn2=f3.file2;
	tekst1=f3.tekst1;
	tekst2=f3.tekst2;
	if size(fn1,1)==1&size(fn2,1)==1
		s=sprintf(['     ' fors ' <--->  %s\n'],fn1,fn2);
	else
		s='';
	end
	if isempty(f3.verw1)
		s=[s sprintf('Geen verschil.\n')];
		if nargout
			Verg=geefresultaat(s,f2);
		else
			geefresultaat(s,f2);
		end
		return
	end
	formlijn=sprintf('%%-%ds',maxlijnlen);
	spc=' ';
	l=0;
	k=0;
	if kort(end,3)
		kort(end+1,:)=[kort(end,2)+1 kort(end,2) 0 0];
	end
	for i=1:size(kort,1)
		%fprintf('i=%d\n',i);
		if kort(i,3)	% gelijke lijnen
			s=[s sprintf('                           %3d-%3d   === %3d-%3d\n',kort(i,1:4))];
			k=kort(i,4);
		else
			j=kort(i,1);
			%fprintf('  start j=%d\n',j);
			k=k+1;
			if i<size(kort,1)
				lastk=kort(i+1,4);
			else
				lastk=length(lijnver2);
			end
			verder=1;
			while ((j<=kort(i,2))|((k<=lastk)&(lijnver2(k)==0)))&verder
				%fprintf('    i=%3d,k=%3d\n',j,k);
				verder=0;
				if j<=kort(i,2)
					verder=1;
					l1=detab(tekst1{j});
					if isempty(l1)
						l1=' ';
					elseif length(l1)>maxlijnlen-3
						l1=[l1(1:maxlijnlen-3) '...'];
					end
					s=[s sprintf(['%4d:' formlijn '  '],j,l1)];
					j=j+1;
				else
					s=[s sprintf('%s',spc(ones(1,maxlijnlen+7)))];
				end	% print lijn van tekst1
				if (k<=lastk)&(lijnver2(k)==0)
					verder=1;
					l1=detab(tekst2{k});
					if isempty(l1)
						l1=' ';
					elseif length(l1)>maxlijnlen-3
						l1=[l1(1:maxlijnlen-3) '...'];
					end
					s=[s sprintf(['%4d:%s'],k,l1)];
					k=k+1;
				end	% print lijn van tekst2
				s=[s sprintf('\n')];
			end	% while nog in blok
		end	% verschil-lijnen
	end	% for alle blokken
	if nargout
		Verg=geefresultaat(s,f2);
	else
		geefresultaat(s,f2);
	end
	return
elseif strcmp(f1,'toonddif')
	s=sprintf('Vergelijking van files in directories %s <-> %s\n\n',LASTDir1,LASTDir2);
	vers=LASTDirVer;
	i=1;
	k=1;
	while (i<=length(vers))&strcmp(vers{i}.soort,'gelijk')
		if k
			s=[s sprintf('Gelijke files :\n')];
			k=0;
		end
		s=[s sprintf('%s\n',vers{i}.file)];
		i=i+1;
	end
	k=1;
	while (i<=length(vers))&strcmp(vers{i}.soort,'verschil')
		if k
			s=[s sprintf('\nVerschillende files :\n\n')];
			k=0;
		end
		s=[s sprintf('%s\n%s\n',vers{i}.file,lijnkar(ones(1,length(vers{i}.file))))];
%		filever([deblank(vers{i}.dirs(1,:)) '\' vers{i}.file],[deblank(vers{i}.dirs(2,:)) '\' vers{i}.file])
		s=[s filever('toonfdif',[],vers{i}.verschil)];
		i=i+1;
	end
	k=1;
	while (i<=length(vers))&strcmp(vers{i}.soort,'enkel 1')
		if k
			s=[s sprintf('\nFiles enkel in %s :\n',LASTDir1)];
			k=0;
		end
		s=[s sprintf('%s\n',vers{i}.file)];
		i=i+1;
	end
	k=1;
	while (i<=length(vers))&strcmp(vers{i}.soort,'enkel 2')
		if k
			s=[s sprintf('\nFiles enkel in %s :\n',LASTDir2)];
			k=0;
		end
		s=[s sprintf('%s\n',vers{i}.file)];
		i=i+1;
	end
	if nargout
		Verg=geefresultaat(s,f2);
	else
		geefresultaat(s,f2);
	end
	return
elseif strcmp(f1,'grafdif')
	s=sprintf('%s   <--->  %s\n',LASTF1,LASTF2);
	if isstruct(LASTVerg)
		lijnver1=LASTVerg.verw1;
		lijnver2=LASTVerg.verw2;
	else
		fprintf('Geen verschil.\n')
		return
	end
	nfigure
	set(gca,'Box','on');
	set(gca,'YDir','reverse')
	axis([-0.2 1.2 0 max(length(lijnver1),length(lijnver2))+1])
	set(gca,'XTick',[0 1],'XTickLabel',{LASTF1,LASTF2})
	for i=1:length(lijnver1)
		if lijnver1(i)
			line([0 1],[i lijnver1(i)]);
		else
			line(0,i,'Marker','o')
		end
	end
	for i=1:length(lijnver2)
		if ~lijnver2(i)
			line(1,i,'Marker','o')
		end
	end
	title(s)
	return
elseif strcmp(f1,'del2')
	%?vragen voor deleten ?
	if ~exist('f2','var')|isempty(f2)
		fprintf('Niets te verwijderen.\n');
	elseif strcmp(f2,'gelijk')
		j=0;
		for i=1:length(LASTDirVer)
			if strcmp(LASTDirVer{i}.soort,'gelijk')
				fn=fullfile(deblank(LASTDirVer{i}.dirs(2,:)),LASTDirVer{i}.file);
				delete(fn);
				fprintf('"%s" verwijderd....\n',fn)
				j=j+1;
			end
		end
		if j
			if j==1
				fprintf('1 file');
			elseif j>1
				fprintf('%d files',j);
			else
				fprintf('van de %d verwijderd.\n',length(LASTDirVer));
			end
		else
			fprintf('Geen gelijke files\n');
		end
	end
	return
elseif isempty(f2)
	error('Verkeerd gebruik van filever')
else
	if size(f1,1)>1
		s1=-1;
	else
		s1=exist(f1);
		if s1==0
			error(sprintf('"%s" niet gevonden.',f1));
		end
	end
	if size(f2,1)>1
		s2=-1;
	else
		s2=exist(f2);
		if s2==0
			error(sprintf('"%s" niet gevonden.',f2));
		end
	end
	if s1==7
		if s2~=7
			error('Verkeerd gebruik van filever (combinatie van directory en ...)');
		end
		LASTDir1=f1;
		LASTDir2=f2;
		vers={};
		dir1=dir(f1);
		dir2=dir(f2);
		status('Vergelijken van twee directories',0)
		for i=1:length(dir1)
			j=1;
			while ~strcmp(dir1(i).name,dir2(j).name)
				j=j+1;
				if j>length(dir2)
					break;
				end
			end
			if j>length(dir2)
				j=[];
			else
				dir2data=dir2(j);
				dir2(j)=[];
			end
			if dir1(i).isdir
				if strcmp(dir1(i).name,'.')|strcmp(dir1(i).name,'..')
					% doe niets
				else
					% ? subdirectories ook 'doen'
				end
			else	% geen directory
				if isempty(j)
					%fprintf('file "%s" is te vinden in directory 1 en niet in 2\n',dir1(i).name)
					vers{end+1}=struct('file',dir1(i).name	...
						,'soort','enkel 1'	...
						,'dirs',strvcat(f1,f2)	...
						,'date',dir1(i).date	...
						,'lengte',dir1(i).bytes	...
						);
				else
					%fprintf('%s<->%s\n',[f1 '\' dir1(i).name],[f2 '\' dir1(i).name])
					v=filever([f1 '\' dir1(i).name],[f2 '\' dir1(i).name]);
					if isstruct(v)
						vers{end+1}=struct('file',dir1(i).name	...
							,'soort','verschil'	...
							,'verschil',v	...
							,'dirs',strvcat(f1,f2)	...
							,'date',strvcat(dir1(i).date,dir2data.date)	...
							,'lengte',[dir1(i).bytes;dir2data.bytes]	...
							);
					else
						vers{end+1}=struct('file',dir1(i).name	...
							,'soort','gelijk'	...
							,'dirs',strvcat(f1,f2)	...
							,'date',strvcat(dir1(i).date,dir2data.date)	...
							,'lengte',[dir1(i).bytes;dir2data.bytes]	...
							);
					end
				end
					
			end	% geen directory
			status(i/length(dir1));
			if isempty(dir2)
				break;
			end
		end	% for alle dir1's
		for i=1:length(dir2)
			if dir2(i).isdir
			else
				%fprintf('file "%s" is te vinden in directory 2 en niet in 1\n',dir2(i).name)
				vers{end+1}=struct('file',dir2(i).name	...
					,'soort','enkel 2'	...
					,'dirs',strvcat(f1,f2)	...
					,'date',dir2(i).date	...
					,'lengte',dir2(i).bytes	...
					);
			end
		end
		files='';
		soorten=zeros(length(vers),1);
		for i=1:length(vers)
			switch vers{i}.soort
				case 'gelijk'
					soorten(i)=0;
				case 'verschil'
					soorten(i)=1;
				case 'enkel 1'
					soorten(i)=2;
				case 'enkel 2'
					soorten(i)=3;
				otherwise
					soorten(i)=4;
					error('Normaal kom ik hier niet')
			end
			files=strvcat(files,vers{i}.file);
		end
		[soorten,i]=sort(soorten);
		files=files(i,:);
		vers=vers(i);
		for i=0:max(soorten)
			j=find(soorten==i);
			if ~isempty(j)
				[files(j,:),k]=sortstr(files(j,:));
				vers(j)=vers(j(k));
			end
		end
		status
		LASTVERUse=2;
		LASTDirVer=vers;
		if nargout
			Verg=vers;
		else
			filever toondif
		end
		return
	elseif s1==2||s1<0
		if s2~=2&&s2>0
			error('Verkeerd gebruik van filever (combinatie van file en ...)');
		end
		LASTF1=f1;
		LASTF2=f2;
		if s1<0
			tekst1=String2Lines(f1);
		else
			fid=fopen(f1,'r');
			tekst1={};
			while ~feof(fid)
				tekst1{end+1}=fgetl(fid);
			end
			fclose(fid);
			if ~isempty(tekst1)
				if ~ischar(tekst1{end})
					tekst1{end}={};
				end
			end
		end
		if s2<0
			tekst2=String2Lines(f2);
		else
			fid=fopen(f2,'r');
			tekst2={};
			while ~feof(fid)
				tekst2{end+1}=fgetl(fid);
			end
			fclose(fid);
			if ~isempty(tekst2)
				if ~ischar(tekst2{end})
					tekst2{end}={};
				end
			end
		end
	else
		error('Verkeerd gebruik van filever');
	end
end

LASTTekst1=tekst1;
LASTTekst2=tekst2;

% Pas tekst aan om niet teveel verschillen te zien.
for i=1:length(tekst1)
	tekst1{i}=vereenvoudig(tekst1{i});
end
for i=1:length(tekst2)
	tekst2{i}=vereenvoudig(tekst2{i});
end

i=1;
i0=0;
j0=1;
j1=1;
k=0;
allesgelijk=1;
lijnver1=zeros(length(tekst1),1);
lijnver2=zeros(length(tekst2),1);
while i<=length(tekst1)
	s1=tekst1{i};
	j=j1;
	while ~strcmp(s1,tekst2{j})
		j=j+1;
		if j>length(tekst2)
			break;
		end
	end
	if j<=length(tekst2)
		if i0==i-1
			i0=i;
		end
		lijnver1(i)=j;
		if lijnver2(j)==0
			lijnver2(j)=i;
		elseif lijnver2(j)>0
			lijnver2(j)=-2;
		else
			lijnver2(j)=lijnver2(j)-1;
		end
		k=k+1;
		
		if j==j1	% Eerst geprobeerde regel was direct een goede
			j1=j1+1;
			if (j==j0)|(k>j-j0-k)
				j0=j1;
			end
		else
			allesgelijk=0;
			j1=j+1;	%???enkel bij hogere waardes van k????
		end
	elseif k	% Vorige regel was wel gelijk
		allesgelijk=0;
		k=0;
		if j1>j0
			j1=j0;	% Doe de regel opnieuw, nu beginnend van vroeger
			i=i-1;
		end
	end
	if j1>length(tekst2)
		if k
			if j0<=length(tekst2)
				while (j0<length(tekst2))&lijnver2(j0)
					j0=j0+1;
				end
				j1=j0;
			else
				break;
			end
		else
			break
		end
	end
	i=i+1;
end
if allesgelijk&(j1<=length(tekst2))
	allesgelijk=0;
end

if allesgelijk
	LASTVerg=1;
else
	i=find(diff(lijnver1)~=1);	%lijnver1(1:end-1)&lijnver1(2:end)&(
	if ~isempty(i)
		j=1;
		while j<=length(i)
			k=i(j);
			if (lijnver1(k+1)~=0)&(k>1)&(k<length(lijnver1)-1)
				if lijnver1(k)==0
					if lijnver1(k+1)+1==lijnver1(k+2)
						%ok
					elseif lijnver1(k+2)==0	% "enkeling"
						l=lijnver1(k+1);
						lijnver1(k+1)=0;
						lijnver2(l)=newlijnv2(lijnver1,lijnver2,l);
						j=j+1;
					else
					end
				else	% lijnver1(k)~=0
					if lijnver1(k+1)==0
					elseif lijnver1(k+1)+1~=lijnver1(k+2)
						l=lijnver1(k+1);
						lijnver1(k+1)=0;
						lijnver2(l)=newlijnv2(lijnver1,lijnver2,l);
						j=j+1;
					end
				end	% lijnver1(k)~=0
			end	% k niet te dicht bij begin of eind
			j=j+1;
		end
	end
	
	i=find(lijnver2<0);
	if ~isempty(i)
	
	end
	
	gelijk=lijnver1(1)~=0;
	x=zeros(0,4);
	i=1;
	while i<=length(lijnver1)
		i0=i;
		if gelijk
			while (i0==i)|(lijnver1(i)==lijnver1(i-1)+1)
				i=i+1;
				if i>length(lijnver1)
					break;
				end
			end
			x(end+1,:)=[i0 i-1 lijnver1(i0) lijnver1(i-1)];
			gelijk=0;
		else
			while ~lijnver1(i)
				i=i+1;
				if i>=length(lijnver1)
					break;
				end
			end
			x(end+1,:)=[i0 i-1 0 0];
			gelijk=1;
		end
	end
	i=2;	% Het eerste gedeelte moet geen minimale lengte hebben.
	minngelijk=5;
	while i<size(x,1)	% Het laatste gedeelte moet ook geen minimale lengte hebben.
		if x(i,3)
			if x(i,2)-x(i,1)~=x(i,4)-x(i,3)	% test op juistheid van werking dit programma
				error('!!!!!!Programma loopt fout')
			end
			if x(i,2)-x(i,1)<minngelijk
				j=x(i,1);
				k=x(i,3);
				while j<=x(i,2)
					l=lijnver1(j);
					lijnver1(j)=0;
					lijnver2(l)=newlijnv2(lijnver1,lijnver2,l);
					j=j+1;
					k=k+1;
				end
				x(i-1,2)=x(i+1,2);
				x(i:i+1,:)=[];
			else
				i=i+1;
			end
		else
			i=i+1;
		end
	end
	LASTVerg=struct(	...
		'file1',LASTF1,'file2',LASTF2	...
		,'tekst1',{LASTTekst1},'tekst2',{LASTTekst2}	...
		,'verw1',lijnver1,'verw2',lijnver2,'kort',x);
end
LASTVERUse=1;
if nargout
	Verg=LASTVerg;
else
	filever toondif
end

function x=newlijnv2(lijnver1,lijnver2,i)
% NEWLIJNV2 - Verwijdert referentie van lijnver2
if lijnver2(i)>0
	x=0;
elseif lijnver2(i)==-1
	error('Dit kan niet zijn...')
elseif lijnver2(i)==-2
	j=find(lijnver1==i);
	if length(j)~=1
		error('Dan is er iets fout gelopen')
	end
	x=j;
else
	x=lijnver2(i)+1;
end

function uit=geefresultaat(s,f)
if nargout
	uit=s;
elseif ~exist('f')|isempty(f)
	fprintf('%s',s)
elseif ischar(f)
	fid=fopen(f,'wt');
	if fid<=0
		error('Kan file niet openen')
	end
	fprintf(fid,'%s',s);
	fclose(fid);
else
	fprintf(fid,'%s',s);
end

function t=detab(s)
t=strrep(s,char(9),'   ');

function t=vereenvoudig(s)
t=deblank(strrep(s,char(9),' '));
if ~isempty(t)
	if t(1)==' '
		t(1)=' ';
		i=find(t~=' ');
		t(2:i(1)-1)='';
	end
end

function tekst=String2Lines(S)
S=S(:)';
iCR=find(S==13);
iLF=find(S==10);
if length(iCR)==length(iLF)
	% DOS/windows
	S(iCR)=[];
	iLF=find(S==10);
elseif length(iCR)>length(iLF)
	if ~isempty(iLF)
		warning('?mixed text modes?')
		if iLF(1)==1
			S(1)=[];
			iLF=find(S==10);
		end
		if ~isempty(iLF)
			S(iLF(S(iLF-1)==13))=[];
		end
		iLF=find(S==13|S==10);
	end
else
	if ~isempty(iCR)
		warning('?mixed text modes?')
		if iCR(end)==length(S)
			S(end)=[];
			iCR(end)=[];
		end
		if ~isempty(iCR)
			S(iLF(S(iLF+1)==10))=[];
		end
		iLF=find(S==13|S==10);
	end
end
nL=length(iLF);
tekst=cell(1,nL+1);
tekst{1}=S(1:iLF(1)-1);
for i=2:nL
	tekst{i}=S(iLF(i-1)+1:iLF(i)-1);
end
tekst{end}=S(iLF(nL)+1:end);
