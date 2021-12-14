function riff = riffread(file,ext)
% RIFFREAD - Reads RIFF-files
% Parts are taken from wavread (the Mathworks).

% (kijk ook in aviriff.h)

% chunks read as char --> better to read in uint8 and only convert to char
% if needed

% Parse input arguments:
nargchk(1,2,nargin);
if nargin<2, ext=[]; end    % Default - read all samples
exts = prod(size(ext));     % length of extent info
if ~strncmp(lower(ext),'size',exts) & (exts > 2),
	error('Index range must be specified as a scalar or 2-element vector.');
end
if ~ischar(ext) & exts==1,
	if ext==0,
		ext='size';           % synonym for size
	else
		ext=[1 ext];          % Prepend start sample index
	end
end

% Open WAV file:
[fid,msg] = open_wav(file);
error(msg);

% Find the first RIFF chunk:
[riffck,msg] = find_cktype(fid,'RIFF');
%error(msg);
if ~isempty(msg),
	error('Not a WAVE file.');
end

typ = find_cktype(fid,0);

% Find optional chunks, and don't stop till <data-ck> found:
found_data  = 0;
end_of_file = 0;
opt_ck      = [];

while(~end_of_file),
	[ck,msg] = find_cktype(fid);
	error(msg);
	
	switch lower(ck.ID)
		
		case 'end of file'
			end_of_file = 1;
			
		case 'fmt'
			% <fmt-ck> found
			[opt_ck,msg] = read_wavefmt(fid,ck,opt_ck);
			error(msg);
			
		case 'data'
			% <data-ck> found:
			found_data = 1;
			if ~isfield(opt_ck,'fmt'),
				error('Corrupt WAV file: found audio data before format information.');
			end
			
			if strncmp(lower(ext),'size',exts) | ...
					(~isempty(ext) & all(ext==0)),
				% Caller doesn't want data - just data size:
				[samples,msg] = read_wavedat(ck, opt_ck.fmt, -1);
				error(msg);
				y = [samples opt_ck.fmt.nChannels];
				
			else
				% Read <wave-data>:
				[datack,msg] = read_wavedat(ck, opt_ck.fmt, ext);
				error(msg);
				y = datack.Data;
				
			end
			
		case 'fact'
			% Optional <fact-ck> found:
			[opt_ck,msg] = read_factck(fid, ck, opt_ck);
			error(msg);
			
		case 'disp'
			% Optional <disp-ck> found:
			[opt_ck,msg] = read_dispck(fid, ck, opt_ck);
			error(msg);
			
		case 'list'
			% Optional <list-ck> found:
			[opt_ck, msg] = read_listck(fid, ck, opt_ck);
			error(msg);
			
		case 'anih'
			fprintf('"%s" werd nog niet geimplementeerd\n',ck.ID)
			if rem(ck.Size,2), ck.Size=ck.Size+1; end
			[x,l]=fread(fid,ck.Size);
			if(l~=ck.Size==-1),
				error('Incorrect chunk size information in WAV file.');
			end
			printhex(x)
		case 'rate'
			if rem(ck.Size,4)
				fclose(fid);
				error('Verkeerde grootte voor rate')
			end
			opt_ck=setfield(opt_ck,'rate',fread(fid,ck.Size/4,'long'));
			if length(opt_ck.rate)*4~=ck.Size
				fclose(fid);
				error('Kon rate niet volledig inlezen');
			end
		otherwise
			fprintf('Onbekende data ''%s'' (len=%d bytes)\n',ck.ID,ck.Size)
			% Skip over data in unprocessed chunks:
			if rem(ck.Size,2), ck.Size=ck.Size+1; end
			if(fseek(fid,ck.Size,0)==-1),
				error('Incorrect chunk size information in WAV file.');
			end
	end
end
fclose(fid);

riff=struct('Type',typ.ID,'opt',opt_ck);
switch lower(typ.ID)
	case 'wave'
		% Parse structure info for return to user:
		Fs = opt_ck.fmt.nSamplesPerSec;
		if opt_ck.fmt.wFormatTag == 1,
			bits = opt_ck.fmt.nBitsPerSample;
		else
			bits = [];  % Unknown
		end
		riff=setfield(riff,'y',y);
		riff=setfield(riff,'Fs',Fs);
		riff=setfield(riff,'bits',bits);
	case 'acon'	%(ani-cursor)
		riff=setfield(riff,'cursors',extract_cursors(opt_ck.list.fram));
	otherwise
		fprintf('Geen bekend type (%s)\n',typ.ID)
end


% ------------------------------------------------------------------------
% Private functions:
% ------------------------------------------------------------------------

% ---------------------------------------------
% OPEN_WAV: Open a WAV file for reading
% ---------------------------------------------
function [fid,msg] = open_wav(file)
% Append .wav extension if it's missing:
[pat,nam,ext] = fileparts(file);
if isempty(ext),
	file = [file '.wav'];
end
[fid,msg] = fopen(file,'rb','l');   % Little-endian
if fid == -1,
	msg = 'Cannot open file.';
end
return

% ---------------------------------------------
% READ_CKINFO: Reads next RIFF chunk, but not the chunk data.
%   If optional sflg is set to nonzero, reads SUBchunk info instead.
%   Expects an open FID pointing to first byte of chunk header.
%   Returns a new chunk structure.
% ---------------------------------------------
function [ck,msg] = read_ckinfo(fid,ftype)
msg     = '';
ck.fid  = fid;
ck.Data = [];
err_msg = 'Truncated chunk header found - possibly not a WAV file.';

[s,cnt] = fread(fid,4,'char');

% Do not error-out if a few (<4) trailing chars are in file
% Just return quickly:
if (cnt~=4),
	if feof(fid),
		% End of the file (not an error)
		ck.ID = 'end of file';  % unambiguous chunk ID (>4 chars)
		ck.Size = 0;
	else
		msg = err_msg;
	end
	return
end

ck.ID = deblank(setstr(s'));

if ~ischar(ftype)
	return
end

% Read chunk size (skip if subchunk):
[sz,cnt] = fread(fid,1,'ulong');
if cnt~=1,
	msg = err_msg;
	return
end
ck.Size = sz;
return

% ---------------------------------------------
% FIND_CKTYPE: Finds a chunk with appropriate type.
%   Searches from current file position specified by fid.
%   Leaves file positions to data of desired chunk.
%   If optional sflg is set to nonzero, finds a SUBchunk instead.
% ---------------------------------------------
function [ck,msg] = find_cktype(fid,ftype)

msg = '';
if nargin<2, ftype = ''; end

[ck,msg] = read_ckinfo(fid,ftype);
if ~isempty(msg), return; end

% Was a required chunk type specified?
if ~isempty(ftype) & ~strcmp(lower(ck.ID),lower(ftype)),
	msg = ['<' ftype '-ck> did not appear as expected'];
end
return

% ---------------------------------------------
% READ_LISTCK: Read the FLIST chunk:
% ---------------------------------------------
function [opt_ck,msg] = read_listck(fid,ck, orig_opt_ck)

MAXBYTES=2^28;

opt_ck = orig_opt_ck;

orig_pos    = ftell(fid);
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 4;       % # of required bytes in <list-ck> header
msg = '';
err_msg = 'Error reading <list-ck> chunk.';

if total_bytes < nbytes,
	msg = err_msg;
	return
end

% Read standard <list-ck> data:
if total_bytes>MAXBYTES
	warning('Data chunk is too large - truncated! (%d/%d bytes read)'	...
		,MAXBYTES,total_bytes)
	listdata = fread(fid,[1 MAXBYTES],'*char');
	fseek(fid,total_bytes-MAXBYTES,'cof');
else
	listdata = fread(fid,[1 total_bytes],'*char');
end

listtype = lower(listdata(1:4)); % Get LIST type
listdata = listdata(5:end);      % Move past INFO

if strcmp(listtype,'info'),
	% Information:
	while(~isempty(listdata)),
		id = listdata(1:4);
		switch lower(id)
			case 'iart'
				name = 'Artist';
			case 'icmt'
				name = 'Comments';
			case 'icrd'
				name = 'Creation date';
			case 'icop'
				name = ['Copy' 'right'];
			case 'ieng'
				name = 'Engineer';
			case 'inam'
				name = 'Name';
			case 'iprd'
				name = 'Product';
			case 'isbj'
				name = 'Subject';
			case 'isft'
				name = 'Software';
			case 'isrc'
				name = 'Source';
			otherwise
				name = id;
		end
		
		if ~isfield(opt_ck,'info'),
			opt_ck.info = [];
		end
		len = listdata(5:8) * 2.^[0 8 16 24]';
		txt = listdata(9:9+len-1);
		
		% Fix up text: deblank, and replace CR/LR with LF
		txt = deblank(txt);
		idx=findstr(txt,setstr([13 10]));
		txt(idx) = '';
		
		% Store - don't include the "name" info
		opt_ck.info = setfield(opt_ck.info, lower(id), txt );
		
		if rem(len,2), len=len+1; end
		listdata = listdata(9+len:end);
	end
	
else
	if ~isfield(opt_ck,'list'),
		opt_ck.list = [];
	end
	if isfield(opt_ck.list,listtype)
		warning(sprintf('optie "%s" wordt overschreven.',listtype))
	end
	opt_ck.list = setfield(opt_ck.list, listtype, listdata);
end

% Skip over any unprocessed data:
if rem(total_bytes,2), total_bytes=total_bytes+1; end
rbytes = total_bytes - (ftell(fid) - orig_pos);
if rbytes~=0,
	if (fseek(fid,rbytes,'cof')==-1),
		msg = err_msg;
	end
end
return


% ---------------------------------------------
% READ_DISPCK: Read the DISP chunk:
% ---------------------------------------------
function [opt_ck, msg] = read_dispck(fid,ck,orig_opt_ck)

opt_ck = orig_opt_ck;

orig_pos    = ftell(fid);
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 4;       % # of required bytes in <disp-ck> header
msg = '';
err_msg = 'Error reading <disp-ck> chunk.';

if total_bytes < nbytes,
	msg = err_msg;
	return
end

% Read standard <disp-ck> data:
data = fread(fid,total_bytes,'uchar');

% Process data:

% First few entries are size info:
icon_data = data;
siz_info = reshape(icon_data(1:2*4),4,2)';
siz_info = siz_info*(2.^[0 8 16 24]');
is_icon = isequal(siz_info,[8;40]);

if ~is_icon,
	% Not the icon:
	opt_ck.disp.name = 'DisplayName';
	txt = deblank(setstr(data(5:end)'));
	opt_ck.disp.text = txt;
end

% Skip over any unprocessed data:
if rem(total_bytes,2), total_bytes=total_bytes+1; end
rbytes = total_bytes - (ftell(fid) - orig_pos);
if rbytes~=0,
	if(fseek(fid,rbytes,'cof')==-1),
		msg = err_msg;
	end
end
return


% ---------------------------------------------
% READ_FACTCK: Read the FACT chunk:
% ---------------------------------------------
function [opt_ck,msg] = read_factck(fid,ck,orig_opt_ck)

opt_ck      = orig_opt_ck;
orig_pos    = ftell(fid);
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 4;       % # of required bytes in <fact-ck> header
msg = '';
err_msg = 'Error reading <fact-ck> chunk.';

if total_bytes < nbytes,
	msg = err_msg;
	return
end

% Read standard <fact-ck> data:
opt_ck.fact = setstr(fread(fid,total_bytes,'uchar')');

% Skip over any unprocessed data:
if rem(total_bytes,2), total_bytes=total_bytes+1; end
rbytes = total_bytes - (ftell(fid) - orig_pos);
if rbytes~=0,
	if(fseek(fid,rbytes,'cof')==-1),
		msg = err_msg;
	end
end
return


% ---------------------------------------------
% READ_WAVEFMT: Read WAVE format chunk.
%   Assumes fid points to the <wave-fmt> subchunk.
%   Requires chunk structure to be passed, indicating
%   the length of the chunk in case we don't recognize
%   the format tag.
% ---------------------------------------------
function [opt_ck,msg] = read_wavefmt(fid,ck,orig_opt_ck)

opt_ck = orig_opt_ck;

orig_pos    = ftell(fid);
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 14;  % # of required bytes in <wave-format> header
msg = '';
err_msg = 'Error reading <wave-fmt> chunk.';

if total_bytes < nbytes,
	msg = err_msg;
	return
end

% Read standard <wave-format> data:
opt_ck.fmt.wFormatTag      = fread(fid,1,'ushort'); % Data encoding format
opt_ck.fmt.nChannels       = fread(fid,1,'ushort'); % Number of channels
opt_ck.fmt.nSamplesPerSec  = fread(fid,1,'ulong');  % Samples per second
opt_ck.fmt.nAvgBytesPerSec = fread(fid,1,'ulong');  % Avg transfer rate
opt_ck.fmt.nBlockAlign     = fread(fid,1,'ushort'); % Block alignment

% Read format-specific info:
switch opt_ck.fmt.wFormatTag
	case 1
		% PCM Format:
		[opt_ck.fmt, msg] = read_fmt_pcm(fid, ck, opt_ck.fmt);
end

% Skip over any unprocessed fmt-specific data:
if rem(total_bytes,2), total_bytes=total_bytes+1; end
rbytes = total_bytes - (ftell(fid) - orig_pos);
if rbytes~=0,
	if(fseek(fid,rbytes,'cof')==-1),
		msg = err_msg;
	end
end

return


% ---------------------------------------------
% READ_FMT_PCM: Read <PCM-format-specific> info
% ---------------------------------------------
function [fmt,msg] = read_fmt_pcm(fid, ck, fmt)

% There had better be a bits/sample field:
total_bytes = ck.Size; % # bytes in subchunk
nbytes      = 14;  % # of bytes already read in <wave-format> header
msg = '';
err_msg = 'Error reading PCM <wave-fmt> chunk.';

if (total_bytes < nbytes+2),
	msg = err_msg;
	return
end

[bits,cnt] = fread(fid,1,'ushort');
nbytes=nbytes+2;
if (cnt~=1),
	msg = err_msg;
	return
end
fmt.nBitsPerSample=bits;

% Are there any additional fields present?
if (total_bytes > nbytes),
	% See if the "cbSize" field is present.  If so, grab the data:
	if (total_bytes >= nbytes+2),
		% we have the cbSize ushort in the file:
		[cbSize,cnt]=fread(fid,1,'ushort');
		nbytes=nbytes+2;
		if (cnt~=1),
			msg = err_msg;
			return
		end
		fmt.cbSize = cbSize;
	end
	
	% Simply skip any remaining stuff - we don't know what it is:
	if rem(total_bytes,2), total_bytes=total_bytes+1; end
	rbytes = total_bytes - nbytes;
	if rbytes~=0,
		if (fseek(fid,rbytes,'cof') == -1);
			msg = err_msg;
		end
	end
end
return


% ---------------------------------------------
% READ_WAVEDAT: Read WAVE data chunk
%   Assumes fid points to the wave-data chunk
%   Requires <data-ck> and <wave-format> structures to be passed.
%   Requires extraction range to be specified.
%   Setting ext=[] forces ALL samples to be read.  Otherwise,
%       ext should be a 2-element vector specifying the first
%       and last samples (per channel) to be extracted.
%   Setting ext=-1 returns the number of samples per channel,
%       skipping over the sample data.
% ---------------------------------------------
function [dat,msg] = read_wavedat(datack,wavefmt,ext)

% In case of unsupported data compression format:
dat     = [];
fmt_msg = '';

switch wavefmt.wFormatTag
	case 1
		% PCM Format:
		[dat,msg] = read_dat_pcm(datack,wavefmt,ext);
	case 2
		fmt_msg = 'Microsoft ADPCM';
	case 6
		fmt_msg = 'CCITT a-law';
	case 7
		fmt_msg = 'CCITT mu-law';
	case 17
		fmt_msg = 'IMA ADPCM';
	case 34
		fmt_msg = 'DSP Group TrueSpeech TM';
	case 49
		fmt_msg = 'GSM 6.10';
	case 50
		fmt_msg = 'MSN Audio';
	case 257
		fmt_msg = 'IBM Mu-law';
	case 258
		fmt_msg = 'IBM A-law';
	case 259
		fmt_msg = 'IBM AVC Adaptive Differential';
	otherwise
		fmt_msg = ['Format #' num2str(wavefmt.wFormatTag)];
end
if ~isempty(fmt_msg),
	msg = ['Data compression format (' fmt_msg ') is not supported.'];
end
return


% ---------------------------------------------
% READ_DAT_PCM: Read PCM format data from <wave-data> chunk.
%   Assumes fid points to the wave-data chunk
%   Requires <data-ck> and <wave-format> structures to be passed.
%   Requires extraction range to be specified.
%   Setting ext=[] forces ALL samples to be read.  Otherwise,
%       ext should be a 2-element vector specifying the first
%       and last samples (per channel) to be extracted.
%   Setting ext=-1 returns the number of samples per channel,
%       skipping over the sample data.
% ---------------------------------------------
function [dat,msg] = read_dat_pcm(datack,wavefmt,ext)

dat = [];
msg = '';

% Determine # bytes/sample - format requires rounding
%  to next integer number of bytes:
BytesPerSample = ceil(wavefmt.nBitsPerSample/8);
if (BytesPerSample == 1),
	dtype='uchar'; % unsigned 8-bit
elseif (BytesPerSample == 2),
	dtype='short'; % signed 16-bit
else
	msg = 'Cannot read PCM file formats with more than 16 bits per sample.';
	return
end

total_bytes       = datack.Size; % # bytes in this chunk
total_samples     = total_bytes / BytesPerSample;
SamplesPerChannel = total_samples / wavefmt.nChannels;
if ~isempty(ext) & ext==-1,
	% Just return the samples per channel, and fseek past data:
	dat = SamplesPerChannel;
	
	% Add in a pad-byte, if required:
	total_bytes = total_bytes + rem(datack.Size,2);
	
	if(fseek(datack.fid,total_bytes,'cof')==-1),
		msg = 'Error reading PCM file format.';
	end
	
	return
end

% Determine sample range to read:
if isempty(ext),
	ext = [1 SamplesPerChannel];    % Return all samples
else
	if prod(size(ext))~=2,
		msg = 'Sample limit vector must have 2 elements.';
		return
	end
	if ext(1)<1 | ext(2)>SamplesPerChannel,
		msg = 'Sample limits out of range.';
		return
	end
	if ext(1)>ext(2),
		msg = 'Sample limits must be given in ascending order.';
		return
	end
end

bytes_remaining = total_bytes;  % Preset byte counter

% Skip over leading samples:
if ext(1)>1,
	% Skip over leading samples, if specified:
	skipcnt = BytesPerSample * (ext(1)-1) * wavefmt.nChannels;
	if(fseek(datack.fid, skipcnt,'cof') == -1),
		msg = 'Error reading PCM file format.';
		return
	end
	%
	% Update count of bytes remaining:
	bytes_remaining = bytes_remaining - skipcnt;
end

% Read desired data:
nSPCext    = ext(2)-ext(1)+1; % # samples per channel in extraction range
dat        = datack;  % Copy input structure to output
extSamples = wavefmt.nChannels*nSPCext;
dat.Data   = fread(datack.fid, [wavefmt.nChannels nSPCext], dtype);
%
% Update count of bytes remaining:
skipcnt = BytesPerSample*nSPCext*wavefmt.nChannels;
bytes_remaining = bytes_remaining - skipcnt;

% if cnt~=extSamples, dat='Error reading file.'; return; end
% Skip over trailing samples:
if(fseek(datack.fid, BytesPerSample * ...
		(SamplesPerChannel-ext(2))*wavefmt.nChannels, 'cof')==-1),
	msg = 'Error reading PCM file format.';
	return
end
% Update count of bytes remaining:
skipcnt = BytesPerSample*(SamplesPerChannel-ext(2))*wavefmt.nChannels;
bytes_remaining = bytes_remaining - skipcnt;

% Determine if a pad-byte is appended to data chunk,
%   skipping over it if present:
if rem(datack.Size,2),
	fseek(datack.fid, 1, 'cof');
end
% Rearrange data into a matrix with one channel per column:
dat.Data = dat.Data';
% Normalize data range: min will hit -1, max will not quite hit +1.
if BytesPerSample==1,
	dat.Data = (dat.Data-128)/128;  % [-1,1)
else
	dat.Data = dat.Data/32768;  % [-1,1)
end

return

function curslijst=extract_cursors(fram)
% extract_cursors - Extract cursors uit frame (van animated cursor)
curslijst={};
while ~isempty(fram)
	if length(fram)<8
		error('!!Iets fout met ACON-data')
	end
	if ~strcmp(lower(fram(1:4)),'icon')
		error('Anders dan verwacht (in extract_cursors)')
	end
	l=abs(fram(5:8))*[1;256;65536;16777216];
	curslijst{end+1}=cursread(abs(fram(9:8+l)));
	fram(1:8+l)=[];
end
