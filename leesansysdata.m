function [Xt,stat]=leesansysdata(fn)
% LEESANSYSSTRUC - Leest output van ansys - nog een poging
%   D=leesansysdata(fn)
%      probeert aaneengesloten gedeeltes te lezen
%          aangesloten gedeelte start met '---[-*]abc[-*]---'

fid=fopen(fn);
if fid<3
	error('Kan file niet openen')
end

nStat=0;
lStat=cell(1000,4);
iLijn=0;

cGetal=zeros(1,255);
cGetal(abs('-.0123456789'))=1;	% !enkel voor starts

X=struct('type',cell(1,0),'data',cell(1,0),'info',cell(1,0));
soortD=0;
D=[];
Dinfo={};
n=0;
nWarnings=zeros(1,5);
Xt=struct('deel',cell(1,0),'data',cell(1,0));
sdeel='';
fseek(fid,0,'eof');
lfile=ftell(fid);
fseek(fid,0,'bof');
bStatus=0;
if lfile>10000
	status('Lezen van grote ansys-output-file',0);
	bStatus=1;
end
while ~feof(fid)
	iLijn=iLijn+1;
	l=strtrim(fgetl(fid));
	if strcmp(l(1:min(3,end)),'---')&&strcmp(l(max(1,end-2):end),'---')
		if bStatus
			status(ftell(fid)/lfile)
		end
		if ~isempty(D)
			X(1,end+1)=struct('type',soortD,'data',D,'info',{Dinfo});
			D=[];
		end
		soortD=0;
		if ~isempty(X)
			Xt(1,end+1)=struct('deel',sdeel,'data',X);
			X(:)=[];
		end
		sdeel=l(l~='-');
		if isempty(sdeel)
			warning('??leeg gedeelte??')
			sdeel='x';
		end
		if ~isempty(Xt)
			i=strmatch(sdeel,{Xt.deel});
			if ~isempty(i)
				if length(i)==1
					sdeel=[sdeel '_2'];
				else
					sd1=Xt(i(end)).deel;
					if any(sd1=='_')
						i=find(sd1=='_');
						k=str2num(sd1(i(end)+1:end));
						if isempty(k)
							sdeel=[sd1(1:i(end)) num2str(length(i)+1)];
						else
							sdeel=[sd1(1:i(end)) num2str(max(k)+1)];
						end
					else
						sdeel=[sdeel '_' num2str(length(i)+1)];
					end
				end
			end
		end
		continue
	end
	if ~isempty(sdeel)&~isempty(l)
		if cGetal(abs(l(1)))
			if soortD<=0
				if ~nWarnings(4)
					warning('!!!!getalleninput zonder gekende data-soort!!! (lijn %d)',iLijn)
				end
				nWarnings(4)=nWarnings(4)+1;
				soortD=98;	% neem toch iets
				nStat=nStat+1;
				lStat{nStat,1}=length(Xt)+1;
				lStat{nStat,2}=4;
				lStat{nStat,3}=iLijn;
				lStat{nStat,4}=l;
			end
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
							warning('!!!toch verkeerde interpretatie!!! (lijn %d)',iLijn)
						end
						nWarnings(5)=nWarnings(5)+1;
						D(end+1,:)=d1(1:nwds)';
						nStat=nStat+1;
						lStat{nStat,1}=length(Xt)+1;
						lStat{nStat,2}=5;
						lStat{nStat,3}=iLijn;
						lStat{nStat,4}=l;
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
						warning('!!!!verkeerde lengte!!! (lijn %d, %s)',iLijn,l)
					end
					nWarnings(1)=nWarnings(1)+1;
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
		elseif l(1)=='*'
			%continue - doe niets
		elseif strcmp(l(1:min(5,end)),'PRINT')
			if bStatus
				status(ftell(fid)/lfile)
			end
			[wds,nwds]=getitems(l);
			if nwds>3&strcmp(wds{2},'ALONG')&strcmp(wds{3},'PATH')
				nSoort=1;
			elseif ~isempty(strmatch('SOLUTION',wds))
				nSoort=80;	% niet volledig "uitgespind", maar...
			else
				if ~nWarnings(2)
					warning('Dit type is onbekend (lijn %d, %s)',iLijn,l)
				end
				nWarnings(2)=nWarnings(2)+1;
				nSoort=-1;
				nStat=nStat+1;
				lStat{nStat,1}=length(Xt)+1;
				lStat{nStat,2}=2;
				lStat{nStat,3}=iLijn;
				lStat{nStat,4}=l;
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
			if bStatus
				status(ftell(fid)/lfile)
			end
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
			elseif ~isempty(strmatch('NODES',wds))
				soortD=6;
			else
				soortD=99;
			end
		elseif strcmp(l(1:min(9,end)),'LOAD STEP')
		elseif strcmp(l(1:min(5,end)),'TIME=')
		elseif strcmp(l,'MAXIMUM ABSOLUTE VALUES')
			% is dit veilig genoeg?
			for i=1:nwds
				l=fgetl(fid);
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
						warning('!!!!!onverwachte wijziging van gegevens!!!!(lijn %d, %s)',iLijn,l)
					end
					nWarnings(3)=nWarnings(3)+1;
					nStat=nStat+1;
					lStat{nStat,1}=length(Xt)+1;
					lStat{nStat,2}=3;
					lStat{nStat,3}=iLijn;
					lStat{nStat,4}=l;
				end
				nwds=nwds1;
			end
		end
	end
end
if bStatus
	status
end
fclose(fid);
if ~isempty(D)
	X(1,end+1)=struct('type',soortD,'data',D,'info',{Dinfo});
end
if ~isempty(X)
	Xt(1,end+1)=struct('deel',sdeel,'data',X);
end
if nargout>1
	stat=struct('nLijn',iLijn,'nWarn',nWarnings,'lStat',{lStat(1:nStat,:)});
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
