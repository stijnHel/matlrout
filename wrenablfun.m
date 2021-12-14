function varargout=wrenablfun(fun,enable)
%wrenablfun - Makes a function write-en(/dis-)abled
%    wrenablfun(fun,enable)
%    wrenablfun list ---- gives the list of enabled functions
%    wrenablfun all  ---- disables all enabled functions
%    wrenablfun find ---- searches for enabled functions
%
% !only for unix-based systems!

persistent ENfunctions

if ~isunix
	error('This function is only made for unix-like platforms')
end

if nargin==0
    fun='list';
end

if iscell(fun)
	if nargin<2
		enable=true;
	end
	for i=1:length(fun)
		wrenablfun(fun{i},enable);
	end
	return
elseif strcmpi(fun,'list')
	printstr(ENfunctions)
	return
elseif strcmpi(fun,'all')
	L=ENfunctions;
	for i=1:length(L)
		wrenablfun(L{i});
	end
	return
elseif strcmpi(fun,'find')
	sDir=which(mfilename);
	fDir=fileparts(sDir);
	[baseDir,sDir]=fileparts(fDir);
	if nargin==1
		sDir=[filesep sDir filesep];
	else
		sDir=enable;
		if sDir(end)~='/'
			sDir(end+1)='/';
		end
	end
	[o,L]=unix(['ls -l ' baseDir sDir '*.m|grep ^-rw']);
	if o
		FL=[];
	else
		iLF=[0 find(L==10)];
		FL=cell(1,length(iLF)-1);
		for i=1:length(FL)
			s=L(iLF(i)+1:iLF(i+1)-1);
			j=findstr(s,sDir);
			if length(j)~=1
				error('What''s wrong???')
			end
			FL{i}=s(j+10:end-2);	% (fixed part to add subdirectory)
		end
		d=dir([baseDir sDir]);
		d=d(cat(2,d.isdir));
		FLrec=cell(1,length(d));
		B=false(1,length(d));
		for i=1:length(d)
			if strcmp(d(i),'private')||d(i).name(1)=='@'
				FLrec{i}=wrenablfun(fun,[sDir d(i).name '/']);
				B(i)=~isempty(FLrec{i});
			end
		end
		if any(B)
			FL=[FL FLrec{B}];
		end
	end
	if nargout
		varargout={FL};
	elseif isempty(FL)
		fprintf('No write enabled functions found\n')
	else
		printstr(FL)
	end
	return
end
fullfun=which(fun);
if isempty(fullfun)
	error('Function can''t be found!')
end

if ~iscell(ENfunctions)
	ENfunctions={};
end
if nargin<2
	enable=[];
elseif ischar(enable)
	enable=str2num(enable); %#ok<ST2NM>
	if isempty(enable)
		warning('WRENABLEFUN:enable','Wrong enable input - default behaviour is done')
	end
end
if isempty(enable)
	if ~isempty(strmatch(fun,ENfunctions,'exact'))
		enable=false;
	else
		enable=true;
	end
end
if enable
	cden='666';
else
	cden='444';
end

dos(['chmod ' cden ' "' fullfun '"']);
i=strmatch(fun,ENfunctions,'exact');
if enable
	fprintf('function (%s) is write-enabled\n',fullfun)
	if isempty(i)
		ENfunctions{end+1}=fun;
	end
else
	fprintf('function (%s) is write-disabled\n',fullfun)
	if ~isempty(i)
		ENfunctions(i)=[];
	end
end
