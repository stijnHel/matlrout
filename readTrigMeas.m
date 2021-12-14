function X=readTrigMeas(fname,varargin)
%readTrigMeas - Reads the triggered data (originally HALT data)
%   simplified version of leesCDfaultlog
%
%    X=readTrigMeas(fname[,options])

nMaxRead=1e6;
nMaxBlocks=100000;
dXsize=10000;
nMaxDig=1e6;
if nargin>1
	setoptions({'nMaxRead','nMaxBlocks','nMaxDig'}	...
		,varargin{:})
end
bBigEndian=[];

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
X=struct('typ',cell(1,min(nMaxBlocks,100000)),'data',[]	...
	,'nData',[],'nDigData',[]	...
	);
nX=0;
nD=0;
bElist=false(1,10);
%bElist([3 6])=true;
bElist([6])=true;
nDigData=0;
t0=[];	% "zero time" to reduce rounding errors
lenTags=zeros(1,64);	% minimum lengths on disk
lenTags([1 0 30 31]+1)=16;	% exact
lenTags([2,3,4,6,7,8]+1)=4;	% minimal
lenTags(5+1)=4;	% normally 68;
lenTags([9 20]+1)=2;
lenTags(14+1)=4;	% minimal
lenTags(21+1)=8;
while ~feof(fid)
	curfPos=ftell(fid);
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
	nX=nX+1;
	if nX>=length(X)
		X(end+dXsize).typ=[];
	end
	nD1=0;
	nDig=0;
	switch typ
		case 1	% start
			[t,t0]=readtime(fid,t0);
			data=t;
		case 0
			[t,t0]=readtime(fid,t0);
			data=t;
		case {2,3,4,6,7,8}
			nD1=fread(fid,1,'int32');
			if nD1>1e6||nD1<0
				warning('!!!!fault at location %d/%d (n=%d)!!!!',ftell(fid),lFile,nD1)
				break
			end
			if nD1>0
				if nD<nMaxRead
					if isempty(bBigEndian)
						bE=bElist(typ);
					else
						bE=bBigEndian;
					end
					if bE
						data=fread(fid,nD1,'double');
					else
						data=todouble(fread(fid,8*nD1,'*uint8'));
					end
				else
					fseek(fid,nD1*8,'cof');
					data=[];
				end
			else
				fclose(fid);
				error('Faulty program/data!!!')
			end
			nD=nD+nD1;
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
			end
			data=settings;
		case 50	% flattened cluster settings
			n=fread(fid,1,'int32');
			sTyp=fread(fid,[1 n],'int16');
			n=fread(fid,1,'int32');
			sData=fread(fid,[1 n],'uint8');
			S=readLVtypeString(sTyp,sData);
			settings=lvData2struct(S);
			data=settings;
		case 9	% digital data
			data=fread(fid,1,'uint16');
		case 14 % high speed digital data
			nDig=fread(fid,1,'int32');
			if nDig>0
				digD1=fread(fid,nDig,'uint8');
			else
				digD1=zeros(0,1);
			end
			if nDigData>nMaxDig
				data=digD1;
			else
				data=[];
			end
			nDigData=nDigData+nDig;
		case 20	% digital data2????????
			data=fread(fid,1,'uint16');
		case 21 % analog summary data
			nidx=fread(fid,1,'int32');
			idx=fread(fid,nidx,'int32');
			nad=fread(fid,1,'int32');
			ad=fread(fid,nad,'double');
			data=struct('ad',ad','idx',idx');
		case 30	% test starting time
			[t,t0,data]=readtime(fid,t0);
		case 31	% test ending time
			[t,t0,data]=readtime(fid,t0);
		case 32	% first measurement time
			[t,t0,data]=readtime(fid,t0);
		otherwise
			warning('!!!!fault at location %d/%d (typ=%d)!!!!',ftell(fid),lFile,typ)
			data=[];
			break
	end		%  switch
	X(nX).typ=typ;
	X(nX).data=data;
	X(nX).nData=nD1;
	X(nX).nDigData=nDig;
	if nX>=nMaxBlocks
		fprintf('%d blocks read, %d/%d bytes.\n',nX,curfPos,lFile);
		warning('Maximum number of blocks reached ---> stopped reading (use nMaxBlocks parameter to increase maximum number of blocks)')
		break
	end
end
fclose(fid);
X=X(1:nX);

function [t,t0,tlv]=readtime(fid,t0)
tlv=lvtime([],fid);
if isempty(t0)
	t0=tlv;
end
t=tlv-t0;
