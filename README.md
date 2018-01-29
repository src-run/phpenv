# phpenv

Installer for `phpenv`, which leverages the great [`sstephenson/rbenv`](https://github.com/sstephenson/rbenv.git)
project at its core (with optional installation of the [`php-build`](https://github.com/php-build/php-build.git)
and [`php-conf`](https://github.com/src-run/php-conf.git) plug-ins). Additionally, the required `build-deps` for
PHP can be installed during script execution.

## Installation

__Single Command Install:__ You can use this installer script without cloning the repository yourself by calling the
following command:

```bash
curl -s https://raw.githubusercontent.com/src-run/phpenv/master/bin/phpenv-installer-remote.bash | bash
```

__Clone Repository Yourself:__ Alternatively, you can clone the repository yourself and execute the installer script:

```bash
git clone --recurse-submodules https://github.com/src-run/phpenv.git
bash phpenv/bin/phpenv-installer.bash
```

## `phpenv` Usage

The `phpenv-install.sh` command sets up a separate `rbenv` for usage with PHP. This environment is  stored in the
`$HOME/.phpenv` directory and contains a `phpenv` executable which sets the `PHPENV_ROOT`  environment variable
to `$HOME/.phpenv`.

To install PHP versions, you can either put compiled version within the `$HOME/.phpenv/versions` directory, or
(if you installed the `php-build` plug-in) you can use the following commands:

```bash
phpenv install -l     # list available versions
phpenv install 7.1.13 # installed php version 7.1.13
phpenv rehash         # refresh installed versions
phpenv global 7.1.13  # set 7.1.13 as global active version
php -v                # outputs version 7.1.13 info
phpenv global system  # go back to the system-installed php version
```