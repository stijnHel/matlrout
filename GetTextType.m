function [sTxtType,nBytes,nBits,endian,S]=GetTextType(s,bFile)
%GetTextType - Find type of file text type (UTF8, ...) - extended to interpretation
%       [sTxtType,nBytes,nBits,endian,S]=GetTextType(s)
%       ...=GetTextType(fName,true)
%
%    sTxtType: string defining the type
%           UTF-8, UTF-16(_le / _be), UTF-32, ...
%    nBytes: number of bytes used

% based on: https://en.wikipedia.org/wiki/Byte_order_mark

if nargin>1&&bFile
	fName=s;
	fid=fopen(fName);
	if fid<3
		error('Can''t open the file!')
	end
	if nargout>4
		lText=Inf;
	else
		lText=5;
	end
	s=fread(fid,[1 lText],'*char');
	fclose(fid);
end

sTxtType=0;
nBytes=0;
endian=0;
nBits=8;
if strncmp(s,char([239 187 191]),3)	% UTF8
	sTxtType='UTF-8';
	nBytes=3;
elseif strncmp(s,char([254 255]),2)	% UTF16-big-endian
	sTxtType='UTF-16_be';
	nBytes=2;
	endian='B';
	nBits=16;
elseif strncmp(s,char([255 254]),2)	% UTF16 little-endian
	sTxtType='UTF-16_le';
	nBytes=2;
	endian='L';
	nBits=16;
elseif strncmp(s,char([0 0 254 255]),4)	% UTF32 big-endian
	sTxtType='UTF-32_be';
	nBytes=4;
	endian='B';
	nBits=32;
elseif strncmp(s,char([255 254 0 0]),4)	% UTF32 little-endian
	sTxtType='UTF-32_le';
	nBytes=4;
	endian='L';
	nBits=32;
elseif strncmp(s,char(sscanf('2b 2f 76','%x',[1 3])),3)&&length(s)>3
	if s(4)==hex2dec('38')
		sTxtType='UTF7';	%?
		if length(s)>4&&s(5)==hex2dec('2d')
			nBytes=5;
		else
			nBytes=4;
		end
	elseif s(4)==hex2dec('38')
		sTxtType='UTF7';	%?
		nBytes=4;
	elseif s(4)==hex2dec('38')
		sTxtType='UTF7';	%?
		nBytes=4;
	elseif s(4)==hex2dec('38')
		sTxtType='UTF7';	%?
		nBytes=4;
	elseif s(4)==hex2dec('38')
		sTxtType=-1;
	end
elseif strncmp(s,char(sscanf('f7 64 4c','%x',[1 3])),3)
	sTxtType='UTF-1';
	nBytes=3;
elseif strncmp(s,char(sscanf('dd 73 66 73','%x',[1 4])),4)
	sTxtType='UTF-EBCDIC';
	nBytes=4;
elseif strncmp(s,char(sscanf('0e fe ff','%x',[1 3])),3)
	sTxtType='SCSU';
	nBytes=3;
elseif strncmp(s,char(sscanf('FB EE 28','%x',[1 3])),3)
	sTxtType='BOCU-1';
	nBytes=3;
elseif strncmp(s,char(sscanf('84 31 95 33','%x',[1 4])),4)
	sTxtType='GB-18030';
	nBytes=4;
end

if nargout>4
	S=s(nBytes+1:end);
	if nBits>8
		[~,~,E_c]=computer;
		if nBits==16
			S=typecast(uint8(S),'uint16');
		elseif nBites==32
			S=typecast(uint8(S),'uint32');
		else
			warning('Not implemented number of bits!')
		end
		if E_c~=endian
			S=swapbytes(S);
		end
		S=char(S);
	elseif strcmp(sTxtType,'UTF-8')
		i=1;
		while i<length(S)
			if S(i)>=128
				if S(i)<192
					warning('Bad UTF-8! (10xx xxxxb) - stopped interpreting')
					break
				elseif S(i)<224	% 2 bytes
					if S(i+1)<128||S(i+1)>=192
						warning('Bad UTF-8! (2nd byte bad value) - stopped interpreting')
						break
					end
					c=64*bitand(abs(S(i)),31)+bitand(abs(S(i+1)),63);
					S(i)=char(c);
					S(i+1)=[];
				elseif S(i)<240	% 3 bytes
					if any(S(i+1:i+2)<128|S(i+1:i+2)>=192)
						warning('Bad UTF-8! (3-byte sequence) - stopped interpreting')
						break
					end
					c=[bitand(abs(S(i)),15),bitand(abs(S(i+1:i+2)),63)]*[4096;64;1];
					S(i)=char(c);
					S(i+1:i+2)=[];
				elseif S(i)<248	% 4 bytes
					if any(S(i+1:i+3)<128|S(i+1:i+3)>=192)
						warning('Bad UTF-8! (4 byte sequence) - stopped interpreting')
						break
					end
					c=[bitand(abs(S(i)),15),bitand(abs(S(i+1:i+3)),63)]*[262144;4096;64;1];
					S(i)=char(c);
					S(i+1:i+3)=[];
				else
					warning('Bad UTF-8 character (>=248) - stopped interpreting')
					break
				end
			end		% multi byte sequence
			i=i+1;
		end		% while i
	end		% UTF-8
end		% if nargout>4
