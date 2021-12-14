function tc = readstdtcdata_r13(filename)
%READSTDTCDATA_r13 parse ITS-90 thermocouple database file
%
% file format keys:
%   a line with * as the first non-white character is a comment
%   a line beginning with �C is a scale line
%     a scale line can increase to the right or decrease (!)
%     the first (or odd) one starts a table segment
%     the second (or even) ones end a table segment
%   a line beginning with ITS-90 Table is a table segment header
%   a line with Thermoelectric Voltage in mV is a units line
%   a data line begins with a temperature number and has 1 or more emf entries
%
%   a line beginning with name: is the beginning of a polynomial section (fwd or inv)
%                         type: is the t/c type letter
%                         emf units: gives the output units
%                         range:  has a beginning, an end, and the order of the polynomial
%                           there can be multiple range sections, vertically stacked
%                           exponential: (optional) gives coefficients for the exponential
%   			  Inverse coefficients is the header for the inverse polynomial
%   			  Temperature is the beginning of an inverse poly temperature range
%   			  Range: is the end of an inverse poly range for temp, volts, or error
%   			  Voltage is the beginning of an inverse poly volts range
%                           NOTE: multiple columns indicate multiple ranges, vertically       
% a line beginning with a number below an inverse polynomial declaration is a line of inverse data
%                        Error is the beginning  of an inverse poly voltage error
% an inverse polynomial declaration ends on a new table header (ITS-90 Table...) or EOF  
% a BLANK line (all whitespace) is ignored
%
%
% Assertions: 
%    table type, coefs, and inverse coefs do not mix
%

% aangepast : probleem met degree-symbool - FMTC - SHEL - 2006-05-29

tc = [];

f = fopen(filename); 
if (f < 0),
  error(sprintf('File ''%d'' not found', filename));
end

state = 'enter';

while ~feof(f)

  line = fgetl(f);
  line(line==65533)='@';
  line(line==176)='@';

  % --- find type of line - check for comments before all else!

  if feof(f),
    lineType = 'EOF';
    
  elseif isempty(strtok(line)),
    lineType = 'blank';
    
  elseif line(1) == '*',
    lineType = 'comment';
    
  elseif ~isempty(strfind(line, 'ITS-90 Table')),
    lineType = 'tabHeader';
    
  elseif strcmp(strtok(line), '@C'),
    lineType = 'tabScale';
    
  elseif ~isempty(strfind(line, 'Thermoelectric Voltage in mV')),
    lineType = 'tabUnits';
    
  elseif ~isempty(strfind(line, 'name:')),
    lineType = 'cName';
    
  elseif ~isempty(strfind(line, 'type:')),
    lineType = 'cType';
    
  elseif ~isempty(strfind(line, 'temperature units:')),
    lineType = 'cTUnits';
    
  elseif ~isempty(strfind(line, 'emf units:')),
    lineType = 'cVUnits';
    
  elseif ~isempty(strfind(line, 'range:')),
    lineType = 'cRange';
    
  elseif ~isempty(strfind(line, 'exponential:')),
    lineType = 'cExponent';
    
  elseif ~isempty(strfind(line, 'Inverse coefficients for type')),
    lineType = 'iHead';
    
  elseif ~isempty(strfind(line, 'Temperature')),
    lineType = 'iTemp';
    
  elseif ~isempty(strfind(line, 'Voltage')),
    lineType = 'iVolts';
    
  elseif ~isempty(strfind(line, 'Error')),
    lineType = 'iError';
    
  elseif ~isempty(strfind(line, 'Range:')),
    lineType = 'iRange';
    
  elseif ~isempty(strfind(line, '=')) && strcmp(line(1:2),' a'),
    lineType = 'cEData';
        
  else
    %
    % --- must be some kind of data line or a corrupt file
    %
    
    numbers = str2num(line);
    if ~isempty(numbers) && isnumeric(numbers),
      lineType = 'data';
    else
      lineType = 'unknown';
    end
    
  end

  
  % --- Process reader state

  prevState = state;
  
  if ~( strcmp(lineType, 'blank') || strcmp(lineType, 'comment') ),
    switch state
      case 'EOF'
        disp(sprintf('EOF encountered'));
        continue;
      case 'enter'
        if strcmp(lineType, 'tabHeader'),
          state = 'newTabHeader';
          %
          % --- initialize data structure
          %
          tcdata = locInitTCData;
        else
          state = 'lost';
        end
      case 'newTabHeader'
        if strcmp(lineType, 'tabScale'),
          state = 'tabScale';
        else
          state = 'lost';
        end
      case 'tabHeader'
        if strcmp(lineType, 'tabScale'),
          state = 'tabScale';
        else
          state = 'lost';
        end
      case 'tabScale'
        if strcmp(lineType, 'tabHeader'),
          state = 'tabHeader';
        elseif strcmp(lineType, 'tabUnits'),
          state = 'tabUnits';
        elseif strcmp(lineType, 'cName'),
          state = 'cName';
        else
          state = 'lost';
        end
      case 'tabUnits'
        if strcmp(lineType, 'data'),
          state = 'tabData';
        else
          state = 'lost';
        end
      case 'tabData'
        if strcmp(lineType, 'data'),
          state = 'tabData';
        elseif strcmp(lineType, 'tabScale'),
          state = 'tabScale';  % xxx end of table section encountered?
        else
          state = 'lost';
        end
      case 'cName'
        if strcmp(lineType, 'cType'),
          state = 'cType';
        else
          state = 'lost';
        end
      case 'cType'
        if strcmp(lineType, 'cTUnits'),
          state = 'cTUnits';
        else
          state = 'lost';
        end
      case 'cTUnits'
        if strcmp(lineType, 'cVUnits'),
          state = 'cVUnits';
        else
          state = 'lost';
        end
      case 'cVUnits'
        if strcmp(lineType, 'cRange'),
          state = 'cRange';
        else
          state = 'lost';
        end
      case 'cRange'
        if strcmp(lineType, 'data'),
          state = 'cData';
        else
          state = 'lost';
        end
      case 'cData'
        if strcmp(lineType, 'data'),
          state = 'cData';
        elseif strcmp(lineType, 'cRange'),
          state = 'cRange';
        elseif strcmp(lineType, 'cExponent'),
          state = 'cExponent';
        elseif strcmp(lineType, 'iHead'),
          state = 'iHead';
        else
          state = 'lost';
        end
      case 'cExponent'
        if strcmp(lineType, 'cEData'),
          state = 'cEData';
        else
          state = 'lost';
        end
      case 'cEData'
        if strcmp(lineType, 'cEData'),
          state = 'cEData';
        elseif strcmp(lineType, 'cRange'),
          state = 'cRange';
        elseif strcmp(lineType, 'iHead'),
          state = 'iHead';
        else
          state = 'lost';
        end
      case 'iHead'
        if strcmp(lineType, 'iTemp'),
          state = 'iTemp';
        else
          state = 'lost';
        end
      case 'iTemp'
        if strcmp(lineType, 'iRange'),
          state = 'iRange';  % xxx could use a range submode
        else
          state = 'lost';
        end
      case 'iVolts'
        if strcmp(lineType, 'iRange'),
          state = 'iRange';
        else
          state = 'lost';
        end
      case 'iError'
        if strcmp(lineType, 'iRange'),
          state = 'iRange';
        elseif strcmp(lineType, 'EOF'),
          state = 'EOF';
        else
          state = 'lost';
        end
      case 'iRange'
        if strcmp(lineType, 'tabHeader'),
          state = 'newTabHeader';  % only after error range!
          %
          % --- Completed a table read - save structure!
          %
          tc = [ tc; tcdata ];
          tcdata = locInitTCData;
        elseif strcmp(lineType, 'iVolts'),
          state = 'iVolts';
        elseif strcmp(lineType, 'data'),          
          state = 'iData';
        elseif strcmp(lineType, 'EOF'),
          state = 'EOF';
        else
          state = 'lost';
        end
      case 'iData'
        if strcmp(lineType, 'data'),
          state = 'iData';
        elseif strcmp(lineType, 'iError'),
          state = 'iError';
        else
          state = 'lost';
        end
      otherwise
        state = 'lost';
    end

    
    % --- Extract data from line

    if strcmp(state,'lost'),
      warning(sprintf('Algorithm error: thermocouple file reader state inconsistent'));
    end
    
    switch lineType
      case 'data'
        switch state
          case 'tabData'
            len = length(numbers);
            if len > 1,
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
              error(sprintf('invalid table data line encountered, >>%s<<', line));
            end
          case 'cData'
            % xxx multi-case not handled correctly yet!!
            tcdata.coefs    = [ tcdata.coefs; numbers(1) ];
          case 'iData'
            tcdata.invCoefs = [ tcdata.invCoefs; numbers ];
          otherwise
            error(sprintf('unknown data type'));
        end
        
      case 'tabHeader'
        pos = strfind(line, 'type');
        if ~isempty(pos),
          type = strtok(line(pos+4:end));
          if isempty(tcdata.Type),
            tcdata.Type = type;
          else
            if ~strcmp(tcdata.Type,type),
              error(sprintf('Thermocouple type inconsistent, file corrupt?'));
            end
          end
        else
          error(sprintf('Thermocouple type not read from file header correctly'));
        end
        
      case 'tabScale'
        currentScale = str2num(line(5:end));
        
      case 'tabUnits'
        % get the units for consistency
        
      case 'cName'
      case 'cType'
        % extract the thermocouple type from the line
        coefType = strtok(line(6:end));
        if ~strcmp(tcdata.Type, coefType),
          % xxx OR if not a recognized type
          error(sprintf('Thermocouple type inconsistent, file corrupt?'));
        end
      case 'cTUnits'
      case 'cVUnits'
      case 'cRange'
        numbers = str2num(line(7:end));
        if length(numbers) ~= 3,
          error(sprintf('Need 3 numbers on coefficient range line, found %d', length(numbers)));
        else
          tcdata.coefsRange = tcdata.coefsRange; numbers(1:2);
          tcdata.numCoefs  = numbers(3);
        end
      case 'cExponent',
        % do nothing
        
      case 'cEData'
        numbers = str2num(line(7:end));
        k = str2num(line(3));
        tcdata.expCoefs(k+1) = numbers;
        
      case 'iHead',
      case 'iTemp',
      case 'iRange',
      case 'iVolts',
      case 'iError',
      case 'EOF',
        tc = [tc; tcdata];
      otherwise
        error(sprintf('Thermocouple file read algorithm failure: unhandled line type encountered'));
  end
  end

  
end


% --- clean up

fclose(f);

if strcmp(state,'EOF'),
  if isempty(tc),
    error(sprintf('Algorithm error: exiting readstdtcdata() without setting return value'));
  end
else
  error(sprintf('Algorithm error:  exiting readstdtcdata() before end of file'));
end


%endfunction readstdtcdata


% Function: initTCData =======================================================
%
%
function tcdata = locInitTCData()
%INITTCDATA returns an empty thermocouple data structure

tcdata.Type        = '';
tcdata.TData       = [];
tcdata.VData       = [];
tcdata.numCoefs    =  0;
tcdata.coefsRange  = [];
tcdata.coefs       = [];
tcdata.expCoefs    = [];
tcdata.invCoefs    = [];
tcdata.invRange    = [];

%endfunction initTCData

%[EOF] readstdtcdata_r13.m
