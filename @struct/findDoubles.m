function [Fdif,D]=findDoubles(D,fid)
% STRUCT/FINDDOUBLES - Zoekt naar dubbels in een directorylijst
%       Fdif=findDoubles(D[,fid])

if ~exist('fid','var')
	fid=[];
end
if nargout==0&isempty(fid)
	fid=1;
end
if length(D)==1&&isfield(D,'dirnaam')
	D=sort(flattenDir(D),'name');
end
n=0;
totB=0;
Bd=0;
Bd0=0;
i=1;
iD=zeros(1,length(D));
ndif=0;
while i<length(D)
	ndif=ndif+1;
	b=D(i).bytes;
	totB=totB+b;
	if strcmp(D(i).name,D(i+1).name)
		n=n+1;
		iD(i)=n;
		d=D(i).date;
		Bd0=Bd0+b;
		if fid
			fprintf(fid,'%s : %04d-%02d-%02d %2d:%02d:%02d - %s (%d bytes)\n',D(i).name,d,D(i).dir,b);
		end
		while i<length(D)&&strcmp(D(i).name,D(i+1).name)
			i=i+1;
			iD(i)=-n;
			Bd=Bd+D(i).bytes;
			if fid
				fprintf(fid,'              %s',D(i).dir);
				if any(d~=D(i).date)
					fprintf(fid,' !(%04d-%02d-%02d %2d:%02d:%02d)',D(i).date);
				end
				if b~=D(i).bytes
					fprintf(fid,' !(%dB)',D(i).bytes);
				end
				fprintf(fid,'\n');
			end
		end
	end
	i=i+1;
end
if n==0
	fprintf('!geen enkele dubbele file gevonden!! (%d bytes)\n',totB)
elseif n==1
	fprintf('slechts een dubbele file gevonden!! (%d extra bij %d bytes, met totaal %d)\n',Bd,Bd0,totB)
else
	fprintf('%d dubbele files gevonden. (%d extra bij %d bytes, met totaal %d)\n',n,Bd,Bd0,totB)
end

if nargout
	aiD=abs(iD);
	Fdif=struct('naam',{D(iD(iD>0)).name},'i',[]);
	for i=1:n
		Fdif(i).i=find(aiD==i);
	end
end
