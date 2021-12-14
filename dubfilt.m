function y=dubfilt(B,A,x)
% DUBFILT - dubbele filter - vervanging van filtfilt
%     y=dfilt(B,A,x)

y=filter(B,A,x);
y=filter(B,A,y(end:-1:1));
y=y(end:-1:1);
