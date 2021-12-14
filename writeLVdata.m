function Xout=writeLVdata(T,D,fid)
%writeLVdata - write labView data using structure
%    Xout=writeLVdata(T,D,fid)

if nargin<3
	fid=0;
end
if isstruct(D)
	if numel(D)>1
		% do it simple!!
		if fid==0
			X=cell(size(D));
		end
		for i=1:numel(D)
			X1=writeLVdata(T,D(1),fid);
			if fid==0
				X{i}=X1;
			else
				fwrite(fid,X1);
			end
		end
		if nargout
			Xout=X;
		end
		return
	end
	fn=fieldnames(D);
	Dc=cell(length(fn),1);
	for i=1:length(fn)
		Dc{i}=D.(fn{i});
	end
	D=Dc;
end
data=uint8(zeros(1000,1));	% gefundeerde keuze?
B=typecast(uint16(1),'uint8');	% ?beter werken met:
%            [a1,a2,endian]=computer;
id=1;
h=[1 cumprod(256+zeros(1,8))];
for i=1:size(T,1)
	nb=T{i,3};
	iT=T{i};
	dV=D{i};
	if iT<20
		if iT==11||iT==12
			bNeg=dV<0;
			dV=abs(dV);
			if iT==11
				if bNeg
					dV=dV+h(nb+1);
				end
			end
			if nb==1
				d=uint8(dV);
			elseif nb==2
				d=typecast(uint16(dV),'uint8');
			elseif nb==4
				d=typecast(uint32(dV),'uint8');
			elseif nb==8
				d=typecast(uint64(dV),'uint8');
			else
				error('Unknown type')
			end
			if B(1)
				d=d(nb:-1:1);
			end
		elseif iT==13
			d=writeDOUBLE(dV,B);
		end
		data(id:id+nb-1)=d;
		id=id+nb;
	elseif iT==20	% strings
		len=length(dV);
		data(id:id+3)=writeINT32(len,B);
		id=id+4;
		data(id:id+len-1)=uint8(dV);
		id=id+len;
	elseif iT==21	% path
		error 'niet klaar'
		if ~strcmp(char(data(id:id+3)'),'PTH0')
			error('Wrong expectation about path-data')
		end
		len=h([4 3 2 1])*data(id+4:id+7);
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
		if nDims==1
			dims=length(dV);
		else
			dims=size(dV);
		end
		id1=id+nDims*4;
		data(id:id1-1)=writeINT32(dims,B);
		id=id1;
		if size(nb.T,1)==1&&isnumeric(nb.T{1,3})&&nb.T{1,3}==8
			id1=id+nb.T{3}*prod(dims);
			if length(dims)>1
				dV=reshape(dV',dims(end:-1:1));
			end
			data(id:id1-1)=writeDOUBLE(dV,B);
			id=id1;
		else
			% gokwerk(!) - maar het werkt (meestal)
			for ii=1:prod(dims)
				d1=writeLVdata(nb.T,dV(ii),0);
				id1=id+length(d1);
				data(id:id1-1)=d1;
				id=id1;
			end
		end
	elseif iT==40
		d1=writeLVdata(nb,dV,0);
		id1=id+length(d1);
		data(id:id1-1)=d1;
		id=id1;
	elseif iT==50
		if nb~=16
			warning('WLV:lvtimeLen','unexpected lvtime-length (%d)!',nb)
		end
		data(id:id+15)=uint8(dV);
		id=id+nb;
	else
		error('Not yet implemented (type %d)!!',iT)
	end
end
data=data(1:id-1);
if fid
	fwrite(fid,id-1,'uint32');
	fwrite(fid,data);
else
	Xout=data;
end

function d4=writeINT32(v,B)
d4=typecast(int32(v(:)),'uint8');
if B(1)
	d4=reshape(d4,4,[]);
	d4=d4([4 3 2 1],:);
	d4=d4(:);
end

function d8=writeDOUBLE(v,B)
d8=typecast(double(v(:)),'uint8');
if B(1)
	d8=reshape(d8,8,[]);
	d8=d8(8:-1:1,:);
	d8=d8(:);
end
