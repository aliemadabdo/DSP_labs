clear
close all
C8

%==================Main===========================
%%
%Block divide

grayImg = imread('gray_Img.PNG');      %Reading image
grayImg = im2double(grayImg);

figure; imshow('gray_Img.PNG');  title('orignal image');
figure; imshow(grayImg);  title('readed image');

[rows ,cols] = size(grayImg);            %Get number of rows and columns of the image           

paddedRows = N*ceil(rows/N);            %Number of rows divisible by 8
paddedCols = N*ceil(cols/N);            %Number of columns divisible by 8

paddedImg=zeros(paddedRows ,paddedCols);
paddedImg(1:rows,1:cols)= grayImg;      %Divisible by 8 image with zero padding

figure; imshow(paddedImg) %----- check padded image
 title('padded image');
% ---->>>>>reshape fn needs low level implementation <<<<<---------
block8by8 = split_image(paddedImg,[N N]);  %The 8x8 blocks of the image 
%block8by8(5,5,1450)                    %An example for the block 1450 fifth row fifth column

[x ,y ,numberOfBlocks]=size(block8by8);
DctOfTheBlock =zeros(N,N,numberOfBlocks); %could be discarded and use the varaible "block8by8" directly

%loop on all blocks to apply DCT with C8 on them                                          
for i=1:numberOfBlocks
    DctOfTheBlock(:,:,i)= C_8.*block8by8(:,:,i).*(C_8.'); %A^=CN*A*CN(transpose)
end
%disp(DctOfTheBlock);
%%
%Quantization
%A Standard Quantization Matrix for 50% quality 
r=input('Enter Scaling factor  '); %used  to change quantization level
q_mtx =     [16 11 10 16 24 40 51 61; 
            12 12 14 19 26 58 60 55;
            14 13 16 24 40 57 69 56; 
            14 17 22 29 51 87 80 62;
            18 22 37 56 68 109 103 77;
            24 35 55 64 81 104 113 92;
            49 64 78 87 103 121 120 101;
            72 92 95 98 112 100 103 99];

q = rescale(q_mtx,r,numberOfBlocks,DctOfTheBlock);

%%
%Rescaling 
R = rescaling(q,r,q_mtx,numberOfBlocks);  

%%
%IDCT

for i=1:numberOfBlocks
    IDCT_block(:,:,i)=(C_8.').*R(:,:,i).*C_8; %A=CN(transpose)*A^*CN
end
 IDCT_block2= IDCT_block+128;
%disp(IDCT_block2);
%%
%Merging
newImage=ones(paddedRows,paddedCols);
row_blocks=paddedRows/8;
col_blocks=paddedCols/8;
for k=1:row_blocks
    for j=1:col_blocks
        rmin=(k-1)*8+1;
        rmax=k*8;
        cmin=(j-1)*8+1;
        cmax=j*8;
        newImage(rmin:rmax,cmin:cmax)= IDCT_block(:,:,k*j);
    end
end
%disp(newImage);
figure; imshow(newImage);  title('output image');
%%

%===========================end of the main===========================================

%%functions
function quantized_dct = rescale(x,y,n,dct)
    T=y.*x;
    for k=1:n
        quantized_dct(:,:,k)= round(dct(:,:,k) ./ T); 
    end
    %disp(quantized_dct);      
end 

function rescaled_block8by8 = rescaling(y,r,q,n)
  T=r.*q;
  for k=1:n
    rescaled_block8by8(:,:,k) = y(:,:,k) .* T;
  end
  %disp(rescaled_block8by8);
end

function blocks = split_image(I, block_size)
%splits the image matrix I into small blocks of size BLOCK_SIZE, and returns the blocks as a 3D matrix.

[nrows, ncols] = size(I);       % Get the number of rows and columns in the image

% Get the number of blocks in each direction
nblocks_row = ceil(nrows/block_size(1));
nblocks_col = ceil(ncols/block_size(2));

% Initialize the output matrix
blocks = zeros(block_size(1), block_size(2), nblocks_row*nblocks_col);

% Split the image into blocks
for i = 1:nblocks_row
    for j = 1:nblocks_col
        % Get the current block
        block = I((i-1)*block_size(1)+1:i*block_size(1), (j-1)*block_size(2)+1:j*block_size(2));
        
        % Store the block in the output matrix
        blocks(:,:,(i-1)*nblocks_col+j) = block;
    end
end
end

