#!/bin/bash
set -e
set -u
set -o pipefail

strat_park="/Volumes/MRI/STRAT-PARK"
mni="$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz"
sn_r="$HOME/masterproject/SN_R_probatlas27_50.nii"
sn_l="$HOME/masterproject/SN_L_probatlas27_50.nii"
lc="$HOME/masterproject/LC_mask.nii.gz"

header=("patient_id SN-STAGE_CROWN_PD_MAP LC-STAGE_CROWN_PD_MAP SN-STAGE_CROWN_R2S LC-STAGE_CROWN_R2S SN-STAGE_CROWN_R2S_A2 LC-STAGE_CROWN_R2S_A2 SN-STAGE_CROWN_T2S LC-STAGE_CROWN_T2S SN-STAGE_CROWN_T2S_A2 LC-STAGE_CROWN_T2S_A2 SN-STAGE_CROWN_TRUE_PD_MAP LC-STAGE_CROWN_TRUE_PD_MAP SN-STAGE_CROWN_TRUE_PD_MAPa LC-STAGE_CROWN_TRUE_PD_MAPa SN-STAGE_HPF_ECHO-3_e3 LC-STAGE_HPF_ECHO-3_e3 SN-STAGE_KMAP LC-STAGE_KMAP SN-STAGE_MRA_e3 LC-STAGE_MRA_e3 SN-STAGE_PD_MAP LC-STAGE_PD_MAP SN-STAGE_R2S_MIP_e3 LC-STAGE_R2S_MIP_e3 SN-STAGE_R2S_e3 LC-STAGE_R2S_e3 SN-STAGE_SWI_ECHO-3_e3 LC-STAGE_SWI_ECHO-3_e3 SN-STAGE_SWI_mIP_ECHO-3_e3 LC-STAGE_SWI_mIP_ECHO-3_e3 SN-STAGE_T1MAP LC-STAGE_T1MAP SN-STAGE_T1WE LC-STAGE_T1WE SN-STAGE_T2S_MIP_e3 LC-STAGE_T2S_MIP_e3 SN-STAGE_T2S_e3 LC-STAGE_T2S_e3 SN-STAGE_TRUE_PD_MAP LC-STAGE_TRUE_PD_MAP SN-STAGE_dSWI_ECHO-3_e3 LC-STAGE_dSWI_ECHO-3_e3 SN-STAGE_dSWI_mIP_ECHO-3_e3 LC-STAGE_dSWI_mIP_ECHO-3_e3 SN-STAGE_meSWIM LC-STAGE_meSWIM SN-STAGE_meSWIM_HPF_ LC-STAGE_meSWIM_HPF_ SN-STAGE_meSWIM_HPF_filled LC-STAGE_meSWIM_HPF_filled SN-STAGE_meSWIM_filled LC-STAGE_meSWIM_filled SN-STAGE_meSWIM_filled_MIP LC-STAGE_meSWIM_filled_MIP SN-STAGE_mpSWIM_ECHO-3_e3 LC-STAGE_mpSWIM_ECHO-3_e3 SN-STAGE_pSWIM_ECHO-3_e3 LC-STAGE_pSWIM_ECHO-3_e3 SN-STAGE_simCSF LC-STAGE_simCSF SN-STAGE_simFLAIR LC-STAGE_simFLAIR SN-STAGE_simGM LC-STAGE_simGM SN-STAGE_simWM LC-STAGE_simWM SN-STAGE_sim_GRE LC-STAGE_sim_GRE SN-STAGE_sim_GREa LC-STAGE_sim_GREa SN-STAGE_tSWI_ECHO-3_e3 LC-STAGE_tSWI_ECHO-3_e3 SN-STAGE_tSWI_mIP_ECHO-3_e3 LC-STAGE_tSWI_mIP_ECHO-3_e3 SN-STAGE_tSWIhpf_ECHO-3_e3 LC-STAGE_tSWIhpf_ECHO-3_e3") 

echo "$header" > $HOME/masterproject/results_0702

for dir in $strat_park/*
do
    for subject_dir in $dir/DICOM/*
    do
    
        patient_id=$(basename $subject_dir)
            
        echo "Processing subject with patient_id: $patient_id"

        # Convert STAGE images from DICOM to NIFTI
        if [ ! -d "$subject_dir/STAGE/NIFTI" ]
        then
            mkdir $subject_dir/STAGE/NIFTI
        fi
        if [ ! -f "$subject_dir/STAGE/NIFTI/STAGE_tSWIhpf_ECHO-3_e3.nii.gz" ]
        then
            /Applications/MRIcroGL.app/Contents/Resources/dcm2niix -z y -f %p -o $subject_dir/STAGE/NIFTI $subject_dir/STAGE
        fi
        t1we="$subject_dir/STAGE/NIFTI/STAGE_T1WE.nii.gz"


        # Convert MPRAGE from DICOM to NIFTI if not already done
        if [ ! -d "$subject_dir/FSL" ]
        then
            mkdir $subject_dir/FSL
        fi
        if [ ! -f "$subject_dir/FSL/t1_mprage_sag_p2_iso_PACS.nii.gz" ]
        then
            /Applications/MRIcroGL.app/Contents/Resources/dcm2niix -z y -f %p -o $subject_dir/FSL $subject_dir/*t1_mprage_sag_p2_iso_PACS
        fi
        mprage="$subject_dir/FSL/t1_mprage_sag_p2_iso_PACS.nii.gz"


        # Register T1WE to MPRAGE if not already done
        if [ ! -f "$subject_dir/FSL/t1we2mprage.mat" ]
        then
            flirt -in $t1we -ref $mprage -omat $subject_dir/FSL/t1we2mprage.mat -out $subject_dir/FSL/t1we_reg_mprage
        fi

        # Register MPRAGE to MNI if not already done
        #if [ ! -f "$subject_dir/FSL/mprage2mni.mat" ]
        #then
        flirt -in $mprage -ref $mni -omat $subject_dir/FSL/mprage2mni.mat -out $subject_dir/FSL/mprage_reg_mni

        #fi

        # Make transformation matrix from T1WE to MNI if not already done
        #if [ ! -f "$subject_dir/FSL/stage2mni.mat" ]
        #then
        convert_xfm -omat $subject_dir/FSL/stage2mni.mat -concat $subject_dir/FSL/mprage2mni.mat $subject_dir/FSL/t1we2mprage.mat
        #fi
        
        #header=("$patient_id ")
        mean=("$patient_id ")

        for image in $subject_dir/STAGE/NIFTI/*.nii.gz
        do
            [ -f "$image" ] || break

            name=$(basename $image .nii.gz)

            echo $name

            # Register to MNI if not already done
            #if [ ! -f "$subject_dir/FSL/${name}_reg_mni.nii.gz" ]
            #then
            flirt -in $image -ref $mni -init $subject_dir/FSL/stage2mni.mat -out $subject_dir/FSL/${name}_reg_mni -applyxfm
            #fi

            # Make mask of SN
            #if [ ! -f "$subject_dir/FSL/${name}_sn.nii.gz" ]
            #then
            fslmaths $subject_dir/FSL/${name}_reg_mni.nii.gz -mas $sn $subject_dir/FSL/${name}_sn
            #fi

            # Make mask of LC
            #if [ ! -f "$subject_dir/FSL/${name}_lc.nii.gz" ]
            #then
            fslmaths $subject_dir/FSL/${name}_reg_mni.nii.gz -mas $lc $subject_dir/FSL/${name}_lc
            #fi

            # Mean of mask of SN
            #header+="SN-$name "
            mean+=$(fslstats $subject_dir/FSL/${name}_sn.nii.gz -M)

            # Mean of mask of LC
            #header+="LC-$name "
            mean+=$(fslstats $subject_dir/FSL/${name}_lc.nii.gz -M)

        done

        # Write mean to file
        #echo "$header" >> $HOME/masterproject/results
        echo "$mean" >> $HOME/masterproject/results_0702
        
    done
    
done



