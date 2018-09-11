function [FinalImage dim] = load_tif_3D(FileTif)
% From http://www.matlabtips.com/how-to-load-tiff-stacks-fast-really-fast/

InfoImage=imfinfo(FileTif);
mImage=InfoImage(1).Width;
nImage=InfoImage(1).Height;
NumberImages=length(InfoImage);
FinalImage=zeros(nImage,mImage,NumberImages,'uint16');
 
TifLink = Tiff(FileTif, 'r');
for i=1:NumberImages
   TifLink.setDirectory(i);
   FinalImage(:,:,i)=TifLink.read();
end
TifLink.close();

dim.widht = mImage;
dim.height = nImage;
dim.z = NumberImages;