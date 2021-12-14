function [X,ddirs]=readDOSdirFile(fn,isflat,bCalcDirSizes,varargin)
% READDOSDIRFILE - Leest DOS-directory-info (uit textfile)
%    X=readDOSdirFile(fn[,isflat[,bCalcDirSizes]])

if ~exist('bCalcDirSizes','var')||isempty(bCalcDirSizes)
	bCalcDirSizes=false;
		% nu gebeurt dit op het einde
		%----- eerder tijdens het lezen bepalen(?)
end
if ~exist('isflat','var')||isempty(isflat)
	isflat=false;
end

if isstruct(fn)	% vooral nuttig tijdens testen (?)
	X=fn;
else
	fid=fopen(fn);
	if fid<3
		error('Kan file niet openen');
	end
	fseek(fid,0,'eof');
	lFile=ftell(fid);
	fseek(fid,0,'bof');

	ddelim='\'; % DOS

	s0=struct('name',[],'date',[],'bytes',[],'isdir',[],'contents',[]);

	X1=struct('dirnaam',[],'contents',[],'bytes',[]);
	X=X1([]);
	X1.contents=s0([]);

	cNum=zeros(1,255);
	cNum(abs('0123456789'))=1;

	ddirs=cell(1,1000);
	nDirs=0;
	drefs=cell(1,1000);
	curref0=struct('type','()','subs',{{1}});
	%curref0 was oorspronkelijk [], maar het blijkt dat directories gelezen
	%   kunnen worden, zonder dat deze getoond worden in de lijst.  Daarom werd
	%   dit toegevoegd (en lijkt te werken).
	curref=curref0;
	lenref0=length(curref0);
	bStarting=true;
	bSkipDir=false;
	bReadHiddenDirs=false;
	nMaxLines=1e9;
	if ~isempty(varargin)
		setoptions({'bReadHiddenDirs','nMaxLines'},varargin{:})
	end
	bRootDir=true;
	nLines=0;
	bStatus=lFile>1e6;
	if bStatus
		status('Reading long directorylist',0)
	end

	while ~feof(fid)
		nLines=nLines+1;
		if nLines>nMaxLines
			fprintf('maximum number of lines reached!\n')
			break
		end
		l=fgetl(fid);
		if isempty(l)
			% doe niets
		elseif cNum(abs(l(1)))&&~bSkipDir
			[dat,n,err,i]=sscanf(l,'%d/%d/%d %d:%d',5);
			if ~isempty(err)||n<5
				warning('READDOSDIR:prelimStop','!!!voortijdig afgebroken (verkeerd datum formaat)!!! (%s)',l)
				break
			end
			[dir_siz,n,err,i1]=sscanf(l(i:end),'%s',1);
			if ~isempty(err)||n<1
				warning('READDOSDIR:prelimStop2','!!!voortijdig afgebroken ("size" kon niet gelezen worden)!!! (%s)',l)
				break
			end
			i=i+i1;
			while l(i)==' '
				i=i+1;
			end
			fn=l(i:end);
			if any(fn==255|fn==127)
				fn(fn==255|fn==127)='_';
			end
			isDir=0;
			nbytes=0;
			if strcmp(dir_siz,'<DIR>')||strcmp(dir_siz,'<JUNCTION>')
				% <JUNCTION> added, not knowing what it is, but it looks
				%    like another directory
				if strcmp(fn,'.')||strcmp(fn,'..')
					isDir=-1;
				else
					isDir=1;
					if X1.dirnaam(end)==ddelim
						newdir=[X1.dirnaam fn];
					else
						newdir=[X1.dirnaam ddelim fn];
					end
					nDirs=nDirs+1;
					ddirs{nDirs}=newdir;
					drefs{nDirs}=[curref struct('type',{'.','()'}   ...
						,'subs',{'contents',{length(X1.contents)+1}})];
				end
			elseif cNum(abs(dir_siz(1)))
				dir_siz(dir_siz=='.'|dir_siz==',')='';
				nbytes=str2double(dir_siz);
			else
				warning('READDOSDIR:prelimStop3','!!!voortijdig afgebroken (ongeldige "size")!!! (%s)',l)
				break
			end
			if isDir>=0
				if isempty(X1)
					warning('READDOSDIR:prelimStop4','!!!voortijdig afgebroken (directory zonder gegevens?))!!! (%s)',l)
					break;
				end
				s1=s0;
				s1.name=fn;
				s1.date=[dat([3 2 1 4 5])' 0];
				s1.bytes=nbytes;
				s1.isdir=isDir;
				X1.contents(end+1)=s1;
			end
		elseif strcmp(l(1:min(end,14)),' Directory of ')
			X1.dirnaam=l(15:end);
			X1.contents(:)=[];  % waarom hier?
			i=strmatch(X1.dirnaam,ddirs(1:nDirs),'exact');
			if isempty(i)
				% enkel mogelijk eerste keer (normaal gezien)
				%       ---- blijkt niet waar te zijn(!!!)
				if ~isempty(X)
					if bRootDir
						warning('READDOSDIRFILE:MultipleRoots','Multiple roots??!')
						bRootDir=false;
					end
				end
				if bStarting||bReadHiddenDirs
					curref=curref0;
					bStarting=false;
				else
					bSkipDir=true;	% blijkbaar mogelijk met DOS:
						% verborgen directories worden niet getoond in lijst
						% maar hun inhoud wordt wel gegeven!
				end
			else
				curref=drefs{i};
				bSkipDir=false;
				% deze dref en ddir zou weggehaald kunnen/moeten worden
				nDirs1=nDirs-1;
				drefs(i:nDirs1)=drefs(i+1:nDirs);
				ddirs(i:nDirs1)=ddirs(i+1:nDirs);
				nDirs=nDirs1;
			end
		elseif ~isempty(X1.dirnaam)
			if length(curref)<=lenref0
				X(end+1)=X1; %#ok<AGROW>
			else
				X=subsasgn(X,[curref struct('type','.','subs','contents')],X1.contents);
			end
			X1.dirnaam='';
		end
		if bStatus&&rem(nLines,5000)==0
			status(ftell(fid)/lFile)
		end
	end		% while ~feof
	if bStatus
		status
	end
	if ftell(fid)<lFile
		fprintf('%d / %d bytes read (%5.1f%%)\n',ftell(fid),lFile,ftell(fid)/lFile*100)
	end
	fclose(fid);
end		% read from file
if bCalcDirSizes
	if length(X)>1
		% This is possible due to hidden directories (contents displays,
		%    but not shown in the parent directory).
		X=struct('multiRoot','hiddenFolders','contents',X);
	end
	[N,X.contents]=calcdirsize(X.contents);
	fprintf('totaal %d bytes\n',N)
	X.bytes=N;
end
if isflat
	%misschien nogal veel werk om eerst gestuctureerd te maken, en dan
	% (traag ongestructureerd omvormen!!)
	for i=1:length(X)
		X(i).contents=flatten(X(i).contents);
	end
end
if nargout>1
	ddirs=[{length(ddirs)},ddirs(1:nDirs);{[]},drefs(1:nDirs)];
end

function [N,X]=calcdirsize(X)
N=0;
for i=1:length(X)
	% due to a fault "somewhere" it's possible to have empty structure
	% fields (except contents).  Maybe it is because of hidden directories
	% (??)
	% This is a work around for running through the data without problems.
	if ~isfield(X(i),'isdir')
		bDir=isfield(X(i),'dirnaam');
	else
		bDir=X(i).isdir;
		if isempty(bDir)
			bDir=false;
		end
	end
	if bDir
		[N1,X(i).contents]=calcdirsize(X(i).contents);
		X(i).bytes=N1;
	else
		N1=X(i).bytes;
		if isempty(N1)
			N1=0;
		end
	end
	N=N+N1;
end

function X=flatten(X)
i=1;
while i<=length(X)
	if X(i).isdir
		i0=length(X);
		n=length(X(i).contents);
		X(i0+1:i0+n)=X(i).contents;
		X(i).contents=[];
		for j=1:n
			X(i0+j).name=[X(i).name filesep X(i0+j).name];
		end
	end
	i=i+1;
end
