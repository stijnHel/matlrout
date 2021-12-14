function [D,E]=ReadPAXlog(fn,varargin)
%ReadPAXlog - Read log from PAX (Process Anomaly eXplorer)
%   D=ReadPAXlog(<file>)
% or
%   D=ReadPAXlog(<directory>)
%      [D,E]=.... also reads error file

bTimeMatlabDays=true;

if nargin>1
	setoptions({'bTimeMatlabDays'},varargin{:})
end

if ~exist(fn,'file')
	fn=zetev([],fn);
end

if isdir(fn)
	% Read full directory
	d=dir(fullfile(fn,'*.prl'));
	if isempty(d)
		error('No files found')
	end
	bStatus=length(d)>5;
	if bStatus
		status('Reading of PAX=process files',0)
	end
	t=zeros(length(d)*2,length(d)*2+1);	% (!!)oversized!!
		% first column:t, next start/stop prl indices (neg for stopped)
	nt=1;
	nt2=2;
	for i=1:length(d)
		D1=ReadPAXlog(fullfile(fn,d(i).name),varargin{:});
		if i==1
			if length(d)>1
				D=D1(1,ones(1,length(d)));
			end
			t(1)=D1.data(1);	% first starting time
			t(1,2)=1;	% first process
			if size(D1.data,1)==1	% only one point!
				t(1,3)=-1;
				nt2=3;
			else
				t(2)=D1.data(end,1);
				t(2,2)=-1;
				nt=2;
			end
		else
			D(i)=D1;
			if D1.data(1)<t(1)
				t(2:nt+1,1:nt2)=t(1:nt,1:nt2);
				nt=nt+1;
				t(1)=D1.data(1);
				t(1,2)=i;
				t(1,3:nt2)=0;
			else
				it=find(t(1:nt)<=D1.data(1),1,'last');
				if D1.data(1)==t(it)
					k=find(t(it,:)==0,1);
					t(it,k)=i;
					if k>nt2
						nt2=k;
					end
				else
					it=it+1;
					t(it+1:nt+1,1:nt2)=t(it:nt,1:nt2);
					nt=nt+1;
					t(it)=D1.data(1);
					t(it,2)=i;
					t(it,3:nt2)=0;
				end
			end
			if D1.data(end,1)>t(nt)
				nt=nt+1;
				it=nt;
				t(it)=D1.data(end,1);
				t(it,2)=-i;
			else
				it=find(t(1:nt)<=D1.data(end,1),1,'last');
				if D1.data(end,1)==t(it)
					k=find(t(it,:)==0,1);
					t(it,k)=-i;
				else
					it=it+1;
					nt=nt+1;
					t(it+1:nt+1,1:nt2)=t(it:nt,1:nt2);
					t(it)=D1.data(end,1);
					t(it,2)=-i;
					t(it,3:nt2)=0;
				end
			end
			if bStatus
				status(i/length(d))
			end
		end
	end
	if bStatus
		status
	end
	
	d=dir(fullfile(fn,'*.srl'));
	if ~isempty(d)
		Ds=ReadSRL(fullfile(fn,d(1).name),bTimeMatlabDays);
		if length(d)>1
			Ds(1,length(D))=Ds;
			for i=2:length(d)
				Ds(i)=ReadSRL(fullfile(fn,d(1).name),bTimeMatlabDays);
			end
		end
		D=struct('prl',D,'srl',Ds,'t',t(1:nt,1:nt2));
	end
	if nargout>1
		d=dir(fullfile(fn,'*.log'));
		if isempty(d)
			E=[];
		else
			if length(d)>1
				warning('READPAXLOG:MultiLogFiles'	...
					,'Are there multiple log files, only the first is read (%s)??'	...
					,d(1).name)
				d=d(1);
			end
			nWarn=0;
			c=cBufTextFile(fullfile(fn,d.name));
			L=fgetlN(c,1000);
			iL=0;
			l0='';
			E=struct('t',cell(1,1000),'nProcessFaults',[],'pID',[]	...
				,'pAdded',[],'pRemoved',[]);
			pLast=[];
			nE=0;
			while ~isempty(L)
				iL=iL+1;
				if iL>length(L)
					L=fgetlN(c,1000);
					iL=1;
					if isempty(L)
						break	% all is read
					end
				end
				l=L{iL};
				if length(l)<20
					continue;	% break should do, but you never know if empty lines exist
				end
				l1=l(25:end);
				if ~strcmp(l0,l1)
					l0=l1;
					js=find(l=='[');
					je=find(l==']');
					t=datenum(l(js(1)+1:je(1)-1),'yyyy-mm-ddTHH:MM:SS');
					n=str2double(l(js(2)+1:je(2)-1));
					js2=find(l=='(');
					je2=find(l==')');
					if isempty(js2)
						pp=[];
						pAdded=sscanf(l(je(2)+1:end),'%d,',[1 Inf]);
						pRemoved=[];	% !!!can't be retrieved!!!
					else	% old version
						[pp,np]=sscanf(l(js2+1:je2-1),'%d,');
						pp=pp';
						if np~=n
							nWarn=nWarn+1;
							if nWarn<5
								warning('READPAXLOG:WrongNumberOfProcs','Wrong number of processes (%d read, %d expected)!?',np,n)
							end
						end
						pAdded=setdiff(pp,pLast);
						pRemoved=setdiff(pLast,pp);
						pLast=pp;
					end
					nE=nE+1;
					if nE>length(E)
						E(end+1000).t=0; %#ok<AGROW>
					end
					E(nE).t=t;
					E(nE).nProcessFaults=n;
					E(nE).pID=pp;
					E(nE).pAdded=pAdded;
					E(nE).pRemoved=pRemoved;
				end
			end		% while ~isempty(L)
			E=E(1:nE);
		end		% read errors
	end
	return
end

fid=fopen(fn);
if fid<3
	error('Can''t find file')
end

x=fread(fid,[1 Inf],'*uint8');
fclose(fid);
[n,iX]=GetNum(x,0,'uint32',4);

cHead={'Version',[4 2],'version';
	'PID',[4 2],'PID';
	'Process Name',-1,'pName';
	'Process Path',-1,'pPath';
	};

Ds=cHead(:,3)';Ds{2,1}=[];
D=struct(Ds{:},'nInit',n,'data',[]);
if x(9)==0
	[D.version,iX]=GetNum(x,iX,'uint32',8);
	nHead=3;
else
	nHead=4;
end
for i=1:nHead
	[s,iX]=GetString(x,iX);
	j=strmatch(s,cHead(:,1),'exact');
	if isempty(j)
		warning('READPAXLOG:UnknownHeadField','"%s" is unknown in header - reading stopped',s)
		break
	end
	switch cHead{j,2}(1)
		case 4	% uint32
			[z,iX]=GetNum(x,iX,'uint32',prod(cHead{j,2}));
			D.(cHead{j,3})=z;
		case -1
			[s,iX]=GetString(x,iX);
			D.(cHead{j,3})=s;
		otherwise
			error('Wrong head-type definition')
	end
end
[nField,iX]=GetNum(x,iX,'uint32',4);
fields=cell(1,nField);
for i=1:nField
	[fields{i},iX]=GetString(x,iX);
end
D.fields=fields;

z=reshapetrunc(swapbytes(typecast(x(iX+1:end),'uint32')),nField,[])';
Z=double(z);
if bTimeMatlabDays
	Z(:,1)=Z(:,1)/(3600*24)+datenum(1970,1,1,1,0,0);
end
for i=1:nField
	if strcmp(fields{i}(end-2:end),'[%]')
		Z(:,i)=typecast(z(:,i),'single');
	end
end
D.data=Z;

function [a,iX]=GetNum(x,iX,typ,nBytes)
bSwap=true;
a=typecast(x(iX+1:iX+nBytes),typ);
if bSwap
	a=swapbytes(a);
end
iX=iX+double(nBytes);

function [s,iX]=GetString(x,iX)
[n,iX]=GetNum(x,iX,'uint32',4);
if n>2e5
	%what's wrong?
	n=0;
end
s=char(x(iX+1:iX+n));
iX=iX+double(n);

function D=ReadSRL(fName,bTimeMatlabDays)
fid=fopen(fName);
if fid<3
	error('Can''t find file')
end

x=fread(fid,[1 Inf],'*uint8');
fclose(fid);
[QDatastreamVersion,iX]=GetNum(x,0,'uint32',4);
[LOGversion,iX]=GetNum(x,iX,'uint32',4);
[NSIE,iX]=GetNum(x,iX,'uint32',4);
SIE=cell(2,NSIE);
for i=1:NSIE
	[SIE{1,i},iX]=GetString(x,iX);
	[SIE{2,i},iX]=GetString(x,iX);
end
[NSRE,iX]=GetNum(x,iX,'uint32',4);
SRE=cell(2,NSRE);
dTypes={4,'uint32';8,'uint64';4,'single'};
tSRE=zeros(1,NSRE);
for i=1:NSRE
	[s,iX]=GetString(x,iX);
	if s(end)==']'
		j=find(s=='[',1,'last');
		if isempty(j)
			error('Fault in type-information?')
		end
		tp=s(j+1:end-1);
		if isempty(tp)
			tSRE(i)=1;
		else
			switch tp
				case 's'
					tSRE(i)=1;
				case 'B'
					tSRE(i)=2;
				case '%'
					tSRE(i)=3;
				otherwise
					tSRE(i)=2;
			end
		end
		s=s(1:j-1);
		SRE{2,i}=tp;
	else
		tSRE(i)=1;
	end
	SRE{1,i}=s;
end
NB=cat(2,dTypes{:,1});
NB=NB(tSRE);
dataB=reshape(x(iX+1:end),sum(NB),[]);
data=zeros(size(dataB,2),NSRE);
j=0;
for i=1:NSRE
	jN=j+NB(i);
	data(:,i)=swapbytes(typecast(reshape(dataB(j+1:jN,:),[],1),dTypes{tSRE(i),2}));
	j=jN;
end
if bTimeMatlabDays
	data(:,1)=data(:,1)/(3600*24)+datenum(1970,1,1,1,0,0);
end

D=struct('QDatastreamVersion',QDatastreamVersion,'LOGversion',LOGversion	...
	,'SIE',{SIE},'SRE',{SRE}	...
	,'data',data	...
	);
