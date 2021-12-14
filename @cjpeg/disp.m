function disp(c,i1,i2,cinfo)
% CJPEG/DISP
%    disp(c,i1,i2,info)
%        info : 0 - alles
%               1 - verkorting van RST_x

if ~exist('i1','var')||isempty(i1)
	i1=1;
end
if ~exist('i2','var')||isempty(i2)
	i2=length(c.data);
end
if ~exist('cinfo','var')||isempty(cinfo)
	cinfo=0;
end
if ischar(c.ruw)
	i=find(c.ruw=='(');
	if isempty(i)
		warning('!!onbekende ruwe jpeg-data!!')
	else
		lFile=sscanf(c.ruw(i+1:end),'%d',1);
	end
else
	lFile=length(c.ruw);
end
nDatabytes=0;
nNotPrintMarkers=0;

i0=0;
for i=i1:i2
	data=c.data(i);
	if i0+1<data.index
		nDatabytes=nDatabytes+data.index-i0-1;
	end
	i0=data.index+2+data.len;
	pr=1;
	if bitand(cinfo,1)
		if data.marker>=208&&data.marker<=215
			pr=0;
		end
	end
	if pr
		bTemp=0;
		if nDatabytes
			bTemp=1;
			fprintf('   %d databytes',nDatabytes);
			nDatabytes=0;
		end
		if nNotPrintMarkers
			bTemp=1;
			fprintf('   (%d markers)',nNotPrintMarkers)
			nNotPrintMarkers=0;
		end
		if bTemp
			fprintf('\n')
		end
		fprintf('%4d : %-7s (%4d)',i,data.markerName,length(data.data));
		if strcmp(data.markerName(1:3),'SOF')
			if length(data.data)<30
				fprintf(' %d bit, %d(y) x %d(x), %d componenten :',double(data.data(1)),double(data.data(2:3))*[256;1],double(data.data(4:5))*[256;1],double(data.data(6)))
				fprintf(' [%d:%d(H)x%d(V),%d(Q)]',[double(data.data(7:3:end));floor(double(data.data(8:3:end))/16);rem(double(data.data(8:3:end)),16);double(data.data(9:3:end))])
			else
				fprintf(' %d bit, %d(y) x %d(x), %d componenten :....???????........',double(data.data(1)),double(data.data(2:3))*[256;1],double(data.data(4:5))*[256;1],double(data.data(6)))
			end
		elseif strcmp(data.markerName(1:3),'COM')
			fprintf(' %s',char(data.data))
		elseif strcmp(data.markerName(1:3),'SOS')
			n=double(data.data(1));
			fprintf(' %d',n)
			fprintf(' [%d:%d(dc),%d(ac)]',[double(data.data(2:2:1+2*n));floor(double(data.data(3:2:1+2*n))/16);rem(double(data.data(3:2:1+2*n)),16)])
			fprintf(' %d(Ss) %d(Se) %d(Ah) %d(Al)',double(data.data(end-2:end-1)),floor(double(data.data(end))/16),rem(double(data.data(end)),16))
		elseif strcmp(data.markerName,'APP_0')
			d=double(data.data);
			if length(d)<14
				fprintf('??onbekend APP_0-gebruik -');
				fprintf(' %02x',d)
			else
				j=find(d==0);
				if isempty(j)
					fprintf('??onbekend APP_0-gebruik -');
					fprintf(' %02x',d)
				else
					j=j(1);
					APP0=char(d(1:j-1));
					if strcmp(APP0,'JFIF')
						vmaj=d(j+1);
						vmin=d(j+2);
						if vmaj~=1||vmin>2
							fprintf('onbekende JFIF-versie (%d.%d) -',vmaj,vmin);
							fprintf(' %02x',d)
						else
							density=d(j+3);
							Xdens=d(j+4)*256+d(j+5);
							Ydens=d(j+6)*256+d(j+7);
							ThumbX=d(j+8);
							ThumbY=d(j+9);
							fprintf(' JFIF %d.%d, (%d) %dx%d dpi'	...
								,vmaj,vmin,density,Xdens,Ydens)
							if ThumbX||ThumbY
								fprintf(', %dx%d thumbnail'	...
									,ThumbX,ThumbY)
							end
							if length(d)>14
								fprintf(' (%d extra bytes)',length(d)-14)
							end
						end
					end
					
				end
			end
		elseif length(data.data)<20
			fprintf(' %02x',double(data.data));
		end
		fprintf('\n');
	else
		nNotPrintMarkers=nNotPrintMarkers+1;
	end
end
nDatabytes=max(0,lFile-i0);
if nDatabytes
	fprintf('en %d databytes\n',nDatabytes);
end
if nNotPrintMarkers
	fprintf('ook nog %d nietgeprinte markers\n',nNotPrintMarkers)
end
