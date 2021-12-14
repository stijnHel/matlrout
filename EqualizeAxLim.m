function D=EqualizeAxLim(fList,eType)
%EqualizeAxLim - equalize limits of axes on different figures
%     EqualizeAxLim(fList)
%   This function is made to make different plots (axes) on different
%   figures comparable by making the limits equal.  Axes on one figure can
%   have different scales, only axes on different figures on the same
%   locations are made equal.
%
%   This function is extended in case fList only contains one figure.  In
%   that case the axes on one figure are put to the same scale.  Then there
%   are different possibilities:
%         EqualizeAxLim(<figure>,{<'X'|'Y'>},<'max' | 'auto'>})

if isscalar(fList)
	ax=filterassen(findobj(fList,'type','axes'));
	if nargin<2||isempty(eType)
		eType={'Y','auto'};
	end
	for i=1:size(eType,1)
		lType=[eType{i} 'Lim'];
		switch lower(eType{i,2})
			case 'max'
				XL=get(ax,lType);
			case 'auto'
				set(ax,[eType{i} 'LimMode'],'auto');
				XL=get(ax,lType);
			otherwise
				error('Unknown type of single figure equalization!')
		end
		set(ax,lType,MaxLim(XL))
	end
	return
end
ax=cell(1,length(fList));
N=0;
Pall=zeros(length(fList),1);
%!!!!niet zoals oorspronkelijk bedoeld!!!
%   posities van assen niet gecontrolleerd!!!
for i=1:length(fList)
	ax{i}=filterassen(findobj(fList(i),'type','axes'));
	P=get(ax{i},'Position');
	if iscell(P)
		P=cat(1,P{:});
	end
	f=ceil(max(P(:,1)+P(:,3)));
	P=P(:,1)*f+P(:,2);
	[P,iS]=sort(P);
	ax{i}=ax{i}(iS);
	if i==1
		P0=P;
		N=length(ax{i});
		Pall(1,N)=0;
		XlMin=Inf(1,N);
		XlMax=-Inf(1,N);
		YlMin=Inf(1,N);
		YlMax=-Inf(1,N);
	elseif N~=length(ax{i})
		error('Not all figures have the same number of axes''s')
	end
	Pall(i,:)=P;
	for j=1:N
		Xl=get(ax{i}(j),'XLim');
		Yl=get(ax{i}(j),'YLim');
		XlMin(j)=min(XlMin(j),Xl(1));
		XlMax(j)=max(XlMax(j),Xl(2));
		YlMin(j)=min(YlMin(j),Yl(1));
		YlMax(j)=max(YlMax(j),Yl(2));
		if any(P~=P0)
			warning('Assen op verschillende plaatsen?')
		end
	end
end
for i=1:length(fList)
	for j=1:N
		set(ax{i}(j),'XLim',[XlMin(j) XlMax(j)]	...
			,'YLim',[YlMin(j) YlMax(j)])
	end
end
if nargout
	D=struct('ax',{ax},'P',Pall);
end

function as=filterassen(as)
notToInclude={'legend','Colorbar','discard'};
for tp=notToInclude
	ll=findobj(as,'Tag',tp{1});
	if ~isempty(ll)
		as=setdiff(as,ll);
	end
end

function xl=MaxLim(XL)
mx=max(cat(1,XL{:}));
mn=min(cat(1,XL{:}));
xl=[mn(1) mx(2)];
