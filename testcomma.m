function testcomma
% TESTCOMMA - functie om te testen of getallen gegeven worden door '.' of ','
s=num2str(1/2);
a=[1,2];

if any(s==',')
    if length(a)<1
        fprintf('Alles met comma. (!!!!!niet gebruikerlijk!!!!!)  sommige zaken kunnen fout lopen\n   (zoals inlezen van LPH1-metingen)\n');
    else
        fprintf('!!!!!weergegeven getallen met "," en input van getallen met "."!!!!!!\n')
        fprintf('!!!matlab begrijpt zichzelf niet!!!!!   : str2num(num2str(1/2))~=1/2!!!!!\n')
    end
elseif length(a)<1
    fprintf('!!!!!weergegeven getallen met "." en input van getallen met ","!!!!!!\n')
        fprintf('!!!matlab begrijpt zichzelf niet!!!!!   : str2num(num2str(1/2))~=1/2!!!!!\n')
else
    fprintf('Alles met punt.  Dit is de meest normale situatie, en alles zal normaal werken.\n');
end
