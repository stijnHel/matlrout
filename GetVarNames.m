function [varNames,bOK]=GetVarNames(varargin)
%GetVarNames - Get all variable names of input arguments
%      varNames=GetVarNames(var1,var2,...)
%           function that can be used to:
%               make variables be used (for MLint message)
%               use (correct) names for setoptions
%
% see also setoptions

varNames=cell(1,nargin);
bOK=true;
for i=1:nargin
	varNames{i}=inputname(i);
	bOK=bOK&&~isempty(varNames{i});
end
if nargout<2&&~bOK
	warning('Not all variable names could be extracted!')
end
