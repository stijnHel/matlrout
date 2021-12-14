function [Tir,Ecjout]=tcconversief(Vir,Tcj,sensorType)
%TCCONVERSIEF - Conversie van thermokoppel-signaal
%   [Tir,Ecj]=tcconversief(Vir,Tcj[,sensType])
%       Vir : gemeten spanning [mV]
%       Tcj : cold junction temperature [degC]
%       sensorType : sensor-type ('K', 'T', 'B', ...)
%           default 'K'
%       Tir : berekende temperatuur
%       Ecj : cold junction potential (relative to 0 degC)

global TCdata

if isempty(TCdata)
	[pth,fn]=fileparts(mfilename('fullpath'));
	fndata=[pth filesep 'its90all.tab'];
	if ~exist(fndata,'file')
		error('data-file is niet gevonden')
	end
	try
		TCdata = readstdtcdata_r14(fndata);
	catch
		TCdata = readstdtcdata_r13(fndata);
	end
	% extra data
	fid=fopen('IRtcTabel.txt','r');
	if fid>0
		h1=fgetl(fid);
		h2=fgetl(fid);
		n=sum(h2==9);
		x=fscanf(fid,'%g');
		if rem(length(x),n+1)
			warning('Er loopt iets fout bij het inlezen van IRtc-data')
			x=x(1:end-rem(length(x),n+1));
		end
		x=reshape(x,n+1,[])';
		i=[find(h2==9) length(h1)+1];
		for j=1:n
			TCdata(end+1).Type=['IR' h2(i(j)+1:i(j+1)-1)];
			TCdata(end).TData=x(:,1);
			TCdata(end).VData=x(:,j+1);
		end
		fclose(fid);
	end
end
if ischar(Vir)
	switch lower(Vir)
		case 'list'
			if nargout
				Tir={TCdata.Type};
			else
				fprintf('%s\n',TCdata.Type);
			end
		otherwise
			error('Verkeerd gebruikt van tcconversief')
	end
	return
end
if ~exist('sensorType','var')||isempty(sensorType)
	sensorType='K';
end
iType=strmatch(upper(sensorType),{TCdata.Type},'exact');
if isempty(iType)
	error('Juiste thermokoppel sensortype niet gevonden')
end
tc=TCdata(iType);

Vcj=interp1(tc.TData,tc.VData,Tcj);
V=Vir+Vcj;
if any(diff(tc.VData)<=0)
	i=findclose(tc.VData,V);
	i=max(i-2,1):min(i+2,length(tc.TData));
	Tir=interp1(tc.VData(i),tc.TData(i),Vir+Vcj);
else
	Tir=interp1(tc.VData,tc.TData,V);
end
if nargout>1
	Ecjout=Vcj;
end
