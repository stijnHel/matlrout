function y=interpm(A,x)
% INTERPM  - Interpoleert in array
%    y=interpm(A,x)
%        : y=interp1(A(:,1),A(:,2),x);

y=interp1(A(:,1),A(:,2),x);
