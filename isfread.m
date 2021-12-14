function [T,V,H] = isfread(filename)

% This function loads the binary data from a Tektronix ".ISF"
% file.  The ISF file format is used by newer Tektronix
% TDS-series oscilloscopes.
%
% Syntax:
%   [t,v] = isfread(filename);
%   [t,v,head] = isfread(filename);
%
% Input:
%   filename - name of Tektronix ISF file
%
% Outputs:
%   t - time data vector
%   v - voltage data vector.  If format is 'ENV' (envelope), two columns
%       are returned: [vmax vmin]
%   head - (optional) header record of file

% origin:
% http://www.mathworks.nl/matlabcentral/fileexchange/24402-isfread-updated

if any(filename=='?' | filename=='*')
	d=dir(filename);
	if isempty(d)
		d=direv(filename);
		if isempty(d)
			error('No file found')
		end
	end
	OUT=cell(max(1,length(d)),nargout);
	for i=1:length(d)
		[OUT{i,:}]=isfread(d(i).name);
	end
	T=OUT(:,1);
	if nargout>1
		V=OUT(:,2);
		if nargout>2
			H=OUT(:,3);
		end
	end
	return
end

if ~exist(filename,'file')
	if exist(zetev([],filename),'file')
		filename=zetev([],filename);
	else
		error('%s not found.',filename);
	end
end;

FID = fopen(filename,'r');
nOut=0;
T=cell(1,10);
V=cell(1,10);
H=cell(1,10);

while true
	head = ReadHead(FID);
	if isempty(head)
		break
	end

	bWords=(head.bytenum == 2) && (head.bitnum == 16);
	bBytes =(head.bytenum == 1) && (head.bitnum == 8);

	if  ~(bWords || bBytes) || ...
			not(strcmp(head.encoding,'BIN')) || ...
			not(strcmp(head.binformat,'RI'))
		fclose(FID);
		error('Unable to process IFS file.');
	end

	switch head.byteorder
		case 'MSB'
			machineformat = 'b';
		case 'LSB'
			machineformat = 'l';
		otherwise,
			error('Unrecognized byte order.');
	end

	if bWords
		data = fread(FID, head.npts, 'int16', machineformat);
	elseif bBytes	% due to previous tests must be true (==> not necessary)
		data = fread(FID, head.npts, 'int8', machineformat);
	end

	% If ENV format (envelope), separate into max and min
	% this doesn't seem to be true....
	if strcmp(head.pointformat,'ENV')
		%disp('Envelope format: voltage output = [vmax vmin]');
		npts = round(head.npts/2);
		vmin = head.yzero + head.ymult*(data(1:2:end) - head.yoff);
		vmax = head.yzero + head.ymult*(data(2:2:end) - head.yoff);
		t = head.xzero + head.xincr*(0:npts-1)'*2;  % 2 data points per increment
		v = [vmax vmin];
	else
		v = head.yzero + head.ymult*(data - head.yoff);
		t = head.xzero + head.xincr*(0:head.npts-1)';
	end;
	nOut=nOut+1;
	T{nOut}=t;
	V{nOut}=v;
	H{nOut}=head;
end
fclose(FID);
if nOut==1
	T=T{1};
	V=V{1};
	H=H{1};
else
	T=T(1:nOut);
	V=V(1:nOut);
	H=[H{1:nOut}];
end

function z = getnum(str,pattern)
ii = strfind(str,pattern) + length(pattern);
tmp = strtok(str(ii:length(str)),';');
z = str2double(tmp);

function z = getstr(str,pattern)
ii = strfind(str,pattern) + length(pattern) + 1;
z = strtok(str(ii:length(str)),';');

function z = getquotedstr(str,pattern)
ii = strfind(str,pattern) + length(pattern) + 1;
z = strtok(str(ii:length(str)),'"');

function head = ReadHead(FID)
pStart=ftell(FID);
hdata = fread(FID,511,'char')';			% read first 511 bytes
if length(hdata)<511
	head=[];
	return
end
hdata = min(hdata,126);					% eliminate non-ascii
hdata = max(hdata,9);					% characters from header data
hdata = char(hdata);					% convert to character string

bytenum = getnum(hdata,'BYT_NR');
bitnum = getnum(hdata,'BIT_NR');
encoding = getstr(hdata,'ENCDG');
binformat = getstr(hdata,'BN_FMT');
byteorder = getstr(hdata,'BYT_OR');
wfid = getquotedstr(hdata,'WFID');
pointformat = getstr(hdata,'PT_FMT');
xunit = getquotedstr(hdata,'XUNIT');
yunit = getquotedstr(hdata,'YUNIT');
xzero = getnum(hdata,'XZERO');
xincr = getnum(hdata,'XINCR');
ptoff = getnum(hdata,'PT_OFF');
ymult = getnum(hdata,'YMULT');
yzero = getnum(hdata,'YZERO');
yoff = getnum(hdata,'YOFF');
npts = getnum(hdata,'NR_PT');

% New format (e.g. Tek DPO3000 series, 2009) changed several formats...
if isnan(npts)
	bytenum = getnum(hdata,'BYT_N');
	bitnum = getnum(hdata,'BIT_N');
	encoding = getstr(hdata,'ENC');
	binformat = getstr(hdata,'BN_F');
	byteorder = getstr(hdata,'BYT_O');
	wfid = getquotedstr(hdata,'WFI');
	pointformat = getstr(hdata,'PT_F');
	xunit = getquotedstr(hdata,'XUN');
	yunit = getquotedstr(hdata,'YUN');
	xzero = getnum(hdata,'XZE');
	xincr = getnum(hdata,'XIN');
	ptoff = getnum(hdata,'PT_O');
	ymult = getnum(hdata,'YMU');
	yzero = getnum(hdata,'YZE');
	yoff = getnum(hdata,'YOF');
	npts = getnum(hdata,'NR_P');
end;
head.bytenum = bytenum;
head.bitnum = bitnum;
head.encoding = encoding;
head.binformat = binformat;
head.byteorder = byteorder;
head.wfid = wfid;
head.pointformat = pointformat;
head.xunit = xunit;
head.yunit = yunit;
head.xzero = xzero;
head.xincr = xincr;
head.ptoff = ptoff;
head.ymult = ymult;
head.yzero = yzero;
head.yoff = yoff;
head.npts = npts;

ii = strfind(hdata,'#');

% Fix for reading files from older scopes
fseek(FID,pStart+ii(1),'bof');					% advance to start of data
skip = str2double(fread(FID,1,'*char'));
fseek(FID,skip,'cof');
