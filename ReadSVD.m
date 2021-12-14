function D=ReadSVD(fName)
%ReadSVD  - Read SVD-file (Beckhoff logging)
%     D=ReadSVD(fName)

tScale=1e-7;

c=file(fFullPath(fName));
x=fread(c,'*uint8');
fclose(c);
I1=[1 256 65536 16777216]*double(reshape(x(1:20),4,5));
iX=20;
iXML=I1(1);
nChannels=I1(5);
XML=readxml({char(x(iXML+1:end)')},true);

% Interpretation of XML-data (rather simple!)
iChannels=find(strcmp('Acquisition',{XML.tag}));
F=[0 XML(2:end).from];
Channel=cell(1,length(iChannels));
if length(iChannels)~=nChannels
	warning('Mismatch between channel-info and data-channels!')
end
fn={};
bCompatChanneldata=true;
for i=1:length(iChannels)
	C=XML(F==iChannels(i));
	fn1={C.tag;C.data};
	if isempty(fn)
		fn=fn1(1,:);
	else
		bCompatChanneldata=bCompatChanneldata||isequal(fn,fn1(1,:));
	end
	for j=1:size(fn1,2)
		if iscell(fn1{2,j})
			if isscalar(fn1{2,j})
				fn1{2,j}=fn1{2,j}{1};
			else
				fn1{2,j}=fn1(2,j);
			end
		end
		if ischar(fn1{2,j})
			if all(fn1{2,j}>='0'&fn1{2,j}<='9')
				fn1{2,j}=str2double(fn1{2,j});
			elseif strcmp(fn1{2,j},'true')
				fn1{2,j}=true;
			elseif strcmp(fn1{2,j},'false')
				fn1{2,j}=false;
			end
		end
	end
	Channel{i}=struct(fn1{:});
end
if bCompatChanneldata
	Channel=[Channel{:}];
end

% Reading header - far from ready! ------ wrongwrongwrong!!!!
iXn=iX+20*nChannels;
I2=reshape([1 256 65536 16777216]*double(reshape(x(iX+1:iXn),4,5*nChannels)),5,nChannels)';
if I2(1)~=iXn
	warning('Data not read in header!')
end

% Read header data, block by block (given by I2)

X=[];
T=[];
if all(I2(:,3)==I2(1,3))
	B=zeros(I2(1,3),nChannels,'uint8');
	iTime=1:8;
	iData1=17:24;
	xx=reshape(25:204,12,15);
	iDtime=xx(1:4,:);
	iData=[iData1' xx(5:12,:)];
	
	SubData=struct('Tb',cell(1,nChannels),'dt',[],'I1',[],'I2',[],'Tblocks',[],'Dblocks',[]);
	v=[];
	for iCh=1:nChannels
		B(:,iCh)=x(I2(iCh,1)+1:I2(iCh,1)+I2(iCh,3));
		v1=char(B(1:11,iCh))';
		if isempty(v)
			v=v1;
		elseif ~strcmp(v,v1)
			warning('Not equal version for different channels?! ("%s" <-> "%s")',v,v1)
		end
		iB=11;
		iBn=iB+14*4;
		I_1=double(typecast(B(iB+1:iBn,iCh),'uint32'));
		iB=iBn;
		nB=I_1(9);
		SubData(iCh).Tb=[1 2^32]*tScale*reshape(I_1([1:2 5:6 7:8]),2,[]);
		SubData(iCh).dt=I_1(13)*tScale;
		iBn=iB+nB*14*4;
		I_2=reshape(double(typecast(B(iB+1:iBn,iCh),'uint32')),14,nB);
		iB=iBn;
		
		SubData(iCh).I1=I_1';
		SubData(iCh).I2=I_2;
		N=I_2(1,1:nB-1);
		nTot=sum(N);
		iBn=iB+nTot*24;
		x1=reshapetrunc(B(iB+1:iBn,iCh),24,[]);
		iB=iBn;
		% decimated data (in multiple steps)
		SubData(iCh).Tblocks=typecast(reshape(x1(1:8,:),1,[]),'uint64');
		SubData(iCh).Dblocks=reshape(typecast(reshape(x1(9:24,:),1,[]),'double'),2,[]);
		
		zz=B(iB+1:end,iCh);
		
		if rem(length(zz),204)
			warning('Data block doesn''t have the right size!?')
		end
		ZZ=reshapetrunc(zz,204,[],'-bExpand');
		Tstamps1=typecast(reshape(ZZ(iTime,:),1,[]),'uint64');
		dTstamps=reshape(typecast(reshape(ZZ(iDtime,:),[],1),'uint32'),15,[]);
		Tstamps1=bsxfun(@plus,Tstamps1,[zeros(1,size(dTstamps,2),'uint64');uint64(dTstamps)]);
		Data=typecast(reshape(ZZ(iData,:),[],1),'double');
		
		if iCh==1
			X=zeros(length(Data),nChannels);
			T=zeros(length(Data),nChannels);
		end
		X(:,iCh)=Data; %#ok<AGROW>
		T(:,iCh)=double(Tstamps1(:))*tScale; %#ok<AGROW>
	end
else
	B=cell(1,nChannels);
	T=cell(1,nChannels);
	X=cell(1,nChannels);
	iTime=1:8;
	iI3=9:16;
	
	SubData=struct('Tb',cell(1,nChannels),'dt',[],'I1',[],'I2',[]	...
		,'Tblocks',[],'Dblocks',[]	...
		,'I3',[]	...
		);
	v=[];
	for iCh=1:nChannels
		B{iCh}=x(I2(iCh,1)+1:I2(iCh,1)+I2(iCh,3));
		v1=char(B{iCh}(1:11))';
		if isempty(v)
			v=v1;
		elseif ~strcmp(v,v1)
			warning('Not equal version for different channels?! ("%s" <-> "%s")',v,v1)
		end
		iB=11;
		iBn=iB+14*4;
		I_1=double(typecast(B{iCh}(iB+1:iBn),'uint32'));
		iB=iBn;
		nB=I_1(9);
		SubData(iCh).Tb=[1 2^32]*tScale*reshape(I_1([1:2 5:6 7:8]),2,[]);
		SubData(iCh).dt=I_1(13)*tScale;
		iBn=iB+nB*14*4;
		I_2=reshape(double(typecast(B{iCh}(iB+1:iBn),'uint32')),14,nB);
		iB=iBn;
		
		SubData(iCh).I1=I_1';
		SubData(iCh).I2=I_2;
		N=I_2(1,1:nB-1);
		nTot=sum(N);
		sizBlock=8+2*Channel(iCh).VariableSize;
		iBn=iB+nTot*sizBlock;
		x1=reshape(B{iCh}(iB+1:iBn),sizBlock,[]);
		iB=iBn;
		% decimated data (in multiple steps)
		SubData(iCh).Tblocks=typecast(reshape(x1(1:8,:),1,[]),'uint64');
		switch Channel(iCh).DataType
			case 'REAL32'
				MLdType='single';
			case 'REAL64'
				MLdType='double';
			case 'INT32'
				MLdType='int32';
			case 'INT16'
				MLdType='int16';
			case 'BIT'
				MLdType='uint8';
			otherwise
				warning('data type channel #%d "%s" not implemented!',iCh,Channel(iCh).DataType)
				switch Channel(iCh).VariableSize
					case 1
						MLdType='uint8';
					case 2
						MLdType='uint16';
					case 4
						MLdType='uint32';
					case 8
						MLdType='uint64';
					otherwise
						MLdType='uint8';
				end
		end
		SubData(iCh).Dblocks=reshape(typecast(reshape(x1(9:sizBlock,:),1,[]),MLdType),2,[]);
		sizBlock=8+8+15*4+Channel(iCh).VariableSize*16;
		iData1=17:16+Channel(iCh).VariableSize;
		xx=reshape(17+Channel(iCh).VariableSize:sizBlock,4+Channel(iCh).VariableSize,15);
		iDtime=xx(1:4,:);
		iData=[iData1' xx(5:end,:)];
		
		zz=B{iCh}(iB+1:end);
		
		if rem(length(zz),sizBlock)
			warning('Data block doesn''t have the right size!?')
		end
		ZZ=reshapetrunc(zz,sizBlock,[],'-bExpand');
		Tstamps1=typecast(reshape(ZZ(iTime,:),1,[]),'uint64');
		SubData(iCh).I3=typecast(reshape(ZZ(iI3,:),1,[]),'uint64');
		dTstamps=reshape(typecast(reshape(ZZ(iDtime,:),[],1),'uint32'),15,[]);
		Tstamps1=bsxfun(@plus,Tstamps1,[zeros(1,size(dTstamps,2),'uint64');uint64(dTstamps)]);
		Data=typecast(reshape(ZZ(iData,:),[],1),MLdType);
		
		X{iCh}=Data;
		T{iCh}=double(Tstamps1(:))*tScale;
	end
end

D=var2struct(Channel,I1,I2,XML,X,T,SubData);
