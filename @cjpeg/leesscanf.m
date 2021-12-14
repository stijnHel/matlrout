function a=leesscanf(c,nr,nROWmax)
% CJPEG/LEESSCAN - Leest JPEG-scan
%    a=leesscanf(c,nr)

if ~exist('nr','var')|isempty(nr)
	nr=1;
end
if ~exist('nROWmax','var')|isempty(nROWmax)
	nROWmax=100000;
end
iZigZag=[1 3 4 10 11 21 22 36 2 5 9 12 20 23 35 37 6 8 13 19 24 34 38 49 7 14 18 25 33 39 48 50 15 17 26 32 40 47 51 58 16 27 31 41 46 52 57 59 28 30 42 45 53 56 60 63 29 43 44 54 55 61 62 64];
extend_test=2.^(0:14);
extend_offset=1-2.^(1:15);

markers=strvcat({c.data.markerName});
i=fstrmat(markers(:,1:3),'SOF');
if length(i)>1
	warning('!!!meerdere SOF-markers')
	i=i(1);
elseif isempty(i)
	error('!!geen SOF-marker')
end
switch c.data(i).markerName
case 'SOF_0'
	% OK, "gewoon"
otherwise
	error('!!andere frames dan "gewone" zijn nog niet voorzien');
end
d=double(c.data(i).data);
nbit=d(1);
Y=d(2:3)*[256;1];
X=d(4:5)*[256;1];
ncomp=d(6);
a=cell(1,ncomp);
COMP=[d(7:3:end)' bitshift(d(8:3:end),-4)' bitand(d(8:3:end),15)' d(9:3:end)'];
%[%d:%d(H)x%d(V),%d(Q)]',[);data.data(9:3:end)])
nCOL_MCU=ceil(X/max(COMP(:,2))/8);
nROW_MCU=ceil(Y/max(COMP(:,3))/8);

dri=1e9;

iMarker=1;	% was i+1, maar dan wordt DHT, ... niet gelezen
SOSgevonden=0;
Hdc=[];
Hac=[];
Q=zeros(4,64);
iSOS=0;
fid=0;
while ~SOSgevonden
	switch c.data(iMarker).markerName
	case 'DRI'
		dri=double(c.data(iMarker).data)*[256;1];
		if dri<=0
			dri=1e9;
		end
	case 'DHT'
		H1=maakjpghuftable(double(c.data(iMarker).data));
		for i=1:length(H1)
			if H1(i).type<16
				if H1(i).type>=4
					warning('!!!!!????meer dan 4 dc-huffman-tabellen????')
				end
				if isempty(Hdc)
					Hdc=H1([i i i i]);
				else
					Hdc(H1(i).type+1)=H1(i);
				end
			elseif floor(H1(i).type/16)>1
				error('type huffman table niet ac en niet dc???')
			else	% ac
				j=rem(H1(i).type,16)+1;
				if j>4
					warning('!!!!!????meer dan 4 ac-huffman-tabellen????')
				end
				if isempty(Hac)
					Hac=H1([i i i i]);
				else
					Hac(j)=H1(i);
				end
			end	% ac
		end	% for
	case 'DQT'
		Q1=double(reshape(c.data(iMarker).data,65,length(c.data(iMarker).data)/65)');
		Q(Q1(:,1)+1,:)=Q1(:,2:end);
	case 'SOS'
		iSOS=iSOS+1;
		if iSOS==nr
			SOSgevonden=1;
		end
		d=double(c.data(iMarker).data);
		n=d(1);
		comp=[d(2:2:1+2*n)' bitshift(d(3:2:1+2*n),-4)' bitand(d(3:2:1+2*n),15)'];
		Ss=d(end-2);
		Se=d(end-1);
		Ah=bitshift(d(end),-4);
		Al=bitand(d(end),15);
		
		i1=c.data(iMarker).index+4+length(c.data(iMarker).data);
		i=iMarker+1;
		while strcmp(c.data(i).markerName(1:3),'RST')
			i=i+1;
		end
		if ischar(c.ruw)
			% !niet gestokkeerde data!
			fid=fopen(c.fname);
			if fid<3
				error('!!!Kan file niet openen (data is niet gestokkeerd in object)!!!')
			end
			fseek(fid,i1-1,'bof');
			d=uint8(fread(fid,min(500000,c.data(i).index-i1)));
			if length(d)>=c.data(i).index-i1
				fclose(fid);
				fid=0;
			end
		else
			d=c.ruw(i1:c.data(i).index-1);
			dtot
		end
	end	% switch
	iMarker=iMarker+1;
	if iMarker>length(c.data)
		error('SOS niet gevonden');
	end
end	% while ~SOSgevonden

if nROWmax<nROW_MCU
	warning('!!!Aantal rijen ingekort door opgelegde maximum!!')
	nROW_MCU=nROWmax;
end

for i=1:ncomp
	a{i}=uint8(zeros(nROW_MCU*COMP(i,3)*8,nCOL_MCU*COMP(i,2)*8));
end

xDCT=zeros(1,64);
Ydct=zeros(8);
ii=1;
jj=0;
iRST=0;
lastDCs=zeros(4,1);
nMCU=0;
nBlok=sum(prod(COMP(comp(:,1),2:3),2));
pos=zeros(nBlok,3);
l=0;
for i=1:n
	for j=1:COMP(comp(i,1),3)	% vertikaal
		for k=1:COMP(comp(i,1),2)	% horizontaal
			l=l+1;
			pos(l,1)=(j-1)*8;
			pos(l,2)=(k-1)*8;
			pos(l,3)=i;
		end
	end
end
pos0=pos;
aaaa=find(d==255);
llll=2;
status('Lezen van scan',0);
nbits=zeros(2,n);
i1=[1 8 2 7 3 6 4 5];

ww = 4*exp(1i*(0:7)*pi/16).';
ww(1) = ww(1)/sqrt(2);
W = ww(:,[1 1 1 1 1 1 1 1]);
for iROW=1:nROW_MCU
	pos=pos0;
	%!!!!Hier moet nog iets bijkomen om niet volledig ingelezen file "bij te lezen"!!!!!!
	for iCOL=1:nCOL_MCU
		nMCU=nMCU+1;
		if nMCU>dri
			nMCU=1;
			lastDCs(:)=0;
			if jj
				ii=ii+1;
				jj=0;
			end
			if d(ii)==0&d(ii+1)==255
				warning('????onnodig lege byte???')
				ii=ii+1;
			end
			if d(ii)~=255|d(ii+1)~=208+iRST
				if fid
					fclose(fid);
				end
				error('!geen RST waar verwacht');
			end
			iRST=rem(iRST+1,8);
			ii=ii+2;
		end
		k=0;
		for i=1:n
			for j=1:prod(COMP(comp(i,1),2:3))
				[nb,ii,jj,nb1]=getjpghufcode(d,ii,jj,Hdc(comp(i,2)+1));
				nbits(1,comp(i,1))=nbits(1,comp(i,1))+nb+nb1;	% !!!enkel voor analyse van JPEG
				if nb
					[cc,ii,jj]=getjpgbits(d,ii,jj,nb);
					if cc < extend_test(nb)
						cc=cc+extend_offset(nb);
					end
				else
					cc=0;
				end
				cc=cc+lastDCs(i);
				lastDCs(i)=cc;
				xDCT(1)=cc;
				ff=2;
				xDCT(2:end)=0;
				while ff<=64
					if any(abs(aaaa-ii)<llll)
						ii=ii;	% mogelijkheid voor breakpoint
					end
					[rrss,ii,jj,nb1]=getjpghufcode(d,ii,jj,Hac(comp(i,3)+1));
					nb=rem(rrss,16);
					nbits(2,comp(i,1))=nbits(2,comp(i,1))+nb+nb1;	% !!!enkel voor analyse van JPEG
					rr=floor(rrss/16);
					if rrss==0	% in C-versie wordt ss==0&rr!=15 getest
						break;
					end
%					nb=bitand(rrss,15);
					ff=ff+rr;
					if ff>64
						if fid
							fclose(fid);
						end
						error('!!!er wordt voorbij de DCT-blok geschreven!!!')
					end
					if nb==0
						if rr~=15
							if fid
								fclose(fid);
							end
							error('??onmogelijke waarde voor ac-code??');
						end
						ff=ff+1;	% rr==15 & nb==0 betekent 16 nullen
					else
						[cc,ii,jj]=getjpgbits(d,ii,jj,nb);
						if cc < extend_test(nb)
							cc=cc+extend_offset(nb);
						end
						xDCT(ff)=cc;
						ff=ff+1;
					end
				end
				xDCT=xDCT.*Q(COMP(i,4)+1,:);
				Ydct(:)=xDCT(iZigZag);
				Xdct = ifft(W.*Ydct);
				Xdct = real(Xdct(i1,:));
				
				Xdct = ifft(W.'.*Xdct,[],2);
				Xdct = real(Xdct(:,i1));
				Xdct=round(min(255,max(0,Xdct+128)));
				k=k+1;
				a{comp(i,1)}(pos(k,1)+(1:8),pos(k,2)+(1:8))=uint8(Xdct);
				% X bewaren
			end	% nDCT's for this component
		end	% nDCT's per MCU
		pos(:,2)=pos(:,2)+COMP(pos(:,3),2)*8;
	end	% iCOL
	pos0(:,1)=pos0(:,1)+COMP(pos0(:,3),3)*8;
	status(iROW/nROW_MCU);
end	% iROW
if fid
	fclose(fid);
end
fprintf('aantal bits per component (en per dc/ac) :\n');disp(nbits)
status
