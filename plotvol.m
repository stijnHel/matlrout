function pout=plotvol(d,c)
% PLOTVOL  - Plot volume uit lgw-file

if nargin<2|isempty(c)
    c=[0 1 0];
end

if length(d)>1
    if size(c,1)==1
        c=c(ones(length(d),1),:);
    elseif size(c,1)~=length(d)
        error('Grootte van kleuren en volumes komt niet overeen')
    end
    for i=1:length(d)
        plotvol(d(i),c(i,:))
    end
    return
elseif isfield(d,'elem')&isfield(d,'data')&length(fieldnames(d))==2
    if ~strcmp(d.elem,'volume')
        return  % error?
    end
    d=d.data;
end
if isfield(d,'oper')
    if strcmp(d.oper,'add')
        p=cell(1,length(d.elem));
        for i=1:length(d.elem)
            p{i}=plotvol(d.elem(i));
        end
    else
        warning('Deze functie werkt (nog) niet op dit soort volumes')
    end
else
    if 0
        line(d.X(:,1),d.X(:,2),d.X(:,3))
        n=size(d.X,1);
        t=zeros(1,n);
        for i=1:n
            algetekend=0;
            if i>1
                del=sum((d.X(1:i-1,:)-d.X(i+zeros(1,i-1),:)).^2,2);
                if any(del==0)
                    algetekend=1;
                    j=find(del==0);
                    j=j(1);
                    t1=t(j);
                    set(t1,'String',[get(t1,'String') ',' num2str(i)])
                end
            end
            if ~algetekend
                t1=text(d.X(i,1),d.X(i,2),d.X(i,3),num2str(i),'horizontalal','center','verticalal','bottom');
            end
            t(i)=t1;
        end
    end
    % vlakken
    V=[1:4;1 2 6 5;2 6 7 3;1 5 8 4;5:8;4 3 7 8]';
    X=reshape(d.X(V,1),4,6);
    Y=reshape(d.X(V,2),4,6);
    Z=reshape(d.X(V,3),4,6);
    p=patch(X,Y,Z,c,'facealpha',0.3);
end

if nargout
    pout=p;
end
