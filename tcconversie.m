%TCCONVERSIE - script voor conversie van gemeten spanning naar K-thermokoppel-data

if size(e,2)==5
	if ~exist('Tcj','var')||(length(Tcj)~=size(e,1)&&~isempty(Tcj))
		Tcj=25;
	end
	warning('geen cold junction compensation!!')
else
	Tcj=e(:,5);
end
[Tir,Vcj]=tcconversion(e(:,6)*1000,Tcj);
plot(e(:,1),Tir);grid
