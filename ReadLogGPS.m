function D=ReadLogGPS(fname)
%ReadLogGPS - Read log file of GPS
%      D=ReadLogGPS(fname)

if isstruct(fname)
	if length(fname)>1
		fname={fname.name};
	else
		fname=fname.name;
		% other directory information could be used! (especially size for
		% improved status input!
	end
end
nP={'t','latitude','longitude','height'};
if iscell(fname)
	DC=cell(1,length(fname));
	if isstruct(fname)
		fname=sort(fname,'name');
	else
		fname=sort(fname);
	end
	status(sprintf('Reading multiple (%d) GPS-files',length(fname)),0);
	parts=zeros(length(fname),3);
	Iok=zeros(1,length(fname));
	tLast=-Inf;
	for i=1:length(fname)
		D=ReadLogGPS(fname{i});
		DC{i}=D.P;
		if ~isempty(D.P)
			parts(i, 1)   =D.P(1);
			parts(i, 2)   =D.P(end,1);
			parts(i, 3)   =size(D.P,1);
			parts(i, 4:5 )=D.P(1,2:3);
			parts(i, 6:7 )=D.P(end,2:3);
			parts(i, 8:9 )=min(D.P(:,2:3));
			parts(i,10:11)=max(D.P(:,2:3));
			if D.P(1)-tLast<5/1440	% time difference < 5 minutes
				Iok(i)=-1;
			else
				Iok(i)=size(D.P,1)>4;
			end
			tLast=D.P(end,1);
		end
		status(i/length(fname))
	end
	status
	D.partsOK=Iok;
	D.removedPartN=fname(Iok==0);
	D.removedParts=parts(Iok==0,:);
	D.removedD=DC(Iok==0);
	D.files=fname(Iok>0);
	D.nP=nP;
	if any(diff(parts(:,1)<0))
		warning('RLGPS:NoIncTime','Not a logic order of files!')
	end
	D.P=cat(1,DC{Iok>0});
	D.parts=parts(Iok>0,:);
	D.nParts={'t_start','t_end','nPoints','p0_lat','p0_long'	...
		,'pe_lat','pe_long','min_lat','min_long','max_lat','max_long'};
	return
end
if ~exist(fname,'file')
	fname=zetev([],fname);
end
c=cBufTextFile(fname);
L=fgetlN(c,10000);

iL=0;
LNr=0;
P=zeros(10000,4);
nP=0;
t0=0;
status('Reading GPS logfile',0);
while iL<length(L)
	iL=iL+1;
	l=deblank(L{iL});
	if isempty(l)
		continue
	end
	[~,n,err,iNxt]=sscanf(l,'%s',1);	% wt not used anymore
	if n==1
		[w,n,err,iNxt1]=sscanf(l(iNxt:end),'%s',1);
		iNxt=iNxt+iNxt1-1;
		if n==1&&w(1)=='$'
			[w2,n,err,iNxt1]=sscanf(l(iNxt:end),'%s',1);
			iNxt=iNxt+iNxt1-1;
			if n==1
				if strncmp(w2,'GL',2)
					%t1=datenum(wt);	% only time
					%t1=t1-floor(t1);	% !!!!
					switch str2double(w2(3:end))
						case 100
							if false
								if wt(3)==':'&&wt(6)==':'
									t1=str2double(wt(1:2))/24	...
										+str2double(wt(4:5))/1440	...
										+str2double(wt(7:end))/86400;
								else
									t1=datenum(wt);	% normally not used!
									t1=t1-floor(t1);	% !!!!
								end
							end
							[w,~,~,iNxt1]=sscanf(l(iNxt:end),'%s',1);
							iNxt=iNxt+iNxt1-1;
							switch w
								case 'Tim'
									t0=datenum(l(iNxt+3:end),'yyyy-mmm-dd HH:MM:SS');
								case 'Pos'
									pos=sscanf(strtrim(l(iNxt:end)),'[%g %g %g]',3);
									nP=nP+1;
									if nP>size(P,1)
										P(end+1000,1)=0; %#ok<AGROW>
									end
									P(nP)=t0;
									%P(nP,2)=LNr+iL;
									P(nP,2:4)=pos;
							end
					end
				end
			else
				%do nothing...
				%warning('READLOGGPS:WordExtractError3','error extracting word 2 (#%d: %s)',LNr+iL,err)
			end
		elseif n==0
			warning('READLOGGPS:WordExtractError2','error extracting word 2 (#%d: %s)',LNr+iL,err)
		end
	else
		warning('READLOGGPS:WordExtractError1','error extracting word (#%d: %s)',LNr+iL,err)
	end
	if iL>=length(L)&&~feof(c)
		status(c.iFile/c.lFile)
		LNr=LNr+length(L);
		L=fgetlN(c,10000);
		iL=0;
	end
end
status
i1=1;

if nP>3
	dA=sqrt(sum(diff(P(1:4,2:3)).^2,2));
	if any(dA>2e-3)
		i1=find(dA>2e-3,1,'last')+1;
	end
end

P=P(i1:nP,:);
nP=nP+1-i1;
B=all(P(1:nP-1,2:4)==P(2:nP,2:4),2);
B=B(1:nP-2)&B(2:nP-1);
if any(B)
	P([false;B],:)=[];
	nP=size(P,1);
end
i=1;
while i<nP
	j=i+1;
	if P(i)>=P(i+1)	% constant time or decreasing
		% is decreasing time possible?
		while j<=nP&&P(j)<=P(i)
			j=j+1;
		end
		if j>nP
			P(i+1:nP)=P(i)+(1:nP-i)'*median(diff(P(:,1)));
			break
		end
		k=i+1;
		while k<j
			P(k)=P(i)+(P(j)-P(i))/(j-i)*(k-i);
			k=k+1;
		end
	end
	i=j;
end

D=struct('P',P,'nP',{nP});
