function mis = VA_xml2mis(filename)
% XML2MIS builds a Measurement Information Structure from 
% an xml measurement information file
%
% mis = xml2mis(filename)
%
% Description:
%   
% This function gathers information about a measurement in an xml structured file
% and returns a structure. If the file can not be opened, an empty structure is 
% returned.
% 
%
% Parameters [IN]:
%   > filename : the name of the xml measurement information file
%
% Parameters [OUT]:
% > mis : the Measurement Information Structure filled with the content of the file
%
% See also -

% Authors: Tony Postiau
% Project: Vibro Acoustic GCO - VA ToolBox
% Created: February 2007
% Matlab version: MATLAB Version 7.0.0.19901 (R14)
%
% Copyright (c) 2006 FMTC Flanders Mechatronics Technology Centre, Belgium
%

% REMARKS 
% > This function make use of instructions from the Java language, therefore 
% some statements syntax might look unusual to the Matlab programmer. 
% > Matlab provides a function for reading an xml file. This one returns a DOM object.
% > Information about Java Interface for handling DOM can be found at
% http://java.sun.com/j2se/1.4.2/docs/guide/plugin/dom/index.html
% > Tutorial about xml can be found at http://www.w3schools.com/
% 

% Last Modifications
%   > tpos - 2007-03-13 : Add coupling and DC_Offset fields in mis.data.signal
%   shel - matlrout-compliant

% IMPORTANT VARIABLES 
% > xDoc  : the DOM object returned by the xmlread function 
% > xRoot : the root element of the document                                                                                                                        
%

% DEFINITION OF CONSTANTS
% > -

[fpth,fnam,fext]=fileparts(filename);
if length(fext)<=1
	if isempty(fext)
		filename(end+1)='.';
	end
	filename(end+1:end+3)='xml';
end
if ~exist(filename,'file')
	error('An error occured while reading the xml file %s',filename);
end
xDoc = xmlread(filename);

% <Measurement_Info>
xRoot = xDoc.getDocumentElement();

if xRoot.hasChildNodes()
	%
	% <DataFile>
	tag = 'DataFile';
	NodeList = xRoot.getElementsByTagName(tag);
	if NodeList.getLength == 1
		%
		iNode = NodeList.item(0);
		mis.(tag) = char(iNode.getChildNodes.item(0).getNodeValue());
		%
	else
		error(['xml document should contain exactly one <' tag '> node']);
	end

	% <SamplingRate>
	tag = 'SamplingRate';
	NodeList = xRoot.getElementsByTagName(tag);
	if NodeList.getLength == 1
		%
		iNode = NodeList.item(0);
		mis.(tag) = str2num(iNode.getChildNodes.item(0).getNodeValue());
		%
	else
		error(['xml document should contain exactly one <' tag '> node']);
	end

	% <SampleNumber>
	%     tag = 'SampleNumber';
	tag = 'NumberOfSamples';
	NodeList = xRoot.getElementsByTagName(tag);
	if NodeList.getLength == 1
		%
		iNode = NodeList.item(0);
		mis.(tag) = str2num(iNode.getChildNodes.item(0).getNodeValue());
		%
	else
		error(['xml document should contain exactly one <' tag '> node']);
	end

	% <blocksize>
	%     tag = 'blocksize';
	tag = 'BlockSize';
	NodeList = xRoot.getElementsByTagName(tag);
	if NodeList.getLength == 1
		%
		iNode = NodeList.item(0);
		mis.(tag) = str2num(iNode.getChildNodes.item(0).getNodeValue());
		%
	else
		error(['xml document should contain exactly one <' tag '> node']);
	end

	% <signalNumber>
	tag = 'NumberOfSignals';
	NodeList = xRoot.getElementsByTagName(tag);
	if NodeList.getLength == 1
		%
		iNode = NodeList.item(0);
		mis.(tag) = str2num(iNode.getChildNodes.item(0).getNodeValue());
		%
	else
		error(['xml document should contain exactly one <' tag '> node']);
	end

	% <info>
	NodeList = xRoot.getElementsByTagName('info');
	if NodeList.getLength >= 1
		iNode = NodeList.item(0);
		% <date>
		mis.info.date = xml_get_txtag(iNode,'date');
		% <time>
		mis.info.time = xml_get_txtag(iNode,'time');
		% <comment>
		mis.info.comment = xml_get_txtag(iNode,'comment');
	else
		warning(['Section <info> is missing in this xml document']);
	end
	% </info>

	% <identification>
	NodeList = xRoot.getElementsByTagName('identification');
	if NodeList.getLength == 1
		iNode = NodeList.item(0);
		% <measurement_id>
		mis.identification.measurement_id = xml_get_txtag(iNode,'measurement_id');
		% </measurement_id>
		tagNodeList = iNode.getElementsByTagName('tag');
		for itag=1:tagNodeList.getLength()
			% <tag>
			%   <info> the company where the measurement has been taken</info>
			% not implemented
			%   <name> company </name>
			mis.identification.tag(itag).name = xml_get_txtag(tagNodeList.item(itag-1),'name');
			%   <value> VDW </value>
			mis.identification.tag(itag).value = xml_get_txtag(tagNodeList.item(itag-1),'value');
			% </tag>
		end
	else
		%warning(['xml document should contain exactly one <identification> node']);
	end
	% </identification>

	% <tacho>
	NodeList = xRoot.getElementsByTagName('tacho');
	if NodeList.getLength == 1
		iNode = NodeList.item(0);
		% <SignalName>
		mis.tacho.SignalName = xml_get_txtag(iNode,'SignalName');
		% </SignalName>
	else
		%error(['xml document should contain exactly one <tacho> node']);
	end
	%</tacho>

	% <data>
	NodeList = xRoot.getElementsByTagName('data');
	if NodeList.getLength == 1
		iNode = NodeList.item(0);
		chNodeList = iNode.getElementsByTagName('signal');
		nn = chNodeList.getLength();
		if nn ~= mis.NumberOfSignals
			error('Wrong number of signals : Inconsistent Measurement Information File');
		end
		for ich = 1:nn
			% <signal>
			%   <name> AE </name>
			mis.data.signal(ich).name = xml_get_txtag(chNodeList.item(ich-1),'name');
			%   <sensor> SN 50699 accelerometer z rad </sensor>
			mis.data.signal(ich).sensorID = xml_get_txtag(chNodeList.item(ich-1),'sensorID');
			%   <units> m/s^2 </units>
			mis.data.signal(ich).units = xml_get_txtag(chNodeList.item(ich-1),'units');
			%   <sensitivity>
			mis.data.signal(ich).sensitivity = xml_get_valtag(chNodeList.item(ich-1),'sensitivity');
			%   <dBref>
			mis.data.signal(ich).dBref = xml_get_valtag(chNodeList.item(ich-1),'dBref');
			%   <type>
			mis.data.signal(ich).type = xml_get_txtag(chNodeList.item(ich-1),'type');
			%   %<DAQdevice>
			%mis.data.signal(ich).DAQdevice = xml_get_txtag(chNodeList.item(ich-1),'DAQdevice');
			%   <DAQchannel>
			mis.data.signal(ich).DAQchannel = xml_get_txtag(chNodeList.item(ich-1),'DAQchannel');
			%   <Coupling>
			mis.data.signal(ich).Coupling = xml_get_txtag(chNodeList.item(ich-1),'Coupling');
			%   <Offset>
			mis.data.signal(ich).DC_Offset = xml_get_valtag(chNodeList.item(ich-1),'DC_Offset');
			%   <comment> I enjoyed doing this measurement </comment>
			mis.data.signal(ich).comment = xml_get_txtag(chNodeList.item(ich-1),'comment');
			%   <IEPEcurrent>
			mis.data.signal(ich).IEPEcurrent = xml_get_valtag(chNodeList.item(ich-1),'IEPEcurrent');
			%</signal>
		end
	else
		%warning(['xml document should contain exactly one <data> node']);
	end
	% </data>
end

return

%--------------------------------------------------------------------------
function val = xml_get_val(iNode)
val = str2double(iNode.getChildNodes.item(0).getNodeValue());
return

%--------------------------------------------------------------------------
function sval = xml_get_valtag(Node,tag)

iNodes = Node.getElementsByTagName(tag);
nn = iNodes.getLength();
if nn > 0
	%for i=1:nn > 0
	iNode = iNodes.item(0);%(i);%
	%sval(i)
	sval = xml_get_val(iNode);
	%end
else
	sval = 0.0;
end

return

%--------------------------------------------------------------------------
function stxt = xml_get_txtag(Node,tag)

iNodes = Node.getElementsByTagName(tag);
nn = iNodes.getLength();
if nn > 0
	%for i=1:nn > 0
	iNode = iNodes.item(0);%(i);%
	%stxt{i}
	if ~isempty(iNode.getChildNodes.item(0))
		stxt = (char(iNode.getChildNodes.item(0).getNodeValue().trim()));
	else
		stxt = '';
	end
	%end
else
	stxt = '';
end

return
%--------------------------------------------------------------------------
function hastag = xml_has_tag(Node,tag)

iNodes = Node.getElementsByTagName(tag);
nn = iNodes.getLength();
if nn > 0
	hastag = true;
else
	hastag = false;
end

return
%--------------------------------------------------------------------------

