function [L,DA,ri]=lagrptn(alpha)
%lagrptn

if ~exist('alpha','var')|isempty(alpha)
	alpha=1/81;
end

d=1;
d1=alpha/(1+alpha);
d2=1-d1;

ri=-2:0.001:2;

da1=1./(d1+ri).^2-alpha./(d2-ri).^2-ri/d1/(d1+d2)^2;
L1=FindZeros(da1,ri);

da2=1./(d1+ri).^2+alpha./(d2-ri).^2-ri/d1/(d1+d2)^2;
L2=FindZeros(da2,ri);

da3=1./(ri-d1).^2+alpha./(ri+d2).^2-ri/d1/(d1+d2)^2;
L3=FindZeros(da3,ri);

DA=[da1;da2;da3];
L={L1,L2,L3};

function [L,Li,Ld]=FindZeros(da,ri)
ii=find(da(1:end-1)<0&da(2:end)>=0);
limA=1e5;
if isempty(ii)
	Li=[];
else
	ii(abs(da(ii))>limA|abs(da(ii+1))>limA)=[];
	Li=ii;
	for i=1:length(ii)
		k=ii(i)-3:ii(i)+3;
		Li(i)=interp1(da(k),ri(k),0,'spline');
	end
end
id=find(da(1:end-1)>0&da(2:end)<=0);
if isempty(id)
	Ld=[];
else
	id(abs(da(id))>limA|abs(da(id+1))>limA)=[];
	Ld=id;
	for i=1:length(id)
		k=id(i)-3:id(i)+3;
		Ld(i)=interp1(da(k),ri(k),0,'spline');
	end
end
L=[Li Ld];
