function [W8,W16]=FindTextInData(x,varargin)
%FindTextInData - Find possible parts of text in a file
%     [W8,W16]=FindTextInData(x)

nWordMin=8;
n16WordMin=[];

if ~isempty(varargin)
	setoptions({'nWordMin','n16WordMin'},varargin{:})
end
if isempty(n16WordMin)
	n16WordMin=nWordMin;
end

bT1=false(1,255);
bT1(abs('A'):abs('Z'))=true;
bT1(abs('a'):abs('z'))=true;
bT1(abs('0'):abs('9'))=true;
bT1(abs(',.;"'' |@&$%!^*()-_=+[]{}\:/<>~'))=true;
bT1([9 10 13])=true;
bT=[false bT1];

B8=bT(double(x)+1);
N8=zeros(1,length(B8));
N8(1)=B8(1);
% allow zeros between words?
% more complex conditions:
%     only ',','.',... on certain locations
%     not only spaces, ....
%     ...
for i=2:length(B8)
	if B8(i)
		N8(i)=N8(i-1)+1;
	elseif B8(i-1)&&N8(i-1)<nWordMin
		j=i-1;
		while j&&N8(j)
			N8(j)=0;
			j=j-1;
		end
	end
end
if N8(end)
	N8(end+1)=0;
end
ii=[find(N8==1)' find(N8(1:end-1)>0&N8(2:end)==0)'];
W=cell(1,size(ii,1));
for i=1:size(ii,1)
	W{i}=char(x(ii(i,1):ii(i,2)));
end
W8=struct('ii',ii,'W',{W});

if nargout>1
	%!only for little endian systems?!
	B16=bT(abs(x(1:end-1))+1)&x(2:end)==0;
	N16=zeros(1,length(B16));
	N16(1:2)=B16(1:2);
	if B16(2)
		i=4;
	else
		i=3;
	end
	while i<=length(B16)
		if B16(i)
			N16(i)=N16(i-2)+1;
			i=i+2;
		elseif B16(i-2)&&N16(i-2)<n16WordMin
			j=i-2;
			while j&&N16(j)
				N16(j)=0;
				j=j-2;
			end
			i=i+1;
		else
			i=i+1;
		end
	end
	if N16(end)||N16(end-1)
		%(!!!)if N16(end) ---> bigendian?!!!!
		i=length(N16);
		if N16(i)==0
			i=i-1;
		elseif N16(i)>=n16WordMin
			x(end+1)=0;	%!!!!!!!!
		end
		
		ii=[find(N16(1:i-N16(i)*2)==1)' find(N16(1:end-2)>0&N16(3:end)==0)'];
		if N16(i)>=n16WordMin
			ii(end+1,:)=[i-N16(i)*2+2 i];
		end
	else
		ii=[find(N16==1)' find(N16(1:end-2)>0&N16(3:end)==0)'];
	end
	W=cell(1,length(ii));
	for i=1:size(ii,1)
		W{i}=char(typecast(uint8(x(ii(i,1):ii(i,2)+1)),'uint16'));
	end
	W16=struct('ii',ii,'W',{W});
end
