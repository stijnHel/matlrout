function [varargout] = ReadGPS(f,varargin)
%ReadGPS - GPS-log-file reader for different formats
%    Possible formats:
%         GPX
%         FIT (Garmin format)
%
%      [...] = ReadGPS(fname,...)
%
% uses ReadGPX, ReadFIT

fFull = fFullPath(f);
[~,~,fExt] = fileparts(fFull);
varargout = cell(1,nargout);
if strcmpi(fExt,'.fit')
	[varargout{:}] = ReadFIT(fFull,varargin{:});
elseif strcmpi(fExt,'.gpx')
	[varargout{:}] = ReadGPX(fFull,varargin{:});
else
	error('Unknown format')
end
