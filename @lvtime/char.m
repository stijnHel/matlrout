function s=char(c)
%lvtime/char - makes a string from lvtime data

t=datenum(c,true,true);
s=datestr(t);
