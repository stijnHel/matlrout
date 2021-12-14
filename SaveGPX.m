function SaveGPX(P,fName,trackName,bExt,bLF)
%SaveGPX  - Save track to GPX format
%   SaveGPX(P,fName,trackName)
%      P: array [time latitude longitude <elevation>]
%
%   format taken(/stolen) from Garmin GPX

% because gps didn't use any linefeed or carriage returns, this function
% doesn't do this either.

if nargin<5
	bLF=true;
	if nargin<4
		if nargin<3
			trackName='testTrack';
		end
		bExt=false;
	end
end

fid=fopen(fName,'w');
if fid<3
	error('Can''t open the file')
end
H={'<?xml version="1.0" encoding="UTF-8" standalone="no" ?>'};
if bExt
	H{2}='<gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxx="http://www.garmin.com/xmlschemas/WaypointExtension/v1" xmlns:gpxtrx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" creator="Oregon 550" version="1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/WaypointExtension/v1 http://www8.garmin.com/xmlschemas/WaypointExtensionv1.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd">';
else
	H{2}='<gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxx="http://www.garmin.com/xmlschemas/WaypointExtension/v1" xmlns:gpxtrx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" creator="Oregon 550" version="1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/WaypointExtension/v1 http://www8.garmin.com/xmlschemas/WaypointExtensionv1.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd">';
end

fprintf(fid,'%s',H{:});
if bLF
	fprintf(fid,'\n');
end
fprintf(fid,'<trk><name>%s</name>',trackName);
if bLF
	fprintf(fid,'\n');
end
fprintf(fid,'<trkseg>');
if bLF
	fprintf(fid,'\n');
end
for i=1:size(P,1)
	if bLF
		fprintf(fid,'   ');
	end
	fprintf(fid,'<trkpt lat="%8.6f" lon="%8.6f">',P(i,2:3));
	if size(P,2)>3
		fprintf(fid,'<ele>%4.2f</ele>',P(i,4));
	end
	fprintf(fid,'<time>%d-%02d-%02dT%02d:%02d:%02dZ</time>',datevec(P(i,1)));
	fprintf(fid,'</trkpt>');
	if bLF
		fprintf(fid,'\n');
	end
end
fprintf(fid,'</trkseg></trk>');
if bLF
	fprintf(fid,'\n');
end
fprintf(fid,'</gpx>');
if bLF
	fprintf(fid,'\n');
end
fclose(fid);
