% illustration of a vector field on a surface

figure(1); clf; hold on; axis equal; axis off;
view(-12, 20) % viewing angle

% initial data
f=inline('0.4*(1-(X.^2+1.1*Y.^2))'); % the function to be plotted
fx=inline('-2*X', 'X', 'Y'); fy=inline('-2.2*Y', 'X', 'Y');

Lx1=0; Lx2=1; Ly1=-1; Ly2=1; % the domain of f is the box [Lx1 Lx2] x [Ly1 Ly2]

% plot the surface
N=50; [X, Y]=meshgrid(Lx1:1/N:Lx2, Ly1:1/N:Ly2); Z=f(X, Y); % X and Y
		 surf(X, Y, Z, 'FaceColor','red', 'EdgeColor','none', ...
			  'AmbientStrength', 0.3, 'SpecularStrength', 1, 'DiffuseStrength', 0.8);

% create and plot a vector field (rather arbitrarily)
lw=1.4; % width of vectors
N=3; [X, Y]=meshgrid(Lx1:1/N:Lx2, Ly1:1/N:Ly2); Z=f(X, Y); % X and Y
Vx=fy(X, Y); Vy=-0.5*fx(X, Y); Vz=3+0*Vx;
H=quiver3(X, Y, Z, Vx, Vy, Vz); % draw the normals
set(H(1), 'linewidth', lw); set(H(2), 'linewidth', lw);

camlight headlight; lighting phong; % make nice lightning 

saveas(gcf, 'surface_vectors.eps', 'psc2');
print('-dpng',  '-r300', 'surface_vectors.png') % save to file. 
print('-djpeg',  '-r300', 'surface_vectors.jpg') % save to file. 
