function D=readIXXATtrace(fn,varargin)
%readIXXATtrace - Reads CAN-trace of IXXAT minimon
%    D=readIXXATtrace(fn)
%      X=readIXXATtrace(D,cmd)
%         cmd:
%            'plot'
%            'anal'

if isstruct(fn)&&isfield(fn,'name')&&isfield(fn,'datenum')
	fn=fn.name;
end
if isstruct(fn)
	Din=fn;
	switch varargin{1}
		case 'anal'
			Ns=sort(Din.nID);
			A=zeros(length(Din.uID)+1,Ns(end)+Ns(end-1));
			iA=1;
			n1=0;
			A(end,1)=1;
			for i=1:length(Din.ID)
				j=find(Din.ID(i)==Din.uID);
				if A(j,iA)==0
					n1=n1+1;
				else
					n1=1;
					iA=iA+1;
					A(end,iA)=i;
				end
				A(j,iA)=n1;
			end
			D=A(:,1:iA);
		case 'plot'
			bRunWait=true;
			if nargin>3
				setoptions({'bRunWait'},varargin{3:end})
			end
			[f,bN]=getmakefig('CANtrace',true,true,'logged CAN-msg analysis');
			if bN
				navfig
			end
			n=length(Din.uID);
			if nargin<=2||isempty(varargin{2})
				ii=1:n;
			else
				ii=varargin{2};
			end
			for i=ii
				imagesc(Din.D(Din.iID{i},2:1+Din.D(Din.iID{i}(1)))');
				dt=diff(Din.T(Din.iID{i}));
				title(sprintf('%d/%d, ID %08x (%d) - dt %6.1fms (%6.1f)'	...
					,i,n,Din.uID(i),Din.nID(i)	...
					,mean(dt)*1e3,std(dt)*1e3))
				colorbar;
				if length(ii)>1
					if bRunWait
						pause;
					else
						break %#ok<UNRCH>
					end
				end
			end
			setappdata(f,'traceData',Din)
			setappdata(f,'traceIndex',i)
			navfig('addkey','2',0,@PrevCANid)
			navfig('addkey','8',0,@NextCANid)
			navfig('addkey','1',0,@FirstCANid)
			navfig('addkey','9',0,@LastCANid)
	end
	return
end
[bCANOPEN] = false;
[optsUnused] = {};
if nargin>1
	[~,~,optsUnused]=setoptions([2,0],{'bCANOPEN'},varargin{:});
end
bRelTime = false;
iDLC = [];
[~,~,fExt]=fileparts(fn);
if strcmpi(fExt,'.tr0')
	[H,C,T,ID,E,D] = ReadTR0(fn);
else
	cFile=cBufTextFile(fn);

	%(!very simple - non-safe!)

	lTitle=cFile.fgetl();
	cDelim=[];	% if empty, '"' locations are used
	if strncmp(lTitle,'ASCII Trace',5)
		lDate=cFile.fgetl(); %#ok<NASGU>
		lTstart=cFile.fgetl(); %#ok<NASGU>
		lTend=cFile.fgetl(); %#ok<NASGU>
		lOverruns=cFile.fgetl(); %#ok<NASGU>
		lBaud=cFile.fgetl(); %#ok<NASGU>
		lHead=cFile.fgetl(); %#ok<NASGU>
		H=var2struct('lTitle','lDate','lTstart','lTend','lOverruns','lBaud','lHead');
		iTime=1;
		iID=3;
		iData=9;
	elseif strncmp(lTitle,'Start Time',10)
		H=cell(1,10);
		nH=1;
		H{1}=lTitle;
		l=cFile.fgetl();
		while l(1)~='"'
			nH=nH+1;
			H{nH}=l;
			l=cFile.fgetl();
		end
		nH=nH+1;
		H{nH}=l;
		H=H(1:nH);
		ii=find(l=='"');
		for i=1:2:length(ii)
			switch lower(l(ii(i)+1:ii(i+1)-1))
				case 'time'
					iTime=i;
				case 'dlc'
					% not used
				case 'id (hex)'
					iID=i;
				case 'data (hex)'
					iData=i;
			end
		end
	elseif contains(lTitle,'"Bus"')
		cDelim = ',';
		H = regexp(lTitle,cDelim,'split');
		iTime=find(strcmp('"Time (abs)"',H));
		if isempty(iTime)
			bRelTime = true;
			iTime=find(strcmp('"Time (rel)"',H));
		end
		iID=find(strcmp('"ID (hex)"',H));
		iDLC=find(strcmp('"DLC"',H));
		iData=find(strcmp('"Data (hex)"',H));
		%'"ASCII"'
	else
		error('Unknown file format!')
	end

	C=cFile.fgetlN(min(1e8,round(cFile.lFile/15)));
	clear cFile
	C(cellfun(@isempty,C))=[];

	nC=length(C);
	T=zeros(1,nC);
	E=false(1,nC);	% not used!!!
	ID=T;
	DLC = T;
	D=zeros(nC,9);
	fT=[3600 60 1];
	cHEX=false(1,255);
	cHEX(abs(' 0123456789ABCDEFabcdef'))=true;
	W=cell(1,10);
	for i=1:nC
		l=C{i};
		if isempty(cDelim)
			ii=find(l=='"');
			sTime = l(ii(iTime)+1:ii(iTime+1)-1);
			sID = l(ii(iID)+1:ii(iID+1)-1);
			sData = l(ii(iData)+1:ii(iData+1)-1);
		else
			% build-in method available?  (simple regexp doesn't work due to ',' in some data
			bInString=false;
			nW=0;
			j=1;
			jWord=1;
			while j<=length(l)
				if l(j)=='"'
					bInString=~bInString;
				elseif jWord==j&&isspace(l(j))
					jWord=j+1;
				elseif ~bInString&&l(j)==','
					w=deblank(l(jWord:j-1));
					if length(w)>1&&w(1)=='"'&&w(end)=='"'
						w=w(2:end-1);
					end
					nW=nW+1;
					W{nW}=w;
					jWord=j+1;
				elseif j<length(l)&&l(j)=='\'
					j=j+1;	% skip
				end
				j=j+1;
			end
			w=deblank(l(jWord:j-1));
			if length(w)>1&&w(1)=='"'&&w(end)=='"'
				w=w(2:end-1);
			end
			nW=nW+1;
			W{nW}=w;
			sTime = strtrim(W{iTime});
			sID = strtrim(W{iID});
			sData = strtrim(W{iData});
			if ~isempty(iDLC)
				sDLC = strtrim(W{iDLC});
			end
		end
		t=sscanf(sTime,'%d:%d:%g');
		T(i)=fT*t;
		d=sscanf(sData,'%x');
		if ~isempty(iDLC)
			dlc = sscanf(sDLC,'%d');
			if dlc~=length(d)
				warning('DLC ~= #bytes?!!! (%s)',l)
			end
			DLC(i) = dlc;
		end
		D(i)=length(d);
		D(i,2:1+length(d))=d;
		if all(cHEX(abs(sID)))
			ID(i)=sscanf(sID,'%x');
		else
			ID(i)=-1;
		end
	end
end
uID=unique(double(ID));
if isempty(uID)
	nID = 0;
elseif isscalar(uID)
	nID = length(ID);
else
	nID=hist(double(ID),uID);
end
iID=cell(1,length(uID));
for i=1:length(uID)
	iID{i}=find(ID==uID(i));
end
if bRelTime
	dT = T;
	T = cumsum(dT);
end

D=struct('head',{H},'C',{C},'T',T,'ID',ID,'E',E,'D',D	...
	,'uID',uID,'nID',nID,'iID',{iID});
if ~isempty(iDLC)
	D.DLC = DLC;
end
if bRelTime
	D.dT = dT;
end
if bCANOPEN
	D = InterpretCANOPEN(D,optsUnused{1:2,:});
end

function PrevCANid(f)
D=getappdata(f,'traceData');
i=getappdata(f,'traceIndex');
i=i-1;
if i<1
	i=length(D.uID);
end
readIXXATtrace(D,'plot',i);

function NextCANid(f)
D=getappdata(f,'traceData');
i=getappdata(f,'traceIndex');
i=i+1;
if i>length(D.uID)
	i=1;
end
readIXXATtrace(D,'plot',i);

function FirstCANid(f)
D=getappdata(f,'traceData');
readIXXATtrace(D,'plot',1);

function LastCANid(f)
D=getappdata(f,'traceData');
readIXXATtrace(D,'plot',length(D.uID));

function [H,C,T,ID,Bextended,D] = ReadTR0(fn)
fid = fopen(fFullPath(fn));
if fid<3
	error('Can''t open the file!')
end
x = fread(fid,[1 Inf],'*uint8');
fclose(fid);
ix=38;

H_I32 = double(typecast(x(21:32),'uint32'));
H_I16=double(typecast(x([17:20,33:38]),'uint16'));
lHead = H_I32(1);
nMsgs = H_I32(2);
maxLenBlock = H_I16(3);	% ? pure guess
head = x(1:ix);

lName = double(typecast(x(ix+1:ix+2),'uint16'));
Name = char(typecast(x(ix+3:ix+2+lName*2),'uint16'));
ix = ix+lName*2+2;
ix = ix+4;	% check if all zeros?

X = zeros(28,nMsgs,'uint8');
C = zeros(4,nMsgs,'uint8');
nC = 0;
nX = 0;
while ix<length(x)
	if rem(nX,128)==0
		nC = nC+1;
		C(:,nC)=x(ix+1:ix+4);
		ix=ix+4;
	end
	n=x(ix+1);
	ixn=ix+double(n)+1;
	if ixn>length(x)
		break
	end
	nX = nX+1;
	X(1:n,nX)=x(ix+2:ixn);
	ix=ixn;
end
C=C(:,1:nC);
T=double(typecast(reshape(X(1:8,1:nX),1,[]),'uint64'))/1e7;	% fixed scale?!!!!
T = unwrapgen(T,2^32/1e7);
ID=typecast(reshape(X(15:18,1:nX),1,[]),'uint32');
D=X([19 21:28],1:nX)';
Bextended = X(12,:);
H = var2struct(Name,H_I32,head);
