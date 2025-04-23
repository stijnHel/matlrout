function m = minutes(t)
%lvtime/days - converts a lvtime (or array) to minutes
%   m = minutes(t)
%
% see also lvtime/datenum / lvtime/hours

m = datenum(t)*1440;
