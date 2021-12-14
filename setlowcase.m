function setlowcase(d0)
d=dir(d0);

d00=[d0 filesep];

for i=1:length(d)
    fn=lower(d(i).name);
    if ~strcmp(d(i).name,fn)
        dos(['mv ' d00 d(i).name ' ' d00 fn]);
    end
    if d(i).isdir
        if fn(1)~='.'
            setlowcase([d0 filesep fn])
        end
    end
end

