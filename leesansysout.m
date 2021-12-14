function [D,lhead]=leesansysout(fn)
% LEESANSYSLOAD - Leest output van ansys - poging tot....
%   [D,lhead]=leesansysout(fn)

fid=fopen(fn);
if fid<3
	error('Kan file niet openen')
end

Dother={};

lhead=cell(1,50);
nhead=0;
Node=0;
n=0;
items={};
while n==0
	if feof(fid)
		fclose(fid);
		error('File zonder numerieke data?')
	end
	l1=deblank(fgetl(fid));
	if ~isempty(l1)
		while l1(1)==' '|l1(1)==9
			l1(1)='';
		end
		if ~Node
			if l1(1)>='0'&l1(1)<='9'	% laatste headerlijn gemist(!)
				[items,nitems]=getitems(llast);
				Node=1;
				if nhead
					[nietgebruikt,nitems]=getitems(lhead{nhead});
				else
					nitems=0;
				end
			end
		end
		if strcmp(upper(l1(1:min(end,4))),'NODE')
			Node=1;
			[items,nitems]=getitems(l1);
		elseif Node
			[d1,sForm,nitems,l1,n]=getNumForm(l1,nitems);
		end
		lhead{nhead+1}=l1;
		lhead{nhead+2}='...';
		nhead=nhead+2;
		llast=l1;
	end
end
D=d1;
while ~feof(fid)
	D1=fscanf(fid,sForm);
	if rem(length(D1),nitems)
		warning('Er loopt iets fout met aantal getallen.')
		D1=D1(1:end-rem(length(D1),nitems));
	end
	D=[D reshape(D1,nitems,[])];
	n1=0;
	while 1
		l=fgetl(fid);
		if ischar(l)
			l=deblank(l);
			d1=sscanf(l,sForm);
			n1=length(d1);
			if feof(fid)
				break
			end
			if n1
				[itemsn,nitems2]=getitems(llast);
				if ~isequal(items,itemsn)
					Dother{end+1}=D;
					[d1,sForm,nitems,l1,n]=getNumForm(l,nitems2);
					n1=nitems;
					D=zeros(n1,0);
					items=itemsn;
					lhead{nhead+1}=llast;
					lhead{nhead+2}=l;
					lhead{nhead+3}='...';
					nhead=nhead+3;
				end
				break
			elseif ~isempty(l)
				llast=l;
			end
		else
			break;
		end
	end
	if n1==nitems
		D=[D d1];
	end
end
fclose(fid);
lhead=lhead(1:nhead);

if ~isempty(Dother)
	Dother{end+1}=D;
	s2=cellfun('size',Dother,2);
	if all(s2==s2(1))
		s1=cellfun('size',Dother,1);
		D=zeros(sum(s1)-length(s1)+1,s2(1));
		D(1:s1(1),:)=Dother{1};
		k=s1(1);
		for i=2:length(s2)
			D(k+1:k+s1(i)-1,:)=Dother{i}(2:end,:);
		end
	else
		D=Dother;
	end
end

function l=addspaces(l)
% Voeg spaties tussen cijfer en '-' (getallen worden soms "aan
%           elkaar geplakt")
i=2;
while i<=length(l)
	if l(i)=='-'&l(i-1)>='0'&l(i-1)<='9'
		l=l([1:i i:end]);
		l(i)=' ';
	end
	i=i+1;
end

function [elems,nitems]=getitems(l)

l(l==',')=' ';
l(l=='(')=' ';
l(l==')')=' ';
[sdum,nitems]=sscanf(l,'%s');
elems=cell(1,nitems);
nxt=1;
for i=1:nitems
	[elems{i},n,err,nxt1]=sscanf(l(nxt:end),'%s',1);
	nxt=nxt+nxt1-1;
end

function [d1,sForm,nitems,l1,n]=getNumForm(l1,nitems)
sForm='%g';
l1=addspaces(l1);
d1=sscanf(l1,sForm);
n=length(d1);
% !!!!heel wat geknoei!!!
if n<nitems
	% dit omdat soms meerdere woorden gebruikt worden voor 1
	% element
	warning('!!!stringdata??? --- wordt genegeerd!!! --- en moet constant zijn!!\n     mogelijk verkeerde interpretatie header\n     %s',l1)
	cF=cell(1,2*nitems);
	in=1;
	for i=1:nitems
		[cF{i*2-1},n1,err1,in1]=sscanf(l1(in:end),'%s',1);
		d1=str2num(cF{i*2-1});
		if ~isempty(d1)
			cF{i*2-1}='%g';
		else
			nitems=nitems-1;
		end
		cF{i*2}=' ';
		in=in+in1-1;
	end
	cF{end}='\n';
	sForm=cat(2,cF{1:end});
	d1=sscanf(l1,sForm);
elseif n>nitems
	% dit omdat soms meerdere getallen gegeven worden voor 1
	% type data
	% !!!!de combinatie van te veel en te weinig wordt niet
	% gemerkt!!!!!
	nitems=n;
end
