function orig=moveass(figs,fig,pos)
% MOVEASS  - Zet alle assen van de figuren in een figuur
%      orig=moveass(figs,fig,pos)
%        figs : figuren te "plakken" in een andere figuur
%        fig  : als gegeven de figuur naar waar figuren te "plakken"
%               als niet gegeven wordt een nieuwe figuur gemaakt
%        pos  : de posities waar de figuren "geplakt" moeten worden.
%      moveass('herstel',orig) : herstelt de verplaats-aktie
%            orig is de data die uit moveass komt.
%                  indien deze niet gegeven is, wordt de laatste
%                  aktie teniet gedaan.
%      moveass('defpos',figs,opties)
%            Geeft de standaard-waardes voor pos

persistent LASTMoveassOrig

if ischar(figs)
	switch figs
		case 'herstel'
			if ~exist('fig')|isempty(fig)
				fig=LASTMoveassOrig;
			end
			for i=1:size(fig,1)
				set(fig(i,1),'Parent',fig(i,2),'Position',fig(i,3:6))
			end
			return
		case 'defpos'
			% Het volgende is niet klaar maar is gepland (of voorgesteld)
			% pos leeg : automatisch
			% pos=-1   : automatisch op basis van vorm van figs
			% pos=-2   : automatisch op basis van positie van figuren op scherm
			nf=prod(size(fig));
			if ~exist('pos')|isempty(pos)
				if nf<4
					nk=1;
				else
					nk=2;
				end
				nr=ceil(nf/nk);
				pos=zeros(nf,4);
				if nk==1
					pos(:,1)=0;
					pos(:,2)=1-(1:nf)'/nf;
				else
					pos(:,1)=rem(0:nf-1,2)'/2;
					pos(:,2)=1-floor((2:nf+1)'/2)/nr;
				end
				pos(:,3)=1/nk;
				pos(:,4)=1/nr;
			else
				error('Verkeerd gebruik van moveass')
			end
			orig=pos;
			return
		otherwise
			error('Verkeerd gebruik van moveass');
	end
end
nf=prod(size(figs));
if ~exist('pos')|length(pos)<=1
	if exist('pos')
		pos=moveass('defpos',figs,pos);
	else
		pos=moveass('defpos',figs);
	end
elseif size(pos)~=[nf,4];
	error('pos heeft een verkeerde waarde');
end

if ~exist('fig')|isempty(fig)
	fig=nfigure;
	orient landscape
end
ass=zeros(0,6);
for i=1:nf
	xx=findobj(figs(i),'Type','axes');
	for j=1:length(xx)
		u=get(xx(j),'Units');
		if ~strcmp(u,'normalized')
			error('Deze routine gaat ervan uit dat het om "normalized-positioned" assen gaat');
		end
		p=get(xx(j),'Position');
		ass(end+1,:)=[xx(j),figs(i),p];
		p(1)=pos(i,1)+p(1)*pos(i,3);
		p(2)=pos(i,2)+p(2)*pos(i,4);
		p(3)=p(3)*pos(i,3);
		p(4)=p(4)*pos(i,4);
		set(xx(j),'Parent',fig,'Position',p)
	end
end
if nargout
	orig=ass;
end
LASTMoveassOrig=ass;
