function D=ReadGZIP(fName)
%ReadGZIP  - Read and extract (in memory) a gzip file
%       D=ReadGZIP(fName)
%     in development!
% No CRC-checks are done;
%
%  (https://tools.ietf.org/html/rfc1952)

fid=fopen(fFullPath(fName,[],'.zip'));
if fid<3
	error('Can''t open the file!')
end
x=fread(fid,[1 Inf],'*uint8');
fclose(fid);

endian=[1;256;65536;16777216];

ix=1;
nD=0;
while ix<length(x)-10
	if x(ix)~=31||x(ix+1)~=139
		error('Wrong identification for gzip-format')
	end
	CM=x(ix+2);
	if CM~=8
		error('Unknown compression method!')
	end
	xFLG=x(ix+3);
	FLG=struct('FTEXT',bitand(xFLG,1)>0	...
		,'FHCRC',bitand(xFLG,2)>0	...
		,'FEXTRA',bitand(xFLG,4)>0	...
		,'FNAME',bitand(xFLG,8)>0	...
		,'FCOMMENT',bitand(xFLG,16)>0	...
		);
	MTIME=double(x(ix+4:ix+7))*endian/86400+datenum(1970,1,1);	% (GMT!)
	XFL=x(ix+8);
	OS=x(ix+9);
	ix=ix+10;
	if FLG.FEXTRA
		XLEN=double(x(ix:ix+1))*endian(1:2);
		FEXTRA=x(ix+2:ix+1+XLEN);
		ix=ix+2+XLEN;
	else
		FEXTRA=[];
	end
	if FLG.FNAME
		i1=ix;
		while x(ix)
			ix=ix+1;
		end
		FNAME=char(x(i1:ix-1));
		ix=ix+1;
	else
		FNAME='';
	end
	if FLG.FCOMMENT
		i1=ix;
		while x(ix)
			ix=ix+1;
		end
		FCOMMENT=char(x(i1:ix-1));
	else
		FCOMMENT='';
	end
	if FLG.FHCRC
		FHCRC=double(x(ix:ix+1))*endian(1:2);
		ix=ix+2;
	else
		FHCRC='';
	end
	xComp=x(ix:end-8);	% can contain multiple blocks!
	% deflate! + extract compressed length!
	[xUncomp,nUsed]=zinflate(xComp);
	ix=ix+nUsed;
	CRC32=double(x(ix:ix+3))*endian;
	ISIZE=double(x(ix+4:ix+7))*endian;
	if ISIZE~=length(xUncomp)
		warning('??Uncompressed size is different from given uncompressed size?!'	...
			,length(xUncomp),ISIZE)
	end
	ix=ix+8;
	D1=struct('CM',CM,'FLG',FLG,'MTIME',MTIME,'XFL',XFL,'OS',OS		...
		,'FEXTRA',FEXTRA,'FNAME',FNAME,'FCOMMENT',FCOMMENT	...
		,'FHCRC',FHCRC,'CRC32',CRC32,'ISIZE',ISIZE	...
		,'orig',xComp,'D',xUncomp);
	if nD
		D(1,end+1)=D1;
	else
		D=D1;
	end
end
