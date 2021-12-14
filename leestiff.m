function D=leestiff(f)% LEESTIFF - Leest tiff-filepersistent TIFFTags% TIFFTags :%    TagName, ID, Type, number of values%      type : 2 ( 1) : BYTE%             4 ( 2) : ASCII%             8 ( 3) : SHORT%            16 ( 4) : LONG%            32 ( 5) : RATIONAL%            64 ( 6) : SBYTE%           128 ( 7) : undefined (8-bit byte - any interpretation)%           256 ( 8) : SSHORT%           512 ( 9) : SLONG%          1024 (10) : SRATIONAL%          2048 (11) : FLOAT%          4096 (12) : DOUBLE%         (bitor of possible values)%if isempty(TIFFTags)	% see https://www.loc.gov/preservation/digital/formats/content/tiff_tags.shtml	%  and https://awaresystems.be/imaging/tiff/tifftags.html	TIFFTags={'NewSubfileType',254,16,1;		'SubfileType',255,8,1;		'ImageWidth',256,24,1;		'ImageLength',257,24,1;		'BitsPerSample',258,8,-1;		'Compression',259,8,1;	... 1 uncompressed,CCID 1D, Group 3 fax, Group 4 fax, LZW, (6) JPEG, (32773)PackBits		'PhotometricInterpretation',262,8,1;	... 0 (whiteIsZero), BlackIsZero, RGB, RGB Palette, Transparency mask, CMYK, (6)YCbCr, (8)CIELab		'Threshholding',263,8,1;		'CellWidth',264,8,1;		'FillOrder',266,8,1;		'DocumentName',269,4,-1;		'ImageDescription',270,4,-1;		'Make',271,4,-1;		'Model',272,4,-1;		'StripOffsets',273,24,-1;		'Orientation',274,0,0;	... only 2 first values added		'SamplesPerPixel',277,0,0;	... only 2 first values added		'RowsPerStrip',278,0,0;	... only 2 first values added		'StripByteCounts',279,0,0;	... only 2 first values added		'MinSampleValue',280,0,0;	... only 2 first values added		'MaxSampleValue',281,0,0;	... only 2 first values added		'XResolution',282,0,0;	... only 2 first values added		'YResolution',283,0,0;	... only 2 first values added		'PlanarConfiguration',284,0,0;	... only 2 first values added		'PageName',285,0,0;	... only 2 first values added		'XPosition',286,0,0;	... only 2 first values added		'YPosition',287,0,0;	... only 2 first values added		'FreeOffsets',288,0,0;	... only 2 first values added		'FreeByteCounts',289,0,0;	... only 2 first values added		'GrayResponseUnit',290,0,0;	... only 2 first values added		'GrayResponseCurve',291,0,0;	... only 2 first values added		'T4Options',292,0,0;	... only 2 first values added		'T6Options',293,0,0;	... only 2 first values added		'ResolutionUnit',296,0,0;	... only 2 first values added		'PageNumber',297,0,0;	... only 2 first values added		'TransferFunction',301,0,0;	... only 2 first values added		'Software',305,0,0;	... only 2 first values added		'DateTime',306,0,0;	... only 2 first values added		'Artist',315,0,0;	... only 2 first values added		'HostComputer',316,0,0;	... only 2 first values added		'Predictor',317,0,0;	... only 2 first values added		'WhitePoint',318,0,0;	... only 2 first values added		'PrimageChromaticities',319,0,0;	... only 2 first values added		'ColorMap',320,0,0;	... only 2 first values added		'HalftoneHints',321,0,0;	... only 2 first values added		'TileWidth',322,0,0;	... only 2 first values added		'TileLength',323,0,0;	... only 2 first values added		'TileOffsets',324,0,0;	... only 2 first values added		'TileByteCounts',325,0,0;	... only 2 first values added		'BadFaxLines',326,0,0;	... only 2 first values added		'SampleFormat',339,0,0;	... only 2 first values added		'ModelPixelScaleTag',33550,0,0;	... only 2 first values added		'ModelTiepointTag',33922,0,0;	... only 2 first values added		'GeoKeyDirectoryTag',34735,0,0;	... only 2 first values added		'GeoDoubleParamsTag',34736,0,0;	... only 2 first values added		'GeoAsciiParamsTag',34737,0,0;	... only 2 first values added		'GDAL_NODATA',42113,0,0;	... only 2 first values added		};endbPrint = nargout==0;tagIDs=cat(1,TIFFTags{:,2});typeLengtes=[1 1 2 4 8];if ischar(f)	fid=fopen(f);	if fid<3		error('Kan file niet openen');	end	x=fread(fid,[1 Inf],'*uint8');	fclose(fid);else	x=f;endbRevBytes = false;if x(1)=='I' && x(2)=='I'	% OKelseif x(1)=='M' && x(2)=='M'	bRevBytes = true;else	error('verkeerd file-type (onbekend endian-type)')endif toInt16(x(3:4))~=42	error('verkeerd filetype (onjuist versienummer)')endiIFD=toInt32(x(5:8));D = struct('tags',cell(1,1000));nD = 0;while iIFD	% (!)dubbele transpose - dit moet vermeden kunnen worden.	nDirEntries=toInt16(x(iIFD+1:iIFD+2));	xDirEnt=reshape(x(iIFD+3:iIFD+2+nDirEntries*12),12,nDirEntries)';	TagIDs=toInt16(xDirEnt(:,1:2)');	FieldTypes=toInt16(xDirEnt(:,3:4)');	nValues=toInt32(xDirEnt(:,5:8)');	valueOffsets=toInt32(xDirEnt(:,9:12)');	tags = struct('TagID',num2cell(TagIDs),'name',''	...		,'FieldType',num2cell(FieldTypes)	...		,'nValues',num2cell(nValues),'valueOffsets',num2cell(valueOffsets)	...		,'data',[]);	for k=1:length(TagIDs)		i=find(tagIDs==TagIDs(k));		if ~isempty(i)			tags(k).name = TIFFTags{i,1};			if length(typeLengtes)>=FieldTypes(k) && typeLengtes(FieldTypes(k))*nValues(k)<=4				l=typeLengtes(FieldTypes(k));				data=gettiffdata(xDirEnt(k,9:8+l*nValues(k)),TagIDs(k),FieldTypes(k),nValues(k),0);			else				data=gettiffdata(x,TagIDs(k),FieldTypes(k),nValues(k),valueOffsets(k));			end			tags(k).data = data;			if bPrint				fprintf('%2d : (%3d) %s : ',k,TagIDs(k),TIFFTags{i,1})				disp(data)			end		elseif bPrint			fprintf('%2d : (%3d) : %d %d %d\n',k,TagIDs(k),FieldTypes(k),nValues(k),valueOffsets(k))		end	end	nD = nD+1;	if nD>length(D)		D(nD+1000).tags=[];	end	D(nD).tags = tags;	ix = iIFD+2+nDirEntries*12;	iIFD=toInt32(x(ix+1:ix+4));endif nD<length(D)	D = D(1:nD);end	function data=gettiffdata(x,ID,fType,nValues,offset)		switch fType			case 1	% BYTE				data=x(offset+1:offset+nValues);			case 2	% ASCII				data=char(x(offset+1:offset+nValues-1));				if x(offset+nValues)~=0					warning('!!!ASCII niet null-terminated')				end			case 3	% WORD				data=toInt16(x(offset+1:offset+nValues*2));			case 4	% LONG				data=toInt32(x(offset+1:offset+nValues*4));			case 5	% RATIONAL				data=reshape(toInt32(x(offset+1:offset+nValues*8)),2,nValues);				data=double(data(1,:))./double(data(2,:));			case 6	% SBYTE				data=typecast(x(offset+1:offset+nValues),'int8');			case 7	% undefined				data=x(offset+1:offset+nValues);			case 8	% SSHORT				data=typecast(toInt16(x(offset+1:offset+nValues*2)),'int16');			case 9	% SLONG				data=typecast(toInt32(x(offset+1:offset+nValues*4)),'int32');			case 10	% SRATIONAL				data=reshape(toInt32(x(offset+1:offset+nValues*8)),2,nValues);				% sign!!!!!				data=double(data(1,:))./double(data(2,:));			case 11	% FLOAT				data=toSingle(x(offset+1:offset+nValues*4));			case 12	% DOUBLE				data=toDouble(x(offset+1:offset+nValues*8));			otherwise				warning('Unknown data type (%d)',fType)				data = [];		end	end		% gettiffdata	function i = toInt16(x)		i = typecast(x(:)','uint16');		if bRevBytes			i = swapbytes(i);		end		i = double(i);	% because Matlab doesn't like this...	end		% toInt16	function i = toInt32(x)		i = typecast(x(:)','uint32');		if bRevBytes			i = swapbytes(i);		end		i = double(i);	% because Matlab doesn't like this...	end		% toInt32	function i = toDouble(x)		i = typecast(x(:)','double');		if bRevBytes			i = swapbytes(i);		end	end		% toDoubleend		% leestiff