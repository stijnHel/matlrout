function a=interpkline(e, baud, metInit)
% INTERPKLINE - Interpreteert k-lijn-meting

if ~exist('metInit','var')
	metInit=-1;
end
metgraf=0;	% 0 geen, 1 begin en eind van byte, 2 ook bits

dtB=1/baud;
dt=mean(diff(e(:,1)));
iDaal=find(e(2:end,2)<4&e(1:end-1,2)>=4);
iByte=1;

Nt1=round(1/dt);
Nt3=round(3/dt);

if metInit
	% ???keuze tussen 5 Baud init of Fast init???
	while iByte<length(iDaal)-10	% (10 snel genomen minimum)
		i=iDaal(iByte);
		j=find(e(i+1:min(i+Nt1),2)>5);
		if ~isempty(j)
			j=j(1);
			if abs(e(i+j)-e(i)-0.025)>0.005	% TiniL
				if metInit<0
					metInit=0;
					break;
				else
					error('Verkeerde initialisatie')
				end
			end
			iByte=iByte+1;
			if abs(e(iDaal(iByte+1))-e(i)-0.05)>0.005	% T_WuP
				error('Verkeerde initialisatie')
			end
			break;
		end
		iByte=iByte+1;
	end
end
ia=0;
a=zeros(10000,2);

for aa=1:10000
	i=iDaal(iByte)+floor(dtB/2/dt);
	nBit=8;
	i1=i+round((1:nBit)*dtB/dt);
	i2=i1(end)+round(dtB/dt);
	if i2>length(e)
		break;
	end
	ok=0;
	if dtB/dt>3
		if e(i2,2)<4
			if metgraf
				line([0 0]+e(i,1),[0 10],'color',[0 1 0],'linestyle',':')
				line([0 0]+e(i2,1),[0 10],'color',[1 0 0],'linestyle',':')
				for k=1:nBit
					line([0 0 0 0 0]+e(i1(k)),[0 1 nan 9 10],'color',[0 1 0],'linestyle',':')
				end
			end
		else
			k=[1 2 4 8 16 32 64 128]*(e(i1,2)>=4);
			if metgraf
				line([0 0]+e(i,1),[0 10],'color',[0 1 0])
				line([0 0]+e(i2,1),[0 10],'color',[1 0 0])
				text(e(i2,1),10.1,sprintf('%02x',k),'horizontalal','left','verticalal','bottom')
				if metgraf>1
					for k=1:nBit
						line([0 0 0 0 0]+e(i1(k)),[0 1 nan 9 10],'color',[0 1 0])
					end
				end
			end
			ok=1;
		end
	else	% low measurement frequency
		ni=ceil((nBit+2)*dtB/dt);
		dt1=dtB/10;
		e1=interp1(e(i:i+ni),e(i:i+ni,2),e(i):dt1:e(i+ni))';

		i1_=10+round((1:nBit)*dtB/dt1);
		i2_=i1_(end)+round(dtB/dt1);
		if e1(i2_)<4
			if metgraf
				line([0 0]+e(i,1),[0 10],'color',[0 1 0],'linestyle',':')
				line([0 0]+e(i2,1),[0 10],'color',[1 0 0],'linestyle',':')
				for k=1:nBit
					line([0 0 0 0 0]+e(i)+k*dtB,[0 1 nan 9 10],'color',[0 1 0],'linestyle',':')
				end
			end
		else
			k=[1 2 4 8 16 32 64 128]*(e1(i1_)>=4);
			if metgraf
				line([0 0]+e(i,1),[0 10],'color',[0 1 0])
				line([0 0]+e(i2,1),[0 10],'color',[1 0 0])
				text(e(i2,1),10.1,sprintf('%02x',k),'horizontalal','left','verticalal','bottom')
				if metgraf>1
					for k=1:nBit
						line([0 0 0 0 0]+e(i)+k*dtB,[0 1 nan 9 10],'color',[0 1 0])
					end
				end
			end
			ok=1;
		end
	end
	if ok
		ia=ia+1;
		a(ia,1)=e(i2,1);
		a(ia,2)=k;
	end
	while iDaal(iByte)<i2
		iByte=iByte+1;
		if iByte>length(iDaal)
			a=a(1:ia,:);
			return;
		end
	end
end

a=a(1:ia,:);
