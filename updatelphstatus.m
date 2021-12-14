function updatelphstatus
% UPDATELPHSTATUS - Update excel-file met gegevens van LPH1 en 2

if ~exist('fexcel','var')|isempty(fexcel)
	fexcel='i:\cs\stijn\Matlab\lphstatus.xls';
end

excel=actxserver('Excel.Application');
set(excel,'Visible',1);
invoke(excel.Workbooks,'Open',fexcel);

for lphnr=1:2
	T=leeslphpref(sprintf('k:\\lph%d\\Voorkeuren\\Status.pref',lphnr));
    invoke(get(excel.sheets,'item',lphnr+1),'Activate');
	set(get(excel.Activesheet,'Range','C3','C3'),'Value',T.BUT);
	set(get(excel.Activesheet,'Range','C5','C5'),'Value',T.proefstandskm);
	set(get(excel.Activesheet,'Range','C6','C6'),'Value',T.afstand);
	set(get(excel.Activesheet,'Range','C7','C7'),'Value',T.cyclus);
	set(get(excel.Activesheet,'Range','C8','C8'),'Value',T.afstandtest);
	set(get(excel.Activesheet,'Range','C9','C9'),'Value',T.tijd);
end

invoke(get(excel.sheets,'item',1),'Activate');



delete(excel)
