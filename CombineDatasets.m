function Y=CombineDatasets(varargin)
%CombineDatasets - Combine numerical data sets
%    Y=CombineDatasets(X1,X2,X3,...);
%    Y=CombineDatasets({X1,X2,X3,...});
%      first column of X_i is taken as X-data
%         these are combined

if iscell(varargin{1})
	if nargin>1
		error('if cell input is used, only one input is allowed')
	end
	Xsets=varargin{1};
else
	Xsets=varargin;
end
tp=unique(cellfun(@class,Xsets,'UniformOutput',false));
if length(tp)~=1||~strcmp(tp{1},'double')
	error('Bad input')
end

Xtotal=[];
Nch=cellfun('size',Xsets,2)-1;
nChan=sum(Nch);
for i=1:length(Xsets)
	Xtotal=union(Xtotal,Xsets{i}(:,1));
end

Y=nan(length(Xtotal),nChan);
Y(:,1)=Xtotal;
kCh=1;
for i=1:length(Xsets)
	[~,ii]=intersect(Xtotal,Xsets{i}(:,1));
	Y(ii,kCh+1:kCh+Nch(i))=Xsets{i}(:,2:end);
	kCh=kCh+Nch(i);
end
