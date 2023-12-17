function CreateChargerOutBus()
%CreateChargerOutBus - create databus with charger-data
%    CreateChargerOutBus()
%       ---> adds a variable (base Matlab workspace) CHARGER_OUT_BUS

elems = Simulink.BusElement;

elements = {	...
	'Vbat','double',1;
	'Ibat','double',1;
	'HSTEMP','double',1;
	'BATTEMP','double',1;
	'VBATCHARGER','double',1;
	'VSENS','double',1;
	'V13V','double',1;
	};
for i=1:size(elements,1)
	elems(i).Name = elements{i};
	elems(i).DataType = elements{i,2};
	elems(i).Dimensions = elements{i,3};
end
BUS = Simulink.Bus;
BUS.Elements = elems;
assignin('base','CHARGER_OUT_BUS',BUS)
