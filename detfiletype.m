function [out,xout]=detfiletype(fname)
%detfiletype - Determines filetype
%    [out=]detfiletype(fname)
%    (file has to exist and be able to be opened)
%  file types determined:
%    0 empty
%    1 binary
%    9 no CR/LF
%    2 unix (LF)
%    3 dos (CR LF)
%    4 mac (CR)
%    5 mixed
%    if any values>127, 16 is added to the filetype (if output argument is
%       used)

fid=fopen(fname);
if fid<3
	error('Can''t open file')
end
x=fread(fid);
fclose(fid);
bTextChars=false(1,255);
bTextChars([9 10 13 32:127 160:255])=true;
if isempty(x)
	ft=0;
elseif ~all(bTextChars(max(1,x)))
	ft=1;
else
	iCR=find(x==13);
	iLF=find(x==10);
	if isempty(iCR)
		if isempty(iLF)
			ft=5;
		else
			ft=2;
		end
	elseif isempty(iLF)
		ft=4;
	elseif isequal(iCR+1,iLF)
		ft=3;
	else
		ft=5;
	end
end
if ft>1&any(x>127)
	ft=ft+16;
end

if nargout
	out=ft;
	if nargout>1
		xout=x;
		if ft>1
			ft=char(ft');
		end
	end
else
	switch rem(ft,16)
		case 0
			sft='empty';
		case 1
			sft='binary';
		case 2
			sft='unix';
		case 3
			sft='DOS';
		case 4
			sft='MAC';
		case 5
			sft='mixed';
		otherwise
			error('programmafout!!!')
	end
	if ft>15
		sft=[sft ' (expandedASCII)'];
	end
	fprintf('%s is van type %s.\n',fname,sft)
end
