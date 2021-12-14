function [mn,iMn]=minmin(X)
%minmin   - Minimum element of an array
%    [mn,iMn]=minmin(X)
%  This is the same as [mn,iMn]=mub(X(:)), and is mainly made to be used if
%  X is a formula.

[mn,iMn]=min(X(:));
