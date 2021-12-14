function X=ReadEMF(fName)
%ReadEMF  - Starting function to read an EMF file (WMF - enhanced)
%    X=ReadEMF(fName);

fid=fopen(fName);
if fid<3
	error('Can''t open the file!')
end
x=fread(fid,[1 Inf],'*uint8');
fclose(fid);

[Htp,Hsz,Hd,ix]=GetObject(x,1);
if Htp~=1
	error('No good header start found!')
end
if Hsz>=108
	hExt=2;
elseif Hsz>=100
	hExt=1;
else
	hExt=0;
end
d=typecast(Hd,'int32');
Head=struct('hExtension',hExt	...
	,'bounds',d(1:4),'frame',double(d(5:8))/100	...
	,'rSig',char(Hd(33:36)),'version',d(10)	...
	,'lFile',d(11),'nRecords',d(12)	...
	,'nHandles',d(13)	... (should be d(13)&65535)
	,'nDescription',d(14),'offDescription',d(15)	...
	,'nPalEntries',d(16),'device',d(17:18),'millimeters',d(19:20)	...
	);
if hExt
	Head.cbPixelFormat=d(21);
	Head.offPixelFormat=d(22);
	Head.bOpenGL=d(23);
	if hExt>1
		Head.MicrometersX=d(24);
		Head.MicrometersY=d(25);
	end
end

O=struct('tp',cell(1,Head.nRecords-1),'d',[]);
for i=1:Head.nRecords-1
	[O(i).tp,sz,O(i).d,ix]=GetObject(x,ix);
	switch O(i).tp
		case 14		% EOF
			if i+1~=Head.nRecords
				warning('End-Of-File before the end?!')
			end
	end
end
X=struct('head',Head,'Hd',Hd,'d',d	...
	,'O',O);

function [tp,sz,d,iEnd]=GetObject(x,ix)
iLE=[1;256;65536;16777216];
tp=double(x(ix:ix+3))*iLE;
sz=double(x(ix+4:ix+7))*iLE;
iEnd=ix+sz;
if iEnd>length(x)+1
	error('Something goes wrong!')
end
d=x(ix+8:iEnd-1);

