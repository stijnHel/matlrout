function [tMatlab,scale,timeFormat]=Conv2MLtime(timeFormat,t,varargin)
%Conv2MLtime - Convert time to Matlab time-format.
%     [tMatlab,scale,timeFormat]=Conv2MLtime(timeFormat,t)
%     [tMatlab,scale,timeFormat]=Conv2MLtime(t)
%         timeformat (default - auto-select):
%             'excel' - Excel timestamp (0/1/1900 - days)
%             'winSeconds' - Windows timestamp (1/1/1970 - seconds)
%             'lvSeconds' - LabVIEW timestamp (1/1/1904 - seconds)
%             'matlab' - Matlab timestamp (to be complete)
%             'matlabSeconds' - Matlab timestamp but converted to seconds
%             'julianday' - Julian day (astronomically used timestamp)
%             'base<yyyymmdd>' or 'base<yyyymmddHHMMSS>'
%                    given starting time
%             'sec<yyyymmdd>' or 'sec<yyyymmddHHMMSS>'
%                    given starting time
%         t: time vector
%
%         tMatlab - converted time to Matlab timestamp
%         scale - [tScale tOffset]: tMatlab = t/tScale + tOffset

% remark for some types, DST is used, for others not!

bUseDST=true;
if ~isempty(varargin)
	setoptions({'bUseDST'},varargin{:})
end
if nargin==1
	t=timeFormat;
	timeFormat=[];
elseif isnumeric(timeFormat)&&ischar(t)	% do the opposite conversion
	tIn=timeFormat;
	tfOut=t;
	tfIn=GetDefaultTF(tIn);
	[tScaleIn,tOffsetIn]=GetScale(tfIn,tIn,[],bUseDST);
	tMatlab=tIn/tScaleIn+tOffsetIn;
	[tScaleOut,tOffsetOut]=GetScale(tfOut,[],tMatlab,bUseDST);
	tMatlab=(tMatlab-tOffsetOut)*tScaleOut;
	return
end

if isempty(timeFormat)
	timeFormat=GetDefaultTF(t);
end
[tScale,tOffset]=GetScale(timeFormat,t,[],bUseDST);
tMatlab=t/tScale+tOffset;
if nargout>1
	scale=[tScale,tOffset];
end

function timeFormat=GetDefaultTF(xl)
if xl(1)<1e5
	if xl(1)>10000	% Excel-date?
		timeFormat='excel';
	else
		timeFormat='base20101101';
	end
elseif xl(1)>6e10	% supposed to be "Matlab-seconds" (matlabtime*86400)
	timeFormat='matlabSeconds';
elseif xl(1)>3e9
	timeFormat='lvSeconds';
elseif xl(1)>1e7	% supposed to be "windows-seconds" (sec after 1/1/1970)
	timeFormat='winSeconds';
elseif xl(1)>1e6	% supposed to be jd
	timeFormat='julianday';
else
	timeFormat='matlab';
end

function [tScale,tOffset]=GetScale(timeFormat,t,tMatlab,bUseDST)
tScale=1;
tOffset=0;
switch lower(timeFormat)
	case 'excel'
		tOffset=datenum(1900,1,-1);
		bUseDST=false;	% overrule
	case 'winseconds'
		tScale=86400;
		tOffset=datenum(1970,1,0,1,0,0);
	case 'winmillisec'
		tScale=86400e3;
		tOffset=datenum(1970,1,1,1,0,0);
	case 'winmicrosec'
		tScale=86400e6;
		tOffset=datenum(1970,1,1,1,0,0);
	case 'winnanosec'
		tScale=86400e9;
		tOffset=datenum(1970,1,1,1,0,0);
	case 'lvseconds'
		tScale=86400;
		tOffset=datenum(1904,1,1);
	case 'matlabseconds'
		tScale=86400;
		tOffset=0;
		bUseDST=false;	% overrule
	case 'julianday'
		%tOffset=datenum(2000,1,1)-calcjd(1,1,2000);	% julian day ---> matlab-datenum
		tOffset=-1721058.5;
		bUseDST=false;	% overrule???
	case 'matlab'
		%no "correction"
		bUseDST=false;	% overrule
	otherwise
		bBase=strncmpi(timeFormat,'base',4);
		bSec=strncmpi(timeFormat,'sec',3);
		if bBase||bSec
			if bSec
				sTime=timeFormat(4:end);
				tScale=86400;
			else
				sTime=timeFormat(5:end);
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
		bUseDST=false;	% overrule
end
if bUseDST
	if isempty(t)
		if isDST(tMatlab(1))
			tOffset=tOffset+1/24;
		end
	elseif isDST(t(1)/tScale+tOffset)
		tOffset=tOffset+1/24;
	end
end
