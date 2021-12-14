function [e,ne,de,e2,gegs]=leesRHT10(fn,varargin)
%leesRHT10 - Reads RHT10-logger data (temperature and humidity logger)
%    [e,ne,de,e2,gegs]=leesRHT10(fn)
%          if 'fn' is a structure, a dir-struct is supposed.
%          all files are read and combined, 'e' is expanded with time
%               (matlab time)

if ~exist('fn','var')||isempty(fn)
	d=direv('logTH*.rec');
	if isempty(d)
		zetev('./Tdata/RT10/');
		d=direv('logTH*.rec');
	end
	fn=sort(d,'datenum');
elseif isnumeric(fn)
	d=struct('name',cell(1,length(fn)));
	for i=1:length(fn)
		d(i).name=sprintf('logTH%d.rec',fn(i));
	end
	fn=d;
end
bPlot=false;
if isstruct(fn)
	if ~isempty(varargin)
		setoptions({'bPlot'},varargin{:})
	end
	E=cell(length(fn),6);
	for i=1:length(fn)
		[E{i,1:5}]=leesRHT10(fn(i).name,'bConvertCelcius',true);
		E{i,6}=timevec(E{i,5},E{i})/86400+E{i,5}.tStart;
		E{i,5}.file=fn(i).name;
	end
	gegs=cat(2,E{:,5});
	T=cat(2,gegs.tStart);
	[T,ii]=sort(T);
	dT=diff(T);
	E=E(ii,:);
	if any(dT==0)
		warning('LEESRHT10:duplicates','Duplicate data!')
		jj=find(dT==0);
		N=cellfun('length',E(:,1));
		if any(N(jj)~=N(jj+1))
			warning('LEESRHT10:DiffDupplicates','Not all dupplicates the same??!')
		end
		E(jj+1,:)=[];
	end
	e=[cat(1,E{:,6}) cat(1,E{:,1})];
	if min(diff(e(:,1)))<0
		warning('LEESRHT10:overlappingData','Overlapping data after combination!')
	end
	ne=[{'t'} E{1,2}];
	de=[{'-'} E{1,3}];
	e2=cat(1,E{:,4});
	gegs=cat(2,E{:,5});
	if bPlot
		PlotRes(e,ne,de,gegs)
	end
	return
end

bConvertCelcius=false;
if nargin>1
	setoptions({'bConvertCelcius','bPlot'},varargin{:})
end

[~,~,fext]=fileparts(fn);

fid=fopen(fn);
if fid<3
	fid=fopen(zetev([],fn));
	if fid<3
		[~,~,fext]=fileparts(fn);
		if isempty(fext)
			[e,ne,de,e2,gegs]=leesRHT10([fn '.rec']);
			return
		end
		error('Can''t open the file')
	end
end
if strcmpi(fext,'.txt')
	% text file
	l=fgetl(fid);
	H=cell(1,5);
	nH=0;
	loggingName=[];
	N=0;
	Tunit=[];
	while strncmp(l,'>>',2)
		l=l(3:end);
		nH=nH+1;
		H{nH}=l;
		i=find(l==':');
		if length(i)==1
			ll=l(i+1:end);
			switch lower(l(1:i-1))
				case 'logging name'
					loggingName=ll;
				case 'sample points'
					N=str2double(ll);
				case 'sample rate'
					% nothing
				case 'temperature unit'
					Tunit=ll;
				otherwise
					% possible?
			end
		else
			% alarms or from-to
			% nothing yet
		end
		l=fgetl(fid);
	end
	l=fgetl(fid);
	iT=[0 find(l==9) length(l)+1];
	ne=cell(1,length(iT)-1);
	for i=1:length(ne)
		ne{i}=l(iT(i)+1:iT(i+1)-1);
	end
	if length(ne)==6	% fast version
		e=fscanf(fid,'%d %d-%d-%d %d:%d:%d %g %g %g\n',[10,1e5])';
		e(:,2)=datenum(e(:,4),e(:,3),e(:,2));
		Z=zeros(size(e,1),1);
		e(:,3)=datenum(Z,Z,Z,e(:,5),e(:,6),e(:,7));
		e(:,3)=e(:,3)-floor(e(:,3));
		e=e(:,[1:3 8:10]);
	else
		if N==0
			N=16000;	% !!
		end
		e=zeros(N,length(ne));
		for i=1:N
			l=fgetl(fid);
			iT=[0 find(l==9) length(l)+1];
			if length(iT)-1>length(ne)
				warning('LEESRHT10:wrongNdata','!!!!Wrong number of points!!! - reading stopped')
				break
			end
			for j=1:length(iT)-1
				s=l(iT(j)+1:iT(j+1)-1);
				if sum(s=='-')==2
					d=datenum(s);
				elseif sum(s==':')==2
					d=datenum(s);
					d=d-floor(d);
				else
					d=str2double(s);
				end
				e(i,j)=d;
			end
		end
	end
	de=[];
	e2=[];
	gegs=struct(	...
		'loggerName',loggingName	...
		,'Tunit',Tunit	...
		,'H',{H});
	fclose(fid);
else	% binary file
	x=fread(fid,[1 1e6],'*uint8');
	fclose(fid);
	S=char(x(1:3));
	bFahrenheit=x(37);
	i=3;
	N1=typecast(x(i+1:i+20),'int32');
	i=67;
	e=double(reshape(typecast(x(i+1:end),'int16'),2,[])')/10;
	if size(e,1)~=N1(3)
		warning('LEESRHT10:wrongNdata','Unexpected number of points!!')
	end
	ne={'Temp','RH'};
	de={'degC','%'};
	if bFahrenheit
		if bConvertCelcius
			e(:,1)=(e(:,1)-32)*(5/9); %#ok<UNRCH>
		else
			de{1}='degF';
		end
	end
	d=double([N1(5) int32(x(32:36))]);
	e2=x(1:i);
	gegs=struct(	...
		'spec',S	...
		,'Ntarget',N1(2),'dt',double(N1(4))	...
		,'d',d	...
		,'tStart',datenum(d)	...
		,'TAlow',typecast(x(26:27),'uint16')	...	scaling?
		,'TAhigh',typecast(x(30:31),'uint16')	... scaling?
		,'HAlow',x(58)	... ?
		,'HAhigh',x(62)	... ?
		,'N1',N1(1)	...
		);
	%N1(1)==x(i-3:i)!?
end

if bPlot
	PlotRes(e,ne,de,gegs);
end

function PlotRes(e,ne,de,gegs)
if size(e,2)==2
	e=[gegs.tStart+timevec(gegs.dt,e)/86400 e];
	ne=[{'t'},ne];
end
plotmat(e,[],1,ne,de,'bTnav',true,'fig','RHTmeas')
