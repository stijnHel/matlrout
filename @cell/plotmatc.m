function plotmat(C)
%cell/plotmat - very simple function for cell-based plotmat
%    plotmat(C)
%       plots graphs given by C: first column X, other colmns Y
%           if C is cell-vector, place of plots is done automatically
%           otherwise shape of C is used
%       if data in C is vector, standard (plot-)x-data is used

nPlots=numel(C);
if min(size(C))==1
	if nPlots<4
		nRow=nPlots;
		nCol=1;
	else
		nRow=ceil(nPlots/2);
		nCol=2;
	end
else
	nRow=size(C,1);
	nCol=size(C,2);
	C=C';	% since numbering of C and subplots is different
end

nfigure
for i=1:nPlots
	if ~isempty(C{i})
		subplot(nRow,nCol,i)
		if min(size(C{i}))==1
			plot(C{i});grid
		else
			plot(C{i}(:,1),C{i}(:,2:end));grid
		end
	end
end
