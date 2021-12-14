function [C,common]=SplitCommonString(C)
%SplitCommonNames - split common start of strings
%      [C,common]=SplitCommonString(C)

if length(C)<=1
	common='';
else
	common=C{1};
	i=1;
	while ~isempty(common)&&i<length(C)
		i=i+1;
		if isempty(C{i})
			common='';
			break
		end
		n=min(length(C{i}),length(common));
		j=find(C{i}(1:n)~=common(1:n),1);
		if ~isempty(j)
			common=common(1:j-1);
		end
	end
	if ~isempty(common)
		n=length(common)+1;
		for i=1:length(C)
			C{i}=C{i}(n:end);
		end
	end
end
