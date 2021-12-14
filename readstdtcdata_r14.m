function tc = readstdtcdata_r14(filename)
%READSTDTCDATA_R14 read NIST STD DB 60 ITS-90 thermocouple data file
%
% TC = READSTDTCDATA_R14('all.tab');
%
% Reads all the table data and polynomial coefficient data 
% from the official NIST ITS-90 thermocouple database file.  Uses MATLAB 7
% language constructs. NIST thermocouple database files can be 
% downloaded from:
%
%  http://srdata.nist.gov/its90/download/download.html
%
% To get all the data, you only need to obtain and read this file:
%
%  all.tab
%
% Individual data is also available at the above URL.  If the URL
% no longer works, please contact support@mathworks.com for updated
% information.  (URL current as of 25 Mar 2006).  The data file can 
% also be downloaded from MATLAB Central's download area from this
% location:
%
%  MATLAB Central >  File Exchange > Test and Measurement > Hardware
%  Support and Drivers > Simulating and Conditioning Thermocouple Signals
%
% If you don't already have all.tab, try this command to download the 
% file into the pwd directly from the MATLAB prompt:
%
% >> urlwrite('http://srdata.nist.gov/its90/download/all.tab','all.tab')
%
% Units are degrees Celsius for temperature and millivolts for voltage.
% Purely repeated entries at 0 degC are removed.
%
% Data is returned in an array of structures.  Each structure contains
% data for one type of thermocouple and has the following fields:
%
%          Type: 'B'                          % letter designation
%         TData: [1821x1 double]              % Temperature in degC
%         VData: [1821x1 double]              % Voltage in mV
%      numCoefs: {[7]  [9]}                   % numCoefs from file
%    coefsRange: {[2x1 double]  [2x1 double]} % Valid degC range for coefs
%         coefs: {[7x1 double]  [9x1 double]} % Coefs to get mV
%      expCoefs: []                           % exponent coefs
%      invCoefs: {[9x1 double]  [9x1 double]} % coefs to get degC
%      invRange: {[2x1 double]  [2x1 double]} % Valid mV range for coefs
%
%
% The polynomial coefficients and inverse coefficients are flipped by
% this routine to be compatible with MATLAB polyval() ordering.
%
% file format keys:
%   a line with * as the first non-white character is a comment
%   a line beginning with �C is a scale line
%     a scale line can increase to the right or decrease (!)
%     the first (or odd) one starts a table segment
%     the second (or even) ones end a table segment
%   a line beginning with ITS-90 Table is a table segment header
%   a line with Thermoelectric Voltage in mV is a units line
%   a data line begins with a temperature number and has >=1 emf entries
%
%   a line beginning with:
%          name: is the beginning of a polynomial section (fwd or inv)
%          type: is the t/c type letter
%     emf units: gives the output units
%         range: has a beginning, an end, and the order of the polynomial
%                there can be multiple range sections, vertically stacked
%   exponential: (optional) gives coefficients for the exponential
%                "Inverse coefficients" - header for the inverse polynomial
%   			 "Temperature" - beginning of an inverse poly T range
%         Range: end of an inverse poly range for temp, volts, or error
%       Voltage: beginning of an inverse poly volts range
%
% NOTE: multiple columns indicate multiple ranges, range goes vertically
%
% A line beginning with a number below an inverse polynomial declaration
% is a line of inverse data
%
% Error is the beginning  of an inverse poly voltage error
%
% an inverse polynomial declaration ends on a new table header (ITS-90 Table...) or EOF
%
% a BLANK line (all whitespace) is ignored
%
%
% Assertions:
%    table type, coefs, and inverse coefs do not mix
%

% roa 05 Feb 2004
% Copyright 1990-2005 The MathWorks, Inc.
% $Revision: 1.1.6.5 $

% --- Define reader state variables and built-up variables

isEOF    = false;
state    = 'enter';
substate = '';

tc           = [];
tcdata       = [];
currentScale = [];

% --- Open ITS-90 textual data file

%f = fopen(filename,'r', 'n', 'ISO-8859-1');
f = fopen(filename);
if (f < 0),
    error('Demos:TcData:FileNotFound', 'File ''%s'' not found', filename);
end

% --- Loop to process file line by line

while ~isEOF 
    
    % --- Read until a non-empty line is found
    
    [isEOF, line] = locGetNonEmptyLine(f);
    if isEOF
        continue;
    end
    
    % --- Determine what kind of line was just read
    
    [lineType,numbers] = locFindLineType(line);
    if strcmp(lineType,'comment')
        continue;
    end
    
    % --- Process current file reader state to determine next state

    locProcessReaderState();

    if strcmp(state,'lost'),
        warning('Demos:TcData:ReaderInternalError', ...
            'Algorithm error: thermocouple file reader state inconsistent');
    end
    
    % --- Extract data as indicated by the new state

    locExtractData();    

end

AddNewData();	% EOF-verwerking wordt (verkeerdelijk) niet opgeroepen!!

% --- clean up

fclose(f);

if isEOF && isempty(tc)
    error('Demos:TcData:InternalErrorEofNoData', ...
        'Algorithm error: exiting readstdtcdata() without setting return value');
elseif ~isEOF
    error('Demos:TcData:InternalErrorExitBeforeEof', ...
            'Algorithm error:  exiting readstdtcdata() before end of file');
end


% --------------------------- NESTED FUNCTIONS ---------------------------

% Function: locProcessReaderState ========================================
% Abstract:
%    Given the current file reader state and the line type, 
%    determine the new file reader state/substate
%
function locProcessReaderState()

substate = 'null';
newstate = 'null';

switch state
    case 'enter'
        if strcmp(lineType, 'tabHeader')
            newstate = 'newTabHeader';
            %
            % --- initialize data structure
            %
            tcdata = locInitTCData();
        end
    case 'newTabHeader'
        if strcmp(lineType, 'tabScale')
            newstate = 'tabScale';
        end
    case 'tabHeader'
        if strcmp(lineType, 'tabScale')
            newstate = 'tabScale';
        end
    case 'tabScale'
        if strcmp(lineType, 'tabHeader')
            newstate = 'tabHeader';
        elseif strcmp(lineType, 'tabUnits')
            newstate = 'tabUnits';
        elseif strcmp(lineType, 'cName')
            newstate = 'cName';
        end
    case 'tabUnits'
        if strcmp(lineType, 'data')
            newstate = 'tabData';
        end
    case 'tabData'
        if strcmp(lineType, 'data')
            newstate = 'tabData';
        elseif strcmp(lineType, 'tabScale')
            newstate = 'tabScale';
        end
    case 'cName'
        if strcmp(lineType, 'cType')
            newstate = 'cType';
        end
    case 'cType'
        if strcmp(lineType, 'cTUnits')
            newstate = 'cTUnits';
        end
    case 'cTUnits'
        if strcmp(lineType, 'cVUnits')
            newstate = 'cVUnits';
        end
    case 'cVUnits'
        if strcmp(lineType, 'cRange')
            newstate = 'cRange';
        end
    case 'cRange'
        if strcmp(lineType, 'data')
            newstate = 'cData';
        end
    case 'cData'
        if strcmp(lineType, 'data')
            newstate = 'cData';
        elseif strcmp(lineType, 'cRange')
            newstate = 'cRange';
        elseif strcmp(lineType, 'cExponent')
            newstate = 'cExponent';
        elseif strcmp(lineType, 'iHead')
            newstate = 'iHead';
        end
    case 'cExponent'
        if strcmp(lineType, 'cEData')
            newstate = 'cEData';
        end
    case 'cEData'
        if strcmp(lineType, 'cEData')
            newstate = 'cEData';
        elseif strcmp(lineType, 'cRange')
            newstate = 'cRange';
        elseif strcmp(lineType, 'iHead')
            newstate = 'iHead';
        end
    case 'iHead'
        if strcmp(lineType, 'iTemp')
            newstate = 'iTemp';
        end
    case 'iTemp'
        if strcmp(lineType, 'iRange')
            newstate = 'iRange';
            substate = 'iTemp';
        end
    case 'iVolts'
        if strcmp(lineType, 'iRange')
            newstate = 'iRange';
            substate = 'iVolts';
        end
    case 'iError'
        if strcmp(lineType, 'iRange')
            newstate = 'iRange';
            substate = 'iError';
        elseif strcmp(lineType, 'EOF')
            newstate = 'EOF';
        end
    case 'iRange'
        if strcmp(lineType, 'tabHeader')
            newstate = 'newTabHeader';  % only allowed after error range
            substate = '';
            % --- Adjust storage formats
            tcdata = removeDupZeros(tcdata);
            for k = 1:length(tcdata.coefs)
                tcdata.coefs{k} = flipud(tcdata.coefs{k});
            end
            for k = 1:length(tcdata.invCoefs)
                tcdata.invCoefs{k} = flipud(tcdata.invCoefs{k});
            end

            % --- Completed a table read - save into structure & reset
            AddNewData();
            tcdata = locInitTCData();
        elseif strcmp(lineType, 'iVolts')
            newstate = 'iVolts';
        elseif strcmp(lineType, 'data')
            newstate = 'iData';
        elseif strcmp(lineType, 'EOF')
            newstate = 'EOF';
        end
    case 'iData'
        if strcmp(lineType, 'data')
            newstate = 'iData';
        elseif strcmp(lineType, 'iError')
            newstate = 'iError';
        end
    otherwise
        newstate = 'lost';
end

if strcmp(newstate, 'null')
    state = 'lost';
else
    state = newstate;
end

end %function locProcessReaderState


% Function: locExtractData ===============================================
% Abstract:
%    Based on the current file reader state, read the current hunk of data
%
function locExtractData()

    switch lineType
        case 'tabScale'
            currentScale = locStr2DoubleArray(line(5:end));

        case 'data'
            switch state
                case 'tabData'
                    len = length(numbers);
                    if len > 1
                        %
                        % Only need 10 numbers, skip end number if there are 12 (a
                        % repeat!)
                        %
                        last = min(11,len);
                        newT = numbers(1) + currentScale(1:last-1)';
                        newV = numbers(2:last)';
                        if currentScale(2) < 0,
                            newT = flipud(newT);
                            newV = flipud(newV);
                        end
                        tcdata.TData = [tcdata.TData; newT ];
                        tcdata.VData = [tcdata.VData; newV ];
                    else
                        error('Demos:TcData:InvalidTableDataFound', ...
                            'invalid table data line encountered, >>%s<<', line);
                    end
                case 'cData'
                    % --- Handle multi-range case
                    k = length(tcdata.numCoefs);
                    if k > 0,
                        len = length(tcdata.coefs);
                        if len == 0,
                            tcdata.coefs    = { numbers(1) };
                        elseif len == k,
                            tcdata.coefs(k) = { [ tcdata.coefs{k}; numbers(1) ] };
                        elseif len < k,
                            tcdata.coefs(k) = { numbers(1) };
                        else
                            error('Demos:TcData:InternalErrorInPolyReader', ...
                                'reader is lost in polynomial coefficient section');
                        end
                    else
                        error('Demos:TcData:PolynomialCoefsOutOfOrder', ...
                            'Cannot read coefficients before poly order is read');
                    end
                case 'iData'
                    if isempty(tcdata.invCoefs),
                        for k= 1:length(numbers),
                            tcdata.invCoefs(k) = { numbers(k) };
                        end
                    else
                        for k= 1:length(numbers),
                            tcdata.invCoefs(k) = { [ tcdata.invCoefs{k}; numbers(k) ] };
                        end
                    end
                otherwise
                    error('Demos:TcData:UnknownDataTypeInFile', ...
                        'unknown data type');
            end

        case 'tabHeader'
            pos = strfind(line, 'type');
            if ~isempty(pos),
                type = strtok(line(pos+4:end));
                if isempty(tcdata.Type),
                    tcdata.Type = type;
                else
                    if ~strcmp(tcdata.Type,type),
                        error('Demos:TcData:FoundTcTypeInconsistent', ...
                            'Thermocouple type inconsistent, file corrupt?');
                    end
                end
            else
                error('Demos:TcData:UnreadableFileHeader', ...
                    'Thermocouple type not read from file header correctly');
            end

        case 'tabUnits'
            % get the units for consistency

        case 'cName'
        case 'cType'
            % --- Extract the thermocouple type from the line
            coefType = strtok(line(6:end));
            if ~strcmp(tcdata.Type, coefType),
                error('Demos:TcData:FoundTcTypeInconsistent', ...
                    'Thermocouple type inconsistent or unknown, is the file corrupt?');
            end
        case 'cTUnits'
        case 'cVUnits'
        case 'cRange'
            numbers = locStr2DoubleArray(line(7:end));
            if length(numbers) ~= 3,
                error('Demos:TcData:FileFormatNeeds3Coefs', ...
                    'Need 3 numbers on coefficient range line, found %d', length(numbers));
            else
                if isempty( tcdata.coefsRange ),
                    tcdata.coefsRange = { numbers(1:2)'  };
                    tcdata.numCoefs   = { numbers(3) + 1 };
                else
                    tcdata.coefsRange(end+1) = { numbers(1:2)'   };
                    tcdata.numCoefs(end+1)   = {  numbers(3) + 1 };
                end
            end
        case 'cExponent',
            % do nothing

        case 'cEData',
            % Only Type K range 2 currently uses this for ITS-90
            numbers = locStr2DoubleArray(line(7:end));
            m = length(tcdata.numCoefs);
            if isempty( tcdata.expCoefs ),
                tcdata.expCoefs(m) = { numbers };
            else
                tcdata.expCoefs(m) = { [ tcdata.expCoefs{m}; numbers ] };
            end
        case 'iHead',
        case 'iTemp',
        case 'iRange',
            if strcmp(substate,'iVolts'),
                % Read the second line of voltage range for the inverse coefficients
                numbers = locStr2DoubleArray(line(10:end));
                if isempty(tcdata.invRange),
                    for k= 1:length(numbers),
                        tcdata.invRange(k) = { numbers(k) };
                    end
                else
                    for k= 1:length(numbers),
                        tcdata.invRange(k) = { [ tcdata.invRange{k}; numbers(k) ] };
                    end
                end
            end
        case 'iVolts',
            % Read the beginning of the voltage range for the inverse coefficients
            numbers = locStr2DoubleArray(line(10:end));
            if isempty(tcdata.invRange),
                for k= 1:length(numbers),
                    tcdata.invRange(k) = { numbers(k) };
                end
            else
                for k = 1:length(numbers),
                    tcdata.invRange(k) = { [ tcdata.invRange{k}; numbers(k) ] };
                end
            end
        case 'iError',
        case 'EOF',
            % --- adjust storage formats
            tcdata = removeDupZeros(tcdata);
            for k = 1:length(tcdata.coefs),
                tcdata.coefs{k} = flipud(tcdata.coefs{k});
            end
            for k = 1:length(tcdata.invCoefs),
                tcdata.invCoefs{k} = flipud(tcdata.invCoefs{k});
			end

            % --- add struct to array of structs
            AddNewData();
        otherwise
            error('Demos:TcData:UnknownLineType', ...
                'Thermocouple file read algorithm failure: unhandled line type encountered');
    end

end %function locExtractData

function AddNewData()
if ~isempty(tcdata)&&~isempty(tcdata.Type)
	% dit werd geschreven voor "removeDupZeros" opgemerkt werd, terwijl
	%   dit niet leek te werken!!
	i=find(diff(tcdata.TData)<=0);
	if ~isempty(i)
		if length(i)>1||tcdata.TData(i)~=0
			warning('I thought that double datapoints were only found at 0!!')
			i=i(1);
		end
		if any(tcdata.VData(i)~=tcdata.VData(i+1))
			warning('Double datapoints in T are having different data in V?!!')
		end
		tcdata.TData(i)=[];
		tcdata.VData(i)=[];
	end
	tc=[tc;tcdata];
end
end % function AddNewData

end %function readstdtcdata


% Function: initTCData ===================================================
%
%
function tcdata = locInitTCData()
%INITTCDATA returns an empty thermocouple data structure

tcdata.Type        = '';
tcdata.TData       = [];
tcdata.VData       = [];
tcdata.numCoefs    = {};
tcdata.coefsRange  = {};
tcdata.coefs       = {};
tcdata.expCoefs    = {};
tcdata.invCoefs    = {};
tcdata.invRange    = {};

end %function initTCData


% Function: removeDupZeros ===============================================
% Abstract:
%   The ITS-90 tables have 2 types of "duplicate" points:
%
%   1) "repeated" voltages with different temperature data due
%      to the X.XXX numeric format - this is an artifact of the table
%      and not the actual physical behavior, which should be
%      differentiable many, many times (down to quantum levels at least)
%   2) one repeated zero voltage data point when crossing 0 degC
%
%   This function removes duplicates for variety #2 by identifying
%   exact duplicates - this is OK since we are not performing operations
%   on the data so numerics do not come into play.
%
function tcdata = removeDupZeros(indata)

% --- Find all zero voltage data points

tcdata = indata;
zIdx   = find(tcdata.TData == 0.0);

if length(zIdx) == 2 && tcdata.VData(zIdx(1)) == tcdata.VData(zIdx(2))
    skip   = zIdx(2);
    numPts = length(tcdata.TData);
    keep   = [1:(skip-1),(skip+1):numPts];
    % --- remove second zero-entry from the arrays
    tcdata.TData = tcdata.TData( keep );
    tcdata.VData = tcdata.VData( keep );
end

end %function removeDupZeros


% Function: locStr2DoubleArray ===========================================
% Abstract:
%    Uses str2num for reading a string into a numeric array
%
function numbers = locStr2DoubleArray(dataStr)

    numbers = str2num(dataStr);  %#ok

end %function locStr2DoubleArray


% Function: locGetNonEmptyLine ===========================================
% Abstract:
%    Read a line and remove trailing whitespace.  
%    If it is blank, read another line
%
function [isEOF,line] = locGetNonEmptyLine(hFile)

isEOF = false;
line  = '';

while ~isEOF && isempty(line) 
    % get a line and delete trailing spaces
    line  = deblank(fgetl(hFile));
    isEOF = feof(hFile);
end

end %function locGetNonEmptyLine


% Function: locFindLineType ==============================================
% Abstract:
%    Determines the kind of line currently in the line buffer.
%
function [lineType, numbers] = locFindLineType(line)

numbers = '';

% --- find type of line - check for comments before all else!

if line(1) == '*'
    lineType = 'comment';

elseif ~isempty(strfind(line, 'ITS-90 Table'))
    lineType = 'tabHeader';

elseif strcmp(strtok(line), char([176 67]))   % Use UTF-16 character code because character
    lineType = 'tabScale';                    % code 176 may not be supported on some environments.

elseif ~isempty(strfind(line, 'Thermoelectric Voltage in mV'))
    lineType = 'tabUnits';

elseif ~isempty(strfind(line, 'name:'))
    lineType = 'cName';

elseif ~isempty(strfind(line, 'type:'))
    lineType = 'cType';

elseif ~isempty(strfind(line, 'temperature units:'))
    lineType = 'cTUnits';

elseif ~isempty(strfind(line, 'emf units:'))
    lineType = 'cVUnits';

elseif ~isempty(strfind(line, 'range:'))
    lineType = 'cRange';

elseif ~isempty(strfind(line, 'exponential:'))
    lineType = 'cExponent';

elseif ~isempty(strfind(line, 'Inverse coefficients for type'))
    lineType = 'iHead';

elseif ~isempty(strfind(line, 'Temperature'))
    lineType = 'iTemp';

elseif ~isempty(strfind(line, 'Voltage'))
    lineType = 'iVolts';

elseif ~isempty(strfind(line, 'Error'))
    lineType = 'iError';

elseif ~isempty(strfind(line, 'Range:'))
    lineType = 'iRange';

elseif ~isempty(strfind(line, '=')) && strcmp(line(1:2),' a')
    lineType = 'cEData';

else
    %
    % --- must be some kind of data line or maybe a corrupt file
    %

    numbers = locStr2DoubleArray(line);
    if ~isempty(numbers) && isnumeric(numbers),
        lineType = 'data';
    else
        lineType = 'unknown';
    end

end

end %function locFindLineType

%[EOF] readstdtcdata_r14.m
