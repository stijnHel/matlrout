function leesmdff(f)
% LEESMDF  - Leest Ascet-files-formaat (MDF-formaat, wat eigenlijk niet van ETAS is)
%     leesmdff(meting)
%
%   deze versie dient enkel om dit formaat te bekijken.

bigendian=[1 256 65536 16777216];
%nhex=64;
nhex=512;

fevent=fopen([zetev f],'r');
if fevent<0
	error('file niet gevonden');
end
x=fread(fevent);
fclose(fevent);
if length(x)<100
	error('De file is te kort')
end
if ~strcmp(setstr(x(1:8)'),'MDF     ')
	error('Onverwacht begin');
end

i0=64;
j=1;
k=1;
ilijst=zeros(100,2);
ilijst(1,:)=[i0,0];
while i0
	ss=setstr(x(i0+1:i0+2)');
	l=bigendian(1:2)*x(i0+(3:4));
	if l>12
		i1=bigendian*x(i0+(5: 8));
		i2=bigendian*x(i0+(9:12));
	else
		i1=-1;
		i2=-1;
	end
	fprintf('%3d (vanuit %5.1f) %s (%d) : %08x %08x\n',j,ilijst(j,2),ss,l,i1,i2);
	if i1>0 & i1<length(x)
		k=k+1;
		ilijst(k,:)=[i1 j];
	end
	if i2>0 & i2<length(x)
		k=k+1;
		ilijst(k,:)=[i2 j+.5];
	end
	printhex(x(i0+(1:min(l,nhex))),[],i0)
	if j>=k
		fprintf('----------------------------------------------\n');
		i0=0;
	else
		j=j+1;
		i0=ilijst(j,1)*(j<100);
	end
end
