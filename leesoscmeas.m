function [x,nx,dx,x2,gegs]=leesoscmeas(fn)
%leesoscmeas - Reads a measurement of an oscilloscope (agilent)
%     [x,nx,dx,x2,gegs]=leesoscmeas(fn)

if isnumeric(fn)&&isscalar(fn)
	fn=sprintf('PRINT_%02d.CSV',fn);
elseif ~ischar(fn)
	error('Wrong input to this function')
end
fid=fopen(fn);
if fid<3
	fid=fopen(zetev([],fn));
	if fid<3
		error('Can''t open the file (%s)',fn)
	else
		fn=zetev([],fn);
	end
end

l1=fgetl(fid);
icomma=find(l1==',');
if isempty(icomma)
	firstWord='';
else
	firstWord=deblank(l1(1:icomma(1)-1));
end
fseek(fid,0,'bof');
if length(icomma)<6&strcmp(lower(firstWord),'x-axis')
	[x,nx,dx,x2,gegs]=leesAgilentOscData(fid);
elseif strcmp(lower(firstWord),'record length')
	[x,nx,dx,x2,gegs]=leesTektronicsOscData(fid);
else
	error('Unknown Format')
end

function [x,nx,dx,x2,gegs]=leesAgilentOscData(fid)
fn=fopen(fid);
l1=fgetl(fid);
l2=fgetl(fid);
lhead=ftell(fid);
fseek(fid,0,'eof');
lfile=ftell(fid);	% just for "gegs"
fclose(fid);
i1=find(l1==',');
i2=find(l2==',');
if length(i1)<1||length(i1)~=length(i2)
	error('Channel names or units can not be found')
end
nx=cell(1,length(i1)+1);
dx=nx;
i1=[0 i1 length(l1)+1];
i2=[0 i2 length(l2)+1];
for i=1:length(i1)-1
	nx{i}=l1(i1(i)+1:i1(i+1)-1);
	dx{i}=l2(i2(i)+1:i2(i+1)-1);
end
x=csvread(fn,2);
x2=[];
ver=0;
nKan=size(x,2)-1;
gegs=[ver 0 0 1 1 2100 0 0 0  0 nKan mean(diff(x(:,1))) 0 0 1 lhead size(x,1) lfile ones(1,nKan) zeros(1,nKan)];

function [x,nx,dx,x2,gegs]=leesTektronicsOscData(fid)
fn=fopen(fid);
lhead=0;
Ltot=-1;
dt=-1;
tTrig=0;
nx=[];
for i=1:50	% how much?
	l1=fgetl(fid);
	icomma=find(l1==',');
	if length(l1)<2
		break
	end
	w1=deblank(lower(l1(1:icomma(1)-1)));
	w2=deblank(l1(icomma(1)+1:icomma(2)-1));
	switch w1
		case 'record length'
			Ltot=str2num(w2);
		case 'sample interval'
			dt=str2num(w2);
		case 'trigger point'
			tTrig=str2num(w2);
		case 'source'
		case 'vertical units'
		case 'vertical scale'
		case 'vertical offset'
		case 'horizontal units'
		case 'horizontal scale'
		case 'pt fmt'
		case 'yzero'
		case 'probe atten'
		case 'model number'
		case 'serial number'
		case 'firmware number'
		case ''
		otherwise
	end
end
fseek(fid,0,'eof');
lfile=ftell(fid);
fclose(fid);
x=csvread(fn,0,3);

x2=[];
ver=0;
nKan=size(x,2)-1;
if isempty(nx)
	nx=reshape(sprintf('x%02d',0:nKan),3,[])';
	nx(1,:)='t  ';
	dx='-';
	dx=dx(ones(1,nKan+1),1);
	dx(1)='s';
end
if isempty(dt)
	dt=mean(diff(x(:,1)));
end
gegs=[ver 0 0 1 1 2100 0 0 0  tTrig nKan dt 0 0 1 lhead size(x,1) lfile ones(1,nKan) zeros(1,nKan)];
