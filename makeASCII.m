function Xout=makeASCII(fn,fnCorr,varargin)
%makeASCII - replace non-ASCII chars (>127) by other chars
%      makeASCII(fn,fnCorr[,options])
%             default fnCorr: same name (and extenstion) with '_corr' added
%
%  options:
%        rCh     : list of replacement characters ([c1 cR1;c2 cR2;...])
%        cDefault: default replacement character ('Z')

rCh=[181 'u'];
cDefault='Z';
if ~isempty(varargin)
	setoptions({'rCh','cDefault'},varargin{:})
end

if ~exist('fnCorr','var')||isempty(fnCorr)
	[pth,fn,fext]=fileparts(fn);
	fnCorr=[pth fn '_corr' fext];
end

fid=fopen(fn);
if fid<3
	error('Can''t open the file')
end
x=fread(fid);
fclose(fid);

i=find(x>127);
if isempty(i)
	fprintf('No "bad characters" found, no new file made!');
	return
end
if length(i)/length(x)>1e-3
	error('Too many "bad characters" (%d/%d)!',length(i),length(x))
end

U=unique(x(i));
Uset=cell(1,length(U));
for i=1:length(U)
	j=find(x==U(i));
	Uset{i}=j;
	if any(U(i)==rCh(:,1))
		cN=rCh(U(i)==rCh,2);
	else
		cN=cDefault;
	end
	fprintf('Character %3d - %c (%d)--> %c\n',U(i),char(U(i)),length(j),cN);
	for k=1:length(j)
		fprintf('     ');
		ii=max(1,j(k)-8):min(length(x),j(k)+7);
		printhex(x(ii),[],ii(1)-1)
	end
	x(j)=cN;
end
	
if ischar(fnCorr)
	fid=fopen(fnCorr,'w');
	if fid<3
		error('Can''t open new file')
	end
	fwrite(fid,x);
	fclose(fid);
end
if nargout
	Xout=struct('Tnew',char(x'),'CnonASCII',char(U'),'Idx',{Uset});
end
