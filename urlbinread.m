function [output,status] = urlbinread(urlChar,method,params)
%urlbinread - Returns the contents of a URL as a string.
%   S = urlbinread('URL') reads the content at a URL into a string, S.  If the
%   server returns binary data, the string will contain garbage.
%
%   S = urlbinread('URL','method',PARAMS) passes information to the server as
%   part of the request.  The 'method' can be 'get', or 'post' and PARAMS is a 
%   cell array of param/value pairs.
%
%   [S,STATUS] = urlbinread(...) catches any errors and returns 1 if the file
%   downloaded successfully and 0 otherwise.
%
%   Examples:
%   s = urlbinread('http://www.mathworks.com')
%   s = urlbinread('ftp://ftp.mathworks.com/README')
%   s = urlbinread(['file:///' fullfile(prefdir,'history.m')])
% 
%   From behind a firewall, use the Preferences to set your proxy server.
%
%   See also URLREAD, URLWRITE.
if ~usejava('jvm')
   error('MATLAB:urlread:NoJvm','URLREAD requires Java.');
end

import com.mathworks.mlwidgets.io.InterruptibleStreamCopier;

% Be sure the proxy settings are set.
com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings

% Check number of inputs and outputs.
error(nargchk(1,3,nargin))
error(nargoutchk(0,2,nargout))
if (nargin > 1) && ~strcmpi(method,'get') && ~strcmpi(method,'post')
    error('MATLAB:urlread:InvalidInput','Second argument must be either "get" or "post".');
end

% Do we want to throw errors or catch them?
if nargout == 2
    catchErrors = true;
else
    catchErrors = false;
end

% Set default outputs.
output = '';
status = 0;

% GET method.  Tack param/value to end of URL.
if (nargin > 1) && strcmpi(method,'get')
    if mod(length(params),2) == 1
        error('MATLAB:urlread:InvalidInput','Invalid parameter/value pair arguments.');
    end
    for i=1:2:length(params)
        if (i == 1), separator = '?'; else, separator = '&'; end
        param = char(java.net.URLEncoder.encode(params{i}));
        value = char(java.net.URLEncoder.encode(params{i+1}));
        urlChar = [urlChar separator param '=' value];
    end
end

% Create a urlConnection.
[urlConnection,errorid,errormsg] = urlbreadwrite(mfilename,urlChar);
if isempty(urlConnection)
    if catchErrors, return
    else error(errorid,errormsg);
    end
end

% POST method.  Write param/values to server.
if (nargin > 1) && strcmpi(method,'post')
    try
        urlConnection.setDoOutput(true);
        urlConnection.setRequestProperty( ...
            'Content-Type','application/x-www-form-urlencoded');
        printStream = java.io.PrintStream(urlConnection.getOutputStream);
        for i=1:2:length(params)
            if (i > 1), printStream.print('&'); end
            param = char(java.net.URLEncoder.encode(params{i}));
            value = char(java.net.URLEncoder.encode(params{i+1}));
            printStream.print([param '=' value]);
        end
        printStream.close;
    catch
        if catchErrors, return
        else error('MATLAB:urlread:ConnectionFailed','Could not POST to URL.');
        end
    end
end

% Read the data from the connection.
try
    inputStream = urlConnection.getInputStream;
    byteArrayOutputStream = java.io.ByteArrayOutputStream;
    % This StreamCopier is unsupported and may change at any time.
    isc = InterruptibleStreamCopier.getInterruptibleStreamCopier;
    isc.copyStream(inputStream,byteArrayOutputStream);
    inputStream.close;
    byteArrayOutputStream.close;
    output = typecast(byteArrayOutputStream.toByteArray,'uint8');
catch err
    if catchErrors, return
	else
		DispErr(err)
		error('MATLAB:urlread:ConnectionFailed','Error downloading URL.');
    end
end

status = 1;
