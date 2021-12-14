function [e,ne,de,e2,gegs]=leesHotInt(fName,bAltRead)
%leesHotInt - Reads simulation results from HotInt (multibody simulation)

if nargin==0||isempty(fName)
	fName='sol.txt';
	if ~exist(fName,'file')
		if exist(zetev([],fName),'file')
			fName=zetev([],fName);
		else
			d=direv('sol*.txt');
			if length(d)<1
				error('No file found')
			elseif length(d)>1
				i=1;
				while i>=length(d)
					if strncmpi(d(i).name,'solp')
						d(i)=[];
					else
						i=i+1;
					end
				end
				if length(d)>1
					[~,i]=max([d.datenum]);
					d=d(i);
					fprintf('Most recent file used (%s)\n',d.name)
				elseif isempty(d)
					error('After removing "solp*"-files no remaning file found!')
				end
			end
			fName=d.name;
		end		% no default file found in "zetev"
	end		% no default file found in path
end		% no filename given
if nargin<2||isempty(bAltRead)
	bAltRead=true;
end
if ~exist(fName,'file')
	fName=zetev([],fName);
	if ~exist(fName,'file')
		if isempty(which(fName))
			error('Can''t find the file')
		end
		fName=which(fName);
	end
end
if exist(fName,'dir')
	fName=fullfile(fName,'sol.txt');
	if ~exist(fName,'file')
		error('"sol.txt" doesn''t exist in the requested directory')
	end
end
e2 = [];
if bAltRead
	%trial to reduce memory problems
	c=cBufTextFile(fName);
	gegs=fgetlN(c,6);
	if isempty(gegs{1})||gegs{1}(1)=='%'
		LH=fgetl(c);
		nChan=sum(LH==' ');
		LH(1)=' ';
		iS=find(LH==' ');
		ne=cell(1,nChan);
		for i=1:nChan
			ne{i}=LH(iS(i)+1:iS(i+1)-1);
		end
		L={};
	else	% no header
		x1=sscanf(gegs{1},'%g');
		nChan=length(x1);
		ne=cell(1,nChan);
		de=cell(1,nChan);
		ne{1}='time';
		de{1}='s';
		for i=2:nChan
			ne{i}=sprintf('x%d',i-1);
			de{i}='-';
		end
		L=gegs;
		gegs=[];
	end
	status('Reading the file',0)
	L=[L fgetlN(c,1000)];
	Navg=mean(cellfun('length',L));
	nPt=c.lFile/Navg;
	e=zeros(ceil(nPt)+5,nChan);
	iE=0;
	iL=0;
	while iL<length(L)
		iL=iL+1;
		l=L{iL};
		if iL>=length(L)
			L=fgetlN(c,1000);
			iL=0;
			status(c.iFile/c.lFile)
			%fprintf('%7.3fM / %7.3fM (%6d | %6d - %9d | %9d - %6d | %6d)\n'		...
			%	,[c.iFile,c.iFile]/1e6,c.iLine,c.nLines,c.fPos,c.fPosNext	...
			%	,iE,size(e,1))
		end
		if isempty(l)
			break
		end
		iE=iE+1;
		if iE>size(e,1)
			nExtra=length(L)-iL+100		...
				+ceil((c.lFile-c.iFile)/mean(cellfun('length',L)));
			e(iE+nExtra,1)=0;	% increase size, hopefully enough
		end
		e(iE,:)=sscanf(l,'%g');
	end
	status
	if iE<length(e)
		e(iE+1:end,:)=[];
	end
else
	M = importdata(fName, ' ', 7);
	ne = M.colheaders;
	ne{1}=ne{1}(2:end);	% column header starts with '%'
	e = M.data;
	gegs = [];
end
de = cell(1,length(ne));
