function Xd=ConvertRaw2Array(X,TP)
%ConvertRaw2Array - Convert raw (uint8) data to numeric array
%     Xd=ConvertRaw2Array(X,TP)
%           TP: cell vector with (char) datatype per element (or multiple)
%               TP{<i>} = 'int<nn>','double','single'... <nn> n-bits
%                         '<nn><type>' ... <nn> n vars of type

if ~isa(X,'uint8')
	if any(X(:)<0)||any(X(:)>255)||any(X(:)>floor(X(:)))
		error('bytes are expected for input X!')
	end
	X=uint8(X);
end

N=ones(1,length(TP));
NB=zeros(1,length(TP));
for i=1:length(TP)
	if TP{i}(1)>='0'&&TP{i}(1)<='9'
		[n,~,~,iN]=sscanf(TP{i},'%d',1);
		N(i)=n;
		TP{i}=TP{i}(iN:end);
	end
	TP{i}=strtrim(TP{i});
	switch lower(TP{i})
		case 'int8'
			nb=1;
		case 'uint8'
			nb=1;
		case 'int16'
			nb=2;
		case 'uint16'
			nb=2;
		case 'int32'
			nb=4;
		case 'uint32'
			nb=4;
		case 'int64'
			nb=8;
		case 'uint64'
			nb=8;
		case 'single'
			nb=4;
		case 'double'
			nb=8;
		otherwise
			error('Unknown type (%s)',TP{i})
	end
	NB(i)=nb;
end
BS=zeros(1,sum(N));
iTP=zeros(1,length(BS));	% !!!!nog in te vullen!!!!
b=1;
iV=0;
for i=1:length(TP)
	BS (iV+1:iV+N(i))=b:NB(i):b+(N(i)-1)*NB(i);
	iTP(iV+1:iV+N(i))=i;
	iV=iV+N(i);
	b=b+NB(i)*N(i);
end
b=b-1;
if min(size(X))==1
	nB=max(size(X));
	if nB>nb
		nV=nB/b;
		if nV>floor(nV)
			warning('Data is truncated!')
			nV=floor(nV);
			X=X(1:nV*b);
		end
		X=reshape(X,b,nV);
	elseif size(X,1)==1
		X=X(:);
	end
else
	[nB,nV]=size(X);
	if nB~=b
		if nB>b
			warning('Data is truncated!')
		else
			error('Number of bytes per block supplied is smaller than bytes in a block!')
		end
	end
end
Xd=zeros(nV,length(BS));
for i=1:length(BS)
	Xd(:,i)=typecast(reshape(X(BS(i):BS(i)-1+NB(iTP(i)),:),[],1),TP{iTP(i)});
end
