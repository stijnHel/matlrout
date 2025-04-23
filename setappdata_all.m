function setappdata_all(H,varargin)
%setappdata_all - setappdata allowing multiple handles and settings
%         setappdata(<handles>,'par1',data1,'par2',data2...)

for i=1:numel(H)
	for j=1:2:length(varargin)
		setappdata(H(i),varargin{j},varargin{j+1})
	end
end
