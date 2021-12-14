function [X,nX,dX,X2,gegs,str]=reads1p(fn)
%reads1p  - Reads S11 files from network analyzer (Agilent E8358A: A.01.51)
%    X=reads1p(<filename>);

if ~exist(fn,'file')
	if exist(zetev([],fn),'file')
		fn=zetev([],fn);
	else
		error('Can''t find file "%s".',fn)
	end
end
X=dlmread(fn,'',3,0);
X(:,4)=X(:,2)+1i*X(:,3);
if nargout>1
	nX={'f','Sreal','Simag','Scomplex'};
	dX={'Hz','-','-','-'};
	X2=[];
	if nargout>4
		fid=fopen(fn);
		l1=fgetl(fid);
		l2=fgetl(fid);
		l3=fgetl(fid);
		lhead=ftell(fid);
		fseek(fid,0,'eof');
		lfile=ftell(fid);
		fclose(fid);
		ver=0;
		nKan=size(X,2)-1;
		gegs=[ver 0 0 1 1 2100 0 0 0  0 nKan mean(diff(X(:,1))) 0 0 1 lhead size(X,1) lfile ones(1,nKan) zeros(1,nKan)];
		str={l1,l2,l3};
	end
end
