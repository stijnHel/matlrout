function [mx,iMx]=maxmax(X)
%maxmax   - Maximum element of an array
%    [mx,iMx]=maxmax(X)
%  This is the same as [mx,iMx]=max(X(:)), and is mainly made to be used if
%  X is a formula.

[mx,iMx]=max(X(:));
