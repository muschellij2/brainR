
#!/bin/bash

# Author: John Muschelli, 2013
# This code is to extract the brain using FSL
# BET (Brain Extraction Tool, Steve Smith) from CT Scans 
# Converted from dcm2nii (Chris Rorden)
function usage {
  echo "Usage: $0 -i File to be skull stripped"
  echo "          -o Output directory"
  echo "          -f Fraction used in Skull stripping"
  echo "          -h This page"
  echo "          -g Create the ss images from filled masks (will range outside (0, 100)"  
  echo "          -a Value to be added to image, default 1024"  
  echo "          -r Exclude running raw data"  
  echo "          -b Run only the best option at the time"  
#  echo "          NEED TO ADD opts for which to do"
}
fill='';
run='';
best='';
while getopts "hi:o:f:ga:r:b" flag
do
  case "$flag" in
    i)
      file=$OPTARG
      ;;
    o)
      OUTDIR=$OPTARG
      ;;
    f)
      intensity=$OPTARG
      ;;      
    g)
      fill='fill'
      ;;      
    a)
      adder=$OPTARG
      ;;
    r)
      run='run'
      ;;
    b)
      best='best'
      ;;                            
    h|?)
      usage
      exit 2
      ;;
  esac
done

if [ -z "${file}" ]; then
  echo "File is required"
  usage
  exit 2
fi

if [ -z "${OUTDIR}" ]; then
  echo "OUTDIR is required"
  usage
  exit 3
else
  mkdir -p ${OUTDIR}
fi


if [ -z "${intensity}" ]; then
  echo "No intensity given, using 0.1"
  intensity=0.1;
fi


if [ -z "${adder}" ]; then
  echo "No adder given, using 1024 if needed"
  adder=1024;
  # addon='';
fi


ext=".nii.gz"
if [ "$FSLOUTPUTTYPE" = "NIFTI" ]; 
then
  ext=".nii"
fi

addon="${adder}";

  
sstub=`basename $file`
stub=`echo $sstub | awk '{ sub(/\.gz/, ""); print }'`
stub=`echo $stub | awk '{ sub(/\.nii/, ""); print }'`


### need this because then you can reorient them if you need to
sform=`fslorient -getsformcode $file`  

suffix="${addon}_${intensity}"

if [ -n "${best}" ]; then
  ### no adding or whatever, but thresholding
  raw="${stub}_SS_${intensity}"
  echo "No addition of $adder, 0-100 thresh $file file..";
  fslmaths $file -thr 0 -uthr 100 "${OUTDIR}/${raw}"

  echo "Bet 1 Running $raw"
  bet2 "$OUTDIR/$raw" "$OUTDIR/$raw" -f ${intensity}
  
  rawmask="${stub}_SS_Mask_${intensity}"
  fslmaths "${OUTDIR}/${raw}" -bin -fillh "${OUTDIR}/${rawmask}"

  rm "$OUTDIR/${raw}${ext}"
  exit 0
fi

if [ -z "${run}" ]; then

  # Try BET just on the raw image
  null="${stub}_Raw_${intensity}"

  echo "Raw Brain Extraction $null file..";
  bet2 $file "$OUTDIR/${null}" -f ${intensity}

  nullmask="${stub}_Raw_Mask_${intensity}"
  fslmaths "${OUTDIR}/${null}" -bin -fillh "${OUTDIR}/${nullmask}"      

  ### no adding or whatever, but thresholding
  raw="${stub}_SS_${intensity}"  
  echo "No addition of $adder, 0-100 thresh $file file..";
  fslmaths $file -thr 0 -uthr 100 "${OUTDIR}/${raw}"

  echo "Bet 1 Running $raw"
  bet2 "$OUTDIR/$raw" "$OUTDIR/$raw" -f ${intensity}
  
  rawmask="${stub}_SS_Mask_${intensity}"
  fslmaths "${OUTDIR}/${raw}" -bin -fillh "${OUTDIR}/${rawmask}"
  # fslmaths "$OUTDIR/${rawmask}" -fillh "$OUTDIR/${rawmask}"            
  
  # filled image    
  if [[ ! -z "${fill}" ]]; then
    echo "Filling Image from filled mask"
    fslmaths "${OUTDIR}/${raw}" -mas "$OUTDIR/${rawmask}" "${OUTDIR}/${raw}"
  fi

fi



minmax=`fslstats $file -R`
min=`echo "$minmax" | cut -d ' ' -f 1`
max=`echo "$minmax" | cut -d ' ' -f 2`


result=`echo "($min < 0)" | bc`

if [ $result ] 
then

  zeroed="${file}_Zeroed_${suffix}"
  echo "Rescaling so histograms are 'zeroed', adding $adder"
  ### need to add this so that rest works - can't have pre-subtracted data.  Could adapt this to be anything other than 1024
  fslmaths $file -add $adder $zeroed
  file="$zeroed" 
fi 

# This is important because of 2 things - constraining to brain and getting rid of FOV
h="${stub}_SS_Add_${suffix}"
echo "Thresholding 0 - 100 HU $file file..";
uthresh=`expr $adder + 100`
fslmaths $file -thr $adder -uthr $uthresh "${OUTDIR}/${h}"

echo "Brain from Room extraction $h file..";
bet2 "${OUTDIR}/${h}" "${OUTDIR}/${h}" -f ${intensity}

fslmaths "${OUTDIR}/${h}" -sub $adder "${OUTDIR}/${h}"

fpmask="${stub}_SS_Add_Mask_${suffix}"
fslmaths "${OUTDIR}/${h}" -bin "${OUTDIR}/${fpmask}"
fslmaths "$OUTDIR/${fpmask}" -fillh "$OUTDIR/${fpmask}"
# filled image
if [[ ! -z "${fill}" ]]; then
  echo "Filling Image from filled mask"
  fslmaths "$OUTDIR/${h}" -mas "$OUTDIR/${fpmask}" "$OUTDIR/${h}" 
fi

## fslmaths "$OUTDIR/$h" -thr $adder -bin "$OUTDIR/$h"

### just trying bet straight up
human="${stub}_Human_${suffix}"
echo "Human Extraction $human file..";
bet2 $file "$OUTDIR/${human}" -f ${intensity}

#   j=`echo $stub | awk '{ sub(/\.nii\.gz/, "_SS_"'${intensity}'"\.nii\.gz"); print }'`
#   jmask=`echo $stub | awk '{ sub(/\.nii\.gz/, "_SS_Mask_"'${intensity}'"\.nii\.gz"); print }'`

#   bbet=`echo $stub | awk '{ sub(/\.nii\.gz/, "_SS2_"'${intensity}'"\.nii\.gz"); print }'`
#   bbetmask=`echo $stub | awk '{ sub(/\.nii\.gz/, "_SS2_Mask_"'${intensity}'"\.nii\.gz"); print }'`

#   echo "Thresholding to range of 1024-1124 $human file..";
#   fslmaths "$OUTDIR/${human}" -thr $adder -uthr $uthresh "$OUTDIR/${j}"

#   echo "Bet 1 Running ${j}"
#   bet2 "$OUTDIR/${j}" "$OUTDIR/${j}" -f ${intensity}

#   echo "Bet 2 Running ${j}"
#   ### this is if we want meshes
# # bet $j $j -f $intensity -A
#   bet2 "$OUTDIR/${j}" "$OUTDIR/${bbet}" -f ${intensity}



# # echo "Translating to 0-100 range"
#   echo "Making Binary Image"
#   fslmaths "$OUTDIR/${j}" -thr $adder -bin "$OUTDIR/${jmask}"
#   # filling the holes
#   fslmaths "$OUTDIR/${jmask}" -fillh "$OUTDIR/${jmask}"
# # echo "Making Binary Image"
# # fslmaths "$j" -thr 0 "$j"

#   fslmaths "$OUTDIR/${bbet}" -thr $adder -bin "$OUTDIR/${bbetmask}"
#   fslmaths "$OUTDIR/${bbetmask}" -fillh "$OUTDIR/${bbetmask}"
# # fslmaths "$bbet" -thr 0 "$bbet"

# # echo "Translating to 0-100 range"
#   echo "Subtracting $adder from Image"
#   fslmaths "$OUTDIR/${j}" -sub $adder "$OUTDIR/${j}"
# # echo "Making Binary Image"
# # fslmaths "$j" -thr 0 "$j"

#   fslmaths "$OUTDIR/${bbet}" -sub $adder "$OUTDIR/${bbet}"


fslmaths "$OUTDIR/${human}" -sub $adder "$OUTDIR/${human}"
# fslmaths "$OUTDIR/${human}" -thr $adder "$OUTDIR/${human}"

brainvol=`fslstats "$OUTDIR/${fpmask}" -V | awk '{ print $2/1000 }'`;
echo "Brain volume is $brainvol"
if [ $result ]
then
  echo "Deleting ${zeroed} for cleanup"
  rm "${zeroed}${ext}"
fi 

