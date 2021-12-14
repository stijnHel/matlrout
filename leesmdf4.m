function [e,ne,de,e2,gegs,str]=leesmdf4(f)
% leesmdf4 - Leest MDF-files (version 4)
%   [e,ne,de,e2,gegs]=leesmdf4(fName)
%    uses extractMDFstruct
%
%  This isn't robust yet.
%    It is started as "black box".  But structure is known now.  Using that
%    information is "in progress".

% First the file is read as a "generic hierarchical tree".
%           by extractMDFstruct
%   then this tree interpreted further, mainly based on BTypes in
%      ReadBlocks.  Some types of blocks are processed generically, others
%      are processed via a specific function, also indicated in BTypes.

if nargin==0
	e=struct('LNI',NotImplemented()	...
		,'LEB',ExtraBlock());
	return
end

ne=[];
de=[];
e2=[];
Dstruct=extractMDFstruct(f);

if ~strcmp(Dstruct.TP,'HD')
	error('Not starting with a HD-block!?')
end

% Interprete HD-block
HD=ReadBlock(Dstruct);

DG=HD.DG;
gegs=HD;
if length(DG)>1
	if length(DG)>2
		e=DG;
		return
	elseif size(DG(1).X,1)>size(DG(2).X,1)
		iMain=1;
	else
		iMain=2;
	end
	e2=DG(3-iMain);
	DG=DG(iMain);
end
e=DG.X;
ne=DG.nX;
str=Dstruct;

function L=NotImplemented(TP)
persistent NItypeList

if nargin==0
	L=NItypeList;
	return
end

bNew=false;
if isempty(NItypeList)
	NItypeList={TP,1};
	bNew=true;
else
	i=find(strcmp(TP,NItypeList(:,1)));
	if isempty(i)
		NItypeList{end+1,1}=TP;
		NItypeList{end  ,2}=1;
		bNew=true;
	else
		NItypeList{i,2}=NItypeList{i,2}+1;
	end
end
if bNew
	warning('LEESMDF:NItype','Not implemented type (%s)',TP)
end

function L=ExtraBlock(TP,TPchild)
persistent EClist

if nargin==0
	L=EClist;
	return
end

bNew=false;
s=[TP,'_',TPchild];
if isempty(EClist)
	EClist={s,1};
	bNew=true;
else
	i=find(strcmp(s,EClist(:,1)));
	if isempty(i)
		EClist{end+1,1}=s;
		EClist{end  ,2}=1;
		bNew=true;
	else
		EClist{i,2}=EClist{i,2}+1;
	end
end
if bNew
	warning('LEESMDF:EChild','Extra child type for %s: %s',TP,TPchild)
end

function B=InterpretDL(B)
flags=B.x(1);
rsrvd=B.x(2:4);
cnt=Convert2Num(B.x(5:8),'uint32');
if flags
	len=Convert2Num(B.x(9:16),'uint64');	% not really used (positions in file)
	B.x=struct('flags',flags,'rsrvd',rsrvd,'cnt',cnt,'len',len);
else
	nBytes=8+cnt*8;
	if nBytes~=length(B.x)
		warning('LEESMDF:DLwrongLength','Wrong length of DL-bytes?(#%d, %d<->%d) - interpretation is not done'	...
			,cnt,nBytes,length(B.x))
	else
		idx=Convert2Num(B.x(9:end),'uint64');	% not really used (positions in file)
			% only the length is used, as a check, but that can be done
			% without interpretation!
		if length(idx)~=length(B.data)
			warning('LEESMDF:DL:incoherentnrs','Different number of idx and DTBlocks? (%d<->%d)'	...
				,length(idx),length(B.data))
		end
		%B=B.data;	% only keep DTBlock-data(!!!!loosing information????!!!!)
		B.x=struct('flags',flags,'rsrvd',rsrvd,'cnt',cnt,'idx',idx);
	end
end

function [V,iXn]=Convert2Num(x,sType,iX,nV)
persistent BSwapBytes

if ischar(x)	% change source endian - this was not used?!
	if ~any('LB'==upper(x(1)))
		error('Wrong endian type')
	end
	[~,~,E]=computer;
	if BSwapBytes
		V=char(142-E);	% 'B'->'E','E'->'B'
	else
		V=E;
	end
	BSwapBytes=E~=upper(x(1));
	return
end

bTest=false;
if nargin>2
	switch sType
		case {'BYTE','UINT8'}
			nB=1;
			sType='';
			fConv=[];
		case 'CHAR'
			nB=1;
			sType='';
			fConv=@char;
		case 'INT16'
			nB=2;
		case 'UINT16'
			nB=2;
		case 'INT32'
			nB=4;
		case 'UINT32'
			nB=4;
		case 'INT64'
			nB=8;
		case 'LINK'
			nB=8;
			bTest=true;
			sType='int64';
		case 'UINT64'
			nB=8;
		case 'REAL'
			nB=8;
			sType='double';
		otherwise
			error('Unknown type (%s)!',sType)
	end
	iXn=iX+nB*nV;
	x=x(iX+1:iXn);
end

if isempty(BSwapBytes)
	[~,~,E]=computer;
	BSwapBytes=E~='L';
end
if isempty(sType)
	if isempty(fConv)
		V=x;
	else
		V=fConv(x);
	end
else
	try
		V=typecast(x,sType);
	catch err
		DispErr(err)
		warning('Error converting raw bytes to data (%s)',sType)
		V=x;
	end
end
if BSwapBytes
	V=swapbytes(V);
end
if bTest
	if any(rem(V,8))
		warning('LINK should be a multiple of 8?!')
	end
end

function X=Convert2NumberFree(data,dataTyp,nBits)
bSetByteOrder=false;
bConvert=true;
switch dataTyp
	case {0,1}	% unsigned number (LE/BE byte order)
		if nBits>8
			bSetByteOrder=true;
			if dataTyp==0
				boLast=Convert2Num('L');
			else
				boLast=Convert2Num('B');
			end
		end
		switch nBits
			case 8
				typ='uint8';
				bConvert=false;
			case 16
				typ='uint16';
			case 32
				typ='uint32';
			case 64
				typ='uint64';
			case 1
				typ='uint8';	%!!!!!!!
				bConvert=false;
			otherwise
				error('Sorry, but this number of bits is not implemented (%d)',nBits)
		end
	case {2,3}	% signed number (LE/BE byte order)
		if nBits>8
			bSetByteOrder=true;
			if dataTyp==2
				boLast=Convert2Num('L');
			else
				boLast=Convert2Num('B');
			end
		end
		switch nBits
			case 8
				typ='int8';
				bConvert=false;
			case 16
				typ='int16';
			case 32
				typ='int32';
			case 64
				typ='int64';
			otherwise
				error('Sorry, but this number of bits is not implemented (%d)',nBits)
		end
	case {4,5}	% floating point (LE / BE)
		bSetByteOrder=true;
		if dataTyp==4
			boLast=Convert2Num('L');
		else
			boLast=Convert2Num('B');
		end
		switch nBits
			case 32
				typ='single';
			case 64
				typ='double';
			otherwise
				error('Sorry, but this number of bits for FP is not implemented (%d)',nBits)
		end
	otherwise
		warning('This type is not implemented (%d,%d).',dataTyp,nBits)
		bConvert=false;
		data=num2cell(data,1);
end
if bConvert
	X=Convert2Num(data(:),typ);	% !!!!all doubles?!!!
elseif nBits==1
	X=data>0;
else
	X=data;
end
if bSetByteOrder	% set back to default
	Convert2Num(boLast);
end

function B=InterpretDG(B)
if isempty(B.CG)||isempty(B.data)
	error('Group without channel-info or data?!')
end
nX={B.CG.CN.name};
%!!!!This should be "Cleaned up"!
data=B.data;
if iscell(data)	% OK??
	data=[data{:}];
	if isstruct(data)
		data=[data.data];
	end
else
	if isstruct(data)
		if strcmp(data(1).TP,'DL')
			if length(data)>1
				warning('Sorry, multiple DL-blocks are not foreseen!!! only one block is used')
				data=data(1);
			end
			data=data.data;
		end
		if strcmp(data(1).TP,'DT')	% expecting all the same...
			data=[data.x];
		else
			warning('data type %s is not implemented!',data.TP)
			data=data.x;
		end
	end
end
nPts=double(B.CG.x.cyc_cnt);
nBytesData=double(B.CG.x.data_bytes);
nBytesExtra=double(B.CG.x.inval_bytes);	% never seen!!!
nBytesTot=nBytesData+nBytesExtra;
chInfo=[B.CG.CN.x];
dataTyp=[chInfo.data_typ];
nBits=[chInfo.bit_cnt];
if all(nBits==nBits(1)&dataTyp==dataTyp(1))
	X=Convert2NumberFree(data,dataTyp(1),nBits(1));
	if rem(length(X),length(nX))
		warning('Number of elements is not an integral number of number of channels!')
	else
		X=reshape(X,length(nX),[])';	% !!!!all doubles?!!!
	end
else
	if length(data)~=nBytesTot*nPts
		warning('Unexpected number of databytes!')
	end
	if any(rem(nBits,8))&&false
		fprintf('    nBits: %d',nBits(1))
		if length(nBits)>1
			fprintf(',%d',nBits(2:end));
		end
		fprintf('\n')
		warning('Sorry, fractional bytes are not robustly implemented!')
	end
	data=reshape(data,nBytesTot,[]);
	X=zeros(nPts,length(nX));
	iX=0;
	iBit=0;
	for i=1:length(nX)
		if nBits(i)<8
			iXn=iX;
			data_i=bitand(data(iX+1,:),2^iBit);
			iBit=iBit+1;
			if iBit>7
				iXn=iX+1;
				iBit=0;
			end
		else
			iXn=iX+nBits(i)/8;
			iBit=0;
			data_i=data(iX+1:iXn,:);
		end
		Xi=Convert2NumberFree(data_i,dataTyp(i),nBits(i));
		if isnumeric(X)&&iscell(Xi)
			X=num2cell(X);
		end
		X(:,i)=Xi;
		iX=iXn;
	end
end
B=struct('nX',{nX},'X',{X},'CG',B.CG);

function B=GetText(B)
% Only keep the text-field(!)
if isempty(B.x)
	B='';
elseif B.x(end)~=0
	warning('LEESMDF:non0termText','Text not terminated with a zero.')
	B=char(B.x);
else
	B=deblank(char(B.x(1:end-1)));
end

function B=GetXML(B)
B=GetText(B);
% Do something with the XML-string? (or at least test it?)

function D=CombineBlocks(D,D1)
%Combine data
%If structs, make a struct vector, if necessary with addition of missing fields
if isstruct(D)&&isstruct(D1)
	fn=fieldnames(D);
	fn1=fieldnames(D1);
	if ~isequal(fn,fn1)
		% add fields in D
		df=setdiff(fn1,fn);
		for i=1:length(df)
			D(1).(df{i})=[];
		end
		% add fields in D1
		df=setdiff(fn,fn1);
		for i=1:length(df)
			D1(1).(df{i})=[];
		end
	end
	D=[D D1];
elseif iscell(D)
	D=[D D1];
elseif iscell(D1)
	D=[{D} D1];
else
	D={D,D1};
end

function block=ExtractData(x,dataAnal)
fn=fieldnames(dataAnal);
block=dataAnal;
iX=0;
for i=1:length(fn)
	tp=dataAnal.(fn{i});
	if iscell(tp)
		n=tp{2};
		tp=tp{1};
	else
		n=1;
	end
	if ischar(n)
		n=block.(n);	%?!not yet used!!
	end
	[x1,iXn]=Convert2Num(x,tp,iX,n);
	block.(fn{i})=x1;
	iX=iXn;
end
if iX<length(x)
	warning('Not all data processed?!')
end

function block=ReadBlock(D)

% probably better to read list not recursively but as a loop in this
% function!

TP=D.TP;
%BTypes: block types
%     {type,list possible,children-types,analysis function}
%          children-types:
%              if cell-vector of char's ==> just in general for children
%              if struct --> fields with possible types
%                 this conflicts a bit with the "list"-option!
%                 it's also not really used properly.
%          anaylisis function
%               or a functionhandle
BTypes={'HD',false,struct('DG','DG','FH','FH','CH','CH','AT','AT','EV','EV','comment',{{'TX','MD'}})	...
		,struct('start_time_ns','UINT64','tz_off_min','INT16'	...
			,'dst_off_min','INT16','time_flgs','UINT8','time_class','UINT8'	...
			,'flags','UINT8','reserved','BYTE','start_angle_rad','REAL'	...
			,'start_dist_m','REAL');
	'DG',true ,struct('next','DG','CG','CG','data',{{'DT','DZ','DL','HL'}},'comment',{{'TX','MD'}})	...
		,@InterpretDG;
	'CG',true ,struct('next','CG','CN','CN','acq_name','TX','acq_src','SI','SR','SR','comment',{{'TX','MD'}})	...
		,struct('record_id','UINT64','cyc_cnt','UINT64','flags','UINT16','pth_sep','UINT16'	...
			,'rsrvd',{{'BYTE',4}},'data_bytes','UINT32','inval_bytes','UINT32');
	'SI',false,struct('name','TX','path','TX','comment',{{'TX','MD'}})	...
		,struct('type','UINT8','bus_type','UINT8','flags','UINT8','rsrvd',{{'BYTE',5}});
	'CN',true ,struct('next','CN','composition',{{'CA','CN'}},'name','TX'	...
			,'src','SI'	...
			,'conv','CC','data',{{'SD','DL','CG'}},'unit',{{'TX','MD'}}	...
			,'comment',{{'TX','MD'}},'ref','AT','default_x','DG')	...
		,struct('typ','UINT8','sync_type','UINT8','data_typ','UINT8'	...
			,'bit_offset','UINT8','byte_offset','UINT32','bit_cnt','UINT32'	...
			,'flags','UINT32','inval_bit_pos','UINT32','precision','UINT8'	...
			,'rsrvd','BYTE','attach_cnt','UINT16','val_range_min','REAL'	...
			,'val_range_max','REAL','limit_min','REAL','limit_max','REAL'	...
			,'limit_ext_min','REAL','limit_ext_max','REAL');
	'DL',true,struct('next','DL','data',{{'DT','SD','RD','DZ'}}),@InterpretDL;
	'DT',true ,{},[];
	'TX',false,{},@GetText;
	'MD',false,{},@GetXML;
	'RD',false,{},[];
	'CC',false,{'TX','MD'},[];
	'FH',true,struct('next','FH','comment','MD')	...
		,struct('time_ms','UINT64','tz_off_min','INT16','dst_off_min','INT16'	...
			,'time_flags','UINT8','reserved',{{'BYTE',3}});
	'EV',true,{'TX','MD'},[];
	'SR',true,struct('next','SR','data',{{'RD','DZ','DL','HL'}})	...
		,struct('cycCount','UINT64','interval','REAL'	...
			,'syncTyp','UINT8','flags','UINT8','rsrvd',{{'BYTE',6}});
	};
iT=find(strcmp(BTypes(:,1),TP));
if isempty(iT)
	NotImplemented(TP);
	block=D;	% ?!!!
	return
elseif isstruct(BTypes{iT,3})
	fn=fieldnames(BTypes{iT,3});
	bCHILDtyp=true;
else
	bCHILDtyp=false;
end

block=struct('TP',TP,'x',D.x);
for iD=1:length(D.D)
	if isempty(D.D{iD})
		if bCHILDtyp
			block.(fn{iD})=[];
		end
	else
		if iD==1&&BTypes{iT,2}&&strcmp(TP,D.D{iD}.TP)
			% leave for list at the end
		else
			if bCHILDtyp
				bC=strcmp(D.D{iD}.TP,BTypes{iT,3}.(fn{min(end,iD)}));
				if ~any(bC)
					if strcmp(D.D{iD}.TP,'loop!')
						% do something?
					else
						warning('Unexpected field in known type (%s #%d %s)'	...
							,TP,iD,D.D{iD}.TP)
					end
				end
			else
				bC=strcmp(D.D{iD}.TP,BTypes{iT,3});
			end
			if ~any(bC)
				if strcmp(D.D{iD}.TP,'loop!')	% recursive loop in reading
					%do something?
				else
					ExtraBlock(TP,D.D{iD}.TP)
				end
			elseif bCHILDtyp
				D1=ReadBlock(D.D{iD});
				if iD>length(fn)
					block.(fn{end})(1,end+1)=D1;
				else
					block.(fn{iD})=D1;
				end
			else
				BL=ReadBlock(D.D{iD});
				if isfield(block,D.D{iD}.TP)	% !multiple blocks!
					block.(D.D{iD}.TP)=CombineBlocks(block.(D.D{iD}.TP),BL);
				else
					block.(D.D{iD}.TP)=BL;
				end
			end
		end		% no block for the list
	end		% ~isempty child
end		% for iD
if ~isempty(BTypes{iT,4})
	dataAnal=BTypes{iT,4};
	if isstruct(dataAnal)
		block.x=ExtractData(D.x,dataAnal);
	elseif isa(dataAnal,'function_handle')
		block=dataAnal(block);
	else
		error('Error in type-definition!!!')
	end
end

if BTypes{iT,2}&&~isempty(D.D)	% list
	%?only check the first element?
	if ~isempty(D.D{1})
		if strcmp(D.D{1}.TP,TP)
			nextBlocks=ReadBlock(D.D{1});
			block=CombineBlocks(block,nextBlocks);
		else
			warning('LEESMDF:Not1stNext','List but not the right element on the first place! (%s)',TP)
		end
	end
end
