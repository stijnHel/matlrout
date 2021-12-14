function [Dout,info,users]=getprocdata(expr,user)
%GETPROCDATA - Geeft proces-data gebaseerd op expressie

bParentCheck=false;
if ~exist('expr','var')||~ischar(expr)
	expr='MATLAB';
	bParentCheck=true;
end
if isempty(expr)
	[~,w]=dos('ps aux');
	removeTests={'ps aux'};
else
	[~,w]=dos(['ps aux|grep ' expr]);
	removeTests={'ps aux',['grep ' expr]};
end
iCR=[0 find(w==10)];
if length(iCR)<3
	error('Geen proces gevonden')
end
nKol=11+double(bParentCheck)*5;
D=cell(length(iCR)-3,nKol);
D1=cell(1,11);
iLok=0;
for iLine=1:length(iCR)-1
	bDex=false;
	l1=w(iCR(iLine)+1:iCR(iLine+1)-1);
	bOK=true;
	for j=1:length(removeTests)
		if ~isempty(strfind(l1,removeTests{j}))
			bOK=false;
			break
		end
	end
	if bOK
		iLok=iLok+1;
		D1=leeslijn(l1,D1);
		if bParentCheck
			[~,w1]=dos(sprintf('ps -f %d',D1{2}));
			iCR1=find(w1==10);
			if length(iCR1)==2	% en anders?
				D2=leeslijn(w1(iCR1(1)+1:iCR1(2)-1),cell(1,4));
				[~,w1]=dos(sprintf('ps %d',D2{3}));
				iCR1=find(w1==10);
				if length(iCR1)==2
					bDex=true;
					iStart=iCR1(1)+1;
					while w1(iStart)==' '
						iStart=iStart+1;
					end
					Dex=leeslijn(w1(iStart:iCR1(2)-1),cell(1,5));
					D1{end}=[D1{end} ' # ' Dex{5}];
				end
			end
		end
		[D{iLok,1:11}]=D1{:};
		if bDex
			[D{iLok,12:11+length(Dex)}]=Dex{:};
		end
	end
end
D=D(1:iLok,:);
if nargin>1&&~isempty(user)
	B=false(1,iLok);
	for i=1:iLok
		B(i)=~isempty(strfind(D{i,16},user))||~isempty(strfind(D{i,11},user));
	end
	D=D(B,:);
end
if nargout==0
	fprintf('prID  : username   mem-use            - start  cpu     - command\n')
	if bParentCheck
		sForm='%5d : %-8s %8d KB (%4.1f %%) - %-6s %-7s - (%5d) %s\n';
		dPrint=[2 1 6 4 9 10 12 11];
	else
		sForm='%5d : %-8s %8d KB (%4.1f %%) - %-6s %-7s - %s\n';
		dPrint=[2 1 6 4 9 10 11];
	end
	for i=1:size(D,1)
		fprintf(sForm,D{i,dPrint}) %#ok<PRTCAL>
	end
	i=find(cat(2,D{:,12})==1);
	if ~isempty(i)
		fprintf('!!parent-less : %d',D{i(1),2})
		if length(i)>1
			fprintf(',%d',D{i(2:end),2})
		end
		fprintf('!!\n')
	end
else
	Dout=D;
	if nargout>1
		if bParentCheck
			info={'user','PID','%??cpu','%mem','?memtot','memRSS','display','??','tStart','tCPU','command'	...
				,'PPID','Pdisp','P??','PtCPU','Pcommand'};
		else
			info={'user','PID','%??cpu','%mem','?memtot','memRSS','display','??','tStart','tCPU','command'};
		end
		if nargout>2
			users=cell(2,iLok);
			for i=1:iLok
				l=D{i,16};
				j=strfind(l,'/matlab');
				if isempty(j)
					users{1,i}='?';
					users{2,i}='-';
				else
					l=l(j(end)+7:end);
					if l(1)==' '
						users{2,i}='?';
					else
						[v,n,~,inxt]=sscanf(l,'%d',1);
						if n<1
							users{2,i}='??';
						else
							users{2,i}=v;
							l=l(inxt:end);
						end
					end
					l=strtrim(l);
					if any(l=='-');
						l=deblank(l(1:find(l=='-',1)));
					end
					users{1,i}=l;
				end
			end
		end
	end
end

function D=leeslijn(l1,D)
l1(end+1)=0;
j=1;
for n=1:length(D)-1
	j0=j;
	while l1(j)~=' '
		j=j+1;
	end
	w1=l1(j0:j-1);
	if all((w1>='0'&w1<='9')|w1=='.')&&sum(w1=='.')<=1
		D{n}=str2double(w1);
	else
		D{n}=w1;
	end
	while l1(j)==' '
		j=j+1;
	end
end
D{end}=l1(j:end-1);
