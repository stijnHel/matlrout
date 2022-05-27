function [Dfiles,Ddirs,Deocd]=ReadZip(fName,varargin)
%ReadZip  - Read and extract (in memory) a zip file
%       D=ReadZip(fName)
% The directory structure is read, and files that could be decomressed are
%    decompressed.
% No CRC-checks are done;

% in "reconstruction"!!!!!
%    oorspronklijk:
%         file helemaal gelezen --> x
%         gebruik x met lopende ix
%    nu:
%         optie om deel per deel te lezen (vooral gemaakt voor grote files)
%              ook is er de optie om de data zelf te lezen of niet (en dus
%                 enkel de structuur te behouden.

[bUncompress]=true;
[bReadAll]=true;	% not yet ready - read all at once
[bReadData]=true;
if nargin>1
	setoptions({'bUncompress','bReadData','bReadAll'},varargin{:})
end

bFileOpen=false;
if ischar(fName)
	bFileOpen=true;
	fid=file(fFullPath(fName,[],'.zip'));
	if bReadAll
		x=fid.fread([1 Inf],'*uint8');
		fid.fclose();
		bFileOpen=false;
	end
elseif isa(fName,'uint8')
	if size(fName,1)>1
		x=fName';
	else
		x=fName;
	end
else
	error('Wrong input to this file')
end

ix=0;
Dfiles=[];
Ddirs=[];
bLoop=true;
while bLoop
	if bReadAll
		x1=x(ix+1:ix+4);
		ix=ix+4;
	else
		x1=fread(fid,[1 4],'*uint8');
		if length(x1)<4
			break
		end
	end
	if ~strcmp(char(x1(1:2)),'PK')
		if bReadAll&&all(x(ix+1:end)==0)
			% just "filling data" - not worth warning the user
		else
			warning('Wrong format (no "PK")@#%d! - reading stopped',ix)
		end
		return
	end
	if x1(3)==3&&x1(4)==4	% local file header
		if bReadAll
			x1=x(ix+1:ix+26);
			ix=ix+26;
		else
			x1=fread(fid,[1 26],'*uint8');
		end
		verMin=x1(1:2);
		genFlag=ToInt(x1(3:4));
		compMeth=ToInt(x1(5:6));
		lastModTime=ToTime(x1(7:8));
		lastModDate=ToDate(x1(9:10));
		CRC32=uint32(ToInt(x1(11:14)));
		sizComp=ToInt(x1(15:18));
		sizUncomp=ToInt(x1(19:22));
		lfName=ToInt(x1(23:24));
		lExtra=ToInt(x1(25:26));
		if bReadAll
			fName=char(x(ix+1:ix+lfName)); %#ok<NASGU>
			ix=ix+lfName;
			x1=x(ix+1:ix+lExtra);
			ix=ix+lExtra;
		else
			fName=fread(fid,[1 lfName],'*char'); %#ok<NASGU>
			x1=fread(fid,[1 lExtra],'*uint8');
		end
		extra=ReadExtra(x1,1);
		if genFlag&&bitand(genFlag,8)	%not known!?!
			if sizComp
				warning('READZIP:unknownCompSiz'	...
					,'uncompressed file size not known, but compressed file size is known?!')
			else
				B=x(ix+1:end-3)=='P'&x(ix+2:end-2)=='K';
				B1 = B & ((x(ix+3:end-1)==1&x(ix+4:end)==2)	...
					| (x(ix+3:end-1)==3&x(ix+4:end)==4)	...
					| (x(ix+3:end-1)==5&x(ix+4:end)==6)	...
					| (x(ix+3:end-1)==7&x(ix+4:end)==8)	...
					);
				iPK=ix+find(B1,1);
				if isempty(iPK)
					%warning('postponed file sizes without data descriptor block?!')
					sizComp=length(x)-ix;
				else
					sizComp=iPK-ix-1;
				end
			end
		end
		if bReadData
			if bReadAll
				fData=x(ix+1:ix+sizComp);
				ix=ix+sizComp;
			else
				fData=fread(fid,[1 sizComp],'*uint8');
			end
			% (is it possible that sizComp == 0?)
			fUncomp=[];
			switch compMeth
				case 0
					fUncomp=fData;
				case 8	% inflate
					if bUncompress
						if sizComp<3
							sHex = sprintf('0x%02x ',fData);
							warning('Small compressed data but not empty uncompressed?! (%s)',sHex(1:end-1))
							fUncomp=[];
						elseif sizUncomp==0
							try
								fUncomp=zinflate(fData);
							catch err
								DispErr(err)
								warning('Tried to inflate data without success...')
							end
						else
							fUncomp=zinflate(fData,sizUncomp);
						end
					end
				otherwise
					warning('READZIP:unknownCompType'	...
						,'Unknown (or not implemented) compression type (%d)',compMeth)
			end
		else
			fData=[];
			fUncomp=[];
			if bReadAll
				ix=ix+sizComp;
			elseif sizComp>0
				fid.fseek(sizComp,'cof');
			end
		end
		Dfile=var2struct(verMin,genFlag,compMeth,lastModTime,lastModDate,CRC32	...
			,sizComp,sizUncomp,'fName',extra,fData,fUncomp);
		if isempty(Dfiles)
			Dfiles=Dfile;
		else
			Dfiles(1,end+1)=Dfile; %#ok<AGROW>
		end
	elseif x1(3)==1&&x1(4)==2	% central directory file header
		if bReadAll
			x1=x(ix+1:ix+42);
			ix=ix+42;
		else
			x1=fread(fid,[1 42],'*uint8');
		end
		verMade=x1(1:2);
		verMin=x1(3:4);
		genFlag=ToInt(x1(5:6));
		compMeth=ToInt(x1(7:8));
		lastModTime=ToTime(x1(9:10));
		lastModDate=ToDate(x1(11:12));
		CRC32=ToInt(x1(13:16));
		sizComp=ToInt(x1(17:20));
		sizUncomp=ToInt(x1(21:24));
		lfName=ToInt(x1(25:26));
		lExtra=ToInt(x1(27:28));
		lfComm=ToInt(x1(29:30));
		diskNr=ToInt(x1(31:32));
		intfAttr=ToInt(x1(33:34));
		extfAttr=ToInt(x1(35:38));
		relOffLocHead=ToInt(x1(39:42));
		if bReadAll
			fName=char(x(ix+1:ix+lfName)); %#ok<NASGU>
			ix=ix+lfName;
			x1=x(ix+1:ix+lExtra);
			ix=ix+lExtra;
			fComm=char(x(ix+1:ix+lfComm)); %#ok<NASGU>
			ix=ix+lfComm;
		else
			fName=fread(fid,[1 lfName],'*char'); %#ok<NASGU>
			x1=fread(fid,[1 lExtra],'*uint8');
			fComm=fread(fid,[1 lfComm],'*char'); %#ok<NASGU>
		end
		extra=ReadExtra(x1,2);
		Ddir=var2struct(verMade,verMin,genFlag,compMeth,lastModTime,lastModDate,CRC32	...
			,sizComp,sizUncomp,diskNr,intfAttr,extfAttr,relOffLocHead	...
			,'fName',extra,'fComm');
		if isempty(Ddirs)
			Ddirs=Ddir;
		else
			Ddirs(1,end+1)=Ddir; %#ok<AGROW>
		end
	elseif x1(3)==5&&x1(4)==6	% end of central 
		if bReadAll
			x1=x(ix+1:ix+18);
			ix=ix+18;
		else
			x1=fread(fid,[1 18],'*uint8');
		end
		nrDisk=ToInt(x1(1:2));
		centrDirDisk=ToInt(x1(3:4));
		nrCdirRecs=ToInt(x1(5:6));
		totNcDirRecs=ToInt(x1(7:8));
		sizCentrDir=ToInt(x1(9:12));
		offStartCDir=ToInt(x1(13:16));
		sizComm=ToInt(x1(17:18));
		if bReadAll
			comm=char(x(ix+1:ix+sizComm)); %#ok<NASGU>
			ix=ix+sizComm;
		else
			comm=fread(fid,[1 sizComm],'*char'); %#ok<NASGU>
		end
		Deocd=var2struct(nrDisk,centrDirDisk,nrCdirRecs,totNcDirRecs	...
			,sizCentrDir,offStartCDir,'comm');
	elseif x1(3)==7&&x1(4)==8	% data descriptor
		if bReadAll
			x1=x(ix+1:ix+12);
			ix=ix+12;
		else
			x1=fread(fid,[1 12],'*uint8');
		end
		CRC32=ToInt(x1(1:4));
		sizComp=ToInt(x1(5:8));
		sizUncomp=ToInt(x(9:12));
		Dfiles(end).CRC32=CRC32;
		Dfiles(end).sizComp=sizComp;
		Dfiles(end).sizUncomp=sizUncomp;
	else
		error('Unexpected/not implemented PK-data chunk (@#%d - %02x%02x)',ix,x(ix+3:ix+4))
	end
	if bReadAll
		bLoop=ix<length(x);
	end
end		% while bLoop
if bFileOpen
	fid.fclose();
end

function y=ToInt(x)
if length(x)==2
	y=double(x)*[1;256];
elseif length(x)==4
	y=double(x)*[1;256;65536;16777216];
else
	error('Wrong input')
end

% date and time interpretation
function time=ToTime(x)
s=rem(double(x(1)),32)*2;
m=floor(double(x(1))/32)+rem(double(x(2)),8)*8;
h=floor(double(x(2))/8);
time=[h,m,s];

function date=ToDate(x)
d=rem(double(x(1)),32);
m=floor(double(x(1))/32)+rem(double(x(2)),2);
y=floor(double(x(2))/2)+1980;
date=[d,m,y];

function E=ReadExtra(x,iHeader)
E=struct('nID',cell(1,20),'cID',[],'data',[]);
nE=0;
ix=0;
while ix<length(x)
	nE=nE+1;
	E(nE).nID=ToInt(x(ix+1:ix+2));
	E(nE).cID=char(x(ix+1:ix+2));
	l=ToInt(x(ix+3:ix+4));
	ix=ix+4;
	E(nE).data=x(ix+1:ix+l);
	ix=ix+l;
	switch E(nE).cID
		case 'UT'
			if iHeader==1
				if l==13
					flg=E(nE).data(1);
					modTime=Tim2MLtime(ToInt(E(nE).data(2:5)),'winSeconds');
					acTime=Tim2MLtime(ToInt(E(nE).data(6:9)),'winSeconds');
					crTime=Tim2MLtime(ToInt(E(nE).data(10:13)),'winSeconds');
					E(nE).data=var2struct(flg,modTime,acTime,crTime);
				elseif l==9	% unknown format?!!!
					E(nE).data=E(nE).data;
				else
					warning('Wrong assumption about UT-local header')
					E(nE).data=E(nE).data;
				end
			else
				if l~=5
					error('Wrong assumption about UT-central header')
				end
				flg=E(nE).data(1);
				modTime=Tim2MLtime(ToInt(E(nE).data(2:5)),'winSeconds');
				E(nE).data=var2struct(flg,modTime);
			end
		otherwise
		%see http://www.opensource.apple.com/source/zip/zip-6/unzip/unzip/proginfo/extra.fld
		%  or https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
		%      for more ID's
	end
end
E=E(1:nE);
