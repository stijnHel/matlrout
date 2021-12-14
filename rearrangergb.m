function C=rearrangergb(C)
% REARRANGERGB - Herschikt RGB-waarden om grote verschillen te hebben tussen kleuren
% (!!!) gemaakt voor "HSV-achtige kleuren-volgorde"
%       de kleuren zelf worden niet bekeken!!!!!!!!
% eenvoudig (niet geoptimaliseerd) geprogrammeerd(!!)

if numel(C)==1
	C=hsv(C);
end
n=size(C,1);
if n<7
	return
end
nd=n/6;
i0=round(1:nd:n);
p=ceil(log(nd)/log(2));
N=2^p;
N1=N/2;
j0=zeros(1,N);
for i=1:N
	k=0;
	k0=N1;
	j=i-1;
	while j
		if rem(j,2)
			k=k+k0;
		end
		k0=k0/2;
		j=floor(j/2);
	end
	j0(i)=k;
end
j0(j0>nd)=[];

I=zeros(1,0);
for i=1:length(j0)
	I=[I i0+j0(i)];
end
for i=2:length(I)
	if any(I(1:i-1)==I(i))
		I(i)=0;
	end
end
I(I==0|I>n)=[];
if length(I)<n
	I=[I setdiff(1:n,I)];
end
C=C(I,:);
