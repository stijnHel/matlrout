function [X,D,I,digData]=leesCDfaultlog(fname,varargin)
%leesCDfaultlog - Reads the CD fault log (binary format) made for HALT test
%    [X,D,I,digData]=leesCDfaultlog(fname[,options])
%        options:
%				bTest
%				bPlot
%				bPlotT
%				nMaxRead
%				skipAfterN
%				bReadD
%				bDigSep
%				nMaxBlocks
%				nMaxPlot
%               nDecimate
%               bNav : start nav (do nav like below)
%further use:
%NAV=struct('data',D,'idx',[X(:,3);length(D)+1]);
%cnavmsrs(NAV,[],'kanx',1/I.settings.fSampling)
%  or
%ii=[X(:,3);length(D)+1];
%V=zeros(size(X,1),7);
%for i=1:size(V,1);v=D(ii(i):ii(i+1)-1);nv=length(v);if nv>5;mV=mean(v);sV=std(v);b=v>mV-5*sV&v<mV+5*sV;v=v(b);mV2=mean(v);sV2=std(v);mdV=median(v);V(i,:)=[mV sV mV2 sV2 mdV nv length(v)];end;end

global TestBadFile TTT

bTest=false;
bPlot=false;
bPlotT=true;
nMaxRead=1e6;
skipAfterN=1e7;
bReadD=[];
bDigSep=true;
bDigOut=nargout>3;
nMaxBlocks=100000;
dXsize=10000;
nMaxPlot=1.5e6;
nDecimate=10;
bNav=false;
bMarker=false;
bStructOut=[];
if nargin>1
	setoptions({'bTest','bPlot','bPlotT','nMaxRead','bReadD'	...
		,'bDigSep','nMaxBlocks','skipAfterN','nMaxPlot','nDecimate'	...
		,'bNav','bMarker','bStructOut'}	...
		,varargin{:})
end
if isempty(bStructOut)
	bStructOut=nargout<=1&&~bTest;
end
if isempty(bReadD)
	bReadD=nargout>1||bPlot||bStructOut;
end
TTT=zeros(1,1000);
bBigEndian=[];

if isnumeric(fname)
	fname=sprintf('HALT%02d.dat',fname);
end
fid=fopen(fname,'r','ieee-be');
if fid<3
	fid=fopen(zetev([],fname),'r','ieee-be');
	if fid<3
		error('Can''t open the file')
	end
end
fseek(fid,0,'eof');
lFile=ftell(fid);
fseek(fid,0,'bof');
maxLenD=min([floor((lFile-6)/8),skipAfterN,nMaxRead]);
iXtStart=1;
iXtEnd=2;
iXDstart=3;
if bTest
	iXtyp=4;
	iXdig=5;
else
	iXdig=4;
end
iXiDig=iXdig+1;
nXchan=iXiDig;
if bReadD
	nXchan=nXchan+1;
	iXvMax=nXchan;
	nXchan=nXchan+1;
	iXvMean=nXchan;
	nXchan=nXchan+1;
	iXvMedian=nXchan;
	nXchan=nXchan+1;
	iXvMin=nXchan;
	nXchan=nXchan+1;
	iXvMin10=nXchan;
	nXchan=nXchan+1;
	iXvMax10=nXchan;
end
X=zeros(min(nMaxBlocks,100000),nXchan);
if bReadD
	D=zeros(maxLenD,1);
elseif nargout>1
	D=[];
end
nX=0;
nXlast=0;
nD=0;
ii=0;
TestBadFile=0;
bElist=false(1,10);
%bElist([3 6])=true;
bElist([6])=true;
settings=[];
fS=1;
nDigData=0;
testStart=[];
testEnd=[];
firstMeas=[];
if bDigOut
	digData=zeros(100000,1);
end
sumD=zeros(1000,6);
nSD=0;
bSumWarn=false;
iBlockNr=0;
t0=[];	% "zero time" to reduce rounding errors
lenTags=zeros(1,64);	% minimum lengths on disk
lenTags([1 0 30 31]+1)=16;	% exact
lenTags([2,3,4,6,7,8]+1)=4;	% minimal
lenTags(5+1)=4;	% normally 68;
lenTags([9 20]+1)=2;
lenTags(14+1)=4;	% minimal
lenTags(21+1)=8;
nDskipped=0;
while ~feof(fid)
	curfPos=ftell(fid);
	if iBlockNr>=nMaxBlocks
		fprintf('%d blocks read, %d/%d bytes.\n',iBlockNr,curfPos,lFile);
		warning('Maximum number of blocks reached ---> stopped reading (use nMaxBlocks parameter to increase maximum number of blocks)')
		break
	end
	iBlockNr=iBlockNr+1;
	typ=fread(fid,1,'int16');
	if isempty(typ)
		break;
	end
	if typ<0||typ>64
		warning('!!!wrong tag(/type (%d)) - reading is stopped! (%d/%d)',typ,curfPos,lFile)
		break
	end
	if isempty(typ)||feof(fid)||curfPos+2+lenTags(typ+1)>lFile
		if ~isempty(typ)
			warning('File broken?');
		end
		break
	end
	if bTest
		nX=nX+1;
		X(nX,iXtyp)=typ;
	end
	if nX>=size(X,1)
		X(end+dXsize,1)=0;
	end
	switch typ
		case 1	% start
			[t,t0]=readtime(fid,t0);
			if ~bTest
				nX=nX+1;
			end
			X(nX,iXtStart)=t;
		case 0
			[t,t0]=readtime(fid,t0);
			X(nX,iXtEnd)=t;
		case {2,3,4,6,7,8}
			ii=ii+1;
			cP=ftell(fid);
			nD1=nD+1;
			if ~any(TTT(:,1)==typ)%%%testtesttest regarding endian
				fserr=fseek(fid,-32,'cof');
				TTT(end+1,1)=typ;
				TTT1=fread(fid,[1,length(TTT)-1],'uint8');
				if fserr<0
					TTT1=[zeros(1,32)-1 TTT1(1:min(end,size(TTT,2)-33))];
				end
				TTT(end,2:1+length(TTT1))=TTT1;
				fseek(fid,cP,'bof');
			end
			n=fread(fid,1,'int32');
			if n>1e6||n<0
				warning('!!!!fault at location %d/%d (n=%d)!!!!',ftell(fid),lFile,n)
				break
			end
			if n>0
				if bReadD
					if isempty(bBigEndian)
						bE=bElist(typ);
					else
						bE=bBigEndian;
					end
					if bE
						D1=fread(fid,n,'double');
					else
						D1=todouble(fread(fid,8*n,'*uint8'));
					end
					if nD<skipAfterN
						D(nD1:nD+n)=D1;
						nD=nD+n;
					else
						nDskipped=nDskipped+n;
					end
					if nXlast==nX
						D1=[D1last;D1];
					end
					%X(nX,iXvMax)=max(max(D1),X(nX,iXvMax));
					%X(nX,iXvMean)=mean([mean(D1),X(nX,iXvMean)]);
					%X(nX,iXvMedian)=max(median(D1),X(nX,iXvMedian));
					X(nX,iXvMax)=max(D1);
					X(nX,iXvMean)=mean(D1);
					X(nX,iXvMedian)=median(D1);
					X(nX,iXvMin)=min(D1);
					if n>nDecimate*2
						D1_10=median(reshapetrunc(D1,nDecimate,[]));
						X(nX,iXvMin10)=min(D1_10);
						X(nX,iXvMax10)=max(D1_10);
					end
					nXlast=nX;
					D1last=D1;
				else
					fseek(fid,n*8,'cof');
				end
			else
				TestBadFile=TestBadFile+1;
				n=0;	% for the case of negative values (fault in early LV-program)
			end
			if bTest
			elseif nX==0
				warning('measurement data before type data!')
				nX=1;
			end
			if typ==8
				% set start of raw data block (8=>posttrigger)
				X(nX,iXDstart)=nD+1;
			elseif X(nX,iXDstart)==0
				X(nX,iXDstart)=nD1;
			end
		case 5	% settings
			n=fread(fid,1,'int32');
			if n==76
				n=80;	%!!!
			end
			S=fread(fid,[1 n],'*uint8');
			sS={'fSampling','f',8;
				'VminMeas','f',8;
				'VmaxMeas','f',8;
				'sizeBlock','i',4;
				'VStartFlt','f',8;
				'VstopFlt','f',8;
				'Npre','i',4;
				'Npost','i',4;
				'NminNoFlt','i',4;
				'NmaxLog','i',4;
				'NminFltLength','i',4;
				't01','i',4;
				't02','i',4;
				't03','i',4;
				't04','i',4;
				};
			sSs=cat(2,sS{:,3});
			TsSs=cumsum(sSs);
			nData=find(TsSs==length(S));
			if isempty(nData)
				settings='unknown settings format';
			else
				iS=0;
				T=sS(1:nData,[1 3])';
				settings=struct(T{:});
				endian=[16777216;65536;256;1];
				for i=1:nData
					d=S(iS+1:iS+sS{i,3});
					switch sS{i,2}
						case 'f'
							if sS{i,3}~=8
								error('only double precision floating point numbers allowed')
							end
							v=todouble(d,1);
						case 'i'
							v=double(d)*endian(end-sS{i,3}+1:end);
						otherwise
							error('Wrong format')
					end
					settings.(sS{i,1})=v;
					iS=iS+sS{i,3};
				end
				if isfield(settings,'t04')
					warning('This comes from a program that has been lost - not tested!!!')
					t0_1=lvtime([settings.t01 settings.t02 settings.t03 settings.t04]);
					settings.t0=t0_1;
					settings=rmfield(settings,{'t01','t02','t03','t04'});
				end
				fS=settings.fSampling;
			end
		case 50	% flattened cluster settings
			n=fread(fid,1,'int32');
			sTyp=fread(fid,[1 n],'int16');
			n=fread(fid,1,'int32');
			sData=fread(fid,[1 n],'uint8');
			S=readLVtypeString(sTyp,sData);
			settings=lvData2struct(S);
			fS=settings.AI_Sample_Rate;
		case 9	% digital data
			if bTest
			elseif nX==0
				warning('measurement data before type data!')
				nX=1;
			end
			X(nX,iXdig)=fread(fid,1,'uint16');
		case 14 % high speed digital data
			n=fread(fid,1,'int32');
			if n>0
				digD1=fread(fid,n,'uint8');
			else
				digD1=zeros(0,1);
			end
			if bDigOut
				if size(digData,1)<nDigData+n
					digData(end+100000,1)=0;
				end
				digData(nDigData+1:nDigData+n)=digD1;
				if size(X,2)<iXiDig
					X(1,iXiDig)=0;	% add column(s)
				end
				if X(nX,iXiDig)==0
					X(nX,iXiDig)=nDigData+1;
				end
				nDigData=nDigData+n;
			end
		case 20	% digital data2????????
			if bTest
			elseif nX==0
				warning('measurement data before type data!')
				nX=1;
			end
			X(nX,iXdig)=fread(fid,1,'uint16');
		case 21 % analog summary data
			nidx=fread(fid,1,'int32');
			idx=fread(fid,nidx,'int32');
			nad=fread(fid,1,'int32');
			ad=fread(fid,nad,'double');
			if ~bSumWarn&&(nidx~=2||nad~=3)
				bSumWarn=true;
				warning('LEESCDfault:summaryData','Unexpected number of summary-data')
			end
			nSD=nSD+1;
			if nSD>size(sumD,1)
				sumD(end+1000,1)=0;
			end
			sumD(nSD,1)=nX;
			sumD(nSD,2:4)=ad';
			sumD(nSD,5:6)=idx';
		case 30	% test starting time
			[t,t0,tlv]=readtime(fid,t0);
			testStart=tlv;
		case 31	% test ending time
			[t,t0,tlv]=readtime(fid,t0);
			testEnd=tlv;
		case 32	% first measurement time
			[t,t0,tlv]=readtime(fid,t0);
			testEnd=tlv;
			firstMeas=tlv;
		otherwise
			warning('!!!!fault at location %d/%d (typ=%d)!!!!',ftell(fid),lFile,typ)
			break
	end
	if bReadD
		if nD>nMaxRead
			fprintf('Stopped reading at file position %d/%d.\n',ftell(fid),lFile)
			break
		end
	end
end
fclose(fid);
X=X(1:nX,:);
if nDskipped>0
	warning('%d datapoints not stored after %d stored data points (tot %d points)',nDskipped,nD,nDskipped+nD)
end
if bReadD&&nD<length(D)
	D=D(1:nD);
end
if nargout>2||bPlot||bStructOut
	% make a zigzag-line to show separate parts
	if ~bReadD||isempty(D)
		J=[];
		K=[];
		t=[];
	else
		J=reshape(repmat([X(X(:,iXDstart)>0,iXDstart);length(D)],1,2)',1,[]);
		n=ceil(length(J)/2)+1;
		K=[zeros(2,n);ones(2,n)];
		K=K(2:length(J)+1);
		if length(D)<nMaxPlot
			t=(0:length(D)-1)'/fS;
		else
			t=[];
		end
	end
	I=struct('settings',settings,'t0',t0	...
		,'t0string',datestr(t0)	...
		,'tstStart',testStart,'sTstStart',datestr(testStart)	...
		,'tstEnd',testEnd,'sTstEnd',datestr(testEnd)	...
		,'firstMeas',firstMeas	...
		,'t',t,'J',J,'K',K	...
		,'sumData',sumD(1:nSD,:)	...
		);
	if bDigOut
		digData=digData(1:nDigData);
		if bDigSep
			nBits=1+floor(log2(max(1,max(digData))));
			ii=0:nBits-1;
			digData=(bitand(digData*ones(1,nBits),repmat(round(2.^ii),nDigData,1))>0)*0.9+repmat(ii,nDigData,1);
		end
	end
end		% if nargout>2||bPlot
if bPlot&&~isempty(D)&&isempty(t)
	warning('LCDF:tooMuchToPlot','Too much data to plot (%d)',length(D))
	bPlot=false;
end
if bPlot&&~isempty(D)
	getmakefig('HALTana',true,true,'Analog HALT-measurement data')
	if ~bPlotT
		t=1:nD;
	end
	plot(t,D);grid
	minD=min(D);
	maxD=max(D);
	yText=maxD+(maxD-minD)/15;
	set(gca,'ylim',[minD,yText])
	CCC=[0 0 1;0 1 1;1 0 0;0 1 0;0 0 1;1 1 0;1 0 1;0 0 1];
	mxD=max(D);
	mnD=min(D);
	if bTest
		typPlot=false(1,60);
		typPlot([2:4 6:8]+1)=true;
		Yline=[-0.1 1.1]*(mxD-mnD)+mnD;
		for i=1:nX
			if typPlot(X(i,iXtyp)+1)
				text(t(X(i,iXDstart)),yText,datestr(t0+X(i,iXtStart),13),'verticalal','top','horizontalal','left');
				line(t(X(i,iXDstart))+[0 0],Yline,'color',CCC(X(i,iXtyp),:));
				text(t(X(i,iXDstart)),Yline(2),num2str(X(i,iXtyp)),'color',CCC(X(i,iXtyp),:));
			end;
		end
	else
		for i=1:nX
			if X(i,iXDstart);
				text(t(X(i,iXDstart)),yText,datestr(t0+X(i,iXtStart),13),'verticalal','top','horizontalal','left');
			end
		end
	end 	% if bTest
	if bDigOut&&length(digData)>100
		getmakefig('HALTdigi',true,true,'Digital HALT-measurement data')
		plot((0:nDigData-1)/100000,digData);grid
		xlabel 'time [s]'
		title 'digital data'
		ylabel 'packed bits [-]'
		mxDig=max(digData(:));
		for i=1:nX
			if X(i,1)>0&&X(i,iXiDig)>0
				line(X(i,iXiDig)*1e-5+[0 0],[0 mxDig],'color',[1 0 0])
			end
		end
	end
end		% if bPlot
idx=[X(:,iXDstart);length(D)+1];
idx(idx==0)=[];
idx(find(diff(idx)==0)+1)=[];
if bNav
	NAV=struct('data',D,'idx',idx);
	cnavmsrs(NAV,[],'kanx',1/fS)
	if bMarker
		if isfield(settings,'Npre')
			nPre=settings.Npre;
			Vth=settings.VStartFlt;
		elseif isfield(settings,'preTrigger')
			nPre=settings.preTrigger;
			Vth=settings.upThr;
		end
		tPre=nPre/fS;
		line([0 tPre*2],[0 0]+Vth,'color',[0 1 0],'tag','marker');
		line([0 0]+tPre,[0 Vth*2],'color',[1 0 0],'tag','marker')
	end
end
if bStructOut
	if bTest
		error('!struct output only works without test-output!')
	end
	dX={'tStart',num2cell(X(:,iXtStart));	...
		'tEnd',num2cell(X(:,iXtEnd));	...
		'dt',num2cell(X(:,iXtEnd)-X(:,iXtStart));	...
		'D',num2cell(X(:,iXDstart));	...
		}';
	if bReadD
		dX(:,end+1:end+6)={'vMax',num2cell(X(:,iXvMax));	...
			'vMean',num2cell(X(:,iXvMean));	...
			'vMedian',num2cell(X(:,iXvMedian));	...
			'vMin',num2cell(X(:,iXvMin));	...
			'vMin10',num2cell(X(:,iXvMin10));	...
			'vMax10',num2cell(X(:,iXvMax10));	...
			}';
	end
	for i=1:nX
		if idx(i+1)-idx(i)>1
			dX{2,4}{i}=D(idx(i):idx(i+1)-1);
		end
	end
	X=struct(dX{:});
	if nargout>1
		D=I;
	end
end

function [t,t0,tlv]=readtime(fid,t0)
tlv=lvtime([],fid);
if isempty(t0)
	t0=tlv;
end
t=tlv-t0;
