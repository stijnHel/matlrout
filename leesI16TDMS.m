function [e,ne,de,e2,gegs,D]=leesI16TDMS(fn,varargin)
%leesI16TDMS - Reads tdms-file with 16-bit integer data
%   specific data format made for
%      1. humidity test
%         [e,ne,de,e2,gegs]=leesI16TDMS(fn);
%      2. HSmeasTDMS

iDecimate=0;
decimFun=[];
options=varargin;

if ~isempty(options)
	[~,~,options]=setoptions([2,0],{'iDecimate','decimFun'},options{:});
end

[e,ne,de,e2,gegs,~,D]=leesTDMS(fn,options{:});
if isfloat(e)
	warning('LEESI16TDMS:NoInt','No integer values - result of leesTDMS given')
	return
end
groups={D.group.name};
iScale=find(strcmp('scale',groups));
if ~isempty(iScale)
	rmFields={'measInfo','cGroups','nData'};
	for i=1:length(rmFields)
		if isfield(gegs,rmFields{i})
			gegs=rmfield(gegs,rmFields{i});
		end
	end
	props=fieldnames(D.properties);
	for i=1:length(props)
		gegs.(props{i})=D.properties.(props{i});
	end
	if length(D.group)>2
		warning('LEESI16TDMS:multiGroup','!!!multiple groups!!!')
	end
	iMeas=3-iScale;
	gegs.chanInfo=D.group(iScale).channel;
	gegs.dt=1/D.properties.realRate;
	if iDecimate>1
		gegs.dt=gegs.dt*iDecimate;
	end
	ne={D.group(iMeas).channel.name};
	de=ne;
	de(:)={'V'};
	e=cell(1,length(ne));
	e2=[];
	if ~isequal({D.group(iScale).channel.name},ne)
		fprintf('Scale:\n');
		printstr({D.group(iScale).channel.name})
		fprintf('Meas:\n')
		printstr({D.group(iMeas).channel.name})
		error('Wrong combination of channels (in this simplistic function)')
	end
	tB=lvtime;
	tB(1,length(ne))=tB;
	N=zeros(1,length(ne));
	if isfield(D.group(iMeas).properties,'wf_start_time')
		t0=lvtime(D.group(iMeas).properties.wf_start_time([4 3 2 1]));
	else
		t0=[];
	end
	for i=1:length(D.group(iScale).channel)
		if isfield(D.group(iMeas).channel(i).properties,'wf_start_time')
			tB(i)=lvtime(D.group(iMeas).channel(i).properties.wf_start_time([4 3 2 1]));
			if isempty(t0)
				t0=tB(i);
			end
		end
		if iDecimate>1
			%!!!!!!!see leesI16TDMS0!!!!!!!!
			error('not ready')
		else
			e{i}=double(D.group(iMeas).channel(i).data);
			%!!!!
			if sum(e{i}<-25000|e{i}>25000)>length(e{i})*.9
				%probably signed rather than unsigned!!
				e{i}=e{i}+65536*(e{i}<0);
			end
		end
		N(i)=length(e{i});
		if isempty(decimFun)
			e{i}=polyval(D.group(iScale).channel(i).data(end:-1:1)',e{i});
		end
	end
	gegs.tBlocks=tB;
	gegs.t0=t0;
	if all(N==N(1))
		e=[e{:}];
	end
elseif isfield(gegs.chanInfo,'props2')&&isfield(gegs.chanInfo(1).props2,'Vmin')
	e=double(e);
	for i=1:size(e,2)
		Vmin=gegs.chanInfo(i).props2.Vmin;
		Vmax=gegs.chanInfo(i).props2.Vmax;
		e(:,i)=e(:,i)*((Vmax-Vmin)/65536)+Vmin;
	end
elseif isfield(gegs.chanInfo,'properties')&&isfield(gegs.chanInfo(1).properties,'Vmin')
	e=double(e);
	for i=1:size(e,2)
		Vmin=gegs.chanInfo(i).properties.Vmin;
		Vmax=gegs.chanInfo(i).properties.Vmax;
		e(:,i)=e(:,i)*((Vmax-Vmin)/65536)+Vmin;
	end
else
	error('Wrong TDMS-file')
end
