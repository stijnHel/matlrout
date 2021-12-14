function cws2fws(fsource,fdest)
%cws2fws  - Convert CWS (compressed swf) to fws file (normal swf)
%    cws2fws(fsource,fdest)

fid=fopen(fsource);
if fid<3
    error('Can''t open source file')
end
x=fread(fid);
fclose(fid);
if length(x)<9||~strcmp(char(x(1:3)'),'CWS')
    error('Unexpected type')
end
l=[1 256 65536 16777216]*x(5:8);
y=zuncompr(uint8(x(9:end)),l);
x1=['F';x(2:8);y];
fid=fopen(fdest,'w');
if fid<3
    error('Can''t open destination file')
end
fwrite(fid,x1);
fclose(fid);
