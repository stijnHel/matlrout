function [e,ne,de,e2,gegs,str,err]=leesmdf(f,varargin)
% LEESMDF  - Leest Ascet-meet-files
%     [e,ne,de]=leesmdf(meting)

global LASTCOMMENT

start=0;
eind=inf;
bScale=false;
options=varargin;
if ~isempty(options)&&isnumeric(options{1})
	start=options{1};
	options(1)=[];
	if ~isempty(options)&&isnumeric(options{1})
		eind=options{1};
		options(1)=[];
	end
end
if ~isempty(options)
	setoptions({'start','eind','bScale'},options{:})
end
e2=[];

endian=[1 256 65536 16777216];
endian2=endian(1:2);

err=0;
str='';

fevent=fopen([zetev f],'r');
if fevent<0
	error('file niet gevonden');
end
x=fread(fevent,[1 64],'*char');
if ~strcmp(x(1:8),'MDF     ')
	fclose(fevent);
	error('Onverwacht begin');
end
[HD,bHD,sgroup,sdat]=leesblok(fevent);
if isempty(bHD)
	fclose(fevent);
	error('De file is te kort')
end
e='';

groepen=struct('e',{},'ne',{},'de',{});
grinfo=zeros(0,2);
nietAllesGelezen=0;
scale=1;
offset=0;

while sgroup
	[DG,bDG,ngroup,sgr1]=leesblok(fevent,sgroup);
	if ~strcmp(DG,'DG')
		fclose(fevent);
		error('Andere volgorde dan verwacht');
	end
	
	startf=endian*bDG(13:16);
	n1=endian2*bDG(17:18);	%?1 groep
	nextra=endian2*bDG(19:20);	%?extra bytes per record?
	if n1~=1
		fclose(fevent);
		error('Deze file kan ik niet verwerken');
	end
	
	[CG,bCG,ngroup1,kan1]=leesblok(fevent,sgr1);
	
	n1    =endian2*bCG(13:14);
	nkan  =endian2*bCG(15:16);
	nbytes=endian2*bCG(17:18);
	nsamp =endian     *bCG(19:22);
	if ngroup1~=0
		fclose(fevent);
		error('Deze file kan ik niet verwerken');
	end
	
	if start==0 & eind<nsamp-1
		if eind==0
			if nietAllesGelezen==0
				fprintf('(')
				nietAllesGelezen=-1;
			else
				fprintf(',')
			end
			fprintf('%d',nsamp)
		else
			nietAllesGelezen=1;
			fprintf('%d van de %d meetpunten ingelezen.\n',eind,nsamp);
		end
	end
	eind1=min(nsamp-1,eind);
	nsamp=min(nsamp,eind1-start+1);
	
	ne='';
	de='';
	kans=zeros(nkan,3);
	e=zeros(nsamp,nkan);
	
	for i=1:nkan
		[KAN,bKAN,kan1,cdim]=leesblok(fevent,kan1);
		off =endian2*bKAN(183:184);
		nbit=endian2*bKAN(185:186);
		soor=endian2*bKAN(187:188);
		nskip=nbytes+nextra-ceil(nbit/8);
		switch soor
		case 0	% unsigned
			if nbit==1
				fsoort='char';
			elseif nbit==8
				fsoort='uint8';
			elseif nbit==16
				fsoort='uint16';
			elseif nbit==32
				fsoort='uint32';
			else
				fclose(fevent);
				error('Het aantal bits met soort 0 is anders dan verwacht');
			end
		case 1	% unsigned
			if nbit==1
				fsoort='uchar';
			elseif nbit==8
				fsoort='uint8';
			elseif nbit==16
				fsoort='uint16';
			elseif nbit==32
				fsoort='uint32';
			else
				fclose(fevent);
				error('Het aantal bits met soort 1 is anders dan verwacht');
			end
		case 2
			if nbit==32
				fsoort='float';
			elseif nbit==64
				fsoort='double';
			else
				fclose(fevent);
				error('Het aantal bits met soort 2 is anders dan verwacht');
			end
		case 7	% ???
			soor=7;	% test
		otherwise
			fclose(fevent);
			error('Verkeerde soort');
		end
		if bScale
			scale=0;
		end
		if nsamp
			foffset=startf+nextra+floor(off/8)+start*(ceil(nbit/8)+nskip);
			fseek(fevent,foffset,'bof');
			e(:,i)=fread(fevent,nsamp,fsoort,nskip);
			if (soor==0)&(nbit==1)
				e(:,i)=bitand(e(:,i),round(2^bitand(off,7)));
				scale=1;
			end
		end
	
		j=23;
		while bKAN(j);j=j+1;end
		ne=addstr(ne,char(bKAN(23:j-1)'));
	
		[DIM,cDIM]=leesblok(fevent,cdim);
		j0=19;
		j=j0;
		while cDIM(j);j=j+1;end
		if j>j0
			dim=char(cDIM(j0:j-1)');
		else
			dim='-';
		end
		de=addstr(de,dim);
		if bScale&&scale==0
			scale=todoublele(cDIM(end-7:end));
			offset=todoublele(cDIM(end-15:end-8));
			if scale~=1|offset~=0
				e(:,i)=e(:,i)*scale+offset;
			end
		end
		%fprintf('%2d : %s [%s] (%g - %g)\n',i,ne(i,:),dim,[todoublele(bKAN(end-11:end-4)) todoublele(cDIM(end-7:end))]);
		%printhex(bKAN)
		%fprintf('\n');
		%printhex(cDIM)
	end
	if ~isempty(groepen)|ngroup
		groepen(end+1)=struct('e',e,'ne',ne,'de',de);
		grinfo(end+1,:)=size(e);
	end
	sgroup=ngroup;
end	% lees groepen
if nietAllesGelezen<0
	fprintf(') ');
end
[TX,cTX]=leesblok(fevent,sdat);
if strcmp(TX,'TX')
	str=char(cTX');
	x=zeros(256,1);
	x(1:33)=1;
	while ~isempty(str)&x(abs(str(end))+1)
		str(end)='';
	end
	LASTCOMMENT=str;
	disp(str);
end

fclose(fevent);
if nargout==1
	e=groepen;
elseif ~isempty(groepen)
	i=1;
	ig=1:length(groepen);
	while i<=length(groepen)
		if isempty(groepen(i).e)
			fprintf('groep %d :\n',ig(i))
			printstr(groepen(i).ne)
			printstr(groepen(i).de)
			groepen(i)=[];
			ig(i)=[];
		else
			i=i+1;
		end
	end
	if any(grinfo(:,1)-grinfo(1))
		if length(groepen)>2
			warning('!!!nog niets voorzien om meerdere ongelijke groepen aan elkaar te hangen!!');
			disp(grinfo)
			%e2=groepen;
			e=groepen(1).e;
			ne=groepen(1).ne;
			de=groepen(1).de;
		elseif length(groepen)==1	% andere groepen waren waarschijnlijk comment-groepen
			e=groepen.e;
			ne=groepen.ne;
			de=groepen.de;
		else
			if ~strcmp(deblank(groepen(1).ne(1,:)),'time')
				warning('!!!!??verwarring tijd met ander kanaal????')
			end
			if diff(groepen(1).e(1:2))<diff(groepen(2).e(1:2))
				e=groepen(1).e;
				e2=groepen(2).e;
				ne=strvcat(groepen(1).ne,groepen(2).ne(2:end,:));
				de=strvcat(groepen(1).de,groepen(2).de(2:end,:));
			else
				e=groepen(2).e;
				e2=groepen(1).e;
				ne=strvcat(groepen(2).ne,groepen(1).ne(2:end,:));
				de=strvcat(groepen(2).de,groepen(1).de(2:end,:));
			end
		end
	else
		e=cat(2,groepen.e);
		ne=strvcat(groepen.ne);
		de=strvcat(groepen.de);
	end
end
if ischar(e)
	warning('!!!Geen data ingelezen!!!')
	e=[];
	ne='';
	de='';
end
if nargout>3
	if nargout>4
		gegs=[0 0 0 1 1 1980 0 0 0 0 nkan 0.123456 0 16 0 0 size(e,1) 0 ones(1,nkan),zeros(1,nkan)];
	end
end

function [tp,b,i1,i2]=leesblok(f,ind)
if exist('ind')
	fseek(f,ind,-1);
end
tp=fread(f,[1,2],'*char');
l=[1 256]*fread(f,2);
b=fread(f,l-4);
if nargout>2
	i1=[1 256 65536 16777216]*b(1:4);
	i2=[1 256 65536 16777216]*b(5:8);
end
