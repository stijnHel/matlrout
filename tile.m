function out=tile(figs,ncols,nrij,pos0)
%TILE - verdeelt de figuren over het schem
%      tile(figs,ncols,nrij,pos0)

% idee:
%    als figs matrix (min(size(figs))>1), geeft dit de structuur aan
%         (ncols,nrij)

if ~exist('figs','var')
	figs=[];
end

if ~exist('ncols','var')
	ncols=[];
end

if ~exist('nrij','var')
	nrij=[];
end

if ~exist('pos0','var')
	pos0=[];
end

if isempty(figs)
	figs=sort(findobj('Type','figure','Visible','on'));
	if isempty(figs)
		return
	end
elseif length(figs)==1
	figs=1:figs;
end
nfigs=length(figs);

if isempty(nrij)
	if isempty(ncols)
		if nfigs>3
			ncols=2;
		else
			ncols=1;
		end
	end
	nrij=ceil(nfigs/ncols);
end

if isempty(pos0)
	% This doesn't seem to work in a function
	wState=warning('off');		% (!) in the future this warning can be important
	jFrame = get(handle(figs(1)),'JavaFrame');
	jFrame.setMaximized(true)
	hh=uicontrol('parent',figs(1));	% To make sure that the size is updated!
		% also this doesn't seem to have effect?!
	drawnow		% in first trials this didn't have effect?!
	drawnow		% doing it twice helps?!
	set(figs(1),'Units','pixel')
	pos0 = get(figs(1),'Position');
	delete(hh)
	%disp(pos0)
	jFrame.setMaximized(false)
	warning(wState)
elseif isscalar(pos0)
	if ~ishghandle(pos0)
		error('Bad input for pos0')
	end
	if pos0>0
		pos0=get(pos0,'Position');
	else
		pos0=get(figs(1),'Position');
		P=[pos0(1:2) pos0(1:2)+pos0(3:4)];
		for i=2:numel(figs)
			Pi=get(figs(i),'Position');
			P(1:2)=min(P(1:2),Pi(1:2));
			P(3:4)=max(P(3:4),Pi(1:2)+Pi(3:4));
		end
		pos0=[P(1:2) P(3:4)-P(1:2)];
	end
end

sx=floor(pos0(3)/ncols);
sy=floor((pos0(4)+10)/nrij);
POS=zeros(nfigs,4);
EXTR=zeros(1,nfigs);

for i=0:nfigs-1
	j=floor(i/nrij);
	k=rem(i,nrij);
	nf=double(figs(i+1));
	if nf && ishandle(nf)
		figure(nf)
		if strcmp(get(nf,'MenuBar'),'none')
			extr=0;
		else
			extr=30;
		end
		EXTR(i+1)=extr;
		POS(i+1,:)=[j*sx+pos0(1),k*sy+pos0(2)+12,sx-1,sy-28-extr];
		set(nf,'units','pixels','Position',POS(i+1,:))
	end
end
if nargout
	out=struct('figs',figs,'pos0',pos0,'sx',sx,'sy',sy,'extr',EXTR,'pos',POS);
end
