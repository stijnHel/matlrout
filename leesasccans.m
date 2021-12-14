function [x info]=leesasccans(fn)
%LEESASCCANS - Leest ASCII CAN-data (sneller)

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
S=fread(fid,[1 inf],'*char');
fclose(fid);
if any(S==13)&&any(S==10)
	S(S==13)=[];
end
i=[0 find(S==10|S==13)];
x=zeros(length(i)-1,11);
xT=zeros(length(i)-1,1);
for j=1:length(i)-1
	i1=i(j)+1;
	x(j,1)=str2num(S(i1:i1+11));
	x(j,2)=sscanf(S(i1+15:i1+17),'%x');
	x(j,3)=double(S(i1+38))-48;
	x(j,4:3+x(j,3))=sscanf(S(i1+40:i(j+1)-1),'%x');
	xT(j)=(S(i1+31)=='T')+(S(i1+33)=='R')*2;
end
if nargout>1
	info=struct('head',{{h1,h2,h3}},'extra',xT);
end
