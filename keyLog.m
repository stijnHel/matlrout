function D=keyLog(h,ev)
%keyLog - logger of keystrokes for callback

if nargin==0||isnumeric(h)
	if nargin==0
		h=gcf;
	end
	if nargin<2
		c=double(get(h,'currentcharacter'));
	else
		c=ev.Character;
	end
	X=getappdata(h,'keyStrokes');
	t=now;
	if length(c)>1
		c=((0:length(c)-1)*256+1)*c';
	elseif isempty(c)
		c=0;
	end
	if isempty(X)
		keyLog start
	end
	X.t(1,end+1)=t;
	X.key(1,end+1)=c;
	setappdata(h,'keyStrokes',X);
	switch X.UItype
		case 1
			S=X.key;
			S(S==9)=32;
			S(S==13)=10;
			S=char(S);
			S(S<32&S~=10)=[];
			set(X.H(1),'String',S)
			set(X.H(2),'String',num2str(length(S)))
			if length(S)>1
				s=1/((X.t(end)-X.t(1))/(length(X.t)-1)*24*60);
				set(X.H(3),'String',sprintf('%4.1f',s))
			end
	end
elseif ischar(h)
	switch lower(h)
		case 'text'
			X=getappdata(gcf,'keyStrokes');
			D=char(X.key);
		case 'startui'
			keyLog('start',1)
		case 'herstart'
			X=getappdata(gcf,'keyStrokes');
			X.key=zeros(1,0);
			X.t=zeros(1,0);
			if X.UItype==1
				set(X.H(1),'String','Start met typen')
				set(X.H(2:3),'String','---')
			end
			setappdata(gcf,'keyStrokes',X);
		case 'start'
			if nargin>1
				UItype=ev;
			else
				UItype=0;
			end
			f=[];
			H=[];
			switch UItype
				case 1
					[f,bN]=getmakefig('keyLogFig');
					if ~bN
						h=clf(f);
					end
					p=get(f,'Position');
					hT=uicontrol('Style','text','Position',[5 5 p(3)-10 p(4)-30]	...
						,'horizontalalignment','left');
					hN=uicontrol('Style','text','Position',[5 p(4)-20 40 15]);
					hA=uicontrol('Style','text','Position',[50 p(4)-20 40 15]);
					H=[hT,hN,hA];
			end
			if isempty(f)
				f=gcf;
			end
			set(f,'WindowKeyPressFcn',@keyLog)
			X=struct('key',zeros(1,0),'t',zeros(1,0)	...
				,'UItype',UItype,'H',H);
			setappdata(f,'keyStrokes',X)
		case 'snelheid'
			X=getappdata(gcf,'keyStrokes');
			t=(X.t(end)-X.t(1))/(length(X.t)-1)*24*60;
			if nargout
				D=1/t;
			else
				fprintf('%4.1f per minuut.\n',1/t)
			end
		otherwise
			D=getappdata(gcf,'keyStrokes');
	end
end
