% illustration of a triple torus.
function main(N)

   % number of data points (more points == pretier picture)
%   N = 150;
    N
 
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

   upper_thresh = 0.55*r;
   Z(find (Z>upper_thresh)) = NaN;
   
   a = 2*Kb/sqrt(3); b = a/2;
   myplot(X-Kb, Y-b, Z, surf_color);
   myplot(X+Kb, Y-b, Z, surf_color);
   myplot(X, Y+a, Z, surf_color);


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
         y = Y(i, j);

         x = my_map(x, Kb, Km);

         Z(i, j) = single_torus_function (x, y, r, R);
      end
   end
   Z(find (Z>upper_thresh)) = NaN;
   
   % shift the waist
   X = X-Kb; Y = Y+b;
   Y = -Y;
   
   % plot the waist
   myplot(X, Y, Z, surf_color2);
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
      myplot(X, Y, Z, surf_color2);
      myplot(X, Y, -Z, surf_color2);

   end


   % plot the common surface of the torii
   L=9; 
   I=linspace(-L, L, N);
   
   [X, Y] = meshgrid(I, I);
   Z = 0*X;
      
   for i=1:N
      for j=1:N

         x = X(i, j); 
         y = Y(i, j);
         Z(i, j) = triple_torus_function (x, y, r, R, Kb, Km);
         
      end
   end
   
   myplot(X, Y, Z, surf_color);
   myplot(X, Y, -Z, surf_color);

 % viewing angle
   view(-28, 42);

% add in a source of light
camlight (-50, 54); lighting phong;

print('-dpng', '-r300', sprintf('Triple_torus_illustration_N%d_r300.png', N));

function z = triple_torus_function (x, y, r, R, Kb, Km)

   % center of one of the torii
   O = [-Kb, -Kb/sqrt(3)]; 

   angle = 2*pi/3;
   Mat = [cos(angle)  -sin(angle); sin(angle)   cos(angle)  ];
   
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

         p = [x, y];
         rho = norm(p-O);

         B = O+(Kb/rho)*(p-O);
         
%         t = -O(1)/(x-O(1));
%         B = [0, O(2)+t*(y-O(2))];
         
      end
      
      p = [x, y];
      
      d=norm(p-A);
      q = norm(B-A);
      
      d = my_map(d, q, Km);
      p = (d/q)*B+(1-d/q)*A;
      x=p(1); y=p(2);
         
   end
   
   % shift towards the origin
   x = x-O(1);
   y = y-O(2);
   
   z = single_torus_function (x, y, r, R);

         
function z = single_torus_function (x, y, r, R)

   
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
      y = Km + 1;
   elseif x < Km
      y = x;
   else
      y = Km+sin((pi/2)*(x-Km)/(Kb-Km));
   end
