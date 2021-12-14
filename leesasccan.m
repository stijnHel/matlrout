function [x info]=leesasccan(fn)
%LEESASCCAN - Leest ASCII CAN-data

fid=fopen(fn);
if fid<3
	fid=fopen(zetev([],fn));
	if fid<3
		error('Kan file niet openen')
	end
end
fseek(fid,0,'eof');
lFile=ftell(fid);
fseek(fid,0,'bof');
h1=fgetl(fid);
h2=fgetl(fid);
h3=fgetl(fid);
start=ftell(fid);
x=zeros(ceil((lFile-start)/50),14);
nx=0;
while ~feof(fid)
	l=deblank(fgetl(fid));
	if isempty(l)
		break;
	end
	if ~ischar(l)
		fclose(fid);
		error('Fout tijdens lezen van file')
	end
	[data1,n,err,nxt]=sscanf(l,'%g %d %x',3);
	if n<3
		warning('Lezen afgebroken');
		break;
	end
	[typ,n,err,nxt1]=sscanf(l(nxt:end),'%s',1);
	if n<1
		warning('Lezen afgebroken');
		break;
	end
	switch typ
		case 'Rx'
			iTyp=1;
		case 'Tx'
			iTyp=2;
		case 'TxRq'
			iTyp=3;
		otherwise
			iTyp=-1;
	end
	nxt=nxt+nxt1-1;
	[isditaltijdd,n,err,nxt1]=sscanf(l(nxt:end),'%s',1);
	if n<1
		warning('Lezen afgebroken');
		break;
	end
	nxt=nxt+nxt1-1;
	[ndata,n,err,nxt1]=sscanf(l(nxt:end),'%d',1);
	if n<1
		warning('Lezen afgebroken');
		break;
	end
	nxt=nxt+nxt1-1;
	[data2,n,err,nxt]=sscanf(l(nxt:end),'%x');
	if n~=ndata
		warning('Lezen afgebroken');
		break;
	end
	if nx>=size(x,1)
		x(end+100,1)=0;
	end
	nx=nx+1;
	x(nx,1)=data1(1);
	x(nx,2)=data1(3);
	x(nx,3)=ndata;
	x(nx,4:3+ndata)=data2;
	x(nx,12)=iTyp;
	x(nx,13)=data1(2);
	x(nx,14)=isditaltijdd=='d';
end
fclose(fid);
x=x(1:nx,:);
if nargout>1
	info=struct('head',{{h1,h2,h3}},'extra',x(:,12:end));
end
x=x(:,1:11);
