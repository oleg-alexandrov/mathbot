A=load('data.txt');

plot(A(:, 1), A(:, 2), '.');
axis equal; axis off;

B=8;
axis([-4 6 -5 5])
saveas(gcf, 'amoeba2.eps', 'psc2');
