function [e,ne,de,e2,gegs,str,err]=leesmdf2(f,start,eind,ongeschaald)
% LEESMDF2 - Leest MDF-files (Measurement Data File)
%        Originally made for ASCET-SD-measurement/simulation files
%     [e,ne,de]=leesmdf(meting)

global LASTCOMMENT

if ~exist('start','var')||isempty(start)
	start=0;
end
if ~exist('eind','var')||isempty(eind)
	eind=inf;
end

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
if ~strcmp(HD,'HD')
	warning('Something wrong?!')
end
if isempty(bHD)
	fclose(fevent);
	error('De file is te kort')
end
if isempty(sdat)
	HD_i=sgroup;
	sgroup=HD_i(1);	%!!!!
	sdat=HD_i(2);
end

groepen=struct('e',{},'ne',{},'de',{});
grinfo=zeros(0,2);
nkan=0;
while sgroup
	[DG,bDG,ngroup,sgr1]=leesblok(fevent,sgroup);
	if ~strcmp(DG,'DG')
		fclose(fevent);
		error('Andere volgorde dan verwacht');
	end
	if isempty(sgr1)
		DG_i=ngroup;
		ngroup=DG_i(1);
		sgr1=DG_i(2);
	end
	
	startf=endian*bDG(13:16);
	n1=endian2*bDG(17:18);	%?1 groep
	nextra=endian2*bDG(19:20);	%?extra bytes per record?
	if n1~=1
		fclose(fevent);
		error('Deze file kan ik niet verwerken');
	end
	
	[CG,bCG,ngroup1,kan1]=leesblok(fevent,sgr1);
	if isempty(kan1)
		CG_i=ngroup1;
		ngroup1=CG_i(1);
		kan1=CG_i(2);
	end
	n1    =endian2*bCG(13:14);
	nkan  =endian2*bCG(15:16);
	nbytes=endian2*bCG(17:18);
	nsamp =endian     *bCG(19:22);
	if ngroup1~=0
		fclose(fevent);
		error('Deze file kan ik niet verwerken');
	end
	
	if start==0 && eind<nsamp-1
		fprintf('%d van de %d meetpunten ingelezen.\n',eind,nsamp);
	end
	eind1=min(nsamp-1,eind);
	nsamp=min(nsamp,eind1-start+1);
	
	ne='';
	de='';
	e=zeros(nsamp,nkan);
	
	for i=1:nkan
		[KAN,bKAN,kan1,cdim]=leesblok(fevent,kan1);
		if isempty(cdim)
			KAN_i=kan1;
			kan1=KAN_i(1);
			cdim=KAN_i(2);
		end
		off =endian2*bKAN(183:184);
		nbit=endian2*bKAN(185:186);
		soor=endian2*bKAN(187:188);
		nskip=nbytes+nextra-ceil(nbit/8);
		if soor==0
			if nbit==1
				fsoort='char';
			elseif nbit==8
				fsoort='char';
			elseif nbit==16
				fsoort='short';
			elseif nbit==32
				fsoort='long';
			else
				fclose(fevent);
				error('Het aantal bits met soort 0 is anders dan verwacht');
			end
		elseif soor==1	%??
			if nbit==1
				fsoort='char';
			elseif nbit==8
				fsoort='char';
			elseif nbit==32
				fsoort='long';
			elseif nbit==16
				fsoort='short';
			else
				fclose(fevent);
				error('Het aantal bits met soort 1 is anders dan verwacht');
			end
		elseif soor==2
			fsoort='float';
			if nbit~=32
				fclose(fevent);
				error('Het aantal bits met soort 2 is anders dan verwacht');
			end
		else
			fclose(fevent);
			error('Verkeerde soort');
		end
		if nsamp
			foffset=startf+nextra+floor(off/8)+start*(ceil(nbit/8)+nskip);
			fseek(fevent,foffset,'bof');
			e(:,i)=fread(fevent,nsamp,fsoort,nskip);
			if (soor==0)&&(nbit==1)
				e(:,i)=bitand(e(:,i),round(2^bitand(off,7)));
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
	end
	if ~isempty(groepen)||ngroup
		groepen(end+1)=struct('e',e,'ne',ne,'de',de);
		grinfo(end+1,:)=size(e);
	end
	sgroup=ngroup;
end	% lees groepen
if nkan==0
	warning('Empty measurement?')
end
if ~isempty(groepen)
	if any(grinfo(:,1)-grinfo(1))
		warning('!!!nog niets voorzien om ongelijke groepen aan elkaar te hangen!!');
	else
		e=cat(2,groepen.e);
		ne={groepen.ne};
		de={groepen.de};
	end
end
[TX,cTX]=leesblok(fevent,sdat);
if strcmp(TX,'TX')
	str=char(cTX');
	LASTCOMMENT=str;
	disp(str);
end

fclose(fevent);
if nargout>3
	e2=[];
	if nargout>4
		gegs=[0 0 0 1 1 1980 0 0 0 0 nkan 0.123456 0 16 0 0 size(e,1) 0 ones(1,nkan),zeros(1,nkan)];
	end
end
%!!!!!!
if size(e,1)>10 && e(11,1)-e(2,1)>1
	e(:,1)=e(:,1)/1e4;
end

function [tp,b,i1,i2]=leesblok(f,ind)
iConvert8=cumprod([1 256 256 256 256 256 256 256]);
iConvert4=iConvert8(1:4);
iConvert2=iConvert8(1:2);
bShortVersion=true;
if exist('ind','var')
	fseek(f,ind,-1);
end
tp=fread(f,[1,2],'*char');
if all(tp==35)	% new format(?)
	tp=deblank(fread(f,[1,6],'*char'));
	l=iConvert8*fread(f,8);
	nh=16;
	bShortVersion=false;
else
	l=iConvert2*fread(f,2);
	nh=4;
end
b=fread(f,l-nh);
if nargout>2
	if bShortVersion
		i1=iConvert4*b(1:4);
		i2=iConvert4*b(5:8);
	else
		n=iConvert8*b( 1: 8);
		i1=iConvert8*reshape(b( 9:8+n*8),8,n);
		i2=[];
	end
end
