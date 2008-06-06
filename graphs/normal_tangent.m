% an illustration of tangent and normal components of a vector to a surface

% a few settings
BoxSize=5;
N=50;
gridsize=BoxSize/N;
lw=3;  % linewidth
fs=30; % fontsize

% the function giving the surface and its gradient
f=inline('10-(x.^2+y.^2)/15', 'x', 'y');
fx=inline('-2*x/15', 'x', 'y');
fy=inline('-2*y/15', 'x', 'y');

% calc the surface
XX=-BoxSize:gridsize:BoxSize; 
YY=-BoxSize:gridsize:BoxSize;
[X, Y]=meshgrid(XX, YY);
Z=f(X, Y);

% plot the surface
H=figure(1); clf; hold on; axis equal; axis off;
view (23, 24); 
surf(X, Y, Z, 'FaceColor','red', 'EdgeColor','none', ...
       'AmbientStrength', 0.3, 'SpecularStrength', 1, 'DiffuseStrength', 0.8);
camlight right; lighting phong; % make nice lightning 

% the vector at the current point, as well as its tangent and normal components
Z0=[0, 0, f(0, 0)];
V=4*[1, 1, 2]; 
n=[fx(0, 0), fy(0, 0), -1]; n=n/norm(n);
Vn=n*dot(V, n);
Vt=V-Vn; 

% graph the vectors
%HH=quiver3(Z0(1), Z0(2), Z0(3), V(1), V(2), V(3), 0);    set(HH(1), 'linewidth', lw); set(HH(2), 'linewidth', lw)
%HH=quiver3(Z0(1), Z0(2), Z0(3), Vt(1), Vt(2), Vt(3), 0); set(HH(1), 'linewidth', lw); set(HH(2), 'linewidth', lw)
%HH=quiver3(Z0(1), Z0(2), Z0(3), Vn(1), Vn(2), Vn(3), 0); set(HH(1), 'linewidth', lw); set(HH(2), 'linewidth', lw)

% plot the text
PV=Z0+V;  text(PV(1), PV(2), PV(3), '{ V}', 'fontsize', fs)
PV=Z0+Vt; text(PV(1), PV(2), PV(3), '{ V}_{||}', 'fontsize', fs)
PV=Z0+Vn; text(PV(1), PV(2), PV(3), '{ V}_{\perp}', 'fontsize', fs)

% save to file
%print('-dpng',  '-r300', 'normal_and_tangent_illustration.png');
plot2svg('normal_and_tangent_illustration.svg')

% The resulting picture was tweaked in Gimp, especially the text, to look nice