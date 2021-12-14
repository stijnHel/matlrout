function [tML,timeFormat]=Tim2MLtime(t,timeFormat)
%Tim2MLtime - Convert time to Matlab-timestamp
%          tML=Tim2MLtime(t,timeFormat)
%                tymeFormat:
%                     'excel' (days after -1/1/1900)
%                     'matlab'
%                     'matlabSeconds'
%                     'winSeconds'
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
%    extracted data from axtick2date

if ~isnumeric(t)
	if isa(t,'lvtime')
		tML = double(t);
		timeFormat = 'lvtime';
		return
	else
		error('Wrong input!')
	end
end

tScale=1;
tOffset=0;
if nargin<2||isempty(timeFormat)
	timeFormat=GetDefaultTF(t(1));
end
if isnumeric(t)&&~isfloat(t)
	t=double(t);
end
switch lower(timeFormat)
	case 'excel'
		tOffset=datenum(1900,1,-1);
	case 'winseconds'
		tScale=86400;
		tOffset=datenum(1970,1,1,1,0,0);
		if isDST(t(1)/tScale+tOffset)
			tOffset=tOffset+1/24;
		end
	case 'winmicrosec'
		tScale=86400e6;
		tOffset=datenum(1970,1,1,1,0,0);
		if isDST(t(1)/tScale+tOffset)
			tOffset=tOffset+1/24;
		end
	case 'winnanosec'
		tScale=86400e9;
		tOffset=datenum(1970,1,1,1,0,0);
		if isDST(t(1)/tScale+tOffset)
			tOffset=tOffset+1/24;
		end
	case 'lvseconds'
		tScale=86400;
		tOffset=datenum(1904,1,1);
		if isDST(t(1)/tScale+tOffset)
			tOffset=tOffset+1/24;
		end
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
		if isDST(t(1)/tScale+tOffset)
			tOffset=tOffset+1/24;
		end
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
tML=double(t)/tScale+tOffset;

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
