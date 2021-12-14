function [D,T] = leesdtlg(fnaam)
% LEESDTLG - functie om DTLG-labView-file te lezen
%     [D,T] = leesdtlg(fnaam)
%
%  functie in opbouw vanuit leesnlph-functie

bSimplifyOutput=true;

if nargin==0
   help leesnlph
   return
end

fid=fopen(zetev([],fnaam),'r');
if fid<3
	error('Kan de file niet openen');
end
x=fread(fid,[1 4],'*char');
if ~strcmp(x,'DTLG')
	fclose(fid);
	error('File heeft verkeerd formaat');
end
versie=fread(fid,[1 4],'uint8')';
nblok=[16777216 65536 256 1]*fread(fid,[4 1],'uint8');
start1=[16777216 65536 256 1]*fread(fid,[4 1],'uint8');
if start1==0	%!!!
	pos=ftell(fid);
	fseek(fid,0,'eof');
	lFile=ftell(fid);
	fseek(fid,pos,'bof');
end
lDesc=[256 1]*fread(fid,[2 1],'uint8');
if lDesc<6	%!!!!!!
	if start1==0
		nDesc=lFile-ftell(fid);
	else
		nDesc=start1-ftell(fid);
	end
	desc=fread(fid,nDesc,'uint8');
	nelems=[256 1]*desc(1:2);
	k=3;
else
	desc=fread(fid,lDesc-2,'uint8');
	clust_internal=desc(1);
	clust=desc(2);
	nelems=[256 1]*desc(3:4);
	k=5;
end
T=cell(nelems,4);
for i=1:nelems
	ld1=[256 1]*desc(k:k+1);
	kNext=k+ld1;
	%!!! verwijzing van array en cluster naar elementen in lijst!!!!
	%       nog niet gebruikt!!!!!!!
	T1=readLVtypeString(	...
		swapbytes(typecast(uint8(desc(k:kNext-1)),'uint16'))	...
		,'bDTLG',true,'bFlatten',false);
		% working via uint16 should be avoided!!!!
	if isstruct(T1{3})&&isfield(T1{3},'T')
		%!!!!!???? fast test for arrays
		T1{3}.T=T(T1{3}.T+1,:);
	end
	T(i,:)=T1;
	k=kNext;
end
i1=[256 1]*desc(k:k+1);
nElData=[256 1]*desc(k+2:k+3);	% (!)niet # data, maar "main element in T"
k=k+4;	% end of desc?

if size(T,1)>1
	% Clearly "crazy problem solving..."
	if isnumeric(T{end,3})
		Teff=T(T{end,3}+1,:);
	else
		%Teff=T(end,:);
		Teff=T;
	end
else
	Teff=T;
end

if bSimplifyOutput
	Teff=SimplifyStructure(Teff);
end

if nblok==0
	D=[];
elseif start1==0	% fixed length data, no index-info
	D=readLVtypeString(Teff,desc(k:end),'ball',-nblok,'bStruct',true);
else	% with indexes
	%fseek(fid,start1,'bof');%!!!!necessary / test ???
	z=[];
	y=[16777216 65536 256 1]*fread(fid,[4 128],'uint8');
	volblok=y(end);
	% delete y(end)?
	fseek(fid,0,'eof');
	lBlockMax=1e7;
	lFile=ftell(fid);
	if nblok>1
		iy=0;
		iz=1;
		for iD=1:nblok
			iy=iy+1;
			if iy>length(y)
				iz=iz+1;
				if isempty(z)
					Z=fread(fid,[4 128],'uint8');
					if isequal(size(Z),[4,128])
						z=[16777216 65536 256 1]*Z;
					else
						z=[];
					end
				elseif iz>=length(z)
					if isempty(zz)
						zz=[16777216 65536 256 1]*fread(fid,[4 128],'uint8');
					end
					z=[16777216 65536 256 1]*fread(fid,[4 128],'uint8');
					iz=0;
				else
					fseek(fid,z(iz),'bof');
				end
				%y0=[16777216 65536 256 1]*fread(fid,[4 1],'uint8');
				%y=[16777216 65536 256 1]*fread(fid,[4 127],'uint8');
				y=[16777216 65536 256 1]*fread(fid,[4 128],'uint8');
				iy=1;
			end
			fseek(fid,y(iy),'bof');	% if simply saved data - not needed
			% look to length of block?
			if iy<length(y)
				xN=y(iy+1);
			elseif start1==0	%???!!!!!!!
				xN=lFile;
			else
				xN=start1;
			end
			if xN==0
				xN=lFile;
			elseif xN<y(iy)
				xN=lFile;
			end
			if xN-y(iy)>lBlockMax
				xN=y(iy)+lBlockMax;
			end
			x=fread(fid,xN-y(iy),'*uint8');	%....!!!!
			D1=readLVtypeString(Teff,x,'bStruct',true);
			if iD==1
				D=D1(1,ones(1,nblok));
			else
				D(iD)=D1;
			end
		end
	end
end
fn=fieldnames(D);
while length(fn)==1
	D=[D.(fn{1})];
	if ~isstruct(D)
		break
	end
	fn=fieldnames(D);
end
fclose(fid);

function s=leesstr(fid)
l=[16777216 65536 256 1]*fread(fid,[4 1],'uint8');
if isempty(l)
	s='';
	return
end
s=fread(fid,[1 l],'*char');

function A=leesA(fid)
ncol=[16777216 65536 256 1]*fread(fid,[4 1],'uint8');
nrij=[16777216 65536 256 1]*fread(fid,[4 1],'uint8');
if isempty(nrij)
	A=[];
	return
end
A=[256 1]*fread(fid,[2 nrij*ncol],'uint8');
A=reshape(A-65536*(A>32767),nrij,ncol);

function [s,i]=getstr(x,i)
s=char(x(i+1:i+x(i))');
i=i+x(i)+1;

function T=SimplifyStructure(T)
if iscell(T)
	if size(T,1)==1&&iscell(T{1,3})
		T=SimplifyStructure(T{3});
	else
		for i=1:size(T,1)
			T{i,3}=SimplifyStructure(T{i,3});
		end
	end
end
