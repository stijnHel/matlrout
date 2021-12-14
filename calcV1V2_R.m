function R=calcV1V2_R(V1,V2)
%calcV1V2_R - Calculate rotation matrix to translate V1 onto V2
%    R=calcV1V2_R(V1,V2)

%https://math.stackexchange.com/questions/180418/calculate-rotation-matrix-to-align-vector-a-to-vector-b-in-3d
%      ssc = @(v) [0 -v(3) v(2); v(3) 0 -v(1); -v(2) v(1) 0]
%      RU = @(A,B) eye(3) + ssc(cross(A,B))	...
%          + ssc(cross(A,B))^2*(1-dot(A,B))/(norm(cross(A,B))^2)

V1=V1(:);
V2=V2(:);

% Make sure V1 and V2 are unit vectors
V1=V1/sqrt(V1'*V1);
V2=V2/sqrt(V2'*V2);

V3=cross(V1,V2);
R=eye(3);
r=V1'*V2;
if sum(abs(V3))<1e-14
	if r<0
		R=-R;
	end
else
	ssc = [0 -V3(3) V3(2);V3(3) 0 -V3(1);-V3(2) V3(1) 0];
	R = R+ssc+ssc^2*(1-r)/(V3'*V3);
end
