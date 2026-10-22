Name:           teku
Version:        0.1.2
Release:        1%{?dist}
Summary:        Install apps from a right-click
License:        GPL-3.0-or-later
URL:            https://github.com/anuzdhk/teku
Source0:        %{url}/archive/v%{version}/teku-%{version}.tar.gz
BuildArch:      noarch
BuildRequires:  make
Requires:       bash zenity polkit file
Recommends:     flatpak nautilus-python

%description
Teku detects a downloaded file's type and your distro, then installs
.deb, .rpm, AppImage and .flatpakref files, or explains why it can't.

%prep
%autosetup

%build

%install
make install DESTDIR=%{buildroot} PREFIX=%{_prefix}

%files
%license LICENSE
%doc README.md
%{_bindir}/teku
%{_datadir}/teku/
%{_datadir}/applications/teku.desktop
%{_datadir}/icons/hicolor/512x512/apps/teku.png
%{_metainfodir}/io.github.anuzdhk.Teku.metainfo.xml
%{_datadir}/kio/servicemenus/teku.desktop
%{_datadir}/nemo/actions/teku.nemo_action
%{_datadir}/nautilus-python/extensions/teku_nautilus.py

%changelog
* Thu Oct 22 2026 anuzdhk <anuzsystem@gmail.com> - 0.1.2-1
- AppStream metadata; show AppImage destination as ~/Applications

* Thu Oct 22 2026 anuzdhk <anuzsystem@gmail.com> - 0.1.1-1
- Add .rpm and AppImage builds
