function matrix2vars(A,varnames)
%MATRIX2VARS - extracts columns of a matrix to variables
%
%Description
% Columns in a matrix are extracted and make them available in separate
%   variables in the functions caller workspace.
%    matrix2vars(A,varnames)
%
%Parameters [IN]:
%       A : matrix
%       varnames : stringarray or cell-array with names
%   !no checks are done regarding valid names, different names, ....!
%       spaces in names are replaced by underscore

%Authors: Stijn Helsen
%Created: 2006-05-23
%Matlab version: MATLAB Version 7.0.0.19901 (R14)
%
% Copyright (c) 2006 FMTC Flanders Mechatronics Technology Centre, Belgium

bCellArray=true;	% selection boolean for cellarray or stringarray
if ischar(varnames)	% character array with names
	if size(varnames,1)~=size(A,2)
		error('Wrong combination of names and number of columns')
	end
	bCellArray=false;
elseif iscell(varnames)
	if length(varnames)~=size(A,2)
		error('Wrong combination of names and number of columns')
	end
else
	error('Wrong input-type of varnames')
end
for i=1:size(A,2)
	if bCellArray
		varname1=varnames{i};
	else
		varname1=deblank(varnames(i,:));
	end
	if isempty(varname1)
		error('empty variable name?!')
	end
	varname1(varname1==' ')='_';
	assignin('caller',varname1,A(:,i))
end
