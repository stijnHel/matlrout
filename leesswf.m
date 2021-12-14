function [uit,X]=leesswf(f)

global SWF_versie SWF_x_last
global SWF_tags SWF_ttypes SWF_actionIDs SWF_sactions
global onbIDs onbActions
if isempty(SWF_tags)
	SWF_tags={'End','ShowFrame','DefineShape','FreeCharacter','PlaceObject',	...		0-4
		'RemoveObject','DefineBits','DefineButton','JPEGTables','SetBackGroundColor',	... 5-9
		'DefineFont','DefineText','DoActionTag','DefineFontInfo','DefineSound',	...	10-14
		'StartSound','xxxID16','DefineButtonSound','SoundStreamHead','SoundStreamBlock'	... 15-19
		'DefineBitsLossLess','DefineBitsJPEG2','DefineShape2','DefineButtonCxForm','Protect'	... 20-24
		'PathsArePostScript','PlaceObject2','xxxID27','RemoveObject2','SyncFrame',	... 25-29
		'xxxID30','FreeAll','DefineShape3','DefineText2','DefineButton2',	... 30-34
		'DefineBitsJPEG3','DefineBitsLossLess2','DefineEditText','DefineMovie','DefineSprite',	... 35-39
		'NameCharacter','SerialNumber','DefineTextFormat','FrameLabel','xxxID44',	... 40-44
		'SoundStreamHead2','DefineMorphShape','FrameTag','DefineFont2','GenCommand',	... 45-49
		'DefineCommandObj','CharacterSet','FontRef','xxxID53','xxxID54',	... 50-54
		'xxxID55','ExportAssets','ImportAssets','EnableDebugger'};	% 55-58
%	           0 1 2 3 4 5 6 7 8 9
	SWF_ttypes=[0 0 1 0 0 0 1 1 1 0	...	 0- 9
	           1 1 0 1 1 0 0 1 0 0	... 10-19
			   1 1 1 1 0 0 0 0 0 0	... 20-29
			   0 0 1 1 1 1 1 1 1 1	... 30-39
			   0 0 1 0 0 1 1 0 1 0	... 40-49
			   1 0 0 0 0 0 0 0 0	... 50-58
	           ];
	SWF_actionIDs=[	...
	     0     4     5     6     7     8     9    10    11    12    13    14	...
	    15    16    17    18    19    20    21    23    24    28    29    32	...
	    33    34    35    36    37    38    39    40    41    48    49    50	...
	    51    52    53    54    55   58 59 60 61 62 63 64 65 66 68 69 70	...
		71 72 73 74 75 76 77 78 79 80 83 96 97 98 99 100 101	...
	128   129   131  135  138   139   140   141	...
	  148 150   153   154   157   158   159   170];
	SWF_sactions={	...
			'sactionNone',            	...   0 [0x00]
			'sactionNextFrame',       	...   4 [0x04]
			'sactionPrevFrame',       	...   5 [0x05]
			'sactionPlay',            	...   6 [0x06]
			'sactionStop',            	...   7 [0x07]
			'sactionToggleQuality',   	...   8 [0x08]
			'sactionStopSounds',      	...   9 [0x09]
			'sactionAdd',             	...  10 [0x0a]
			'sactionSubtract',        	...  11 [0x0b]
			'sactionMultiply',        	...  12 [0x0c]
			'sactionDivide',          	...  13 [0x0d]
			'sactionEquals',          	...  14 [0x0e]
			'sactionLess',            	...  15 [0x0f]
			'sactionAnd',             	...  16 [0x10]
			'sactionOr',              	...  17 [0x11]
			'sactionNot',             	...  18 [0x12]
			'sactionStringEquals',    	...  19 [0x13]
			'sactionStringLength',    	...  20 [0x14]
			'sactionStringExtract',   	...  21 [0x15]
			'sactionPop',             	...  23 [0x17]
			'sactionToInteger',       	...  24 [0x18]
			'sactionGetVariable',     	...  28 [0x1c]
			'sactionSetVariable',     	...  29 [0x1d]
			'sactionSetTarget2',      	...  32 [0x20]
			'sactionStringAdd',       	...  33 [0x21]
			'sactionGetProperty',     	...  34 [0x22]
			'sactionSetProperty',     	...  35 [0x23]
			'sactionCloneSprite',     	...  36 [0x24]
			'sactionRemoveSprite',    	...  37 [0x25]
			'sactionTrace',           	...  38 [0x26]
			'sactionStartDrag',       	...  39 [0x27]
			'sactionEndDrag',         	...  40 [0x28]
			'sactionStringLess',      	...  41 [0x29]
			'sactionRandomNumber',    	...  48 [0x30]
			'sactionMBStringLength',  	...  49 [0x31]
			'sactionCharToAscii',     	...  50 [0x32]
			'sactionAsciiToChar',     	...  51 [0x33]
			'sactionGetTime',         	...  52 [0x34]
			'sactionMBStringExtract', 	...  53 [0x35]
			'sactionMBCharToAscii',   	...  54 [0x36]
			'sactionMBAsciiToChar',   	...  55 [0x37]
			'sactionDelete',     		...  58 [0x3a]
			'sactionDelete2',     		...  59 [0x3b]
			'sactionDefineLocal', 		...  60 [0x3c]
			'sactionCallFunction', 		...  61 [0x3d]
			'sactionReturn',     		...  62 [0x3e]
			'sactionModulo',     		...  63 [0x3f]
			'sactionNewObject',    		...  64 [0x40]
			'sactionDefineLocal',  		...  65 [0x41]
			'saction!!InitArray__InitObject---docerror',	...  66 [0x42]
			'sactionTypeOf',     		...  68 [0x44]
			'sactionTargetPath',   		...  69 [0x45]
			'sactionEnumerate',   		...  70 [0x46]
			'sactionAdd2',      		...  71 [0x47]
			'sactionLess2',     		...  72 [0x48]
			'sactionEquals2',     		...  73 [0x49]
			'sactionToNumber',     		...  74 [0x4a]
			'sactionToString',     		...  75 [0x4b]
			'sactionPushDuplicate',		...  76 [0x4c]
			'sactionStackSwap',    		...  77 [0x4d]
			'sactionGetMember',   		...  78 [0x4e]
			'sactionSetMember',   		...  79 [0x4f]
			'sactionIncrement',    		...  80 [0x50]
			'sactionNewMethod',   		...  83 [0x53]
			'sactionBitAnd',     		...  96 [0x60]
			'sactionBitOr',     		...  97 [0x61]
			'sactionBitXor',     		...  98 [0x62]
			'sactionBitShift',     		...  99 [0x63]
			'sactionBitRShift',    		... 100 [0x64]
			'sactionBitURShift',   		... 101 [0x65]
			'sactionHasLength',       	... 128 [0x80]
			'sactionGotoFrame',       	... 129 [0x81]
			'sactionGetURL',          	... 131 [0x83]
			'sactionStoreRegister',		... 135 [0x87]
			'sactionWaitForFrame',    	... 138 [0x8a]
			'sactionSetTarget',       	... 139 [0x8b]
			'sactionGotoLabel',       	... 140 [0x8c]
			'sactionWaitForFrame2',   	... 141 [0x8d]
			'sactionWith',      		... 148 [0x94]
			'sactionPush',            	... 150 [0x96]
			'sactionJump',            	... 153 [0x99]
			'sactionGetURL2',         	... 154 [0x9a]
			'sactionIf',              	... 157 [0x9d]
			'sactionCall',            	... 158 [0x9e]
			'sactionGotoFrame2',      	... 159 [0x9f]
			'sactionQuickTime',       	... 170 [0xaa]
			};

end
% (tagName zou hier niet opgenomen moeten worden (alsook de actionName).  Het vergemakkelijkt
%  wel het manueel bekijken van SWF-files, maar vergroot sterk het geheugengebruik.)
endian4=[1 256 65536 16777216];
endian2=[1 256];
if ischar(f)
	fid=fopen(f,'r');
	if fid<3
		error('kan file niet openen');
	end
	x=fread(fid);
	fclose(fid);
else
	x=f;
end
SWF_x_last=x;
if length(x)<21
	error('lengte te klein');
end
if x(1)~=double('F')|x(2)~=double('W')|x(3)~=double('S')
	if x(1)==double('C')
		warning('?CWS ipv FWS als signature?')
	else
		error('Eerste begin (signature) is niet juist (%c%c%c)',x(1),x(2),x(3))
	end
end
ver=x(4);
SWF_versie=ver;
len=endian4*x(5:8);
if len~=length(x)
	warning(sprintf('aangegeven lengte is verschillend met de werkelijke filelengte (%d <--> %d)',len,length(x)))
	if len<length(x)
		printhex(x(len+1:end))
	end
end
[frameSize,i]=leesSWFRect(x,9);
frameRate=x(i+1);
i=i+2;
frameCount=endian2*x(i:i+1);
i=i+2;
uit=struct('versie',ver,'len',len,'frameSize',frameSize	...
	,'frameRate',frameRate	...
	,'frameCount',frameCount	...
	,'frames',[]	...
	);
frames=cell(1,frameCount);
frameNr=0;
leesFrames=1;
tags=struct('tagID',[],'tagLen',[],'tagData',cell(1,200));
while leesFrames
	frameNr=frameNr+1;
	tagNr=0;
	leesFrame=1;
	while leesFrame
		if i>length(x)
			warning('Lezen van SWF-file onderbroken door overschrijden einde van file.');
			leesFrames=0;
			break;
		end
		tagNr=tagNr+1;
		if frameNr==212&tagNr==42 % gewoon om een breakpoint te kunnen zetten
			ver=ver;
		end
		tagHead=endian2*x(i:i+1);
		tagID=bitshift(tagHead,-6);
		tagLen=bitand(tagHead,63);
		i=i+2;
		if tagLen==63
			tagLen=endian4*x(i:i+3);
			i=i+4;
		end
%		if tagID<length(SWF_tags)
%			tags(tagNr).tagName=SWF_tags{tagID+1};
%			tags(tagNr).tagType=SWF_ttypes(tagID+1);
%		else
%			tags(tagNr).tagName='onbekend';
%			tags(tagNr).tagType=0;
%		end
		if i+tagLen-1>length(x)
			fprintf('Doordat de file te kort is voor deze tag, wordt het lezen afgebroken.\n');
%			tagName=[tagName '-afgebroken'];
			tagID=0;
		end
		tags(tagNr).tagID=tagID;
		tags(tagNr).tagLen=tagLen;
		tagData=[];
		switch tagID
		case 0 % End
			leesFrame=0;	% einde frame
			leesFrames=0;	% einde movie
		case 1 % ShoweFrame
			leesFrame=0;
		case 2	% DefineShape
			tagData=leesDefineShape(x,i,1);
		case 4	% PlaceObject
			tagData=leesPlaceObject(x,i,tagLen);
		case 5	% RemoveObject
			tagData=struct('ID',endian2*x(i:i+1),'depth',endian2*x(i+2:i+3));
		case 6	% DefineBits
			tagData=struct('ID',endian2*x(i:i+1),'JPEG',uint8(x(i+2:i+tagLen-1)));
		case 7	% DefineButton
			tagData=leesDefineButton(x,i);
		case 8	% JPEGTabels
			tagData=uint8(x(i:i+tagLen-1));
		case 9	% backgroundColor block
			if tagLen~=3
				error('verkeerde lengte');
			end
			tagData=x(i:i+2)';
		case 10	% DefineFont
			tagData=leesFont(x,i);
		case 11	% DefineText
			tagData=leesText(x,i,1);
		case 12	% DoAction
			tagData=leesActions(x,i);
		case 13	% DefineFontInfo
			tagData=leesFontInfo(x,i,tagLen);
		case 14	% DefineSound
			tagData=leesDefineSound(x,i,tagLen);
		case 15	% StartSound
			ID=endian2*x(i:i+1);
			info=leesSoundInfo(x,i+2);
			tagData=struct('ID',ID,'info',info);
		case 17	% DefineButtonSound
			tagData=leesDefineButtonSound(x,i);
		case 18	% SoundStreamHead
			tagData=leesSoundStreamHead(x,i);
		case 19	% SoundStreamBlock
			tagData=uint8(x(i:i+tagLen));
		case 20	% DefineBitsLossLess
			tagData=leesBitsLossLess(x,i,tagLen,1);
		case 21	% DefineBitsJPEG2
			tagData=struct('ID',endian2*x(i:i+1),'JPEG',uint8(x(i+2:i+tagLen-1)));
		case 22	% DefineShape2 
			tagData=leesDefineShape(x,i,2);
		case 23	% DefineButtonCxform
			tagData=struct('ID',endian2*x(i:i+1),	...
				'buttonColorTransforms',leesCXForm(x,i+2));
		case 24	% Protect
			if tagLen
				warning('!password protected!')
				tagData=uint8(x(i:i+tagLen-1)');
			end
%			warning('Deze SWF is "protected"!')
		case 25	% PathsArePostScript
		case 26	% placeObject2
			tagData=leesPlaceObject2(x,i);
		case 28	% RemoveObject2
			tagData=struct('depth',endian2*x(i+2:i+3));
		case 32	% DefineShape3
			tagData=leesDefineShape(x,i,3);
		case 33 % DefineText2
			tagData=leesText(x,i,2);
		case 34 % DefineButton2
			tagData=leesDefineButton2(x,i,tagLen);
		case 35	% DefineBitsJPEG3
%			warning('!niet klaar : verwijderen van stream begin/end tags + alpha-data')
			tagData=struct('ID',endian2*x(i:i+1),	...
				'offset',endian4*x(i+2:i+5),	...
				'JPEG_end_im',x(i+6:i+tagLen-1));
		case 36	% DefineBitsLossLess2
			tagData=leesBitsLossLess(x,i,tagLen,2);
		case 37	% DefineEditText
			tagData=leesEditText(x,i);
		case 38	% DefineMovie
			tagData=struct('ID',endian2*x(i:i+1),'name',leesString(x,i+2));
		case 39	% leesSprite
			tagData=leesSprite(x,i,tagLen);
		case 41 % SerialNumber
			tagData=uint8(x(i:i+tagLen-1)');
		case 43	% FrameLabel
			tagData=leesString(x,i);
		case 45	% SoundStreamHead2
			tagData=leesSoundStreamHead(x,i);
		case 46	% DefineMorphShape
			tagData=leesDefineMorphShape(x,i);
		case 48	% DefineFont2
			tagData=leesFont2(x,i);
		case 56	% ExportAssets
			tagData=leesExportAssets(x,i);
		case 57	% ImportAssets
			tagData=leesImportAssets(x,i);
		case 58	% EnableDebugger
			tagData=leesString(x,i);	%%MD5-encrypted password
		case 1023 %DefineBitsPtr
%			tags(tagNr).tagName='DefineBitsPtr';
			tagData=endian4*x(i:i+3);
		otherwise
			if isempty(onbIDs)|~any(onbIDs==tagID)
				onbIDs(end+1)=tagID;
%				warning(sprintf('onbekende tagID %d (%s)',tagID,tagName))
				warning(sprintf('onbekende tagID %d',tagID))
			end
			tagData=uint8(x(i:i+tagLen-1));
		end
		tags(tagNr).tagData=tagData;
		i=i+tagLen;
	end	% lees tags
	frames{frameNr}=tags(1:tagNr);
end
uit.frames=frames;
if nargout>1
	X=x;
end

function sprite=leesSprite(x,i,len)
%global SWF_tags SWF_ttypes
endian4=[1 256 65536 16777216];
endian2=[1 256];
i_end=i+len;
ID=endian2*x(i:i+1);
frameCount=endian2*x(i+2:i+3);
i=i+4;
frames=cell(1,frameCount);
frameNr=0;
leesFrames=1;
sprite=struct('ID',ID,'frames',[]);
while leesFrames
	frameNr=frameNr+1;
	tags=struct('tagID',[],'tagLen',[],'tagData',cell(1,20));
	tagNr=0;
	leesFrame=1;
	while leesFrame
		if i>i_end
			error('Lezen van sprite in SWF-file onderbroken door overschrijden van sprite-blok.');
		end
		tagNr=tagNr+1;
		tagHead=endian2*x(i:i+1);
		tagID=bitshift(tagHead,-6);
		tagLen=bitand(tagHead,63);
		i=i+2;
		if tagLen==63
			tagLen=endian4*x(i:i+3);
			i=i+4;
		end
%		if tagID<length(SWF_tags)
%			tags(tagNr).tagName=SWF_tags{tagID+1};
%			tags(tagNr).tagType=SWF_ttypes(tagID+1);
%		else
%			tags(tagNr).tagName='onbekend';
%			tags(tagNr).tagType=0;
%		end
		tags(tagNr).tagID=tagID;
		tags(tagNr).tagLen=tagLen;
		switch tagID
		case 0 % End
			tagData=[];
			leesFrame=0;	% einde frame
			leesFrames=0;	% einde movie
		case 1 % ShoweFrame
			tagData=[];
			leesFrame=0;
		case 4	% PlaceObject
			tagData=leesPlaceObject(x,i,tagLen);
		case 5	% RemoveObject
			tagData=struct('ID',endian2*x(i:i+1),'depth',endian2*x(i+2:i+3));
		case 12	% DoAction
			tagData=leesActions(x,i);
		case 15	% StartSound
			ID=endian2*x(i:i+1);
			info=leesSoundInfo(x,i+2);
			tagData=struct('ID',ID,'info',info);
		case 18	% SoundStreamHead
			tagData=leesSoundStreamHead(x,i);
		case 26	% placeObject2
			tagData=leesPlaceObject2(x,i);
		case 28	% RemoveObject2
			tagData=struct('depth',endian2*x(i+2:i+3));
		case 43	% FrameLabel
			tagData=leesString(x,i);
		case 45	% SoundStreamHead2
			tagData=leesSoundStreamHead(x,i);
		otherwise
			error('onmogelijke tag in sprite');
		end
		tags(tagNr).tagData=tagData;	% niet direct een struct omdat bij
			% cell-data een structarray gemaakt wordt.
		i=i+tagLen;
	end	% lees tags
	frames{frameNr}=tags(1:tagNr);
end
sprite.frames=frames;

function assets=leesExportAssets(x,i)
endian2=[1 256];
n=endian2*x(i:i+1);
i=i+2;
assets=struct('tag',cell(n,1),'asset',cell(n,1));
for k=1:n
	assets(k).tag=endian2*x(i:i+1);
	[assets(k).asset,i]=leesString(x,i+2);
end

function asset=leesImportAssets(x,i)
endian2=[1 256];
[url,i]=leesString(x,i);
n=endian2*x(i:i+1);
i=i+2;
assets=struct('tag',cell(n,1),'asset',cell(n,1));
for k=1:n
	assets(k).tag=endian2*x(i:i+1);
	[assets(k).asset,i]=leesString(x,i+2);
end
asset=struct('url',url,'assets',assets);

function head=leesSoundStreamHead(x,i)
rates=[5.5 11 22 44];
playbackSoundRate=rates(bitand(x(i),12)/4+1);
playbackSoundSize=bitand(x(i),2);	% 0 : 8 bit, anders 16-bit
playbackSoundType=bitand(x(i),1);	% mono or Stereo (1)
i=i+1;
soundCompression=bitand(x(i),240)/16;	% always 1 (ADPCM) (bij type 1) (0 : no compress, 2 MP3)
soundRate=bitand(x(i),12)/4;	% always 0(?) : 5.5 kHz (bij type 1)
soundSize=bitand(x(i),2);	% always ~=0 : 16bit (bij type 1)
soundType=bitand(x(i),1);
nSamples=[1 256]*x(i+1:i+2);
if soundCompression~=1|soundRate~=0|soundSize==0
	fprintf('!SoundStreamHead heeft niet "oude standaardwaarden"!\n')
end
head=struct('playbackSoundRate',playbackSoundRate,'playbackSoundSize',playbackSoundSize	...
	,'playbackSoundType',playbackSoundType	...
	,'soundCompression',soundCompression	...
	,'soundRate',soundRate	...
	,'soundSize',soundSize	...
	,'soundType',soundType	...
	,'nSamples',nSamples	...
	);

function sound=leesDefineSound(x,i,len)
rates=[5.5 11 11 44];
formats={'NoCompress','ADPCM','MP3'};
ID=[1 256]*x(i:i+1);
i=i+2;
format=bitshift(x(i),-4);
rate=bitshift(bitand(x(i),12),-2);	% 5.5, 11, 22, 44K
size=bitand(x(i),2);	% 8bit or 16 bit
type=bitand(x(i),1);	% mono, stereo
nSamp=[1 256 65536 16777216]*x(i+1:i+4);
data=uint8(x(i+5:i+len-2));
sound=struct('ID',ID,'format',formats{format+1},'rate',rates(rate+1),'size',size,'nSamp',nSamp,'data',data);

function info=leesFontInfo(x,i,tagLen)
i_end=i+tagLen-1;	% in andere versies was dit zonder -1 ???
ID=[1 256]*x(i:i+1);
len=x(i+2);
name=char(x(i+3:i+2+len)');
i=i+3+len;
unicode=bitand(x(i),32);
shiftJIS=bitand(x(i),16);
ansi=bitand(x(i),8);
italic=bitand(x(i),4);
bold=bitand(x(i),2);
wideChars=bitand(x(i),1);
if wideChars
	nGlyphs=floor((i_end-i)/2);	% ???rommel tussen data waardoor nGlyphs niet juist (en kan eindigen in xxx.5) ???
	codes=[1 256]*reshape(x(i+1:i+2*nGlyphs),2,nGlyphs);
else
	nGlyphs=i_end-i;
	codes=x(i+1:i+nGlyphs)';
end
info=struct('ID',ID,'name',name,'unicode',unicode>0,'shiftJIS',shiftJIS>0,	...
	'ansi',ansi>0,'italic',italic>0,'bold',bold>0,'wideChars',wideChars,	...
	'codes',codes);

function text=leesEditText(x,i)
endian2=[1 256];
ID=endian2*x(i:i+1);
[bounds,i]=leesSWFRect(x,i+2);
hasText=bitand(x(i),128);
wordWrap=bitand(x(i),64);
multiline=bitand(x(i),32);
password=bitand(x(i),16);
readOnly=bitand(x(i),8);
hasTextColor=bitand(x(i),4);
hasMaxLength=bitand(x(i),2);
hasFont=bitand(x(i),1);
i=i+1;
% first 2 bits are reserved
hasLayout=bitand(x(i),32);
noSelect=bitand(x(i),16);
border=bitand(x(i),8);
% 2 reserved bits
useOutlines=bitand(x(i),1);
i=i+1;
text=struct('ID',ID,'bounds',bounds,'wordWrap',wordWrap,'multiline',multiline	...
	,'password',password,'readOnly',readOnly,'border',border);
if hasFont
	text.fontID=endian2*x(i:i+1);
	text.fontHeight=endian2*x(i+2:i+3);
	i=i+4;
end
if hasTextColor
	text.color=x(i:i+3)';
	i=i+4;
end
if hasMaxLength
	text.maxLength=endian2*x(i:i+1);
	i=i+2;
end
if hasLayout
	aligns={'left','right','center','justify'};
	text.align=aligns{x(i)+1};
	text.leftMargin=endian2*x(i+1:i+2);
	text.rightMargin=endian2*x(i+3:i+4);
	text.indent=endian2*x(i+5:i+6);
	text.leading=endian2*x(i+7:i+8);
	i=i+9;
end
[text.variableName,i]=leesString(x,i);
if hasText
	[text.initialText,i]=leesString(x,i);
end

function text=leesText(x,i,type)
ID=[1 256]*x(i:i+1);
[textBounds,i]=leesSWFRect(x,i+2);
[textMatrix,i]=leesMatrix(x,i);
nGlyphBits=x(i);
nAdvanceBits=x(i+1);
records=leesTextRecords(x,i+2,type,nGlyphBits,nAdvanceBits);
text=struct('ID',ID,'bounds',textBounds,'matrix',textMatrix,'records',records);

function [text,i]=leesTextRecords(x,i,type,nGlyphBits,nAdvanceBits)
endian2=[1 256];
text=struct('type',{},'data',{});
while x(i)
	recType=bitand(x(i),128);
	text(end+1).type=recType;
	if recType	% type 1
		hasFont=bitand(x(i),8);
		hasColor=bitand(x(i),4);
		hasYOffset=bitand(x(i),2);
		hasXOffset=bitand(x(i),1);
		data=[];
		i=i+1;
		if hasFont
			data.fontID=endian2*x(i:i+1);
			i=i+2;
		end
		if hasColor
			if type==1
				data.color=x(i:i+2)';
				i=i+3;
			else
				data.color=x(i:i+3)';
				i=i+4;
			end
		end
		if hasXOffset
			data.xOffset=endian2*x(i:i+1);
			if data.xOffset>32767
				data.xOffset=data.xOffset-65536;
			end
			i=i+2;
		end
		if hasYOffset
			data.yOffset=endian2*x(i:i+1);
			if data.yOffset>32767
				data.yOffset=data.yOffset-65536;
			end
			i=i+2;
		end
		if hasFont
			data.height=endian2*x(i:i+1);
			i=i+2;
		end
	else	% type0
		nGlyphs=bitand(x(i),127);
		i=i+1;
		j=0;
		data=zeros(nGlyphs,2);
		for k=1:nGlyphs
			[data(k,1),i,j]=leesUBij(x,i,j,nGlyphBits);
			[data(k,2),i,j]=leesUBij(x,i,j,nAdvanceBits);
		end
		if j
			i=i+1;
		end
	end
	text(end).data=data;
end

function sound=leesDefineButtonSound(x,i)
endian2=[1 256];
ID=endian2*x(i:i+1);
buttonSoundChar0=endian2*x(i+2:i+3);
[buttonSoundInfo0,i]=leesSoundInfo(x,i+4);
buttonSoundChar1=endian2*x(i:i+1);
[buttonSoundInfo1,i]=leesSoundInfo(x,i+2);
buttonSoundChar2=endian2*x(i:i+1);
[buttonSoundInfo2,i]=leesSoundInfo(x,i+2);
buttonSoundChar3=endian2*x(i:i+1);
[buttonSoundInfo3,i]=leesSoundInfo(x,i+2);
sound=struct('ID',ID,	...
	'soundChar0',buttonSoundChar0,'soundInfo0',buttonSoundInfo0,	...
	'soundChar1',buttonSoundChar1,'soundInfo1',buttonSoundInfo1,	...
	'soundChar2',buttonSoundChar2,'soundInfo2',buttonSoundInfo2,	...
	'soundChar3',buttonSoundChar3,'soundInfo3',buttonSoundInfo3	...
	);

function [info,i]=leesSoundInfo(x,i)
endian4=[1 256 65536 16777216];
endian2=[1 256];
if 0
	%!!!!!
	hasEnvelope=bitand(x(i),128);
	hasLoops=bitand(x(i),64);
	hasOutPoint=bitand(x(i),32);
	hasInPoint=bitand(x(i),16);
	syncFlags=bitand(x(i),15);
else
	syncFlags=bitshift(x(i),-4);	% 1 : syncNoMultiple, 2 : syncStop
	hasEnvelope=bitand(x(i),8);
	hasLoops=bitand(x(i),4);
	hasOutPoint=bitand(x(i),2);
	hasInPoint=bitand(x(i),1);
end
i=i+1;
info=[];
if hasInPoint
	info.inPoint=endian4*x(i:i+3);
	i=i+4;
end
if hasOutPoint
	info.outPoint=endian4*x(i:i+3);
	i=i+4;
end
if hasLoops
	info.loops=endian2*x(i:i+1);
	i=i+2;
end
if hasEnvelope
	nPoints=x(i);
	i=i+1;
	sndenv=zeros(nPoints,3);
	for k=1:nPoints
		sndenv(k,1)=endian4*x(i:i+3);
		sndenv(k,2)=endian2*x(i+4:i+5);
		sndenv(k,3)=endian2*x(i+6:i+7);
		i=i+8;
	end
	info.sndenv=sndenv;
end

function bitmap=leesBitsLossLess(x,i,len,type)
endian2=[1 256];
iend=i+len-1;
ID=endian2*x(i:i+1);
format=x(i+2);
width=endian2*x(i+3:i+4);
height=endian2*x(i+5:i+6);	%	... (ook colorTableSize afh van format)
i=i+7;
ncol=0;
if type==1
	bytesperkleur=3;
else
	bytesperkleur=4;
end
if format==3
	ncol=x(i)+1;
	i=i+1;
	nbyte=1;
elseif type==1
	nbyte=3;
else
	nbyte=4;
end
j=ncol*bytesperkleur;
try
	data=zuncompr(uint8(x(i:iend)),j+(width+3)*(height+3)*nbyte*2);	% "licht overdreven lengte..."
catch
%	warning(sprintf('Kon data niet decomprimeren!!! data werd vervangen door nullen!!\n',lasterr));
	warning('Kon data niet decomprimeren!!! data werd vervangen door nullen!!');
	data=zeros(width*height*nbyte+j,1);
end
colorTable=reshape(data(1:j),bytesperkleur,ncol)';
n=length(data)-j;
%fprintf('bitmap %dx%d (%d-%d) ',width,height,rem(width,4),rem(height,4));
if width*height*nbyte~=n
	if width*height*nbyte>n
		fprintf('de data is te klein!! - nullen worden toegevoegd (%d --> %d)\n',n,width*height*nbyte);
		data=[data(:);zeros(width*height*nbyte-n,1)];
	elseif width*height*(nbyte+1)==n
		if n~=3
			fprintf('???door aantal bytes/pixel te verhogen (%d -> %d) lukt het wel???\n',nbyte,nbyte+1)
		end
		nbyte=nbyte+1;
	elseif rem(n,height*nbyte)==0
%		if n/(height*nbyte)-width~=3-rem(width,4)  welke is juist???
		if n/(height*nbyte)-width~=4-rem(width,4)
			fprintf('het aantal kolommen wordt groter gemaakt (%d --> %d)\n',width,n/(height*nbyte))
		end
		width=n/(height*nbyte);
	elseif rem(n,width*nbyte)==0
		fprintf('het aantal lijnen wordt groter gemaakt (%d --> %d)\n',height,n/(width*nbyte))
		height=n/(width*nbyte);
	else
		fprintf('Vermits het aantal lijnen niet groter kon gemaakt worden door "niet afgeronde lengte", wordt de data ingekort. (%d  --> %d)\n',n,width*height*nbyte);
		n=width*height*nbyte;
	end
end
if nbyte==1
	bitmapTable=reshape(data(j+1:j+n),width,height)';
else
	bitmapTable=reshape(data(j+1:j+n),nbyte,width,height);
end

bitmap=struct('ID',ID,	...
	'format',format,	...
	'width',width,	...
	'height',height,	...
	'colorTable',colorTable,	...
	'bitmapTable',bitmapTable);

function button=leesDefineButton2(x,i,len)
i_end=i+len;
ID=[1 256]*x(i:i+1);
flags=x(i+2);
offset=[1 256]*x(i+3:i+4);
i_actions=i+3+offset;
[buttons,i]=leesButtonRecords2(x,i+5);
actions=struct('condition',{},'actions',{});
if offset
	if i_actions~=i
%		fprintf('(?teveel of teweinig buttons?   %d  <---->   %d          %d\n',i_actions,i,i-i_actions);
%		if i<i_actions
%			printhex(x(i:i_actions))
%		end
		if i>i_actions
			fprintf('??!!te veel buttons gelezen ? (i=%d,i_actions=%d,i_end=%d,offset=%d)\n',i,i_actions,i_end,offset);
		else	% i<i_actions
			fprintf('??!!te weinig buttons gelezen ? (i=%d,i_actions=%d,i_end=%d,offset=%d)\n',i,i_actions,i_end,offset);
		end	% i<i_actions
		i=i_actions;
	end	% i_actions~=i
elseif i>i_end
	fprintf('buttons gelezen tot over de grens van de tag\n')
elseif i<i_end
	fprintf('ongebruikte informatie na buttons?\n');
end
while offset
	% ??!! offset ook gebruiken??
	offset=[1 256]*x(i:i+1);
	condition=[1 256]*x(i+2:i+3);
	[actions1,i]=leesActions(x,i+4);
	actions(end+1)=struct('condition',condition,'actions',actions1);
end
button=struct('ID',ID,'flags',flags,'buttons',buttons,'actions',actions);

function button=leesDefineButton(x,i)
ID=[1 256]*x(i:i+1);
flags=x(i+2);
[buttons,i]=leesButtonRecords(x,i+3);
actions=leesActions(x,i);
button=struct('ID',ID,'buttons',buttons,'actions',actions);

function [buttons,i]=leesButtonRecords2(x,i)
endian2=[1 256];
buttons=struct('state',{},'character',{},'layer',{},'matrix',{},'cxForm',{});
if x(i)==0
	error('fout bij lezen van buttonrecords')
end
while x(i)
	[matrix,j]=leesMatrix(x,i+5);
	[colorTransform,j]=leesCXAForm(x,j);
	buttons(end+1)=struct('state',x(i),	...
		'character',endian2*x(i+1:i+2),	...
		'layer',endian2*x(i+3:i+4),	...
		'matrix',matrix,	...
		'cxForm',colorTransform	...
		);
	i=j;
end
i=i+1;

function [buttons,i]=leesButtonRecords(x,i)
endian2=[1 256];
buttons=struct('state',{},'character',{},'layer',{},'matrix',{});
if x(i)==0
	error('fout bij lezen van buttonrecords2')
end
while x(i)
	[matrix,j]=leesMatrix(x,i+5);
	buttons(end+1)=struct('state',x(i),	...
		'character',endian2*x(i+1:i+2),	...
		'layer',endian2*x(i+3:i+4),	...
		'matrix',matrix);
	i=j;
end
i=i+1;

function morph=leesDefineMorphShape(x,i)
ID=[1 256]*x(i:i+1);
[shapeBounds1,i]=leesSWFRect(x,i+2);
[shapeBounds2,i]=leesSWFRect(x,i);
offset=[1 256 65536 16777216]*x(i:i+3);
[morphFillStyles,i]=leesMorphFillStyles(x,i+4);
[morphLineStyles,i]=leesMorphLineStyles(x,i);
morph=struct('ID',ID,'bounds1',shapeBounds1,'bounds2',shapeBounds2	...
	,'offset',offset,'fillStyles',morphFillStyles,'linesStyles',morphLineStyles	...
	,'edges1',[],'edges2',[]);
[edges1,i]=leesShapes(x,i);
[edges2,i]=leesShapes(x,i);
morph.edges1=edges1;
morph.edges2=edges2;

function [fillStyles,i]=leesMorphFillStyles(x,i)
nFillStyles=x(i);
i=i+1;
if nFillStyles==255
	nFillStyles=[1 256]*x(i:i+1);
	i=i+2;
end
temp=cell(nFillStyles,1);
fillStyles=struct('fillStyleType',temp,'color1',temp,'color2',temp,	...
	'gradientMatrix1',temp,'gradientMatrix2',temp,	...
	'gradient',temp,'bitmapID',temp,'bitmapMatrix1',temp,'bitmapMatrix2',temp);
for j=1:nFillStyles
	[fillStyles(j),i]=leesMorphFillStyle(x,i);
end

function [fillStyle,i]=leesMorphFillStyle(x,i);
fillStyleType=x(i);
i=i+1;
color1=[];
color2=[];
gradientMatrix1=[];
gradientMatrix2=[];
gradient=[];
bitmapID=[];
bitmapMatrix1=[];
bitmapMatrix2=[];
if fillStyleType==0	% color
	color1=x(i:i+3)';
	color2=x(i+4:i+7)';
	i=i+8;
elseif bitand(fillStyleType,253)==16	% gradient
	[gradientMatrix1,i]=leesMatrix(x,i);
	[gradientMatrix2,i]=leesMatrix(x,i);
	[gradient,i]=leesMorphGradient(x,i);
elseif bitand(fillStyleType,254)==64
	bitmapID=[1 256]*x(i:i+1);
	[bitmapMatrix1,i]=leesMatrix(x,i+2);
	[bitmapMatrix2,i]=leesMatrix(x,i);
else
	error('onbekend fillStyleType')
end
fillStyle=struct('fillStyleType',fillStyleType,'color1',color1,'color2',color2,	...
	'gradientMatrix1',gradientMatrix1,'gradientMatrix2',gradientMatrix2,	...
	'gradient',gradient,	...
	'bitmapID',bitmapID,'bitmapMatrix1',bitmapMatrix1,'bitmapMatrix2',bitmapMatrix2);

function [gradient,i]=leesMorphGradient(x,i)
nGrads=x(i);
i=i+1;
if nGrads==0
	nGrads=1;
elseif nGrads>8
	error('aantal gradienten is niet tussen 1 en 8')
end
gradient=reshape(x(i:i-1+nGrads*10),10,nGrads)';
i=i+10*nGrads;

function [lineStyles,i]=leesMorphLineStyles(x,i);
nLineStyles=x(i);
i=i+1;
if nLineStyles==255
	nLineStyles=[1 256]*x(i:i+1);
	i=i+2;
end
lineStyles=struct('width',{},'color',{});
for j=1:nLineStyles
	[lineStyles(j),i]=leesMorphLineStyle(x,i);
end

function [lineStyle,i]=leesMorphLineStyle(x,i);
width=[1 256]*reshape(x(i:i+3),2,2);
color=reshape(x(i+4:i+11),4,2)';
i=i+12;
lineStyle=struct('width',width,'color',color);

function font=leesFont2(x,i)
global SHAPETYPE
SHAPETYPE=3;	%???
ID=[1 256]*x(i:i+1);
i=i+2;
% x(i+2) : reserved flags??????in andere spec niet
hasLayout=bitand(x(i),128);
shiftJIS=bitand(x(i),64);
unicode=bitand(x(i),32);
ansi=bitand(x(i),16);
wideOffsets=bitand(x(i),8);
wideChars=bitand(x(i),4);
italic=bitand(x(i),2);
bold=bitand(x(i),1);
i=i+2;	% reserved bits
len=x(i);
name=char(x(i+1:i+len)');
i=i+1+len;
nGlyphs=[1 256]*x(i:i+1);
if nGlyphs
	if wideOffsets
		offsets=[1 256 65536 16777216]*reshape(x(i+2:i+nGlyphs*4+1),4,nGlyphs);
		i=i+nGlyphs*4+2;
		codeOffset=[1 256 65536 16777216]*x(i:i+3);
		i=i+4;
	else
		offsets=[1 256]*reshape(x(i+2:i+nGlyphs*2+1),2,nGlyphs);
		i=i+nGlyphs*2+2;
		codeOffset=[1 256]*x(i:i+1);
		i=i+2;
	end
else
	offsets=[];
	codeOffset=[];
end
font=struct('ID',ID,'name',name,'offsets',[offsets codeOffset],'shapes',[],'codes',[]);
font.shapes=cell(nGlyphs,1);
for j=1:nGlyphs
	[font.shapes{j},i]=leesShapes(x,i);
end
if wideChars
	font.codes=[1 256]*reshape(x(i:i-1+2*nGlyphs),2,nGlyphs);
	i=i+2*nGlyphs;
else
	font.codes=x(i:i+nGlyphs-1);
	i=i+nGlyphs;
end
if hasLayout
	y=[1 256]*reshape(x(i:i+5+2*nGlyphs),2,3+nGlyphs);
	y=y-65536*(y>32767);
	i=i+6+2*nGlyphs;
	rects=zeros(nGlyphs,4);
	for k=1:nGlyphs
		[rects(k,:),i]=leesSWFRect(x,i);
	end
	nKernings=[1 256]*x(i:i+1);
	i=i+2;
	if wideChars
		z=reshape(x(i:i-1+nKernings*6),6,nKernings)';
		code1=z(:,1)+256*z(:,2);
		code2=z(:,3)+256*z(:,4);
		adjustment=z(:,5)+256*z(:,6);
	else
		z=reshape(x(i:i-1+nKernings*4),4,nKernings)';
		code1=z(:,1);
		code2=z(:,2);
		adjustment=z(:,3)+256*z(:,4);
	end
	adjustment=adjustment-65536*(adjustment>32767);
	font.layout=struct('ascent',y(1),'descent',y(2),'leading',y(3),	...
		'advances',y(4:end),'rects',rects,	...
		'code1',code1,'code2',code2,'adjustment',adjustment	...
		);
end

function font=leesFont(x,i)
global SHAPETYPE
SHAPETYPE=3;	%???
ID=[1 256]*x(i:i+1);
offset0=[1 256]*x(i+2:i+3);
nShapes=offset0/2;
offsets=[1 256]*reshape(x(i+4:i+nShapes*2+1),2,nShapes-1);
i=i+nShapes*2+2;
shapes=cell(nShapes,1);
font=struct('ID',ID,'offsets',[offset0 offsets],'shapes',[]);
for j=1:nShapes
	[shapes{j},i]=leesShapes(x,i);
end
font.shapes=shapes;

function [actions,i]=leesActions(x,i)
global onbActions SWF_actionIDs
actions=struct('ID',{},'data',{});
j=0;
while x(i)
	j=j+1;
	actions(j).ID=x(i);
	if x(i)>127
		len=[1 256]*x(i+1:i+2);
		i=i+3;
	else
		len=0;
		i=i+1;
	end
	if ~any(SWF_actionIDs==actions(j).ID)
		if isempty(onbActions)|all(actions(j).ID~=onbActions)
			fprintf('onbekende actie : %d (0x%02x)\n',actions(j).ID*[1 1])
			onbActions(end+1)=actions(j).ID;
		end
		actions(j).data=x(i:i+len-1);
	elseif actions(j).ID==66
%		actions(j).name='initArray_of_initObject';
		fprintf('!!!!fout in documentatie!!!!\n');
	end
	if len
		switch actions(j).ID
		case 129	% gotoFrame
			if len~=2
				error('gotoFrame-len moet 2 zijn');
			end
			actions(j).data=[1 256]*x(i:i+1);
		case 131	% getURL
			[url,k]=leesString(x,i);
			win=leesString(x,k);
			actions(j).data=struct('url',url,'win',win);
		case 136	% constantPool
			actions(j).data=leesString(x,i);
		case 138	% waitForFrame
			frame=[1 256]*x(i:i+1);
			skipCount=x(i+2);
			actions(j).data=struct('frame',frame,'skipCount',skipCount);
		case 139	% setTarget
			actions(j).data=leesString(x,i);
		case 140	% gotoLabel
			actions(j).data=leesString(x,i);
		case 141	% waitForFrame2
			actions(j).data=x(i);	% # actions to skip (if loaded)
		case 150	% push
			type=x(i);
			if type
				data=x(i+1:i+4);	%!!!!!!!float!!!!!
			else
				data=leesString(x,i+1);
			end
			actions(j).data=data;
		case 153	% jump
			data=[1 256]*x(i:i+1);
			if data>32767
				data=data-65536;
			end
			actions(j).data=data;
		case 154	% GetURL2
			switch x(i)
			case 0
				actions(j).data='none';
			case 1
				actions(j).data='GET';
			case 2
				actions(j).data='POST';
			case 64
				actions(j).data='LoadTarget';
			case 128
				actions(j).data='LoadVariables';
			case 192
				actions(j).data='LoadTarget_Variables';
			otherwise
				warning('???fout met GetURL2-action???');
				actions(j).data=x(i);
			end
		case 155	% defineFunction
			[name,k]=leesString(x,i);
			nPars=[1 256]*x(k:k+1);
			actions(j).data=struct('name',name,'pars',[],'code','');
			k=k+2;
			pars=cell(1,nPars);
			for l=1:nPars
				[pars{l},k]=leesString(x,k);
			end
			lCode=[1 256]*x(k:k+1);
			code=char(x(k+2:k+lCode+1)');
			actions(j).data.pars=pars;
			actions(j).data.code=code;
		case 157	% if
			data=[1 256]*x(i:i+1);
			if data>32767
				data=data-65536;
			end
			actions(j).data=data;
		case 158	% call
			actions(j).data=x(i:i+len-1);
		case 159	% gotoFrame2'
			actions(j).data=x(i);
		end
	end
	i=i+len;
end
i=i+1;

function [shapeDef,i]=leesDefineShape(x,i,type)
global SHAPETYPE
SHAPETYPE=type;
ID=[1 256]*x(i:i+1);
[shapeBounds,i]=leesSWFRect(x,i+2);
shape=leesShapeWStyle(x,i);
shapeDef=struct('ID',ID,'shapeBounds',shapeBounds,'shape',shape);

function [object,i]=leesPlaceObject2(x,i)
reservedFlags=bitshift(x(i),-6);
hasName=bitand(x(i),32);
hasRatio=bitand(x(i),16);
hasColorTransform=bitand(x(i),8);
hasMatrix=bitand(x(i),4);
hasCharacter=bitand(x(i),2);
move=bitand(x(i),1);
depth=[1 256]*x(i+1:i+2);
object=struct('depth',depth,'move',move);
i=i+3;
if hasCharacter
	ID=[1 256]*x(i:i+1);
	i=i+2;
	object.ID=ID;
end
if hasMatrix
	[matrix,i]=leesMatrix(x,i);
	object.matrix=matrix;
end
if hasColorTransform
	[colorTransform,i]=leesCXForm(x,i);
	object.colorTransform=colorTransform;
end
if hasRatio
	ratio=[1 256]*x(i:i+1);
	i=i+2;
	object.ratio=ratio;
end
if hasName
	[name,i]=leesString(x,i);
	object.name=name;
end

function [object,i]=leesPlaceObject(x,i,len)
i_end=i+len;
ID=[1 256]*x(i:i+1);
depth=[1 256]*x(i+2:i+3);
[matrix,i]=leesMatrix(x,i);
object=struct('ID',ID,'depth',depth,'matrix',matrix);
if i<i_end
	[cxForm,i]=leesCXForm(x,i);
	object.cxForm=cxForm;
end

function [shapes,i]=leesShapes(x,i)
nFillBits=bitshift(x(i),-4);
nLineBits=bitand(x(i),15);
i=i+1;
shapeRec=1;
shapes={};
j=0;
while ~isempty(shapeRec)
	[typeFlag,i,j]=leesUBij(x,i,j,1);
	if typeFlag	% type 2
		[edgeFlag,i,j]=leesUBij(x,i,j,1);
		[nBits,i,j]=leesUBij(x,i,j,4);
		nBits=nBits+2;
		if edgeFlag	% rechte lijn
			[lineFlag,i,j]=leesUBij(x,i,j,1);
			if lineFlag	% deltaX,deltaY
				[deltaX,i,j]=leesSBij(x,i,j,nBits);
				[deltaY,i,j]=leesSBij(x,i,j,nBits);
				shapeRec=struct('delta',[deltaX,deltaY]);
			else	% vertikaal of horizontaal
				[vertFlag,i,j]=leesUBij(x,i,j,1);
				[delta,i,j]=leesSBij(x,i,j,nBits);
				if vertFlag
					shapeRec=struct('deltaY',delta);
				else
					shapeRec=struct('deltaX',delta);
				end
			end	% vertikaal of horizontaal
		else	% bezier
			[controlDeltaX,i,j]=leesSBij(x,i,j,nBits);
			[controlDeltaY,i,j]=leesSBij(x,i,j,nBits);
			[anchorDeltaX,i,j]=leesSBij(x,i,j,nBits);
			[anchorDeltaY,i,j]=leesSBij(x,i,j,nBits);
			shapeRec=struct('delta',[controlDeltaX,controlDeltaY,anchorDeltaX,anchorDeltaY]);
		end
	else % type 0 or 1
		[newStyles,i,j]=leesUBij(x,i,j,1);
		[lineStyle,i,j]=leesUBij(x,i,j,1);
		[fillStyle0,i,j]=leesUBij(x,i,j,1);
		[fillStyle1,i,j]=leesUBij(x,i,j,1);
		[moveTo,i,j]=leesUBij(x,i,j,1);
		shapeRec=[];
		if moveTo
			[nMoveBits,i,j]=leesUBij(x,i,j,5);
			[moveDeltaX,i,j]=leesSBij(x,i,j,nMoveBits);
			[moveDeltaY,i,j]=leesSBij(x,i,j,nMoveBits);
			shapeRec.moveDelta=[moveDeltaX moveDeltaY];
		end
		if fillStyle0
			[fillStyle0,i,j]=leesUBij(x,i,j,nFillBits);
			shapeRec.fillStyle0=fillStyle0;
		end
		if fillStyle1
			[fillStyle1,i,j]=leesUBij(x,i,j,nFillBits);
			shapeRec.fillStyle1=fillStyle1;
		end
		if lineStyle
			[lineStyle,i,j]=leesUBij(x,i,j,nLineBits);
			shapeRec.lineStyle=lineStyle;
		end
		if newStyles
			if j
				i=i+1;
				j=0;
			end
			[newStyles,i]=leesFillStyles(x,i);
			shapeRec.newStyles=newStyles;
		end
	end	% type 0 or 1
	if ~isempty(shapeRec);
		shapes{end+1}=shapeRec;
	end
end	% all shapeRecords
if j
	i=i+1;
end

function [shape,i]=leesShapeWStyle(x,i)
[fillStyles,i]=leesFillStyles(x,i);
[lineStyles,i]=leesLineStyles(x,i);
[shapes,i]=leesShapes(x,i);

shape=struct('fillStyles',fillStyles,'lineStyles',lineStyles,'shapes',shapes);

function [fillStyles,i]=leesFillStyles(x,i)
nFillStyles=x(i);
i=i+1;
if nFillStyles==255
	nFillStyles=[1 256]*x(i:i+1);
	i=i+2;
end
temp=cell(nFillStyles,1);
fillStyles=struct('fillStyleType',temp,'color',temp,	...
	'gradientMatrix',temp,'gradient',temp,'bitmapID',temp,'bitmapMatrix',temp);
for j=1:nFillStyles
	[fillStyles(j),i]=leesFillStyle(x,i);
end

function [fillStyle,i]=leesFillStyle(x,i);
global SHAPETYPE
fillStyleType=x(i);
i=i+1;
color=[];
gradientMatrix=[];
gradient=[];
bitmapID=[];
bitmapMatrix=[];
if fillStyleType==0	% color
	if SHAPETYPE==3
		color=x(i:i+3)';
		i=i+4;
	else
		color=x(i:i+2)';
		i=i+3;
	end
elseif bitand(fillStyleType,253)==16	% gradient
	[gradientMatrix,i]=leesMatrix(x,i);
	[gradient,i]=leesGradient(x,i);
elseif bitand(fillStyleType,254)==64
	bitmapID=[1 256]*x(i:i+1);
	[bitmapMatrix,i]=leesMatrix(x,i+2);
else
	error('onbekend fillStyleType')
end
fillStyle=struct('fillStyleType',fillStyleType,'color',color,	...
	'gradientMatrix',gradientMatrix,'gradient',gradient,	...
	'bitmapID',bitmapID,'bitmapMatrix',bitmapMatrix);

function [gradient,i]=leesGradient(x,i)
global SHAPETYPE
nGrads=x(i);
i=i+1;
if nGrads==0
	nGrads=1;
elseif nGrads>8
	error('aantal gradienten is niet tussen 1 en 8')
end
if SHAPETYPE==1|SHAPETYPE==2
	gradient=reshape(x(i:i-1+nGrads*4),4,nGrads)';
	i=i+4*nGrads;
elseif SHAPETYPE==3
	gradient=reshape(x(i:i-1+nGrads*5),5,nGrads)';
	i=i+5*nGrads;
else
	error('onbekend shapetype voor gradient')
end
	
function [lineStyles,i]=leesLineStyles(x,i);
nLineStyles=x(i);
i=i+1;
if nLineStyles==255
	nLineStyles=[1 256]*x(i:i+1);
	i=i+2;
end
lineStyles=struct('width',{},'color',{});
for j=1:nLineStyles
	[lineStyles(j),i]=leesLineStyle(x,i);
end

function [lineStyle,i]=leesLineStyle(x,i);
global SHAPETYPE
width=[1 256]*x(i:i+1);
if SHAPETYPE==3
	color=x(i+2:i+5)';
	i=i+6;
else
	color=x(i+2:i+4)';
	i=i+5;
end
lineStyle=struct('width',width,'color',color);

function [lineStyle,i]=leesLineStyle3(x,i);
width=[1 256]*x(i:i+1);
color=x(i+2:i+5)';
i=i+6;
lineStyle=struct('width',width,'color',color);

function [r,i]=leesSWFRect(x,i)
nBit=bitshift(x(i),-3);
r=[0 0 0 0];
[r(1),i,j]=leesSBij(x,i,5,nBit);
[r(2),i,j]=leesSBij(x,i,j,nBit);
[r(3),i,j]=leesSBij(x,i,j,nBit);
[r(4),i,j]=leesSBij(x,i,j,nBit);
if j
	i=i+1;
end

function [a,i]=leesMatrix(x,i)
hasScale=x(i)>127;
if hasScale
	nScaleBits=leesUB(x(i),1,5);
	[scaleX,i,j]=leesFBij(x,i,6,nScaleBits);
	[scaleY,i,j]=leesFBij(x,i,j,nScaleBits);
	scale=[scaleX scaleY];
else
	scale=[];
	j=1;
end
[hasRotate,i,j]=leesUBij(x,i,j,1);
if hasRotate
	[nRotateBits,i,j]=leesUBij(x,i,j,5);
	[rotateSkew0,i,j]=leesFBij(x,i,j,nRotateBits);
	[rotateSkew1,i,j]=leesFBij(x,i,j,nRotateBits);
	rotation=[rotateSkew0 rotateSkew1];
else
	rotation=[];
end
[nTranslate,i,j]=leesUBij(x,i,j,5);
if nTranslate
	[translateX,i,j]=leesSBij(x,i,j,nTranslate);
	[translateY,i,j]=leesSBij(x,i,j,nTranslate);
else
	translateX=0;	% mogelijk ?
	translateY=0;
end
if j
	i=i+1;
end
a=struct('scale',scale,'rotate',rotation,'translate',[translateX translateY]);

function [cxf,i]=leesCXForm(x,i)
hasAddTerms=x(i)>127;
hasMultTerms=bitand(x(i),64);
nBits=leesUB(x(i),2,4);
cxf=[];
if hasMultTerms
	[redMultTerms,i,j]=leesSBij(x,i,6,nBits);
	[greenMultTerms,i,j]=leesSBij(x,i,j,nBits);
	[blueMultTerms,i,j]=leesSBij(x,i,j,nBits);
	cxf.mult=[redMultTerms greenMultTerms blueMultTerms];
else
	j=6;
end
if hasAddTerms
	[redAddTerms,i,j]=leesSBij(x,i,j,nBits);
	[greenAddTerms,i,j]=leesSBij(x,i,j,nBits);
	[blueAddTerms,i,j]=leesSBij(x,i,j,nBits);
	cxf.add=[redAddTerms greenAddTerms blueAddTerms];
end
if j
	i=i+1;
end

function [cxf,i]=leesCXAForm(x,i)
hasAddTerms=x(i)>127;
hasMultTerms=bitand(x(i),64);
nBits=leesUB(x(i),2,4);
cxf=[];
if hasMultTerms
	[redMultTerms,i,j]=leesSBij(x,i,6,nBits);
	[greenMultTerms,i,j]=leesSBij(x,i,j,nBits);
	[blueMultTerms,i,j]=leesSBij(x,i,j,nBits);
	[alphaMultTerms,i,j]=leesSBij(x,i,j,nBits);
	cxf.mult=[redMultTerms greenMultTerms blueMultTerms alphaMultTerms];
else
	j=6;
end
if hasAddTerms
	[redAddTerms,i,j]=leesSBij(x,i,j,nBits);
	[greenAddTerms,i,j]=leesSBij(x,i,j,nBits);
	[blueAddTerms,i,j]=leesSBij(x,i,j,nBits);
	[alphaAddTerms,i,j]=leesSBij(x,i,j,nBits);
	cxf.mult=[redAddTerms greenAddTerms blueAddTerms alphaAddTerms];
end
if j
	i=i+1;
end

function a=maaksigned(x,n)
a=x-(x>=2^(n-1))*2^n;

function a=leesSB(x,b0,N)
if N==0
	%warning('Kan SB0 ?')	% blijkbaar wel
	a=0;
	return
end
n=N;
if 8-b0>=n
	a=bitand(2^n-1,bitshift(x(1),b0+n-8));
else
	a=bitand(2^(8-b0)-1,x(1));
	n=n-8+b0;
	i=2;
	while n
		if n<=8
			a=bitshift(a,n)+bitshift(x(i),n-8);
			n=0;
		else
			a=bitshift(a,8)+x(i);
			n=n-8;
			i=i+1;
		end
	end
end
if bitand(a,2^(N-1))
	a=a-2^N;
end

function [a,i,j]=leesSBij(x,i,j,n)
a=leesSB(x(i:min(end,i+4)),j,n);
j=j+n;
i=i+bitshift(j,-3);
j=bitand(j,7);


function [a,i,j]=leesUBij(x,i,j,n)
a=leesUB(x(i:min(end,i+4)),j,n);
j=j+n;
i=i+bitshift(j,-3);
j=bitand(j,7);

function [a,i,j]=leesFBij(x,i,j,n)
a=leesFB(x(i:min(end,i+4)),j,n);
j=j+n;
i=i+bitshift(j,-3);
j=bitand(j,7);

function a=leesUB(x,b0,N)
n=N;
if 8-b0>=n
	a=bitand(2^n-1,bitshift(x(1),b0+n-8));
else
	a=bitand(2^(8-b0)-1,x(1));
	n=n-8+b0;
	i=2;
	while n
		if n<=8
			a=bitshift(a,n)+bitshift(x(i),n-8);
			n=0;
		else
			a=bitshift(a,8)+x(i);
			n=n-8;
			i=i+1;
		end
	end
end

function a=leesFB(x,b0,N)
n=N;
if 8-b0>=n
	a=bitand(2^n-1,bitshift(x(1),b0+n-8));
else
	a=bitand(2^(8-b0)-1,x(1));
	n=n-8+b0;
	i=2;
	while n
		if n<=8
			a=bitshift(a,n)+bitshift(x(i),n-8);
			n=0;
		else
			a=bitshift(a,8)+x(i);
			n=n-8;
			i=i+1;
		end
	end
end
%!!!! nog delen door ????

function [s,i]=leesString(x,i)
j=i;
while x(j);j=j+1;end
s=char(x(i:j-1)');
i=j+1;

