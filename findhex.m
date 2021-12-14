function k=findhex(a,h)

if rem(length(h),2)
	h=['0' h];
end
h=sscanf(h,'%2x');
k=find(a==h(1));
h(1)=[];
i=1;
while ~isempty(h)&~isempty(k)
	if k(length(k))+i>length(a)
		k(length(k))=[];
		if isempty(k)
			break;
		end
	end
	k=k(find(a(k+i)==h(1)));
	i=i+1;
	h(1)=[];
end
