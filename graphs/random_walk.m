% simulate a random walk in 2D
function main()

   lw = 1;   % line width
   dx=0.05;  % step size
   L=1;      % window size
   N = 5000; % number of steps
   
   ii=sqrt(-1);
   
   AP =(1+ii)*ones(1, N);

   % do the random walk with N steps. Save the results in AP
   P=0;
   for i=1:N
      AP(i)=P;
      dP = (1+ii)*dx*(hrand+ii*hrand)/2;
      P = P+dP;
   end

   figure(2); clf; hold on; axis equal; axis off; 
   plot(real(AP), imag(AP),  'color', 'r', 'linewidth', lw);

   saveas(gcf, 'random_walk_in2D_closeup.eps', 'psc2')

  % chose randomly a number from the set {-1, 1}
function z=hrand

   z=0;
   while z==0
      z=rand(1)-0.5;
      z = sign(z);
   end
   