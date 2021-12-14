function  r=long(varargin)
%LONG Constructor of long class objects
%
% A=LONG constructs the default object: 0e0
% 
% A=LONG(D) converts a double object D into a long object.
% If D is already a long precision array, LONG has
% no effect.
%
% A=LONG(Dec,Pow) constructs the long object: Dec*e(Pow), Dec and Pow are
% double objects
%
%
%   Ignacio del Valle Alles (ignacio_del_valle_alles@scientist.com)
%   $Revision: 1.0 $  $Date: 2003/03/26 10:29:20 $
%
if nargin>0 
    if nargin == 1   
        A=varargin{1};
        if ~strcmp(class(A),'double')&~strcmp(class(A),'long')
            error('Error in class LONG constructor. Argument must be a double array')    
        end 
        if strcmp(class(varargin{1}),'long')
            r=A;
        else
            s=size(A);
            r.potencia=zeros(s);
            r.decimales=zeros(s);
            for i=1:s(1)
                for j=1:s(2)
                    if A(i,j)~=0
                        r.potencia(i,j)=floor(log10(abs(A(i,j))));
                        r.decimales(i,j)=A(i,j)/(10^r.potencia(i,j));
                    else
                        r.potencia(i,j)=0;
                        r.decimales(i,j)=0;
                    end
                end
            end
            r=class(r,'long');
        end
    elseif nargin == 2
        if ~strcmp(class(varargin{1}),'double')|~strcmp(class(varargin{2}),'double')
            error('Error in class LONG constructor. Argument must be a double array')    
        end 
        X=varargin{1};
        A=varargin{2};
        s=size(X);
        for i=1:prod(s)
            if X(i)==0
                A(i)=0;
            elseif abs(X(i))>=10
                pot_ad=floor(log10(abs(X(i))));
                X(i)=X(i)/10^pot_ad;
                A(i)=A(i)+pot_ad;
            end
        end
        r.potencia=A;
        r.decimales=X;
        r=class(r,'long');
    
    else
        error('Error in class LONG constructor. Invalid number of inputs')    
    end
else
    r.potencia=0;
    r.decimales=0;
    r=class(r,'long');
end 