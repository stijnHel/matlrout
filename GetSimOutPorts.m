function Onames=GetSimOutPorts(model)
%GetSimOutPorts - Retrieves output ports of simulinkmodel
%    Onames=GetSimOutPorts(model)

try
	O=find_system(model,'searchdepth',1,'blocktype','Outport');
catch err
	if exist(model,'file')==4
		open(model)
	else
		error('Can''t find the model')
	end
	O=find_system(model,'searchdepth',1,'blocktype','Outport');
end
Onames=cell(1,length(O));
for i=1:length(O)
	% use port number because it's not known if the order of find_system is
	% always logical.  (During tests it was!)
	% strange that "port number" is string!
	Onames{str2double(get_param(O{i},'Port'))}=get_param(O{i},'Name');
end
