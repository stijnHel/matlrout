function [X,Y]=ReadMLV(fName)
%ReadMLV  - Read MLV-file
%       X=ReadMLV(fName)
%  very basic!!!! tested on very limited data!!!!!

f=file(fName);
x=fread(f,'*uint8');
fclose(f);

ix=0;
[nVar,ix]=readI32(x,ix);
C=cell(4,nVar);
for i=1:nVar
	[l,ix]=readI32(x,ix);
	C{1,i}=char(x(ix+1:ix+l)');
	ix=ix+l;
	%printhex(x(ix+1:ix+64))
	ixNext=ix+12;
	if x(ix+4)==4
		ixNext=ixNext+8;
	end
	I=x(ix+1:ixNext);
	ix=ixNext;
	s=swapbytes(typecast(I(end-7:end),'uint32'))';
	ixNext=ix+2*8*prod(s);
	Y=swapbytes(typecast(x(ix+1:ixNext),'double'));
	Y=reshape([1 1i]*reshape(Y,2,prod(s)),s);
	C{2,i}=Y;
	ix=ixNext;
	ixNext=ix+30;
	C{3,i}=I';
	C{4,i}=x(ix+1:ixNext)';
	ix=ixNext;
end
X=struct(C{1:2,:});
if nargout>1
	Y={struct(C{[1 3],:}),struct(C{[1 4],:}),x(ix+1:end)'};
end


function [i,nNew]=readI32(x,n)
nNew=n+4;
i=swapbytes(typecast(x(n+1:nNew),'int32'));
