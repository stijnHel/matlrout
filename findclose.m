function [i,del,v]=findclose(x,x1)
% FINDCLOSE - Zoekt dichtst bijliggende punt (1D)
%      [i,del,v]=findclose(x,x1)
%         default for x1: 0

if nargin<2||isempty(x1)
	x1=0;
end

if (isscalar(x)&&isinf(x))||(isscalar(x1)&&isinf(x1))
	if ~isscalar(x)
		x2=x;
		x=x1;
		x1=x2;
	end
	i=find(isinf(x1)&sign(x)==sign(x1));
	if isempty(i)
		if x>0
			[mx,i]=max(x1);
		else
			[mx,i]=min(x1);
		end
		del=x-mx;
	else
		del=0;
	end
else
	[del,i]=min(abs(x-x1));
	if nargout>2
		if isscalar(x)
			v=x1(i);
		else
			v=x(i);
		end
	end
end
