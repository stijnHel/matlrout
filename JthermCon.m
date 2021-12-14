function T=JthermCon(V,Xin)
%JthermCon - J-thermistor conversion (for NI-TCxx module)
%     T=JthermCon(V)
% (JthermCon <datafile>
%  and JthermCon <option> can be used too)

global JTHERMdata

if isempty(JTHERMdata)
	LoadDataFile('Jthermistor.txt');
end
if ischar(V)
	switch lower(V)
		case 'ohm'
			JTHERMdata.bVoltInput=false;
		case 'volt'
			JTHERMdata.bVoltInput=true;
		case 'vref'
			JTHERMdata.Vin=Xin;
		case 'rref'
			JTHERMdata.Rup=Xin;
		otherwise
			JTHERMdata=LoadDataFile(V);
	end
	SetXinput
	return
end
T=interp1(JTHERMdata.Xin,JTHERMdata.tab(:,1),V);

function D=LoadDataFile(f1)
global JTHERMdata
[pth,fn]=fileparts(mfilename('fullpath'));
f1='Jthermistor.txt';
fndata=[pth filesep f1];
if ~exist(fndata,'file')
	if exist(f1,'file')
		fndata=which(f1);
	else
		error('data-file is niet gevonden')
	end
end
X=load(fndata);
JTHERMdata=struct('tab',X	...
	,'bVoltInput',true	...
	,'Rup',5000	...
	,'Vin',2.5	...
	,'Xin',[]	...
	);
SetXinput

function SetXinput
global JTHERMdata
if JTHERMdata.bVoltInput
	JTHERMdata.Xin=JTHERMdata.tab(:,2)./(JTHERMdata.Rup+JTHERMdata.tab(:,2))*JTHERMdata.Vin;
else
	JTHERMdata.Xin=JTHERMdata.tab(:,2);
end
