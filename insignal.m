function insignal
% INSIGNAL - Zoekt opgeroepen functies die (waarschijnlijk) in signal toolbox zitten
x=inmem;
for i=1:length(x)
   if ~isempty(findstr(which(x{i}),'toolbox\signal'))
      fprintf('%10s : %s\n',x{i},which(x{i}))
   end
end
