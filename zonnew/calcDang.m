%calcDang - script voor bepaling van schijnbare afstanden

if ~exist('t','var')
	t=calcjd(1,1,2009):calcjd(1,1,2012);
end
if ~exist('el','var')
	el={'aarde','mercurius','venus','mars','jupiter','saturnus','uranus','neptunus'};
end
elD=el;
for i=1:length(el)
	elD{i}=calcvsop87(el{i},'zoek');
end
P=zeros(3,length(el),length(t));
for i=1:length(t)
	for j=1:length(el)
		P(:,j,i)=calcvsop87(elD{j},calcjc(t(i))/10);
	end
end
X=P([3 3 3],:,:).*[cos(P(1,:,:)).*cos(P(2,:,:));sin(P(1,:,:)).*cos(P(2,:,:));sin(P(2,:,:))];
dX=X;
dX(:,1,:)=0;
dX=squeeze(dX-X(:,ones(1,length(el)),:));
D=zeros(length(el),length(el),length(t));
for i=1:length(el)-1
	for j=i+1:length(el)
		D(i,j,:)=acosd(sum(dX(:,i,:).*dX(:,j,:))./sqrt(sum(dX(:,i,:).^2).*sum(dX(:,j,:).^2)));
		D(j,i,:)=D(i,j,:);
	end
end
