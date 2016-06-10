% find the amoeba of the polynomial
% p(z, w)=50 z^3+83 z^2 w+24 z w^2+w^3+392 z^2+414 z w+50 w^2-28 z +59 w-100
% See https://en.wikipedia.org/wiki/Amoeba_(mathematics).

function main()

   figure(3); clf; hold on;
   axis equal; axis off;
   axis([-4.5, 5, -3.5, 6]); 
   fs = 20; set(gca, 'fontsize', fs);
   ii=sqrt(-1);
   tiny = 100*eps;
   
   Ntheta = 500; % for Ntheta=500 the code will run very slowly, but will get a good resolution
   NR=      Ntheta; 

   % R is a vector of numbers, exponentiall distributed
   A=-5; B=5;
   LogR  = linspace(A, B, NR);
   R     = exp(LogR);

   % a vector of angles, uniformly distributed
   Theta = linspace(0, 2*pi, Ntheta);

   degree=3;
   Rho = zeros(1, degree*Ntheta); % Rho will store the absolute values of the roots
   One = ones (1, degree*Ntheta);

   % play around with these numbers to get various amoebas
   b1=1;  c1=1; 
   b2=3;  c2=15;
   b3=20; c3=b3/5; 
   d=-80; e=d/4;
   f=0; g=0;
   h=20; k=30; l=60;
   m=0; n = -10; p=0; q=0;
   
%  Draw the 2D figure as union of horizontal slices and then union of vertical slices.
%  The resulting picture achieves much higher resolution than any of the two individually.
   for type=1:2

	  for count_r = 1:NR
		 count_r
		 
		 r = R(count_r);
		 for count_t =1:Ntheta
			
			theta = Theta (count_t);

			if type == 1
			   z=r*exp(ii*theta);

%              write p(z, w) as a polynomial in w with coefficients polynomials in z 
%              first comes the coeff of the highest power of w, then of the lower one, etc.
			   Coeffs=[1+m,
				   c1+c2+c3+b1*z+b2*z+b3*z+k+p*z,
				   e+g+(c1+b1*z)*(c2+b2*z)+(c1+c2+b1*z+b2*z)*(c3+b3*z)+l*z+q*z^2,
				   d+f*z+(c3+b3*z)*(e+(c1+b1*z)*(c2+b2*z))+h*z^2+n*z^3];

			else
%           write p(z, w) as a polynomial in z with coefficients polynomials in w 		
			   w=r*exp(ii*theta);
			   Coeffs=[b1*b2*b3+n,
				   h+b1*b3*(c2+w)+b2*(b3*(c1+w)+b1*(c3+w))+q*w,
				   (b2*c1+b1*c2)*c3+b3*(c1*c2+e)+f+(b1*c2+b3*(c1+c2)+b1*c3+b2*(c1+c3)+l)*w+...
				   (b1+b2+b3)*w^2+p*w^2,
				   d+c3*(c1*c2+e)+(c1*c2+(c1+c2)*c3+e+g)*w+(c1+c2+c3+k)*w^2+w^3+m*w^3];
			end
			
%           find the roots of the polynomial with given coefficients
			Roots = roots(Coeffs);
			
%           log |root|. Use max() to avoid log 0.
			Rho((degree*(count_t-1)+1):(degree*count_t))= log (max(abs(Roots), tiny)); 
		 end
		 

%        plot the roots horizontally or vertically
		 if type == 1
		        plot(LogR(count_r)*One, Rho, 'b.');
		 else
		        plot(Rho, LogR(count_r)*One, 'b.');
		 end
		 
	  end

   end
   
   saveas(gcf, sprintf('amoeba4_%d.eps', NR), 'psc2');

