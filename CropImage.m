function Xout=CropImage(in)
%CropImage - Crop an image (removing background border)
%   CropImage imageFilename

if ischar(in)
	Ximg=imread(in);
	[~,Ximg]=CheckMarginImg(Ximg);
	imwrite(Ximg,in)
else
	[~,Xout]=CheckMarginImg(in);
end


