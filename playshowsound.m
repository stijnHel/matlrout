function playshowsound(y,Fs,varargin)
%playshowsound - Plays a sound, and displays data while playing - audioplayer version
%    playshowsound(y,Fs[,options])
%
%     options : (pairs of option-name and option-data)
%        - B : spectrogram (real data), if not given calculated
%        - T,F : time and frequency belonging to spectrogram
%        - bShowTime : show signal in time domain
%        - bShowSpec : show spectrogram (frequency domain)
%        - bTimeHor : show time on horizontal axis (otherwise vertical)
%        - bRevXdir : reverse direction of time axis
%
%    Additional use:
%        playshowsound - starts sound (with an already made window)
%        playshowsound(Tstart) - Starts sound from t=Tstart
%        playshowsound([Tstart Tend]) - Plays sound between Tstart and Tend
%
%    This action can be added to existing axes.  This can be done as follows:
%       playshowsound(<axes>,D[,option])
%          with D : structure with
%                 y(or x) : signal
%                 Fs : sampling frequency
B = [];
T = [];
F = [];
[bShowTime] = true;
[bShowSpec] = true;
[bTimeHor] = true;
[bRevXdir] = false;
Tstart = 0;
[bPlay] = false;
[bExtMenu] = true;
[bFollowGraph] = true;
sPlayLabel = 'Play sound';
% specgram data
nFFT = 256;
window = [];
nOverlap = [];
fMax = [];
fMin = [];

if nargin<2||ischar(y)
	bUpdate = false;
	f = findobj('Tag','playshowsound');
	if nargin&&ischar(y)
		switch y
			case 'demo'
				D = load('handel');
				playshowsound(D.y,D.Fs)
				return
			case 'update'
				newX = Fs;
				if nargin>2
					newFs = varargin{1};
				else
					newFs = [];
				end
				bPlay = false;
				bUpdate = true;
			case 'remove'
				h = findobj(gcf,'Tag','playshowremove');
				RemovePlay(h)
				return
			otherwise
				error('Unknown use of this function')
		end
	end
	if isempty(f)
		audio = [];
	else
		audio = getappdata(f,'playshowtimer');
		D = get(audio,'UserData');
	end
	if bUpdate
		setappdata(D.pointers(1),'sound',newX)	% does this work?
		if ~isempty(newFs)
			D.Fs = newFs;
		end
		set(audio,'UserData',D)
	end
	if bPlay
		if nargin==0
			StartSound(f);
		else
			StartSound(f,[],y);
		end
	end
	return
end

if isempty(varargin)
	opties = {};
elseif length(varargin)==1
	opties = varargin{1};
else
	opties = varargin;
end
if ~isempty(opties)
	setoptions({'B','bShowTime','bShowSpec','bTimeHor','bRevXdir'	...
		,'Tstart','bPlay','bExtMenu','sPlayLabel','bFollowGraph'	...
		,'nFFT','window','nOverlap','fMax','fMin'	...
		},opties{:})
end

if bTimeHor
	tAx = 'XData';
else
	tAx = 'YData';
end
if length(y)<=10	%!!!max 10 axes linked, time signal minimal 11 datapoints
	ax = y;
	if isfield(Fs,'y')
		y = Fs.y;
	elseif isfield(Fs,'x')
		y = Fs.x;
	else
		error('Wrong use of playshowsound(<axes>,D) - x or y should be in D')
	end
	Fs = Fs.Fs;
	Tend = (length(y)-1)/Fs;
	f = get(ax(1),'Parent');
	audio = getappdata(f,'playshowtimer');
else
	t = (0:length(y)-1)/Fs;
	Tend=t(end);
	if bShowSpec
		if isempty(B)
			[B,F,T]=specgram(y,nFFT,Fs,window,nOverlap);
			B=log(abs(B));
			if ~isempty(fMin)
				B = B(F>=fMin,:);
				F = F(F>=fMin);
			end
			if ~isempty(fMax)
				B = B(F<=fMax,:);
				F = F(F<=fMax);
			end
		else
			if isempty(F)
				F=(0:size(B,1)-1)/(size(B,1)*2-1)*Fs;
			end
			if isempty(T)
				DT=Tend/(size(B,2)-1);
				T=(0.5:size(B,2)-0.5)*DT;
			end
		end
	end
	nGraph=bShowTime+bShowSpec;
	[f,bNew]=getmakefig('playshowsound');
	if bNew
		set(f,'menubar','none')
		audio = [];
		navfig
	else
		delete(findobj(f,'Type','axes'))
		audio = getappdata(f,'playshowtimer');
	end
	if nGraph==0
		error('Nothing to draw!')
	elseif nGraph==1
		ax=axes;
	elseif bTimeHor
		ax=[subplot('211') subplot('212')];
	else	% ~bTimeHor
		ax=[subplot('121') subplot('122')];
	end

	l = zeros(1,nGraph);
	if bShowTime
		if bTimeHor
			plot(t,y,'parent',ax(1))
		else
			plot(y,t,'parent',ax(1))
		end
		grid(ax(1),'on')
		set(ax(1),'Tag','signal')
		if bNew
			navfig('addkey','q',0,@FreqAnal)
			navfig('addkey','C',0,@ClearBlocks)
			navfig('addkey','0',0,@(f) SelectBox(f,0))
			navfig('addkey','1',0,@(f) SelectBox(f,1))
			navfig('addkey','2',0,@(f) SelectBox(f,2))
			navfig('addkey','3',0,@(f) SelectBox(f,3))
			navfig('addkey','4',0,@(f) SelectBox(f,4))
			navfig('addkey','5',0,@(f) SelectBox(f,5))
			navfig('addkey','6',0,@(f) SelectBox(f,6))
			navfig('addkey','7',0,@(f) SelectBox(f,7))
			navfig('addkey','8',0,@(f) SelectBox(f,8))
			navfig('addkey','9',0,@(f) SelectBox(f,9))
			navfig('addkey','+',0,@(f) SelectBox(f,[]))
			navfig('addkey','p',0,@(f) StartSound(f,[],-2))
		end
	end
	if bShowSpec
		if bTimeHor
			imagesc(T,F,B,'parent',ax(end))
		else
			imagesc(F,T,B','parent',ax(end))
		end
		grid(ax(end),'on')
		axis(ax(end),'xy')
		set(ax(end),'Tag','spectrum')
	end
	set(ax,[tAx(1) 'Lim'],t([1 end]))
end
if ~isempty(audio)	% can't it be reused?
	delete(audio)
	audio = [];
end
if isempty(audio)
	audio = audioplayer(y,Fs);
	audio.TimerFcn = @ExecTimer;
	audio.Tag = 'ShowSoundAudio';
	audio.StopFcn = @AudioStopped;
end
if isempty(findobj(f,'Tag','playshowsoundmenu'))
	hm=uimenu(f,'Label','Sound','Tag','playshowsoundmenu');
	if bExtMenu
		uimenu(hm,'Label','Play all','Callback',{@StartSound -1})
		uimenu(hm,'Label','Play again','Callback',@StartSound)
		uimenu(hm,'Label','Play part','Callback',{@StartSound,-2})
    	uimenu(hm,'Label','Stop sound','Callback',@StopSound)
    	uimenu(hm,'Label','Remove play options','Callback',@RemovePlay	...
        	,'Tag','playshowremove','Separator','on')
	else
		uimenu(hm,'Label',sPlayLabel,'Callback',{@StartSound -1})
	end
end
for i=1:length(ax)
	if bTimeHor
		l(i)=line([0 0],get(ax(i),'ylim'),'Parent',ax(i)	...
			,'Tag','soundHorPointer','Visible','off');
	else
		l(i)=line(get(ax(i),'xlim'),[0 0],'Parent',ax(i)	...
			,'Tag','soundVerPointer','Visible','off');
	end
end
if bRevXdir
	set(ax,[tAx(1) 'Dir'],'reverse')
end
D=struct('f',f,'Fs',Fs,'audio',audio,'pointers',l,'tAx',tAx	...
	,'Tstart',Tstart,'Tend',Tend,'t0',0,'bFollowGraph',bFollowGraph		...
	,'fMin',fMin,'fMax',fMax);
setappdata(l(1),'sound',y)
setappdata(l(1),'audio',audio)
set(l(1),'DeleteFcn',@DeleteTimer)
set(audio,'UserData',D)
setappdata(f,'playshowtimer',audio)

if bPlay
	StartSound(f)
end

function ExecTimer(audio,~)
i = audio.CurrentSample;
if i>1
	D=get(audio,'UserData');
	tt=i/audio.SampleRate;
	set(D.pointers,D.tAx,[tt tt])
	if D.bFollowGraph && strcmp(D.tAx,'XData')
		xl = get(ancestor(D.pointers(1),'axes'),'XLim');
		if tt<xl(1) || tt>xl(2)
			ca = get(D.pointers,'Parent');
			ax = [ca{:}];
			set(ax,'XLim',tt+[0 xl(2)-xl(1)])
		end
	end
	drawnow
end

function DeleteTimer(l,~)
audio=getappdata(l,'timer');
if ~isempty(audio)
	delete(audio)
end

function [Tstart,Tend,iBox] = GetSelectedPart(f)
iBox = getappdata(f,'CurrentSelectedBox');
if isempty(iBox)
	xl = xlim;
	Tstart = xl(1);
	Tend = xl(2);
else
	Boxes = getappdata(f,'Boxes');
	Tstart = Boxes(iBox).xMin;	%!!!!! what if non-XData-type?!!!!!
	Tend = Boxes(iBox).xMax;
	iBox = Boxes(iBox).nr;
end

function StartSound(h,~,in,varargin)
f = ancestor(h,'figure');
audio = getappdata(f,'playshowtimer');
if isempty(audio)
	error('For this window no player is installed')
end
if audio.isplaying()
	disp('this is already running - can''t do it double!')
	return
end
D = get(audio,'UserData');
for i=1:length(D.pointers)
	ax = ancestor(D.pointers(i),'axes');
	if strcmp(D.tAx,'XData')
		xl = get(ax,'YLim');
		set(D.pointers(i),'YData',xl)
	else
		xl = get(ax,'XLim');
		set(D.pointers(i),'XData',xl)
	end
end
set(D.pointers,'Visible','on')

if nargin>2
	y = getappdata(D.pointers(1),'sound');
	Tend = (length(y)-1)/D.Fs;
	if length(in)==1
		if in==-1
			Tstart = 0;
		elseif in==-2
			[Tstart,Tend] = GetSelectedPart(get(ax,'Parent'));
		elseif in==-3
			nr = varargin{1};
			Boxes = getappdata(f,'Boxes');
			iBox = find([Boxes.nr]==nr);
			if isempty(iBox)
				error('Box not found?!')
			end
			Tstart = Boxes(iBox).xMin;	%!!!!! what if non-XData-type?!!!!!
			Tend = Boxes(iBox).xMax;
		else
			Tstart = in;
		end
	elseif length(in)==2
		Tstart = in(1);
		Tend = in(2);
	else
		error('Wrong use of this function')
	end
	Tstart=max(0,Tstart);
	Tend=min(Tend,length(y)*D.Fs);
	i1=max(1,min(length(y),round(Tstart*D.Fs+1)));
	i2=max(1,min(length(y),round(Tend*D.Fs+1)));
	D.t0=now;
	D.Tstart = Tstart;
	D.Tend = Tend;
	set(audio,'UserData',D)
	audio.play([i1,i2])
else
	audio.play()
end

function StopSound(h,~)
audio=getappdata(ancestor(h,'figure'),'playshowtimer');
stop(audio)

function AudioStopped(audio,~)
D = get(audio,'UserData');
set(D.pointers,'Visible','off')

function RemovePlay(h,~)
f=ancestor(h,'figure');
if strcmp(get(h,'Type'),'uimenu')
	hm=get(h,'Parent');
	if strcmp(get(hm,'Type'),'uimenu')
		delete(hm)
	else
		delete(h)
	end
end
audio=getappdata(f,'playshowtimer');
stop(audio)
D=get(audio,'UserData');
delete(D.pointers)
delete(audio)
if strcmp(get(f,'Tag'),'playshowsound')
	set(f,'Tag','')
end
rmappdata(f,'playshowtimer');

function FreqAnal(f)
audio = getappdata(f,'playshowtimer');
D = get(audio,'UserData');
[Tstart,Tend,iBox] = GetSelectedPart(f);
xl = [Tstart,Tend];
xli = xl*audio.SampleRate+1;
xli(1) = max(ceil(xli(1)),1);
xli(2) = min(floor(xli(2)),audio.TotalSamples);
y = getappdata(D.pointers(1),'sound');
y = y(xli(1):xli(2));

Y = abs(fft(y.*hanning(length(y))))/(length(y)/2);
n = floor((length(y)+1)/2);
F = (0:n-1)*(audio.SampleRate/length(Y));
Y = Y(1:n);
[f,A] = CalcFreqPeak(F,Y,20,50);
[C,X]=PlotXCOR(y,'--bPlot');
X(1) = [];
C(1) = [];
C(C<0) = 0;
Fc = audio.SampleRate./X;
AA_F = interp1(Fc,C,f);
[AAmax,iMax] = max(AA_F);
fMax = f(iMax);
sNotes = {'A','A#','B','C','C#','D','D#','E','F','F#','G','G#','A'};
iN = round(log2(fMax/13.75)*12);
note = sNotes{mod(iN,12)+1};
fCorrect = 13.75*2^(iN/12);

fF = nfigure;
subplot 211
semilogy(F,Y);grid
if isempty(iBox)
	title(sprintf('spectrum (%.1f - %.1f s)',xl))
else
	title(sprintf('spectrum (%.1f - %.1f s - box %d)',xl,iBox))
end
ff = [f;f;nan(size(f))];
AA = [A;A/5;nan(size(A))];
line(ff(:),AA(:),'color',[1 0 0],'Tag','foundPeaks','ButtonDownFcn',@PlayFreq)
line([fMax fMax],A(iMax)*[1 1/5],'color',[1 0 0],'Tag','maxPeak'	...
	,'linewidth',2,'ButtonDownFcn',@PlayFreq)
xlabel(sprintf('f_{peak} = %.1f Hz - %s_%d \\Delta{f} = %.1fHz',fMax	...
	,note,floor(iN/12),fMax-fCorrect))

subplot 212
%fprintf('peak frequencies (t = %.2f .. %.2f s):\n',xl)
%disp([f(:),A(:),AA_F(:)])

plot(Fc,C);grid
ff = [f;f;nan(1,length(f))];
AA = [AA_F(:)'*1.2;AA_F(:)'*0.8;nan(1,length(A))];
line(ff(:),AA(:),'color',[1 0 0],'ButtonDownFcn',@PlayFreq)
line([fMax fMax],AAmax*[1.2 0.8],'color',[1 0 0],'Tag','maxPeak'	...
	,'linewidth',2,'ButtonDownFcn',@PlayFreq)
set(fF,'UserData',struct('t',xl,'range',xli))
title 'cross correlation - shown in frequency domain'
xlabel 'f [Hz]'

Dblock = struct('y',y,'Fs',audio.SampleRate,'blockNr',iBox,'lim',xl		...
	,'fMax',fMax,'note',note,'fCorrect',fCorrect);
set(fF,'UserData',Dblock,'Tag','soundspectrum')
navfig
bepfig(0,max(f)*1.2)
navfig('addkey','p',0,@PlayAnalyzed)
navfig('addkey','P',0,@(f) PlayAnalyzed(f,true))
navfig('addkey','q',0,@(f) PlayAnalyzed(f,false,'sine'))
navfig('addkey','Q',0,@(f) PlayAnalyzed(f,true,'sine'))
navfig('addkey','w',0,@(f) PlayAnalyzed(f,false,'correct'))
navfig('addkey','W',0,@(f) PlayAnalyzed(f,true,'correct'))
f = findobj('Type','figure','Tag','soundspectrum');
if length(f)>1
	navfig('link',f(end:-1:1))
end

function PlayAnalyzed(f,bScaled,typ)
if nargin<2 || isempty(bScaled)
	bScaled = false;
end
if nargin<3 || isempty(typ)
	typ = 'base';
end
D = get(f,'UserData');
switch typ
	case 'base'
		s = D.y;
	case 'sine'
		s = (rms(D.y)*sqrt(2))*sin((0:length(D.y)-1)*(2*pi*D.fMax/D.Fs));
	case 'correct'
		s = (rms(D.y)*sqrt(2))*sin((0:length(D.y)-1)*(2*pi*D.fCorrect/D.Fs));
	otherwise
		error('Unknown type! (%s)',typ)
end
if bScaled
	soundsc(s,D.Fs)
else
	sound(s,D.Fs)
end

function SelectBox(f,nr)
Boxes = getappdata(f,'Boxes');
lBox = [];
if isempty(Boxes)
	iBox = [];
else
	if isempty(nr)
		iBox = [];
	else
		iBox = find([Boxes.nr]==nr);
	end
	Bothers = true(1,length(Boxes));
	if ~isempty(iBox)
		Bothers(iBox) = false;
		lBox = Boxes(iBox).lBox;
		set(lBox,'LineWidth',2)
	end
	if any(Bothers)
		set([Boxes(Bothers).lBox],'LineWidth',0.5)
	end
end
if isempty(nr)
	setappdata(f,'CurrentSelectedBox',[])
	return
end
audio = getappdata(f,'playshowtimer');
D = get(audio,'UserData');
axT = get(D.pointers(1),'Parent');
sTit = get(get(axT,'Title'),'String');
if isempty(iBox)
	title(axT,sprintf('Create box nr %d',nr))
else
	title(axT,sprintf('Set box nr %d',nr))
end
[xMin,xMax,yMin,yMax,bOK,ax,typ] = SelectRect(f,'xy');
title(axT,sTit)
if bOK
	if strcmp(typ,'signal')
		y = getappdata(D.pointers(1),'sound');
		col = [1 0 0];
		i1 = max(ceil(xMin*audio.SampleRate)+1,1);
		i2 = min(floor(xMax*audio.SampleRate)+1,audio.TotalSamples);
		yMin = min(y(i1:i2));
		yMax = max(y(i1:i2));
	elseif strcmp(typ,'spectrum')
		col = [0 0 1];
	else
		error('Unknown type?! (%s)',typ)
	end
	x = xMin+[0 1 1 0 0]*(xMax-xMin);
	y = yMin+[0 0 1 1 0]*(yMax-yMin);
	if isempty(lBox)
		lBox = line(x,y,'Color',col,'LineWidth',2,'Tag','box','UserData',nr		...
			,'Parent',ax,'ButtonDownFcn',@PlayBox);
		iBox = length(Boxes)+1;
	else
		set(lBox,'XData',x,'YData',y,'Color',col,'Parent',ax)
	end
	Box1 = var2struct(lBox,xMin,xMax,yMin,yMax,nr,typ);
	if isempty(Boxes)
		Boxes = Box1;
	else
		Boxes(iBox) = Box1;
	end
	setappdata(f,'Boxes',Boxes);
end
setappdata(f,'CurrentSelectedBox',iBox)

function PlayBox(h,~)
nr = h.UserData;
StartSound(h,[],-3,nr)

function PlayFreq(h,~)
ax = get(h,'Parent');
pt = get(ax,'CurrentPoint');
x = get(h,'XData');
[~,~,f] = findclose(x,pt(1));
Fs = 44100;
tTot = 2;
A = 0.5;
s = A*sin((0:round(Fs*tTot))*(2*pi*f/Fs));
sound(s,Fs)

function ClearBlocks(f)
Boxes = getappdata(f,'Boxes');
if ~isempty(Boxes)
	delete([Boxes.lBox])
	rmappdata(f,'CurrentSelectedBox')
	rmappdata(f,'Boxes')
end

function [xMin,xMax,yMin,yMax,bOK,ax,typ]=SelectRect(f,typ)
%SelectRect - Lets a user select a rectangle
ptr=get(f,'Pointer');
switch typ
	case 'x'
		set(f,'Pointer','crosshair')
	case 'y'
		set(f,'Pointer','cross')
	case 'xy'
		%set(f,'Pointer','fullcrosshair')
		set(f,'Pointer','crosshair')
	otherwise
		warning('Not expected SelectRect-type! (%s)',typ)
end
setappdata(f,'uihandlingactive',true)
k=waitforbuttonpress;
if k
	set(f,'Pointer',ptr)
	xMin=0;
	xMax=0;
	yMin=0;
	yMax=0;
	bOK=false;
	ax = [];
else
	ax=gca;
	pt1=get(ax,'CurrentPoint');
	rbbox;
	set(f,'Pointer',ptr)
	drawnow		% does this help for updating the position?  It seems to be.
	pt2=get(ax,'CurrentPoint');
	xMin=min(pt1(1),pt2(1));
	xMax=max(pt1(1),pt2(1));
	yMin=min(pt1(1,2),pt2(1,2));
	yMax=max(pt1(1,2),pt2(1,2));
	bOK=true;
	typ = get(ax,'Tag');
end
rmappdata(f,'uihandlingactive')
