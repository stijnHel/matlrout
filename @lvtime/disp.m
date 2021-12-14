function disp(c)
%lvtime/disp - displays lvtime data

t=c.t*[2^32;1;2^-32;2^-64]/3600/24+datenum(1904,1,1);
disp(datestr(t))
