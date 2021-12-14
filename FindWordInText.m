function [ii,S0]=FindWordInText(fName,word,varargin)
%FindWordInText - Find a word in a file - 8-bit, 16-bit, case (in)sensitive
%    [ii,S]=FindWordInText(fName,word,varargin)

bCaseInsensitive=true;
b8bit=true;
b16bit=true;
bDirectText=~ischar(fName);
bPrint=nargout==0;
nPre=16;
nPost=64;
if nargin>2
	setoptions({'bCaseInsensitive','bDirectText','b8bit','b16bit','bPrint'}	...
		,varargin{:})
end

if bDirectText
	S=char(fName);
else
	fid=fopen(fName);
	if fid<3
		error('Can''t open the file!')
	end
	S=fread(fid,[1 Inf],'*char');
	fclose(fid);
end

S0=S;
if bCaseInsensitive
	S=upper(S);
	word=upper(word);
end
if b8bit
	ii1=strfind(S,word);
else
	ii1=[];
end
if b16bit
	ii2=strfind(S(1:2:end),word);
	ii3=strfind(S(2:2:end),word);
	ii2=sort([ii2*2-1,ii3*2]);
else
	ii2=[];
end
ii=sort([ii1 ii2]);
if bPrint
	for i=1:length(ii)
		if any(ii(i)==ii1)
			fprintf('%3d: %6d (8bit)\n',i,ii(i))
			n=length(word)+nPost;
		else
			fprintf('%3d: %6d (16bit)\n',i,ii(i))
			n=length(word)*2+nPost;
		end
		printhex(S0(max(1,ii(i)-nPre):min(length(S0),ii(i)+n-1)))
	end
end
