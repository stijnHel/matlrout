function [e,ne,de,e2,gegs,D,Ds]=leesVAtdms(fName,varargin)
%leesVAtdms - Reads a measurement from VA toolbox - TDMS version
%    [e,ne,de,e2,gegs,varargout]=leesVAtdms(fName,...);
%
%  Most is done by leesTDMS (see that function for in/out).
%  Additions:
%    Scale to the "right units": (currently only for acceleration)
%          units 'g','m/s^2','m/s2' are all converted to the default ('g')
%
% Possibility to change default units:
%       ...leesVAtdms(fName,'defUnits',{<type>,<default unit>},...)
%             <type>: name of "type of unit", currently only 'acc' (for acceleration)
%             <default unit>: (currently 'g' for 'acc')
% It's also possible to disable the conversion to "default units":
%       ...leesVAtdms(fName,'useDefaultUnits',false,...)

useDefaultUnits = true;
units = struct('name','acc','default','g','units',{{'g',9.80665;'m/s^2',1;'m/s2',1}});
defUnits = [];	% can overrule default in units (to allow change of
			% default without needing to give the full units-data

[~,~,options] = setoptions([2,0],{'useDefaultUnits','units','defUnits'},varargin{:});
if iscell(defUnits)
	for i=1:size(defUnits,1)
		units = AdaptDefaults(units,defUnits{i,:});
	end
elseif isstruct(defUnits)
	for i=1:length(defUnits)
		units = AdaptDefaults(units,defUnits(i).name,defUnits(i).default);
	end
elseif ~isempty(defUnits)
	error('Wrong input for default units')
end		% ~isempty(defUnits)

[e,ne,~,e2,gegs,~,Ds]=leesTDMS(fName,options{1:2,:});
if isempty(Ds)
	e=[];
	ne=[];
	de=[];
	e2=[];
	gegs=struct('dt',1,'comments','');
	D=[];
	Ds=[];
	return
end
iS=find(strcmp('settings',{Ds.group.name}));
if isempty(iS)
	error('No settings found!')
end
bT=strcmp('type',{Ds.group(iS).channel.name});
bD=strcmp('data',{Ds.group(iS).channel.name});
if ~any(bT)||~any(bD)
	error('No type/data found in settings')
end
D=readLVtypeString(Ds.group(iS).channel(bT).data);
Dx=readLVtypeString(D,Ds.group(iS).channel(bD).data);
gegs.signals=[Dx{1}.channel];
S=gegs.signals;
if isfield(S,'units')
	de={S.units};
	if ~isempty(e)
		if iscell(e)
			warning('LEESVATDMS:TDMScellOutput','Cell output from leesTDMS?')
			e=[e{:}];
		end
		bSIunitsOK = false;
		for i=1:length(S)
			e(:,i) = e(:,i)/S(i).sensitivity;
			if ischar(useDefaultUnits)
				if strcmpi(useDefaultUnits,'SI')
					if ~bSIunitsOK
						% make sure 'g' means acceleration, not 0.001 kg !!
						if ~isequal(unitcon('test','g'),[0 1 -2 0 0])
							unitcon('addunit','g','L1T-2',9.80665)
						end
						bSIunitsOK = true;
					end
					[b,v,sUnit] = unitcon('test',de{i});
					if ~isempty(b) && v~=1
						e(:,i) = e(:,i)*v;
					end
					de{i} = sUnit;
				else
					error('Wrong use! (useDefaultUnits - %s)',useDefaultUnits)
				end
			elseif useDefaultUnits
				for j = 1:length(units)
					Bunit = strcmp(de{i},units(j).units(:,1));
					if any(Bunit) && ~strcmp(de{i},units(j).default)
						Bdef = strcmp(units(j).default,units(j).units(:,1));
						factor = units(j).units{Bunit,2}/units(j).units{Bdef,2};
						e(:,i) = e(:,i)*factor;
						de{i} = units(j).default;
					end
				end
			end		% if useDefaultUnits
		end		% for i
	end		% not empty e
elseif isfield(S,'signals')&&isfield(S,'sampleRate')
	% Multi-sample rate version of VA-toolbox
	Sets={S.name_set};
	e=cell(1,length(S));
	e2=[];
	ne=e;
	Gn={Ds.group.name};
	de=ne;
	gegs.dt=zeros(1,length(e));
	for iS=1:length(ne)
		if ~isempty(S(iS).signals)
			gegs.dt(iS)=1/S(iS).sampleRate;
			Si=[S(iS).signals.Channel_control];
			Si=Si([Si.enable]>0);
			S(iS).signals=Si;
			iG=find(strcmp(Sets{iS},Gn));
			for iC=1:length(Si)
				X=Ds.group(iG).channel(iC).data;
				X=(X+Si(iC).offset__V_)/Si(iC).sens__V_Unit_;
				Ds.group(iG).channel(iC).data=X;
			end
			e{iS}=[Ds.group(iG).channel.data];
			ne{iS}={Si.name};
			de{iS}={Si.Unit};
		end
	end
else
	warning('LEESVATDMS:unknownTDMStype','Unknown type of TDMS-VA-measurement')
end
fn=fieldnames(Ds.properties);
for i=1:length(fn)
	gegs.(fn{i})=Ds.properties.(fn{i});
end

function units = AdaptDefaults(units,name,default)
B = strcmpi({units.name},name);
if any(B)
	units(B).default = default;
else
	warning('Unit type "%s" is not known!  Default wasn''t changed.',name)
end
