function [X,lhead]=leesansysstruc(fn)
% LEESANSYSSTRUC - Leest output van ansys - strucout.lgw
%   [D,lhead]=leesansysstruc(fn)

if ~exist('fn','var')
	fn='/users/shel/ansysfiles/strucout.txt';
end

fid=fopen(fn);
if fid<3
	error('Kan file niet openen')
end

bHead1=1;
lhead=cell(1,10);
nhead=0;
iLijn=1;
l=strtrim(fgetl(fid));

while ~strcmp(l,'---------structuur-------')
	nhead=nhead+1;
	lhead{nhead}=l;
	if feof(fid)
		fclose(fid);
		error('Te korte file - of verkeerde data')
	end
	iLijn=iLijn+1;
	l=strtrim(fgetl(fid));
end

cGetal=zeros(1,255);
cGetal(abs('-.0123456789'))=1;	% !enkel voor starts

X=struct('type',cell(1,0),'data',cell(1,0),'info',cell(1,0));
soortD=0;
D=[];
Dinfo={};
n=0;
nWarnings=zeros(1,5);
while ~feof(fid)
	iLijn=iLijn+1;
	l=strtrim(fgetl(fid));
	if ~isempty(l)
		if cGetal(abs(l(1)))
			if soortD<=0
				if ~nWarnings(4)
					nWarnings(4)=nWarnings(4)+1;
					warning('!!!!getalleninput zonder gekende data-soort!!! (lijn %d)',iLijn)
				end
			else
				l1=addspaces(l);
				d1=sscanf(l1,'%g');
				if length(d1)==0
					warning('!!!!geen getallen gelezen in lijn %d ("%s")!!!',iLijn,l)
				elseif nwds==0
					nwds=length(d1);
					D=d1';
				elseif length(d1)~=nwds
					if soortD==4|soortD==5
						if isempty(D)
							error('!!Dit kan niet!!')
						end
						if length(d1)>nwds
							if ~nWarnings(5)
								nWarnings(5)=nWarnings(5)+1;
								warning('!!!toch verkeerde interpretatie!!! (lijn %d)',iLijn)
							end
							D(end+1,:)=d1(1:nwds)';
						else
							D(end+1,1)=D(end,1);
							if length(d1)>4	% ???eerder naar positie van eerste getal kijken???
								D(end,2:1+length(d1))=d1';
							else
								D(end,3:2+length(d1))=d1';
							end
						end
					else
						if ~nWarnings(1)
							nWarnings(1)=nWarnings(1)+1;
							warning('!!!!verkeerde lengte!!! (lijn %d, %s)',iLijn,l)
						end
						if length(d1)<nwds
							D(end+1,1:length(d1))=d1';
						else
							D(end+1,:)=d1(1:nwds)';
						end
					end
				else
					D(end+1,:)=d1';
					%D(end+1,1:nwds)=d1';	% 1:nwds toegevoegd voor sneloplossing probleem!!???
				end
			end
		elseif l(1)=='*'
			%continue - doe niets
		elseif strcmp(l(1:min(5,end)),'PRINT')
			[wds,nwds]=getitems(l);
			if nwds>3&strcmp(wds{2},'ALONG')&strcmp(wds{3},'PATH')
				nSoort=1;
			else
				if ~nWarnings(2)
					nWarnings(2)=nWarnings(2)+1;
					warning('Dit type is onbekend (lijn %d, %s)',iLijn,l)
				end
				soortD=-1;
			end
			if soortD
				% ?testen voor toevoegen van data?
				X(1,end+1)=struct('type',soortD,'data',D,'info',{Dinfo});
			end
			soortD=nSoort;
			D=[];
			nwds=0;
			Dinfo(:)=[];
		elseif strcmp(l(1:min(4,end)),'LIST')
			if soortD
				X(1,end+1)=struct('type',soortD,'data',D,'info',{Dinfo});
				soortD=0;
				D=[];
			end
			l(l=='.')=='';
			[wds,nwds1]=getitems(l);
			nwds=0;
			if ~isempty(strmatch('KEYPOINTS',wds))
				soortD=2;
			elseif ~isempty(strmatch('LINES',wds))
				soortD=3;
			elseif ~isempty(strmatch('AREAS',wds))
				soortD=4;
			elseif ~isempty(strmatch('VOLUMES',wds))
				soortD=5;
			end
		else
			[wds,nwds1]=getitems(l);
			if soortD>=2&soortD<=5
				Dinfo=wds;
				% er wordt gerekend op een vaste header
			elseif isempty(D)
				Dinfo=wds;
				D=zeros(0,nwds1);
				nwds=nwds1;
			else
				if ~isequal(Dinfo,wds)
					if ~nWarnings(3)
						nWarnings(3)=nWarnings(3)+1;
						warning('!!!!!onverwachte wijziging van gegevens!!!!(lijn %d, %s)',iLijn,l)
					end
				end
				nwds=nwds1;
			end
		end
	end
end
lhead=lhead(1:nhead);
fclose(fid);
if ~isempty(D)
	X(1,end+1)=struct('type',soortD,'data',D,'info',{Dinfo});
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
