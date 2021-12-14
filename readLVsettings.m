function S=readLVsettings(fn)
%readLVsettings - Read settings in labView files - saved by GetSettings.vi
%   S=readLVsettings(fn)

global LVDEBUG_raw

bFile=true;
bFileOpened=false;
fid=0;
if isstruct(fn)
	if isfield(fn,'name')
		fn=fn.name;
	elseif isfield(fn,'group')
		bFile=false;
		iType=2;
		D=fn;
	else
		error('Unknown input (struct)')
	end
elseif isnumeric(fn)||isa(fn,'file')
	bFile=false;
	iType=1;
	fid=fn;
end
if bFile
	[~,~,fext]=fileparts(fn);
	switch lower(fext)
		case '.tdms'
			iType=2;
		case {'.bin','.cfg'}
			iType=1;
		case ''	% tdms supposed
			iType=2;
		otherwise
			error('Unknown type')
	end
end

if iType==1	% binary file (only settings)
	if fid==0
		fid=file(fn,'r','ieee-be');
		bFileOpened=true;
	end
	n=fread(fid,1,'uint32');
	S=struct('VIname',cell(1,n),'controls',[]);
	for i=1:n
		n=fread(fid,1,'uint32');
		if isempty(n)
			fclose(fid);
			error('Error reading the settings file')
		end
		T=fread(fid,n,'*int16');
		if n~=length(T)
			fclose(fid);
			error('Error reading the settings file')
		end
		n=fread(fid,1,'uint32');
		if isempty(n)
			fclose(fid);
			error('Error reading the settings file')
		end
		D=fread(fid,n,'*uint8');
		if n~=length(D)
			fclose(fid);
			error('Error reading the settings file')
		end
		T=readLVtypeString(T);
		LVDEBUG_raw(i).T=T;
		A=lvData2struct(readLVtypeString(T,D));
		LVDEBUG_raw(i).A=A;
		S(i).VIname=A.VIname;
		S(i).controls=struct('Name',{A.controls.Name},'data',[]);
		for j=1:length(S(i).controls)
			d1=A.controls(j).Variant_Data.dVal;
			if iscell(d1)&&length(d1)>1&&isstruct(d1{1})
				d1=TryStructArray(d1);
			end
			S(i).controls(j).data=d1;
		end
	end		% for
	if bFileOpened
		fclose(fid);
	end
else	% (iType==2) TDMS file with settings
	if bFile
		D=leesTDMS(fn,'bRaw',-1);
	end
	B=false(1,length(D.group));
	S=struct('VIname',cell(1,length(B)),'controls',[]);

	LVDEBUG_raw=struct('T',cell(1,length(B)),'A',[]);

	for i=1:length(B)
		G=D.group(i).name;
		if strncmpi(G,'settings',8)
			B(i)=true;
			Gnr=str2double(G(9:end));
			if ~isnan(Gnr)
				CN={D.group(i).channel.name};
				bT=strcmp('type',CN);	% normally the first
				bD=strcmp('data',CN);	% normally the second
				if sum(bT)~=1||sum(bD)~=1
					error('Can''t extract data!')
				end
				T=readLVtypeString(D.group(i).channel(bT).data);
				LVDEBUG_raw(i).T=T;
				A=lvData2struct(readLVtypeString(T,D.group(i).channel(bD).data));
				LVDEBUG_raw(i).A=A;
				S(i).VIname=A.VIname;
				S(i).controls=struct('Name',{A.controls.Name},'data',[]);
				for j=1:length(S(i).controls)
					d1=A.controls(j).Variant_Data.dVal;
					if iscell(d1)&&length(d1)>1&&isstruct(d1{1})
						d1=TryStructArray(d1);
					end
					S(i).controls(j).data=d1;
				end
			end
		end		% if settings
	end		% for i
	S=S(B);
end		% TDMS

function d=TryStructArray(d)
fn=fieldnames(d{1});
for i=2:length(d)
	if ~isstruct(d{i})
		return
	end
	fn1=fieldnames(d{i});
	if ~isequal(fn,fn1)
		return
	end
end
d=cat(2,d{:});
