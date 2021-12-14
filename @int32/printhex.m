function printhex(x,varargin)
% INT32/PRINTHEX - print gegevens in hexadecimale vorm
%     printhex(x,f,offset,s0)
%        f kan een file-ID zijn of een filename
%        offset kan een getal of een hexadecimale string zijn
%        s0 is een string die vooraan de tekst toegevoegd wordt (bij elke lijn)
%  uses uint32/printhex

printhex(typecast(x,'uint32'));
