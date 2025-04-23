function CreateEnumDefinition(enumName,C)
%CreateEnumDefinition - Create enumeration definition
%   CreateEnumDefinition(enumName,C)
%         C: cell-vector ==> enum for values 0,1,2,..
%         C: cell-matrix with 2 columns:
%               {'enumString1',enumVal1;
%                'enumString2',enumVal2;
%                ....}
%
%  Creates a new file in edit (without saving)

if isvector(C)
	C = [C(:),num2cell(0:length(C)-1)'];
end
minV = min([C{:,2}]);
maxV = max([C{:,2}]);
if minV<0
	if maxV<128
		typ = 'int8';
		lNum = 4;
	elseif maxV<32768
		typ = 'int16';
		lNum = 6;
	else
		typ = 'int32';
		lNum = 9;
	end
else
	if maxV<256
		typ = 'uint8';
		lNum = 3;
	elseif maxV<65636
		typ = 'uint16';
		lNum = 5;
	else
		typ = 'uint32';
		lNum = 9;
	end
end
nVal = size(C,1);
S = cell(1,nVal+7);
S{1} = sprintf('classdef %s < %s',enumName,typ);
S{2} = sprintf('%%%s - enumeration definition',enumName);
S{3} = '';
S{4} = sprintf('\tenumeration');
iS = 4;
lNames = cellfun('length',C(:,1));
lMax = max(lNames);
if lMax<20
	lMax = 20;
end
sFormat = sprintf('\t\t%%-%ds  (%%%dd)',lMax,lNum);
for i=1:nVal
	iS = iS+1;
	S{iS} = sprintf(sFormat,C{i,1:2});
end
iS = iS+1;
S{iS} = sprintf('\tend  %% end enumeration');
iS = iS+1;
S{iS} = sprintf('end   %% end classdef %s',enumName);
s = sprintf('%s\n',S{1:iS});
edit % new file
activeFile = matlab.desktop.editor.getActive;
activeFile.Text = s;
