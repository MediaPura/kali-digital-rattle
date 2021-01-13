for file in Kali_Intro_03_*;
do ext="${file##*.}";
filename="${file%.*}";
finalfilename="${filename}@2x.${ext}";
echo $finalfilename
mv "$file" "$finalfilename";
done
