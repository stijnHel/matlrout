function nn=extr(e,ne,opties)
%EXTR - maakt variabelen uit matrix
%    nn=extr(e,ne,WS)
%  met
%    e een matrix waar de verschillende kolommen gesplitst moeten worden.
%    ne een matrix met in de rijen de namen van de verschillende kolommen
%       de namen mogen enkel letters en cijfers bevatten.
%    opties :
%       opties(1) geeft aan of de variabelen als globale gedefinieerd moeten worden
%       opties(2) geeft de workspace aan :
%                  0 lokaal (voor enkel gebruik als globale variabele)
%                  1 "caller"
%                  2 "base"

if nargin==0
	opties=[0 2];
	err=0;
	e=evalin('caller','e','err');
	ne=evalin('caller','ne','0');
	if isstr(e)|isempty(e)|~isstr(ne)
		error('Bij gebruik van extr zonder argumenten moet e en ne bestaan in "caller"-workspace')
	end
elseif nargin<2
	disp('Verkeerd gebruik van extr')
	help extr
	return
end

if nargin>2
	if isempty(opties)
		opties=[1 0];
	elseif length(opties)==1
		if opties
			opties=[1 0];
		else
			opties=[0 1];
		end
	end
end

extr_nn1='';
for extr_i=1:size(e,2)
	extr_n=lower(deblank(ne(extr_i,:)));
	extr_nn1=[extr_nn1 ' ' extr_n];
	e1=e(:,extr_i);
	switch opties(2)
		case 0
			if opties(1)	% globale variabele
				eval(['global ' extr_n]);
			end
			eval([extr_n '=e1;']);
		case 1
			if opties(1)	% globale variabele
				evalin('caller',['global ' extr_n]);
			end
			assignin('caller',extr_n,e1);
		case 2
			if opties(1)	% globale variabele
				evalin('base',['global ' extr_n]);
			end
			assignin('base',extr_n,e1);
		otherwise
			error('Verkeerde opties')
	end
end;
if nargout==0
  fprintf('%s\n',extr_nn1);
else
  nn=extr_nn1;
end