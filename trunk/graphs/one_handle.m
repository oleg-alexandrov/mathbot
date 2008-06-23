clear;

S = 6.0;

r = 1;
R = 2.8;
Shift = 7;

L = max(S, 2*r+R+Shift);

N = 30;

L = max(Shift + 2*r+R, S);
X = linspace(-L, L, N);
Y = linspace(-L, L, N);
Z = linspace(-L, L, N);


theta = pi/2.6;
W = zeros(N, N, N) + 100;
Mat = [cos(theta) -sin(theta);
       sin(theta) cos(theta)];

for i=1:N
   for j=1:N
      for k=1:N
         x = X(i);
         y = Y(j);
         z = Z(k);
         
         W(i, j, k) = x^2+y^2+z^2-S^2; % sphere
         
         for q=0:2 % tori
            V = Mat*([x, y]');
            x = V(1); y = V(2);
            W(i, j, k) = min(W(i, j, k), ...
                             (sqrt((x-Shift)^2+y^2)-R)^2 + z^2-r^2);
         end
      end
   end
end


if 1==1
   % smooth a bit the places where the tori meet
   XM = -2:50:2;
   sigma = 1.5;
   SM = exp(-XM.^2/sigma^2);
   SM = SM/sum(SM);
   
   W = filter(SM, [1], W, [], 1);
   W = filter(SM, [1], W, [], 2);
   W = filter(SM, [1], W, [], 3);
end


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
view(-63, -46);
%view(130, 46);

camlight headlight;
lighting phong

print('-dpng',  '-zbuffer',  '-r100', 'Sphere_with_three_handles.png');

%print('-dpng', '-r100',  ...
%      sprintf('Sphere_one_handle.png'));
