function print1(f,toFile,fAppend,kleur)
% PRINT1 - print 1 figuur

global printInKleur PRINT1Fnaam

if ~exist('f');f=[];end
if ~exist('toFile');toFile=[];end
if ~exist('fAppend');fAppend=[];end
if ~exist('kleur');kleur=[];end
if isempty(f)
       f=gcf;
end
if isempty(fAppend)
       fAppend=0;
end
if isempty(kleur)
   	if isempty(printInKleur)
         kleur=0;
         printInKleur=0;
      else
         kleur=printInKleur;
      end
end
if length(f)>1
	for i=1:length(f)
		print1(f(i))
	end
	return
end
if isempty(toFile)
	printopdr=sprintf('print -f%d',f);
	if kleur
	%              printopdr=[printopdr ' -dwinc'];
	%              printopdr=[printopdr ' -dcdj550'];
		if isempty(PRINT1Fnaam)	...
				|~isstr(PRINT1Fnaam)	...
				|(length(PRINT1Fnaam)~=11)
			PRINT1Fnaam='printf00.ps';
		else
			i=find(PRINT1Fnaam=='.');
			if isempty(i)|i(1)<4
				PRINT1Fnaam='printf00.ps';
			else
				i=i(1);
				k=str2num(PRINT1Fnaam(i-2:i-1));
				if isempty(k)|k>=99
					k=0;
				else
					k=k+1;
				end
				PRINT1Fnaam(i-2:i-1)=sprintf('%02d',k);
			end
		end
		fnaam=[matlabroot '\' PRINT1Fnaam];
		eval(sprintf('print -f%d -dpsc %s',f,fnaam));
		dos(['C:\GSTOOLS\GSVIEW\gsview32 ',fnaam,' &']);
		return
	end
	eval(printopdr);
	return
else
       fNaam=toFile;
end
if isunix
       eval(sprintf('print -f%d -dcdjcolor ttt.jet', f));
       !lp -ddjcolor ttt.jet
elseif strcmp(computer, 'PCWIN')
       printopdr=sprintf('print -f%d',f);
       if fAppend
              printopdr=[printopdr ' -append'];
       end
       if kleur
%              printopdr=[printopdr ' -dwinc'];
%              printopdr=[printopdr ' -dcdj550'];
              printopdr=[printopdr ' -dpsc'];
       end
       printopdr=[printopdr ' ' fNaam];
       eval(printopdr);
       if isempty(toFile)
              if isempty(find(fNaam=='.'))
                     ext='.ps';
              else
                     ext='';
              end
              if kleur
                 dos(['C:\GSTOOLS\GSVIEW\gsview32  ' fNaam ext ' lpt1']);
              else
                 dos(['copy ' fNaam ext ' lpt1']);
              end
       end
end
