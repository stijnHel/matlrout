function [A,B,C]=getmatr(X,Y,Z)
% GETMATR - Vormt matrices om naar verschillende vormen
%   [X,Z]=getmatr(A)
%      X = eerste kolom (of rij) van A
%      Z = tweede kolom van A
%   [X,Y,Z]=getmatr(A)
%      zelfde als vorige maar in 3 dimensies :
%             A=[0 X
%                Y Z]
%   A=getmatr(X,Z)
%   A=getmatr(X,Y,Z)
%       omgekeerde konversies

if nargin==1
	s=size(X);
	if nargout==2
		if min(s)<2
			error('Bij "[X,Y]=getmatr(A)" moet A minstens 2x2 matrix zijn.')
		end
		if (s(1)==2)&(s(2)>2)
			X=X';
		end
		A=X(:,1);
		B=X(:,2);
	elseif nargout==3
		if min(s)<2
			error('Bij "[X,Y,Z]=getmatr(A)" moet A minstens 2x2 matrix zijn.')
		end
		A=X(1,2:s(2))';
		B=X(2:s(1),1);
		C=X(2:s(1),2:s(2));
	else
		error('Verkeerd aantal outputs aan deze routine')
	end
elseif nargin==2
	if nargout~=1
		error('Bij 2 inputs mag er slechts 1 output zijn.')
	end
	if min([size(X) size(Y)])~=1
		error('X en Z moeten vectoren zijn')
	elseif length(X)~=length(Y)
		error('X en Z moeten dezelfde lengte hebben')
	end
	A=[X(:) Y(:)];
elseif nargin==3
	if nargout~=1
		error('Bij 3 inputs mag er slechts 1 output zijn.')
	end
	if min([size(X) size(Y)])~=1
		error('X en Y moeten vectoren zijn')
	end
	if length(X)~=size(Z,2)
		if (length(X)==size(Z,1))&(length(Y)==size(Z,2))
			Z=Z';
		else
			error('X heeft een verkeerde lengte tov Z')
		end
	elseif length(Y)~=size(Z,1)
		error('Y heeft een verkeerde lengte tov Z')
	end
	A=[0 X(:)';Y(:) Z];
else
	error('Minstens 1 input moet gegeven zijn')
end
