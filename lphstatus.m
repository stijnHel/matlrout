function lphstatus
% LPHSTATUS - Update excel-file met gegevens van LPH's

if ~exist('fexcel','var')|isempty(fexcel)
	fexcel='I:\CS\filip\prevohlph.xls';
end

excel=actxserver('Excel.Application');
set(excel,'Visible',1);
invoke(excel.Workbooks,'Open',fexcel);

%??????????????????????????????????????????????????????
%!!!!!!!!!!!!!!afstand <----> afstandtest!!!!!!!!!!!!!!
%??????????????????????????????????????????????????????
%   misschien beter afstandtest gebruiken

for lphnr=1:4
	T=leeslphpref(sprintf('k:\\lph%d\\Voorkeuren\\Status.pref',lphnr));
    invoke(get(excel.sheets,'item',lphnr),'Activate');
	set(get(excel.Activesheet,'Range','E31','E31'),'Value',T.BUT);
	set(get(excel.Activesheet,'Range','H3','H3'),'Value',T.proefstandskm);
	set(get(excel.Activesheet,'Range','E32','E32'),'Value',T.afstand);
	%set(get(excel.Activesheet,'Range','E33','E33'),'Value',T.cyclus);
	%set(get(excel.Activesheet,'Range','E33','E33'),'Value',T.afstandtest);
	%set(get(excel.Activesheet,'Range','E34','E34'),'Value',T.tijd);
end

invoke(get(excel.sheets,'item',1),'Activate');



delete(excel)
