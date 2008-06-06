figure(1); clf;

H=axes;

hold on;

h=0.01;
thetam=-0.4*pi; thetap=0.8*pi;
Theta=thetam:h:thetap;
X=cos(Theta); Y=sin(Theta);
Thetam=-2*pi:h:2*pi;
linewidth=2;
Nz=3;
hz=3;

p=0;
N0=max(1, floor(((1-p)*thetam+p*thetap)/h));

B=1.1; hh=0.1;
[XX, YY]=meshgrid(-B:hh:B, -B:hh:B); ZZ=0*XX;
plot3([0 0], [0 0], [0*Nz*hz Nz*hz], 'color', 0*[1, 1, 1])
n=length(X);
surf(XX, YY, ZZ+hz, 'FaceColor','blue', 'EdgeColor','none', 'FaceAlpha', 0.5); 
for i=1:Nz
   z=hz*(Nz+1-i);
%   H2=plot3(cos(Thetam), sin(Thetam), z+0*cos(Thetam), 'color', 0.9*[1 1 1]); set(H2, 'LineStyle', '-.')
   H3=plot3(X, Y, z+0*X, 'color', [1, 0, 0]);   set(H3, 'Linewidth', linewidth, 'linestyle', '-')
   plot3([0, X(N0)], [0, Y(N0)], [z, z])
%   quiver3(0, 0, z, 1, 1, 1, 1/z)
%   scale=0.01; H4=quiver3(X(n), Y(n), z, -scale*(2*Y(n)-Y(n-1)), scale*(2*X(n)-X(n-1)) , 0, 1/z);  set(H4, 'linewidth', linewidth)
end


view(100, 60)
axis equal; axis off;

set(H, 'CameraUpVector', [-10, 0, 1])

%saveas(gcf, 'axis_of_rotation_illustration.eps', 'psc2')