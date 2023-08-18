set MIX_ENV=prod

call mix assets.deploy
call mix release

call mix phx.digest.clean --all
