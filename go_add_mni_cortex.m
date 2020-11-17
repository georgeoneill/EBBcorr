function D = go_add_mni_cortex(S)

D = spm_eeg_load(S.D);

D.inv{1}.mesh.tess_mni = export(gifti(S.cortex),'spm');
D.inv{1}.mesh.tess_ctx = S.cortex;

D = spm_eeg_inv_forward(D,1);
spm_eeg_inv_checkforward(D,1);

save(D);