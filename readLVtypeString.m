function varargout=readLVtypeString(x,data,varargin)
%readLVtypeString - reads the type string of flattened lv-data
%     T=readLVtypeString(x)
%          used to read in a recursive way a full type description
% further use:
%     [D,T]=readLVtypeString(x,data)
%     [D,T]=readLVtypeString(T,data)
%          does the conversion of data, using the type definition in x
%       x can be the raw type data or the result of this function
%     T=readLVtypeString(Dtdms)
%       Reads settings from a TDMS file with type and data of a flattened
%       structure.
%
%   see also lvData2struct

% some additions were done to allow the output of enum-values, but this is
% not OK.  It's done via an additional output, but why not in type-field?
%             --> type is used for typecast!

% dubbel werk variant <-> normaal ?

% data conversions done on different locations (not via ConverData)

persistent DtypeList

if isempty(DtypeList)
	%!!!!!!enum ---> niet juist gelezen
	DtypeList={'Byte Integer','01','int8',1;
		'Word Integer','02','int16',2;
		'Long Integer','03','int32',4;
		'Signed I64','04','int64',8;
		'Unsigned Byte Integer','05','uint8',1;
		'Unsigned Word Integer','06','uint16',2;
		'Unsigned Long Integer','07','uint32',4;
		'Unsigned I64','08','uint64',8;
		'Fixed Point','5F',-1,8;
		'Single-Precision Floating-Point Number','09','single',4;
		'Double-Precision Floating-Point Number','0A','double',8;
		'Extended-Precision Floating-Point Number','0B','extended',16;
		'Single-Precision Complex Floating-Point Number','0C','CSG',8;
		'Double-Precision Complex Floating-Point Number','0D','CDB',16;
		'Extended-Precision Complex Floating-Point Number','0E','CXT',32;
		'Enumerated Byte Integer','15','uint8',1;
		'Enumerated Word Integer','16','uint16',2;
		'Enumerated Long Integer','17','uint32',4;
		'Single-Precision Physical Quantity','19',-1,4;
		'Double-Precision Physical Quantity','1A',-1,8;
		'Extended-Precision Physical Quantity','1B',-1,10;
		'Single-Precision Complex Physical Quantity','1C',-1,8;
		'Double-Precision Complex Physical Quantity','1D',-1,16;
		'Extended-Precision Complex Physical Quantity','1E',-1,32;
		'Boolean','21','int8',1;
		'String','30',0,-1;
		'Path','32',0,-1;
		'Pict','33',0,-1;
		'PhysChan','37',0,-1;	% of array
		'Array','40',0,-1;
		'Cluster','50',0,0;
		'Variant','53',0,0;
		'LVtime','54',0,16;
		'VISA','70',0,-1;
		};
	for iD=1:size(DtypeList,1)
		DtypeList{iD,2}=sscanf(DtypeList{iD,2},'%x');
	end
end

[~,~,E] = computer;
bSwapBytes = E=='L';	% not used everywhere!!!!
extra = [];	% keep this???
hBytes = [1 cumprod(256+zeros(1,8))];
TnBytes = {'int8','uint8';'int16','uint16';0,0;'int32','uint32';
	0,0;0,0;0,0;'int64','uint64'};

if iscell(x)
	T=x;
	[bAll]=false;
	[bStruct]=false;
	[bFast]=false;
	if ~isempty(varargin)
		setoptions({'bAll','bStruct','bFast'},varargin{:})
	end
	if bFast
		D=ConvertDataFast(T,data);
		varargout={D,T};
		return
	end
	[D,id]=ConvertData(T,data);
	if bAll
		if islogical(bAll)||bAll>0
			% unknown number
			nD=-1;
		else
			nD=-bAll;
		end
		if all(cellfun(@isnumeric,T(:,3))) %fixed length
			if nD<0
				B=cat(2,T{:,3});
				if any(B<0)	% is this right? is this possible?
					error('This doesn''t work with variable length data')
				end
				sB=sum(B);	% (sum(B) should be equal to id-1
				nD=length(data)/sB;
				if nD>floor(nD)
					warning('READLVTYPE:NotFullData','Problem converting all data')
					nD=floor(nD);
				end
			end
			D=D(:,[2 ones(1,nD)]);
			for iD=2:nD
				[D1,id]=ConvertData(T,data((iD-1)*sB+1:iD*sB));
				% check on id? (otherwise id can be removed)
				D(:,iD+1)=D1(:,1);
			end
		else	% variable length structures
			nDest = round(length(data)/(id-1));
			D = D(:,[2 ones(1,nDest)]);
			nD = 1;
			while id<length(data)
				[D1,id] = ConvertData(T,data,id);
				nD = nD+1;
				D(:,nD+1) = D1(:,1);
			end
			if nD<size(D,2)-1
				D = D(:,1:nD+1);
			end
		end
		if bStruct
			DD=D(:,1:2)';
			for iD=1:size(DD,2)
				DD{2,iD}=D(iD,2:end);
			end
			D=struct(DD{:});
		end
	elseif bStruct
		D=lvData2struct(D);
	end
	O={D,T,id};
	varargout=O(1:nargout);
	return
elseif isstruct(x)
	if all(cellfun(@(x) ismember(x,{'group','properties','version'}),fieldnames(x)))
		% supposed to be a (structured) "leesTDMS-struct"
		% a group with settings is searched
		D=[];
		fcnVARchannels = @(x) ismember(x,{'type','data'});
		for iG=1:length(x.group)
			if sum(cellfun(fcnVARchannels,{x.group(iG).channel.name}))==2
				Dg=readLVtypeString(x.group(iG));
				if isempty(D)	% first set
					D=Dg;
				elseif isstruct(D)	% second set
					D={D,Dg}; %#ok<AGROW>
				else
					D{end+1}=Dg; %#ok<AGROW>
				end
			end
		end
		if isempty(D)
			warning('No settings found!')
		end
		varargout={D};
		return
	elseif all(cellfun(@(f) ismember(f,fieldnames(x)),{'name','properties','channel'}))
		% supposed to be a group of a leesTDMS-struct
		C={x.channel.name};
		Btype=strcmp(C,'type');
		Bdata=strcmp(C,'data');
		if ~any(Btype)||~any(Bdata)
			error('Not the right channels')
		end
		if ~isa(x.channel(Btype).data,'int16')	...
				||~isa(x.channel(Bdata).data,'uint8')
			error('Channels don''t have the right type')
		end
		D=lvData2struct(readLVtypeString(x.channel(Btype).data,x.channel(Bdata).data));
		varargout={D};
		return
	else
		error('Unknown type of structure')
	end
end

[bFlatten]=true;
[bDTLG]=false;
if nargin<2
	data=[];
	options=[];
elseif ischar(data)
	options=[{data},varargin];
	data=[];
elseif iscell(data)
	options=data;
else
	options=varargin;
end

if ~isempty(options)
	setoptions({'bFlatten','bDTLG'},options{:})
end

if isa(x,'uint8')
	if rem(length(x),2)
		x(end+1) = uint8(0);
	end
	x = typecast(x,'uint16');
	if bSwapBytes
		x = swapbytes(x);
	end
end
if length(x)~=ceil(x(1)/2)
	warning('READLVTYPE:wrongLength','length of data different from specified length?')
end
if ~isa(x,'double')
	x=double(x);	%(!)bitand doesn't exist for int's...
end
if any(x<0)
	x(x<0)=x(x<0)+65536;
end

bName=bitand(x(2),16384)>0;	% guessed!
name='';
iTyp=bitand(x(2),255);
jTyp=find(iTyp==cat(1,DtypeList{:,2}));
if isempty(jTyp)
	if iTyp==0	% empty(?)
		T={0,'empty',[]};
	else
		error('unknown type (%d - 0x%02x)',iTyp,iTyp)
	end
elseif ischar(DtypeList{jTyp,3})	% simple type
	ix=3;
	if strncmpi(DtypeList{jTyp,3},'int',3)
		iT=11;
	elseif strncmpi(DtypeList{jTyp,3},'uint',4)
		iT=12;
	elseif strcmpi(DtypeList{jTyp,3},'double')
		iT=13;
	elseif strcmpi(DtypeList{jTyp,3},'single')
		iT=10;
	elseif strcmpi(DtypeList{jTyp,3},'extended')
		iT=14;
	elseif strcmpi(DtypeList{jTyp,3},'CSG')
		iT=17;
	elseif strcmpi(DtypeList{jTyp,3},'CDB')
		iT=18;
	elseif strcmpi(DtypeList{jTyp,3},'CXT')
		iT=19;
	else
		iT=15;
		warning('READLVTYPE:unknownType','Unknown type!')
	end
	T={iT,DtypeList{jTyp,3},DtypeList{jTyp,4}};
	if DtypeList{jTyp,2}>=21&&DtypeList{jTyp,2}<=23
		%!!!! kan name in fractie van x-woorden komen????
		nVals=x(ix);
		ix=ix+1;
		dV=typecast(swapbytes(uint16(x(ix:end))),'uint8')';
		vals=cell(1,nVals);	% wat mee doen?
		id=1;
		for iV=1:nVals
			vals{iV}=char(dV(id+1:id+dV(id)));
			id=id+1+dV(id);
		end
		id=id-1;
		ix=ix+ceil(id/2);
		extra = struct('type',T{2},'enum',{vals});
		T{2} = extra;
	end
else
	switch iTyp
		case 26		% double precision physical quantity
			%to be checked!!!!
			T=[{13},DtypeList(jTyp,[1 4])];
			nU=x(3);
			U=x(4:3+nU*2);
			ix=4+nU*2;
			extra = struct('type',T{2},'unit',U);
			T{2} = extra;
		case {48,51}	% string, pict
			%?check for "-1"-size?
			T={20,DtypeList{jTyp,1},-1};
			ix=5;
		case 50	% path
			T={21,DtypeList{jTyp,1},-1};
			ix=5;
		case 55	% physical channel
			a1=[65536 1]*x(3:4);
			a2=x(5);
			ix=6;
			T={20,'channel',-1};	%%%%%!!!!!!!!!!!!
			extra = struct('physChan_a1',a1,'physChan_a2',a2);
		case 64	% array
			nDimsM=x(3);
			ix=4+nDimsM*2;
			dimsA=[65536 1]*reshape(x(4:ix-1),2,[]);
			if bDTLG
				T2=x(ix);
				ixn=ix+1;
			else
				ixn=ix+ceil((x(ix)-1)/2);
				T2=readLVtypeString(x(ix:ixn-1),'bFlatten',false);
			end
			T={30,'array',struct('dims',dimsA,'T',{T2})};
			ix=ixn;
		case 80	% cluster
			nEl=x(3);
			ix=4;
			if bDTLG
				T2=x(ix:ix+nEl-1);
				ix=ix+nEl;
			else
				T2=cell(nEl,4);
				for iEl=1:nEl
					ixn=ix+ceil(x(ix)/2);
					T2(iEl,:)=readLVtypeString(x(ix:ixn-1),'bFlatten',false);
					ix=ixn;
				end
			end
			T={40,'cluster',T2};
		case 83	% variant (?)
			T={43,'variant',[]};
			ix=3;%!!!!!!!!
		case 84	% lvtime
			if bDTLG
				%nEl=x(3);	%??!!??
				nEl=1;
				ix=4;
				T2=cell(nEl,4);
				for iEl=1:nEl
					ixn=ix+ceil(x(ix)/2);
					T2(iEl,:)=readLVtypeString(x(ix:ixn-1),'bFlatten',false);
					ix=ixn;
				end
				T={40,'cluster',T2};
			else
				T={50,'lvtime',16};
				ix=15;	% ?!!!? wat zit er nog meer van informatie in?
			end
		case 95	% Fixed Point
			ix=3;
			ixe=18;
			iT=16;
			bSigned=bitand(x(ix),uint16(16384))~=0;
			bOverflowBit=bitand(x(ix),uint16(8))~=0;
			if bitand(x(ix),uint16(49143))~=4355
				warning('Different FXP-bits as expected!')
			end
			ix=ix+1;
			nBits=swapbytes(uint16(x(ix)));
			nInt=typecast(swapbytes(uint16(x(ix+1:ix+2))),'int32');
			ix=ix+3;
			FXPlen=8+bOverflowBit;
			dd=typecast(swapbytes(uint16(x(ix:ixe))),'double');
				% (!)this data is stored separately, but can be extracted
				% from nBits and nInt (and bSigned)
			
			T={iT,struct('nBits',nBits, 'nInt',nInt	...
					,'bSigned',bSigned,'bOverflowBit',bOverflowBit	...
					,'xMin',dd(1),'xMax',dd(2),'dx',dd(3))	...
				,FXPlen};
			ix=ixe+1;
		case 112	% VISA and others?
			s=sprintf('%04x',x(4:min(end,6)));
			s8=sscanf(s,'%02x');
			switch x(3)
				case 14		% VISA
					T={20,DtypeList{jTyp,1},-1};
					if s8(1)~=5 || ~strcmp(char(s8(2:end)'),'Instr')
						error('Unexpected fault - due to simple guess about VISA-type')
					end
					ix=7;
				case 24		% .NET
					d1=x(4);	% ???
					s=sprintf('%04x',x(5:end));
					dN=sscanf(s,'%02x');
					ix=1+dN(1);
					s1=char(dN(2:1+dN(1))');
					dN(1:1+dN(1))=[];
					s2=char(dN(2:1+dN(1))');
					ix=ix+dN(1)+1;
					ix=5+ceil((ix-1)/2);
					T={11,'Long Integer',4};	%!!!!!???????
				otherwise
					error('Unknown VISA and others types...')
			end
		otherwise
			error('unknown type (%d)!',iTyp)
	end
end
if bName
	%typecast(swapbytes(uint16(x(ix:end))),'uint8')
	s=sprintf('%04x',x(ix:end));
	dN=sscanf(s,'%02x');
	name=char(dN(2:1+dN(1))');
	ix = ix+1+floor(dN(1)/2);
end
T{1,4}=name;

if bFlatten
	% remove clusters - replace by separate data
	iT=1;
	while iT<=size(T,1)
		if T{iT}==40
			Tr=T(iT+1:end,:);
			i1=iT+size(T{iT,3},1);
			T(iT:i1-1,:)=T{iT,3};
			T(i1:i1-1+size(Tr,1),:)=Tr;
		else
			iT=iT+1;
		end
	end
end
if isempty(data)
	varargout={T};
	if nargout>1
		varargout{2} = extra;
		varargout{3} = ix;
	end
else
	[D,id]=ConvertData(T,data);
	varargout={D};
	if id<length(data)
		if nargout>2
			varargout{3}=id;
		else
			warning('READLV:notAllDataUsed','Not all data was used!')
		end
	end
	if nargout>1
		varargout{2}=T;
	end
	return
end

	function [D,id]=ConvertData(T,data,id)
		data=data(:);
		D=cell(size(T,1),2);
		if nargin<3 || isempty(id)
			id=1;
		end
		for i=1:size(T,1)
			nb=T{i,3};
			iT=T{i};
			if iT==0	% empty
				d=[];
			elseif iT<20
				if iT==11||iT==12
					if false
						d = typecast(data(id:id-1+nb),TnBytes{nb,iT-10});
						if bSwapBytes && nb>1
							d=swapbytes(d);
						end
					else
						d = hBytes(nb:-1:1)*double(data(id:id-1+nb));
						if iT==11
							if d>hBytes(nb+1)/2
								d=d-hBytes(nb+1);
							end
						end
					end
				elseif iT==10	% single
					d=typecast(uint8(data(id:id+3)),'single');
					if bSwapBytes
						d=swapbytes(d);
					end
				elseif iT==13
					%d=todouble(data(id:id+7),1);
					d=typecast(uint8(data(id:id+7)),'double');
					if bSwapBytes
						d=swapbytes(d);
					end
				elseif iT==14	% extended
					d=ConvertExt2Dbl(data(id:id+9),bSwapBytes);
				elseif iT==16	% fixed point data
					Ti=T{i,2};
					if Ti.bOverflowBit&&data(id+8)
						d=Inf;	% or negative?
						if Ti.bSigned
							if data(id)>127
								d=-d;
							end
						elseif all(data(id:id+7)==0)
							d=-d;
						end
					else
						d=hBytes(8:-1:1)*double(data(id:id+7));
						if Ti.bSigned
							if d>hBytes(nb+1)/2
								d=d-hBytes(nb+1);
							end
						end
						%d=d/2^(double(Ti.nBits)-double(Ti.nInt));
						d=d*Ti.dx;
					end
				elseif iT==17	% single point precision complex
					d=typecast(uint8(data(id:id+7)),'single');
					if bSwapBytes
						d=swapbytes(d);
					end
					d=d(1)+1i*d(2);
				elseif iT==18	% double point precision complex
					d=typecast(uint8(data(id:id+15)),'double');
					if bSwapBytes
						d=swapbytes(d);
					end
					d=d(1)+1i*d(2);
				elseif iT==19	% extended point precision complex
					d1=ConvertExt2Dbl(data(id   :id+ 9),bSwapBytes);
					d2=ConvertExt2Dbl(data(id+16:id+25),bSwapBytes);
					d=d1+1i*d2;
				else
					error('Not yet implemented simple type!')
				end
				id=id+nb;
			elseif iT==20	% strings
				len=hBytes([4 3 2 1])*double(data(id:id+3));
				if id+len-1>length(data)
					error('Problem with reading string - length too large')
				end
				id=id+4;
				d=char(data(id:id+len-1)');
				id=id+len;
			elseif iT==21	% path
				if ~strcmp(char(data(id:id+3)'),'PTH0')
					error('Wrong expectation about path-data')
				end
				len=hBytes([4 3 2 1])*double(data(id+4:id+7));
				if id+len-1>length(data)
					error('Problem with reading path - length too large')
				end
				id=id+8;
				d=lvpath2string(uint8(data(id:id+len-1))');
				id=id+len;
			elseif iT==30	% only simple arrays
				% variable size arrays expected
				if length(nb)>1	% ?kan dit?
					nDims=length(nb);
				else
					nDims=length(nb.dims);
				end
				id1=id+nDims*4;
				dims=hBytes([4 3 2 1])*reshape(double(data(id:id1-1)),4,nDims);
				id=id1;
				if size(nb.T,1)==1&&isnumeric(nb.T{1,3})	...
						&&ischar(nb.T{2})&&nb.T{3}>0
					id1=id+nb.T{3}*prod(dims);
					if id1<=id
						d=[];
					else
						if nb.T{1,3}==8
							d=typecast(uint8(data(id:id1-1)),'double');
							if bSwapBytes
								d=swapbytes(d);
							end
						elseif nb.T{1,3}==16	% lvtime
							d=lvtime(uint8(data(id:id1-1)));
						else
							d=ConvertSimple(uint8(data(id:id1-1)),nb.T{1,2});
							if nb.T{3}>1
								d=swapbytes(d);
							end
						end
						if length(dims)>1
							d=reshape(d,dims(end:-1:1))';
						end
						id=id1;
					end
				elseif prod(dims)==0
					d=[];
				else
					% gokwerk(!) - maar het werkt (meestal)
					for ii=1:prod(dims)
						if length(data)-id<4
							error('Something goes wrong!!!')
						end
						[d1_A,id1]=ConvertData(nb.T,data(id:end));
						if iscell(d1_A)
							if size(d1_A,1)==1&&isempty(d1_A{1,2})
								d1_A=d1_A{1};
							else
								d1_A=lvData2struct(d1_A);
							end
						end
						if ischar(d1_A)
							if ii==1
								if isscalar(dims)
									d=cell(1,dims);
								else
									d=cell(dims);
								end
							end
							d{ii}=d1_A;
						elseif ii==1
							if nDims>1
								d=d1_A(ones(1,dims(1)),ones(1,dims(2)));	% ?volgorde OK?
							else
								d=d1_A(ones(1,dims),1);
							end
						else
							d(ii)=d1_A; %#ok<AGROW>
						end
						id=id+id1-1;
					end
				end
			elseif iT==40
				[d,id1]=ConvertData(nb,data(id:end));
				if iscell(d)
					d=lvData2struct(d,'--bCreateArr');
				end
				id=id+id1-1;
			elseif iT==43	% !!!variant!!!
				d1=double(data(id:id+3));
				%printhex(d1)
				id=id+4;
				nn=hBytes([4 3 2 1])*double(data(id:id+3));
				if nn>1000	% this can't be true
					%id=length(data);	%!!!!!!
					id=id+hBytes([4 3 2 1])*d1-4;
					name='';
					d1=[];
					%iT1=[];
					%d2=[];
					%d3=[];
					dVal=[];
					%CC=[];
					extra=[];
				else
					CC=cell(nn,4);
					id=id+4;
					iT1=zeros(1,nn);
					extra=[];
					name='';	% ??
					for ii=1:nn
						nn1=hBytes([2 1])*double(data(id:id+1));
						if nn1<4||id+nn1-1>length(data)
							error('Unexpected length of block')
						end
						D1=double(data(id+2:id+nn1-1))';
						%fprintf('     %2d - D1:',ii);printhex(D1)
						if D1(1)~=64%&&nn1>6
							%warning('READLV:diffBlock','Different block as normal - this is a trial!!!!')
							iD1_64=find(D1==64,1);
							if isempty(iD1_64)
								%printhex(D1)
								%warning('READLV:BadTrial','Trial didn''t work out!')
							else
								%do something with skipped data?
								D1=D1(iD1_64:end);
							end
						end
						iT1(ii)=D1(2);
						jj=3;
						jT1=find(iT1(ii)==cat(1,DtypeList{:,2}));
						bSimpleValue=false;
						if iT1(ii)==0
							% do nothing (empty variant)
						elseif isempty(jT1)
							error('Error converting data?')
						elseif iT1(ii)==48||iT1(ii)==50
							lFixed=hBytes([4 3 2 1])*D1(jj:jj+3)';
							if lFixed>2^31
								lFixed=lFixed-2^32;
							end
								% lFixed kept since it might be usefull
							jj=jj+4;
							CC(ii,1:3)={20+(iT1(ii)==50),DtypeList{jT1,1},-1};	%???volgende correctie?
						elseif iT1(ii)==112
							%warning('READLVTYPESTRING:VISAunknown','Unknown - very roughly guessed!!!!!!!!')
							d1=hBytes([2 1])*D1(jj:jj+1)';
							jj=jj+2;
							switch d1
								case 14	% VISA
									if D1(jj)~=5||~strcmp(char(D1(jj+1:jj+5)),'Instr')
										error('Bad guess - VISA Instr')
									end
									jj=jj+6;
									d2=D1(jj:jj+1);
									jj=jj+2;
									d3=D1(jj:jj+d2(2)*2-1);
									jj=jj+d2(2)*2;
									d4=D1(jj:jj+19);
									jj=jj+20;
									CC(ii,1:3)={20,DtypeList{jT1,1},-1};
								case 24
									d2=D1(jj:jj+7);
									jj=jj+4;
									lFixed=hBytes([4 3 2 1])*D1(jj:jj+3)';
									jj=jj+4;
									s=char(D1(jj:jj+lFixed-1));
									jj=jj+lFixed;
									CC(ii,1:3)={11,'integer',4};
								otherwise
									%trial!!
									s1=char(D1(jj+1:jj+D1(jj)));
									jj=jj+1+D1(jj)+rem(D1(jj)+1,2);
									d2=D1(jj:jj+3);
									jj=jj+4;
									s2=char(D1(jj+1:jj+D1(jj)));
									jj=jj+1+D1(jj);
									d3=D1(jj:jj+19);
									jj=jj+20;
									%error('Unknown VISAao type (%d)',d1)
									warning('READLV:VISAao','Unknown VISAao type (%d)',d1)
									% get type from data!!!
									CC(ii,1:3)={11,'integer',4};
							end
						elseif iT1(ii)>=22&&iT1(ii)<=23
							nEnum=D1(jj)*256+D1(jj+1);
							jj=jj+2;
							sEnum=cell(1,nEnum);	% !!nog iets mee doen!!!
							for iE=1:nEnum
								sEnum{iE}=char(D1(jj+1:jj+D1(jj)));
								jj=jj+1+D1(jj);
							end
							jj=jj+1-rem(jj,2);	%!!!!
							bSimpleValue=true;
							extra=struct('sEnum',{sEnum});
						elseif iT1(ii)==55	% ??
							%D1(jj:jj+25)	----> wat?
							jj=jj+26;
							CC(ii,1:3)={20,DtypeList{jT1,1},DtypeList{jT1,4}};
						elseif iT1(ii)==64	% array
							nDims=hBytes([2 1])*D1(jj:jj+1)';
							DIMSfixed=hBytes([4 3 2 1])*reshape(D1(jj+2:jj+1+nDims*4),4,nDims);
							DIMSfixed(DIMSfixed>2^31)=-1;
							jj=jj+2+nDims*4;
							e1=hBytes([2 1])*D1(jj:jj+1)';
							jj=jj+2;
							CC(ii,1:3)={30,'array',struct('dims',DIMSfixed,'T',e1)};
						elseif iT1(ii)==80	% Cluster!
							% ?????????indices of data???
							nnn=hBytes([2 1])*D1(jj:jj+1)';
							iii=hBytes([2 1])*reshape(D1(jj+2:jj+1+nnn*2),2,nnn);
							CC(ii,1:3)={40,'cluster',iii};
							jj=jj+nnn*2+2;
						elseif iT1(ii)==84	% multi types
							typ=hBytes([2 1])*D1(jj:jj+1)';
							jj=jj+2;
							bWfrm=true;
							switch typ
								case 2	% I16-waveform
									yTyp={11,'int16',2};
								case 3	% DBL-waveform
									yTyp={13,'double',8};
								case 5	% SGL-waveform
									yTyp={13,'single',4};
								case 6	% LVtime
									CC(ii,1:3)={50,'lvtime',16};
									bWfrm=false;
								case 10	% EXT-waveform
									yTyp={13,'double',8};	%!!
								case 11	% U8-waveform
									yTyp={12,'uint8',1};
								case 12	% U16-waveform
									yTyp={12,'uint16',2};
								case 13	% U32-waveform
									yTyp={12,'uint32',4};
								case 14	% I8-waveform
									yTyp={11,'int8',1};
								case 15	% I32-waveform
									yTyp={11,'int32',4};
								case 16	% CSG-waveform
									yTyp={13,'xxx',8};	%%
								case 17	% CDT-waveform
									yTyp={13,'xxx',16};
								case 18	% CST-waveform
									yTyp={13,'csi',8};
								case 19	% I64-waveform
									yTyp={11,'int64',8};
								case 20	% U64-waveform
									yTyp={12,'uint64',8};
								otherwise
									error('Unknown type!')
							end
							if bWfrm
								% OK?
								% it seems to work but....
								T2={50,'lvtime',16,'t0';
									13,'double',8,'dt';
									30,'array',struct('dims',1,'T',{yTyp}),'Y';
									12,'uint8',1,[];	... 25 bytes???? - replace by fixed length array
									12,'uint32',4,[];	...  2- 5
									12,'uint32',4,[];	...  6- 9
									12,'uint32',4,[];	... 10-14
									12,'uint32',4,[];	... 14-17
									12,'uint32',4,[];	... 18-21
									12,'uint32',4,[];	... 22-25
									30,'array'	...
										,struct('dims',1,'T',{	...
											{20,'String',-1,'Name';	...
											43,'variant',[],'data'}})	...
										,'Attributes'	...
									};
								CC(ii,1:3)={40,'cluster',T2};
							end
						elseif ~ischar(DtypeList{jT1,3})
							error('Only for simple types')
						else
							bSimpleValue=true;
						end
						if bSimpleValue
							%warning('READLVTYPESTRING:unknown','unknown data (%d)?',iT1(ii))
							%(!)copied from above!!
							if strncmpi(DtypeList{jT1,3},'int',3)
								iT2=11;
							elseif strncmpi(DtypeList{jT1,3},'uint',4)
								iT2=12;
							elseif strcmpi(DtypeList{jT1,3},'double')
								iT2=13;
							else
								iT2=10;
							end
							CC(ii,1:3)={iT2,DtypeList{jT1,3},DtypeList{jT1,4}};
						end
						if bitand(D1(1),64)	% name
							if D1(jj)==0	% supposed to be cause by word-alignment, but this alignment info is lost in this function...
								jj=jj+1;
							end
							lName=D1(jj);
							name_V=char(D1(jj+1:jj+lName));
							CC{ii,4}=name_V;
						end
						id=id+nn1;
					end
					d2=data(id:id+3)';	% normaal is d2(4)==nn-1??
					id=id+4;
					if isempty(jT1)
						dVal=[];
					else
						T1=StructureVariant(CC,nn);
						[dVal,id1]=ConvertData(T1,data(id:end));
						if size(T1,1)>1
							dVal=lvData2struct(dVal);
						else
							%?always if one element?
							dVal=dVal{1};
						end
						id=id+id1-1;
					end
					d3=data(id:id+3)';
					if any(d3)
						warning('READLV:guess','Please check before reusing this!!! - sorry guessing stopped here!')
					end
					id=id+4;
				end
				%d=struct('d1',d1(:)','iT',iT1,'name',name,'d2',d2,'d3',d3,'dVal',{dVal},'CC',{CC},'extra',extra);
				%d=struct('d1',d1(:)','name',name,'d2',d2,'dVal',{dVal},'extra',extra);
				d=struct('name',name,'dVal',{dVal},'extra',extra);
			elseif iT==50
				d=lvtime(data(id:id+nb-1));
				id=id+nb;
			else
				error('Not yet implemented (type %d)!!',iT)
			end
			D{i,1}=d;
			D{i,2}=T{i,4};
		end
	end

	function T1=StructureVariant(CC,ii)
		T1=CC(ii,:);
		if size(CC,1)==1
			return
		end
		for i=1:length(ii)
			switch T1{i}
				case 30	% array
					if isnumeric(T1{i,3}.T)
						T1{i,3}.T=StructureVariant(CC,T1{i,3}.T+1);
					end
				case 40	% cluster
					if isnumeric(T1{i,3})
						T1{i,3}=StructureVariant(CC,T1{i,3}+1);
					end
			end
		end
	end		% StructureVariant
end		% readLVtypeString

function d=ConvertExt2Dbl(data,bSwapBytes)
%(!)not the "standard EXT" (IEEE 754) (where no implicit/hidden bit is used)
%(!!!)bSwapBytes not used correctly - based on LE-Matlab-implementation
if bSwapBytes
	zS=floor(double(data(1))/128);
	zE=rem(double(data(1)),128)*256+double(data(2));
	zM=double(typecast(uint8(data(10:-1:3)),'uint64'))/2^64+1;
else
	zS=floor(double(data(10))/128);
	zE=rem(double(data(10)),128)*256+double(data(9));
	zM=double(typecast(uint8(data(1:8)),'uint64'))/2^64+1;
end
d=(-1)^zS*zM*2^(zE-16383);
end		% function ConvertExt2Dbl

function D=ConvertDataFast(T,data)
if ~isa(data,'uint8')&&~isa(data,'int8')
	data=uint8(data);	%%%
end
Nbytes=[T{:,3}];
if any(Nbytes<0)
	error('Fast conversion can only be done with fixed data sizes!')
elseif any(Nbytes==0)
	warning('Skipping data-fields with size 0?!')
	T(Nbytes==0,:)=[];
	Nbytes(Nbytes==0,:)=[];
end
sizBlock=sum(Nbytes);
if min(size(data))==1	% vector
	if rem(length(data),sizBlock)
		error('The number of bytes must fit an integral number of blocks! - at least currently')
	end
	data=reshape(data,sizBlock,[]);
else	% array
	if sizBlock~=size(data,1)
		error('If array of data bytes, its number of rows must be equal to the block size!')
	end
end
D=zeros(size(data,2),size(T,1));
iB=0;
for i=1:size(T,1)
		% ?!!!! test bSwapBytes !!!!
	x=reshape(data(iB+Nbytes(i):-1:iB+1,:),[],1);
	iB=iB+Nbytes(i);
	switch T{i}
		case {10,11,12,13}
			D(:,i)=ConvertSimple(x,T{i,2});
		case {14,16,17,18,19}
			error('Sorry extended, fixed point, complex not implemented!')
		otherwise
			error('Sorry - data seems to be too complex to handle fast (with this simple implementation)!')
	end
end
end		% function ConvertDataFast

function v = ConvertSimple(d,typ)
if isstruct(typ)
	% if enum --> do something with values?
	typ = typ.type;
end
v = typecast(d,typ);
end		% ConvertSimple
