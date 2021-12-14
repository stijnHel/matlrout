function ind=zoekpicts(c)
% CSWF/ZOEKPICTS - Zoekt alle picture data : JPEG's en lossless

i0=zoektags(c,8);	% JPEGTable
i1=zoektags(c,6);	% JPEG-images
i2=zoektags(c,21);	% JPEG2
i3=zoektags(c,35);	% JPEG3
i4=zoektags(c,20);	% LossLess
i5=zoektags(c,36);	% LossLess2

ind=[zeros(size(i0,1),1) i0;	...
	ones(size(i1,1),1) i1;	...
	zeros(size(i2,1),1)+2 i2;	...
	zeros(size(i3,1),1)+3 i3;	...
	zeros(size(i4,1),1)+4 i4;	...
	zeros(size(i5,1),1)+5 i5;
	];
