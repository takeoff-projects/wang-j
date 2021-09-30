Things that were done manually (outside of terraform)
- Enabling APIs (ran into issues with repeated activations so it was removed)
- Inital provisioning of Firestore DB (same reason as above)
- Setting up service account for terraform to use (should've been included in a script probably)
- Downloadng all the go.mod/sum stuff (I don't think this matters for the runtime of the cloud function)
- Setting permissions for cloud function to allUsers allow public access
- Setting permissions for allUsers for cloud function and cloud run site
- TODO: fix automation of cloud run
