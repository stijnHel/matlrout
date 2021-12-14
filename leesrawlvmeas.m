function [A,namen,dim,B,gegs,str,err] = leesrawlvmeas(naam,start,lengte,ongeschaald,kanalen)
%LEESRAWLVMEAS - Leest binaire data van labView-DAQ assistant

%!!gebaseerd op 1 test

fid=fopen(zetev([],naam),'r','ieee-be');
if fid<3
	fid=fopen(naam,'r','ieee-be');
	if fid<3
		error('Kan file niet openen')
	end
end

fseek(fid,0,'eof');
ltot=ftell(fid);
fseek(fid,0,'bof');

B=[];
if nargout>5
	str=cell(0,6);
end
bTest=nargout>5;
PB=zeros(0,1);

DT=zeros(0,1);
bDifDt=false;
bDifND=false;
bDifs=false;
nSteps=0;
nA=0;
t0=0;
facT=[1 2^-32];
while ~feof(fid)
	nKan=fread(fid,1,'int');
	if isempty(nKan)
		break;
	end
	if nSteps==0
		A=zeros(0,nKan+1);
		namen=cell(1,nKan+1);
		dim=cell(1,nKan+1);
	end
	nSteps=nSteps+1;
	for iKan=1:nKan
		h1=fread(fid,4,'uint');	% starttijd
		dt=fread(fid,1,'double'); % sample-tijd
		nD=fread(fid,1,'int');	% aantal meetpunten
		D=fread(fid,nD,'double');	% meetpunten
		t1=fread(fid,21,'*uint8');	% 
		d1=leesstring(fid);
		if ~strcmp(d1,'NI_ChannelName')
			if ~bDifs
				bDifs=true;
				warning('Andere data dan verwacht!!')
			end
		end
		t2=fread(fid,6,'short');	% ?amplifier-data, ...?
		knaam=leesstring(fid);
		t3=fread(fid,1,'long');	% ?altijd 0
		d2=leesstring(fid);
		if ~strcmp(d2,'NI_UnitDescription')
			if ~bDifs
				bDifs=true;
				warning('Andere data dan verwacht!!')
			end
		end
		t4=fread(fid,6,'short');
		kdim=leesstring(fid);
		if length(D)~=nD||feof(fid)||ftell(fid)+4>ltot
			warning('!!vroegtijdig einde!!')
			break;
		end
		t5=fread(fid,1,'long');	% ?altijd 0
		
		if nSteps==1
			namen{iKan+1}=knaam;
			dim{iKan+1}=kdim;
		end
		
		if iKan==1
			t=facT*h1(2:3);	% (tijd wordt nog nauwkeuriger weggeschreven)
			A(nA+1:nA+nD,2)=D;
			DT(nSteps,1)=dt;
			nDcur=nD;
			if nargout>5
				str{nSteps,1}=h1;
				str{nSteps,2}=t1;
				str{nSteps,3}=t2;
				str{nSteps,4}=t3;
				str{nSteps,5}=t4;
				str{nSteps,6}=t5;
			end
		else
			if bTest
				str1={h1,t1,t2,t3,t4,t5};
				for i=1:length(str1)
					if ischar(str1{i})	% dit komt nu niet meer voor
						if ~strcmp(str1{i},str{nSteps,i}(end,:))
							if size(str{nSteps,i},1)<iKan-1
								str{nSteps,i}(end+1,:)=str{nSteps,i}(end,:);
							end
							str{nSteps,i}=strvcat(str{nSteps,i},str1{i});
						end
					elseif ~isequal(str1{i},str{nSteps,i}(:,end))
						str{nSteps,i}=[str{nSteps,i}(:,[1:end-1 end+zeros(1,iKan-size(str{nSteps,i},2))]) str1{i}];
					end
				end
			end
			if nDcur~=nD
				if ~bDifND
					bDifND=true;
					warning('!!verschillende groottes van gedeeltes!!')
				end
			end
			A(nA+1:nA+nD,iKan+1)=D;
			if dt~=DT(nSteps)
				if ~bDifDt
					bDifDt=true;
					warning('!!!verschillende tijdstappen!!')
				end
			end
		end	% iKan==1
	end	% for iKan
	if nSteps==1
		nKanStart=nKan;
		l1=ftell(fid);
		nBlok=ceil(ltot/l1);
		A(nD*nBlok,1)=0;
		str{nBlok,1}=[];
		DT(nBlok,1)=1;
		if bTest
			PB(nBlok,1)=0;
		end
		A(1:nD)=(0:nD-1)*dt;
		t0=t;
	else
		A(nA+1:nA+nD,1)=(0:nD-1)*dt+(t-t0);
	end
	if bTest
		PB(nSteps)=ftell(fid);
	end
	nA=nA+nD;
end	% while
fclose(fid);
namen{1}='t';
dim{1}='s';
if nA<size(A,1)
	A=A(1:nA,:);
end
if nSteps<nBlok
	DT=DT(1:nSteps);
	str=str(1:nSteps,:);
end
if nargout>4
	gegs=zeros(1,18);
	tLVstart=datenum([1904 1 1]);
	t=tLVstart+(t0/3600+2)/24;	% offset UTC - zomertijd(!)
	tVec=datevec(t);
	gegs(4:6)=tVec([3 2 1]);
	gegs(7:9)=tVec(4:6);
	gegs(11)=nKanStart;
	gegs(12)=dt;
	gegs(17)=nA;
	gegs(18)=ltot;
end

function s=leesstring(fid);
n=fread(fid,1,'int');
s=fread(fid,[1 n],'*char');
