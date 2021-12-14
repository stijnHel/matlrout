function [e,ne,de,e2,gegs]=leesdat(fn,start,lengte)
% LEESDAT  - Leest DAT-meting (metingen van GIF)

fid=fopen([zetev fn],'r');
if fid<3
	error('Kan file niet openen');
end

if nargin<2|isempty(start)
	start=0;
end
if nargin<3|isempty(lengte)
	lengte=inf;
end

ne='';
de='';

N=fread(fid,[1 2],'uint16');
nkan=fread(fid,1,'uint16');
nmet=fread(fid,1,'long');
dt=fread(fid,1,'single');
D1=fread(fid,5,'single');

DD=zeros(nkan,10);
for i=1:nkan
	kan1=deblank(fread(fid,[1 21],'*char'));
	dim1=deblank(fread(fid,[1 11],'*char'));
	n1=fread(fid,1,'uint16');
	d1=fread(fid,[1 9],'single');
	ne=addstr(ne,kan1);
	if isempty(dim1)
		de=addstr(de,'-');
	else
		de=addstr(de,dim1);
	end
	DD(i,:)=[n1 d1];
end
if start
	fseek(fid,4*nkan*start,'cof');
end
lengte=min(lengte-start,nmet);
e=fread(fid,[nkan,lengte],'single')';
fclose(fid);


if nargout>3
	e2=[];
	e=[(start:start+lengte-1)'*dt e];
	ne=addstr('t',ne);
	de=addstr('s',de);
	gegs=struct('N0',N,'nkan',nkan,'nmet',nmet,'dt',dt	...
		,'D1',D1,'DD',DD);
end
