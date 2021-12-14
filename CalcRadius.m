function [R,P0]=CalcRadius(XY)
%CalcRadius - Calculate radius of curve
%         [R,P0]=CalcRadius(XY)
dXY=diff(XY);
mXY=(XY(1:end-1,:)+XY(2:end,:))/2;	% middle points
%R=zeros(length(XY)-2,1);
P0=inf(length(XY)-2,2);
B=sum(dXY.*mXY,2);
for i=1:length(P0)
	% Take 3 sucessive points, determine crossing point of line through the
	% middle of two successive parts, perpendicular to the line between the
	% points..
	A=dXY(i:i+1,:);
	%D=det(A);
	D=A(1)*A(4)-A(2)*A(3);
	if abs(D)<1e-7
		%R(i)=Inf;
	else
		P0(i)=(A(4)*B(i)-A(3)*B(i+1))/D;
		P0(i,2)=(A(1)*B(i+1)-A(2)*B(i))/D;
		%P0(i,:)=A\B(i:i+1,:);
		%R(i)=sqrt(sum((P0(i,:)-XY(i,:)).^2));
	end
end
R=sqrt(sum((P0-XY(1:end-2,:)).^2,2));
