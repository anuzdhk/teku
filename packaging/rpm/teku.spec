Name:           teku
Version:        %{teku_version}
Release:        1%{?dist}
Summary:        Install apps from a right-click
License:        MIT
URL:            https://github.com/anuzdhk/teku
Source0:        teku-%{version}.tar.gz
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
%{_datadir}/kio/servicemenus/teku.desktop
%{_datadir}/nemo/actions/teku.nemo_action
%{_datadir}/nautilus-python/extensions/teku_nautilus.py
