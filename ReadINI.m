function S=ReadINI(fName,bFields,bInterpret)
%ReadINI  - Read ini-text file (typical ini-format)
%    S=ReadINI(fName)

bNumber=false(1,255);
bNumber(abs('0123456789+-.eE'))=true;

if nargin<2
	bFields = true;
end
if nargin<3
	bInterpret = false;
end

f=cBufTextFile(fFullPath(fName));

S=struct('section',cell(1,30),'data',[]);
nS=0;
bInSection=false;

while true
	l=f.fgetl();
	if ~ischar(l)
		break
	end
	l=strtrim(l);
	if isempty(l)
		% do nothing (or end section?)
	elseif l(1)=='%' || l(1)=='/' || l(1)=='#'
		% do nothing - comment
	elseif l(1)=='['	% start section
		if bInSection
		end
		nS=nS+1;
		S(nS).section=l(2:end-1);
		S(nS).data=struct();
		bInSection=true;
	else
		if ~bInSection
			warning('starting without section start?!')
			nS=nS+1;
			S(nS).section='unnamedSection';
			S(nS).data=struct();
			bInSection=true;
		end
		i=find(l=='=',1);
		if isempty(i)
			warning('%s.%s without "="?!',S(nS).section,l)
			i=length(l)+1;
		end
		fld = strtrim(l(1:i-1));
		d=strtrim(l(i+1:end));
		if all(bNumber(abs(d)))
			[dNumber,n,err]=sscanf(d,'%g');
			if n==1&&isempty(err)
				d=dNumber;
			end
			S(nS).data.(fld)=d;	% check if possible?!
		else
			if bInterpret
				d = Interpret(d,1);
			end
			S(nS).data.(fld)=d;	% check if possible?!
		end
	end		% not empty l
end		% while true

if bFields
	S0=S;
	S=struct();
	for i=1:nS
		S.(S0(i).section)=S0(i).data;
	end
else
	S=S(1:nS);
end

function [C,i] = Interpret(d,i)
C = d;
i = SkipSpace(d,i);
if i>length(d)
	% do nothing
elseif strcmp(d,'true')
	C = true;
elseif strcmp(d,'false')
	C = false;
elseif d(i)=='''' || d(i)=='"'
	[C,i] = ReadString(d,i);
elseif d(i)=='['
	i1 = i;
	while i<=length(d) && d(i)~=']'
		i = i+1;
	end
	C = eval(d(i1:i));
	i = i+1;
elseif d(i)==','
	C = [];
elseif d(i)=='{'
	C = {};
	i = SkipSpace(d,i+1);
	if d(i)~='}'
		while i<=length(d)
			[C{1,end+1},i] = Interpret(d,i); %#ok<AGROW>
			if d(i)=='}'
				break
			elseif d(i)==','
				i = i+1;
			else
				error('Wrong use of list?! (%s)',d)
			end
		end
		i = i+1;
	end
else
	i1 = i;
	while i<=length(d) && d(i)~='}' && d(i)~=','
		i = i+1;
	end
	C = deblank(d(i1:i-1));
end
i = SkipSpace(d,i);

function [s,i] = ReadString(x,i)
if i==length(x)
	error('Wrong string?!')
end
c = x(i);
i = i+1;
i1 = i;
while i<=length(x) && x(i)~=c
	if x(i)=='\'
		i = i+1;
	end
	i = i+1;
end
if x(i)~=c
	error('Wrong string?! (%s)',x)
end
s = x(i1:i-1);
i = SkipSpace(x,i+1);

function i = SkipSpace(x,i)
while i<=length(x) && (x(i)==' ' || x(i)==9)
	i = i+1;
end
