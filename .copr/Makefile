# COPR "make_srpm" build: fetch the tagged tarball named in the spec, build the SRPM.
# COPR runs: make -f .copr/Makefile srpm outdir=<dir> spec=<spec>
srpm:
	dnf -y install rpmdevtools
	spectool -g -C $(outdir) packaging/rpm/teku.spec
	rpmbuild -bs --define "_sourcedir $(outdir)" --define "_srcrpmdir $(outdir)" packaging/rpm/teku.spec
