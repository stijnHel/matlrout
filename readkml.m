function X=readkml(fn,bDirect)
%readkml  - Reads kml- and kmz-files (Google maps coordinates files)
%   A writekml exist for matlab, but not a read_kml.
%
%   X=readkml(fn);

% uses readxml (because of some problems, not used matlab-xmlread)

if isa(fn,'uint8')
	fn={char(char(fn))};
elseif nargin>1&&~isempty(bDirect)&&bDirect
	fn={fn};
else
	if isstruct(fn)	% directory record
		fn=fn.name;
	elseif ~ischar(fn)
		error('Wrong input type!')
	end
	if ~exist(fn,'file')
		fn=fFullPath(fn);
	end
	[~,~,fext]=fileparts(fn);
	if strcmpi(fext,'.kmz')	% compessed
		D=ReadZip(fn);
		fn={char(D.fUncomp)};
	end
end
Xxml=readxml(fn);
tags={Xxml.tag};
iC=find(strcmp('coordinates',tags)|strcmp('gx:coord',tags));
iN=find(strcmp('name',tags));
iT=find(strcmp('when',tags));
X=struct('t',[],'name',cell(1,length(iC)),'coor',[]);
iiN=0;
iiT=0;
iiNn=1;
iiTn=1;
for i=1:length(iC)
	bN=false;
	while iiNn<=length(iN)&&iN(iiNn)<iC(i)
		iiN=iiNn;
		iiNn=iiNn+1;
		bN=true;
	end
	if bN
		name=Xxml(iN(iiN)).data;
		X(i).name=name;
	end
	bT=false;
	while iiTn<=length(iT)&&iT(iiTn)<iC(i)
		iiT=iiTn;
		iiTn=iiTn+1;
		bT=true;
	end
	if bT
		st=Xxml(iT(iiT)).data;
		if iscell(st)
			st=st{1};
		end
		if ischar(st)&&~isempty(st)
			t=sscanf(st,'%d-%d-%dT%d:%d:%g');
			X(i).t=datenum(t(:)');
		end
	end
	D=Xxml(iC(i)).data;
	if ~isempty(D)
		s=D{1};
		% determine number of coordinates (2 or 3)
		w1=sscanf(s,'%s',1);
		nC=sum(w1==',')+1;
		s(s==',')=' ';
		X(i).coor=sscanf(s,'%g',[nC Inf])';
	end
end
