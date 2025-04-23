function [Ximg,Xinfo,x]=ReadFFF(fName,varargin)
%ReadFFF  - Read file of type FFF (raw image file format)
%     Ximg=ReadFFF(fName);

% see: file:///C:/Users/stijn.helsen/Documents/temp/exiftool/html/TagNames/FLIR.html#FFF

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!! be carefull with long logs !!!!!!!!

f = file(fFullPath(fName,0,'fff'));
x = f.fread([1 Inf],'*uint8');
f.fclose();

Xjpg = [];
if strcmp(char(x(1:3)),'FFF')
	% OK, normal FFF-file
elseif x(1)==255&&x(2)==216	% JPEG
	Xjpg = imread(fFullPath(fName));
	cJPG = cjpeg(x);
	B = getblock(cJPG);
	B_FFF = false(1,length(B));
	C_FFF = cell(1,length(B));
	for i=1:length(B)
		if strcmp(B(i).markerName,'APP_1')&&strcmp(char(B(i).data(1:4)),'FLIR')
			B_FFF(i) = true;
			C_FFF{i} = uint8(B(i).data(9:end));
		end
	end
	if any(B_FFF)
		x = [C_FFF{B_FFF}];
	else
		error('Sorry, no FFF-data found in JPEG-file?!')
	end
else
	error('Sorry, wrong format!')
end

[Ximg,FFF] = ReadFFFdata(x,varargin{:});

if nargout>1
	if isempty(Xjpg)
		Xinfo = FFF;
	else
		Xinfo=struct('jpg',Xjpg,'FFF',FFF);
	end
end

function T_C = Convert2Temp(X, Dir)
% convert raw values from the flir sensor to temperatures in °C
% this calculation has been ported to python from https://github.com/gtatters/Thermimage/blob/master/R/raw2temp.R
% a detailed explanation of what is going on here can be found there

% constants
%ATA1=0.006569; ATA2=0.01262; ATB1=-0.002276; ATB2=-0.00667; ATX=1.9; %RH=0
% transmission through window (calibrated)
emiss_wind = 1 - Dir.IRT;
refl_wind = 0;
% transmission through the air
h2o = (Dir.RH)*exp(1.5587+0.06939*(Dir.atmosT-273.15)-0.00027816*(Dir.atmosT-273.15)^2+0.00000068455*(Dir.atmosT-273.15)^3);
tau1 = Dir.ATX*exp(-sqrt(Dir.objDist/2)*(Dir.ATA1+Dir.ATB1*sqrt(h2o)))+(1-Dir.ATX)*exp(-sqrt(Dir.objDist/2)*(Dir.ATA2+Dir.ATB2*sqrt(h2o)));
tau2 = Dir.ATX*exp(-sqrt(Dir.objDist/2)*(Dir.ATA1+Dir.ATB1*sqrt(h2o)))+(1-Dir.ATX)*exp(-sqrt(Dir.objDist/2)*(Dir.ATA2+Dir.ATB2*sqrt(h2o))) ;       
% radiance from the environment
raw_refl1 = Dir.PlanckR1/(Dir.PlanckR2*(exp(Dir.PlanckB/Dir.reflAppT)-Dir.PlanckF))-Dir.PlanckO;
raw_refl1_attn = (1-Dir.emiss)/Dir.emiss*raw_refl1; % Reflected component

raw_atm1 = Dir.PlanckR1/(Dir.PlanckR2*(exp(Dir.PlanckB/Dir.atmosT)-Dir.PlanckF))-Dir.PlanckO; % Emission from atmosphere 1
raw_atm1_attn = (1-tau1)/Dir.emiss/tau1*raw_atm1; % attenuation for atmospheric 1 emission

raw_wind = Dir.PlanckR1/(Dir.PlanckR2*(exp(Dir.PlanckB/Dir.IRwinT)-Dir.PlanckF))-Dir.PlanckO; % Emission from window due to its own temp
raw_wind_attn = emiss_wind/Dir.emiss/tau1/Dir.IRT*raw_wind; % Componen due to window emissivity

raw_refl2 = Dir.PlanckR1/(Dir.PlanckR2*(exp(Dir.PlanckB/Dir.reflAppT)-Dir.PlanckF))-Dir.PlanckO; % Reflection from window due to external objects
raw_refl2_attn = refl_wind/Dir.emiss/tau1/Dir.IRT*raw_refl2; % component due to window reflectivity

raw_atm2 = Dir.PlanckR1/(Dir.PlanckR2*(exp(Dir.PlanckB/Dir.atmosT)-Dir.PlanckF))-Dir.PlanckO; % Emission from atmosphere 2
raw_atm2_attn = (1-tau2)/Dir.emiss/tau1/Dir.IRT/tau2*raw_atm2; % attenuation for atmospheric 2 emission

raw_obj = (double(X)/Dir.emiss/tau1/Dir.IRT/tau2-raw_atm1_attn-raw_atm2_attn-raw_wind_attn-raw_refl1_attn-raw_refl2_attn);
val_to_log = Dir.PlanckR1./(Dir.PlanckR2*(raw_obj+Dir.PlanckO))+Dir.PlanckF;
if any(val_to_log(:)<0)
	warning('Image seems to be corrupted')
	val_to_log = max(1e-5,val_to_log);
end
% temperature from radiance
T_C = Dir.PlanckB./log(val_to_log)-273.15;

function [IR,FFF] = ReadFFFdata(x,varargin)
[bBigendian] = false;	%(!!!!!!)
[bMulti] = true;
[fRange] = [];
[bKeepRaw] = false;

if nargin>1
	setoptions({'bBigEndian','bMulti','fRange','bKeepRaw'},varargin{:})
end

H = x(1:64);
N1 = typecast(x(17:60),'uint32');
if bBigendian
	N1 = swapbytes(N1);
end
nEntries = N1(4);	%?!!!!
ix = 64;
E = reshape(x(ix+1:ix+32*nEntries),32,nEntries);
TYP = typecast(reshape(E(1:2,:),1,nEntries*2),'uint16');
II = reshape(typecast(reshape(E(13:20,:),1,nEntries*4*2),'uint32'),2,nEntries);
if bBigendian
	II = swapbytes(II);
	TYP = swapbytes(TYP);
end
START = II(1,:);
LEN = II(2,:);
FFF = struct();
for iEntry=1:nEntries
	x1 = x(START(iEntry)+1:START(iEntry)+LEN(iEntry));
	switch TYP(iEntry)
		case 0
			if any(TYP(iEntry+1:end)>0)
				warning('Data after NULL-data?!')
			end
			break
		case 1	% RawData
			FFF.raw = GetRawData(x1);
		case 5	% GainDeadData
			FFF.GainDeadData = x1;
		case 6	% CoarseData
			FFF.CoarseData = x1;
		case 14	% EmbeddedImage
			FFF.EmbeddedImage = x1;
		case 32	% CameraInfo
			FFF.CameraInfo = GetCameraInfo(x1);
		case 33	% MeasurementInfo
			FFF.MeasurementInfo = x1;
		case 34	% PaletteInfo
			FFF.Palette = GetPalette(x1);
		case 35	% TextInfo
			FFF.TextInfo = x1;
		case 36	% EmbeddedAudioFile
			FFF.EmbeddedAudioFile = x1;
		case 40	% PaintData
			FFF.PaintData = x1;
		case 42	% PiP
			FFF.PiP = x1;
		case 43	% GPSInfo
			FFF.GPSInfo = x1;
		case 44	% MeterLink
			FFF.MeterLink = x1;
		case 50	% ParameterInfo
			FFF.ParameterInfo = x1;
		otherwise
			warning('Unkown header FFF-data?! (%d - 0x%04x)',TYP(iEntry),TYP(iEntry))
	end
end
if bMulti
	len0 = START(iEntry)+LEN(iEntry);
	ix = len0;
	nFrames = length(x)/double(ix);	% (!) approximate number of frames(!!)
	if nFrames>=2
		nFrames = floor(nFrames);
		FFF(nFrames) = FFF;
		iFFF = 1;
		while length(x)-ix>len0-100		%(!!)
			iFFF = iFFF+1;
			%!!!!! copy of previous code!!!!!
			N1 = typecast(x(ix+17:ix+60),'uint32');
			if bBigendian
				N1 = swapbytes(N1);
			end
			nEntries = N1(4);	%?!!!!
			E = reshape(x(ix+65:ix+64+32*nEntries),32,nEntries);
			TYP = typecast(reshape(E(1:2,:),1,nEntries*2),'uint16');
			II = reshape(typecast(reshape(E(13:20,:),1,nEntries*4*2),'uint32'),2,nEntries);
			if bBigendian
				II = swapbytes(II);
				TYP = swapbytes(TYP);
			end
			START = II(1,:);
			LEN = II(2,:);
			for iEntry=1:nEntries
				x1 = x(ix+START(iEntry)+1:ix+START(iEntry)+LEN(iEntry));
				switch TYP(iEntry)
					case 0
						if any(TYP(iEntry+1:end)>0)
							warning('Data after NULL-data?!')
						end
						break
					case 1	% RawData
						FFF(iFFF).raw = GetRawData(x1);
					case 5	% GainDeadData
						FFF(iFFF).GainDeadData = x1;
					case 6	% CoarseData
						FFF(iFFF).CoarseData = x1;
					case 14	% EmbeddedImage
						FFF(iFFF).EmbeddedImage = x1;
					case 32	% CameraInfo
						FFF(iFFF).CameraInfo = GetCameraInfo(x1);
					case 33	% MeasurementInfo
						FFF(iFFF).MeasurementInfo = x1;
					case 34	% PaletteInfo
						FFF(iFFF).Palette = GetPalette(x1);
					case 35	% TextInfo
						FFF(iFFF).TextInfo = x1;
					case 36	% EmbeddedAudioFile
						FFF(iFFF).EmbeddedAudioFile = x1;
					case 40	% PaintData
						FFF(iFFF).PaintData = x1;
					case 42	% PiP
						FFF(iFFF).PiP = x1;
					case 43	% GPSInfo
						FFF(iFFF).GPSInfo = x1;
					case 44	% MeterLink
						FFF(iFFF).MeterLink = x1;
					case 50	% ParameterInfo
						FFF(iFFF).ParameterInfo = x1;
					otherwise
						warning('Unkown header FFF-data?! (%d - 0x%04x)',TYP(iEntry),TYP(iEntry))
				end		% switch TYP
			end		% for iEntry
			len0 = START(iEntry)+LEN(iEntry);
			ix = ix+len0;
		end		% while data in x
	end		% more than 1 frame
end		% if bMulti
if bMulti
	IR = Convert2Temp(cat(3,FFF.raw),FFF(1).CameraInfo);	% !!!!!!!! only first CameraInfo?!!!!!!
else
	IR = Convert2Temp(FFF.raw,FFF.CameraInfo);
end
if ~bKeepRaw
	FFF = rmfield(FFF,'raw');
end

function RAW = GetRawData(x)
I = typecast(x,'uint16');
W = I(2);
H = I(3);
if I(1)~=2
	warning('Is the number of bytes per pixel ~= 2? (%d)',I(1))
end
RAW = reshape(I(17:end),W,H)';

function PAL = GetPalette(x)
nColPal = typecast(x(1:4),'uint32');	% expecting 224 colours
COLs1 = reshape(x(7:24),3,6)';
aboveColour = COLs1(1,:);
belowColour = COLs1(2,:);
ovfColour = COLs1(3,:);
unfColour = COLs1(4,:);
iso1Colour = COLs1(5,:);
iso2Colour = COLs1(6,:);
palFilename = char(nonzeros(x(49:80)))';
palName = char(nonzeros(x(81:112)))';
palette = reshape(x(113:112+3*nColPal),3,nColPal)';
PAL = var2struct(aboveColour,belowColour,ovfColour,unfColour,iso1Colour		...
	,iso2Colour,palFilename,palName,palette);

function CAM = GetCameraInfo(x)
F1 = typecast(x(33:64),'single');
F2 = typecast(x(89:176),'single');
CAM = struct();
CAM.emiss			= F1( 1);
CAM.objDist			= F1( 2);
CAM.reflAppT		= F1( 3);
CAM.atmosT			= F1( 4);
CAM.IRwinT			= F1( 5);
CAM.IRT				= F1( 6);
CAM.RH				= F1( 8);
CAM.PlanckR1		= F2( 1);
CAM.PlanckB			= F2( 2);
CAM.PlanckF			= F2( 3);
CAM.ATA1			= F2( 7);
CAM.ATA2			= F2( 8);
CAM.ATB1			= F2( 9);
CAM.ATB2			= F2(10);
CAM.ATX				= F2(11);
CAM.CamTRmx			= F2(15);
CAM.CamTRmn			= F2(16);
CAM.CamTCmx			= F2(17);
CAM.CamTCmn			= F2(18);
CAM.CamTWmx			= F2(19);
CAM.CamTWmn			= F2(20);
CAM.CamTSmx			= F2(21);
CAM.CamTSmn			= F2(22);
CAM.CamModel		= GetString(x,212);
CAM.CamPartNr		= GetString(x,244);
CAM.CamSerialNr		= GetString(x,260);
CAM.CamSW			= GetString(x,276);
CAM.LensModel		= GetString(x,368);
CAM.LensPartNr		= GetString(x,400);
CAM.LensSerialNr	= GetString(x,416);
CAM.FOV				= GetFloat(x,436);
CAM.FilterModel		= GetString(x,492);
CAM.FilterPartNr	= GetString(x,508);
CAM.FilterSerialNr	= GetString(x,540);
CAM.PlanckO			= single(GetInt16(x,776));
CAM.PlanckR2		= GetFloat(x,780);
CAM.RawValRmin		= GetUint16(x,784);
CAM.RawValRmax		= GetUint16(x,786);
CAM.RawValRmedian	= GetUint16(x,824);
CAM.RawValRange		= GetUint16(x,828);
CAM.DateTimeOrig	= GetTime(x,900);
CAM.FocusStepCnt	= GetUint16(x,912);
CAM.FocusDist		= GetFloat(x,1116);
CAM.FrameRate		= GetUint16(x,1124);


function s = GetString(x,i0)
i = i0+1;
while i<=length(x)&&x(i)
	i = i+1;
end
s = char(x(i0+1:i-1));

function v = GetFloat(x,i0)
v = typecast(x(i0+1:i0+4),'single');

function i = GetInt16(x,i0)
i = typecast(x(i0+1:i0+2),'int16');

function i = GetUint16(x,i0)
i = typecast(x(i0+1:i0+2),'uint16');

function i = GetUint32(x,i0)
i = typecast(x(i0+1:i0+4),'uint32');

function t = GetTime(x,i0)
tS = typecast(x(i0+1:i0+4),'uint32');
tMS = typecast(x(i0+5:i0+6),'uint16');
t = double(tS)+double(tMS)/1000;
