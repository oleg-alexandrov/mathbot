Lx=4.5; Ly=4.5; % box is [-Lx Lx] x [-Ly, Ly]
N=60;  % number of points (don't make it big, code will be slow)

[X, Y]=meshgrid(-Lx:(1/N):Lx, -Ly:(1/N):Ly);     % X and Y coordinates
Z=X+i*Y;

z0=0.2+0.3*i; z1=2.1+0.6*i; z3=-1-1.8*i;
f=0.2*Z+1./(Z-z0)+2./(Z-z1)+1.3./(Z-z3);

top=5;
f=min(abs(f), top);
clf; 
surf(X, Y, f)
axis off;
colormap jet; shading flat;
axis equal;
