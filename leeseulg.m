function out=leeseulg(fn)
%LEESEULG - Leest eudora audit file
if ~exist('fn','var')||isempty(fn)
	fn='Audit.log';
elseif isdir(fn)
	if fn(end)~=filesep
		fn(end+1)=filesep;
	end
	fn=[fn 'Audit.log'];
end
fid=fopen(fn);
if fid<3
	error('kan file niet openen')
end
l='';
while ~strcmp(l(1:min(end,5)),'=====')
	l=fgetl(fid);
end
l=fgetl(fid);
if ~strcmp(upper(deblank(l)),'INFO STARTS HERE')
	error('kan begin niet vinden')
end
l=fgetl(fid);
if ~strcmp(l(1:min(end,5)),'=====')
	error('kan begin niet vinden (2)')
end
D1=zeros(10000,4);
D2=cell(1,10000);
n=0;
while ~feof(fid)
	l=fgetl(fid);
	d=sscanf(l,'%g');
	if length(d)>2
		n=n+1;
		D1(n,1:3)=d(1:3);
		dat=sscanf(l,'%02d',5);
		D1(n,4)=datenum(dat(1)+2000,dat(2),dat(3),dat(4),dat(5),0);
		D2{n}=d(4:end);
	end
end
fclose(fid);
D1=D1(1:n,:);
D2=D2(1:n);

iT0=find(D1(:,3)==1);
A=cat(2,D2{iT0})';
Tcum=cumsum(A(:,1));
tt=Tcum./max(1,D1(iT0,4)-D1(1,4))/60;
Tvec=datevec(D1(iT0,4));
iT=find((diff([0;Tvec(:,1:3)*[372;31;1]])>0));
t=D1(iT0,4)-D1(1,4);
DT=(Tcum(iT(2:end))-Tcum(iT(1:end-1)))./(t(iT(2:end))-t(iT(1:end-1)))/60;
tDT=(t(iT(2:end))+t(iT(1:end-1)))/2;
meanDT=(Tcum(iT(41:end))-Tcum(iT(1:end-40)))./(t(iT(41:end))-t(iT(1:end-40)))/60;
tM=(t(iT(41:end))+t(iT(1:end-40)))/2;

if nargout
	out=struct('D1',D1,'D2',{D2},'iT0',iT0,'iT',iT,'Tcum',Tcum,'t',t	...
		,'MinPerDag',tt	...
		,'tDT',tDT,'DT',DT	...
		,'tM',tM,'meanDT',meanDT	...
		);
else
	nfigure
	plot(t(3:end),tt(3:end),tDT,DT,tM,meanDT);grid
end
