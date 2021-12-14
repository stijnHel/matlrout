function [e,varargout]=leesTDM(fname,varargin)
%leesTDM  - Reads a labView TDM-file (first version)
%    [e[,...]]=leesTDM(fname[,...])
%

[fpth,fnm]=fileparts(fname);

if exist(fullfile(fpth,[fnm '.tdm']),'file')
	fullName=fullfile(fpth,fnm);
else
	fullName=zetev([],fullfile(fpth,fnm));
	if ~exist([fullName '.tdm'],'file')
		error('Can''t find the file')
	end
end
fpth=fileparts(fullName);

%% read TDM-file
%!!!!no fault detection!!!
S=readxml([fullName '.tdm']);
i=1;
while ~strcmpi(S(i).tag,'file')
	i=i+1;
end
fileData=readfields( S(i).fields,[],1);
if strcmp(fileData.byteOrder,'littleEndian')
	bLittleEndian=true;
	endianType='ieee-le';
else
	bLittleEndian=false;
	endianType='ieee-be';
end
iSFile=i;
i=i+1;
struc=struct('byteOffset',{},'id',{},'length',{},'type',{});
while S(i).from==iSFile
	if strcmp(S(i).tag,'block')
		struc=readfields(S(i).fields,struc,length(struc)+1);
		switch struc(end).valueType
			case 'eTimeUsi'
				struc(end).type=1;
			case 'eFloat64Usi'
				struc(end).type=2;
			otherwise
				warning(sprintf('!!!not known datatypa : %s!!',Sdata))
		end
	end
	i=i+1;
end	% while S(i).from
% The following is not yet used!!!
while ~strcmp(S(i).tag,'usi:data')
	i=i+1;
	if i>length(S)
		break;	%!!
	end
end
chans=struct('type',{},'id',{},'data',{});
if i<length(S)
	i=i+1;
	while i<=length(S)
		switch S(i).tag
			case {'time_sequence','double_sequence'}
				D1=readfields(S(i).fields,[],1);
				chans(end+1).type=S(i).tag;
				chans(end).id=D1.id;
				i0=i;
				i=i+1;
				while S(i).from==i0
					D1=readfields(S(i).fields,[],1);
					if isempty(chans(end).data)
						chans(end).data=D1;
					elseif ~iscell(chans(end).data)
						chans(end).data={chans(end).data,D1};
					else
						chans(end).data{end+1}=D1;
					end
					i=i+1;
				end
				i=i-1;	% will be incremented again
			case 'tdm_root'
				% read info (or skip)
				% read channel groups
				% read channels
				% ?read submatrix .... localcolumn
		end
		i=i+1;
	end
end

%% read TDX-file (data)
fid=fopen(fullfile(fpth,fileData.url),'r',endianType);
if fid<3
	error('Can''t open datafile')
end

t0=[];
if bLittleEndian
	%tFac=[2^-64 1];	% doesn't seem to work on old versions
	tFac=[2^-64 2^-32 1 2^32];
	it0=1:4;
else
	%tFac=[1 2^-64];	% doesn't seem to work on old(-mac?) versions
	tFac=[2^32 1 2^32 2^64];
	it0=[4 3 2 1];
end
nCol=length(struc);
e=zeros(max(cat(1,struc.length)),nCol);
for i=1:nCol
	fseek(fid,struc(i).byteOffset,'bof');
	switch struc(i).type
		case 1	% time data
			t1=fread(fid,[4,struc(i).length],'uint32');	% uint64 doesn't seem to work on old versions
			if length(t1)<struc(i).length
				warning(sprintf('not read enough data!! stopped reading (col %d)',i))
				break
			end
			% the following is done to avoid rounding errors
			if isempty(t0)
				t0=t1(:,1);
			end
			for j=1:3
				t1(it0(j),:)=t1(it0(j),:)-t0(j);
				b=t1(it0(j),:)<0;
				t1(it0(j),b)=t1(it0(j),b)+2^32;
				t1(it0(j)+1,b)=t1(it0(j)+1,b)-1;
			end
			e(1:struc(i).length,i)=(tFac*t1)';
		case 2	% double
			e(1:struc(i).length,i)=fread(fid,struc(i).length,'double');
		otherwise
			warning(sprintf('Unknown type of data (col %d)!!!! - not read',i))
	end
end
fclose(fid);

if nargout>1
	varargout=cell(1,nargout-1);
	if nargout>4
		varargout{4}=struct('t0',t0,'struc',struc,'xmlData',S);
	end
end

function S=readfields(F,S,iS)
if ~isstruct(S)
	S1=[];
elseif iS>length(S)
	Fn=fieldnames(S);
	eF=cell(1,length(Fn));
	Fn={Fn{:};eF{:}};
	S1=struct(Fn{:});
else
	S1=S(iS);
end
for j=1:size(F,1)
	Sdata=deblank(F{j,2});
	if all((Sdata>='0'&Sdata<='9')|Sdata=='.'|Sdata=='-')
		Sdata=str2num(Sdata);
	end
	if isempty(S1)
		S1=struct(F{j},Sdata);
	else
		S1=setfield(S1,F{j},Sdata);	% (done like this to be 5.2-conform)
	end
end
if isempty(S)
	S=S1;
else
	S(iS)=S1;
end
