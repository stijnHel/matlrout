function [T,bST]=getutctime(T)
%getutctime - Geeft UTC vanuit lokale (belgische tijd)
%

if ~exist('T','var')||isempty(T)
	T=clock;
	T=T([3 2 1 4:end]);
end

T(4)=T(4)-1;
bST=false;
if T(2)>3&&T(2)<10	% super simpele zomertijd-bepaling
	T(4)=T(4)-1;
	bST=true;
elseif T(2)==3&&T(1)>24
	[dd,~,~,~,~,~,wd]=calccaldate(calcjd(T(1:3)));
	if wd==0
		if T(4)>=2
			T(4)=T(4)-1;
			bST=true;
		end
	elseif wd+31-dd<7
		T(4)=T(4)-1;
		bST=true;
	end
elseif T(2)==10
	if T(1)<25
		T(4)=T(4)-1;
		bST=true;
	else
		[dd,~,~,~,~,~,wd]=calccaldate(calcjd(T(1:3)));
		if wd==0
			if T(4)<2
				T(4)=T(4)-1;
				bST=true;
			end
		elseif wd+31-dd>=7
			T(4)=T(4)-1;
			bST=true;
		end
	end
end
