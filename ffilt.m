function [fil,t]=ffilt(x,minx,maxx,dx)
% FFILT filtert een piekerig signaal door :
%     - extremen weg te halen
%     - enkele pieken weg te halen
l=length(x);
s=size(x);
% Haal de extremen uit de meting
t1=x>minx;
t2=x<maxx;
t=t1.*t2;
fil=t.*x+(1-t1).*(minx*ones(s))+(1-t2).*(maxx*ones(s));

% haal de pieken uit de meting
t1=diff(fil);
t1=sign(t1).*(min([abs(t1) dx*ones(l-1,1)]')');
t=[1;(-t1(1:l-2).*t1(2:l-1))<dx*dx*0.99;1];

fil=t.*fil+(1-t).*[fil(1);(fil(1:l-2)+fil(3:l))/2;fil(l)];
