function Xfull=idx2fullcolor(X,map)
%idx2fullcolor - Convert indexed to full color image
%      Xfull=idx2fullcolor(X,map)

if ~ismatrix(X)
	sz=size(X);
	nIMGs=prod(sz(3:end));
	sz=[sz(1:2) 3 sz(3:end)];
	Xfull=zeros(sz);
	varMap=~(isnumeric(map)&&ismatrix(map));
	if ~varMap
		mapi=map;
	end
	for i=1:nIMGs
		if varMap
			if iscell(map)
				mapi=map{i};
			else
				mapi=map(:,:,i);
			end
		end
		Xfull(:,:,:,i)=idx2fullcolor(X(:,:,i),mapi);
	end
	return
end

Xfull=zeros(numel(X),3);
for i=0:size(map,1)-1
	B=X==i;
	Xfull(B,:)=map(i+ones(sum(B(:)),1),:);
end
if any(X(:)<0|X(:)>=size(map,1))
	warning('Not all pixels are filled!')
end

Xfull=reshape(Xfull,size(X,1),size(X,2),3);
