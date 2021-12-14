function [a,i,j]=getbits(x,i,j,n,bLSb)% GETBITS - Neemt bits uit lijst%      [a,i,j]=getbits(x,i,j,n[,false])%            takes bits starting from x(i), bit 0 is MSb%      [a,i,j]=getbits(x,i,j,n,true)%            takes bits starting from x(i), bit 0 is LSbif nargin==4||~bLSb	if 8-j>=n		a=double(bitand(2^n-1,bitshift(x(i),j+n-8)));		j=j+n;		if j>7			j=0;			i=i+1;		end	else		a=double(bitand(2^(8-j)-1,x(i)));		n=n-8+j;		i=i+1;		while n>8			a=bitshift(a,8)+double(x(i));			n=n-8;			i=i+1;		end		j=n;		if n			a=bitshift(a,n)+double(bitshift(x(i),n-8));			if j>7				j=0;				i=i+1;			end		end	endelse	% LSb	if 8-j>=n		a=double(bitand(bitshift(x(i),-j),2^n-1));		j=j+n;		if j>7			j=0;			i=i+1;		end	else		a=double(bitshift(x(i),-j));		f=bitshift(1,8-j);		n=n-8+j;		i=i+1;		while n>8			a=a+double(x(i))*f;			f=f*256;			n=n-8;			i=i+1;		end		j=n;		if n			a=a+double(bitand(x(i),2^n-1))*f;			if j>7				j=0;				i=i+1;			end		end	endend