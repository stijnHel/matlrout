function dirdiffs(X1,X2,naam1,naam2)
% DIRDIFFS - vergelijking van directory-structuren
if isfield(X1,'dirnaam')
    D1=X1.contents;
    naam1=X1.dirnaam;
else
    D1=X1;
end
if isfield(X2,'dirnaam')
    D2=X2.contents;
    naam2=X2.dirnaam;
else
    D2=X2;
end
if ~exist('naam1','var')
    naam1='X1';
end
if ~exist('naam2','var')
    naam1='X2';
end
Dlijst=struct('naam1',naam1,'D1',D1,'naam2',naam2,'D2',D2);

% opties ("hardcoded")
datediffdisp=0;
listcontdiff=0;

while ~isempty(Dlijst)
    D1=Dlijst(1).D1;
    D2=Dlijst(1).D2;
    naam1=Dlijst(1).naam1;
    naam2=Dlijst(1).naam2;
    Dlijst(1)=[];
    anydiff=0;
	sdiff=sprintf('%s <--> %s\n%s\n',naam1,naam2,repmat('-',1,length(naam1)+length(naam2)+6));
%    if length(D1)>1||length(D2)>1
    [i2,diffs1]=zoekgel(D1,D2,'name','contents');
    i_1=find(i2==0);
    i_2=setdiff(1:length(D2),abs(i2));
    if ~isempty(i_1)
        fprintf('%sin D1 en niet in D2 : "%s"',sdiff,D1(i_1(1)).name)
        anydiff=1;
        if length(i_1)>1
            fprintf(',"%s"',D1(i_1(2:end)).name)
        end
        fprintf('\n')
    end
    if ~isempty(i_2)
        if ~anydiff
            anydiff=1;
            fprintf('%s',sdiff)
        end
        fprintf('in D2 en niet in D1 : "%s"',D2(i_2(1)).name)
        if length(i_2)>1
            fprintf(',"%s"',D2(i_2(2:end)).name)
        end
        fprintf('\n')
    end
    for i_1=find(i2<0)
        i_2=-i2(i_1);
        [sV,rV]=compare(D1(i_1),D2(i_2),0);
        checkthis=0;
        if ~isempty(sV)
            realdiff=0;
            if iscell(sV)
                for i=1:length(sV)
                    r=rV{i};
                    s1=r(end).subs;
                    isD=strcmp(s1,'date');
                    isC=strcmp(s1,'contents');
                    if (~isD&&~isC)||(datediffdisp&&isD)||(listcontdiff&&isC)
                        realdiff=1;
                        break
                    end
                end
            else
                realdiff
            end
            if realdiff
                if ~anydiff
                    anydiff=1;
                    fprintf('%s',sdiff)
                end
                fprintf('"%s" : (%d-%d)\n',D1(i_1).name,i_1,i_2)
                if iscell(sV)
                    for i=1:length(sV)
                        r=rV{i};
                        s1=r(end).subs;
                        isD=strcmp(s1,'date');
                        isC=strcmp(s1,'contents');
                        if (~isD&&~isC)||(datediffdisp&&isD)||(listcontdiff&&isC)
                            r(end).subs='name';
                            fprintf('    %s ("%s")\n',sV{i},subsref(D1(i_1),r))
                        end
                        if strcmp(s1,'contents')
                            checkthis=1;
                        end
                    end
    %                fprintf('    %s\n',sV{:})
                else
                    s1='';
                    fprintf('    %s\n',sV)
                end
            elseif iscell(sV)
                for i=1:length(sV)
                    r=rV{i};
                    s1=r(end).subs;
                    if strcmp(s1,'contents')
                        checkthis=1;
                    end
                end
            end
            D11=D1(i_1).contents;
            D21=D2(i_2).contents;
            if (checkthis||length(D11)~=length(D21))&&length(D11)*length(D21)
                Dlijst=[Dlijst struct('naam1',[naam1 '\' D1(i_1).name]  ...
                    ,'D1',D11   ...
                    ,'naam2',[naam2 '\' D2(i_2).name]   ...
                    ,'D2',D21)];
            end
        end
    end
    if anydiff
        fprintf('\n')
    end
end
