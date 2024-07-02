function [Bout,Par_out,Val_out,Units] = SetSSPars(sys,typ,block,value,varargin)
%SetSSPars - Set parameter(s) of blocks of a Simscape model
%   SetSSPars(sys,typ,{<block-parameter1>,value1;...})
%               <block-parameter<i>>: block parameter of a block (like 'r' for Resistor)
%   SetSSPars(sys,typ,value)	-  value based on type <typ>
%   SetSSPars(sys,typ,block,value)
%   SetSSPars(sys,typ[,block],'get')	- retrieves data
%
%   example:
%         SetSSPars(gcs,'Resistor','Resistor1',{'r',0.2})
%                  --> set resistor value of Resistor block Resistor1 to 0.2
%         SetSSPars(gcs,'Resistor','Resistor1',0.2)
%                  --> same but sets the "main parameter"
%   main parameters of blocks:
%            'Resistor' : 'r'
%            'Capacitor': 'c'
%            'Inductor' : 'l'
%
% function output:
%      [B,Par,Val,Units] = SetSSPars...

% this function can be extended to more types (not only electrical)!

if nargin<1 || isempty(sys)
	sys = gcs;
end
if nargin<=1 || (ischar(typ)&&startsWith(typ,'get','IgnoreCase',true))	% get all
	if nargout
		O = cell(3,4);
	else
		O = cell(3,0);
	end
	[O{1,:}] = SetSSPars(sys,'Resistor','get');
	[O{2,:}] = SetSSPars(sys,'Inductor','get');
	[O{3,:}] = SetSSPars(sys,'Capacitor','get');
	if nargout
		Bout = O(:,1)';
		Par_out = O(:,2)';
		Val_out = O(:,3)';
		Units = O(:,4)';
	end
	return
end
Par = [];
if nargin<4 || isempty(value) || (ischar(block) && strcmpi(block,'get'))
	Bspec = {typ};
	if nargin>3 && ischar(block) && strcmpi(block,'get')
		Par = value;
	end
	value = block;
else
	Bspec = [{ typ,block},varargin];
	if iscell(block) && size(block,2)>1
		Par = block(:,2);
	end
end
if ischar(value) && strcmpi(value,'get')
	value = [];
end
B = FindSSblock(sys,Bspec{:});
if iscell(value)
	Par = value(:,1);
	Val = value(:,2);
elseif isempty(value)	% get
	if isempty(Par)
		switch typ
			case 'Resistor'
				Par = {'r'};
			case 'Capacitor'
				Par = {'c','r','g'};
			case 'Inductor'
				Par = {'l','r','g'};
			otherwise
				error('Unknown(/not implementd) block type for auto-selection of parameter')
		end
	elseif ischar(Par)
		Par = {Par};
	end
	Val = zeros(length(B),length(Par));
	if nargout>3
		Units = cell(length(B),length(Par));
	end
	for i=1:length(B)
		if nargout==0
			fprintf('%s:\n',B{i})
		end
		for j=1:length(Par)
			v = get_param(B{i},Par{j});
			Val(i,j) = evalin('base',v);	% evalin to allow the use of formula's with variables
			if nargout==0 || nargout>3
				u = get_param(B{i},[Par{j},'_unit']);
				if nargout<4
					fprintf('       %-4s: %s [%s]\n',Par{j},v,u)
				else
					Units{i,j} = u;
				end
			end
		end
	end
	if nargout
		Bout = B;
		Par_out = Par;
		Val_out = Val;
	end
	return
else
	switch typ
		case 'Resistor'
			Par = {'r'};
			Val = {value};
		case 'Capacitor'
			Par = {'c'};
			Val = {value};
		case 'Inductor'
			Par = {'l'};
			Val = {value};
		otherwise
			error('Unknown(/not implementd) block type for auto-selection of parameter')
	end
end
if isempty(B)
	warning('No block found')
else
	for i=1:length(B)
		for j=1:length(Par)
			v = Val{j};
			if isnumeric(v)
				v = num2str(v);
			end
			set_param(B{i},Par{j},v)
		end
	end
	if nargout==0 && length(B)>1
		fprintf('The following blocks are updated:\n')
		fprintf('       %s\n',B{:})
	end
end
if nargout
	Bout = B;
	Par_out = Par;
	Val_out = Val;
end
