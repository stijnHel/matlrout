function a=calcphra(u,geog,dag,el)

if ~exist('geog','var')||isempty(geog)
	geog='ukkel';
end
if ~exist('dag','var')||isempty(dag)
	dag=clock;
	dag=dag([3 2 1]);
end
if ~exist('el','var')||isempty(el)
	el='zon';
end
if length(dag)==1
	dag=dag+u/24;
elseif length(dag)<3
	error('Verkeerd gebruik')
elseif length(dag)>3
	dag(4)=dag(4)+u;
else
	dag(4)=u;
end
p=calcposhemel(geog,dag,el);
a=p(1);
