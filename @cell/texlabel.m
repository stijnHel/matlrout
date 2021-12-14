function L=texlabel(L)
%cell/texlabel - texlabel version for cell arrays (TeX from character strings)
%   L=texlabel(L)
%         with L an array
%   function texlabel for all elements of L is called
%     in this way, the function can work recursive

for i=1:numel(L)
	L{i}=texlabel(L{i});
end
