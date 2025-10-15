# this allows caching of instability.
# making switches less annoying but also less up to date
builtins.fetchGit (
    {
        url = "https://github.com/jappeace/agda-mode";
        ref = "master";
        # 2022.07.03
        rev = "1d16196d9760d69e0eec814fa83fdf27fe27bd4f";
    }
    )
