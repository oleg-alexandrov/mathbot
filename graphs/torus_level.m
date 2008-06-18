
r = 1.1;
R = 3;
S = 3.4;

L = r+R+1.2*S;

N = 60;

X = linspace(-L, L, N); m = length(X);
Y = linspace(-L, L, N); n = length(Y);
Z = linspace(-L, L, N); k = length(Z);

theta = 2*pi/3;

W = zeros(m, n, k) + 100;

for q=1:3
   Mat = [cos(q*theta) -sin(q*theta);
          sin(q*theta) cos(q*theta)];
   
   for i=1:length(X)
      for j=1:length(Y)
         for k=1:length(Z)
            x = X(i);
            y = Y(j);
            z = Z(k);
            
            V = Mat*([x, y]');
            x = V(1); y = V(2);
            
            W(i, j, k) = ...
                min(W(i, j, k), ...
                    (sqrt((x-S)^2+y^2)-R)^2 ...
                    +z^2-r^2);
         end
      end
   end
end


   % smooth a bit the places where the tori meet
   XM = -2:50/N:2;
   sigma = 1.5;
   SM = exp(-XM.^2/sigma^2);
   SM = SM/sum(SM);
   
   W = filter(SM, [1], W, [], 1);
   W = filter(SM, [1], W, [], 2);
   W = filter(SM, [1], W, [], 3);


   figure(1); clf; hold on;
   axis equal; axis off;

   light_green=[184, 224, 98]/256; % light green

   H = patch(isosurface(X, Y, Z, W, 0));
   isonormals(X, Y, Z, W, H);
   mycolor = light_green;

%set(H, 'FaceColor', light_green, 'EdgeColor','none', 'FaceAlpha', 1);
%set(H, 'SpecularColorReflectance', 0.9, 'DiffuseStrength', 0.8);
%set(H, 'FaceLighting', 'phong', 'AmbientStrength', 0.35);
%set(H, 'SpecularExponent', 8, 'SpecularStrength', 0.2);
 
   set(H, 'FaceColor', mycolor, 'EdgeColor','none', 'FaceAlpha', 1);
   set(H, 'SpecularColorReflectance', 0.1, 'DiffuseStrength', 0.8);
   set(H, 'FaceLighting', 'phong', 'AmbientStrength', 0.3);
   set(H, 'SpecularExponent', 108);

   daspect([1 1 1]);
   axis tight;
   colormap(prism(28))
   view(89, 34);
   
   camlight headlight;
   lighting phong

  print('-dpng', '-r400',  ...
      sprintf('Triple_torus_illustration.png'));
