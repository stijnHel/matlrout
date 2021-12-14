function u=canpr(x1,x2,x3)
% CANPR    - CAN-protocol-berekeningen
%    u=canpr(x1)    : 82526-berekeningen (canpr('82526',x1) werkt ook)
%         x1 = '....' (hex letters)
%                  gebruikt .... als BTR0/1-hex-waarden
%                        berekent baud-rate rekenend op 16 MHz
%         x1 = getal : geeft BTR0/1-hex-waarden
%            vector : [baud,SJW,sampleratio,sample];
%    u=canpr(x1,kristalF) : gebruikt andere kristal-frequentie
%    u=canpr('82c200',x1) : zelfde berekeningen maar voor 82c200

kFreq=16e6;
canType='82526';
if nargin>1
	if isstr(x1)&length(x1)~=4
		canType=lower(x1);
		x1=x2;
		if nargin>2
			kFreq=x3;
		end
	else
		kFreq=x2;
	end
end
if ~strcmp(canType,'82526')&~strcmp(canType,'82c200')
	error('Verkeerd canType')
end
if isstr(x1)&length(x1)==4
	BTR=sscanf(x1,'%02x');
	SJW=floor(BTR(1)/64)+1;
	BRP=rem(BTR(1),64)+1;
	sample=BTR(2)>127;
	TSEG1=rem(BTR(2),16)+1;
	TSEG2=floor(BTR(2)/16)-sample*8+1;
	if strcmp(canType,'82526')
		NBT=1+TSEG1+TSEG2+2*SJW;
	else
		NBT=1+TSEG1+TSEG2;
	end
	baud=kFreq/2/BRP/NBT;
	if nargout
		u=baud;
	else
		fprintf('BaudRate = %5.0f\n',baud)
		fprintf('    SJW = %d, SAM = %d, TSEG = %d-%d\n',SJW,sample,TSEG1,TSEG2)
	end
elseif ~isstr(x1)
	% defaults
	sample=1;
	SJW=4;
	sampleRatio=1/2;
	BRP=0;
	%BRP=kFreq/66/x1-1; (minimum)
	TSEG1=100;
	TSEG2=100;
	baud=x1(1);
	if length(x1)>1
		if x1(2)>0
			SJW=x1(2);
		end
		if length(x1)>2
			if x1(3)>0
				sampleRatio=x1(3);
			end
			if length(x1)>3
				if x1(4)>=0
					sample=x1(4)~=0;
				end
			end
		end
	end
	while (TSEG1>16)|(TSEG2>8)
		BRP=BRP+1;
		NBT=round(kFreq/2/BRP/baud);
		if strcmp(canType,'82526')
			x=NBT-1-2*SJW;
		else
			x=NBT-1;
		end
		TSEG1=ceil(x*sampleRatio);
		TSEG2=x-TSEG1;
	end
	
	BTR0=BRP-1+(SJW-1)*64;
	BTR1=TSEG1-1+(TSEG2-1)*16+sample*128;
	BTR=[BTR0 BTR1];
	
	if nargout
		u=sprintf('%02x%02x',BTR);
	else
		fprintf('BTR0 = 0x%02x, BTR1 = 0x%02x\n',BTR);
		fprintf('    BRP = %d, SJW = %d, SAM = %d, TSEG = %d-%d\n'	...
			,BRP,SJW,sample,TSEG1,TSEG2)
	end
else
	error('Verkeerd gebruik van CANPR')
end