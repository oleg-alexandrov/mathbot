   % number of data points (more points == pretier picture)
   N = 150;

%  Big and small radii of the torus
   R = 3; r = 1; 

   Kb = R+r;
   Ks = R-r;

   % Km controls the smoothness of the transition from one ring to the others
   Km = 0.5125*Kb;

% prepare the plotting window
   figure(4); clf; hold on; axis equal; axis off;
   scale = 2; axis([-scale*Kb scale*Kb -scale*Kb scale*Kb -r r]);

   surf_color=[184, 224, 98]/256; % light green
   surf_color2=[1, 0, 0];
   surf_color2 = surf_color;
   
% viewing angle
   view(108, 42);

% plot pieces of the three rings
   Ttheta=linspace(0, 2*pi, N);
   Pphi=linspace(0, 2*pi, N);
   [Theta, Phi] = meshgrid(Ttheta, Pphi);
   X=(R+r*cos(Theta)).*cos(Phi);
   Y=(R+r*cos(Theta)).*sin(Phi);
   Z=r*sin(Theta);


surf(X, Y, Z);

camlight (-50, 54); 
lighting phong;

%saveas(gcf, 'delme.eps', 'psc2');

print('-dpng', '-r300', sprintf('Triple_torus_illustration_N%d_r300.png', N));
