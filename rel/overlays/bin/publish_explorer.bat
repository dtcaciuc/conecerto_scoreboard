set PHX_SERVER=true
call "%~dp0\migrate.bat"
call "%~dp0\conecerto_scoreboard" eval Conecerto.Scoreboard.Explorer.publish_once
