function [t,U,param]=PLW2ML(fullfilename,info)
% PLW2ML converts PLW-files (PicoTech Picologger) to MATLAB variables
% [t,U,param]=PLW2ML(filename,info)
% filename is the full filename (with path and extension .plw)
% info is an optional parameter that if set to 1 displays
% information about the file being read
% t is the time vector
% U is the output (voltage, temperature etc. vector/matrix)
% param is a structure containing other information,
% for example param.PLS is a settings file (first part is strange)
%
% A typical use of the plw2ml function is as follows:
%
% [t,U]=plw2ml('c:\measure2\rotfungi\sl0921A.plw');
% plot(t,U(:,1))
%
% A more advanced way is to use it on all files of a certain sort,
% for example to plot the data in all files starting with 'sl' in one directory:
%
% presdir=cd; %present directory
% dirvec=dir; %Find all filenames in directory
% for k=1:length(dirvec) %go through all files
% filename=dirvec(k).name; %put filename in filename-string
% if length(filename)>5 % do not evaluate '-' '--' and other strange things in dirvec
% if strcmp(filename(1:2),'SL') %only if it is a SLXXXX- file
% fullfilename=[presdir,'\',filename]; %full filename, incl. path
% [t,U]=PLW2ML(fullfilename);
% plot(t,U);
% end
% end
% end
%
% An even more automated evaluation method can be made by looking up,
% e.g., sample identifiers in the param.PLS-variable (if they have
% been entered into PLW before the start of the measurements). In the
% following example samples (channels) are named HDMXX, where XX is a
% sample number that the program finds and uses to sort the measurements
%
% k=k+1;
% indstart=findstr('MultiConverter',param.PLS); %---Find line before channel identifier
% indname=findstr('HDM',param.PLS(indstart:end)); %---In this example sample numbers follow HDM-string
% %find all places in PLS-file starting with 'Name=HDM' (that are followed by the sample number)
% for p=1:length(indname) %for all measurements found in the file
% sample_no(k)=str2num(param.PLS(indstart+indname(p)+2:indstart+indname(p)+3)); %extract sample number
% end
%
% Lars Wadsö, Building Materials, Lund University, Sweden 28 Oct 2004

if nargin==0;[fn,pn]=uigetfile('*.*','Open a measurement file');fullfilename=[pn,fn];info=0;end
if nargin==1;info=0;end
if isstruct(fullfilename)||iscell(fullfilename)
	A=cell(length(fullfilename),3);
	if iscell(fullfilename)
		L=fullfilename;
	else
		L={fullfilename.name};
	end
	for i=1:length(L)
		[A{i,:}]=PLW2ML(L{i},info);
		t0=A{i,3}.start_date+A{i,3}.start_time/86400+366;
		A{i}=A{i}/86400+t0;
	end
	t=cat(1,A{:,1});
	U=cat(1,A{:,2});
	param=[A{:,3}];
	return
end
if ~strcmpi(fullfilename(end-3:end),'.plw')
	error('PLW2ML can only open files with extension .plw or .PLW');
end
fid=fopen(fullfilename); %open file for reading
if fid<3
	fid=fopen(zetev([],fullfilename));
	if fid==-1;error('File could not be opened');end
end
param.header_bytes=fread(fid,1,'ushort'); %read first line of PLW-HEADER (the end of the file contains a partial explanation of how a PLW file is built up)
param.signature=fread(fid,[1 40],'*char'); %etc
param.version=fread(fid,1,'uint32');
if info;disp(['PLW file version ',int2str(param.version)]);end
switch param.version
	case 1
		antal_parametrar=50;
		antal_notes=200;
	case 2
		antal_parametrar=50; %100;
		antal_notes=200;
	case {3,4,5}	% (5) added
		antal_parametrar=250;
		antal_notes=1000;
	otherwise
		antal_parametrar=250;
		antal_notes=1000;
		warning('PLW2ML:UnkownVersion','Unknown version (%d)!!',param.version)
end
param.no_of_parameters=fread(fid,1,'uint32');
if info;disp(['Number of parameters ',int2str(param.no_of_parameters)]);end
param.parameters=fread(fid,antal_parametrar,'uint16'); %says 50 in PLW manual
if info;disp(['Parameters: ',int2str(param.parameters(1:param.no_of_parameters)')]);end
% param.sample_no=0;
% while param.sample_no==0
param.sample_no=fread(fid,1,'uint32'); %=following
% end
if info;disp(['Number of samples: ',int2str(param.sample_no)]);end
param.no_of_samples=fread(fid,1,'uint32'); %=previous %number of samples
if info;disp(['No OF SAMPLES: ',int2str(param.no_of_samples)]);end
param.max_samples=fread(fid,1,'uint32');
if info;disp(['MAX Number of samples: ',int2str(param.max_samples)]);end
param.interval=fread(fid,1,'uint32'); %measurement interval
if info;disp(['Interval: ',int2str(param.interval)]);end
param.interval_units=fread(fid,1,'uint16'); %interval units
if info;disp(['Interval_units: ',int2str(param.interval_units)]);end
switch param.interval_units
	case 0;units=' fs';
	case 1;units=' ps';
	case 2;units=' ns';
	case 3;units=' us';
	case 4;units=' ms';
	case 5;units=' s';
	case 6;units=' min';
	case 6;units=' h';
	otherwise;units=' with unknown unit';
end
if info;disp(['Sampling interval: ',num2str(param.interval),units]);end
param.trigger_sample=fread(fid,1,'uint32');
param.triggered=fread(fid,1,'uint16');
param.first_sample=fread(fid,1,'uint32');
param.sample_bytes=fread(fid,1,'uint32');
param.settings_bytes=fread(fid,1,'uint32');
param.start_date=fread(fid,1,'uint32'); %start date (days since start of year 0)
if info;disp(['Start date (days since 1 jan year 0) ',int2str(param.start_date)]);end
param.start_time=fread(fid,1,'uint32'); %start time (seconds since start of day)
if info;disp(['Start time (secondas since beginning of day) ',int2str(param.start_time)]);end
param.minimum_time=fread(fid,1,'int32');
param.maximum_time=fread(fid,1,'int32');
param.notes=fread(fid,antal_notes,'uchar')';
param.current_time=fread(fid,1,'int32');
param.spare=fread(fid,78,'uint8');
%read DATA
t = zeros(param.no_of_samples,1);
U = zeros(param.no_of_samples,param.no_of_parameters);
for p=1:param.no_of_samples %here the samples are read
	t(p)=fread(fid,1,'uint')'; %time
	U(p,:)=fread(fid,[1 param.no_of_parameters],'float'); %no_of_parameters of data
end
%read PLS-file appended at end of PLW-file (see the end of this file for an explanation)
param.PLS=char(fread(fid,inf,'uchar'))'; %here the PLS-file is read (the first part contains strange text)
if info;disp('The param.PLS file with infomation about the run can be retreived from a third output argument');end
fclose(fid); %close file
if nargout>2
	I=RetrieveInfo(param.PLS);
	if ~isfield(I{1},'sectionName')
		I(1)=[];
	end
	II=catstruct(I);
	S={II.sectionName};
	bPar=strncmp(S,'Parameter ',length('Parameter '));
	param.I0=I(~bPar);
	I=catstruct(I(bPar));
	%??is there somewhere a link to the start of the usefull header?
	%   there are duplications...
	for i=1:length(I)
		I(i).sectionName=sprintf('Parameter %2d'	...
			,sscanf(I(i).sectionName,'Parameter %d'));
	end
	[~,i]=unique({I.sectionName});
	I=I(i);
	param.I=I;
end

function I=RetrieveInfo(PLS)
iCR=[0 find(PLS==13)];
n=sum(PLS(1:end-1)==10&PLS(2:end)=='[');
I=cell(1,n);
nI=0;
I1=struct();
bI1=false;
for iL=1:length(iCR)-1
	l=strtrim(PLS(iCR(iL)+1:iCR(iL+1)-1));
	if isempty(l)
	elseif l(1)=='['&&l(end)==']'
		if bI1
			bI1=false;
			nI=nI+1;
			I{nI}=I1;
			I1=struct('sectionName',strtrim(l(2:end-1)));
		end
	elseif any(l=='=')
		k=find(l=='=');
		p=strtrim(l(1:k-1));
		v=strtrim(l(k+1:end));
		vv=str2double(v);
		if ~isnan(vv)
			v=vv;
		end
		I1.(p)=v;
		bI1=true;
	end
end
if bI1
	nI=nI+1;
	I{nI}=I1;
end
I=I(1:nI);
