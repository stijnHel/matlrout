function [X,info]=leesMIraw(fn,bOnlyInfo)
%leesMIraw - Reads raw data file from Micron sensors (using demo kit)
%       [X,info]=leesMIraw(fn)

dataType='*uint8';
[pth,fname,fext]=fileparts(fn);
fid=fopen(fullfile(pth,[fname '_info.txt']));
if fid<3
	if exist(zetev([],fullfile(pth,[fname '_info.txt'])),'file')
		fn=zetev([],fn);
		[pth,fname,fext]=fileparts(fn);
		fid=fopen(fullfile(pth,[fname '_info.txt']));
	end
	if fid<3
		error('Can''t open the text info file')
	end
end

l=fgetl(fid);
while isempty(findstr(lower(l),'sensor info:'))
	l=fgetl(fid);
	if ~ischar(l)
		fclose(fid);
		error('Can''t find the sensor info part in the info file')
	end
end
W=0;
H=0;
bVideo=false;
nFrames=0;
l='';
while isempty(l)
	l=GetInfoLine(fid);
end
while ~isempty(l)
	if l(1)=='.'
		break
	end
	[s1,ns,serr,nxt]=sscanf(l,'%s',1);
	l=l(nxt:end);
	[s2,ns,serr,nxt]=sscanf(l,'%s',1);
	l=l(nxt:end);
	while ~isempty(l)&&l(1)==' '
		l(1)=[];
	end
	switch lower(s1)
		case 'width'
			W=str2num(l);
		case 'height'
			H=str2num(l);
		case 'image'

		case 'sensor'
			i=find(l=='=');
			nb=sscanf(l(i(1)+1:end),'%d');
			if nb>8
				dataType='*uint16';	% very simple!!!
			end
		case 'stored'
			bVideo=true;
			l=GetInfoLine(fid);
			nBperRow=sscanf(l,'%d',1);
			l=GetInfoLine(fid);
			nBperImage=sscanf(l,'%d',1);
		case 'frames'
			nFrames=str2num(l);
		case 'size'
	end
	l=GetInfoLine(fid);
end
if nargout>1
	l='';
	info=struct('W',W,'H',H,'dType',dataType(2:end)	...
		,'bVideo',bVideo);
	while ~feof(fid)
		while ischar(l)&&(isempty(l)||l(1)~='[')
			l=fgetl(fid);
		end
		if feof(fid)
			break
		end
		i=find(l==']');
		if isempty(i)
			warning('!!!error while interpreting text file (further info)')
			break
		end
		s=l(2:i(1)-1);
		if strcmp(lower(s(max(1,end-4):end)),'state')
			s=s(1:end-5);
		end
		s=deblank(s);
		while s(1)==' '
			s(1)=[];
		end
		s(s==' ')='_';
		fieldName=s;
		info1=struct('name',cell(1,0),'data',cell(1,0),'extra',cell(1,0));
		l=deblank(fgetl(fid));
		while ~isempty(l)
			while l(1)==' '||l(1)==9
				l(1)=[];
			end
			i=find(l==',');
			if isempty(i)
				warning('!!!unexpected data (no ",") - reading of this part is stopped')
				break
			end
			if strcmp(lower(l(1:min(end,6))),'state=')
				info1(end+1).name=l(7:i(1)-1);
				s=l(i(1)+1:end);
				while ~isempty(s)&&(s(1)==' '||s(1)==9)
					s(1)=[];
				end
				info1(end).data=s;
			elseif strcmp(lower(l(1:min(end,4))),'reg=')
				if ~strcmp(l(5:6),'0x')
					warning('!!unexpected label of register!! reading is stopped')
					break
				end
				info1(end+1).name=sscanf(l(7:i(1)-1),'%x',1);
				s=l(i(1)+1:end);
				while ~isempty(s)&&(s(1)==' '||s(1)==9)
					s(1)=[];
				end
				if ~strcmp(s(1:2),'0x')
					warning('!!unexpected data of register!! reading is stopped')
					break
				end
				[info1(end).data,cnt,errmsg,nxt]=sscanf(s(3:end),'%x',1);
				s=s(nxt+2:end);
				while ~isempty(s)&&(s(1)==' '||s(1)==9)
					s(1)=[];
				end
				info1(end).extra=s;
			else
				info1(end+1).name=l(1:i(1)-1);
				info1(end).data=l(i(1)+1:end);
			end
			l=fgetl(fid);
			if ~ischar(l)
				break
			end
			l=deblank(l);
		end
		info.(fieldName)=info1;
		if strcmp(lower(fieldName),'register')
			A=cat(2,info.(fieldName).name);
			D=cat(2,info.(fieldName).data);
			if length(A)~=length(D)
				warning('!!Unexpected data in Register values (or adresses)!!')
			else
				info.RegData=[A;D];
				info.timing=ExtractMIsettings(info.RegData);
			end
		end
	end	% while read all info
end	% if nargout>1
fclose(fid);
if nargin>1&&bOnlyInfo
	X=[];
	return
end
if W==0||H==0
	error('Unknown size')
end
if isempty(fext)
	fext='.raw';
end
if nFrames>1
	status('Reading video data')
end
fid=fopen(fullfile(pth,[fname,fext]));
if fid<3
	error('Can''t open raw data file')
end
if bVideo&&nBperRow~=W
	dataType='*uint8';	% force uint8 data type
end
X=fread(fid,dataType);
fclose(fid);
if bVideo
	if nFrames==0
		warning('No number of frames given for a video file?')
		nFrames=length(X)/W/H;
		if nFrames>floor(nFrames)
			warning('!!!Number of bytes doesn'' match full frames???')
			nFrames=floor(nFrames);
			X=X(1:W*H*nFrames);
		end
	end
else
	nBperRow=W;
	nFrames=1;
end
X=reshape(X,nBperRow,H,nFrames);
if nFrames>1
	status
end
if nBperRow~=W
	nBitPerP=floor(nBperRow*8/W);
	if nBitPerP==16	% no sensor known
		X=uint16(X(1:2:end,:,:))+uint16(X(2:2:end,:,:))*256;
	else
		if nBitPerP==10 % only known alternative for 8-bit images
			status('Interpreting 10 bit image data')
			if rem(nBperRow,5)
				X(ceil(nBperRow/5)*5,1,1)=0;
			end
			B1=uint16(X(1:5:end,:,:));
			B2=uint16(X(2:5:end,:,:));
			B3=uint16(X(3:5:end,:,:));
			B4=uint16(X(4:5:end,:,:));
			B5=uint16(X(5:5:end,:,:));
			X=uint16(0);
			X=X(ones(ceil(W/4)*4,H,nFrames));
			X(1:4:end,:,:)=B1+bitand(B2,3)*256;
			X(2:4:end,:,:)=bitshift(B2,-2)+bitand(B3,15)*64;
			X(3:4:end,:,:)=bitshift(B3,-4)+bitand(B4,63)*16;
			X(4:4:end,:,:)=bitshift(B4,-6)+B5*4;
			if size(X,1)>W
				X=X(1:W,:,:);
			end
		else    % (very) slow method
			X1=uint16(0);
			X1=X1(ones(W,H,nFrames));
			M=uint16(bitshift(1,nBitPerP)-1);
			status('This is made for files with 8-bit images, and not optimized for 8+-images',0)
			for iF=1:nFrames
				for iR=1:H
					Word=uint16([1 256]*double(X(1:2,iR,iF)));
					iB=2;
					nB=16;
					for iC=1:W
						X1(iC,iR,iF)=bitand(Word,M);
						Word=bitshift(Word,-nBitPerP);
						nB=nB-nBitPerP;
						while nB<=8&&iB<nBperRow
							iB=iB+1;
							Word=bitor(Word,bitshift(uint16(X(iB,iR,iF)),nB));
							nB=nB+8;
						end
					end	% for all columns
				end	% for all rows
				status(iF/nFrames)
			end	% for all frames
			X=X1;
		end
		status
	end	% 8<nBperRow<16 (expected)
end
if nFrames==1
	X=X';
end

function l=GetInfoLine(fid)
bBlank=false(1,255);
bBlank([9 abs(' \/')])=true;
l=fgetl(fid);
if ~ischar(l)
	fclose(fid);
	error('Unexpected end of info-file')
	return
end
while ~isempty(l)&&bBlank(abs(l(1)))
	l(1)=[];
end
