function ShowEigenStateVector(DE,nrT,nrE,varargin)
%ShowStateVector - Show states related to an eigen value
%       ShowEigenStateVector(DE,nrT,nrE)
%            DE: (currently) the full struct-output from EvaluateEigValues

tol=1e-12;
if ~isempty(varargin)
	setoptions({'tol'},varargin{:})
end

VV=DE.VV(nrT);
V=VV.V(:,nrE);
[vv,kk] = sort(abs(V),'descend');
i0=find(vv<=tol,1);
if isempty(i0)
	i0=length(V)+1;
end
ii=1:i0-1;
jj=kk(ii);
E = DE.E(nrE,nrT);
if imag(E)
	fprintf('Eigenstate for eigenvalue #%d     (%12g : %12g   %12gi)\n'	...
		,nrE,abs(E),real(E),imag(E))
	printstr('%s',DE.J.stateName(VV.iS(kk(ii))),' %12g :',vv(ii)	...
		,'%12g',real(V(jj))	...
		,'%12gi',imag(V(jj))	...
		)
else
	fprintf('Eigenstate for eigenvalue #%d     (%12g)\n'	...
		,nrE,E)
	printstr('%s',DE.J.stateName(VV.iS(kk(ii))),' %12g',V(jj))
end
