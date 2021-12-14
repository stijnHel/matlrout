function p=unwrapgen(p,per,nSample)
%unwrapgen - General (fast) unrwapper (first column)
%     p=unwrapgen(p,period[,nSample])
%          nSample: for dampened steps
%          nSample(2) --> post processing filtering out short "jumps"

if nargin==1||isempty(per)
	per=1;
end
if nargin<3
	nSample=0;
end

if min(size(p))>1
	for i=1:size(p,2)
		p(:,i)=unwrapgen(p(:,i),per,nSample);
	end
	return
end

step=per/2;

if nargin>2&&~isempty(nSample)&&nSample(1)>0
	nS=nSample(1);
	b=abs(p(1+nS:end)-p(1:end-nS))>step;
	i=1;
	N=length(b);
	while i<N
		if b(i)
			if all(abs(diff(p(i:i+nS+1)))<=step)
				j=i+nS;
				k=j+1;
				if p(i+nS+1)>p(i)
					while p(j-1)<p(j)
						j=j-1;
					end
					while p(k+1)>p(k)
						k=k+1;
					end
				else
					while p(j-1)>p(j)
						j=j-1;
					end
					while p(k+1)<p(k)
						k=k+1;
					end
				end
				p(j+1:i+nS)=p(j);
				p(i+nS+1:k-1)=p(k);
				i=k;
			else
			end
		end
		i=i+1;
	end
end

dp=diff(p);
dpCor=per.*(abs(dp)>step).*sign(dp);
p(2:end)=p(2:end)-cumsum(dpCor);
if length(nSample)>1
	%!!!!!NOT READY!!!!!
	nS=nSample(2);
	B=abs(p(1+nS:end)-p(1:end-nS))>step;
	dpCor=zeros(length(B),1);
	N=length(B);
	i=1;
	b=false;
	while i<N
		if B(i)
			dpCor(i+1)=sign(p(i+nS)-p(i))*per;
			i=i+nS;
			b=true;
		end
		i=i+1;
	end
	if b
		p(nS+1:end)=p(nS+1:end)-cumsum(dpCor);
	end
end
