function d = hours(t)
%lvtime/days - converts a lvtime (or array) to hours
%   h = hours(t)
%
% see also lvtime/datenum / lvtime/hours

d = datenum(t)*24;
