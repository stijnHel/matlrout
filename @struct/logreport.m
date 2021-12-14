function logreport(S,varargin)
%struct/logreport - logreport for fields of a structure
%   logreport(S)
%
% see also embedded.fi/logreport

fnXXX1952=struct2var(S);
fnXXX1952_=sprintf('%s,',fnXXX1952{:});
name = inputname(1);
if isempty(name)
	name = 'ans';
end
fprintf('logreport of ''%s'':\n',name)
eval(['logreport(' fnXXX1952_(1:end-1) ')']);
