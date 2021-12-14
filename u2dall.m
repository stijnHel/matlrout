dos('dir *.m>dirlijst');
f=fopen('dirlijst','r');
x=setstr(fread(f)');
l=find(x==13);
k=1;
while (x(l(k)+2)<'A') | (x(l(k)+2)>'Z');k=k+1;end
while (x(l(k)+2)>='A') & (x(l(k)+2)<='Z')
	y=x(l(k)+2:l(k+1)-1);
	z=find(y==' ');
	y=y(1:z-1);
	fn1=[y '.m'];
	fn2=[y '.d'];
	dos(['unix2dos ' fn1 ' ' fn2]);
	k=k+1;
end
