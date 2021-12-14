function [i2,D]=zoekgel(s1,s2,velden,compveld)
% ZOEKGEL  - Zoekt gelijke elementen van structure-array
%   zoekt ook naar gelijke elementen met uitzondering van structure-data

i2=zeros(1,length(s1));
j1=1:numel(s2);
ns1=fieldnames(s1);
ns2=fieldnames(s2);
if ~exist('velden','var')||isempty(velden)
    velden=ns1;
    if ~isequal(ns1,ns2)
        warning('!!verschillende structuren kunnen geen gelijke elementen hebben!!')
    end
else
    if ischar(velden)
        velden={velden};
    end
    if ~isempty(setdiff(velden,ns1))||~isempty(setdiff(velden,ns2))
        error('niet alle gewenste velden in gegeven structures')
    end
end
for i=1:length(s1)
    s11=s1(i);
    for j=1:length(j1)
        if isequal(s11,s2(j1(j)))
            i2(i)=j1(j);
            j1(j)=[];
            break;
        else
            s21=s2(j1(j));
            dd=1;
            for k=1:length(velden)
                x1=getfield(s11,velden{k});
                x2=getfield(s21,velden{k});
                if ~isstruct(x1)||~isstruct(x2)
                    if ~isequal(x1,x2)
                        dd=0;
                        break;
                    end
                end
            end
            if dd
                i2(i)=-j1(j);
                j1(j)=[];
                break;
            end
        end
    end
end

if nargout>1
    if ~exist('compveld','var')
        compveld=[];
    end
    iDif=find(i2<0);
    D=struct('i1',num2cell(iDif),'i2',num2cell(-i2(iDif)),'diff',[] ...
        ,'s1',[],'s2',[] ...
        );
    k=0;
    for i=iDif
        k=k+1;
        i_2=-i2(i);
        if isempty(compveld)
            [sV,rV,nCh]=compare(s1(i),s2(i_2));
        else
            str1=getfield(s1(i),compveld);
            str2=getfield(s2(-i2(i)),compveld);
            if isstruct(str1)&&isstruct(str2)
                [sV,rV,nCh]=compare(str1,str2);
            else
                %!!!(?)!!! vergelijking zonder 'compveld'
                [sV,rV,nCh]=compare(s1(i),s2(i_2));
            end
        end
        D(k).diff=struct('sV',sV,'rV',rV,'nCh',nCh);
        D(k).s1=s1(i);
        D(k).s2=s2(i_2);
    end
end
