function [sVerschillen,refVerschillen,nChecked]=compare(s1,s2,recur)
% STRUCT/COMPARE - Vergelijkt twee structures hierarchisch
%     [sVerschillen,refVerschillen,nChecked]=compare(s1,s2,recur)

if ~exist('recur')||isempty(recur)
    recur=1;
end
if ~isstruct(s1)||~isstruct(s2)
    error('inputs moeten van het type struct zijn')
end
ns=fieldnames(s1);
ns2=fieldnames(s2);
nChecked=1;

refVerschillen=[];

if isequal(s1,s2)
    sVerschillen=[];
    return
elseif length(ns)~=length(ns2)
    sVerschillen='aantal velden is verschillend';
elseif ~isequal(ns,ns2)
    sVerschillen='verschillende velden in structure';
elseif ndims(s1)~=ndims(s2)
    sVerschillen='verschillend aantal dimensies';
elseif any(size(s1)~=size(s2))
    sVerschillen='verschillende groottes';
else
    sVerschillen={};
    for i=1:numel(s1)
        if ~isequal(s1(i),s2(i))
            for j=1:length(ns)
                nChecked=nChecked+1;
                s11=getfield(s1(i),ns{j});
                s21=getfield(s2(i),ns{j});
                s0=sprintf('(%d).%s',i,ns{j});
                rs0=struct('type',{'()','.'},'subs',{{i},ns{j}});
                if ~strcmp(class(s11),class(s21))
                    if (isnumeric(s11)||islogical(s11))&&(isnumeric(s21)||islogical(s21))
                        if ~isequal(s11,s21)
                            sVerschillen{end+1}=[s0 ' - inhoud verschillend'];
                            refVerschillen{end+1}=rs0;
                        end
                    else
                        sVerschillen{end+1}=[s0 ' - verschillend type'];
                        refVerschillen{end+1}=rs0;
                    end
                elseif isstruct(s11)&&recur
                    [sV1,rV1,nC1]=compare(s11,s21,recur);
                    nChecked=nChecked+nC1-1;
                    if isempty(sV1)
                        % gelijk
                    elseif iscell(rV1)
                        for k=1:length(sV1)
                            sVerschillen{end+1}=[s0 sV1{k}];
                            refVerschillen{end+1}=[rs0 rV1{k}];
                        end
                    else
                        if iscell(sV1)
                            warning('!!onverwacht!!')
                            sV1=sV1{1};
                        elseif ~isempty(rV1)
                            warning('ook onverwacht!!!')
                        end
                        sVerschillen{end+1}=[s0 ' - ' sV1];
                        refVerschillen{end+1}=rs0;
                    end
                elseif ~isequal(s11,s21)
                    sVerschillen{end+1}=[s0 ' - inhoud verschillend'];
                    refVerschillen{end+1}=rs0;
                end
            end
        end
    end
end
