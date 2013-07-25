%global ruby_exec jruby
%global gem_exec %{ruby_exec} -S gem

%global gemname gemjam

%global gemdir %(%{ruby_exec} -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

%define rel %{?gitrev}%{!?gitrev:1}

Summary: Tool for packing rubygem dependencies, into a java jar
Name: jrubygem-%{gemname}
Version:  %{?version}%{!?version:0.0.2}
Release: %{rel}%{?dist}
Group: Development/Languages
License: GPLv2+ or Ruby
URL: http://git.corp.redhat.com/cgit/dev/towers/engineering/gems/gemjam/
Source0: %{gemname}-%{version}.gem
Requires: jruby
Requires: jrubygem(bundler)
BuildRequires: jruby
BuildArch: noarch
Provides: jrubygem(%{gemname}) = %{version}

%description
%{summary}

%prep
rm -rf %{buildroot}
%setup -q -c -T
mkdir -p .%{gemdir}
%{gem_exec} install --local --install-dir .%{gemdir} \
            --bindir .%{_bindir} \
            --force %{SOURCE0}

%build

%install
mkdir -p %{buildroot}%{gemdir}
cp -a .%{gemdir}/* \
        %{buildroot}%{gemdir}

mkdir -p %{buildroot}%{_bindir}
cp -a .%{_bindir}/* \
        %{buildroot}%{_bindir}/

%clean
rm -rf %{buildroot}

%files
%dir %{geminstdir}
%{_bindir}/%{gemname}
%{geminstdir}/bin/%{gemname}
%{geminstdir}/lib
%{geminstdir}/LICENSE
%{geminstdir}/README.md
%exclude %{geminstdir}/%{name}.spec
%exclude %{geminstdir}/%{gemname}.gemspec
%exclude %{geminstdir}/Gemfile
%exclude %{geminstdir}/Rakefile
%exclude %{geminstdir}/.gitignore
%exclude %{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%changelog
* Wed Jun 24 2013 Vincent Batts - 0.0.2-1
- fail on a command failure
- `bundle` uses jruby now
- flag for quiet output
- a few comments

* Tue Jun 23 2013 Vincent Batts - 0.0.1-1
- initial package
