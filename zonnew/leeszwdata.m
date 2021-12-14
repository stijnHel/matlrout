function [S,extra]=leeszwdata(fn)%LEESZWDATA - Leest data voor zonnewijzerglobal cCsts cCsts2global constsfid=fopen(fn);if fid<3	error('Kan file niet openen')endextra={};% defaultsDsetProj=[21 6 2006];	% als lengte kleiner dan 4, plaatselijk middaguuranaDagen=[21-0.5/24 6 2006;21 6 2006;21+0.5/24 6 2006];anaUren=0:24:24*365;zonDagen=[21 3 2006;21 6 2006;21 9 2006;21 12 2006];zonUren=[10:0.05:14];wijzerType='analemma';cCsts=zeros(1,255);cCsts([abs('_') abs('a'):abs('z') abs('A'):abs('Z')])=1;cCsts2=cCsts;cCsts2(abs('0123456789'))=1;S=struct(	...	'titel',''	...	,'origin',fn	...	,'spiegel',[]	...	,'geog',[]	...	,'hoekZuiden',0	...	,'DsetProj',DsetProj,'PsetProj',[]	...	,'anaDagen',anaDagen,'anaUren',anaUren	...	,'zonDagen',zonDagen,'zonUren',zonUren	...	,'bGeogMiddagRef',0	...	,'type',wijzerType	...	,'bSpiegel',1	...	,'consts',[]	...	,'data',[]	...	,'ZWs',[]	...	);consts=struct('dummyxxxx',0);Ppunt=struct('nr',0,'pos',[],'naam',[],'comment',[]);Plijn=struct('nr',0,'ptn',[],'naam',[],'comment',[],'coor',[]);Pvlak=struct('nr',0,'ptn',[],'naam',[],'comment',[],'coor',[],'norm',[],'a',[]);Pteken=struct('type',[],'data',[],'opties',[]);S.titel=fgetl(fid);camerapositie=[];cameratarget=[];cameraviewangle=[];projecties=[];meridiaan=[];bExtra=0;while ~feof(fid)	l=fgetl(fid);	if ischar(l)		l=deblank(l);	end	if ~isempty(l)		l(l==9)=' ';		iIs=find(l=='=');		if isempty(iIs)			parts=getdelen(l);			switch lower(parts{1})			case 'type'				if ~strcmp(parts{2},'analemma')&~strcmp(parts{2},'zonnewijzer')					error('Verkeerd type')				end				S.type=parts{2};			case 'isspiegel'				S.bSpiegel=valjaneedata(parts{2});			case 'geog'				if cCsts(abs(parts{2}(1)))					S.geog=parts{2};				else					error('numerieke data voor geog nog niet voorzien')				end			case 'geogmiddagref'				S.bGeogMiddagRef=valjaneedata(parts{2});			case 'autospiegelor'				S.bAutoSpiegelOr=valjaneedata(parts{2});			case 'hoekzuiden'				S.hoekZuiden=str2num(parts{2});			case 'zondagen'				S.zonDagen=InterpreteData(l(parts{2,2}:end));			case 'anadagen'				S.anaDagen=InterpreteData(l(parts{2,2}:end));			case 'spiegel'				S.spiegel=GetPtCoords(Ppunt,str2num(parts{2}));			case 'camerapositie'				camerapositie=GetPtCoords(Ppunt,str2num(parts{2}));			case 'cameratarget'				cameratarget=GetPtCoords(Ppunt,str2num(parts{2}));			case 'cameraviewangle'				cameraviewangle=str2num(parts{2});			case 'meridiaan'				n=str2num(parts{2});				vlakken=zeros(1,n);				for i=1:n					vlakken(i)=str2num(parts{2+i});				end				meridiaan=vlakken;			case 'projectie'				projecties(end+1)=str2num(parts{2});			case 'p'				% ?kijken of dit al bestaat?				nr=str2num(parts{2});				x=evallijn(parts{3});				y=evallijn(parts{4});				z=evallijn(parts{5});				naam='';				comment='';				if length(parts)>5					naam=parts{6};					if length(parts)>6						comment=l(parts{7,2}:end);					end				end				Ppunt(end+1).nr=nr;				Ppunt(end).pos=[x y z];				Ppunt(end).naam=naam;				Ppunt(end).comment=comment;			case 'l'				% ?kijken of dit al bestaat?				nr=str2num(parts{2});				n=str2num(parts{3});				ptn=zeros(1,n);				for i=1:n					ptn(i)=str2num(parts{3+i});				end				naam='';				comment='';				if length(parts)>3+n					naam=parts{4+n};					if length(parts)>4+n						comment=l(parts{5+n,2}:end);					end				end				Plijn(end+1).nr=nr;				Plijn(end).ptn=ptn;				Plijn(end).naam=naam;				Plijn(end).comment=comment;				Plijn(end).coor=GetPtCoords(Ppunt,ptn);			case 'v'				% ?kijken of dit al bestaat?				nr=str2num(parts{2});				n=str2num(parts{3});				ptn=zeros(1,n);				for i=1:n					ptn(i)=str2num(parts{3+i});				end				naam=['vlak ' num2str(nr)];				comment='';				if length(parts)>3+n					naam=parts{4+n};					if length(parts)>4+n						comment=l(parts{5+n,2}:end);					end				end				Pvlak(end+1).nr=nr;				Pvlak(end).ptn=ptn;				Pvlak(end).naam=naam;				Pvlak(end).comment=comment;				X=GetPtCoords(Ppunt,ptn);				Pvlak(end).coor=X;				N=cross(X(2,:)-X(1,:),X(3,:)-X(1,:));				N=N/sqrt(N*N');				Pvlak(end).norm=N;				Pvlak(end).a=N*X(1,:)';			case 'teken'				Pteken(end+1).type=parts{2};				Pteken(end).data=str2num(parts{3});			case 'einde'				if length(parts)>1					if strcmp(parts{2},'extra')						bExtra=1;					end				end				break;			otherwise				error(sprintf('Onbekende opdracht (%s)',l))			end		else	% bepaling van constante			i=1;			while l(i)==' '				i=i+1;			end			cst=deblank(l(i:iIs(1)-1));			val=evallijn(l(iIs(1)+1:end));			consts=setfield(consts,cst,val);		end	endendif bExtra&nargout>1	while ~feof(fid)		l=fgetl(fid);		if ischar(l)			l=deblank(l);			if ~isempty(l)				while l(1)==' '|l(1)==9					l(1)=[];				end				if strcmp(lower(l),'eindextra')					break;				else					extra{end+1}=l;				end			end		end	endendfclose(fid);if isempty(S.spiegel)	error('!!!Geen spiegelpositie gegeven!!!')enddata=struct('P',Ppunt(2:end),'L',Plijn(2:end),'V',Pvlak(2:end),'teken',Pteken(2:end)	...	,'camerapositie',camerapositie,'cameratarget',cameratarget,'cameraviewangle',cameraviewangle	...	,'projecties',projecties,'meridiaan',meridiaan	...	);S.data=data;S.consts=rmfield(consts,'dummyxxxx');Vnrs=cat(2,Pvlak.nr);ZWSs=cell(1,length(projecties));SS=struct('naam',[],'posvlak',[],'orvlak',[],'limprojvlak',[],'rotprojectie',0);for i=1:length(projecties)	j=find(projecties(i)==Vnrs);	if isempty(j)		error('Onbekend projectievlak')	end	N=Pvlak(j).norm;	a=Pvlak(j).a;	if N*(S.spiegel-Pvlak(j).coor(1,:))'-a<0		N=-N;		a=-a;	end	X=Pvlak(j).coor;	SS.naam=Pvlak(j).naam;	SS.posvlak=X(1,:);	SS.orvlak=N;	if max(abs(N(1:2)))<1e-7		% minstens ongeveer horizontaal vlak		if N(3)>0			p=[0 0];		else			p=[pi 0];		end	else		p1=acos(N(3));		p2=atan2(-N(1),N(2));		p=[p1 p2];	end	Rprojvlak=rotzr(p(2))*rotxr(p(1))*rotzr(-p(2));	X2D=Rprojvlak*(X-X([1 1 1],:))';	SS.limprojvlak=[min(X2D(1,:)) max(X2D(1,:)) min(X2D(2,:)) max(X2D(2,:))];	ZWSs{i}=SS;endS.ZWs=struct('S',ZWSs);function [P,startBlank,I]=getdelen(l)% oproepen met niet lege en "gedeblankte" stringP=cell(0,2);i=1;if l(1)==' '	startBlank=1;	i=2;	while l(i)==' '		i=i+1;	endelse	startBlank=0;endwhile i<=length(l)	i0=i;	while l(i)~=' '		i=i+1;		if i>length(l)			break;		end	end	P{end+1,1}=l(i0:i-1);	P{end,2}=i0;	while i<length(l)&l(i)==' '		i=i+1;	endendfunction val=evallijn(l)global cCsts cCsts2global constsi=1;while i<=length(l)	if cCsts(abs(l(i)))		i0=i;		while i<length(l)&cCsts2(abs(l(i+1)))			i=i+1;		end		c1=l(i0:i);		if isfield(consts,c1)			sv1=['consts.' c1];			l=[l(1:i0-1) sv1 l(i+1:end)];			i=i0+length(sv1);		else			error(sprintf('constante "%s" bestaat niet',c1))		end	else		i=i+1;	endendval=eval(l);if length(val)~=1|~isnumeric(val)	error(sprintf('Verkeerde evaluatie (%s)',l))endfunction val=valjaneedata(s)if s(1)>='0'&s(1)<='9'	val=str2num(s);elseif strcmp(s,'ja')	val=1;elseif strcmp(s,'nee')	val=0;else	error('Onbekende ja-nee-data')endfunction L=GetLijn(S,nr)i=find(cat(2,S.data.L.nr)==nr);if isempty(i)	error('Onbekend lijnnummer')endL=S.data.L(i);function X=GetPtCoords(P,nrs)X=zeros(length(nrs),3);Pnrs=cat(2,P.nr);for i=1:length(nrs)	j=find(Pnrs==nrs(i));	if isempty(j)		error('Onbekend puntnummer')	end	X(i,:)=P(j).pos;endfunction D=InterpreteData(l)l(l=='/')='-';Idat=[0 find(l==',') length(l)+1];D=zeros(length(Idat)-1,6);for i=1:length(Idat)-1	[d,n,lerr,Inxt]=sscanf(l(Idat(i)+1:Idat(i+1)-1),'%d-%d-%d %d:%d:%g',[1 6]);	if n<2		error('Verkeerde input voor zonDagen')	elseif n<3		d0=clock;		d(3)=d0(1);	elseif d(3)<100		d(3)=d(3)+2000;	end	D(i,1:length(d))=d;end