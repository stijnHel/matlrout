function [dSet,A]=setmeas(d)
%setmeas  - Set measurement directory
%    quick-setting of measurement directories (zetev)
%         uses local function measDirs
%         setmeas . : base measurement directory
%         setmeas 0 : default
%         setmeas : gives all information
%         setmeas <name> : sets directory as set in list
%
% measDirs must be a function that returns a structure like:
%     main: <base directory>   (used for other items)
%     default: <default name)  (see list)
%     list: cell array:
%            {<name_1> <subdir_1>;
%             <name_2> <subdir_2>
%             ...}
%
% see also (local) measDirs

if ~exist('measDirs','file')
	error('No measurement-directory defined in path')
end
A=measDirs;
A(:,1)=lower(A(:,1));
if nargin==0
	fprintf('main directory: %s\n',A.main)
	fprintf('current default directory (in list): %s\n',A.default)
	L=A.list';
	nM=max(cellfun('length',A.list(:,1)));
	fprintf(['       %-' num2str(nM+1) 's: %s\n'],L{:})
	return
end
if isnumeric(d)
	zetev(A.main);
	D=direv([],'dir','sortn');
	d=D(d).name;
	%d=num2str(d);
end
i=find(d=='/',1);
if isempty(i)
	if d(end)=='/'
		d(end)=[];
	end
	d1=d;
	d2='';
else
	d1=d(1:i-1);
	d2=d(i:end);
end
if strcmp(d1,'0')
	d1=A.default;
end
main=A.main;
if main(end)~=filesep;
	main(end+1)=filesep;
end
if strcmp(d1,'.')
	a='';
else
	i=find(strcmpi(d1,A.list(:,1)));
	if isempty(i)
		i=find(strncmpi(d1,A.list(:,1),length(d1)));
	end
	if isempty(i)
		zetev(main)
		if exist(zetev([],d1),'file')
			a=d1;
		else
			error('Unknown directory - only existing directories are allowed')
		end
	elseif length(i)>1
		error('!!something woring in measDirs!! - doubles!!')
	else
		a=A.list{i,2};
	end
end
if ~isempty(a)&&a(1)==filesep
	main='';	% full filepath defined - not using main directory
end
zetev([main a d2])

if nargout
	dSet=zetev;
end
