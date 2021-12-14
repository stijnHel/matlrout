function fPth=unixpath(fPth)
%unixpath - Convert windows-path to unix-path (FMTC specific)
%   fPthUnix=unixpath(fPthWindows)

drive='';
if any(fPth==':')
	driveList={'i','/mnt/samba/fmtc-projects';
		'h','/mnt/samba/fmtc-share';
		'q','/mnt/samba/fmtc-bulk';
		'x','/mnt/samba/fmtc-archive';
		'y','/mnt/samba/fmtc-pool'	...
		};
	%since drive letters are not standard within FMTC, this can give
	%problems!
	i=find(fPth==':');
	if length(i)>1
		error('This is not possible! - more than one '':''')
	end
	drive=fPth(1:i-1);
	fPth(1:i)=[];
	if isempty(drive)
		warning('UNIXPATH:unknwonDrive','?drive? - %s',drive)
	else
		i=strmatch(lower(drive),driveList(:,1),'exact');
		if lower(drive)=='c'
			error('c-drive is not expected here')
		elseif isempty(i)
			error('this drive is not known!')
		else
			drive=driveList{i,2};
		end
	end
elseif strncmp(fPth,'\\',2)
	iSrv=find(fPth=='\',3);
	if length(iSrv)<3
		error('No direct server location allowed here')
	end
	srvList={'\\server04.site04.wtcm.be\','\\server04\'	...
		,'\\server04.sirris.be\'};
	i=strmatch(lower(fPth(1:iSrv(3))),srvList);
	if ~isempty(i)
		srv=srvList{i};
		fPth=['/mnt/samba/' fPth(length(srv)+1:end)];
	else
		error('Unknown server')
	end
end
fPth(fPth=='\')='/';
if fPth(1)=='/'
	if ~isempty(drive)
		fPth=[drive fPth];
	else
		%?what?
	end
end
