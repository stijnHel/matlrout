function plotlgw(T)
% PLOTLGW  - Plot data van een LGW-file

if ischar(T)
    T=leeslgw(T);
end
plot3(0,0,0);grid
lKeypoints=zeros(0,3);
for i=1:length(T)
    d=T(i).data;
    switch T(i).elem
        case 'keypoint'
            lKeypoints(end+1,:)=d.X;
        case 'line'
            switch d.style
                case 'straight'
                    line(d.X(:,1),d.X(:,2),d.X(:,3) ...
                        ,'Tag','straight line','UserData',i)
                case 'arc'
                    if isfield(d,'the')&~isnan(d.the)
                        a=[d.rho:pi/60:d.the d.the];    %?afh van straal??
                        X=d.r*cos(a);
                        Y=d.r*sin(a);
                        Z0=zeros(1,length(a));
                        if d.phi(1)==0
                            switch d.phi(2)
                                case 1
                                    line(d.Xc(1)+Z0,d.Xc(2)+X,d.Xc(3)+Y   ...
                                        ,'Tag','arc','UserData',i)
                                case 2
                                    line(d.Xc(1)+Y,d.Xc(2)+Z0,d.Xc(3)+X   ...
                                        ,'Tag','arc','UserData',i)
                                case 3
                                    line(d.Xc(1)+X,d.Xc(2)+Y,d.Xc(3)+Z0   ...
                                        ,'Tag','arc','UserData',i)
                            end
                        else
                            Z=[Z0;Z0;Z0];
                            switch d.phi(2)
                                case 1
                                    k=2:3;
                                case 2
                                    k=[3 1];
                                case 3
                                    k=1:2;
                            end
                            Z(k(1),:)=X;
                            Z(k(2),:)=Y;
                            Z=d.Arot'*Z;
                            line(d.Xc(1)+Z(1,:),d.Xc(2)+Z(2,:),d.Xc(3)+Z(3,:)   ...
                                        ,'Tag','arc','UserData',i)
                        end
                    else
                        line(d.X(:,1),d.X(:,2),d.X(:,3),'linestyle',':','color',[1 0 0])
                        warning('!!onvolledige boog!!')
					end
				otherwise
					warning('Onbekend lijntype')
            end
    end
end
if ~isempty(lKeypoints)
    line(lKeypoints(:,1),lKeypoints(:,2),lKeypoints(:,3),'linestyle','none','marker','x')
end
axis equal
