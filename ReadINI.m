function S=ReadINI(fName,bFields)
%ReadINI  - Read ini-text file (typical ini-format)
%    S=ReadINI(fName)

bNumber=false(1,255);
bNumber(abs('0123456789+-.eE'))=true;

if nargin<2
	bFields=true;
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
		d=l(i+1:end);
		if all(bNumber(abs(d)))
			[dNumber,n,err]=sscanf(d,'%g');
			if n==1&&isempty(err)
				d=dNumber;
			end
			S(nS).data.(l(1:i-1))=d;	% check if possible?!
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
