function [Z,I]=sortstr(X,bCaseInsensitive)
% SORTSTR - Sorteert string-matrix

if nargin<2||isempty(bCaseInsensitive)
	bCaseInsensitive=false;
end

v=version;
if v(1)>='5'
	if bCaseInsensitive
		Xu=upper(X);
	else
		Xu=X;
	end
	if ischar(X)
		[Z,I]=sortrows(Xu);
		if bCaseInsensitive
			Z=X(I,:);
		end
	else
		[Z,I]=sort(Xu);
		if bCaseInsensitive
			Z=X(I);
		end
	end
	return
end
% sorteer door insertie
j=1;
for i=2:size(X,1)
	k=binzoek(X(j(1:i-1),:),deblank(X(i,:)));
	if k==floor(k)
		k=k+1;
		n1=deblank(X(i,:));
		while strcmp(deblank(X(k,:)),n1)&(k<i)
			k=k+1;
		end
	else
		k=ceil(k);
	end
	j=[j(1:k-1) i j(k:i-1)];
end
Z=X(j,:);
if nargout>1
	I=j;
end
