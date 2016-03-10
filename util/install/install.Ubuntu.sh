#!/usr/bin/env bash
# DeepDive installers for Debian/Ubuntu Linux

LSB=$(lsb_release -ir | cut -f2) || true
case ${LSB} in
    Debian*8*|Debian*7*) true ;;
    Ubuntu*12.04|Ubuntu*14.04|Ubuntu*15.04) true ;;
    *) error "$LSB found: This installer may not work on your OS." ||
        error "It has been tested only on Debian 7 and 8, Ubuntu 12.04, 14.04, and 15.04." ||
        true  # don't fail here as it might work for other versions
esac

install__deepdive_build_deps() {
    set -x
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test  # for gcc >= 4.8 on Precise (12.04)
    sudo apt-get update
    build_deps=(
        build-essential
        bash
        coreutils
        git
        make
        rsync
        bzip2
        libbz2-dev
        xz-utils
        flex
        default-jdk
        sed
        mawk
        grep
        bc
        perl
        python-software-properties
        # mindbender
        ed
        # sampler
        gcc-4.8
        g++-4.8
        cmake
        unzip
        libnuma-dev
    )
    sudo apt-get install -qy "${build_deps[@]}"
}

install__deepdive_runtime_deps() {
    set -x
    # install all runtime dependencies for DeepDive
    sudo apt-get update
    runtime_deps=(
        bash
        coreutils
        make
        rsync
        bc
        sed
        grep
        mawk
        perl
        python-software-properties
        default-jre-headless
        gnuplot
        libltdl7  # for graphviz
    )
    sudo apt-get install -qy "${runtime_deps[@]}"
}

install_postgres_xl() {
    source_os_script pgxl
}

install_postgres() {
    set -x
    sudo apt-get update
    sudo apt-get install -qy postgresql
    local pgversion=$(ls -1 /var/lib/postgresql/ | head -n 1)
    if [ -z "${TRAVIS:-}" ]; then
        # add user to postgresql and trust all connections to localhost
        sudo -u postgres dropuser --if-exists $USER || sudo -u postgres dropuser $USER || true
        sudo -u postgres createuser --superuser $USER || true
        tmp=$(mktemp /tmp/pg_hba.conf.XXXXXXX)
        trap "rm -f $tmp" EXIT
        {
            echo 'host	all	all	127.0.0.1/32	trust'
            echo 'host	all	all	::1/128	trust'
            sudo cat /etc/postgresql/$pgversion/main/pg_hba.conf
        } >$tmp
        sudo tee /etc/postgresql/$pgversion/main/pg_hba.conf <$tmp >/dev/null
        sudo service postgresql restart
    fi
}
