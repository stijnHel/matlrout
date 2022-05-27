function [D,varargout]=ReadESRI(fName,varargin)
%ReadESRI - Read ESRI Shapefile (shp + shx + dbf)
%       D=ReadESRI(fName)
% Extra options
%    [l=]ReadESRI(D,'plot',country)	- plot countries
%          counrty:
%             index (or indices)
%             name
%    P = ReadESRI(D,'getCoor',country[,...]) - gives coordinate list
%          options:
%              bXYproject
%              bCommonZ0
%              Z0
%              bFlatten
%              bAddNaN
%    A = ReadESRI(D,'calcArea',country)
%
%      D = ReadESRI('country',<country>) % finds (or tries to find) country data
%      L = ReadESRI('countrylist')	% returns a list of available countries (locally)
%      L = ReadESRI('list') % returns of available countries (externally)
%      ReadESRI('download',<country>) % downloads data for a new country


% Data locally available on:
%        borders\BEL_adm
%    origin: https://gadm.org/download_country.html
% other locations:
%         https://github.com/wmgeolab/geoBoundaries
%         https://www.geoboundaries.org/index.html#getdata

% - Add the possibility to "unrwap"?
%    if part close to -180 and other close to +180 ==> try link
%       simple case: keep parts, but just add/subtract 360 to some of them
%       nicer: merge

if ischar(fName)
	if strcmpi(fName,'country')
		country = varargin{1};
		varargout = cell(1,nargout-1);
		[D,varargout{:}] = ReadCountry(country);
		return
	elseif strcmpi(fName,'countrylist')
		T = ReadTransTable();
		for i=1:size(T,1)
			if iscell(T{i,2})
				if length(T{i,2})>1
					T{i,2} = T{i,2}{2};
				else
					T{i,2} = T{i,2}{1};
				end
			end
		end
		if nargout==0
			printstr(T(:,2));
		else
			D = T(:,2);
		end
		return
	elseif strcmpi(fName,'list')
		W = webread('https://gadm.org/download_country.html');
		X = readxml({W},'--bWarning');
		D = [X(strcmp({X.tag},'option')).data];
		D(1) = [];
		return
	elseif strcmpi(fName,'download')
		country = varargin{1};
		[~,pth] = ReadTransTable();
		W = webread('https://gadm.org/download_country.html');
		X = readxml({W},'--bWarning');
		for i=1:length(X)
			if strcmp(X(i).tag,'option') && ~isempty(X(i).data)	...
					&& any(startsWith(X(i).data,country,'IgnoreCase',true))
				tri = X(i).fields{2}(1:3);
				urlBase = 'https://geodata.ucdavis.edu/gadm/gadm4.0/shp/gadm40_%s_shp.zip';
				% this link can be extracted from W(/X)!
				%          ---> script function changeCountry
				url = sprintf(urlBase,tri);
				[~,fPth] = fileparts(url);
				filePath = fullfile(pth,fPth);
				if exist(filePath,'dir')
					error('This path already exists!')
				end
				B = urlbinread(url);
				Z = ReadZip(B);
				mkdir(filePath)
				levelMax = -1;
				fShape = '';
				for j=1:length(Z)
					fid = fopen(fullfile(filePath,Z(j).fName),'wb');
					fwrite(fid,Z(j).fUncomp);
					fclose(fid);
					[~,f,fExt] = fileparts(Z(j).fName);
					if strcmpi(fExt,'.shx')
						w = regexp(f,'_','split');
						level = str2double(w{end});
						if level>levelMax
							levelMax = level;
							fShape = fullfile(fPth,f);
						end
					end
				end
				fid = fopen(fullfile(pth,'countries.txt'),'at');
				fprintf(fid,'%s\t%s\t%s\n',fShape,tri,X(i).data{1});
				fclose(fid);
				if nargout
					D = ReadESRI('country',tri);
				end
				return
			end
		end		% for i
		error('Country not found!')
	end		% if command
end		% char input

if isstruct(fName)
	W=fName;
	if nargin<3
		country = 'all';
	else
		country = varargin{2};
	end
	switch varargin{1}
		case 'plot'
			varargout = cell(1,max(0,nargout-1));
			[L,varargout{:}]=Plot(W,country,varargin{3:end});
			if nargout
				D=L;
			end
		case 'getCoor'
			varargout=cell(1,nargout-1);
			[D,varargout{:}]=GetCoor(W,country,varargin{3:end});
		case 'calcArea'
			C=GetCoor(W,country,true,false);
			A=0;
			if isnumeric(C)
				C={C};
			end
			for i=1:length(C)
				Ci=C{i};
				if isnumeric(Ci)
					Ci={Ci};
				end
				for j=1:length(Ci)
					Z=Ci{j};
					a=0;
					for k=1:size(Z,1)-1
						p=mean(Z(k:k+1,:));
						dP=diff(Z(k:k+1,:));
						a=a+p(1)*dP(2)-p(2)*dP(1);
					end		% for k
					A=A+abs(a);
				end		% for j
			end		% for i
			D=A/2e6;	% /2 (because double A is calcuated, 1e6 for sq km)
		case 'middle'
			P = GetCoor(W,country,false,false,'-bFlatten');
			D = (min(P)+max(P))/2;
		otherwise
			error('Unknown command')
	end
	return
end

bPlot = nargout==0;
if nargin>1
	setoptions({'bPlot'},varargin{:})
end

% Read all files
fPath = fFullPath(fName,true,[],false);
if isempty(fPath)
	error('Sorry, I can''t find this country data')
end
[fpth,fnme,fext]=fileparts(fPath);
if ~any(strcmp(fext,{'.dbc','.shp','.prj','.shx'}))	% hold extension
	fnme=[fnme fext];
end
Xattr=ReadDBF(fullfile(fpth,[fnme '.dbf']));
fid=fopen(fullfile(fpth,[fnme,'.shx']));
if fid<3
	error('Can''t open the index file')
end
xIdx=fread(fid,[1 Inf],'*uint8');
fclose(fid);
fid=fopen(fullfile(fpth,[fnme,'.shp']));
if fid<3
	error('Can''t open the shape file')
end
xShp=fread(fid,[1 Inf],'*uint8');
fclose(fid);

xBigE=[16777216;65536;256;1];
xLE=[1;256;65536;16777216];

% index file
FC=double(xIdx(1:4))*xBigE;
if FC~=9994
	error('Wrong file?!')
end
if ~all(xIdx(5:24)==0)
	warning('First unused bytes in index header are expected to be zero!')
end
fLen=double(xIdx(25:28))*xBigE;
if fLen~=length(xIdx)/2
	warning('Specified length is not equal to the real length? (%d <-> %d)'	...
		,fLen*2,length(xIdx));
end
fVer=double(xIdx(29:32))*xLE;
if fVer~=1000
	warning('Version 1000 expected!')
end
shapeType_idx=double(xIdx(33:36))*xLE;
boundingbox_idx=typecast(xIdx(37:100),'double');
IDX=reshape(xBigE'*reshape(double(xIdx(101:end)),4,[]),2,[]);

% Main File header
FC=double(xShp(1:4))*xBigE;
if FC~=9994
	error('Wrong file?!')
end
if ~all(xShp(5:24)==0)
	warning('First unused bytes in header are expected to be zero!')
end
fLen=double(xShp(25:28))*xBigE;
if fLen~=length(xShp)/2
	warning('Specified length is not equal to the real length? (%d <-> %d)'	...
		,fLen*2,length(xShp));
end
fVer=double(xShp(29:32))*xLE;
if fVer~=1000
	warning('Version 1000 expected!')
end
shapeType=double(xShp(33:36))*xLE;
ix=100;
boundingbox=typecast(xShp(37:ix),'double');

if shapeType~=shapeType_idx||any(boundingbox~=boundingbox_idx)
	warning('Index-file and shape file different?!')
end

unknownTypes=[];

nRecs=0;
Records=struct('type',cell(1,size(Xattr.X,1)),'data',[]);
while ix<length(xShp)
	nRecs=nRecs+1;
	rNr=double(xShp(ix+1:ix+4))*xBigE;
	cLen=double(xShp(ix+5:ix+8))*xBigE;
	if rNr~=nRecs
		warning('Unexpected record number (%d <-> %d)',rNr,nRecs)
	end
	ix=ix+8;
	ixn=ix+cLen*2;
	rec=xShp(ix+5:ixn);
	
	Records(nRecs).type=double(xShp(ix+1:ix+4))*xLE;
	switch Records(nRecs).type
		case 0	% null shape
			data=[];
		case 1	% point
			data=typecast(rec,'double');
		case 5	% polygon
			Box=typecast(rec(1:32),'double');
			nParts=double(rec(33:36))*xLE;
			nPts=double(rec(37:40))*xLE;
			parts=xLE'*double(reshape(rec(41:40+4*nParts),4,nParts));
			points=reshape(typecast(rec(41+4*nParts:end),'double'),2,[])';
			if nPts~=size(points,1)
				warning('Wrong number of points?')
			end
			data=var2struct(Box,parts,points);
		otherwise
			if ~any(unknownTypes==Records(nRecs).type)
				warning('Unknown type (%d)',Records(nRecs).type)
				unknownTypes(1,end+1)=Records(nRecs).type; %#ok<AGROW>
			end
			data=rec;
	end
	Records(nRecs).data=data;
	
	ix=ixn;
end
if nRecs~=size(Xattr.X,1)
	warning('Different numbers of records in attribute- and main file?! (%d <-> %d)'	...
		,nRecs,size(Xattr.X,1))
	Records=Records(1:nRecs);
end
if all([Records.type]==shapeType)
	Records=[Records.data];
end
D=var2struct(shapeType,boundingbox,Records,Xattr,IDX);

if bPlot
	Plot(D,'all');
end

function [L,varargout] = Plot(W,country,varargin)
varargout = cell(1,max(0,nargout-1));
[C,varargout{:}] = GetCoor(W,country,varargin{:},'-bAddNaN');
if isnumeric(C)
	C = {C};	% back to cell...
end
L=zeros(1,length(C));
nxtPlot=get(gca,'NextPlot');
for iC=1:length(C)
	Pi = C{iC};
	if iscell(Pi)
		Pi = cat(1,Pi{:});
	end
	Pi(end,:) = [];	% remove the last NaNs
	L(iC)=plot(Pi(:,1),Pi(:,2));
	if iC==1
		grid
		hold on
	end
end
set(gca,'NextPlot',nxtPlot)

function [Z,Ic,Nc,Z0] = GetCoor(W,country,bXYproject,bCommonZ0,varargin)
if nargin>2 && ischar(bXYproject)
	if nargin>3
		options = [{bXYproject,bCommonZ0},varargin];
	else
		options = {bXYproject};
	end
	bXYproject = [];
	bCommonZ0 = [];
else
	options = varargin;
end
Z0=[];
if nargin<3
	bXYproject = [];
end
if nargin<4
	bCommonZ0 = [];
end
[bFlatten] = false;
[bAddNaN] = [];
[Plimit] = [];
[CountryField] = [];
[CfieldOut] = [];
[bToggleXY] = false;
[bPosLong] = false;
[bNegLong] = false;
if ~isempty(options)
	setoptions({'bXYproject','bCommonZ0','Z0','bFlatten','bAddNaN'	...
		,'Plimit','CountryField','CfieldOut','bToggleXY','bPosLong','bNegLong'	...
		},options{:})
	if ~isempty(Z0)&&isempty(bCommonZ0)
		bCommonZ0 = true;
	end
end
if isempty(bXYproject)
	bXYproject=false;
end
if isempty(bCommonZ0)
	bCommonZ0=true;
elseif ~isscalar(bCommonZ0)
	Z0=bCommonZ0;
	bCommonZ0=true;
end
if isempty(bAddNaN)
	bAddNaN = bFlatten;
end

if ischar(country)
	if strcmpi(country,'all')
		country=1:length(W.Records);
	else
		if ischar(country)
			country={country};
		end
	end
end
Ic = country;
iFieldOut = [];
if iscell(country) || nargout>2
	Nc = cell(size(country));
	AttrFields = {W.Xattr.recordDef.name};
	if ischar(CountryField) && ~isempty(CountryField)
		if strcmpi(CountryField,'extended')
			CountryField = {'SOVEREIGNT','NAME',AttrFields{startsWith(AttrFields,'name_','IgnoreCase',true)}};
		else
			CountryField = {CountryField};
		end
	end
	if isempty(CountryField)
		CountryField = {'SOVEREIGNT','NAME_4','NAME_3','NAME_2','NAME_1'};
	end
	if ~isempty(CfieldOut)
		% Add these fields in front of "search fields" and find indices
		if ischar(CfieldOut)
			CfieldOut = {CfieldOut};
		end
		iFieldOut = zeros(size(CfieldOut));
		for i=1:length(CfieldOut)
			iField1 = find(strcmp(CfieldOut{i},AttrFields),1);
			if isempty(iField1)
				warning('Requested name-field is not found! (%s)',CfieldOut{i})
			else
				iFieldOut(i) = iField1;
			end
			B = strcmpi(CfieldOut{i},CountryField);
			if any(B)
				CountryField(B) = [];
			end
		end
		CountryField = [CfieldOut(:)' CountryField(:)'];
	end
	if iscell(CountryField)
		iField = zeros(1,length(CountryField));
		for i=1:length(CountryField)
			iField1 = find(strcmpi(CountryField{i},AttrFields),1);
			if ~isempty(iField1) && ischar(W.Xattr.X{1,iField1})
				iField(i) = iField1;
			end
		end
		iField(iField==0) = [];
		if isempty(iField)
			error('The field to find the country is not found!')
		end
	elseif isnumeric(CountryField)
		iField = CountryField;
	end
end
if iscell(country)
	for i=1:length(country)
		for j=1:length(iField)
			iC = find(startsWith(W.Xattr.X(:,iField(j)),country{i},'IgnoreCase',true));
			if ~isempty(iC)
				iField = iField(j);	% (!!!)next countries will use this field!
				break
			end
		end
		country{i} = reshape(iC,1,[]);
		if nargout>2
			Nc{i} = W.Xattr.X{iC,iField};
		end
	end
	if nargout>1
		Ic = country;
		if isscalar(Ic)
			Ic = Ic{1};
		end
		if ~isempty(CfieldOut) && any(iFieldOut==0)
			iFieldOut(iFieldOut==0) = iField;
		elseif isempty(CfieldOut)
			iFieldOut = iField;
		end
		if nargout>2
			Nc = W.Xattr.X([country{:}],iFieldOut);
		end
	end
	country=[country{:}];
	if isempty(country)
		error('No country found!')
	end
elseif nargout>2
	Nc = W.Xattr.X(country,iField(1));
end		% iscell(country)
Z=cell(1,length(country));
for iC=1:length(country)
	i=country(iC);
	P=W.Records(i).points;
	I=[W.Records(i).parts,size(P,1)];
	if I(end)==I(end-1)
		I(end)=[];
	end
	Z{iC}=cell(1,length(I)-1);
	for j=1:length(I)-1
		Pi=P(I(j)+1:I(j+1),:);
		if bPosLong
			if any(Pi(:,1)<0)
				if any(Pi(:,1)>0)
					warning('Sorry, but parts Long>0 and other Long<0!')
				else
					Pi(:,1) = Pi(:,1)+360;
				end
			end
		elseif bNegLong
			if any(Pi(:,1)>0)
				if any(Pi(:,1)<0)
					warning('Sorry, but parts Long>0 and other Long<0!')
				else
					Pi(:,1) = Pi(:,1)-360;
				end
			end
		end
		if bXYproject
			if ~bCommonZ0 || isempty(Z0)
				[Pi,~,~,Z0]=ProjGPS2XY(Pi(:,[2 1]));
			else
				Pi=ProjGPS2XY(Pi(:,[2 1]),'Z1',Z0);
			end
		end
		if ~isempty(Plimit)
			Pi = LimitP(Pi,Plimit);
		end
		if bAddNaN && ~isempty(Pi)
			Pi(end+1,:) = [NaN,NaN];
		end
		Z{iC}{j} = Pi;
	end
	if isscalar(Z{iC})
		Z{iC} = Z{iC}{1};
	elseif bFlatten
		Z{iC} = cat(1,Z{iC}{:});
	end
end
if bToggleXY
	for i=1:length(Z)
		Z{i} = Z{i}(:,[2 1]);
	end
end
if isscalar(Z)
	Z = Z{1};
elseif bFlatten
	Z = cat(1,Z{:});
end

function P = LimitP(P,Plimit)
%LimitP - Limit P within limits
%     P = LimitP(P,Plimit)
%             P = [X , Y]
%             Plimit = [Xmin,Xmax,Ymin,Ymax]

Bin = P(:,1)>=Plimit(1) & P(:,1)<=Plimit(2)	...
	& P(:,2)>=Plimit(3) & P(:,2)<=Plimit(4);
if all(Bin)
	return
elseif ~any(Bin)
	P = zeros(0,2);
	return
end
% Find first point
if ~Bin(1)
	i = find(Bin,1);
	P(1:i-2,:) = [];
	Bin(1:i-2) = [];
	P = BorderPoint(P,2,1,Plimit);
	Bin(1) = true;
end

% Find Last point
if ~Bin(end)
	i = find(Bin,1,'last');
	P = BorderPoint(P,i,i+1,Plimit);
	P(i+2:end,:) = [];
	Bin(i+2:end) = [];
	Bin(end) = true;
end
i = 2;
while i<length(Bin)
	if ~Bin(i)
		i1 = i+1;
		while ~Bin(i1)
			i1 = i1+1;
		end
		if i1-i==1	% only 1 point out the limits
			% add 2 points
			P = P([1:i,i,i:end],:);
			Bin = Bin([1:i,i,i:end]);
			i1 = i1+2;
		elseif i1-i==2	% w points out
			% add ont point
			P = P([1:i,i:end],:);
			Bin = Bin([1:i,i:end]);
			i1 = i1+1;
		end
		% replace 3 points by:
		%       leaving point, NaN, entering point
		P = BorderPoint(P,i-1,i,Plimit);
		P = BorderPoint(P,i1,i1-1,Plimit);
		P(i+1,:) = NaN;
		P(i+2:i1-2,:) = [];
		Bin(i+2:i1-2) = [];
		i = i+3;
	else
		i = i+1;
	end
end

function P = BorderPoint(P,idxIn,idxOut,Plimit)
if P(idxOut)<Plimit(1)
	r = (Plimit(1)-P(idxOut))/(P(idxIn)-P(idxOut));
	P(idxOut,:) = P(idxOut,:) + r*(P(idxIn,:)-P(idxOut,:));
elseif P(idxOut)>Plimit(2)
	r = (Plimit(2)-P(idxOut))/(P(idxIn)-P(idxOut));
	P(idxOut,:) = P(idxOut,:) + r*(P(idxIn,:)-P(idxOut,:));
end
if P(idxOut,2)<Plimit(3)
	r = (Plimit(3)-P(idxOut,2))/(P(idxIn,2)-P(idxOut,2));
	P(idxOut,:) = P(idxOut,:) + r*(P(idxIn,:)-P(idxOut,:));
elseif P(idxOut,2)>Plimit(4)
	r = (Plimit(4)-P(idxOut,2))/(P(idxIn,2)-P(idxOut,2));
	P(idxOut,:) = P(idxOut,:) + r*(P(idxIn,:)-P(idxOut,:));
end

function [X,varargout] = ReadCountry(country)
pth = FindFolder('borders',0,'-bAppend');
CountryData = ReadTransTable();
if any(country=='#')
	P = regexp(country,'#','split');
	country = P{1};
	level = str2double(P{2});
	if isnan(level)
		error('bad detail level number?! (%s)',P{2})
	end
else
	level = -1;
end
X = [];
for iC = 1:size(CountryData,1)
	if any(startsWith(CountryData{iC,2},country,'IgnoreCase',true))
		countryPath = CountryData{iC};
		countryName = CountryData{iC,2};
		if iscell(countryName)
			countryName = countryName{1};
		end
		country = countryName;
		if level>=0
			iNr = find(countryPath=='_',1,'last');
			countryPath = [countryPath(1:iNr),num2str(level)];
		end
		X = ReadESRI(fullfile(pth,countryPath));
		break
	end
end
if isempty(X)
	error('Sorry, country not found!')
end
varargout = {country};
