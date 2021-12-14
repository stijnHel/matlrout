function D=readCANtrc(fn)
%readCANtrc - Reads CAN-trace of ???
%    D=readCANtrc(fn)

c=cBufTextFile(fFullPath(fn));
L=fgetlN(c,10000);
iL=1;
head={};
lNr=0;
nMSGs=0;
T=zeros(10000,1);
ID=T;
TYP=T;
IDX=T;
DATA=zeros(10000,9);
msgTyp={'Rx','Tx'};
t0=-100;

while iL<=length(L)
	l=L{iL};
	iL=iL+1;
	if iL>length(L)
		L=fgetlN(c,10000);
		iL=1;
	end
	lNr=lNr+1;
	if isempty(l)
		% do nothing (only the last line, normally)
	elseif l(1)==';'
		head{1,end+1}=l; %#ok<AGROW>
	else
		B=l==')';
		if ~any(B)
			error(''')'' expected (#%d: %s)',lNr,l)
		end
		[d,n,err,iNxt]=sscanf(l,'%d) %g %c%c%c%c %x %d',[1 8]);
		if n<8
			error('Error while interpreting line (#%d: %s) - %s',lNr,l,err)
		end
		idx=d(1);	% normally continuously increasing (step 1)
		t=d(2);	% ms
		if t==t0
			t=t+1e-5;	% make sure the order is kept
		end
		typ=deblank(char(d(3:6)));
		iTyp=find(strcmp(typ,msgTyp));
		if isempty(iTyp)
			msgTyp{end+1}=typ; %#ok<AGROW>
			iTyp=length(msgTyp);
		end
		ID1=d(7);
		lData=d(8);
		if lData==0
			data=[];
		else
			data=sscanf(l(iNxt:end),'%x',[1 n]);
		end
		if nMSGs>=length(T)
			T(end+10000)=0;
			ID(length(T))=0;
			TYP(length(T))=0;
			IDX(length(T))=0;
			DATA(length(T),1)=0;
		end
		nMSGs=nMSGs+1;
		T(nMSGs)=t;
		ID(nMSGs)=ID1;
		TYP(nMSGs)=iTyp;
		IDX(nMSGs)=idx;
		DATA(nMSGs)=lData;
		DATA(nMSGs,2:lData+1)=data;
	end
end
T=T(1:nMSGs);
ID=ID(1:nMSGs);
IDX=IDX(1:nMSGs);
TYP=TYP(1:nMSGs);
DATA=DATA(1:nMSGs,:);
uID=unique(ID);
nID=hist(ID,uID);
iID=cell(1,length(uID));
for i=1:length(uID)
	iID{i}=find(ID==uID(i));
end

D=struct('head',{head},'T',T,'ID',ID,'D',DATA,'type',TYP,'IDX',IDX	...
	,'msgTyp',{msgTyp}	...
	,'uID',uID,'nID',nID,'iID',{iID});
