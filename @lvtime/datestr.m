function s=datestr(c,varargin)
%lvtime/datestr - makes a string from lvtime data
%      s=datestr(c,...)
%
%  uses (matlab-)datestr-function with DST
%       extra inputs are "forwarded" to datestr-function
%
%   see also lvtime/char, lvtime/datenum, lvtime/double

t=datenum(c,true,true);
s=datestr(t,varargin{:});
