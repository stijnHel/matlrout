function [fOut,out2]=status(sArg,prcin,varargin)
% STATUS - geeft een status scherm
%
%   A status window is shown.  It can be called nested.  Only the last
%   message is shown, but the level of nesting is shown (bottom right).
%
%     status('message') open the status window (or adds level)
%     status     decreases status level (or closes status window)
%     status('message',0) open the status window with indication of
%                         fraction finished
%        status(<fraction>) displays fraction finished, with time
%            indication if estimated time is higher than 1 minute
%
%  others:
%     status([],'close') : closes status window if existing
%     status([],'figure') : gives status window handle
%     status([],'disp')   : displays last contents in status window
%          (for example to see the total time)
%     status([],<text>)  : replaces current text by new tekst (without
%                          incrementing level)
%     status(...,'nMaxHier',<nr>) : displays multiple status teksts
%         (multiple "hierarchies")

persistent STATUSTIME FIGwin
persistent BLOG NLOG LOG
persistent TSTART TABS

if isempty(TSTART)
	TSTART = tic;
	TABS = now;
end

tNow=toc(TSTART);
if nargin==1&&isnumeric(sArg)&&tNow-STATUSTIME<0.5
	return
end

if ~exist('sArg','var');sArg=[];end
if ~exist('prcin','var');prcin=[];end

if ~isempty(FIGwin)&&ishandle(FIGwin)
	f=FIGwin;
else
	shh=get(0,'ShowHiddenHandles');
	set(0,'ShowHiddenHandles','on')
	f=findobj(get(0,'Children'),'flat','Name','Statusscherm');
	set(0,'ShowHiddenHandles',shh)
	FIGwin=f;
	if isempty(f)
		BLOG=false;
		NLOG=0;
		LOG=[];
	end
end
if ischar(prcin)
	switch prcin
		case 'close'
			if ~isempty(f)
				delete(f)
				FIGwin=[];
			end
		case 'figure'
			fOut=f;
		case 'disp'
			if isempty(f)
				error('No status-figure found')
			end
			if strcmp(get(f,'Visible'),'off')
				fprintf('Status-window hidden\n')
			end
			l=get(f,'UserData');
			if IsHandle(l(1))
				fprintf('Status-text: %s\n',get(l(1),'String'))
				if strcmp(get(l(2),'Visible'),'on')
					fprintf('       timing text: %s\n',get(l(2),'String'))
				else
					fprintf('       (timing text: %s)\n',get(l(2),'String'))
				end
				fprintf('       level: %s\n',get(l(3),'String'))
			else
				for i=2:length(l)
					s=get(l(i),'String');
					if isempty(s)
						break
					end
					fprintf('     %d - %s\n',i-1,s)
				end
			end
			prcLast=getappdata(f,'lastStatusData');
			if ~isempty(prcLast)
				fprintf('       total time: %5.1f s cpu, %5.1f s duration (ended %s)\n',	...
					(prcLast(4:5)-prcLast(2:3)),datestr(TABS+prcLast(5)/86400))
			end
		case 'status'
			if isempty(f)
				error('No status-figure found')
			end
			if strcmp(get(f,'Visible'),'off')
				fOut=0;
			else
				l=get(f,'UserData');
				prc=get(l(3),'UserData');
				fOut=prc;
			end
		case 'log'
			if nargin==2||isempty(varargin{1})
				if BLOG
					logState='off';
				else
					logState='on';
				end
				fprintf('    logging %s\n',logState)
			else
				logState=varargin{1};
			end
			switch logState
				case 'on'
					BLOG=true;
					NLOG=0;
					if isempty(LOG)
						LOG=zeros(10000,2);
					end
				case 'off'
					BLOG=false;
				otherwise
					error('Wrong value for "status log"')
			end
		case 'clearlog'
			NLOG=0;
		case 'getlog'
			fOut=LOG(1:NLOG,:);
		case 'condclose'	% install conditional close
			if isempty(f)
				error('This can only be done if a status window exists!')
			end
			stopQuestion=varargin{1};
			if isempty(stopQuestion)
				stopQuestion='Interrupt/break current execution?';
			end
			stopAction=varargin{2};
			l=get(f,'UserData');
			prc=get(l(3),'UserData');
			level=size(prc,1);
			STOPREQ=getappdata(f,'StatusStopRequests');
			if ~iscell(STOPREQ)
				STOPREQ=cell(level,2);
			end
			STOPREQ{level,1}=stopQuestion;
			STOPREQ{level,2}=stopAction;
			SetStopReqFcn(f,stopQuestion)
			setappdata(f,'StatusStopRequests',STOPREQ);
		otherwise
			if (isempty(sArg)&&ischar(prcin))||strcmpi(sArg,'tekst')	% rather use status([],'...') !?
				l=get(f,'UserData');
				if IsHandle(l(1))
					set(l(1),'String',prcin);
				else
					prc=get(l(3),'UserData');
					set(l(1+size(prc,1)),'String',prcin)
					s=get(l(2),'UserData');
					if size(s,1)==1
						s=prcin;
					else
						s=char(prcin,s(2:end,:));
						% this used to work is size(s,1)==1 but not anymore?
					end
					set(l(2),'UserData',s)
				end
				drawnow
			end
	end
	return
end
bUseFig=true;
if isempty(f)||~isempty(varargin)
	bUseFig=false;
	location = [];
	if isempty(f)
		nMaxHier=[];
	else
		nMaxHier=getappdata(f,'nMaxHier');
	end
	nMaxHierOld=nMaxHier;
	if ~isempty(varargin)
		setoptions({'nMaxHier','location'},varargin{:})
	end
	if isempty(f)||~isequal(nMaxHier,nMaxHierOld)	% draw/redraw
		if ~isempty(f)
			l=get(f,'UserData');
			if length(l)>2
				s=get(l(2),'UserData');
				if ~isempty(s)
					warning('Recreating status window while in use?!!! This might lead to errors!')
				end
			end
			delete(f)	% recreate
		end
		if isempty(nMaxHier)||nMaxHier==0
			hoog=80;
			breed=400;
			nMaxHier=[];	% replace (possibly) 0 by []
		elseif nMaxHier<0 || nMaxHier>10 || nMaxHier~=round(nMaxHier)
			error('nMaxHier must be an integer between 0 and 10')
		else
			hoog=30+nMaxHier*30;
			breed=600;
		end
		p = get(0,'ScreenSize');
		B = p(3);
		H = p(4);
		f=figure('Name','Statusscherm'	...
			,'NumberTitle','off'	...
			,'MenuBar','none'	...
			,'IntegerHandle','off'	...
			...,'Position',p	...???werkt niet onder XP??
			,'Resize', 'off'	...
			,'Pointer','watch'	...
			,'Tag','statusWindow'	...
			);
		if isempty(location)
			location = 'north';
		end
		if ischar(location)
			switch lower(location)
				case {'north','noord'}
					p = [B/2-breed/2 H-hoog-50];
				case {'south','zuid'}
					p = [B/2-breed/2 50];
				case 'west'
					p = [10 H/2-hoog/2];
				case {'east','oost'}
					p = [B-breed-10 H/2-hoog/2];
				case {'northwest','noordwest'}
					p = [10 H-hoog-50];
				case {'northeast','noordoost'}
					p = [B-breed-10 H-hoog-50];
				case {'southwest','zuidwest'}
					p = [10 50];
				case {'southeast','zuidoost'}
					p = [B-breed-10 50];
				otherwise
					error('Unknown location')
			end
		elseif isnumeric(location)
			if length(location)~=2
				error('Sorry, for location coordinates (2D) are expected!')
			end
			p(1:2) = location;
		else
			error('Wrong input for location')
		end
		p=[p breed hoog];
		setappdata(f,'nMaxHier',nMaxHier)
		setappdata(f,'closereq',get(f,'CloseRequestFcn'));
		FIGwin=f;
		set(f,'Position',p)
		if isempty(nMaxHier)
			% "old style"
			t1=uicontrol('Style','Text'	...
				,'Position',[0,45,breed 20]	...
				,'HorizontalAlignment','center'	...
				,'BackgroundColor', [0 0 0]	...
				,'ForegroundColor', [1 1 1]	...
				);
			t2=uicontrol('Style','Text'	...
				,'Position',[80,10,breed-160,20]	...
				,'HorizontalAlignment','center'	...
				,'BackgroundColor', [0 0 0]	...
				,'ForegroundColor', [1 1 1]	...
				,'TooltipString','CPU time | elapsed time'	...
				);
		else
			t1=0;
			t2=zeros(1,nMaxHier);
			for i=1:nMaxHier
				t2(i)=uicontrol('Style','Text'	...
					,'Position',[0,hoog-30*i,breed 20]	...
					,'HorizontalAlignment','center'	...
					,'BackgroundColor', [0 0 0]	...
					,'ForegroundColor', [1 1 1]	...
					,'TooltipString','CPU time | elapsed time'	...
					,'Visible','off'	...
					);
			end
		end
		axes('Units','pixels'	...
			,'Position',[breed-30 0 30 15]	...
			,'Visible','off'	...
			);
		t3=text(0.5,0.5,'');
		set(t3	...
			,'HorizontalAlignment','center'	...
			,'VerticalAlignment','middle'	...
			,'FontSize',9	...
			);
		l=[t1 t2 t3];
		set(f,'UserData',l	...
			,'HandleVisibility','off'	...
			);
		s='';
		prc=[];
	else
		bUseFig=true;
	end		% draw/redraw
	if nargin>2&&isempty(sArg)	% function call was done to change settings
		set(f,'Visible','off')
		return
	end
end
if bUseFig
	close(f(2:end));	% this shouldn't be useful...
	f=f(1);
	l=get(f,'UserData');
	if length(l)<3
		error('!!!! error in status !!!!!');
	end
	s=get(l(2),'UserData');
	prc=get(l(3),'UserData');
	if isempty(prc)
		if strcmp(get(f,'Visible'),'off')
			set(f,'Visible', 'on')
			%			p=get(0,'ScreenSize');
			%			p=[p(3)/2-breed/2 p(4)*4/5 breed hoog];
		end
	end
end

cpuNow=cputime;
bUpdate=true;

if isempty(sArg)
	if isempty(s) || (size(s,1)~=size(prc,1))
		delete(f);	% er loopt iets fout
		errordlg('Er loopt iets fout met status');
		FIGwin=[];
		return
	end
	n=size(s,1);
	if n<length(l)-1
		set(l(n+1),'visible','off')
	end
	s(1,:)=[];
	set(l(2),'UserData',s);
	prcLast=[prc(1,:) cpuNow tNow];
	setappdata(f,'lastStatusData',prcLast)
	level=size(prc,1);
	prc(1,:)=[];
	set(l(3),'UserData',prc);
	STOPREQ=getappdata(f,'StatusStopRequests');
	if size(STOPREQ,1)>=level&&~isempty(STOPREQ{level})
		STOPREQ{level}=[];
		STOPREQ{level,2}=[];
		fcnClose=[];
		while level>1
			level=level-1;
			if ~isempty(STOPREQ{level})
				fcnClose=STOPREQ{level,2};
				break
			end
		end
		setappdata(f,'StatusStopRequests',STOPREQ)
		SetStopReqFcn(f,fcnClose)
	end
	if isempty(prc)
		set(f,'Visible','off');
		% because of strange behaviour on Matlab7.6 (linux): (!!!)
		fList=findobj('Type','figure','Visible','on');
		if ~isempty(fList)&&gcf==f
			figure(fList(1))
		end
		return;
	end
	bUpdate=false;
	sArg=deblank(s(1,:));
	prcin=prc(1,1);
	if prcin<0
		prcin=[];
	end
	if BLOG
		if NLOG>=size(LOG,1)
			LOG(end+10000,1)=0;
		end
		NLOG=NLOG+1;
		LOG(NLOG,:)=[tNow,-2];
	end
	tNow=0;	% force update next call
elseif ischar(sArg)
	if length(sArg)>size(s,2)
		s=[s zeros(size(s,1),length(sArg)-size(s,2))];
	end
	s=[sArg char(zeros(1,size(s,2)-length(sArg)));s];
	set(l(2),'UserData', s);
	if isempty(prcin)
		prc=[-1 cpuNow tNow;prc];
	else
		prc=[prcin cpuNow tNow;prc];
	end
	if ~IsHandle(l(1))
		n=size(s,1);
		if n+2<=length(l)
			set(l(n+1),'visible','on')
		end
	end
	level=size(prc,1);
	STOPREQ=getappdata(f,'StatusStopRequests');
	if size(STOPREQ,1)>=level&&~isempty(STOPREQ{level})
		STOPREQ{level}=[];
		setappdata(f,'StatusStopRequests',STOPREQ)
	end
	set(l(3),'UserData', prc);
	if BLOG
		if NLOG>=size(LOG,1)
			LOG(end+10000,1)=0;
		end
		NLOG=NLOG+1;
		LOG(NLOG,:)=[tNow,prc(1)];
	end
elseif isempty(prc)
	delete(f)
	FIGwin=[];
	error('Use of status times without the right initialisation')
else
	STATUSTIME=tNow;
	t1=(cpuNow-prc(1,2))/60/max(0.01,sArg);
	t2=(tNow-prc(1,3))/60/max(0.01,sArg);
	if IsHandle(l(1))
		if t2>1
			if t2>=100
				sTfor = '%4.0f';
			else
				sTfor = '%4.2f';
			end
			set(l(2),'String',sprintf(['%5.1f %% (nog ',sTfor,'|',sTfor,' min. (',sTfor,'|',sTfor,' min.))'],	...
				sArg*100,	...
				(1-sArg)*t1,(1-sArg)*t2,t1,t2));
		else
			set(l(2),'String',sprintf('%5.1f %%',sArg*100));
		end
	else
		s=deblank(s(1,:));
		if t2>1
			if t2>=100
				sTfor = '%4.0f';
			else
				sTfor = '%4.2f';
			end
			s=sprintf(['%s (%5.1f %% - ',sTfor,'|',sTfor,' min. (',sTfor,'|',sTfor,' min.))']	...
				,s	...
				,sArg*100,	...
				(1-sArg)*t1,(1-sArg)*t2,t1,t2);
		else
			s=sprintf('%s (%5.1f %%)',s,sArg*100);
		end
		n=size(prc,1);
		if n<length(l)
			set(l(1+n),'String',s);
		end
	end
	set(l(3),'UserData',prc);
	drawnow
	if BLOG
		if NLOG>=size(LOG,1)
			LOG(end+10000,1)=0;
		end
		NLOG=NLOG+1;
		LOG(NLOG,:)=[tNow,sArg];
	end
	if nargout
		fOut=size(prc,1);
		if nargout>1
			STOPREQ=getappdata(f,'StatusStopRequests');
			if fOut<=size(STOPREQ,1)&&~isempty(STOPREQ{fOut})
				out2=STOPREQ(fOut,:);
			else
				out2=[];
			end
		end
	end
	return
end

if IsHandle(l(1))
	set(l(1),'String',sArg);
	if isempty(prcin)
		set(l(2),'Visible','off')
	else
		set(l(2),'Visible','on');
	end
	if ~isempty(prcin)
		set(l(2),'String',sprintf('%5.1f %%',prcin*100));
	end
elseif bUpdate
	n=size(prc,1);
	nHier=length(l)-2;
	if n<=nHier
		if isempty(prcin)
			s=sArg;
		else
			s=sprintf('%s (%5.1f %%)',sArg,prcin*100);
		end
		set(l(1+n),'String',s,'Visible','on');
	end
end
set(l(end),'String',num2str(size(prc,1)));
%figure(f)
drawnow
STATUSTIME=tNow;
if nargout
	fOut=f;
end

function bOK=IsHandle(h)
% checks if h is a handle (and not 0, since that's regarded as a handle)
bOK=h~=0&&ishandle(h);

function SetStopReqFcn(f,stopQuestion)
if isempty(stopQuestion)
	set(f,'CloseRequestFcn',getappdata(f,'closereq'))
elseif ischar(stopQuestion)
	set(f,'CloseRequestFcn',@(f,~) StopReqFcn(f,stopQuestion))
else
	set(f,'CloseReqFcn',stopQuestion)
end

function StopReqFcn(f,stopQuestion)
l=get(f,'UserData');
prc=get(l(3),'UserData');
STOPREQ=getappdata(f,'StatusStopRequests');
doStop=questdlg(stopQuestion,'status-close-action','Yes','No','No');
if strcmp(doStop,'Yes')
	level=size(prc,1);
	stopAction=[];
	while level>0
		if level<=size(STOPREQ,1)&&~isempty(STOPREQ{level})
			stopAction=STOPREQ{level,2};
			level=level-1;
			break
		end
		level=level-1;
	end
	stopQuestion=[];
	while level>0
		if ~isempty(STOPREQ{level})
			stopQuestion=STOPREQ{level};
			break
		end
		level=level-1;
	end
	SetStopReqFcn(f,stopQuestion)
	if ischar(stopAction)
		eval(stopAction)
	elseif isa(stopAction,'function_handle')
		stopAction(f);
	else
		% just do nothing?
	end
end
