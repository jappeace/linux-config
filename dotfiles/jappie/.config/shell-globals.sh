#! /bin/bash
# dunno, something with grep, maybe killing some errors?
unset GREP_OPTIONS

# where are the dist files (source code of installed software)
export DISTDIR='/usr/portage/distfiles'

#temnial collors
export TERM='konsole-256color'

# stuff on JVM
export GRAILS_HOME='/usr/local/lib/grails-core'
export SCALA_HOME='/usr/local/lib/scala'
export PATH=${PATH}:${GRAILS_HOME}'/bin'
export PATH=${PATH}:$HOME'/Projects/bash-simple-ci/bin'
export PATH=${PATH}:${SCALA_HOME}'/bin'
export PATH=${PATH}:$HOME'/programs/bin' # programs that aren't installed trough potrage
export JAVA_OPTS="-Xms1024m -Xmx4048m -XX:MaxPermSize=512m";
export ANDROID_HOME="/opt/android-sdk-update-manager"

# javascript packages in path
export PATH=${PATH}:$HOME'/node_modules/.bin'

export TERMCMD='gnome-terminal'

export CCACHE_COMPRESS=1

export KEYSTORE="$HOME/.android/debug.keystore"
export KEYSTORE_PASSWORD="android"
export KEY_ALIAS="androiddebugkey"
export KEY_PASSWORD="android"
export SCALA_STDLIB=$SCALA_HOME/lib/scala-library.jar

export PATH=$PATH:/opt/usertools/jappie/bin

#rust
export PATH=$PATH:~/Projects/racer/target/release
export RUST_SRC_PATH=$DISTDIR/rustc-$(eselect rust list | grep \* | sed 's/.*-//' | sed 's/ \*$//')-src.tar.gz

#haskell packages in pat
export PATH=$PATH:$HOME/.cargo/bin

#firefox hardware acceleration
export MOZ_USE_OMTC=1

# we want qt to look like the kde theme
export XDG_CURRENT_DESKTOP=kde
export QT_STYLE_OVERRIDE=GTK+
export LS_COLORS='di=0;35'

# crappy jump around mechanism
export LINUX_CONFIG="/usr/local/src/linux-config/"
export DOT_FILES="$LINUX_CONFIG/dotfiles/jappie"

# Prevent Wine from adding menu entries and desktop links.
export WINEDLLOVERRIDES='winemenubuilder.exe=d'
