function X=ReadCANLOG(fName,typ,varargin)
%ReadCANLOG - Read log created by (LabVIEW-)CANlogger
%         X=ReadCANLOG(fName[,typ])
%  Extended for different file formats:
%       *.bin ---> LV_IXXAT files (from CANlogger)
%       *.csv ---> IXXAT Can Analyzer mini
%       *.log ---> * Other IXXAT file format? ("save dump" in old version?)
%                  * CNH-log file

[bCANOPEN] = false;
[optsUnused] = {};
fFull = fFullPath(fName);
fid=file(fFull,'r','ieee-be');
xStart = fid.fread([1 32],'*uint8');
fid.fseek(0,'bof');
if nargin<2||isempty(typ)
	[~,~,fExt]=fileparts(fFull);
	switch lower(fExt)
		case '.bin'
			typ='LV_IXXAT';
		case {'.csv','.tr0'}
			typ='mini_ixxat';
		case '.log'
			if strcmp(char(xStart(1:4)),'(159')
				typ = 'candump';
			else
				typ='busmaster';
			end
		case '.asc'
			typ='vector';
		otherwise
			fid.fclose();
			error('Unknown type')
	end		% switch
end		% no given type
if nargin>2
	[~,~,optsUnused]=setoptions([2,0],{'bCANOPEN'},varargin{:});
end

CHAN=1;
Dextra=[];
switch lower(typ)
	case 'lv_ixxat'
		t0=lvtime([],fid);
		n=fread(fid,1,'uint32');
		TYP=fread(fid,n,'*uint16');
		TT=readLVtypeString(TYP);
		n=fread(fid,1,'uint32');
		if isempty(n)
			warning('Empty file?')
			X = struct('t0',t0,'T',[],'TS',[],'ID',[],'DLC',[],'D',[],'uID',[]);
			return
		end
		fseek(fid,-4,'cof');
		fStart = ftell(fid);
		X=fread(fid,[4+n+16,Inf],'*uint8');
		if all(all(X(1:4,:)==X(1:4,1),2))	% all equal size
			XD=X(5:n+4,:);
			T=lvtime(X(n+5:end,:));
			DD=readLVtypeString(TT,XD(:),'-ball');
		else	% not equal size blocks
			warning('Not all blocks have the same size!')
			fseek(fid,fStart+n+20,'bof');
			x=fread(fid,[1 Inf],'*uint8');
			DD = readLVtypeString(TT,reshape(X(5:n+4,1),[],1));
			DD = DD(:,[2 ones(1,size(X,2))]);	% (with size(X,2) an estimation of number of elements
			T=lvtime(X(n+5:end,1));
			T(size(X,2)) = T;
			ix = 0;
			iD = 2;
			while ix<length(x)
				n = double(typecast(x(ix+4:-1:ix+1),'uint32'));
				if n<=4	% apparently it can happen?!!
					warning('Empty data?!')
					ix = ix+20;
					continue
				end
				try
					DDi = readLVtypeString(TT,x(ix+5:ix+n+4));
				catch err
					DispErr(err)
					warning('Error when reading file - file writing stopped suddenly?')
					break
				end
				DD(:,iD+1) = DDi(:,1);
				T(iD) = lvtime(x(ix+n+5:ix+n+20));
				ix = ix+n+20;
				iD = iD+1;
			end
			if iD<size(DD,2)
				DD = DD(:,1:iD);
				T = T(1:iD-1);
			end
		end
		if any(strcmp(TT(:,4),'Data'))
			bT = strcmp(TT(:,4),'Timestamp');
			bID = strcmp(TT(:,4),'Arbitration ID');
			[fldExtra,iExtra] = setdiff(TT(:,4),{'Timestamp','Arbitration ID','Data'});
			bD = strcmp(TT(:,4),'Data');
			D = zeros(8,size(DD,2)-1,'uint8');
			DLC = zeros(size(DD,2)-1,1);
			%T = cat(1,DD{bT,2:end});
			TS = T-T(1);
			ID = cat(1,DD{bID,2:end});
			for i=1:size(DD,2)-1
				Di = DD{bD,i+1};
				DLC(i) = length(Di);
				D(1:DLC(i),i) = Di;
			end
			for i=1:length(fldExtra)
				Dextra.(MakeVarNames(fldExtra{i})) = cat(1,DD{iExtra(i),2:end});
			end
		else
			%Dall=cell2mat(DD(:,2:end));
			TS = [DD{1,2:end}];
			ID = [DD{2,2:end}];
			DLC = [DD{3,2:end}];
			Dextra=lvData2struct(DD(4:9,[2 1]));
			flds=fieldnames(Dextra);
			for i=4:9
				Dextra.(MakeVarNames(flds{i-3})) = [DD{i,2:end}];
			end
			D = cell2mat(DD(10:17,2:end));
		end
	case 'vector'
		X = leescana(fid);
		t0 = [];
		T = X(:,10);
		TS = X(:,10);
		DLC = X(:,11);
		% Do something with Tx? (column 11)
		ID = X(:,1);
		D = X(:,2:9);
	case 'mini_ixxat'
		fclose(fid);
		X=readIXXATtrace(fFullPath(fName));
		X.CHAN=1;
		return
	case 'busmaster'
		lFile=fid.length();
		H=cell(1,20);
		nH=0;
		t0=[];
		TS=[];
		l=fgetl(fid);
		while strncmp(l,'***',3)
			nH=nH+1;
			H{nH}=l;
			l=fgetl(fid);
		end
		if nH<length(H)
			H=H(1:nH);
		end
		estNmsgs=round(lFile/56);
		D=zeros(estNmsgs,8);
		DLC=zeros(estNmsgs,1);
		CHAN=DLC;
		T=DLC;
		ID=DLC;
		nD=0;
		while ischar(l)&&~isempty(l)&&~strncmp(l,'***',3)
			[t,n,~,nxt]=sscanf(l,'%02d:%02d:%02d:%04d',4);
			if n<4
				warning('Problem reading line!')
				break
			end
			nxt=nxt+1;
			if l(nxt)=='R'
				bTX=false;
			elseif l(nxt)=='T'
				bTX=true;
			else
				warning('No Tx or Rx?')
			end
			channelNr=sscanf(l(nxt+2:nxt+4),'%d');
			l=l(nxt+5:end);
			[id,~,~,nxt]=sscanf(l,'%x',1);
			bExt=l(nxt+1)=='x';
			dlc=sscanf(l(nxt+2:nxt+4),'%d');
			d=sscanf(l(nxt+5:end),'%02x');
			nD=nD+1;
			T(nD)=[3600 60 1 0.0001]*t;
			DLC(nD)=dlc;
			ID(nD)=id;
			CHAN(nD)=channelNr;
			D(nD,1:length(d))=d;
			l=fgetl(fid);
		end
		if nD<length(T)
			T=T(1:nD);
			DLC=DLC(1:nD);
			D=D(1:nD,:);
			ID=ID(1:nD);
			CHAN=CHAN(1:nD);
		end
		F=cell(1,20);
		nF=0;
		while ischar(l)
			nF=nF+1;
			F{nF}=l;
			l=fgetl(fid);
		end
		if nF<length(F)
			F=F(1:nF);
		end
	case 'candump'
		nMax = round(fid.length()/22);
		T = zeros(nMax,1);
		DLC = T;
		D = zeros(nMax,8,'uint8');
		ID = T;
		CHAN = T;
		t0 = T(1);
		TS = [];
		Dextra = [];
		nD = 0;
		while ~fid.feof()
			l = fid.fgetl();
			if ~ischar(l)
				break
			elseif isempty(l)
				continue;	% or break?
			end
			W = regexp(l,' ','split');
			nD = nD+1;
			T(nD) = sscanf(W{1}(2:end-1),'%g');
			CHAN(nD) = W{2}(end)-'0';
			[id,~,~,iNxt] = sscanf(W{3},'%x');
			ID(nD) = id;
			d = sscanf(W{3}(iNxt+1:end),'%02x',[1 8]);
			DLC(nD) = length(d);
			D(nD,1:length(d)) = d;
		end		% while
		T=T(1:nD);
		DLC=DLC(1:nD);
		D=D(1:nD,:);
		ID=ID(1:nD);
		CHAN=CHAN(1:nD);
	otherwise
		error('Unknown log-type')
end
fid.fclose();
uID=unique(ID(:)');
bScalar=isscalar(uID);
if bScalar
	nID=length(ID);
else
	nID=hist(double(ID),double(uID));
end
bID=cell(1,length(uID));
for i=1:length(uID)
	bID{i}=find(ID==uID(i));
end

X=var2struct(t0,T,TS,ID,DLC,D,Dextra,uID,nID,bID,CHAN);
if bCANOPEN
	X = InterpretCANOPEN(X,optsUnused{1:2,:});
end
