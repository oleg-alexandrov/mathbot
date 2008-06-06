% illustration of a triple torus. Obtained by merging three torii
% This code is a poorly written mess. Sorry. I'll try to clean it
% up at some point.

function main()

%  Big and small radii of the torus
   R = 3; r = 1; 

   Kb = R+r;
   Ks = R-r;

   % Km controls the smoothness of the transition from one ring to the others
   Km = 0.5*Kb;

   % number of data points (more points == pretier picture)
   N = 150;

   % A torus parametrized in polar coordinates
   Ttheta=linspace(0, 2*pi, N);
   Pphi=linspace(0, 2*pi, N);
   [Theta, Phi] = meshgrid(Ttheta, Pphi);
   X=(R+r*cos(Theta)).*cos(Phi);
   Y=(R+r*cos(Theta)).*sin(Phi);
   Z=r*sin(Theta);

   figure(1); clf; hold on; axis equal; axis off;
   scale = 2; axis([-scale*Kb scale*Kb -scale*Kb scale*Kb -r r]);

   surf_color=[184, 224, 98]/256; % light green
   surf_color1 = [1, 0, 0];
   surf_color2 = [0, 1, 0];
   surf_color3 = [0, 0, 1];

   surf_color1 = surf_color;   surf_color2 = surf_color;   surf_color3 = surf_color;
   
   % plot the three torii
   a = 2*Kb/sqrt(3); b = a/2;
   tiny1 = 1e-2;
   tiny2 = 0.75e-1;
   tiny3 = 0.125e-2; % side patches
   myplot(X-Kb, Y-b, Z-tiny1, surf_color1);
   myplot(X+Kb, Y-b, Z-tiny1, surf_color1);
   myplot(X, Y+a, Z-tiny1, surf_color1);

% plot the waists connecting each of the two torii
   %  Dirty tricks to get a grid more adapted to the torus geometry
   small = 0.3*r;
   tiny = 0.001;

   % plot the "waist" of the torus
   XX = linspace(R-0.9*r, R+2.9*r, 4*N);
   YY=linspace(-Kb, Kb, N);
   [X, Y] = meshgrid(XX, YY);

   % Modify Y to make it more adapted to the torus geometry
   M = length(XX);
   for j=1:M

      x = XX(j); x = my_map(x, Kb, Km);
      bl = sqrt(Kb^2-x^2);
      bm = sqrt(max(Ks^2-x^2, 0));
      
      k = 10; tiny = 1/N;
      Y1 = linspace(0, bm-tiny, k); 
      Y2 = linspace(bm, bl, N-k); 
      Y(:, j)=[Y1 Y2]';
      
   end
   
   [m, n] = size(X);
   for i=1:m
      for j=1:n

         x = X(i, j);

         x = my_map(x, Kb, Km);
         
         y = Y(i, j);
         
         z = r^2 - (sqrt(x^2+y^2)-R).^2;
         if z < 0
            z = NaN;
         else
            z = sqrt(z);
         end
         
         Z(i, j) = z;
      end
   end
   
   % shift the waist
   X = X-Kb; Y = Y+b;
   Y = -Y;

   % plot the waist
   myplot(X, Y, Z+tiny3, surf_color2);
   myplot(X, Y, -Z, surf_color2);

   
% rotate the waist 120 degrees clockwise, twice, to get two waists
   for iter=1:2
      angle = 2*pi/3;
      Mat = [cos(angle)  -sin(angle); sin(angle)   cos(angle)  ];
      
      [m, n] = size(X);
      for i=1:m
         for j=1:n
            V = [X(i, j), Y(i, j)]';
            V = Mat*V;
            X(i, j) = V(1); Y(i, j) = V(2);
         end
      end

      % plot the waist
      myplot(X, Y, Z+tiny3, surf_color2);
      myplot(X, Y, -Z+tiny3, surf_color2);

   end

   
   % all the code below is to plot the region morphing the torii
   
   % center of one of the torii
   O = [-Kb, -Kb/sqrt(3)]; 
   
   L=3; 
   I=linspace(-L, L, N);
   
   [X, Y] = meshgrid(I, I);

   Z = 0*X;
   
   angle = 2*pi/3;
   Mat = [cos(angle)  -sin(angle); sin(angle)   cos(angle)  ];
   
   for i=1:N
      for j=1:N

         x = X(i, j); 
         y = Y(i, j);

         p =[x, y]';
         phi = atan2(y, x);

         if phi >= pi/6 & phi <= 5*pi/6
            p = Mat*p; % rotate 120 degree counterclockwise
         elseif phi >= -pi/2 & phi < pi/6
            p = Mat*p; p = Mat*p; % rotate 240 degrees counterclockwise
         end

         x=p(1); y = p(2);
         
         % reflect against a line, to merge two cases in one
         if y > x/sqrt(3)

            p = [x, y];
            v = [cos(2*pi/3), sin(2*pi/3)];

            p = p - 2*v*dot(p, v)/dot(v, v);
            x = p(1); y = p(2);

         end

         if x > O(1)

            % project to the y axis, to a point B
            if y < O(2)
               
               A = [O(1), y];
               B = [0, y];
            else
               
               A = O;
               t = -O(1)/(x-O(1));
               B = [0, O(2)+t*(y-O(2))];
               
            end
            
            p = [x, y];
            
            d=norm(p-A);
            q = norm(B-A);
            
            d = my_map(d, q, Km);
            y = Km+sin((pi/2)*(x-Km)/(Kb-Km));
            p = (d/q)*B+(1-d/q)*A;
            x=p(1); y=p(2);
         
         end
         
         % shift towards the origin
         x = x-O(1);
         y = y-O(2);
         
         Z(i, j) = torus_val (x, y, r, R);
         
      end
   end
   
  % finally, plot the transition between the torii
   myplot(X, Y, Z+tiny2, surf_color3);

 % viewing angle
   view(108, 42);

% add in a source of light
camlight (-50, 54); lighting phong;

print('-dpng', '-r300', sprintf('Triple_torus_illustration_N%d_r300.png', N));
   
function z = torus_val (x, y, r, R)

   
   z = r^2 - (sqrt(x^2+y^2)-R).^2;
   if z < 0
      z = NaN;
   else
      z = sqrt(z);
   end

function myplot(X, Y, Z, mycolor)
   
   H=surf(X, Y, Z); 

%%% set some propeties
   set(H, 'FaceColor', mycolor, 'EdgeColor','none', 'FaceAlpha', 1);
   set(H, 'SpecularColorReflectance', 0.1, 'DiffuseStrength', 0.8);
   set(H, 'FaceLighting', 'phong', 'AmbientStrength', 0.3);
   set(H, 'SpecularExponent', 108);


% This function constructs the second ring in the double torus
% by mapping from the first one.
function y = my_map(x, Kb, Km)
   
   if x > Kb
      x = 2*Kb - x;
   end
   
   if x < Km
      y = x;
   else
      y = Km+sin((pi/2)*(x-Km)/(Kb-Km));
   end
