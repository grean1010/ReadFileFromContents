
data AGG_2016;
 infile 'N:\Project\50887_MedicaidAccess\DC1\Task 5\Report 2 (Refresh)\5. Programs\AGG_2016.csv'
    dlm=',' dsd truncover
    firstobs=2;

 length
         year 8.
         state $25.
         ffs_mco_flag $12.
         srv_cat $40.
         spclty_desc $40.
         provider_setting $40.
         pop2use $40.
         pop 8.
         num_providers 8.
         num_inactive_providers 8.
         num_limited_providers 8.
         num_active_providers 8.
         num_any_activity 8.
         pct_inactive_providers 8.
         pct_limited_providers 8.
         pct_active_providers 8.
         pct_any_activity 8.
         num_prov2benes 8.
         num_inact2benes 8.
         num_lim2benes 8.
         num_act2benes 8.
         num_any2benes 8.;

 input
        year
        state
        ffs_mco_flag
        srv_cat
        spclty_desc
        provider_setting
        pop2use
        pop
        num_providers
        num_inactive_providers
        num_limited_providers
        num_active_providers
        num_any_activity
        pct_inactive_providers
        pct_limited_providers
        pct_active_providers
        pct_any_activity
        num_prov2benes
        num_inact2benes
        num_lim2benes
        num_act2benes
        num_any2benes;

 format ffs_mco_flag $12.;
 format num_inactive_providers 11.;
 format num_limited_providers 11.;
 format num_active_providers 11.;

 label ffs_mco_flag = "ffs_mco_flag";
 label num_inactive_providers = "inactive_provider";
 label num_limited_providers = "limited_provider";
 label num_active_providers = "active_provider";
run;
