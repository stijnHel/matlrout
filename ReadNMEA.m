function [X,uC,P,t1]=ReadNMEA(fName,X,varargin)
%ReadNMEA - Read NMEA file (for GPS log)
%      X=ReadNMEA(fName)
% This function can also be used to interpret a nmea-line (or multiple lines):
%     X = ReadNMEA([],<nmea-line(s)>);

if ~isempty(fName)||nargin<2
	if isstruct(fName)
		fName=fName.name;
	end
	if ~exist(fName,'file')
		fName=zetev([],fName);
		if ~exist(fName,'file')
			error('Can''t open the file')
		end
	end
	fid=fopen(fName);
	x=fread(fid,[1 Inf],'*char');
	fclose(fid);
	if nargin>1
		options=[{X},varargin];
	else
		options={};
	end
elseif isnumeric(X)
	x=char(X(:)');
	options=varargin;
else
	x=X;
	options=varargin;
end

P=zeros(0,4);
[bUseV]=false;	% to be compatible with older use
if ~isempty(options)
	setoptions({'bUseV'},options{:})
end

if ischar(x)
	if size(x,1)==1
		iLE=find(x==10|x==13);
		if isempty(iLE)
			iLE=length(x)+1;
		%elseif iLE(end)<length(x)	% don't add this - keep only whole lines
		%	iLE(end+1)=length(x)+1;
		end
		if iLE(1)>1
			iLE=[0 iLE];
		end
		n=length(iLE)-1;
	else
		n=size(x,1);
	end
else
	n=length(x);
end
X=struct('src',cell(1,n),'cmd',[],'data',[]);
nX=0;
for iL=1:n
	if ischar(x)
		if size(x,1)==1
			l=strtrim(x(iLE(iL)+1:iLE(iL+1)-1));
		else
			l=x(iL,:);
		end
	else
		l=x{iL};
	end
	if isempty(l)
		continue
	end
	if length(l)>5
		X1=ExtractNMEAline(strtrim(l));
		if ~isempty(X1)
			nX=nX+1;
			if nX>length(X)
				X(end+10000).src=[]; %#ok<AGROW>
			end
			X(nX)=X1;
		end
	end
end
X=X(1:nX);
Xcmds={X.cmd};
if nX==0
	uC=cell(2,0);
else
	uC=unique(Xcmds);
	for i=1:size(uC,2)
		ii=find(strcmp(uC{1,i},Xcmds));
		if isstruct(X(ii(1)).data)
			if ~all(cellfun(@isstruct,{X(ii).data}))
				uC{2,i}={X(ii).data};
			else
				uC{2,i}=[X(ii).data];
			end
		else
			uC{2,i}={X(ii).data};
		end
	end
end
t0=0;
iRMC=find(strcmp(uC(1,:),'RMC'));
if ~isempty(iRMC)
	if iscell(uC{2,iRMC})
		B=cellfun(@isstruct,uC{2,iRMC});
		if ~all(B)
			warning('Some problematic elements removed!')
			uC{2,iRMC}=uC{2,iRMC}(B);
		end
		uC{2,iRMC}=[uC{2,iRMC}{:}];
	end
	a=cat(1,uC{2,iRMC}.date);
	dy=2000+rem(a,100);
	a=floor(a/100);
	dm=rem(a,100);
	dd=floor(a/100);
	t=datenum(dy,dm,dd);
	t0=t(1);
	if bUseV
		lat=cat(1,uC{2,iRMC}.lat);
		long=cat(1,uC{2,iRMC}.long);
		V=cat(1,uC{2,iRMC}.V)*0.51444444444444444;	% convert knots to m/s
		TA=cat(1,uC{2,iRMC}.TA);
		tRMC=t+cat(1,uC{2,iRMC}.t)/86400;
		RMC=[lat long V TA];
		P=[t lat long zeros(size(t)) V TA];	% overwritten if GGA data is available
	end
elseif bUseV
	RMC=[];
	tRMC=[];
end
iGGA=find(strcmp(uC(1,:),'GGA'));

if isempty(iGGA)||iscell(uC{2,iGGA})
	t1=t0;
else
	t1=[uC{2,iGGA}.t]';
	lat1=[uC{2,iGGA}.lat]';
	long1=[uC{2,iGGA}.long]';
	alt1=[uC{2,iGGA}.alt]';
	if length(lat1)<length(t1)
		warning('Not all data points contained data!')
		if length(lat1)~=length(long1)||length(lat1)~=length(alt1)
			error('Unexpected error: expected to have position or not, not partial data!')
		end
		B=~cellfun(@isempty,{uC{2,iGGA}.long});
		t1=t1(B);
	end
	%t2=[uC{2,5}.t]';lat2=[uC{2,5}.lat]';long2=[uC{2,5}.long]';
		% in received measurement <1> and <2> are the same, but shifted one point
	if nargout>3
		if t0
			t1=t0+t1/86400;
		end
		t=t1-t1(1);
	elseif t0
		if length(t)==length(t1)
			t=t+t1/86400;
		else
			if any(t~=t(1))
				warning('!incorrect date handling!')
			end
			warning('Length of RMC and GGA data not equal ==> ?correct times?')
			t=t0+t1/86400;
		end
	end
	P=[t lat1 long1 alt1];
end
if bUseV&&~isempty(P)&&size(P,2)==4
	if size(P,1)==size(RMC,1)
		if ~isequal(P(:,1),tRMC)
			warning('Not equal times for P and V?!')
		end
		if ~isequal(P(:,2:3),RMC(:,1:2))
			warning('Speed given for unequal positions?!!')
		end
		P=[P RMC(:,3:end)];
	else
		P=var2struct(P,tRMC,RMC);
	end
end

function X=ExtractNMEAline(l)
if l(1)~='$'
	X=[];
	if any(l<9|l>254)
		lDisp=sprintf('bin-data #%d (%d non-zeros)',length(l),sum(l>1&l<255));
	elseif length(l)>140
		lDisp=sprintf('long line #%d',length(l));
	else
		lDisp=l;
	end
	warning('No NMEA-line (%s)',lDisp)
	return
end
i=length(l);
while i>1&&(l(i)==0||l(i)==' '||l(i)==13||l(i)==10)
	i=i-1;
end
while (l(i)>='0'&&l(i)<='9')||(l(i)>='A'&&l(i)<='F')
	i=i-1;
end
if l(i)=='*'	% CRC
	i=i-1;
else
	i=length(l);
end
src=l(2:3);
cmd=l(4:6);
ii=[find(l==',') i+1];
data=cell(1,length(ii)-1);
sdata=cell(1,length(data));
for i=1:length(data)
	%d1=strtrim(l(ii(i)+1:ii(i+1)-1));
	d1=l(ii(i)+1:ii(i+1)-1);	% necessary to trim?
	sdata{i}=d1;
	%nd=str2double(d1);
	nd=sscanf(d1,'%g');	% a lot faster than str2double!
	if ~isempty(d1)
		if isempty(nd)
			data{i}=strtrim(d1);
		else
			data{i}=nd;
		end
	end
end
lD=[];
switch cmd
	case 'GGA'	% Fix information
		if length(data)==14
			lD={'t','lat','latP','long','longP','Q','nSat','horDil'	...
				,'alt','altD','H','HD','dtDGPS','DGPS_ID'};
		else
			warning('READNMEA:GGAerror','error in GGA-data')
		end
	case 'GSA'	% Overall Satellite data
		if length(data)==17
			lD={'autoSel','fix3D','s1','s2','s3','s4','s5','s6','s7'	...
				,'s8','s9','s10','s11','s12','PDOP','HDOP','VDOP'};
			%!!!!"scattered" data of satelites
		else
			warning('READNMEA:GSAerror','error in GSA-data')
		end
	case 'GSV'	% Detailed Satellite data
		if length(data)>19
			warning('READNMEA:GSVerror','error in GSV-data')
		else
			lD={'nSent','sentNr','satInView','PRN1','el1','az1','SNR1'	...
				,'PRN2','el2','az2','SNR2','PRN3','el3','az3','SNR3'	...
				,'PRN4','el4','az4','SNR4'};
			if length(data)<19
				if rem(length(data)-3,4)
					warning('READNMEA:GSVwarning','partial GSV-data?')
				end
				if false
					lD=lD(1:length(data));
				else
					data{19}=[];
				end
			end
		end
	case 'RMC'	% recommended minimum data for gps
		if length(data)==11
			lD={'t','status','lat','latP','long','longP','V','TA','date'	...
				,'magVar','magVarD'};
		elseif length(data)==12
			lD={'t','status','lat','latP','long','longP','V','TA','date'	...
				,'magVar','magVarD','mode'};
		else
			warning('READNMEA:GMCerror','error in GMC-data')
		end
end
if ~isempty(lD)
	for i=1:min(length(sdata),length(lD))
		if ~isempty(sdata{i})
			switch lD{i}
				case 't'
					if isnumeric(data{i})&&~isempty(data{i})
						data{i}=[3600 60 1]*sscanf(sdata{i},'%02d')	...
							+rem(data{i},1);	% normally .000, but maybe...
					end
				case 'long'
					if isnumeric(data{i})
						data{i}=[1 1/60]*sscanf(sdata{i},'%03d%f');
					end
				case 'lat'
					if isnumeric(data{i})
						data{i}=[1 1/60]*sscanf(sdata{i},'%02d%f');
					end
				case {'status','latP','longP','magVarD','mode'}
					% do something? - like sine reversal of lat/lon?
			end		% switch
		end		% if not empty
	end		% for i
	data=[lD;data];
	data=struct(data{:});
end

X=struct('src',src,'cmd',cmd,'data',{data});
