function t=tijd
%TIJD geeft de tijd in een string.

x=clock;
t=sprintf('%2d:%2d:%2d\n',x(4),x(5),fix(x(6)));