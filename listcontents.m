function listcontents(pth,testpath,testfirst,testfunc,docomment)
% LISTCONTENTS - Geeft een lijst van de eerste help-regels van m-files
%    listcontents(pth,testpath,testfirst,testfunc,docomment)
%      pth : - directory (m-files worden gelezen)
%            - directory-struct (resultaat van dir-functie)
%            - 'path' - alle niet-matlab-directories
%            - default - current path
%      testpath : als 1 dan wordt getest of deze functie effectief gebruikt wordt
%                   (dus dat deze eerst in het "path" staat)
%                  aanduiding met (!p) vooraan
%      testfirst : als 1 dan wordt getest of het eerste woord verwijst naar de functie
%                  aanduiding met (!n) vooraan
%      testfunc : test of de file een functie is (er wordt dan ook getest of de
%                 naam van de functie overeenkomt met de naam van de file.
%      docomment : zet voor elke regel een '%' (om een contents.m file te maken)
%   all "extra's" are defaulted to '0'

% een nuttige uitbreiding is het lezen van class-methods. - en misschien private-dir?

if ~exist('testpath','var')
	testpath=[];
end
if ~exist('testfirst','var')
	testfirst=[];
end
if ~exist('testfunc','var')
	testfunc=[];
end
if ~exist('docomment','var')
	docomment=[];
end
if isempty(testpath)
	testpath=0;	% default
end
if isempty(testfirst)
	testfirst=0;	% default
end
if isempty(testfunc)
	testfunc=0;	% default
end
if isempty(docomment)
	docomment=0;	% default
end
if nargin==0||isempty(pth)
	pth=pwd;
end
if ischar(pth)
	if strcmpi(pth,'path')
		d=nmlpath;
		l='=';
		for i=1:length(d)
			fprintf('%s:\n%s\n',d{i},l(ones(1,length(d{i})+1)));
			listcontents(d{i})
		end
		return
	end
	if pth(end)~=filesep
		pth(end+1)=filesep;
	end
	d=dir([pth '*.m']);
	if isempty(d)
		warning('!!!geen files gevonden!!!')
		return
	end
	[~,i]=sort(upper({d.name}));
	d=d(i);
elseif isstruct(pth)
	d=pth;
	pth='';
else
	error('verkeerd gebruik van listcontents')
end
for i=1:length(d)
	if docomment
		fprintf('%%')
	end
	w=which(d(i).name);
	if isempty(w)
		w=[pth d(i).name];
	end
	[pd1,nd1]=fileparts(w);
	if testpath
		if ~strcmpi(pd1,pth(1:end-1))
			fprintf('(!p)');
		else
			fprintf('    ');
		end
	end
	a=help(nd1);
	if testfirst
		if isempty(a)
			fprintf('----')
		else
			b=sscanf(a,'%s',1);
			if ~strcmpi(b,nd1)
				fprintf('(!n)');
			else
				fprintf('    ');
			end
		end
	end
	if testfunc
		fnm=isfunc(w);
		if ischar(fnm)
			if strcmpi(fnm,nd1)
				fprintf('funct  ');
			else
				fprintf('funNok ');
			end
		elseif fnm<0
			fprintf('script ')
		elseif fnm==0
			fprintf('leeg   ')
		else
			fprintf('????   ')
		end
	end
	if isempty(a)
		a='------!geen help!!!';
		j=[];
	else
		j=find(a==10);
	end
	if isempty(j)
		j=length(a+1);
	end
	fprintf('%-15s : %s\n',nd1,a(1:j(1)-1));
end

function fnm=isfunc(f)
% ISFUNC - Hier wordt gekeken of de file een functie is.
fid=fopen(f);
if fid<3
	error('kan file niet openen')
end
while ~feof(fid)
	l=deblank(fgetl(fid));
	if isempty(l)
		continue;
	end
	while l(1)==' '||l(1)==9
		l(1)='';
		if isempty(l)
			break
		end
	end
	if isempty(l)
		continue;
	end
	if l(1)=='%'
		continue;
	end
	% eerste regel gevonden
	fclose(fid);
	[w1,~,~,next]=sscanf(l,'%s',1);
	if strcmpi(w1,'function')	% dit is een functie
		l=l(next:end);
		i=find(l=='%');
		if ~isempty(i)
			l=l(1:i(1)-1);
		end
		if isempty(l)
			warning('!!verkeerd functie-begin???')
			l='xxx';
		end
		i=find(l=='=');
		l(end+1)='(';	%#ok<AGROW> % sentinel
		if isempty(i)
			i=1;
		else
			i=i(1)+1;
		end
		while l(i)==' '||l(i)==9
			i=i+1;
		end
		i0=i;
		varC=zeros(1,255);
		varC([abs('a'):abs('z') abs('A'):abs('Z') abs('0'):abs('9') abs('_')])=1;
		while varC(abs(l(i)))	% (nullen mogen niet voorkomen(!?!))
			i=i+1;
		end
		fnm=l(i0:i-1);
	else
		fnm=-1;
	end
	return
end
fclose(fid);
%warning(sprintf('!!file %s is "MATLAB-leeg".!!',f))
fnm=0;
