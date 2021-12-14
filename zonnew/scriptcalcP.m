if ~exist('y0','var')||~isscalar(y0)||~isnumeric(y0)
	y0=1900;
end
if ~exist('yE','var')||~isscalar(yE)||~isnumeric(yE)
	yE=3000;
end
t=(calcjd(1,1,y0):calcjd(1,1,yE))';

%%
P=zeros(3,2,length(t));
DD=calcvsop87('aa','zoek');
status('calcAM',0)
for i=1:length(t)
	P(:,1,i)=calcvsop87(DD,t(i));
	P(:,2,i)=calclunarc(t(i));
	status(i/length(t))
end
status

%%
dP=squeeze(P(1,2,:)-P(1,1,:))*(180/pi)+90;dP=dP-floor(dP/360)*360;
	% -90 to have transitions at 90 and 270
i1=find(diff(dP>= 90)==1);	% FM
i2=find(diff(dP>=270)==1);	% NM
tFM=t(i1)+( 90-dP(i1))./(dP(i1+1)-dP(i1)).*(t(i1+1)-t(i1));
tNM=t(i2)+(270-dP(i2))./(dP(i2+1)-dP(i2)).*(t(i2+1)-t(i2));

t0=zeros(length(i1),1);
t1=t0;
for i=1:length(i1);
	dd=calccaldate(t(i1(i)));
	t0(i)=calcjd(1,1,dd(3));
	t1(i)=calcjd(21,3,dd(3));
end

ii=find(diff(t(i1)>t1)==1)+1;
tpfm=t(i1(ii));
tz=calcjd(27,1,2013);
dpfm=mod(tpfm-tz,7);
dpfmz=(7-dpfm);	% fm - Sun ==> next
tp=tpfm+dpfmz;

i0=findclose(tp,calcjd);

getmakefig PPlot
plot(y0:y0-1+length(ii),tp-t1(ii)+t1(ii(i0)))
axtick2date y
grid
