function c = CreateGeography(varargin)
%CreateGeography - function to create a (common) cGeography object
%   The object is created only once (when called multiple times).
%
%   c = CreateGeography([options...])
%         options are "forwarded" to cGeography
%
% see also cGeography

persistent GEOG

if isempty(GEOG)
	GEOG = cGeography(varargin{:});
elseif nargin
	GEOG.Update(varargin{:})
end

c = GEOG;
