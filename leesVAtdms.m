function [e,ne,de,e2,gegs,D,Ds]=leesVAtdms(fName,varargin)
%leesVAtdms - Reads a measurement from VA toolbox - TDMS version
%    [e,ne,de,e2,gegs,varargout]=leesVAtdms(fName,...);
%
%  Most is done by leesTDMS (see that function for in/out).
%  Additions:
%    Scale to the right units

[e,ne,~,e2,gegs,~,Ds]=leesTDMS(fName,varargin{:});
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
		for i=1:length(S)
			switch de{i}
				case 'g'
					e(:,i)=e(:,i)/S(i).sensitivity;
				case {'m/s2','m/s^2'}
					e(:,i)=e(:,i)/(S(i).sensitivity*9.80665);
					de{i}='g';
				otherwise
					e(:,i)=e(:,i)/S(i).sensitivity;
			end
		end
	end
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
