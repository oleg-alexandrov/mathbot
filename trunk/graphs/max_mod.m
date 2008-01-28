% illustration of a bump function in two dimensions
function main()

   % the number of data points. More points means prettier picture.
   N = 50;

   RR=linspace(0, 1, N);
   TTheta = linspace(-pi, pi, N);

   [R, Theta] = meshgrid(RR, TTheta);

   I=sqrt(-1);
   Z = R.*exp(I*Theta);
   X = real(Z); Y = imag(Z);
   
   FZ = cos(Z);
   AFZ = abs(FZ);
   
   figure(1); clf; hold on; axis equal; axis off;

   surf(X, Y, AFZ, 'FaceColor',    'red', 'EdgeColor','none', 'FaceAlpha', 1);
   surf(X, Y, 0*AFZ, 'FaceColor', 'blue', 'EdgeColor','none', 'FaceAlpha', 0.5); 

% add in two sources of light
   camlight (50, 54); 
   camlight (50, -20);
   lighting phong;

% viewing angle
   view(149, 22);

% save as png
  print('-dpng', '-r200', 'Maximum_modulus_principle.png');

