function ver=zetev(a,b)
% ZETEV laat de directory waar de gegevens staan juist veranderen.
% Geeft als resultaat of de directory veranderd is of niet.
%        zetev 'directoy'
%
% extra gebruik :
%    [a=]zetev;
%        geeft huidige directory
%    zetev('',<string>)
%        geeft combinatie van directory en string
%    zetev(1,<string>)
%        directory bepaling relatief ten opzichte van huidige zetev-dir
%           (1ste argument wordt niet bekeken ("not empty"))
%    zetev(1,<nr>)
%           vraagt directory op (ongesorteerd) met enkel directories
%              en neemt d(<nr>) als nieuwe directory
%    zetev(<dir-struct>) or zetev([],<dir-struct>)
%       takes name field
%
% zie ook: direv
global EVDIR

if nargin>0
	if nargin==1&&isempty(a)
		EVDIR='';
		return
	elseif isstruct(a)||(nargin>1&&isstruct(b))
		if isstruct(a)
			d=a;
			a=[];
		else
			d=b;
		end
		if isempty(d)
			error('empty struct array!!!')
		end
		if length(d)>1
			warning('ZETEV:FirstFromMore','First from multiple records taken!')
			d=d(1);
		end
		out=zetev(a,d.name);
		if nargout
			ver=out;
		end
		return
	end
end

if nargin>1
	if isnumeric(b)
		if isscalar(b)
			if isempty(a)
				d=direv('','file');
			elseif iscell(a)
				if isscalar(a)
					a{2}='file';
				end
				d=direv(a{:});
				a=[];
			else
				d=direv('','dir');
			end
			if b>length(d)||-b>=length(d)
				error('Not enough directory elements found (%d <-> %d)',b,length(d))
			elseif b<=0
				b=d(end+b).name;
			else
				b=d(b).name;
			end
		else
			error('Wrong input')
		end
	end
	if strcmp(b,'..')
		b=['..' filesep];
	end
	if isnumeric(a)&&isscalar(a)&&a==2
		b=['..' filesep b];
	end
	x=CorrDir(RepStdFilesep(b),EVDIR);
	if isempty(a)
		ver=x;
		return
	end
	a=x;
end

v=version;
if ~exist('a','var')
	if nargout>0
		ver=EVDIR;
	else
		disp(EVDIR)
	end
	return
elseif ~ischar(a)
	error('Verkeerde input');
end
a=RepStdFilesep(a);
if length(a)>1
	i=find(a(1:end-1)==filesep&a(2:end)==filesep);
	if ~isempty(i)&&i(1)>1
		a(i)=[];
	end
end
if any(a=='*')
	d=dir(a);
	if isempty(d)
		error('No match found')
	elseif length(d)>1
		printstr({d.name})
		error('More than one match found!')
	end
	i=find(a==filesep);
	if isempty(i)
		a=d(1).name;
	else
		a=[a(1:i(end)) d(1).name];
	end
end
if a(length(a))~=filesep
	a=[a filesep];
end
if v(1)>='5'
	b=a;
	if b(end)==filesep
		b(end)='';
	end
	if ~exist(b,'dir')
		error('Directory "%s" bestaat niet',a)
	end
end
if strcmp(a,EVDIR)
	veranderd=false;
else
	veranderd=true;
	EVDIR=a;
end
if nargout>0
	ver=veranderd;
end

function a=CorrDir(a,cdir)
bOK=true;
if isempty(cdir)
	return
end
if cdir(end)==filesep
	cdir(end)=[];
end
while a(1)=='.'
	if length(a)==1
		a='';
		break
	elseif a(2)=='.'
		i=find(cdir==filesep);
		if isempty(i)
			error('too much levels back in directory structure')
		end
		cdir=cdir(1:i(end)-1);
		if length(a)==2
			a='';
			break;
		elseif a(3)~=filesep
			error('Wrong use of zetev')
		end
		a=a(4:end);
		if isempty(a)
			break;
		end
	elseif a(2)==filesep
		a=a(3:end);	% relative to current directory
	else
		bOK=false;
		warning('ZETEV:unexpStructure','unexpected structure of directoryname!')
		break
	end
end	% while
if bOK
	if isempty(cdir)
		cdir=filesep;
	end
	a=fullfile(cdir,a);
end

function a=RepStdFilesep(a)
if filesep~='/'&&any(a=='/')
	a(a=='/')=filesep;
end
