function d=dirrecurs(f,varargin)
%dirrecurs - returns the recursive directory contents
%     d=dirrecurs(f)
%
% gives a directory list with directory data in name field
%        (without the base directory)
% only files are kept, empty directories will not be returned
%
% the contents can be read (as uint8-vectors) as follows:
%     d=dirrecurs(dd1,'-bReadContents');
%     a field 'contents' is added
% To be able to check equal contents, without requiring all data, file
% contents can be hashed with option bHashContents. (uses md5_c)
%
%  see also hierdir

[bReadContents,bHashContents,bSortFullname	...
	,bIncludeDotFiles,nMaxDeep,bRemoveDirs	...
	,bDOSdir]=deal(	...
		[],false,true	... bReadContents(default equal to bHashContents), bHashContents, bSortFullname
		,false,500,true,false);	% bIncludeDotFiles,nMaxDeep,bRemoveDirs
%bIncludeDotFiles: include files/directories starting with dot (normally hidden files)
if nargin==0
	f=[];
end
if nargin>1
	setoptions({'bReadContents','bSortFullname','bIncludeDotFiles'	...
		,'bRemoveDirs','nMaxDeep','bHashContents','bDOSdir'},varargin{:})
end
if isempty(bReadContents)
	bReadContents=bHashContents;
end

if bDOSdir
	d = DOSdir(f);
	return
end

if ~isempty(f)&&any(f=='*')
	[fPth,fNm,fExt]=fileparts(f);
	sFileSpec=[fNm,fExt];
	f=fPth;
else
	sFileSpec='';
end

d=GetDir(f,sFileSpec,bIncludeDotFiles,0);
if bReadContents&&~isempty(d)
	d(1).contents=[];
end
i=1;
while i<=length(d)
	if d(i).isdir
		if d(i).level<nMaxDeep
			d1=GetDir(d(i).fullname,sFileSpec,bIncludeDotFiles,d(i).level+1);
			%if bReadContents&&~isempty(d1)	% why was bReadContents added to
											%the condition?
			if ~isempty(d1)
				if bReadContents
					d1(1).contents=[];
				end
				d(end+1:end+length(d1))=d1;
			end
		end
		if bRemoveDirs
			d(i)=[];
		else
			i=i+1;
		end
	else
		if bReadContents
			%fid=fopen(fullfile(f,d(i).fullname)); %#ok<UNRCH>
			fid=fopen(d(i).fullname);
			if fid<3
				warning('Can''t open file "%s"!',d(i).fullname)
			else
				d(i).contents=fread(fid,[1 Inf],'*uint8');
				fclose(fid);
				if bHashContents
					try
						d(i).contents={md5_c(d(i).contents)};
					catch err
						DispErr(err)
						warning('Error when hashing "%s"',d(i).fullname)
					end
				end
			end
		end
		i=i+1;
	end
end
if ~isempty(d)
	if bSortFullname
		d=sort(d,'fullname');
	else
		d=sort(d,'name');
	end
end

function d=GetDir(dirname,sFileSpec,bIncludeDotFiles,level)
if isempty(dirname)
	dirname='.';
end
if isempty(sFileSpec)
	d=dir(dirname);
else
	d=dir(fullfile(dirname,sFileSpec));
	dd=dir(dirname);
	d=[d;dd([dd.isdir])];
end
if ~isempty(d)
	nd=char(d.name);
	d(nd(:,1)=='.')=[];
end
if isempty(dirname)
	[d.fullname]=deal(d.name);
else
	for j=1:length(d)
		d(j).fullname=fullfile(dirname,d(j).name);
	end
end
for j=1:length(d)
	d(j).level=level;
end
if isempty(d)
	% do nothing
elseif bIncludeDotFiles
	[~,i]=intersect({d.name},{'.','..'});
	if ~isempty(i)
		d(i)=[];
	end
else
	nd=char(d.name);
	d(nd(:,1)=='.')=[];	% !!!! also removes other directories/files!!!
end

function d = DOSdir(f)
[~,Sdir] = dos(['dir ',f,' /s']);
ii = find(Sdir==10);
curDir = [];
d = struct('name',cell(1,1000),'folder',[],'date',[],'bytes',[],'datenum',[]);
nD = 0;
for i = 1:length(ii)-1
	l = strtrim(Sdir(ii(i)+1:ii(i+1)-1));
	if startsWith(l,'Directory of')
		curDir = l(14:end);
	elseif endsWith(l,' bytes')
		curDir = [];
	elseif ~isempty(l)
		[dd,~,~,iNxt] = sscanf(l,'%d/%d/%d %d:%d',[1,5]);
		if length(dd)<5
			continue
		end
		l(1:iNxt-1) = [];
		[nB,~,~,iNxt] = sscanf(l,'%s',1);
		nB(nB==',') = [];
		l(1:iNxt-1) = [];
		while l(1)==' '
			l(1)=[];
		end
		nD = nD+1;
		d(nD).folder = curDir;
		d(nD).name = l;
		d(nD).bytes = sscanf(nB,'%d');
		d(nD).date = sprintf('%d/%02d/%d %2d:%02d',dd);
		d(nD).datenum = datenum([dd([3,2,1,4,5]),0]);
	end
end
d = d(1:nD);
