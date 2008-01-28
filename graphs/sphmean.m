L=5;
N=100;
h=L/N;
r=3;
f=inline('10-(x.^2-y.^2)/15', 'x', 'y');
blue=[0, 0, 1];
red =[1, 0, 0];
black=[0, 0, 0];
lw=1;
fs=20;
tiny1=0.01;
tiny2=0.03;
tiny3=0.02;

XX=-L:h:L; 
YY=-L:h:L;
[X, Y]=meshgrid(XX, YY);

Z=f(X, Y);
W = Z*0;

Theta=0:h:2.2*pi;
XC=r*cos(Theta); YC = r*sin(Theta); 
ZC = f(XC, YC);

figure(1); clf; hold on; axis equal; axis off;
%view (-34, 44); 
view (108, 36); 
surf(X, Y, Z, 'FaceColor','red', 'EdgeColor','none');
camlight right; lighting phong; % make nice lightning 

% the box at the bottom
XD=[-L, L, L, -L, -L];
YD=[-L, -L, L, L, -L];
ZD=XD*0;
plot3(XD, YD, ZD, 'color', black, 'linewidth', 2*lw);

% the circle on top, and a tiny circle on top
plot3(XC, YC, ZC+tiny1, 'color', blue, 'linewidth', 3*lw);
fill3(tiny2*XC, tiny2*YC, f(tiny2*XC, tiny2*YC)+2*tiny1, blue, 'LineWidth', 1e-4);

% plot the base circle and a tiny disk at the bottom
plot3(XC, YC, 0*ZC, 'color', blue, 'linewidth', 3*lw);
H=fill3(tiny2*XC, tiny2*YC, 0*ZC, blue, 'LineWidth', 1e-4);
get(H)

% circle center
%text(tiny3, tiny3, 0, '\it{x}', 'fontsize', fs);

%print('-djpeg100',  '-r100', 'spherical_mean.jpg') % save to file.
print('-dpng',  '-r300', 'spherical_mean.png') % save to file.

%saveas(gcf, 'spherical_mean.eps', 'psc2')