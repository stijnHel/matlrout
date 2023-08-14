function CreateCANbus()
%CreateCANbus - compatible with Matlab-canbus
%   isn't there a standard routine to do this?
%
%    CreateCANbus()
%       ---> adds a variable (base Matlab workspace) CAN_MESSAGE_BUS

elems = Simulink.BusElement;

elements = {	...
	'Extended','uint8',1;
	'Length','uint8',1;
	'Remote','uint8',1;
	'Error','uint8',1;
	'ID','uint32',1;
	'Timestamp','double',1;
	'Data','uint8',8;
	};
for i=1:size(elements,1)
	elems(i).Name = elements{i};
	elems(i).DataType = elements{i,2};
	elems(i).Dimensions = elements{i,3};
end
BUS = Simulink.Bus;
BUS.Elements = elems;
assignin('base','CAN_MESSAGE_BUS',BUS)
