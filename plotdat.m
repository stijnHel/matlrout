function plotdat(e,ne,e2,y,x,de)
% PLOTDAT  - Plot data
%   plotdat(e,ne,e2,y[,x[,de]])
%     e : "snelle" data (dit is de standaard, maar hoeft niet)
%     ne : namen van kanalen (snelle en trage)
%     e2 : "trage" data
%     y : namen of nummers van kanalen (zoals bij plotmat)
%     x : x-kanaal (naam of nummer)
%     de : dimensies van kanalen
%
%  Deze routine is een soort opvolger (en gebruiker) van plotmat.
%   Ze dient vooral om data met verschillende sample-tijden samen
%   te kunnen weergeven.
% (Nu werkt deze routine enkel voor twee sample-tijden (bijv.
%   komende uit leesalg).)
%
% zie ook plotmat

if ~exist('x','var')|isempty(x)
	x=1;
end
if ~exist('de','var')
	de=[];
end

if ischar(x)
	ix=fstrmat(ne,x);
	if isempty(ix)
		ix=fstrmat(ne,x,2);
		if isempty(ix)
			ix=fstrmat(lower(ne),lower(x));
			if isempty(ix)
				ix=fstrmat(lower(ne),lower(x),2);
				if isempty(ix)
					error('kan x niet vinden')
				end
			end
		end
	end
	if length(ix)>1
		warning('!!!!meerdere x-kanalen gevonden!!!')
	end
	x=ix;
end
if isempty(e2)
	plotmat(e,y,x,ne,de)
	return
end
if length(x)>1
	if length(x)==size(e,1)
		x1=x;
		x2=interp1(e(:,1),x,e2(:,1));
	elseif length(x)==size(e2,1)
		x2=x;
		x1=interp1(e2(:,1),x,e(:,1));
	else
		error('Bij opgave van x-vector moet de lengte gelijk zijn aan deze van e of e2')
	end
elseif x>1
	if x>size(e,2)
		x2=e2(:,x-size(e,2)+1);
		x1=interp1(e2(:,1),x2,e(:,1));
	else
		x1=e(:,x);
		x2=interp1(e(:,1),x1,e2(:,1));
	end
else
	x1=e(:,1);
	x2=e2(:,1);
end
if isempty(de)
	de1=[];
else
	de1=de([1 size(e,2)+1:end],:);
end
[a,l,miss]=plotmat(e2,y,x2,ne([1 size(e,2)+1:end],:),de1);
a=a';
for i=1:size(miss,1)
	for j=1:length(miss{i,3})
		k=fstrmat(lower(ne),lower(miss{i,3}{j}),2);
		if ~isempty(k)
			if length(k)>1
				warning('!!bij toevoegen snelle kanalen, meerdere kanalen gevonden!!')
			end
			k=k(1);
			if k>size(e,2)
				error('!!!kanaal werd niet gevonden tussen trage kanalen, maar staat er toch tussen?????')
			end
			ll=get(a(miss{i,1}),'children');
			if isempty(ll)
				axes(a(miss{i,1}))
				plot(x1,e(:,k));grid
				title(deblank(ne(k,:)))
			else
				ccc=get(a(miss{i,1}),'ColorOrder');
				ccc=ccc(rem(length(ll),size(ccc,1))+1,:);
				line(x1,e(:,k),'parent',a(miss{i,1}),'color',ccc);
				t=get(a(miss{i,1}),'title');
				set(t,'string',[get(t,'string') ',' deblank(ne(k,:))])
			end
		end
	end
end
