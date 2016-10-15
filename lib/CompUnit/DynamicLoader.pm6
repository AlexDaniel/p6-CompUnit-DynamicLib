use v6;

unit module CompUnit::DynamicLoader;

sub use-lib-do(@include, &block) is export {
    my @repos;
    {
        ENTER {
            @repos = gather for @include -> $inc {
                my $repo;
                CompUnit::RepositoryRegistry.use-repository(
                    $repo = CompUnit::RepositoryRegistry.repository-for-spec($inc)
                );
                take $repo;
            };
        }

        LEAVE {
            for @repos -> $current {
                if $*REPO === $current {
                    PROCESS::<$REPO> := $*REPO.next-repo;
                }
                else {
                    for $*REPO.repo-chain -> $try-repo {
                        if $try-repo.next-repo === $current {
                            $try-repo.next-repo = $current.next-repo;
                            last;
                        }
                    }
                }
            }
        }

        block();
    }
}

sub require-from(@include, Str $module-name) is export {
    use-lib-do(@include, {
        require ::($module-name);
    });
}