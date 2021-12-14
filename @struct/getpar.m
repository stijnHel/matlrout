function [u1,u2]=getpar(X,par)
% STRUCT/GETPAR - Geeft parameter uit struct
%    val=getpar(X,par);
%    [val,str]=getpar(X,par);
%    getpar(X,par);
%  X is structure, bijvoorbeeld uit leesdcm

i=strmatch(lower(par),lower({X.naam}));
if isempty(i)
	error('Geen parameter gevonden.')
elseif length(i)>1
	warning('!!meerdere parameters gevonden!!')
	if nargout==0
		if length(i)<20
			fprintf('%s\n',X(i).naam)
		else
			fprintf('        (%d parameters)\n',length(i))
		end
	elseif nargout>1
		u1={X(i).value};
		u2=X(i);
	end
	return
end
X=X(i);
v=X.value;
if nargout==0
	if numel(v)==1
		fprintf('%g\n',double(v))
	elseif min(size(v))==2
		if size(v,1)==2
			v=v';
		end
		nfigure([],'name',['CURVE - ',X.naam])
		plot(v(:,1),v(:,2));grid
		title(par.Name)
	else
		[Xx,Xy,Xz]=getmatr(v);
		nfigure([],'name',['MAP 2D - ',X.naam])
		orient tall
		subplot 211
		plot(Xx,Xz');grid
		title(X.naam)
		subplot 212
		plot(Xy,Xz);grid
		if strcmp(class(X),'double')
			nfigure([],'name',['MAP 3D - ',X.naam])
			mesh(Xx,Xy,Xz)
			title(X.naam)
		end
	end
else
	u1=v;
	if nargout>1
		u2=X;
	end
end
