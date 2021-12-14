function [Sdir,X]=readMScompDoc(fName)
%readMScompDoc - Reads a document in the Microsoft CompDoc format
%    Sdir=readMScompDoc(fName)

fid=fopen(fName);
if fid<3
	error('Can''t open the file')
end

x=fread(fid,[1 Inf],'*uint8');
fclose(fid);

ff4=[1 cumprod(256+zeros(1,3))]';
ff2=ff4(1:2);
freeSecID=-1;
EOCsecID=-2;
SSATsecID=-3;
MSATsecID=-4;

H=x(1:512);
CDFid=H(1:8);
if ~isequal(CDFid,[208 207 17 224 161 177 26 225])
	error('Wrong file ID')
end
fileID=H(9:24); %#ok<NASGU>
fileRevision=getINT16(H,24); %#ok<NASGU>
fileVersion=getINT16(H,26); %#ok<NASGU>
byteOrderID=H(29:30);
if isequal(byteOrderID,[254 255])
	bLittleEndian=true;	%#ok<NASGU> % little endian (normal)
elseif isequal(byteOrderID,[255 254])
	bLittleEndian=false;	%#ok<NASGU> % big endian (not normal)
	warning('MScDoc:bigEndian','Not expected: big endian!')
else
	error('impossible endian (byte order) identifier')
end
sizeSectorPower=getINT16(H,30);
sizeSector=2^sizeSectorPower; 
sizeShortSectorPower=getINT16(H,32);
sizeShortSector=2^sizeShortSectorPower; 
totNrSATSectors=getINT32(H,44); %#ok<NASGU>
secIDdir=getINT32(H,48);
minSizeSStream=getINT32(H,56);
secID1stSSAT=getINT32(H,60);
totNrSSAT=getINT32(H,64); %#ok<NASGU>
secID1stMSAT=getINT32(H,68); %#ok<NASGU>
totNrSectorsMSAT=getINT32(H,72);
MSAT1=getNINT32(H,76,436/4);

%MSAT
MSAT=MSAT1;
iM=0;
while MSAT(end)~=-1
	if iM>totNrSectorsMSAT
		warning('MScDoc:MSATproblem','????iets loopt fout met Master Sector Allocation Table!!!')
		break
	end
	MSATi=getSectorINT32(MSAT(end));
	MSAT(end:end+length(MSATi)+1)=MSATi;
end
MSAT=MSAT(1:find(MSAT<0,1)-1);

% SAT
SAT=getSectorINT32(MSAT(1));
if length(MSAT)>1
	SAT(length(MSAT),1)=0;
	for i=2:length(MSAT)
		SAT(i,:)=getSectorINT32(MSAT(i));
	end
	SAT=reshape(SAT',1,[]);
end
while SAT(end)==freeSecID
	SAT(end)=[];
end

% SSAT
if secID1stSSAT>=0
	SSAT=getFullSector(secID1stSSAT);
	SSAT=getNINT32(SSAT,0,length(SSAT)/4);
else
	SSAT=[];
end

% directory

S=getFullSector(secIDdir);
nDirMax=length(S)/128;
for i=1:nDirMax
	S1=getDirEntry(S((i-1)*128+(1:128)));
	S1.data=[];
	if i==1
		SS=S1;
		SS(length(S)/128).name='';
	else
		SS(i)=S1;
	end
	if ~isempty(S1.name)&&S1.totSizeStream>0
		if i>1&&S1.totSizeStream<minSizeSStream
			s=getList(SSAT,S1.secIDfirst);
			ss=zeros(sizeShortSector,length(s));
			SStream=SS(1).data;
			for j=1:length(s)
				nr=s(j);
				ss(:,j)=SStream(nr*sizeShortSector+(1:sizeShortSector));
			end
			ss=ss(:);
		else
			ss=getFullSector(S1.secIDfirst);
		end
		SS(i).data=ss(1:S1.totSizeStream);
	end
end
% flatten red-black tree
Sdir=flattenDir(0);
Sdir=Sdir.children;

if nargout>1
	X=var2struct({'fileID','fileRevision','fileVersion','bLittleEndian'	...
		,'sizeSectorPower','sizeSector','sizeShortSector','totNrSATSectors'	...
		,'secIDdir','minSizeSStream','secID1stSSAT','totNrSSAT'	...
		,'secID1stMSAT','totNrSectorsMSAT','MSAT','SAT','SSAT','SS'});
end

	function d=getINT16(x,idx)
		d=double(x(idx+1:idx+2))*ff2;
		if d>32767
			d=d-65536;
		end
	end

	function d=getINT32(x,idx)
		d=double(x(idx+1:idx+4))*ff4;
		if d>2147483647
			d=d-4294967296;
		end
	end

	function d=getNINT32(x,idx,n)
		d=ff4'*double(reshape(x(idx+1:idx+4*n),4,[]));
		d=d-(d>2147483647)*4294967296;
	end

	function S=getSectorINT32(nr)
		S=getNINT32(x,nr*sizeSector+512,sizeSector/4);
	end

	function S=getSectorRaw(nr)
		S=x(nr*sizeSector+512+(1:sizeSector));
	end

	function L=getList(T,nr)
		L=nr;
		while T(L(end)+1)>=0
			L(1,end+1)=T(L(end)+1); %#ok<AGROW>
		end
	end

	function S=getFullSector(nr)
		sList=getList(SAT,nr);
		S=zeros(sizeSector,length(sList));
		for idx=1:length(sList)
			S(:,idx)=getSectorRaw(sList(idx))';
		end
		S=S(:)';
	end

	function flatDir=flattenDir(nr)
		flatDir=SS(nr+1);
		flatDir.children=[];
		root=flatDir.dirIDRoot;
		if root>0	% (==0 is impossible)
			flatDir.children=flattenDir(root);
		end
		left=flatDir.dirIDLeft;
		right=flatDir.dirIDRight;
		if left>0
			flatDir=[flattenDir(left) flatDir];
		end
		if right>0
			flatDir=[flatDir flattenDir(right)];
		end
	end


	function S=getDirEntry(x)
		lName=getINT16(x,64)-2;
		if lName<=0
			name=''; %#ok<NASGU>
		else
			name=char(ff2'*double(reshape(x(1:lName),2,lName/2))); %#ok<NASGU>
		end
		typ=x(67); %#ok<NASGU>
		nodeCol=x(68); %#ok<NASGU>
		dirIDLeft=getINT32(x,68); %#ok<NASGU>
		dirIDRight=getINT32(x,72); %#ok<NASGU>
		dirIDRoot=getINT32(x,76); %#ok<NASGU>
		uID=x(81:96); %#ok<NASGU>
		userFlags=getINT32(x,96); %#ok<NASGU>
		timeStampCreation=datenum(1601,1,1)+double(x(101:108))*[1;cumprod(256+zeros(7,1))]*1e-7/3600/24; %#ok<NASGU>
		timeStampMod=datenum(1601,1,1)+double(x(109:116))*[1;cumprod(256+zeros(7,1))]*1e-7/3600/24; %#ok<NASGU>
		secIDfirst=getINT32(x,116); %#ok<NASGU>
		totSizeStream=getINT32(x,120); %#ok<NASGU>
		S=var2struct('name','typ','nodeCol','dirIDLeft','dirIDRight'	...
			,'dirIDRoot','uID','userFlags','timeStampCreation'	...
			,'timeStampMod','secIDfirst','totSizeStream');
	end
end
