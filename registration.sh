#!/bin/bash
set -e
set -u
set -o pipefail

strat_park="/Volumes/MRI/STRAT-PARK"
mni="$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz"
sn="$HOME/masterproject/SN_mask.nii.gz"
lc="$HOME/masterproject/LC_mask.nii.gz"

subject_dir="$strat_park/01-0002_to_01-0012/DICOM/00000A67"
t1we="$subject_dir/STAGE/NIFTI/STAGE_T1WE.nii.gz"
mprage="$subject_dir/FSL/t1_mprage_sag_p2_iso_PACS.nii.gz"


# Register MPRAGE to MNI
flirt -in $mprage -ref $FSLDIR/data/standard/MNI152_T1_1mm.nii.gz -cost normmi -interp trilinear -out T1toMNIlin_new -omat T1toMNIlin.mat