%touint8  - Gives the raw data of numeric data
%    Xraw=touint8(X);
%  returns a matrix with one dimension more than the original data
%    the first dimension gives the bytes of each separate element
%       X = m x n x p x ... matrix, z bytes/element
%     result :
%       Xraw = z x m x n x p x .... matrix
%    except for 1D-data (column or row) :
%       X = 1 x n  ---->   Xraw = z x n
%       X = n x 1  ---->   Xraw = z x n
%
%   mex-function (Stijn Helsen)