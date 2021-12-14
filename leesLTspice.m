function [varargout]=leesLTspice(fn,bRaw)
%leesLTspice - Reads a LTspice simulation (time-series of transient)
%     [x,nx,dx,x2,gegs]=leesLTspice(fn[,bRaw])

fid=fopen(fn);
if fid<3
	fid=fopen(zetev([],fn));
	if fid<3
		error('Can''t open the file (%s)',fn)
	else
		fn=zetev([],fn);
	end
end
varargout=cell(1,max(1,nargout));

if nargin==1
	[fpth,fnm,fext]=fileparts(fn);
	bRaw=strcmpi(fext,'.raw')||strcmpi(fext,'.fft');
end
if bRaw
	[varargout{:}]=leesLTraw(fid);
else
	[varargout{:}]=leesLTtxt(fid);
end

function [x,nx,dx,x2,gegs]=leesLTtxt(fid)
l1=fgetl(fid);
pData=ftell(fid);
icomma=[0 find(l1==','|l1==9) length(l1)+1];	% (',' is not needed)
nChan=length(icomma)-1;
nx=cell(1,nChan);
for i=1:nChan
	nx{i}=deblank(l1(icomma(i)+1:icomma(i+1)-1));
end
x=reshape(fscanf(fid,'%g'),nChan,[])';
pEnd=ftell(fid);
fclose(fid);
if nargout>2
	dx=cell(1,nChan);
	for i=1:nChan
		switch upper(nx{i}(1))
			case 'T'
				dx{i}='s';
			case 'V'
				dx{i}='V';
			case 'I'
				dx{i}='A';
			otherwise
				dx{i}='-';
		end
	end
	if nargout>3
		x2=[];
		if nargout>4
			gegs=[0,0,pData,0,0,1900,0,0,0,0,nChan-1,...
				(x(end,1)-x(1))/(size(x,1)-1),0,-1,1,-1,-1,pEnd];
		end
	end
end

function [x,nx,dx,x2,gegs]=leesLTraw(fid)

nVars=0;
nPts=0;
gegs=struct();
while true
	l=fgetl(fid);
	if isempty(l)
		fclose(fid);
		error('Fault in reading raw LT-file - empty header-line')
	end
	i=find(l==':',1);
	if isempty(i)
		fclose(fid);
		error('Fault in reading raw LT-file - no ":"')
	end
	switch lower(l(1:i-1))
		case 'title'
			gegs.title=ddeblank(l(i+1:end));
		case 'date'
			gegs.date=ddeblank(l(i+1:end));
		case 'plotname'
			gegs.plotname=ddeblank(l(i+1:end));
		case 'flags'
			gegs.flags=ddeblank(l(i+1:end));
		case 'no. variables'
			nVars=str2num(l(i+1:end));
		case 'no. points'
			nPts=str2num(l(i+1:end));
		case 'offset'
			gegs.offset=str2num(l(i+1:end));
		case 'command'
			gegs.command=ddeblank(l(i+1:end));
		case 'backannotation'
			gegs.backannotation=ddeblank(l(i+1:end));
		case 'variables'
			nx=cell(3,nVars);
			for i=1:nVars
				l=fgetl(fid);
				[nx{1,i},nD,sErr,iNxt]=sscanf(l,'%d',1);
				l=l(iNxt:end);
				[nx{2,i},nD,sErr,iNxt]=sscanf(l,'%s',1);
				l=l(iNxt:end);
				nx{3,i}=sscanf(l,'%s',1);
			end
		case 'binary'
			break	% start of binary data
		otherwise
			fclose(fid);
			error('Fault in reading raw LT-file - unknown data in header')
	end
end
if strcmp(gegs.flags,'real forward')
	nBblock=8+(nVars-1)*4;
	x=fread(fid,[nBblock nPts],'*uint8');
	if numel(x)~=nPts*nBblock
		error('Fault in reading raw LT-file - Not all data could be read')
	end
	t=typecast(reshape(x(1:8,:),[],1),'double');
	x=[t reshape(typecast(reshape(x(9:end,:),[],1),'single'),nVars-1,nPts)'];
elseif strcmp(gegs.flags,'complex forward')
	nBblock=nVars*8*2;
	x=fread(fid,[nBblock*nPts 1],'*uint8');
	if numel(x)~=nPts*nBblock
		error('Fault in reading raw LT-file - Not all data could be read')
	end
	x=reshape([1 1i]*reshape(typecast(x,'double'),2,[]),nVars,nPts)';
else
	warning('??unkown type!!!')
	nBblock=8+(nVars-1)*4;
	x=fread(fid,[nBblock nPts],'*uint8');
	if numel(x)~=nPts*nBblock
		error('Fault in reading raw LT-file - Not all data could be read')
	end
	t=typecast(reshape(x(1:8,:),[],1),'double');
	x=[t reshape(typecast(reshape(x(9:end,:),[],1),'single'),nVars-1,nPts)'];
end
fclose(fid);
dx=nx(3,:);
nx=nx(2,:);
x2=[];

function s=ddeblank(s)
s=deblank(s);
if ~isempty(s)
	while s(1)==9||s(1)==' '
		s(1)=[];
	end
end
