function [Tir,Ecjout]=tcconversion(Vir,Tcj,sensorType,bDirection)
%TCCONVERSION Conversion of thermocouple inputs, with CJ compensation
%
%Description
% Function to convert measured voltage of a thermocouple and the
% temperature of the "cold junction", so that a cold junction compensation
% can be done (in software).  Different types of thermocouples can be used.
% There is also some data of infrared thermopiles (from Exergen).
%
% The T/C data is read from file its90all.tab.  This data is public data
%   available from different sources.  The prefered location of this file
%   is the directory of this function, otherwise it is checked if the file
%   can be found on the Matlab-path.
%   The IRt/c data is read from IRtcTabel.txt, which is data extracted from
%   Exergen-website.
%
%[Tir,Ecj]=tcconversion(Vir,Tcj[,sensorType])
%
%Parameters [IN]:
%       Vir        : measured voltage [mV]
%       Tcj        : cold junction temperature [degC]
%       sensorType : sensor-type ('K', 'T', 'B', ...)
%           also Exergen IRt/c-tables are available : IRK-50, ...
%           default 'K'
%           use : tcconversion list
%              to get a list of available sensors
%Parameters [OUT]:
%       Tir        : calculated temperature
%       Ecj        : cold junction potential (relative to 0 degC)
%
% Other use :
%    tcconversion list (or types=tcconversion('list');)
%       gives the list of available sensor types
%    tcconversion clear
%       clears the global data
%    tcconversion reread
%       rereads the data
%
%  Needed function : readstdtcdata_r14 to read thermocouple-data.

%Authors: Stijn Helsen
%Created: June 2006
%Matlab version: 7.0.0.19901 (R14)
%
% Copyright (c) 2006 FMTC Flanders Mechatronics Technology Centre, Belgium
%
%
%IMPORTANT VARIABLES 
%  TCdata : global variable with different sets of thermocouple data
%     it is struct-array with at three used fields :
%          Type: the different possible sensor types
%          TData: vector for temperature list
%          VData: vector for voltages related to the previous temperature data
%     after initialisation this is seen as a constant, but could be changed
%        by other functions
%  Vcj : The cold junction voltage (only given to output variable (Ecjout)
%    if this output is really requested.

% Initialisation

global TCdata

if isempty(TCdata)
	% reading thermocouple characteristics from file to global data.
	%   the standard from ITS-90 data is used
	[pth,fn]=fileparts(mfilename('fullpath'));
	f1='its90all.tab';
	fndata=[pth filesep f1];
	if ~exist(fndata,'file')
		if exist(f1,'file')
			fndata=which(f1);
		else
			error('data-file is niet gevonden')
		end
	end
	try
		TCdata = readstdtcdata_r14(fndata);
	catch
		TCdata = readstdtcdata_r13(fndata);
	end
	% extra data (infrared thermocouple data from Exergen)
	f1='IRtcTabel.txt';
	fndata=[pth filesep f1];
	if ~exist(fndata,'file')
		if exist(f1,'file')
			fndata=which(f1);
		else
			fndata='';
		end
	end
	fid=0;
	if ~isempty(fndata)
		fid=fopen(fndata,'r');
	end
	if fid<3
		warning('infrared-data couldn''t be read!')
	else
		h1=fgetl(fid);
		h2=fgetl(fid);
		n=sum(h2==9);
		x=fscanf(fid,'%g');
		if rem(length(x),n+1)
			warning('Something is going wrong while reading IRtc-data')
			x=x(1:end-rem(length(x),n+1));
		end
		x=reshape(x,n+1,[])';
		i=[find(h2==9) length(h2)+1];
		for j=1:n
			TCdata(end+1).Type=['IR' h2(i(j)+1:i(j+1)-1)];
			TCdata(end).TData=x(:,1);
			TCdata(end).VData=x(:,j+1);
		end
		fclose(fid);
	end
end

% INPUT BLOCK START
if nargin<4||isempty(bDirection)
	bDirection = false;	% V --> T
end
% Check for special uses of this function (character input)
if ischar(Vir)
	switch Vir
		case 'list'
			if nargout
				Tir={TCdata.Type};
			else
				disp(strvcat(TCdata.Type));
			end
		case 'clear'
			clear TCdata
		case 'reread'
			TCdata=[];
			T=tcconversion('list');
		otherwise
			error('Unknown use of this function')
	end
	return
end

if ~exist('sensorType','var')||isempty(sensorType)
	sensorType='K';
end
iType=find(strcmpi(sensorType,{TCdata.Type}));
if isempty(iType)
	error('Juiste thermokoppel sensortype niet gevonden')
end
tc=TCdata(iType);

% INPUT BLOCK END
if bDirection
	Tir = Vir;
	Vir = interp1(tc.TData,tc.VData,Tir);
	if ~isempty(Tcj)
		Vcj=interp1(tc.TData,tc.VData,Tcj);
		Vir = Vir-Vcj;
	end
	Tir = Vir;	% use (old) default output type variable name
else
	if isempty(Tcj)
		V = Vir;
	else
		Vcj=interp1(tc.TData,tc.VData,Tcj);	% calculation of cold junction voltage (relative to 0 degC)
		V=Vir+Vcj;	% "hot junction voltage" relative to 0 degC (CJ-compensation)
	end

	% conversion from voltage to temperature, since non-monotonic behaviour is
	% possible with thermocouples, care is taken for this possibility.
	if any(diff(tc.VData)<=0)
		i=findclose(tc.VData,V);
		i=max(i-2,1):min(i+2,length(tc.TData));
		Tir=interp1(tc.VData(i),tc.TData(i),Vir+Vcj);
	else
		Tir=interp1(tc.VData,tc.TData,V);
	end
end

% OUTPUT BLOCK START
% The first output (Tir) is always set in the main function block.
if nargout>1
	Ecjout=Vcj;
end
% OUTPUT BLOCK END
