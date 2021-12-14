function i=fstrmat2(A,x,deel)
% FSTRMAT - find string in matrix
%      i=fstrmat(A,x,deel)
%          deel = 0, leeg of niet gegeven : volledige naam
%                 1 : voorkomend in de naam
%                 2 : begin zelfde
%  Deze routine is gedeeltelijk te vervangen door de nieuwere
%  matlab-routine strmatch.
if length(x)>size(A,2)
	i=[];
	return
end
if ~exist('deel');deel=[];end
if isempty(deel)
	deel=0;
end
if deel==1
	i=findstr(char(x), char(reshape(A', 1, prod(size(A)))))-1;
	if isempty(i)
		return;
	end
	i=floor(i/size(A,2)+1);
	di=find(diff(i)==0);
	if ~isempty(di)
		i(di+1)=[];
	end
elseif deel==2
	i=fstrmat(A(:,1:length(x)),x);
elseif deel
	error('Verkeerd gebruik van fstrmat (deel=0, 1 of 2)')
else
	i=1:size(A,1);
	for j=1:length(x)
		i(find(A(i,j)~=x(j)))=[];
		if isempty(i)
			break
		end
	end
	if (length(x)<size(A,2))&~isempty(i)
		l=length(x)+1;
		i(find(A(i,l)&(A(i,l)~=' ')))=[];
	end
end
