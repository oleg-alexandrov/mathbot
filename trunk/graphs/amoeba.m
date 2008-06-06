% a simple code to draw the amoeba of p(z, w) = w-2z-1.

a=0; b=50; h=0.01;

R=h/2:h:b;
X=log(R);
Y=log(abs(2*R-1));
Z=log(abs(2*R+1));

figure(1); clf; hold on; axis equal; axis off;

XX=X;
YY=Y;

% append to (X, Y) the pair (X, Z), traveled in reverse (so that we can use fill)
n=length(Z)
for i=1:n
   XX=[XX X(n-i+1)];
   YY=[YY Z(n-i+1)];
end

blue = [0, 0, 1];
H=fill (XX, YY, blue); set(H, 'EdgeColor', blue);


saveas(gcf, 'amoeba of p=w-2z-1.eps', 'psc2')