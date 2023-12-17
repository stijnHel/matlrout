function [tML,timeFormat]=Tim2MLtime(t,timeFormat,b2Datetime)
%Tim2MLtime - Convert time to Matlab-timestamp
%          tML=Tim2MLtime(t,timeFormat[,,b2Datetime])
%                tymeFormat:
%                     'excel' (days after -1/1/1900)
%                     'matlab'
%                     'matlabSeconds'
%                     'winSeconds'
%                     'winMillisec'
%                     'winMicrosec'
%                     'winNanosec'
%                     'lvSeconds' (LabVIEW seconds)
%                     'julianday'
%                     'beckhoff'
%                     'beckhoffSec'
%                     'base<time>' with <time> (days)
%                              yyyymmdd
%                              yyyymmddHHMMSS.FFF
%                                only HH, HHMM, HHMMSS are also possible
%                     'sec<time>' same as base.. but with seconds
%                 b2Datetime: not Matlab datenum (orig format), but datetime
%          [tScale,tOffset] = Tim2MLtime(timeFormat,t)
%
% See also datetime (with similar Matlab-builtin functionality)
%          axtick2date

if nargin<3 || isempty(b2Datetime)
	b2Datetime = false;
end

if ~isnumeric(t)
	if isa(t,'lvtime')
		tML = double(t);
		timeFormat = 'lvtime';
	elseif ischar(t)
		if nargin<2
			timeFormat = [];
		end
		[tML,timeFormat]=GetScaleOffset(t,timeFormat);
	else
		error('Wrong input!')
	end
else
	if nargin<2||isempty(timeFormat)
		timeFormat=GetDefaultTF(t(1));
	end
	if isnumeric(t)&&~isfloat(t)
		t=double(t);
	end
	[tScale,tOffset] = GetScaleOffset(timeFormat,t(1));
	tML=double(t)/tScale+tOffset;
end

if b2Datetime
	tML = datetime(tML,'ConvertFrom','datenum');
end

function timeFormat=GetDefaultTF(t)
if t<1e5
	if t>10000	% Excel-date?
		timeFormat='excel';
	else
		timeFormat='base20101101';
	end
elseif t>1e18
	timeFormat='winNanosec';
elseif t>1e17
	timeFormat='beckhoff';
elseif t>1e15
	timeFormat='winMicrosec';
elseif t>1e12
	timeFormat='winMillisec';
elseif t>6e10	% supposed to be "Matlab-seconds" (matlabtime*86400)
	timeFormat='matlabSeconds';
elseif t>1e10
	timeFormat='beckhofSec';
elseif t>3e9
	timeFormat='lvSeconds';
elseif t>1e7	% supposed to be "windows-seconds" (sec after 1/1/1970)
	timeFormat='winSeconds';
elseif t>1e6	% supposed to be jd
	timeFormat='julianday';
else
	timeFormat='matlab';
end

function [tScale,tOffset] = GetScaleOffset(timeFormat,t)
tScale=1;
tOffset=0;
bDSTcorr = false;
switch lower(timeFormat)
	case 'excel'
		tOffset=datenum(1900,1,-1);
	case 'winseconds'
		tScale=86400;
		tOffset=datenum(1970,1,1,1,0,0);
		bDSTcorr = true;
	case 'winmicrosec'
		tScale=86400e6;
		tOffset=datenum(1970,1,1,1,0,0);
		bDSTcorr = true;
	case 'winmillisec'
		tScale=86400e3;
		tOffset=datenum(1970,1,1,1,0,0);
		bDSTcorr = true;
	case 'winnanosec'
		tScale=86400e9;
		tOffset=datenum(1970,1,1,1,0,0);
		bDSTcorr = true;
	case 'lvseconds'
		tScale=86400;
		tOffset=datenum(1904,1,1);
		bDSTcorr = true;
	case 'matlabseconds'
		tScale=86400;
		tOffset=0;
	case 'julianday'
		%tOffset=datenum(2000,1,1)-calcjd(1,1,2000);	% julian day ---> matlab-datenum
		tOffset=-1721058.5;
	case 'matlab'
		%no "correction"
	case 'beckhoff'
		tScale=86400e7;
		tOffset=datenum(1601,1,1,1,0,0);
	case 'beckhofsec'
		tScale=86400;
		tOffset=datenum(1601,1,1,1,0,0);
	case 'ntp64'
		tScale=86400;
		tOffset=datenum(1900,1,1);
		bDSTcorr = true;
	otherwise
		bBase=strncmpi(timeFormat,'base',4);
		bSec=strncmpi(timeFormat,'sec',3);
		if bSec
			sTime=timeFormat(4:end);
			tScale=86400;
		elseif bBase
			sTime=timeFormat(5:end);
		else
			error('Unknown time format!')
		end
		lTime=length(sTime);
		if lTime<8||~all((sTime>='0'&sTime<='9')|sTime=='.')
				% not fool proof!
			error('Wrong base time format')
		end
		tBase=sscanf(sTime,'%04d%02d%02d',[1 3]);
		if lTime>8
			tB=sscanf(sTime(9:end),'%02d%02d%02d%f');
			if length(tB)<3
				tB(1,3)=0;
			elseif length(tB)>3
				tB(3)=tB(3)+tB(4);
			end
			tBase(4:6)=tB(1:3);
		end
		tOffset=datenum(tBase);
end
if bDSTcorr && ~isempty(t) && isDST(t/tScale+tOffset)
	tOffset=tOffset+1/24;
end
