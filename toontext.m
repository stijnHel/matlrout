function toontext(x)
% TOONTEXT - Toont tekststukken
x=floor(x(:));
if min(x)<0
	error('x moet minimaal 0 zijn');
end
if max(x)>255
	error('x moet maximaal 255 zijn');
end
cok=ones(256,1);
nok=[0:9 11 12 14:31 127:144 147:159];
cok(nok+1)=zeros(length(nok),1);
i=find(x==0);
if i(1)>1
	i=[0;i];
end
if i(length(i))<length(x)
	i(length(i)+1)=length(x)+1;
end

for j=1:length(i)-1
	if all(cok(x(i(j)+1:i(j+1)-1)+1))
		fprintf('%s\n',x(i(j)+1:i(j+1)-1));
	end
end